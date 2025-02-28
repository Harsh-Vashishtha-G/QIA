from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends
from typing import Dict, List
import json
from ...core.security import get_current_user
from ...services.ai_engine import AIEngine
from ...services.task_executor import TaskExecutor, TaskType
from ...services.user_context import UserContextManager

router = APIRouter()

class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[int, List[WebSocket]] = {}
        self.ai_engine = AIEngine()
        self.task_executor = TaskExecutor()
        self.context_manager = UserContextManager()

    async def connect(self, websocket: WebSocket, user_id: int):
        await websocket.accept()
        if user_id not in self.active_connections:
            self.active_connections[user_id] = []
        self.active_connections[user_id].append(websocket)

    async def disconnect(self, websocket: WebSocket, user_id: int):
        self.active_connections[user_id].remove(websocket)
        if not self.active_connections[user_id]:
            del self.active_connections[user_id]

    async def send_personal_message(self, message: str, user_id: int):
        if user_id in self.active_connections:
            for connection in self.active_connections[user_id]:
                await connection.send_text(json.dumps({
                    "type": "message",
                    "content": message
                }))

    async def process_command(self, command: dict, user_id: int):
        # Get user context for AI personalization
        user_context = await self.context_manager.get_user_context(user_id)
        
        # Process command through AI engine
        ai_response = await self.ai_engine.process_command(
            command["text"],
            context=user_context
        )
        
        # Execute task and get response
        task_result = await self.task_executor.execute_task(
            TaskType(ai_response["task_identified"]),
            {
                "command": command["text"],
                "user_id": user_id,
                "context": user_context
            }
        )
        
        # Update user context with new interaction
        await self.context_manager.update_context(
            user_id,
            command["text"],
            task_result
        )
        
        return task_result

manager = ConnectionManager()

@router.websocket("/ws/{user_id}")
async def websocket_endpoint(
    websocket: WebSocket,
    user_id: int,
    token: str
):
    try:
        # Verify user authentication
        authenticated_user = await get_current_user(token)
        if str(authenticated_user) != str(user_id):
            await websocket.close(code=4001)
            return
            
        await manager.connect(websocket, user_id)
        
        try:
            while True:
                data = await websocket.receive_text()
                command = json.loads(data)
                
                # Process the command
                response = await manager.process_command(command, user_id)
                
                # Send response back to user
                await manager.send_personal_message(
                    json.dumps(response),
                    user_id
                )
                
        except WebSocketDisconnect:
            await manager.disconnect(websocket, user_id)
            
    except Exception as e:
        await websocket.close(code=4000) 