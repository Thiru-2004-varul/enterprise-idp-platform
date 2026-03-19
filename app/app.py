from flask import Flask
import os

app = Flask(__name__)

@app.route('/')
def home():
    env = os.getenv('APP_ENV', 'unknown')
    return f'Enterprise IDP Platform - running in {env} environment\n'

@app.route('/health')
def health():
    return 'healthy\n', 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
