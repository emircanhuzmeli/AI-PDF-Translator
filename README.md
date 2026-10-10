# 🚀 AI-Powered PDF Translator

A full-stack application that seamlessly extracts text from PDF documents and translates them using Large Language Models (LLMs) via API integration. 

This project was developed with a strong focus on system security, clean architecture, and efficient API management.

## 🛠️ Tech Stack

* **Frontend (Client):** Flutter & Dart. Utilizes `file_picker` for local file access and `syncfusion_flutter_pdf` for robust PDF parsing and text extraction.
* **Backend (Server):** Node.js & Express.js. Acts as a secure bridge and API gateway between the client and the AI model.
* **AI Engine:** DeepSeek Chat API. Handles the complex natural language processing and translation tasks.

## 🔒 Security & Architecture

The backend is built with production-grade security measures in mind:
* **Helmet:** Configured HTTP headers to protect the Express app from well-known web vulnerabilities.
* **Rate Limiting:** Implemented `express-rate-limit` (max 30 requests per 15 minutes) to mitigate DDoS and brute-force API quota consumption attacks.
* **Token Authentication:** Custom middleware ensures endpoints are protected via an `APP_SECRET_TOKEN`, allowing only authorized client requests.
* **Environment Isolation:** All sensitive credentials and API keys are strictly isolated using `.env` variables and excluded from version control.
