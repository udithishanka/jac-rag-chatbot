import from mtllm.llm {Model}
import from rag {RagEngine, WebSearch}

glob llm = Model(model_name='gpt-4o', verbose=True);


def web_search(query: str) -> str {
    print(f"Searching the web for: {query}");
    web_search = WebSearch();
    results = web_search.search(query=query);
    return results;
}


def respond(message:str, chat_history:list[dict], allow_mcp: bool=True) -> str
    by llm(
        method="ReAct",
        tools=([web_search] if allow_mcp else []), # [search_docs, search_web] + 
        max_react_iterations=6
    );


with entry {
    message = "What's the Bitcoin price today?";
    chat_history = "";
    reponse = respond(message, chat_history);
    print(f"Response: {reponse}");
}