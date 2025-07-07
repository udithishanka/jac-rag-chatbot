import from mtllm.llms {OpenAI}
import from rag {RagEngine, WebSearch}
import os;
import base64;
import requests;
import anyio;
import mcp;
import mcp_client;

glob rag_engine:RagEngine = RagEngine();
glob llm = OpenAI(model_name='gpt-4o');
glob SERPER_API_KEY: str = os.getenv('SERPER_API_KEY', '');
glob web_search: WebSearch = WebSearch();
glob MCP_SERVER_URL: str = os.getenv('MCP_SERVER_URL', 'http://localhost:8899/mcp');

def search_web(query: str) -> str {
    return web_search.search(query=query);
}

def search_docs(query: str) -> str {
    return rag_engine.search(query=query);
}

def call_mcp_tool(name: str, arguments: dict) -> str {
    return mcp_client.call_mcp_tool(name=name, arguments=arguments);
}


node Session {
    has id: str;
    has chat_history: list[dict];
    has status: int = 1;

    """Generate a response using uploaded documents and web search."""
    def respond(message:str, chat_history:list[dict], allow_mcp: bool=false) -> str
        by llm(
            method="ReAct",
            tools=[search_docs, search_web] + ([call_mcp_tool] if allow_mcp else []),
            max_react_iterations=6
        );
}


walker interact {
    has message: str;
    has session_id: str;
    has allow_mcp: bool = false;

    can init_session with `root entry {
         visit [-->](`?Session)(?id == self.session_id) else {
            session_node = here ++> Session(id=self.session_id, chat_history=[], status=1);
            print("Session Node Created");
            visit session_node;
        }
    }

    can chat with Session entry {
        here.chat_history.append({"role": "user", "content": self.message});
        response = here.respond(
            message=self.message,
            chat_history=here.chat_history,
            allow_mcp=self.allow_mcp
        );

        here.chat_history.append({"role": "assistant", "content": response});

        report {"response": response};
    }
}

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




