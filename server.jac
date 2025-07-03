import from mtllm.llms {OpenAI}
import from rag {RagEngine}

glob rag_engine:RagEngine = RagEngine();

glob llm = OpenAI(model_name='gpt-4o');

node Session {
    has id: str;
    has chat_history: list[dict];
    has status: int = 1;

    def respond(message:str, chat_history:str, agent_role:str,  context:str) -> str by llm();
}


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
        data = rag_engine.get_from_chroma(query=self.message);
        response = here.respond(
            message=self.message,
            chat_history=here.chat_history,
            agent_role="You are a conversation agent designed to help users with their queries based on the documents provided",
            context=data
        );

        here.chat_history.append({"role": "assistant", "content": response});

        report {"response": response};  
    }
}




