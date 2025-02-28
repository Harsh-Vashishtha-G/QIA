from typing import Dict, Any, Optional
import paho.mqtt.client as mqtt
import json
from ..core.config import settings
import asyncio
from enum import Enum

class DeviceType(Enum):
    LIGHT = "light"
    THERMOSTAT = "thermostat"
    LOCK = "lock"
    SWITCH = "switch"
    CAMERA = "camera"

class DeviceAction(Enum):
    TURN_ON = "turn_on"
    TURN_OFF = "turn_off"
    SET_TEMPERATURE = "set_temperature"
    LOCK = "lock"
    UNLOCK = "unlock"
    GET_STATUS = "get_status"

class SmartHomeController:
    def __init__(self):
        self.mqtt_client = mqtt.Client()
        self.mqtt_client.on_connect = self._on_connect
        self.mqtt_client.on_message = self._on_message
        self.device_states: Dict[str, Dict] = {}
        
        # Connect to MQTT broker
        self.mqtt_client.username_pw_set(
            settings.MQTT_USERNAME,
            settings.MQTT_PASSWORD
        )
        self.mqtt_client.connect(
            settings.MQTT_BROKER,
            settings.MQTT_PORT,
            60
        )
        self.mqtt_client.loop_start()

    def _on_connect(self, client, userdata, flags, rc):
        """Subscribe to device topics on connect"""
        self.mqtt_client.subscribe("home/#")

    def _on_message(self, client, userdata, msg):
        """Handle incoming device state updates"""
        try:
            payload = json.loads(msg.payload.decode())
            device_id = msg.topic.split('/')[-1]
            self.device_states[device_id] = payload
        except Exception as e:
            print(f"Error processing message: {e}")

    async def execute_command(
        self,
        device_type: DeviceType,
        action: DeviceAction,
        params: Dict[str, Any] = None,
        device_id: Optional[str] = None
    ) -> Dict[str, Any]:
        """Execute a command on a smart home device"""
        try:
            if not device_id:
                device_id = await self._find_default_device(device_type)
                
            if not device_id:
                return {
                    "status": "error",
                    "message": f"No {device_type.value} device found"
                }

            command = self._build_command(action, params)
            topic = f"home/{device_type.value}/{device_id}/set"
            
            # Publish command to MQTT
            self.mqtt_client.publish(topic, json.dumps(command))
            
            # Wait for state update
            await self._wait_for_state_update(device_id)
            
            return {
                "status": "success",
                "device_id": device_id,
                "state": self.device_states.get(device_id, {}),
                "action": action.value
            }
            
        except Exception as e:
            return {
                "status": "error",
                "message": str(e)
            }

    async def _find_default_device(self, device_type: DeviceType) -> Optional[str]:
        """Find the first available device of given type"""
        # Query device registry or home assistant API
        # This is a placeholder implementation
        return f"default_{device_type.value}"

    def _build_command(
        self,
        action: DeviceAction,
        params: Dict[str, Any] = None
    ) -> Dict[str, Any]:
        """Build command payload based on action and parameters"""
        command = {"action": action.value}
        
        if params:
            if action == DeviceAction.SET_TEMPERATURE:
                command["temperature"] = params.get("temperature", 22)
            elif action in [DeviceAction.TURN_ON, DeviceAction.TURN_OFF]:
                command["brightness"] = params.get("brightness", 100)
                
        return command

    async def _wait_for_state_update(self, device_id: str, timeout: int = 5):
        """Wait for device state update confirmation"""
        start_time = asyncio.get_event_loop().time()
        while (asyncio.get_event_loop().time() - start_time) < timeout:
            if device_id in self.device_states:
                return
            await asyncio.sleep(0.1) 