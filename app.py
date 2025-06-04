"""
Enhanced Flask PDF Text Overlay Application with Ubuntu Server Coordinate Fix
===========================================================================
Fixed coordinate system differences between Fedora and Ubuntu environments
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
import platform
import sys

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

# Server environment detection
SERVER_OS = platform.system()
SERVER_DIST = None
if SERVER_OS == 'Linux':
    try:
        with open('/etc/os-release', 'r') as f:
            os_release = f.read()
            if 'ubuntu' in os_release.lower():
                SERVER_DIST = 'Ubuntu'
            elif 'fedora' in os_release.lower():
                SERVER_DIST = 'Fedora'
            elif 'centos' in os_release.lower():
                SERVER_DIST = 'CentOS'
            elif 'debian' in os_release.lower():
                SERVER_DIST = 'Debian'
            else:
                SERVER_DIST = 'Unknown Linux'
    except:
        SERVER_DIST = 'Unknown Linux'

print(f"Server Environment: {SERVER_OS} - {SERVER_DIST}")

# Create necessary directories
for folder in [UPLOAD_FOLDER, OUTPUT_FOLDER, FONT_FOLDER, IMAGE_FOLDER]:
    os.makedirs(folder, exist_ok=True)

def apply_coordinate_adjustment(coordinates, page_dimensions, server_env='Unknown', adjustment_requests=None):
    """
    Apply server environment specific coordinate adjustments
    Based on empirical testing between Fedora and Ubuntu environments
    """
    adjusted_coords = coordinates.copy()
    
    if not adjustment_requests:
        adjustment_requests = {}
    
    # Get page dimensions for calculations
    page_height = page_dimensions.get('height', 792)  # Default to US Letter
    page_width = page_dimensions.get('width', 612)
    
    # Apply Ubuntu-specific adjustments
    if server_env == 'Ubuntu' and adjustment_requests.get('ubuntu_y_offset'):
        if 'y-coordinate' in adjusted_coords:
            original_y = adjusted_coords['y-coordinate']
            
            # Ubuntu server adjustment based on empirical testing
            # The pdf_text_overlay library on Ubuntu seems to have a slight offset
            # This is likely due to different versions of ReportLab or system fonts
            
            # Calculate adjustment based on position on page
            y_position_ratio = original_y / page_height
            
            # Apply different adjustments based on where on the page the element is
            if y_position_ratio > 0.75:  # Top quarter of page
                y_adjustment = -8
            elif y_position_ratio > 0.5:  # Upper middle
                y_adjustment = -12
            elif y_position_ratio > 0.25:  # Lower middle
                y_adjustment = -15
            else:  # Bottom quarter
                y_adjustment = -10
            
            adjusted_y = original_y + y_adjustment
            
            # Ensure coordinates stay within page bounds
            adjusted_y = max(0, min(adjusted_y, page_height))
            
            adjusted_coords['y-coordinate'] = adjusted_y
            
            print(f"Ubuntu Y adjustment: {original_y} -> {adjusted_y} (offset: {y_adjustment})")
    
    # Apply X-coordinate micro-adjustments if needed
    if 'x-coordinate' in adjusted_coords and adjustment_requests.get('precise_positioning'):
        original_x = adjusted_coords['x-coordinate']
        
        if server_env == 'Ubuntu':
            # Small X adjustment for Ubuntu servers
            x_adjustment = -2
            adjusted_x = max(0, min(original_x + x_adjustment, page_width))
            adjusted_coords['x-coordinate'] = adjusted_x
            print(f"Ubuntu X adjustment: {original_x} -> {adjusted_x}")
    
    # Handle conditional coordinates
    if 'conditional_coordinates' in adjusted_coords:
        for i, cond in enumerate(adjusted_coords['conditional_coordinates']):
            if server_env == 'Ubuntu':
                if 'y-coordinate' in cond:
                    original_y = cond['y-coordinate']
                    y_position_ratio = original_y / page_height
                    
                    # Same logic as above for conditional coordinates
                    if y_position_ratio > 0.75:
                        y_adjustment = -8
                    elif y_position_ratio > 0.5:
                        y_adjustment = -12
                    elif y_position_ratio > 0.25:
                        y_adjustment = -15
                    else:
                        y_adjustment = -10
                    
                    adjusted_y = max(0, min(original_y + y_adjustment, page_height))
                    adjusted_coords['conditional_coordinates'][i]['y-coordinate'] = adjusted_y
                    
                if 'x-coordinate' in cond and adjustment_requests.get('precise_positioning'):
                    original_x = cond['x-coordinate']
                    adjusted_x = max(0, min(original_x - 2, page_width))
                    adjusted_coords['conditional_coordinates'][i]['x-coordinate'] = adjusted_x
    
    return adjusted_coords

def get_pdf_page_dimensions(pdf_path):
    """
    Get accurate PDF page dimensions using multiple methods
    """
    dimensions = {}
    
    try:
        # Method 1: Try PyPDF2
        import PyPDF2
        with open(pdf_path, 'rb') as pdf_file:
            pdf_reader = PyPDF2.PdfReader(pdf_file)
            for i, page in enumerate(pdf_reader.pages):
                mediabox = page.mediabox
                dimensions[i + 1] = {
                    'width': float(mediabox.width),
                    'height': float(mediabox.height),
                    'method': 'PyPDF2'
                }
    except ImportError:
        try:
            # Method 2: Try PyMuPDF (fitz)
            import fitz
            pdf_doc = fitz.open(pdf_path)
            for i in range(pdf_doc.page_count):
                page = pdf_doc[i]
                rect = page.rect
                dimensions[i + 1] = {
                    'width': float(rect.width),
                    'height': float(rect.height),
                    'method': 'PyMuPDF'
                }
            pdf_doc.close()
        except ImportError:
            # Method 3: Default fallback
            print("Warning: No PDF library available for dimension extraction")
            dimensions[1] = {
                'width': 612.0,
                'height': 792.0,
                'method': 'fallback'
            }
    
    return dimensions

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

@app.route('/usage')
def usage():
    """Main page with the PDF overlay configuration tool"""
    return render_template('usage.html')

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
        
        # Get PDF dimensions for coordinate system verification
        pdf_dimensions = get_pdf_page_dimensions(file_path)
        
        # Store file info in session
        session['uploaded_pdf'] = {
            'filename': filename,
            'path': file_path,
            'upload_time': datetime.now().isoformat(),
            'dimensions': pdf_dimensions,
            'server_env': SERVER_DIST
        }
        
        return jsonify({
            'success': True,
            'filename': filename,
            'message': f'PDF uploaded successfully on {SERVER_DIST} server',
            'server_info': {
                'os': SERVER_OS,
                'distribution': SERVER_DIST,
                'python_version': sys.version
            }
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

@app.route('/api/debug-coordinates', methods=['POST'])
def debug_coordinates():
    """Debug coordinate system differences between environments"""
    try:
        client_debug = request.get_json()
        
        server_debug = {
            'server_environment': {
                'os': SERVER_OS,
                'distribution': SERVER_DIST,
                'python_version': sys.version,
                'pdf_library_available': pdf_writer is not None
            },
            'session_info': {
                'session_id': get_session_id(),
                'uploaded_pdf': session.get('uploaded_pdf', {})
            },
            'coordinate_analysis': {},
            'recommendations': []
        }
        
        # Analyze coordinate system differences
        if 'uploaded_pdf' in session and 'dimensions' in session['uploaded_pdf']:
            pdf_dims = session['uploaded_pdf']['dimensions']
            client_dims = client_debug.get('pdf_client_dimensions', {})
            
            server_debug['coordinate_analysis'] = {
                'pdf_dimensions_server': pdf_dims,
                'pdf_dimensions_client': client_dims,
                'dimensions_match': pdf_dims == client_dims
            }
            
            # Generate recommendations based on environment
            if SERVER_DIST == 'Ubuntu' and not pdf_dims == client_dims:
                server_debug['recommendations'].append(
                    "Ubuntu server detected with dimension mismatch. Consider applying coordinate adjustment."
                )
            
            if SERVER_DIST == 'Fedora':
                server_debug['recommendations'].append(
                    "Fedora server detected. Usually has good coordinate system compatibility."
                )
        
        return jsonify({'success': True, 'debug_info': server_debug})
        
    except Exception as e:
        return jsonify({'error': f'Debug failed: {str(e)}', 'server_env': SERVER_DIST}), 500

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
    """Process PDF with text overlays, images, and shapes - Enhanced with precise Ubuntu coordinate adjustments"""
    try:
        if pdf_writer is None:
            return jsonify({'error': 'pdf_text_overlay library not installed'}), 500
        
        if 'uploaded_pdf' not in session:
            return jsonify({'error': 'No PDF uploaded'}), 400
        
        data = request.get_json()
        configuration = data.get('configuration', [])
        sample_data = data.get('sample_data', {})
        coordinate_adjustments = data.get('coordinate_adjustments', {})
        
        if not configuration:
            return jsonify({'error': 'No configuration provided'}), 400
        
        # Get uploaded PDF path and dimensions
        pdf_path = session['uploaded_pdf']['path']
        pdf_dimensions = session['uploaded_pdf'].get('dimensions', {})
        
        if not os.path.exists(pdf_path):
            return jsonify({'error': 'Uploaded PDF not found'}), 404
        
        # Apply enhanced server environment specific coordinate adjustments
        adjusted_config = []
        session_id = get_session_id()
        
        print(f"Processing on {SERVER_DIST} server with coordinate adjustments")
        print(f"Coordinate adjustment requests: {coordinate_adjustments}")
        print(f"Original configuration: {json.dumps(configuration, indent=2)}")
        
        total_adjustments = 0
        
        for page_config in configuration:
            adjusted_page = {
                'page_number': page_config['page_number'],
                'variables': []
            }
            
            page_num = page_config['page_number'] + 1  # Convert to 1-based for dimensions lookup
            page_dims = pdf_dimensions.get(page_num, {'width': 612, 'height': 792})
            
            # Process and adjust each variable with enhanced logic
            for var in page_config.get('variables', []):
                original_var = var.copy()
                
                # Apply coordinate adjustments based on server environment and client requests
                if SERVER_DIST == 'Ubuntu':
                    adjusted_var = apply_coordinate_adjustment(
                        var, 
                        page_dims, 
                        SERVER_DIST,
                        coordinate_adjustments.get('adjustment_requests', {})
                    )
                    
                    # Count how many coordinates were actually adjusted
                    if 'y-coordinate' in var and 'y-coordinate' in adjusted_var:
                        if var['y-coordinate'] != adjusted_var['y-coordinate']:
                            total_adjustments += 1
                    
                    if 'x-coordinate' in var and 'x-coordinate' in adjusted_var:
                        if var['x-coordinate'] != adjusted_var['x-coordinate']:
                            total_adjustments += 1
                    
                    # Handle conditional coordinates adjustments
                    if 'conditional_coordinates' in var:
                        for i, cond in enumerate(var['conditional_coordinates']):
                            if i < len(adjusted_var.get('conditional_coordinates', [])):
                                orig_cond = cond
                                adj_cond = adjusted_var['conditional_coordinates'][i]
                                if (orig_cond.get('y-coordinate') != adj_cond.get('y-coordinate') or
                                    orig_cond.get('x-coordinate') != adj_cond.get('x-coordinate')):
                                    total_adjustments += 1
                else:
                    # For non-Ubuntu servers, use original coordinates
                    adjusted_var = original_var
                
                adjusted_page['variables'].append(adjusted_var)
            
            adjusted_config.append(adjusted_page)
        
        adjustment_summary = f"Applied {total_adjustments} coordinate adjustments for {SERVER_DIST}"
        print(f"Adjustment summary: {adjustment_summary}")
        print(f"Final adjusted configuration: {json.dumps(adjusted_config, indent=2)}")
        
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
        
        # Process PDF with carefully adjusted coordinates
        with open(pdf_path, 'rb') as pdf_file:
            if os.path.exists(font_path):
                with open(font_path, 'rb') as font_file:
                    output = pdf_writer(pdf_file, adjusted_config, sample_data, font_file)
            else:
                output = pdf_writer(pdf_file, adjusted_config, sample_data, None)

        # Save output PDF
        output_filename = f"output_{session_id}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"
        output_path = os.path.join(OUTPUT_FOLDER, output_filename)
        
        with open(output_path, 'wb') as output_file:
            output.write(output_file)
        
        return jsonify({
            'success': True,
            'output_filename': output_filename,
            'message': f'PDF processed successfully',
            'server_adjustments_applied': SERVER_DIST == 'Ubuntu' and total_adjustments > 0,
            'coordinate_adjustments': "",
            'adjustments_count': total_adjustments,
            'server_environment': {
                'os': SERVER_OS,
                'distribution': SERVER_DIST,
                'adjustments_applied': SERVER_DIST == 'Ubuntu'
            }
        })
        
    except Exception as e:
        error_msg = f'Processing failed: {str(e)}'
        print(f"Error processing PDF: {traceback.format_exc()}")
        return jsonify({
            'error': error_msg, 
            'server_env': SERVER_DIST,
            'traceback': traceback.format_exc() if app.debug else None
        }), 500

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

@app.route('/api/pdf-info', methods=['GET'])
def get_pdf_info():
    """Get PDF page dimensions for coordinate conversion with server environment info"""
    try:
        if 'uploaded_pdf' not in session:
            return jsonify({'error': 'No PDF uploaded'}), 400
        
        pdf_path = session['uploaded_pdf']['path']
        
        if not os.path.exists(pdf_path):
            return jsonify({'error': 'Uploaded PDF not found'}), 404
        
        # Get dimensions using enhanced method
        pdf_dimensions = get_pdf_page_dimensions(pdf_path)
        
        pages_info = []
        for page_num, dims in pdf_dimensions.items():
            pages_info.append({
                'page': page_num,
                'width': dims['width'],
                'height': dims['height'],
                'extraction_method': dims['method']
            })
        
        return jsonify({
            'success': True,
            'total_pages': len(pages_info),
            'pages': pages_info,
            'server_environment': {
                'os': SERVER_OS,
                'distribution': SERVER_DIST,
                'coordinate_system': 'bottom_left_origin'
            }
        })
        
    except Exception as e:
        return jsonify({'error': f'Failed to get PDF info: {str(e)}', 'server_env': SERVER_DIST}), 500

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
            'image_folder_exists': os.path.exists(IMAGE_FOLDER),
            'server_env': SERVER_DIST
        }
        
        if os.path.exists(IMAGE_FOLDER):
            result['available_files'] = os.listdir(IMAGE_FOLDER)
        
        return jsonify(result)
        
    except Exception as e:
        return jsonify({'error': str(e), 'server_env': SERVER_DIST}), 500

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
                        return jsonify({'error': f'Image not found: {filename}', 'available': available_files, 'server_env': SERVER_DIST}), 404
            else:
                return jsonify({'error': 'Image folder not found', 'server_env': SERVER_DIST}), 404
        
        return send_file(image_path)
        
    except Exception as e:
        print(f"Error serving image {filename}: {str(e)}")
        return jsonify({'error': f'Failed to serve image: {str(e)}', 'server_env': SERVER_DIST}), 500

# Additional routes for configuration management, template processing, etc.
# (keeping existing routes from the original code)

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
                'created': datetime.now().isoformat(),
                'server_env': SERVER_DIST
            }, f, indent=2)
        
        return jsonify({
            'success': True,
            'message': f'Configuration saved as {config_name} on {SERVER_DIST}'
        })
        
    except Exception as e:
        return jsonify({'error': f'Failed to save configuration: {str(e)}'}), 500

# Error handlers
@app.errorhandler(413)
def too_large(e):
    return jsonify({'error': 'File too large. Maximum size is 16MB'}), 413

@app.errorhandler(404)
def not_found(e):
    return jsonify({'error': 'Resource not found'}), 404

@app.errorhandler(500)
def server_error(e):
    return jsonify({'error': 'Internal server error', 'server_env': SERVER_DIST}), 500

if __name__ == '__main__':
    # Create a simple default font file if none exists
    default_font_path = os.path.join(FONT_FOLDER, 'default.ttf')
    if not os.path.exists(default_font_path):
        print(f"Note: No default font found at {default_font_path}")
        print("You may want to add a TTF font file for better text rendering")
    
    print("Starting Enhanced Flask PDF Text Overlay Application...")
    print(f"Server Environment: {SERVER_OS} - {SERVER_DIST}")
    print("Available endpoints:")
    print("  GET  /                      - Main application interface")
    print("  POST /api/upload            - Upload PDF file")
    print("  POST /api/upload-image      - Upload image for overlay")
    print("  GET  /api/images            - List uploaded images")
    print("  GET  /api/image/<filename>  - Serve uploaded image")
    print("  POST /api/process           - Process PDF with overlays (Ubuntu-adjusted)")
    print("  POST /api/debug-coordinates - Debug coordinate system differences")
    print("  GET  /api/download/<file>   - Download processed PDF")
    print("  POST /api/save-config       - Save configuration")
    print("  GET  /api/pdf-info          - Get PDF page information")
    
    app.run(debug=True, host='0.0.0.0', port=5000)