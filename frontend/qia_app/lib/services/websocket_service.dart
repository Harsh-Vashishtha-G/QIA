import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'dart:convert';
import 'dart:async';
import '../config/app_config.dart';
import '../utils/logger.dart';
import 'auth_service.dart';

class WebSocketService extends ChangeNotifier {
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  bool _isConnected = false;
  final AuthService _authService;

  WebSocketService(this._authService);

  bool get isConnected => _isConnected;

  void connect() async {
    if (_isConnected) return;

    try {
      Logger.info('Attempting WebSocket connection...');
      
      final wsUrl = Uri.parse('${AppConfig.wsUrl}/ws');
      _channel = WebSocketChannel.connect(wsUrl);
      
      // Set up connection listener
      _channel?.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
        cancelOnError: true,
      );

      _isConnected = true;
      _startHeartbeat();
      notifyListeners();
      
      Logger.info('WebSocket connected successfully');
    } catch (e) {
      Logger.error('WebSocket connection failed', error: e);
      _handleError(e);
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final decodedMessage = jsonDecode(message as String);
      // Handle incoming message
      print('Received message: $decodedMessage');
    } catch (e) {
      Logger.error('Error processing message', error: e);
    }
  }

  void _handleError(dynamic error) {
    Logger.error('WebSocket error', error: error);
    _isConnected = false;
    notifyListeners();
    _scheduleReconnect();
  }

  void _handleDisconnect() {
    Logger.info('WebSocket disconnected');
    _isConnected = false;
    notifyListeners();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!_isConnected) {
        connect();
      }
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      sendMessage({'type': 'heartbeat'});
    });
  }

  void sendMessage(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      try {
        final jsonMessage = jsonEncode(message);
        _channel!.sink.add(jsonMessage);
      } catch (e) {
        Logger.error('Error sending message', error: e);
      }
    }
  }

  void disconnect() {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _channel?.sink.close(status.goingAway);
    _isConnected = false;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
} 