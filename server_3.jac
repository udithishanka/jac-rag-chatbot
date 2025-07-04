import from mtllm.llms {OpenAI}
import from rag {RagEngine}
import os;
import base64;
import requests;

# ---------- Global Instances ----------
glob rag_engine:RagEngine = RagEngine();
glob llm = OpenAI(model_name='gpt-4o');

glob SERPER_API_KEY: str = os.getenv('SERPER_API_KEY', '');

obj WebSearch {
    has api_key: str = SERPER_API_KEY;
    has base_url: str = "https://google.serper.dev/search";

    def search(query: str) {
        headers = {"X-API-KEY": self.api_key, "Content-Type": "application/json"};
        payload = {"q": query};
        resp = requests.post(self.base_url, headers=headers, json=payload);
        if resp.status_code == 200 {
            data = resp.json();
            summary = "";
            results = data.get("organic", []) if isinstance(data, dict) else [];
            for r in results[:3] {
                summary += f"{r.get('title', '')}: {r.get('link', '')}\n";
                if r.get('snippet') {
                    summary += f"{r['snippet']}\n";
                }
            }
            return summary;
        }
        return f"Serper request failed: {resp.status_code}";
    }
}

glob web_search: WebSearch = WebSearch();

# ---------- Chat Routing ----------
enum ChatType {
    RAG : 'Need to use retrievable information in specific documents to respond' = "RAG",
    QA  : 'Given context is enough for an answer' = "GENERAL",
    WEB : 'Need to use web search results to respond' = "web_search"
}

node Router {
    def classify(message:str) -> ChatType by llm(method="Reason", temperature=0.0);
}

# ---------- Session ----------
node Session {
    has id: str;
    has chat_history: list[dict];
    has status: int = 1;

    def respond(message:str, chat_history:str, agent_role:str,  context:str) -> str by llm();
}

# ---------- Chat Nodes ----------
node Chat {
    has chat_type: ChatType;
}

# --- RAG Chat ---
node RagChat(Chat) {
    has chat_type: ChatType = ChatType.RAG;

    can respond with infer entry {
        def respond(message:str, chat_history:list[dict], agent_role:str, context:list) -> str by llm();
        docs = rag_engine.get_from_chroma(query = visitor.message);
        visitor.response = visitor.respond(
            message=visitor.message,
            chat_history=visitor.chat_history,
            agent_role="You are a conversation agent designed to help users with their queries based on the documents provided",
            context=docs
        );
    }
}

# --- WEB Chat ---
node WebChat(Chat) {
    has chat_type: ChatType = ChatType.WEB;

    can respond with infer entry {
        def respond(message:str, chat_history:list[dict], agent_role:str, context:str) -> str by llm();

        web_ctx = web_search.search(query = visitor.message);
        visitor.response = visitor.respond(
            message=visitor.message,
            chat_history=visitor.chat_history,
            agent_role="You are a conversation agent designed to help users with their queries based on the web search results",
            context=web_ctx
        );
    }
}

# --- QA Chat ---
node QAChat(Chat) {
    has chat_type: ChatType = ChatType.QA;

    can respond with infer entry {
        def respond(message:str, chat_history:list[dict], agent_role:str) -> str by llm();
        visitor.response = visitor.respond(
            message=visitor.message,
            chat_history=visitor.chat_history,
            agent_role="You are a helpful assistant"
        );
    }
}

# ---------- Routing Walker ----------
walker infer {
    has message:str;
    has chat_history: list[dict];
    has response:str = "";

    can init_router with `root entry {
        visit [-->](`?Router) else {
            router_node = here ++> Router();
            router_node ++> RagChat();
            router_node ++> QAChat();
            router_node ++> WebChat();
            visit router_node;
        }
    }

    can route with Router entry {
        classification = here.classify(message = self.message);
        visit [-->](`?Chat)(?chat_type == classification);
    }
}

# ---------- Main Interaction Walker ----------
walker interact {
    has message: str;
    has session_id: str;

    can init_session with `root entry {
         visit [-->](`?Session)(?id == self.session_id) else {
            session_node = here ++> Session(id=self.session_id, chat_history=[], status=1);
            print("Session Node Created");

            visit session_node;
        }
    }

    can chat with Session entry {
        here.chat_history.append({"role": "user", "content": self.message});
        # Delegate to infer walker to obtain correct response
        resp = infer(message=self.message, chat_history=here.chat_history) spawn root;
        here.chat_history.append({"role": "assistant", "content": resp.response});
        report {"response": resp.response};
    }
}

# ---------- PDF Upload Walker ----------
walker upload_pdf {
    has file_name: str;
    has file_data: str;

    can save_doc with `root entry {
        if not os.path.exists(rag_engine.file_path) {
            os.makedirs(rag_engine.file_path);
        }
        file_path = os.path.join(rag_engine.file_path, self.file_name);
        data = base64.b64decode(self.file_data.encode('utf-8'));
        with open(file_path, 'wb') as f {
            f.write(data);
        }
        rag_engine.add_file(file_path);
        report {"status": "uploaded"};
    }
}
