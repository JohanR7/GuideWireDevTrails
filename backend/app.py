from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

@app.route('/')
def home():
    return "Flask backend running!"

@app.route('/api/data', methods=['POST'])
def receive_data():
    data = request.get_json()
    
    name = data.get('name')
    age = data.get('age')
    
    return jsonify({
        "message": "Data received successfully!",
        "name": name,
        "age": age
    })

if __name__ == '__main__':
    app.run(debug=True)