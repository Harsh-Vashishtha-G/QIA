from fastapi import APIRouter, UploadFile, File, HTTPException, Depends
from ...services.voice_processor import VoiceProcessor
from ...services.ai_engine import AIEngine
from ...services.task_executor import TaskExecutor, TaskType
from typing import Optional
from ...core.security import get_current_user

router = APIRouter()
voice_processor = VoiceProcessor()
ai_engine = AIEngine()
task_executor = TaskExecutor()

@router.post("/process-voice")
async def process_voice_command(
    audio_file: UploadFile = File(...),
    current_user: int = Depends(get_current_user)
):
    try:
        # Read audio file
        audio_content = await audio_file.read()
        
        # Transcribe audio to text
        transcription = await voice_processor.transcribe_audio(audio_content)
        if transcription["status"] != "success":
            raise HTTPException(status_code=400, detail="Failed to transcribe audio")
            
        # Process command through AI engine
        ai_response = await ai_engine.process_command(transcription["text"])
        if ai_response["status"] != "success":
            raise HTTPException(status_code=400, detail="Failed to process command")
            
        # Execute identified task
        task_result = await task_executor.execute_task(
            TaskType(ai_response["task_identified"]),
            {
                "command": transcription["text"],
                "user_id": current_user,
                "user_context": await get_user_context(current_user)
            }
        )
        
        # Generate voice response
        audio_response = await voice_processor.text_to_speech(task_result["result"]["message"])
        
        return {
            "status": "success",
            "transcription": transcription["text"],
            "response": task_result,
            "audio_response": audio_response
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e)) 