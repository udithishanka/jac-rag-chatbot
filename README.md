# jac-rag-chatbot

This project demonstrates a simple Retrieval-Augmented Generation (RAG) chatbot built with Jaseci. It exposes a Streamlit based front‑end and an API powered back‑end.

The server now integrates optional web search via the [Serper](https://serper.dev) API. Set the `SERPER_API_KEY` environment variable before starting the server to enable this feature.

The RAG engine can now index text extracted from common image, audio and video formats using Tesseract OCR and Whisper. Ensure the appropriate dependencies are installed for best results.

## Uploading Files

1. Start the Jaseci server with `server.jac`.
2. Launch the Streamlit app using `app.jac`.
3. Use the *Upload File* widget to select PDFs, images, audio or video files. The files are sent to the back‑end and stored under the `docs/` directory. The RAG engine indexes them immediately so future questions can reference their content.

