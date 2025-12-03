# Mock Backend
 Medical Transcription App  Build a Flutter app that doctors can trust with their patient consultations.  The app records audio during medical visits and streams it to a backend for AI transcription.  

## To Build Locally
Make Sure You have Node and npm install


## To Build From DockerFile
```bash
docker build -t transcript-service:latest .
```
```bash 
docker run -d -p 8080:3000 --name transcriptservice transcript-service
```
## From Docker Compose 
```bash
docker-compose up -d --build
```
