# QIA - Your Personal AI Assistant

QIA is a modern, feature-rich AI assistant built with Flutter and FastAPI, designed to provide a seamless and intelligent user experience.

## Features

- 🎯 Real-time voice command recognition and execution
- 🔒 Secure authentication and data encryption
- 🎨 Beautiful, responsive UI design
- 🤖 AI-powered personalization
- 📱 Cross-platform support (Web, iOS, Android)
- 🔋 Background task handling and battery optimization

## Tech Stack

### Frontend
- Flutter (Web/Mobile)
- Provider for state management
- WebSocket for real-time communication
- Speech-to-text for voice commands
- Modern UI components and animations

### Backend
- FastAPI
- PostgreSQL
- WebSocket support
- JWT authentication
- AI/ML integration

## Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0)
- Python 3.8+
- Git

### Installation

1. Clone the repository
```bash
git clone https://github.com/Harsh-Vashishtha-G/QIA.git
cd QIA
```

2. Frontend Setup
```bash
cd frontend/qia_app
flutter pub get
flutter run -d chrome  # For web development
```

3. Backend Setup
```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --reload
```

## Live Demo
Visit [https://harsh-vashishtha-g.github.io/QIA](https://harsh-vashishtha-g.github.io/QIA) to see the live application.

## Contributing
Contributions are welcome! Please feel free to submit a Pull Request.

## License
This project is licensed under the MIT License - see the LICENSE file for details. 