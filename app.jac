import streamlit as st;
import requests;
import base64;


def bootstrap_frontend(token: str) {
    st.set_page_config(layout="wide");
    st.title("Welcome to your RAG Chatbot!");
    # Initialize chat history
    if "messages" not in st.session_state {
        st.session_state.messages = [];
    }
    allow_mcp = st.checkbox('Allow MCP tools');

    uploaded_file = st.file_uploader('Upload PDF');
    if uploaded_file {
        file_b64 = base64.b64encode(uploaded_file.read()).decode('utf-8');
        response = requests.post(
            "http://localhost:8000/walker/upload_pdf",
            json={"file_name": uploaded_file.name, "file_data": file_b64},
            headers={"Authorization": f"Bearer {token}"}
        );
        if response.status_code == 200 {
            st.success(f"Uploaded {uploaded_file.name}");
        } else {
            st.error(f"Failed to upload {uploaded_file.name}");
        }
    }

    if prompt := st.chat_input("What is up?") {
        # Add user message to chat history
        st.session_state.messages.append({"role": "user", "content": prompt});

        # Display user message in chat message container
        with st.chat_message("user") {
            st.markdown(prompt);
        }
        # Display assistant response in chat message container
        with st.chat_message("assistant") {

            # Call walker API
            response = requests.post(
                "http://localhost:8000/walker/interact",
                json={"message": prompt, "session_id": "123", "allow_mcp": allow_mcp},
                headers={"Authorization": f"Bearer {token}"}
            );

            if response.status_code == 200 {
                response = response.json();
                print("response is",response);
                st.write(response["reports"][0]["response"]);

                # Add assistant response to chat history
                st.session_state.messages.append({"role": "assistant", "content": response["reports"][0]["response"]});
            }
        }
    }
}

with entry {

    INSTANCE_URL = "http://localhost:8000";
    TEST_USER_EMAIL = "test@mail.com";
    TEST_USER_PASSWORD = "password";

    response = requests.post(
        f"{INSTANCE_URL}/user/login",
        json={"email": TEST_USER_EMAIL, "password": TEST_USER_PASSWORD}
    );

    if response.status_code != 200 {
        # Try registering the user if login fails
        response = requests.post(
            f"{INSTANCE_URL}/user/register",
            json={
                "email": TEST_USER_EMAIL,
                "password": TEST_USER_PASSWORD
            }
        );
        assert response.status_code == 201;

        response = requests.post(
            f"{INSTANCE_URL}/user/login",
            json={"email": TEST_USER_EMAIL, "password": TEST_USER_PASSWORD}
        );
        assert response.status_code == 200;
    }

    token = response.json()["token"];

    print("Token:", token);

    bootstrap_frontend(token);
}
