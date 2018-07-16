from flask import Flask, jsonify, request
from sklearn.externals import joblib

app = Flask(__name__)

pip = joblib.load('model.pkl')
pip.set_params(vect__input='content')

@app.route('/predict')
def predict():
    query = request.args.get('q')

    if not query:
        return '"q query parameter is not provided"', 400

    prediction = pip.predict([query])[0]
    
    if prediction < 0.25:
        prediction = 0.25

    prediction = round(prediction * 4)/4

    return jsonify({'prediction': prediction})