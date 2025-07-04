# jac-rag-chatbot

This project demonstrates a simple Retrieval-Augmented Generation (RAG) chatbot built with Jaseci. It exposes a Streamlit based front‑end and an API powered back‑end.

The server now integrates optional web search via the [Serper](https://serper.dev) API. Set the `SERPER_API_KEY` environment variable before starting the server to enable this feature.

LightRAG support has been added. Install the `lightrag-hku` package to enable a lightweight knowledge graph backend that complements the standard vector store.

## Uploading PDFs

1. Start the Jaseci server with `server.jac`.
2. Launch the Streamlit app using `app.jac`.
3. Use the *Upload PDF* widget to select one or more PDF files. The files are sent to the back‑end and stored under the `docs/` directory. The RAG engine indexes them immediately so future questions can reference their content.

