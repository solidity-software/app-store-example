from flask import Flask, render_template
import requests

app = Flask(__name__)

@app.route("/")
def index():
    # Call the FastAPI service
    response = requests.get("http://fastapi:8000/")
    data = response.json()
    return render_template("index.html", message=data["message"])

if __name__ == "__main__":
    app.run(debug=True, port=5000)
