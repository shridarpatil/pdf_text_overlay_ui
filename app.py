"""
Enhanced Flask PDF Text Overlay Application
==========================================
A complete web application for configuring and applying text overlays, images, and shapes to PDF documents.
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
import base64

# Import the pdf_text_overlay library
try:
    from pdf_text_overlay import pdf_writer, pdf_from_template
except ImportError:
    print("Warning: pdf_text_overlay library not installed. Install with: pip install pdf_text_overlay")
    pdf_writer = None
    pdf_from_template = None

app = Flask(__name__)
app.secret_key = 'your-secret-key-change-this-in-production'

# Configuration
UPLOAD_FOLDER = 'uploads'
OUTPUT_FOLDER = 'outputs'
FONT_FOLDER = 'fonts'
IMAGE_FOLDER = 'images'
ALLOWED_EXTENSIONS = {'pdf'}
ALLOWED_IMAGE_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'bmp'}
MAX_FILE_SIZE = 16 * 1024 * 1024  # 16MB
MAX_IMAGE_SIZE = 10 * 1024 * 1024  # 10MB

# Create necessary directories
for folder in [UPLOAD_FOLDER, OUTPUT_FOLDER, FONT_FOLDER, IMAGE_FOLDER]:
    os.makedirs(folder, exist_ok=True)

def allowed_file(filename, file_type='pdf'):
    """Check if file extension is allowed"""
    if file_type == 'pdf':
        return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS
    elif file_type == 'image':
        return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_IMAGE_EXTENSIONS
    return False

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
        
        if not allowed_file(file.filename, 'pdf'):
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

@app.route('/api/upload-image', methods=['POST'])
def upload_image():
    """Handle image file upload for overlays"""
    try:
        if 'image' not in request.files:
            return jsonify({'error': 'No image uploaded'}), 400
        
        file = request.files['image']
        if file.filename == '':
            return jsonify({'error': 'No image selected'}), 400
        
        if not allowed_file(file.filename, 'image'):
            return jsonify({'error': 'Invalid file type. Only image files are allowed'}), 400
        
        if file.content_length and file.content_length > MAX_IMAGE_SIZE:
            return jsonify({'error': f'Image too large. Maximum size is {MAX_IMAGE_SIZE//1024//1024}MB'}), 400
        
        # Save image with session-specific name
        session_id = get_session_id()
        filename = secure_filename(file.filename)
        image_path = os.path.join(IMAGE_FOLDER, f"{session_id}_{filename}")
        file.save(image_path)
        
        # Store image info in session
        if 'uploaded_images' not in session:
            session['uploaded_images'] = []
        
        session['uploaded_images'].append({
            'filename': filename,
            'path': image_path,
            'upload_time': datetime.now().isoformat()
        })
        session.modified = True
        
        return jsonify({
            'success': True,
            'filename': filename,
            'message': 'Image uploaded successfully'
        })
        
    except Exception as e:
        return jsonify({'error': f'Image upload failed: {str(e)}'}), 500

@app.route('/api/images', methods=['GET'])
def list_images():
    """List uploaded images for current session"""
    try:
        session_id = get_session_id()
        images = session.get('uploaded_images', [])
        
        print(f"Current session ID: {session_id}")
        print(f"Images in session: {len(images)}")
        
        # Filter images that still exist
        valid_images = []
        paths = []
        
        # If no images in session, try to find images by scanning the folder
        if not images and os.path.exists(IMAGE_FOLDER):
            available_files = os.listdir(IMAGE_FOLDER)
            print(f"Scanning folder for images. Found files: {available_files}")
            
            for filename in available_files:
                if filename.startswith(f"{session_id}_"):
                    # Extract original filename
                    original_name = filename[len(f"{session_id}_"):]
                    file_path = os.path.join(IMAGE_FOLDER, filename)
                    
                    valid_images.append({
                        'filename': original_name,
                        'upload_time': datetime.now().isoformat(),  # Default time
                        'url': f'/api/image/{original_name}',
                        'stored_path': file_path
                    })
        else:
            # Use images from session
            for img in images:
                if os.path.exists(img['path']) and img['path'] not in paths:
                    paths.append(img['path'])
                    valid_images.append({
                        'filename': img['filename'],
                        'upload_time': img['upload_time'],
                        'url': f'/api/image/{img["filename"]}',
                        'stored_path': img['path']
                    })
                else:
                    print(f"Image file not found: {img['path']}")
        
        print(f"Found {len(valid_images)} valid images")
        
        return jsonify({
            'success': True,
            'images': valid_images
        })
        
    except Exception as e:
        print(f"Error listing images: {str(e)}")
        return jsonify({'error': f'Failed to list images: {str(e)}'}), 500

@app.route('/api/process', methods=['POST'])
def process_pdf():
    """Process PDF with text overlays, images, and shapes"""
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
        converted_config = []
        session_id = get_session_id()
        
        print(f"Processing configuration: {json.dumps(configuration, indent=2)}")  # Debug logging
        print(f"Sample data: {json.dumps(sample_data, indent=2)}")  # Debug logging
        
        for page_config in configuration:
            converted_page = {
                'page_number': page_config['page_number'],
                'variables': []
            }
            
            # Process text variables
            for var in page_config.get('variables', []):
                if var.get('name') == 'draw_shape' and 'draw_shape' in var:
                    # Handle draw_shape variables - pass through as-is
                    converted_page['variables'].append(var)
                elif 'image' in var:
                    # Handle image variables - pass through as-is
                    converted_page['variables'].append(var)
                elif 'conditional_coordinates' in var:
                    # Handle conditional text variables
                    converted_var = {
                        'name': var['name'],
                        'conditional_coordinates': var['conditional_coordinates']
                    }
                    converted_page['variables'].append(converted_var)
                elif 'x-coordinate' in var and 'y-coordinate' in var:
                    # Handle simple text variables
                    converted_var = {
                        'name': var['name'],
                        'x-coordinate': var['x-coordinate'],
                        'y-coordinate': var['y-coordinate'],
                        'font_size': var.get('font_size', 12)
                    }
                    converted_page['variables'].append(converted_var)
            
            # Process images (convert to image variables)
            for img in page_config.get('images', []):
                converted_img = {
                    'name': img['name'],
                    'image': {
                        'x-coordinate': img['x-coordinate'],
                        'y-coordinate': img['y-coordinate'],
                        'width': img.get('width', 100),
                        'height': img.get('height', 100)
                    }
                }
                converted_page['variables'].append(converted_img)
            
            # Process shapes (convert to draw_shape variables)
            for shape in page_config.get('shapes', []):
                try:
                    # Convert RGB hex color to individual components
                    color_hex = shape.get('color', '#000000').replace('#', '')
                    if len(color_hex) != 6:
                        color_hex = '000000'  # Default to black if invalid
                    
                    r = int(color_hex[0:2], 16) / 255.0
                    g = int(color_hex[2:4], 16) / 255.0
                    b = int(color_hex[4:6], 16) / 255.0
                    
                    # Convert PDF coordinates to inches (assuming 72 DPI) with defaults
                    x0 = shape.get('x-coordinate', 0)
                    y0 = shape.get('y-coordinate', 0)
                    x0_inches = float(x0) / 72.0 if x0 is not None else 0.0
                    y0_inches = float(y0) / 72.0 if y0 is not None else 0.0
                    
                    shape_config = {
                        'name': 'draw_shape',
                        'draw_shape': {
                            'r': round(r, 3),
                            'g': round(g, 3),
                            'b': round(b, 3),
                            'shape': str(shape.get('type', 'rectangle')).capitalize(),
                            'x0-coordinate': round(x0_inches, 3),
                            'y0-coordinate': round(y0_inches, 3)
                        }
                    }
                    
                    # Add shape-specific coordinates with proper validation
                    shape_type = shape.get('type', 'rectangle').lower()
                    if shape_type == 'rectangle':
                        width = float(shape.get('width', 50))
                        height = float(shape.get('height', 50))
                        x1_inches = (x0 + width) / 72.0
                        y1_inches = (y0 + height) / 72.0
                        shape_config['draw_shape']['x1-coordinate'] = round(x1_inches, 3)
                        shape_config['draw_shape']['y1-coordinate'] = round(y1_inches, 3)
                    elif shape_type == 'circle':
                        radius = float(shape.get('radius', 25))
                        radius_inches = radius / 72.0
                        x1_inches = x0_inches + radius_inches
                        y1_inches = y0_inches + radius_inches
                        shape_config['draw_shape']['x1-coordinate'] = round(x1_inches, 3)
                        shape_config['draw_shape']['y1-coordinate'] = round(y1_inches, 3)
                    elif shape_type == 'line':
                        end_x = float(shape.get('end_x', x0 + 50))
                        end_y = float(shape.get('end_y', y0))
                        x1_inches = end_x / 72.0
                        y1_inches = end_y / 72.0
                        shape_config['draw_shape']['x1-coordinate'] = round(x1_inches, 3)
                        shape_config['draw_shape']['y1-coordinate'] = round(y1_inches, 3)
                    
                    converted_page['variables'].append(shape_config)
                    
                except (ValueError, TypeError, KeyError) as e:
                    print(f"Error processing shape: {e}. Skipping shape: {shape}")
                    continue
            
            converted_config.append(converted_page)
        
        print(f"Converted configuration: {json.dumps(converted_config, indent=2)}")  # Debug logging
        
        # Validate image URLs in sample data before processing
        for key, value in sample_data.items():
            if isinstance(value, str) and value.startswith(('http://', 'https://')):
                if '/api/image/' in value:
                    # Extract filename from URL
                    filename = value.split('/api/image/')[-1]
                    session_id = get_session_id()
                    image_path = os.path.join(IMAGE_FOLDER, f"{session_id}_{filename}")
                    
                    if not os.path.exists(image_path):
                        # Try fallback path
                        fallback_path = os.path.join(IMAGE_FOLDER, filename)
                        if not os.path.exists(fallback_path):
                            print(f"Warning: Image not found for key '{key}': {image_path}")
                            # List available files for debugging
                            if os.path.exists(IMAGE_FOLDER):
                                available_files = os.listdir(IMAGE_FOLDER)
                                print(f"Available image files: {available_files}")
                    else:
                        print(f"Image found for key '{key}': {image_path}")
        
        # Default font
        font_path = os.path.join(FONT_FOLDER, 'default.ttf')
        
        # Process PDF
        with open(pdf_path, 'rb') as pdf_file:
            if os.path.exists(font_path):
                with open(font_path, 'rb') as font_file:
                    output = pdf_writer(pdf_file, converted_config, sample_data, font_file)
            else:
                output = pdf_writer(pdf_file, converted_config, sample_data, None)

        # Save output PDF
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

@app.route('/api/test-image/<filename>')
def test_image(filename):
    """Test if an image is accessible"""
    try:
        session_id = get_session_id()
        image_path = os.path.join(IMAGE_FOLDER, f"{session_id}_{filename}")
        
        result = {
            'filename': filename,
            'session_id': session_id,
            'expected_path': image_path,
            'exists': os.path.exists(image_path),
            'image_folder_exists': os.path.exists(IMAGE_FOLDER)
        }
        
        if os.path.exists(IMAGE_FOLDER):
            result['available_files'] = os.listdir(IMAGE_FOLDER)
        
        return jsonify(result)
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/image/<filename>')
def serve_image(filename):
    """Serve uploaded images"""
    try:
        session_id = get_session_id()
        
        # First try with current session ID
        image_path = os.path.join(IMAGE_FOLDER, f"{session_id}_{filename}")
        
        print(f"Current session ID: {session_id}")
        print(f"Looking for image at: {image_path}")
        print(f"File exists: {os.path.exists(image_path)}")
        
        if not os.path.exists(image_path):
            # Try to find the image with any session ID
            if os.path.exists(IMAGE_FOLDER):
                available_files = os.listdir(IMAGE_FOLDER)
                print(f"Available files: {available_files}")
                
                # Look for files that end with the requested filename
                matching_files = [f for f in available_files if f.endswith(f"_{filename}")]
                
                if matching_files:
                    # Use the first matching file
                    image_path = os.path.join(IMAGE_FOLDER, matching_files[0])
                    print(f"Found matching file: {image_path}")
                else:
                    # Try direct filename (fallback)
                    fallback_path = os.path.join(IMAGE_FOLDER, filename)
                    if os.path.exists(fallback_path):
                        image_path = fallback_path
                        print(f"Using fallback path: {image_path}")
                    else:
                        print(f"No matching files found for: {filename}")
                        return jsonify({'error': f'Image not found: {filename}', 'available': available_files}), 404
            else:
                return jsonify({'error': 'Image folder not found'}), 404
        
        return send_file(image_path)
        
    except Exception as e:
        print(f"Error serving image {filename}: {str(e)}")
        return jsonify({'error': f'Failed to serve image: {str(e)}'}), 500
def load_config(config_name):
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
    
    print("Starting Enhanced Flask PDF Text Overlay Application...")
    print("Available endpoints:")
    print("  GET  /                     - Main application interface")
    print("  POST /api/upload           - Upload PDF file")
    print("  POST /api/upload-image     - Upload image for overlay")
    print("  GET  /api/images           - List uploaded images")
    print("  GET  /api/image/<filename>   - Serve uploaded image")
    print("  POST /api/process          - Process PDF with overlays, images, and shapes")
    print("  POST /api/template         - Process HTML template to PDF")
    print("  GET  /api/download/<file>  - Download processed PDF")
    print("  POST /api/save-config      - Save configuration")
    print("  GET  /api/load-config      - Load saved configuration")
    print("  GET  /api/pdf-info         - Get PDF page information")
    
    app.run(debug=True, host='0.0.0.0', port=5000)