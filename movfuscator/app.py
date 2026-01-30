from flask import Flask, render_template, request, send_file
import os
from s_processor import process_s_file

app = Flask(__name__)

UPLOAD_FOLDER = os.path.join('movfuscator', 'uploads')
OUTPUT_FOLDER = os.path.join('movfuscator', 'outputs')

# Ensure directories exist
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(OUTPUT_FOLDER, exist_ok=True)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/convert', methods=['POST'])
def convert():
    if 'file' not in request.files:
        return "No file uploaded", 400
    
    file = request.files['file']
    if file.filename == '':
        return "No file selected", 400

    # Save the input .s file
    input_path = os.path.join(UPLOAD_FOLDER, file.filename)
    file.save(input_path)

    # Define the output path
    output_filename = f"converted_{file.filename}"
    output_path = os.path.join(OUTPUT_FOLDER, output_filename)

    try:
        # Run your custom processing logic
        process_s_file(input_path, output_path)
        return send_file(output_path.replace("movfuscator\\", ""), as_attachment=True)
    except Exception as e:
        return f"Processing Error: {str(e)}", 500

if __name__ == '__main__':
    # host='0.0.0.0' allows connections from other devices (like your VM)
    # port=5000 is the default, but you can change it if needed
    app.run(host='0.0.0.0', port=5000, debug=True)