from openai import OpenAI
import asyncio
import base64
from typing import Optional
from ..core.config import settings

class VoiceProcessor:
    def __init__(self):
        self.client = OpenAI(api_key=settings.OPENAI_API_KEY)
        
    async def transcribe_audio(self, audio_file: bytes) -> dict:
        """
        Transcribe audio using Whisper API
        """
        try:
            # Convert audio bytes to base64
            audio_base64 = base64.b64encode(audio_file).decode('utf-8')
            
            response = await self.client.audio.transcriptions.create(
                model="whisper-1",
                file=audio_file,
                language="en"
            )
            
            return {
                "status": "success",
                "text": response.text,
                "language": response.language
            }
        except Exception as e:
            return {
                "status": "error",
                "error": str(e)
            }
    
    async def text_to_speech(self, text: str) -> Optional[bytes]:
        """
        Convert text to speech using OpenAI TTS
        """
        try:
            response = await self.client.audio.speech.create(
                model="tts-1",
                voice="alloy",
                input=text
            )
            
            return response.content
            
        except Exception as e:
            print(f"TTS Error: {str(e)}")
            return None 