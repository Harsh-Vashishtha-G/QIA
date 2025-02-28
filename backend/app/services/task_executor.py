from enum import Enum
from typing import Dict, Any, Optional
from datetime import datetime
import asyncio
import json
import aiohttp
from bs4 import BeautifulSoup
from .smart_home import SmartHomeController, DeviceType, DeviceAction

class TaskType(Enum):
    SCHEDULE = "schedule"
    WEB_SEARCH = "web_search"
    SMART_HOME = "smart_home"
    CODE_ASSIST = "code_assist"
    GENERAL = "general"

class TaskExecutor:
    def __init__(self):
        self.task_handlers = {
            TaskType.SCHEDULE: self._handle_schedule,
            TaskType.WEB_SEARCH: self._handle_web_search,
            TaskType.SMART_HOME: self._handle_smart_home,
            TaskType.CODE_ASSIST: self._handle_code_assist,
            TaskType.GENERAL: self._handle_general
        }
        self.smart_home = SmartHomeController()
        
    async def execute_task(self, task_type: TaskType, params: Dict[str, Any]) -> Dict[str, Any]:
        """
        Execute a task based on its type and parameters
        """
        handler = self.task_handlers.get(task_type)
        if not handler:
            return {
                "status": "error",
                "message": f"Unknown task type: {task_type}"
            }
            
        try:
            result = await handler(params)
            return {
                "status": "success",
                "task_type": task_type.value,
                "result": result,
                "timestamp": datetime.utcnow().isoformat()
            }
        except Exception as e:
            return {
                "status": "error",
                "task_type": task_type.value,
                "error": str(e),
                "timestamp": datetime.utcnow().isoformat()
            }
    
    async def _handle_schedule(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """
        Handle scheduling tasks like reminders and calendar events
        """
        try:
            command = params["command"].lower()
            
            # Extract date/time information (basic implementation)
            time_indicators = ["today", "tomorrow", "next week", "at", "on"]
            event_time = None
            event_description = command
            
            for indicator in time_indicators:
                if indicator in command:
                    # Basic time extraction - would need more sophisticated parsing
                    event_time = datetime.now()  # Placeholder
                    break
            
            return {
                "message": f"Scheduled: {event_description}",
                "scheduled_time": event_time.isoformat() if event_time else None,
                "type": "schedule"
            }
        except Exception as e:
            return {"message": f"Failed to schedule: {str(e)}"}
    
    async def _handle_web_search(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """
        Handle web searches and information retrieval
        """
        try:
            query = params["command"]
            async with aiohttp.ClientSession() as session:
                # Example using DuckDuckGo API (you'd need to implement actual API calls)
                search_url = f"https://api.duckduckgo.com/?q={query}&format=json"
                async with session.get(search_url) as response:
                    result = await response.json()
                    
            return {
                "message": "Here's what I found",
                "results": result,
                "type": "web_search"
            }
        except Exception as e:
            return {"message": f"Search failed: {str(e)}"}
    
    async def _handle_smart_home(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """
        Handle smart home device control
        """
        try:
            command = params["command"].lower()
            context = params.get("context", {})
            
            # Extract device and action
            device_type = self._identify_device_type(command)
            action = self._identify_device_action(command)
            
            if not device_type or not action:
                return {"message": "Could not identify device or action"}
            
            # Extract additional parameters
            command_params = self._extract_command_parameters(
                command,
                device_type,
                context
            )
            
            # Execute device command
            result = await self.smart_home.execute_command(
                device_type,
                action,
                command_params
            )
            
            return {
                "message": self._format_response(result),
                "device_type": device_type.value,
                "action": action.value,
                "result": result,
                "type": "smart_home"
            }
        except Exception as e:
            return {"message": f"Smart home control failed: {str(e)}"}

    def _identify_device_type(self, command: str) -> Optional[DeviceType]:
        """Identify device type from command"""
        device_keywords = {
            DeviceType.LIGHT: ["light", "lamp", "bulb"],
            DeviceType.THERMOSTAT: ["thermostat", "temperature", "ac", "heat"],
            DeviceType.LOCK: ["lock", "door"],
            DeviceType.SWITCH: ["switch", "plug", "outlet"],
            DeviceType.CAMERA: ["camera", "cam", "security"]
        }
        
        for device_type, keywords in device_keywords.items():
            if any(keyword in command for keyword in keywords):
                return device_type
        return None

    def _identify_device_action(self, command: str) -> Optional[DeviceAction]:
        """Identify device action from command"""
        action_keywords = {
            DeviceAction.TURN_ON: ["turn on", "enable", "activate"],
            DeviceAction.TURN_OFF: ["turn off", "disable", "deactivate"],
            DeviceAction.SET_TEMPERATURE: ["set", "change to", "adjust"],
            DeviceAction.LOCK: ["lock", "secure"],
            DeviceAction.UNLOCK: ["unlock", "open"]
        }
        
        for action, keywords in action_keywords.items():
            if any(keyword in command for keyword in keywords):
                return action
        return None

    def _extract_command_parameters(
        self,
        command: str,
        device_type: DeviceType,
        context: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Extract additional parameters from command"""
        params = {}
        
        if device_type == DeviceType.THERMOSTAT:
            # Extract temperature value
            import re
            temp_match = re.search(r'(\d+)\s*(?:degrees?|°)?', command)
            if temp_match:
                params["temperature"] = float(temp_match.group(1))
            elif "preferences" in context:
                # Use preferred temperature from user context
                params["temperature"] = context["preferences"].get(
                    "preferred_temperature",
                    22
                )
                
        elif device_type == DeviceType.LIGHT:
            # Extract brightness
            brightness_keywords = {
                "dim": 30,
                "bright": 100,
                "medium": 50
            }
            for keyword, value in brightness_keywords.items():
                if keyword in command:
                    params["brightness"] = value
                    break
                    
        return params

    def _format_response(self, result: Dict[str, Any]) -> str:
        """Format response message for user"""
        if result["status"] == "success":
            device_type = result.get("device_type", "device")
            action = result.get("action", "updated")
            return f"Successfully {action} {device_type}"
        else:
            return f"Failed to control device: {result.get('message', 'unknown error')}"
    
    async def _handle_code_assist(self, params: Dict[str, Any]) -> Dict[str, Any]:
        # TODO: Implement code assistance logic
        return {"message": "Code assist task handled"}
    
    async def _handle_general(self, params: Dict[str, Any]) -> Dict[str, Any]:
        # Handle general queries through AI engine
        return {"message": "General task handled"} 