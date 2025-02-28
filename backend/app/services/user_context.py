from typing import Dict, Any, List
from datetime import datetime, timedelta
import json
from sqlalchemy.orm import Session
from ..models.user import User
from ..core.database import get_db

class UserContextManager:
    def __init__(self):
        self.short_term_memory: Dict[int, List[Dict]] = {}
        self.max_memory_size = 50
        self.memory_expiry = timedelta(hours=1)

    async def get_user_context(self, user_id: int) -> Dict[str, Any]:
        """
        Get combined short-term and long-term context for a user
        """
        # Get short-term memory
        short_term = self._get_short_term_memory(user_id)
        
        # Get long-term preferences from database
        db = next(get_db())
        user = db.query(User).filter(User.id == user_id).first()
        
        return {
            "recent_interactions": short_term,
            "preferences": user.preferences,
            "frequently_used_commands": user.frequently_used_commands,
            "custom_shortcuts": user.custom_shortcuts
        }

    async def update_context(
        self,
        user_id: int,
        command: str,
        result: Dict[str, Any]
    ) -> None:
        """
        Update both short-term and long-term context
        """
        # Update short-term memory
        self._update_short_term_memory(user_id, command, result)
        
        # Update long-term preferences in database
        await self._update_long_term_memory(user_id, command, result)

    def _get_short_term_memory(self, user_id: int) -> List[Dict]:
        """
        Get recent interactions from short-term memory
        """
        if user_id not in self.short_term_memory:
            return []
            
        # Clean expired memories
        current_time = datetime.utcnow()
        self.short_term_memory[user_id] = [
            memory for memory in self.short_term_memory[user_id]
            if current_time - memory["timestamp"] < self.memory_expiry
        ]
        
        return self.short_term_memory[user_id]

    def _update_short_term_memory(
        self,
        user_id: int,
        command: str,
        result: Dict[str, Any]
    ) -> None:
        """
        Update short-term memory with new interaction
        """
        if user_id not in self.short_term_memory:
            self.short_term_memory[user_id] = []
            
        memory = {
            "command": command,
            "result": result,
            "timestamp": datetime.utcnow()
        }
        
        self.short_term_memory[user_id].append(memory)
        
        # Maintain maximum size
        if len(self.short_term_memory[user_id]) > self.max_memory_size:
            self.short_term_memory[user_id].pop(0)

    async def _update_long_term_memory(
        self,
        user_id: int,
        command: str,
        result: Dict[str, Any]
    ) -> None:
        """
        Update long-term user preferences and patterns
        """
        db = next(get_db())
        user = db.query(User).filter(User.id == user_id).first()
        
        if not user:
            return
            
        # Update command frequency
        commands = user.frequently_used_commands or {}
        commands[command] = commands.get(command, 0) + 1
        user.frequently_used_commands = commands
        
        # Update preferences based on task type
        preferences = user.preferences or {}
        task_type = result.get("task_type")
        if task_type:
            if task_type not in preferences:
                preferences[task_type] = {}
            
            # Update task-specific preferences
            self._update_task_preferences(
                preferences[task_type],
                command,
                result
            )
            
        user.preferences = preferences
        db.commit()

    def _update_task_preferences(
        self,
        preferences: Dict,
        command: str,
        result: Dict[str, Any]
    ) -> None:
        """
        Update task-specific preferences based on user interaction
        """
        # Example: Update preferred temperature for smart home
        if result.get("type") == "smart_home":
            if "temperature" in result:
                preferences["preferred_temperature"] = result["temperature"]
                
        # Example: Update preferred search sources
        elif result.get("type") == "web_search":
            if "source" in result:
                sources = preferences.get("preferred_sources", [])
                if result["source"] not in sources:
                    sources.append(result["source"])
                preferences["preferred_sources"] = sources 