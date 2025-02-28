from openai import OpenAI
from ..core.config import settings
from typing import Dict, Any
import json

class AIEngine:
    def __init__(self):
        self.client = OpenAI(api_key=settings.OPENAI_API_KEY)

    async def process_command(
        self,
        command: str,
        context: Dict[str, Any] = None
    ) -> dict:
        """
        Process natural language commands using GPT-4 with context
        """
        try:
            # Build system message with context
            system_message = self._build_system_message(context)
            
            response = await self.client.chat.completions.create(
                model="gpt-4",
                messages=[
                    {"role": "system", "content": system_message},
                    {"role": "user", "content": command}
                ],
                temperature=0.7,
                max_tokens=150
            )
            
            return {
                "status": "success",
                "response": response.choices[0].message.content,
                "task_identified": self._identify_task(
                    response.choices[0].message.content,
                    context
                )
            }
        except Exception as e:
            return {
                "status": "error",
                "error": str(e)
            }

    def _build_system_message(self, context: Dict[str, Any] = None) -> str:
        """
        Build system message incorporating user context
        """
        base_message = "You are QIA, an advanced AI assistant capable of understanding and executing various tasks."
        
        if not context:
            return base_message
            
        # Add context-specific information
        context_message = []
        
        if context.get("preferences"):
            context_message.append("User preferences: " + json.dumps(context["preferences"]))
            
        if context.get("frequently_used_commands"):
            context_message.append("Common commands: " + json.dumps(context["frequently_used_commands"]))
            
        if context.get("recent_interactions"):
            recent = context["recent_interactions"][-3:]  # Last 3 interactions
            context_message.append("Recent interactions: " + json.dumps(recent))
            
        return base_message + "\n\nContext:\n" + "\n".join(context_message)

    def _identify_task(self, response: str, context: Dict[str, Any] = None) -> str:
        """
        Identify the type of task from the AI response
        """
        # TODO: Implement task classification logic
        return "general_response" 