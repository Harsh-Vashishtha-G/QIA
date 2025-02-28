import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../utils/platform_utils.dart';
import '../utils/logger.dart';
import 'dart:async';
import 'dart:convert';

class PlatformWebSocket {
  WebSocketChannel? _channel;
  final String url;
  final Duration pingInterval;
  final Duration reconnectDelay;
  final int maxReconnectAttempts;
  
  bool _isConnected = false;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  final _messageController = StreamController<dynamic>.broadcast();

  PlatformWebSocket({
    required this.url,
    this.pingInterval = const Duration(seconds: 30),
    this.reconnectDelay = const Duration(seconds: 5),
    this.maxReconnectAttempts = 5,
  });

  bool get isConnected => _isConnected;
  Stream<dynamic> get messageStream => _messageController.stream;

  Future<void> connect() async {
    if (_isConnected) return;

    try {
      final wsUrl = Uri.parse(url);
      
      // Platform-specific WebSocket configurations
      if (PlatformUtils.isWeb) {
        _channel = WebSocketChannel.connect(wsUrl);
      } else {
        _channel = await _createNativeWebSocket(wsUrl);
      }

      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
        cancelOnError: false,
      );

      _isConnected = true;
      _reconnectAttempts = 0;
      _startPingTimer();
      
      Logger.info('WebSocket connected on ${PlatformUtils.platformName}');
    } catch (e) {
      Logger.error('WebSocket connection failed', error: e);
      _handleError(e);
    }
  }

  Future<WebSocketChannel> _createNativeWebSocket(Uri wsUrl) async {
    Map<String, dynamic> options = {};
    
    if (PlatformUtils.isAndroid) {
      options['keepAlive'] = true;
      options['androidNetworkType'] = 'any'; // Allow both WiFi and cellular
    } else if (PlatformUtils.isIOS) {
      options['allowsUntrustedSSLCertificates'] = false;
      options['voipEnabled'] = true; // Enable VoIP socket for background operation
    }

    return WebSocketChannel.connect(wsUrl, protocols: ['qia_protocol']);
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(pingInterval, (_) {
      if (_isConnected) {
        sendMessage({'type': 'ping'});
      }
    });
  }

  void _handleMessage(dynamic message) {
    try {
      final decodedMessage = json.decode(message as String);
      
      if (decodedMessage['type'] == 'pong') {
        return; // Handle ping-pong internally
      }

      _messageController.add(decodedMessage);
    } catch (e) {
      Logger.error('Error processing message', error: e);
    }
  }

  void _handleError(dynamic error) {
    Logger.error('WebSocket error', error: error);
    _isConnected = false;
    _scheduleReconnect();
  }

  void _handleDisconnect() {
    if (!_isConnected) return;
    
    Logger.info('WebSocket disconnected');
    _isConnected = false;
    _pingTimer?.cancel();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();

    if (_reconnectAttempts >= maxReconnectAttempts) {
      Logger.error('Max reconnection attempts reached');
      return;
    }

    _reconnectTimer = Timer(
      reconnectDelay * (1 << _reconnectAttempts), // Exponential backoff
      () {
        _reconnectAttempts++;
        connect();
      },
    );
  }

  Future<void> sendMessage(Map<String, dynamic> message) async {
    if (!_isConnected || _channel == null) {
      throw Exception('WebSocket not connected');
    }

    try {
      final jsonMessage = json.encode(message);
      _channel!.sink.add(jsonMessage);
    } catch (e) {
      Logger.error('Error sending message', error: e);
      rethrow;
    }
  }

  Future<void> disconnect() async {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    await _channel?.sink.close(status.goingAway);
    _isConnected = false;
    await _messageController.close();
  }
} 