from flask import Flask, render_template
import requests
import os

api_url = os.getenv("FASTAPI_URL", "http://localhost:8000")
app_port = os.getenv("APP_PORT", "5000")

app = Flask(__name__)

@app.route("/")
def index():
    # Call the FastAPI service
    response = requests.get(api_url)
    data = response.json()
    return render_template("index.html", message=data["message"])

if __name__ == "__main__":
    app.run(debug=True, port=app_port)
