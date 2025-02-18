# app.py – A simple Flask web application
from flask import Flask

app = Flask(__name__)

@app.route("/")
def hello():
    return "Hello from Terraform on GKE!", 200

if __name__ == "__main__":
    # Listen on all interfaces on port 8080 (Google Cloud will expect this port for containers)
    app.run(host="0.0.0.0", port=8080)
