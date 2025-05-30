"""
Flask PDF Text Overlay Application
==================================
A complete web application for configuring and applying text overlays to PDF documents.
"""

from flask import Flask, render_template, request, jsonify, send_file, session
from werkzeug.utils import secure_filename
import os
import json
import io
import uuid
from datetime import datetime
import tempfile
import traceback

# Import the pdf_text_overlay library
try:
    from pdf_text_overlay import pdf_writer, pdf_from_template
except ImportError as e:
    raise e
    print("Warning: pdf_text_overlay library not installed. Install with: pip install pdf_text_overlay")
    pdf_writer = None
    pdf_from_template = None

app = Flask(__name__)
app.secret_key = 'your-secret-key-change-this-in-production'

# Configuration
UPLOAD_FOLDER = 'uploads'
OUTPUT_FOLDER = 'outputs'
FONT_FOLDER = 'fonts'
ALLOWED_EXTENSIONS = {'pdf'}
MAX_FILE_SIZE = 16 * 1024 * 1024  # 16MB

# Create necessary directories
for folder in [UPLOAD_FOLDER, OUTPUT_FOLDER, FONT_FOLDER]:
    os.makedirs(folder, exist_ok=True)

def allowed_file(filename):
    """Check if file extension is allowed"""
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def get_session_id():
    """Get or create session ID"""
    if 'session_id' not in session:
        session['session_id'] = str(uuid.uuid4())
    return session['session_id']

@app.route('/')
def index():
    """Main page with the PDF overlay configuration tool"""
    return render_template('index.html')

@app.route('/api/upload', methods=['POST'])
def upload_pdf():
    """Handle PDF file upload"""
    try:
        if 'pdf' not in request.files:
            return jsonify({'error': 'No file uploaded'}), 400
        
        file = request.files['pdf']
        if file.filename == '':
            return jsonify({'error': 'No file selected'}), 400
        
        if not allowed_file(file.filename):
            return jsonify({'error': 'Invalid file type. Only PDF files are allowed'}), 400
        
        # Save file with session-specific name
        session_id = get_session_id()
        filename = secure_filename(file.filename)
        file_path = os.path.join(UPLOAD_FOLDER, f"{session_id}_{filename}")
        file.save(file_path)
        
        # Store file info in session
        session['uploaded_pdf'] = {
            'filename': filename,
            'path': file_path,
            'upload_time': datetime.now().isoformat()
        }
        
        return jsonify({
            'success': True,
            'filename': filename,
            'message': 'PDF uploaded successfully'
        })
        
    except Exception as e:
        return jsonify({'error': f'Upload failed: {str(e)}'}), 500

@app.route('/api/process', methods=['POST'])
def process_pdf():
    """Process PDF with text overlays"""
    try:
        if pdf_writer is None:
            return jsonify({'error': 'pdf_text_overlay library not installed'}), 500
        
        if 'uploaded_pdf' not in session:
            return jsonify({'error': 'No PDF uploaded'}), 400
        
        data = request.get_json()
        configuration = data.get('configuration', [])
        sample_data = data.get('sample_data', {})
        
        if not configuration:
            return jsonify({'error': 'No configuration provided'}), 400
        
        # Get uploaded PDF path
        pdf_path = session['uploaded_pdf']['path']
        
        if not os.path.exists(pdf_path):
            return jsonify({'error': 'Uploaded PDF not found'}), 404
        
        # Convert coordinates from canvas to PDF coordinate system
        # The frontend sends canvas coordinates, we need to convert them to PDF coordinates
        converted_config = []
        for page_config in configuration:
            converted_page = {
                'page_number': page_config['page_number'],
                'variables': []
            }
            
            for var in page_config['variables']:
                # The coordinates are already converted in the frontend
                # but we ensure they match the pdf_text_overlay format
                converted_var = {
                    'name': var['name'],
                    'x-coordinate': var['x-coordinate'],
                    'y-coordinate': var['y-coordinate'],
                    'font_size': var.get('font_size', 12)
                }
                converted_page['variables'].append(converted_var)
            
            converted_config.append(converted_page)
        
        # Default font (you can add custom font upload functionality)
        font_path = os.path.join(FONT_FOLDER, 'default.ttf')  # Will use default font if None
        
        # Process PDF
        with open(pdf_path, 'rb') as pdf_file:
            if font_path and os.path.exists(font_path):
                with open(font_path, 'rb') as font_file:
                    output = pdf_writer(pdf_file, converted_config, sample_data, font_file)
            else:
                output = pdf_writer(pdf_file, converted_config, sample_data, None)
        print(output)
        # Save output PDF
        session_id = get_session_id()
        output_filename = f"output_{session_id}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"
        output_path = os.path.join(OUTPUT_FOLDER, output_filename)
        
        with open(output_path, 'wb') as output_file:
            output.write(output_file)
        
        return jsonify({
            'success': True,
            'output_filename': output_filename,
            'message': 'PDF processed successfully'
        })
        
    except Exception as e:
        error_msg = f'Processing failed: {str(e)}'
        print(f"Error processing PDF: {traceback.format_exc()}")
        return jsonify({'error': error_msg}), 500

@app.route('/api/download/<filename>')
def download_file(filename):
    """Download processed PDF"""
    try:
        file_path = os.path.join(OUTPUT_FOLDER, filename)
        if not os.path.exists(file_path):
            return jsonify({'error': 'File not found'}), 404
        
        return send_file(file_path, as_attachment=True, download_name=filename)
        
    except Exception as e:
        return jsonify({'error': f'Download failed: {str(e)}'}), 500

@app.route('/api/template', methods=['POST'])
def process_template():
    """Process HTML template to PDF"""
    try:
        if pdf_from_template is None:
            return jsonify({'error': 'pdf_text_overlay library not installed'}), 500
        
        data = request.get_json()
        html_template = data.get('html_template', '')
        template_data = data.get('template_data', {})
        
        if not html_template:
            return jsonify({'error': 'No HTML template provided'}), 400
        
        # Process template
        output = pdf_from_template(html_template, template_data)
        
        # Save output PDF
        session_id = get_session_id()
        output_filename = f"template_{session_id}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"
        output_path = os.path.join(OUTPUT_FOLDER, output_filename)
        
        with open(output_path, 'wb') as output_file:
            output_file.write(output)
        
        return jsonify({
            'success': True,
            'output_filename': output_filename,
            'message': 'Template processed successfully'
        })
        
    except Exception as e:
        error_msg = f'Template processing failed: {str(e)}'
        print(f"Error processing template: {traceback.format_exc()}")
        return jsonify({'error': error_msg}), 500

@app.route('/api/save-config', methods=['POST'])
def save_config():
    """Save configuration for later use"""
    try:
        data = request.get_json()
        config_name = data.get('name', f'config_{datetime.now().strftime("%Y%m%d_%H%M%S")}')
        configuration = data.get('configuration', [])
        
        session_id = get_session_id()
        config_path = os.path.join(UPLOAD_FOLDER, f"config_{session_id}_{config_name}.json")
        
        with open(config_path, 'w') as f:
            json.dump({
                'name': config_name,
                'configuration': configuration,
                'created': datetime.now().isoformat()
            }, f, indent=2)
        
        return jsonify({
            'success': True,
            'message': f'Configuration saved as {config_name}'
        })
        
    except Exception as e:
        return jsonify({'error': f'Failed to save configuration: {str(e)}'}), 500

@app.route('/api/pdf-info', methods=['GET'])
def get_pdf_info():
    """Get PDF page dimensions for coordinate conversion"""
    try:
        if 'uploaded_pdf' not in session:
            return jsonify({'error': 'No PDF uploaded'}), 400
        
        pdf_path = session['uploaded_pdf']['path']
        
        if not os.path.exists(pdf_path):
            return jsonify({'error': 'Uploaded PDF not found'}), 404
        
        # Import PyPDF2 or similar to get page dimensions
        try:
            import PyPDF2
            with open(pdf_path, 'rb') as pdf_file:
                pdf_reader = PyPDF2.PdfReader(pdf_file)
                pages_info = []
                
                for i, page in enumerate(pdf_reader.pages):
                    mediabox = page.mediabox
                    pages_info.append({
                        'page': i + 1,
                        'width': float(mediabox.width),
                        'height': float(mediabox.height)
                    })
                
                return jsonify({
                    'success': True,
                    'total_pages': len(pages_info),
                    'pages': pages_info
                })
        except ImportError:
            # Fallback: use standard PDF dimensions (US Letter)
            return jsonify({
                'success': True,
                'total_pages': 1,
                'pages': [{'page': 1, 'width': 612, 'height': 792}],
                'note': 'Using default dimensions - install PyPDF2 for accurate dimensions'
            })
        
    except Exception as e:
        return jsonify({'error': f'Failed to get PDF info: {str(e)}'}), 500
    """Load saved configuration"""
    try:
        session_id = get_session_id()
        config_path = os.path.join(UPLOAD_FOLDER, f"config_{session_id}_{config_name}.json")
        
        if not os.path.exists(config_path):
            return jsonify({'error': 'Configuration not found'}), 404
        
        with open(config_path, 'r') as f:
            config_data = json.load(f)
        
        return jsonify(config_data)
        
    except Exception as e:
        return jsonify({'error': f'Failed to load configuration: {str(e)}'}), 500

# Error handlers
@app.errorhandler(413)
def too_large(e):
    return jsonify({'error': 'File too large. Maximum size is 16MB'}), 413

@app.errorhandler(404)
def not_found(e):
    return jsonify({'error': 'Resource not found'}), 404

@app.errorhandler(500)
def server_error(e):
    return jsonify({'error': 'Internal server error'}), 500

if __name__ == '__main__':
    # Create a simple default font file if none exists
    default_font_path = os.path.join(FONT_FOLDER, 'default.ttf')
    if not os.path.exists(default_font_path):
        print(f"Note: No default font found at {default_font_path}")
        print("You may want to add a TTF font file for better text rendering")
    
    print("Starting Flask PDF Text Overlay Application...")
    print("Available endpoints:")
    print("  GET  /                    - Main application interface")
    print("  POST /api/upload          - Upload PDF file")
    print("  POST /api/process         - Process PDF with overlays")
    print("  POST /api/template        - Process HTML template to PDF")
    print("  GET  /api/download/<file> - Download processed PDF")
    print("  POST /api/save-config     - Save configuration")
    print("  GET  /api/load-config     - Load saved configuration")
    
    app.run(debug=True, host='0.0.0.0', port=5000)