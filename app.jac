import streamlit as st;
import requests;
import base64;


def bootstrap_frontend(token: str) {
    st.set_page_config(layout="wide");
    st.title("Welcome to your Jac MCP Chatbot!");
    
    # Initialize session state
    if "messages" not in st.session_state {
        st.session_state.messages = [];
    }
    if "session_id" not in st.session_state {
        st.session_state.session_id = "user_session_123";
    }

    uploaded_file = st.file_uploader('Upload File (PDF, TXT, Image, or Video)');
    if uploaded_file {
        file_b64 = base64.b64encode(uploaded_file.read()).decode('utf-8');
        
        # Determine file type and endpoint
        file_extension = uploaded_file.name.lower().split('.')[-1];
        file_type = uploaded_file.type or '';
        
        if file_extension == 'pdf' or file_type == 'application/pdf' {
            # Handle PDF files
            endpoint = 'upload_pdf';
            payload = {"file_name": uploaded_file.name, "file_data": file_b64};
            success_msg = f"Uploaded PDF: {uploaded_file.name}";
        } elif file_extension == 'txt' or file_type == 'text/plain' {
            # Handle TXT files (use PDF endpoint for now, or create separate if needed)
            endpoint = 'upload_pdf';
            payload = {"file_name": uploaded_file.name, "file_data": file_b64};
            success_msg = f"Uploaded text file: {uploaded_file.name}";
        } elif file_type and file_type.startswith('image') {
            # Handle image files
            endpoint = 'analyze_image';
            payload = {
                "file_name": uploaded_file.name, 
                "file_data": file_b64,
                "session_id": st.session_state.session_id
            };
            success_msg = f"Processed image: {uploaded_file.name}";
        } elif file_type and file_type.startswith('video') {
            # Handle video files
            endpoint = 'analyze_video';
            payload = {
                "file_name": uploaded_file.name, 
                "file_data": file_b64,
                "session_id": st.session_state.session_id
            };
            success_msg = f"Processed video: {uploaded_file.name}";
        } else {
            st.error(f"Unsupported file type: {file_type or 'unknown'}. Please upload PDF, TXT, Image, or Video files.");
            return;
        }
        
        # Make the API call
        response = requests.post(
            f"http://localhost:8000/walker/{endpoint}",
            json=payload,
            headers={"Authorization": f"Bearer {token}"}
        );
        
        if response.status_code == 200 {
            res = response.json();
            
            # Handle different response types
            if endpoint in ['analyze_image', 'analyze_video'] {
                msg = res["reports"][0].get("description") or res["reports"][0].get("summary");
                file_type_name = "image" if endpoint == 'analyze_image' else "video";
                analysis_message = f"I've analyzed your {file_type_name}: {msg}. Feel free to ask me any questions about it!";
                st.session_state.messages.append({"role": "assistant", "content": analysis_message});
            }
            
            st.success(success_msg);
        } else {
            st.error(f"Failed to process {uploaded_file.name}: {response.text}");
        }
    }

    # Display chat messages from history on app rerun
    for message in st.session_state.messages {
        with st.chat_message(message["role"]) {
            st.markdown(message["content"]);
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
            with st.spinner("Thinking...") {
                # Call walker API
                response = requests.post(
                    "http://localhost:8000/walker/interact",
                    json={
                        "message": prompt, 
                        "session_id": st.session_state.session_id
                    },
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
