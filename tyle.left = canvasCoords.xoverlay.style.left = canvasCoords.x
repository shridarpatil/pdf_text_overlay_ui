[33mcommit cdb7ab3e335565426da2125ce579ec83124c5932[m[33m ([m[1;36mHEAD[m[33m -> [m[1;32mmaster[m[33m, [m[1;31morigin/master[m[33m, [m[1;31morigin/HEAD[m[33m)[m
Author: shridhar <shridhar.p@zerodha.com>
Date:   Mon Jun 2 13:39:04 2025 +0530

    fix: draw shapes and image support added

[1mdiff --git a/.gitignore b/.gitignore[m
[1mindex f0b0c39..12ee133 100644[m
[1m--- a/.gitignore[m
[1m+++ b/.gitignore[m
[36m@@ -1,2 +1,3 @@[m
 outputs/*.pdf[m
 uploads/*.pdf[m
[32m+[m[32mimages/*[m
[1mdiff --git a/app.py b/app.py[m
[1mindex 50fa64e..2f26271 100644[m
[1m--- a/app.py[m
[1m+++ b/app.py[m
[36m@@ -1,7 +1,7 @@[m
 """[m
[31m-Flask PDF Text Overlay Application[m
[31m-==================================[m
[31m-A complete web application for configuring and applying text overlays to PDF documents.[m
[32m+[m[32mEnhanced Flask PDF Text Overlay Application[m
[32m+[m[32m==========================================[m
[32m+[m[32mA complete web application for configuring and applying text overlays, images, and shapes to PDF documents.[m
 """[m
 [m
 from flask import Flask, render_template, request, jsonify, send_file, session[m
[36m@@ -13,6 +13,7 @@[m [mimport uuid[m
 from datetime import datetime[m
 import tempfile[m
 import traceback[m
[32m+[m[32mimport base64[m
 [m
 # Import the pdf_text_overlay library[m
 try:[m
[36m@@ -29,16 +30,23 @@[m [mapp.secret_key = 'your-secret-key-change-this-in-production'[m
 UPLOAD_FOLDER = 'uploads'[m
 OUTPUT_FOLDER = 'outputs'[m
 FONT_FOLDER = 'fonts'[m
[32m+[m[32mIMAGE_FOLDER = 'images'[m
 ALLOWED_EXTENSIONS = {'pdf'}[m
[32m+[m[32mALLOWED_IMAGE_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'bmp'}[m
 MAX_FILE_SIZE = 16 * 1024 * 1024  # 16MB[m
[32m+[m[32mMAX_IMAGE_SIZE = 10 * 1024 * 1024  # 10MB[m
 [m
 # Create necessary directories[m
[31m-for folder in [UPLOAD_FOLDER, OUTPUT_FOLDER, FONT_FOLDER]:[m
[32m+[m[32mfor folder in [UPLOAD_FOLDER, OUTPUT_FOLDER, FONT_FOLDER, IMAGE_FOLDER]:[m
     os.makedirs(folder, exist_ok=True)[m
 [m
[31m-def allowed_file(filename):[m
[32m+[m[32mdef allowed_file(filename, file_type='pdf'):[m
     """Check if file extension is allowed"""[m
[31m-    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS[m
[32m+[m[32m    if file_type == 'pdf':[m
[32m+[m[32m        return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS[m
[32m+[m[32m    elif file_type == 'image':[m
[32m+[m[32m        return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_IMAGE_EXTENSIONS[m
[32m+[m[32m    return False[m
 [m
 def get_session_id():[m
     """Get or create session ID"""[m
[36m@@ -62,7 +70,7 @@[m [mdef upload_pdf():[m
         if file.filename == '':[m
             return jsonify({'error': 'No file selected'}), 400[m
         [m
[31m-        if not allowed_file(file.filename):[m
[32m+[m[32m        if not allowed_file(file.filename, 'pdf'):[m
             return jsonify({'error': 'Invalid file type. Only PDF files are allowed'}), 400[m
         [m
         # Save file with session-specific name[m
[36m@@ -87,9 +95,108 @@[m [mdef upload_pdf():[m
     except Exception as e:[m
         return jsonify({'error': f'Upload failed: {str(e)}'}), 500[m
 [m
[32m+[m[32m@app.route('/api/upload-image', methods=['POST'])[m
[32m+[m[32mdef upload_image():[m
[32m+[m[32m    """Handle image file upload for overlays"""[m
[32m+[m[32m    try:[m
[32m+[m[32m        if 'image' not in request.files:[m
[32m+[m[32m            return jsonify({'error': 'No image uploaded'}), 400[m
[32m+[m[41m        [m
[32m+[m[32m        file = request.files['image'][m
[32m+[m[32m        if file.filename == '':[m
[32m+[m[32m            return jsonify({'error': 'No image selected'}), 400[m
[32m+[m[41m        [m
[32m+[m[32m        if not allowed_file(file.filename, 'image'):[m
[32m+[m[32m            return jsonify({'error': 'Invalid file type. Only image files are allowed'}), 400[m
[32m+[m[41m        [m
[32m+[m[32m        if file.content_length and file.content_length > MAX_IMAGE_SIZE:[m
[32m+[m[32m            return jsonify({'error': f'Image too large. Maximum size is {MAX_IMAGE_SIZE//1024//1024}MB'}), 400[m
[32m+[m[41m        [m
[32m+[m[32m        # Save image with session-specific name[m
[32m+[m[32m        session_id = get_session_id()[m
[32m+[m[32m        filename = secure_filename(file.filename)[m
[32m+[m[32m        image_path = os.path.join(IMAGE_FOLDER, f"{session_id}_{filename}")[m
[32m+[m[32m        file.save(image_path)[m
[32m+[m[41m        [m
[32m+[m[32m        # Store image info in session[m
[32m+[m[32m        if 'uploaded_images' not in session:[m
[32m+[m[32m            session['uploaded_images'] = [][m
[32m+[m[41m        [m
[32m+[m[32m        session['uploaded_images'].append({[m
[32m+[m[32m            'filename': filename,[m
[32m+[m[32m            'path': image_path,[m
[32m+[m[32m            'upload_time': datetime.now().isoformat()[m
[32m+[m[32m        })[m
[32m+[m[32m        session.modified = True[m
[32m+[m[41m        [m
[32m+[m[32m        return jsonify({[m
[32m+[m[32m            'success': True,[m
[32m+[m[32m            'filename': filename,[m
[32m+[m[32m            'message': 'Image uploaded successfully'[m
[32m+[m[32m        })[m
[32m+[m[41m        [m
[32m+[m[32m    except Exception as e:[m
[32m+[m[32m        return jsonify({'error': f'Image upload failed: {str(e)}'}), 500[m
[32m+[m
[32m+[m[32m@app.route('/api/images', methods=['GET'])[m
[32m+[m[32mdef list_images():[m
[32m+[m[32m    """List uploaded images for current session"""[m
[32m+[m[32m    try:[m
[32m+[m[32m        session_id = get_session_id()[m
[32m+[m[32m        images = session.get('uploaded_images', [])[m
[32m+[m[41m        [m
[32m+[m[32m        print(f"Current session ID: {session_id}")[m
[32m+[m[32m        print(f"Images in session: {len(images)}")[m
[32m+[m[41m        [m
[32m+[m[32m        # Filter images that still exist[m
[32m+[m[32m        valid_images = [][m
[32m+[m[32m        paths = [][m
[32m+[m[41m        [m
[32m+[m[32m        # If no images in session, try to find images by scanning the folder[m
[32m+[m[32m        if not images and os.path.exists(IMAGE_FOLDER):[m
[32m+[m[32m            available_files = os.listdir(IMAGE_FOLDER)[m
[32m+[m[32m            print(f"Scanning folder for images. Found files: {available_files}")[m
[32m+[m[41m            [m
[32m+[m[32m            for filename in available_files:[m
[32m+[m[32m                if filename.startswith(f"{session_id}_"):[m
[32m+[m[32m                    # Extract original filename[m
[32m+[m[32m                    original_name = filename[len(f"{session_id}_"):][m
[32m+[m[32m                    file_path = os.path.join(IMAGE_FOLDER, filename)[m
[32m+[m[41m                    [m
[32m+[m[32m                    valid_images.append({[m
[32m+[m[32m                        'filename': original_name,[m
[32m+[m[32m                        'upload_time': datetime.now().isoformat(),  # Default time[m
[32m+[m[32m                        'url': f'/api/image/{original_name}',[m
[32m+[m[32m                        'stored_path': file_path[m
[32m+[m[32m                    })[m
[32m+[m[32m        else:[m
[32m+[m[32m            # Use images from session[m
[32m+[m[32m            for img in images:[m
[32m+[m[32m                if os.path.exists(img['path']) and img['path'] not in paths:[m
[32m+[m[32m                    paths.append(img['path'])[m
[32m+[m[32m                    valid_images.append({[m
[32m+[m[32m                        'filename': img['filename'],[m
[32m+[m[32m                        'upload_time': img['upload_time'],[m
[32m+[m[32m                        'url': f'/api/image/{img["filename"]}',[m
[32m+[m[32m                        'stored_path': img['path'][m
[32m+[m[32m                    })[m
[32m+[m[32m                else:[m
[32m+[m[32m                    print(f"Image file not found: {img['path']}")[m
[32m+[m[41m        [m
[32m+[m[32m        print(f"Found {len(valid_images)} valid images")[m
[32m+[m[41m        [m
[32m+[m[32m        return jsonify({[m
[32m+[m[32m            'success': True,[m
[32m+[m[32m            'images': valid_images[m
[32m+[m[32m        })[m
[32m+[m[41m        [m
[32m+[m[32m    except Exception as e:[m
[32m+[m[32m        print(f"Error listing images: {str(e)}")[m
[32m+[m[32m        return jsonify({'error': f'Failed to list images: {str(e)}'}), 500[m
[32m+[m
 @app.route('/api/process', methods=['POST'])[m
 def process_pdf():[m
[31m-    """Process PDF with text overlays"""[m
[32m+[m[32m    """Process PDF with text overlays, images, and shapes"""[m
     try:[m
         if pdf_writer is None:[m
             return jsonify({'error': 'pdf_text_overlay library not installed'}), 500[m
[36m@@ -111,46 +218,153 @@[m [mdef process_pdf():[m
             return jsonify({'error': 'Uploaded PDF not found'}), 404[m
         [m
         # Convert coordinates from canvas to PDF coordinate system[m
[31m-        # The frontend sends 0-based page numbers which is correct for pdf_text_overlay[m
         converted_config = [][m
[32m+[m[32m        session_id = get_session_id()[m
[32m+[m[41m        [m
[32m+[m[32m        print(f"Processing configuration: {json.dumps(configuration, indent=2)}")  # Debug logging[m
[32m+[m[32m        print(f"Sample data: {json.dumps(sample_data, indent=2)}")  # Debug logging[m
[32m+[m[41m        [m
         for page_config in configuration:[m
             converted_page = {[m
[31m-                'page_number': page_config['page_number'],  # Already 0-based from frontend[m
[32m+[m[32m                'page_number': page_config['page_number'],[m
                 'variables': [][m
             }[m
             [m
[31m-            for var in page_config['variables']:[m
[31m-                if 'conditional_coordinates' in var:[m
[31m-                    # Handle conditional coordinates[m
[32m+[m[32m            # Process text variables[m
[32m+[m[32m            for var in page_config.get('variables', []):[m
[32m+[m[32m                if var.get('name') == 'draw_shape' and 'draw_shape' in var:[m
[32m+[m[32m                    # Handle draw_shape variables - pass through as-is[m
[32m+[m[32m                    converted_page['variables'].append(var)[m
[32m+[m[32m                elif 'image' in var:[m
[32m+[m[32m                    # Handle image variables - pass through as-is[m
[32m+[m[32m                    converted_page['variables'].append(var)[m
[32m+[m[32m                elif 'conditional_coordinates' in var:[m
[32m+[m[32m                    # Handle conditional text variables[m
                     converted_var = {[m
                         'name': var['name'],[m
                         'conditional_coordinates': var['conditional_coordinates'][m
                     }[m
[31m-                else:[m
[31m-                    # Handle simple coordinates[m
[32m+[m[32m                    converted_page['variables'].append(converted_var)[m
[32m+[m[32m                elif 'x-coordinate' in var and 'y-coordinate' in var:[m
[32m+[m[32m                    # Handle simple text variables[m
                     converted_var = {[m
                         'name': var['name'],[m
                         'x-coordinate': var['x-coordinate'],[m
                         'y-coordinate': var['y-coordinate'],[m
                         'font_size': var.get('font_size', 12)[m
                     }[m
[31m-                converted_page['variables'].append(converted_var)[m
[32m+[m[32m                    converted_page['variables'].append(converted_var)[m
[32m+[m[41m            [m
[32m+[m[32m            # Process images (convert to image variables)[m
[32m+[m[32m            for img in page_config.get('images', []):[m
[32m+[m[32m                converted_img = {[m
[32m+[m[32m                    'name': img['name'],[m
[32m+[m[32m                    'image': {[m
[32m+[m[32m                        'x-coordinate': img['x-coordinate'],[m
[32m+[m[32m                        'y-coordinate': img['y-coordinate'],[m
[32m+[m[32m                        'width': img.get('width', 100),[m
[32m+[m[32m                        'height': img.get('height', 100)[m
[32m+[m[32m                    }[m
[32m+[m[32m                }[m
[32m+[m[32m                converted_page['variables'].append(converted_img)[m
[32m+[m[41m            [m
[32m+[m[32m            # Process shapes (convert to draw_shape variables)[m
[32m+[m[32m            for shape in page_config.get('shapes', []):[m
[32m+[m[32m                try:[m
[32m+[m[32m                    # Convert RGB hex color to individual components[m
[32m+[m[32m                    color_hex = shape.get('color', '#000000').replace('#', '')[m
[32m+[m[32m                    if len(color_hex) != 6:[m
[32m+[m[32m                        color_hex = '000000'  # Default to black if invalid[m
[32m+[m[41m                    [m
[32m+[m[32m                    r = int(color_hex[0:2], 16) / 255.0[m
[32m+[m[32m                    g = int(color_hex[2:4], 16) / 255.0[m
[32m+[m[32m                    b = int(color_hex[4:6], 16) / 255.0[m
[32m+[m[41m                    [m
[32m+[m[32m                    # Convert PDF coordinates to inches (assuming 72 DPI) with defaults[m
[32m+[m[32m                    x0 = shape.get('x-coordinate', 0)[m
[32m+[m[32m                    y0 = shape.get('y-coordinate', 0)[m
[32m+[m[32m                    x0_inches = float(x0) / 72.0 if x0 is not None else 0.0[m
[32m+[m[32m                    y0_inches = float(y0) / 72.0 if y0 is not None else 0.0[m
[32m+[m[41m                    [m
[32m+[m[32m                    shape_config = {[m
[32m+[m[32m                        'name': 'draw_shape',[m
[32m+[m[32m                        'draw_shape': {[m
[32m+[m[32m                            'r': round(r, 3),[m
[32m+[m[32m                            'g': round(g, 3),[m
[32m+[m[32m                            'b': round(b, 3),[m
[32m+[m[32m                            'shape': str(shape.get('type', 'rectangle')).capitalize(),[m
[32m+[m[32m                            'x0-coordinate': round(x0_inches, 3),[m
[32m+[m[32m                            'y0-coordinate': round(y0_inches, 3)[m
[32m+[m[32m                        }[m
[32m+[m[32m                    }[m
[32m+[m[41m                    [m
[32m+[m[32m                    # Add shape-specific coordinates with proper validation[m
[32m+[m[32m                    shape_type = shape.get('type', 'rectangle').lower()[m
[32m+[m[32m                    if shape_type == 'rectangle':[m
[32m+[m[32m                        width = float(shape.get('width', 50))[m
[32m+[m[32m                        height = float(shape.get('height', 50))[m
[32m+[m[32m                        x1_inches = (x0 + width) / 72.0[m
[32m+[m[32m                        y1_inches = (y0 + height) / 72.0[m
[32m+[m[32m                        shape_config['draw_shape']['x1-coordinate'] = round(x1_inches, 3)[m
[32m+[m[32m                        shape_config['draw_shape']['y1-coordinate'] = round(y1_inches, 3)[m
[32m+[m[32m                    elif shape_type == 'circle':[m
[32m+[m[32m                        radius = float(shape.get('radius', 25))[m
[32m+[m[32m                        radius_inches = radius / 72.0[m
[32m+[m[32m                        x1_inches = x0_inches + radius_inches[m
[32m+[m[32m                        y1_inches = y0_inches + radius_inches[m
[32m+[m[32m                        shape_config['draw_shape']['x1-coordinate'] = round(x1_inches, 3)[m
[32m+[m[32m                        shape_config['draw_shape']['y1-coordinate'] = round(y1_inches, 3)[m
[32m+[m[32m                    elif shape_type == 'line':[m
[32m+[m[32m                        end_x = float(shape.get('end_x', x0 + 50))[m
[32m+[m[32m                        end_y = float(shape.get('end_y', y0))[m
[32m+[m[32m                        x1_inches = end_x / 72.0[m
[32m+[m[32m                        y1_inches = end_y / 72.0[m
[32m+[m[32m                        shape_config['draw_shape']['x1-coordinate'] = round(x1_inches, 3)[m
[32m+[m[32m                        shape_config['draw_shape']['y1-coordinate'] = round(y1_inches, 3)[m
[32m+[m[41m                    [m
[32m+[m[32m                    converted_page['variables'].append(shape_config)[m
[32m+[m[41m                    [m
[32m+[m[32m                except (ValueError, TypeError, KeyError) as e:[m
[32m+[m[32m                    print(f"Error processing shape: {e}. Skipping shape: {shape}")[m
[32m+[m[32m                    continue[m
             [m
             converted_config.append(converted_page)[m
         [m
[31m-        # Default font (you can add custom font upload functionality)[m
[31m-        font_path = None  # Will use default font if None[m
[32m+[m[32m        print(f"Converted configuration: {json.dumps(converted_config, indent=2)}")  # Debug logging[m
[32m+[m[41m        [m
[32m+[m[32m        # Validate image URLs in sample data before processing[m
[32m+[m[32m        for key, value in sample_data.items():[m
[32m+[m[32m            if isinstance(value, str) and value.startswith(('http://', 'https://')):[m
[32m+[m[32m                if '/api/image/' in value:[m
[32m+[m[32m                    # Extract filename from URL[m
[32m+[m[32m                    filename = value.split('/api/image/')[-1][m
[32m+[m[32m                    session_id = get_session_id()[m
[32m+[m[32m                    image_path = os.path.join(IMAGE_FOLDER, f"{session_id}_{filename}")[m
[32m+[m[41m                    [m
[32m+[m[32m                    if not os.path.exists(image_path):[m
[32m+[m[32m                        # Try fallback path[m
[32m+[m[32m                        fallback_path = os.path.join(IMAGE_FOLDER, filename)[m
[32m+[m[32m                        if not os.path.exists(fallback_path):[m
[32m+[m[32m                            print(f"Warning: Image not found for key '{key}': {image_path}")[m
[32m+[m[32m                            # List available files for debugging[m
[32m+[m[32m                            if os.path.exists(IMAGE_FOLDER):[m
[32m+[m[32m                                available_files = os.listdir(IMAGE_FOLDER)[m
[32m+[m[32m                                print(f"Available image files: {available_files}")[m
[32m+[m[32m                    else:[m
[32m+[m[32m                        print(f"Image found for key '{key}': {image_path}")[m
[32m+[m[41m        [m
[32m+[m[32m        # Default font[m
         font_path = os.path.join(FONT_FOLDER, 'default.ttf')[m
[32m+[m[41m        [m
         # Process PDF[m
         with open(pdf_path, 'rb') as pdf_file:[m
[31m-            if font_path and os.path.exists(font_path):[m
[32m+[m[32m            if os.path.exists(font_path):[m
                 with open(font_path, 'rb') as font_file:[m
                     output = pdf_writer(pdf_file, converted_config, sample_data, font_file)[m
             else:[m
                 output = pdf_writer(pdf_file, converted_config, sample_data, None)[m
 [m
         # Save output PDF[m
[31m-        session_id = get_session_id()[m
         output_filename = f"output_{session_id}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"[m
         output_path = os.path.join(OUTPUT_FOLDER, output_filename)[m
         [m
[36m@@ -286,6 +500,74 @@[m [mdef get_pdf_info():[m
         [m
     except Exception as e:[m
         return jsonify({'error': f'Failed to get PDF info: {str(e)}'}), 500[m
[32m+[m
[32m+[m[32m@app.route('/api/test-image/<filename>')[m
[32m+[m[32mdef test_image(filename):[m
[32m+[m[32m    """Test if an image is accessible"""[m
[32m+[m[32m    try:[m
[32m+[m[32m        session_id = get_session_id()[m
[32m+[m[32m        image_path = os.path.join(IMAGE_FOLDER, f"{session_id}_{filename}")[m
[32m+[m[41m        [m
[32m+[m[32m        result = {[m
[32m+[m[32m            'filename': filename,[m
[32m+[m[32m            'session_id': session_id,[m
[32m+[m[32m            'expected_path': image_path,[m
[32m+[m[32m            'exists': os.path.exists(image_path),[m
[32m+[m[32m            'image_folder_exists': os.path.exists(IMAGE_FOLDER)[m
[32m+[m[32m        }[m
[32m+[m[41m        [m
[32m+[m[32m        if os.path.exists(IMAGE_FOLDER):[m
[32m+[m[32m            result['available_files'] = os.listdir(IMAGE_FOLDER)[m
[32m+[m[41m        [m
[32m+[m[32m        return jsonify(result)[m
[32m+[m[41m        [m
[32m+[m[32m    except Exception as e:[m
[32m+[m[32m        return jsonify({'error': str(e)}), 500[m
[32m+[m
[32m+[m[32m@app.route('/api/image/<filename>')[m
[32m+[m[32mdef serve_image(filename):[m
[32m+[m[32m    """Serve uploaded images"""[m
[32m+[m[32m    try:[m
[32m+[m[32m        session_id = get_session_id()[m
[32m+[m[41m        [m
[32m+[m[32m        # First try with current session ID[m
[32m+[m[32m        image_path = os.path.join(IMAGE_FOLDER, f"{session_id}_{filename}")[m
[32m+[m[41m        [m
[32m+[m[32m        print(f"Current session ID: {session_id}")[m
[32m+[m[32m        print(f"Looking for image at: {image_path}")[m
[32m+[m[32m        print(f"File exists: {os.path.exists(image_path)}")[m
[32m+[m[41m        [m
[32m+[m[32m        if not os.path.exists(image_path):[m
[32m+[m[32m            # Try to find the image with any session ID[m
[32m+[m[32m            if os.path.exists(IMAGE_FOLDER):[m
[32m+[m[32m                available_files = os.listdir(IMAGE_FOLDER)[m
[32m+[m[32m                print(f"Available files: {available_files}")[m
[32m+[m[41m                [m
[32m+[m[32m                # Look for files that end with the requested filename[m
[32m+[m[32m                matching_files = [f for f in available_files if f.endswith(f"_{filename}")][m
[32m+[m[41m                [m
[32m+[m[32m                if matching_files:[m
[32m+[m[32m                    # Use the first matching file[m
[32m+[m[32m                    image_path = os.path.join(IMAGE_FOLDER, matching_files[0])[m
[32m+[m[32m                    print(f"Found matching file: {image_path}")[m
[32m+[m[32m                else:[m
[32m+[m[32m                    # Try direct filename (fallback)[m
[32m+[m[32m                    fallback_path = os.path.join(IMAGE_FOLDER, filename)[m
[32m+[m[32m                    if os.path.exists(fallback_path):[m
[32m+[m[32m                        image_path = fallback_path[m
[32m+[m[32m                        print(f"Using fallback path: {image_path}")[m
[32m+[m[32m                    else:[m
[32m+[m[32m                        print(f"No matching files found for: {filename}")[m
[32m+[m[32m                        return jsonify({'error': f'Image not found: {filename}', 'available': available_files}), 404[m
[32m+[m[32m            else:[m
[32m+[m[32m                return jsonify({'error': 'Image folder not found'}), 404[m
[32m+[m[41m        [m
[32m+[m[32m        return send_file(image_path)[m
[32m+[m[41m        [m
[32m+[m[32m    except Exception as e:[m
[32m+[m[32m        print(f"Error serving image {filename}: {str(e)}")[m
[32m+[m[32m        return jsonify({'error': f'Failed to serve image: {str(e)}'}), 500[m
[32m+[m[32mdef load_config(config_name):[m
     """Load saved configuration"""[m
     try:[m
         session_id = get_session_id()[m
[36m@@ -322,14 +604,18 @@[m [mif __name__ == '__main__':[m
         print(f"Note: No default font found at {default_font_path}")[m
         print("You may want to add a TTF font file for better text rendering")[m
     [m
[31m-    print("Starting Flask PDF Text Overlay Application...")[m
[32m+[m[32m    print("Starting Enhanced Flask PDF Text Overlay Application...")[m
     print("Available endpoints:")[m
[31m-    print("  GET  /                    - Main application interface")[m
[31m-    print("  POST /api/upload          - Upload PDF file")[m
[31m-    print("  POST /api/process         - Process PDF with overlays")[m
[31m-    print("  POST /api/template        - Process HTML template to PDF")[m
[31m-    print("  GET  /api/download/<file> - Download processed PDF")[m
[31m-    print("  POST /api/save-config     - Save configuration")[m
[31m-    print("  GET  /api/load-config     - Load saved configuration")[m
[32m+[m[32m    print("  GET  /                     - Main application interface")[m
[32m+[m[32m    print("  POST /api/upload           - Upload PDF file")[m
[32m+[m[32m    print("  POST /api/upload-image     - Upload image for overlay")[m
[32m+[m[32m    print("  GET  /api/images           - List uploaded images")[m
[32m+[m[32m    print("  GET  /api/image/<filename>   - Serve uploaded image")[m
[32m+[m[32m    print("  POST /api/process          - Process PDF with overlays, images, and shapes")[m
[32m+[m[32m    print("  POST /api/template         - Process HTML template to PDF")[m
[32m+[m[32m    print("  GET  /api/download/<file>  - Download processed PDF")[m
[32m+[m[32m    print("  POST /api/save-config      - Save configuration")[m
[32m+[m[32m    print("  GET  /api/load-config      - Load saved configuration")[m
[32m+[m[32m    print("  GET  /api/pdf-info         - Get PDF page information")[m
     [m
     app.run(debug=True, host='0.0.0.0', port=5000)[m
\ No newline at end of file[m
[1mdiff --git a/templates/index.html b/templates/index.html[m
[1mindex 8562067..dbf7de2 100644[m
[1m--- a/templates/index.html[m
[1m+++ b/templates/index.html[m
[36m@@ -3,7 +3,7 @@[m
 <head>[m
     <meta charset="UTF-8">[m
     <meta name="viewport" content="width=device-width, initial-scale=1.0">[m
[31m-    <title>PDF Text Overlay Tool</title>[m
[32m+[m[32m    <title>Enhanced PDF Text Overlay Tool</title>[m
     <script src="https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.min.js"></script>[m
     <style>[m
         * {[m
[36m@@ -148,6 +148,32 @@[m
             z-index: 1000;[m
         }[m
 [m
[32m+[m[32m        .image-overlay {[m
[32m+[m[32m            position: absolute;[m
[32m+[m[32m            background: rgba(76, 175, 80, 0.8);[m
[32m+[m[32m            color: white;[m
[32m+[m[32m            padding: 2px 6px;[m
[32m+[m[32m            border-radius: 3px;[m
[32m+[m[32m            font-size: 12px;[m
[32m+[m[32m            pointer-events: none;[m
[32m+[m[32m            transform: translate(-50%, -100%);[m
[32m+[m[32m            white-space: nowrap;[m
[32m+[m[32m            z-index: 1000;[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .shape-overlay {[m
[32m+[m[32m            position: absolute;[m
[32m+[m[32m            background: rgba(255, 152, 0, 0.8);[m
[32m+[m[32m            color: white;[m
[32m+[m[32m            padding: 2px 6px;[m
[32m+[m[32m            border-radius: 3px;[m
[32m+[m[32m            font-size: 12px;[m
[32m+[m[32m            pointer-events: none;[m
[32m+[m[32m            transform: translate(-50%, -100%);[m
[32m+[m[32m            white-space: nowrap;[m
[32m+[m[32m            z-index: 1000;[m
[32m+[m[32m        }[m
[32m+[m
         .coordinate-dot {[m
             position: absolute;[m
             width: 8px;[m
[36m@@ -166,6 +192,14 @@[m
             background-color: #ff9800;[m
         }[m
 [m
[32m+[m[32m        .coordinate-dot.image {[m
[32m+[m[32m            background-color: #4caf50;[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .coordinate-dot.shape {[m
[32m+[m[32m            background-color: #ff9800;[m
[32m+[m[32m        }[m
[32m+[m
         /* Configuration Section */[m
         .config-section {[m
             flex: 1;[m
[36m@@ -270,12 +304,20 @@[m
             background: linear-gradient(135deg, #dc3545 0%, #c82333 100%);[m
         }[m
 [m
[32m+[m[32m        .btn-warning {[m
[32m+[m[32m            background: linear-gradient(135deg, #ffc107 0%, #ff8c00 100%);[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .btn-info {[m
[32m+[m[32m            background: linear-gradient(135deg, #17a2b8 0%, #138496 100%);[m
[32m+[m[32m        }[m
[32m+[m
         .btn-block {[m
             width: 100%;[m
             margin-bottom: 10px;[m
         }[m
 [m
[31m-        .variable-item {[m
[32m+[m[32m        .variable-item, .image-item, .shape-item {[m
             background: white;[m
             border: 1px solid #dee2e6;[m
             border-radius: 8px;[m
[36m@@ -284,7 +326,15 @@[m
             position: relative;[m
         }[m
 [m
[31m-        .variable-header {[m
[32m+[m[32m        .image-item {[m
[32m+[m[32m            border-left: 4px solid #4caf50;[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .shape-item {[m
[32m+[m[32m            border-left: 4px solid #ff9800;[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .variable-header, .image-header, .shape-header {[m
             display: flex;[m
             justify-content: space-between;[m
             align-items: center;[m
[36m@@ -383,6 +433,85 @@[m
             display: block;[m
         }[m
 [m
[32m+[m[32m        .mode-selector {[m
[32m+[m[32m            display: flex;[m
[32m+[m[32m            gap: 10px;[m
[32m+[m[32m            margin-bottom: 15px;[m
[32m+[m[32m            background: #e9ecef;[m
[32m+[m[32m            padding: 5px;[m
[32m+[m[32m            border-radius: 8px;[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .mode-btn {[m
[32m+[m[32m            flex: 1;[m
[32m+[m[32m            padding: 8px 12px;[m
[32m+[m[32m            border: none;[m
[32m+[m[32m            background: transparent;[m
[32m+[m[32m            border-radius: 5px;[m
[32m+[m[32m            cursor: pointer;[m
[32m+[m[32m            font-size: 0.9rem;[m
[32m+[m[32m            transition: all 0.3s ease;[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .mode-btn.active {[m
[32m+[m[32m            background: #667eea;[m
[32m+[m[32m            color: white;[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .image-upload-area {[m
[32m+[m[32m            border: 2px dashed #4caf50;[m
[32m+[m[32m            padding: 20px;[m
[32m+[m[32m            text-align: center;[m
[32m+[m[32m            border-radius: 8px;[m
[32m+[m[32m            margin-bottom: 15px;[m
[32m+[m[32m            cursor: pointer;[m
[32m+[m[32m            transition: all 0.3s ease;[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .image-upload-area:hover {[m
[32m+[m[32m            background: rgba(76, 175, 80, 0.1);[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .image-list {[m
[32m+[m[32m            max-height: 150px;[m
[32m+[m[32m            overflow-y: auto;[m
[32m+[m[32m            border: 1px solid #dee2e6;[m
[32m+[m[32m            border-radius: 5px;[m
[32m+[m[32m            padding: 10px;[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .image-item-small {[m
[32m+[m[32m            display: flex;[m
[32m+[m[32m            justify-content: space-between;[m
[32m+[m[32m            align-items: center;[m
[32m+[m[32m            padding: 5px;[m
[32m+[m[32m            border-bottom: 1px solid #eee;[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .shape-preview {[m
[32m+[m[32m            width: 30px;[m
[32m+[m[32m            height: 30px;[m
[32m+[m[32m            border: 2px solid #ff9800;[m
[32m+[m[32m            display: inline-block;[m
[32m+[m[32m            margin-right: 10px;[m
[32m+[m[32m            vertical-align: middle;[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .shape-preview.rectangle {[m
[32m+[m[32m            border-radius: 0;[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .shape-preview.circle {[m
[32m+[m[32m            border-radius: 50%;[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .shape-preview.line {[m
[32m+[m[32m            border: none;[m
[32m+[m[32m            border-top: 2px solid #ff9800;[m
[32m+[m[32m            height: 0;[m
[32m+[m[32m            margin-top: 15px;[m
[32m+[m[32m        }[m
[32m+[m
         @media (max-width: 1200px) {[m
             .main-container {[m
                 flex-direction: column;[m
[36m@@ -398,8 +527,8 @@[m
 </head>[m
 <body>[m
     <div class="header">[m
[31m-        <h1>🚀 PDF Text Overlay Tool</h1>[m
[31m-        <p>Upload, configure, and process PDF text overlays with real-time preview</p>[m
[32m+[m[32m        <h1>🚀 Enhanced PDF Overlay Tool</h1>[m
[32m+[m[32m        <p>Upload, configure, and process PDF with text, images, and shapes overlays</p>[m
     </div>[m
 [m
     <div class="main-container">[m
[36m@@ -423,12 +552,15 @@[m
                 </div>[m
             </div>[m
 [m
[31m-            <div class="pdf-viewer" id="pdfViewer">[m
[32m+[m[32m                            <div class="pdf-viewer" id="pdfViewer">[m
                 <div class="click-instruction">[m
[31m-                    💡 <strong>Click the CENTER of checkboxes or text fields</strong>[m
[31m-                    <br><small>The tool automatically adjusts coordinates for proper text positioning</small>[m
[31m-                    <br><small>Blue overlays = Simple variables | Orange overlays = Conditional coordinates</small>[m
[31m-                    <br><small>Hold <strong>Ctrl/Cmd</strong> + Click to add conditional coordinate to selected variable</small>[m
[32m+[m[32m                    🎯 <strong>Current Mode: <span id="currentMode">Text</span></strong>[m
[32m+[m[32m                    <br><small id="modeInstructions">💡 Click to add text variables | 🖼️ Click to place images | 🔲 Click to draw shapes</small>[m
[32m+[m[32m                    <br><small>Blue = Text | Green = Images | Orange = Shapes</small>[m
[32m+[m[32m                    <br><small>Hold <strong>Ctrl/Cmd</strong> + Click to add conditional coordinates to text variables</small>[m
[32m+[m[32m                    <div id="lineDrawingControls" style="display: none; margin-top: 10px;">[m
[32m+[m[32m                        <button class="btn btn-secondary" id="cancelLineBtn" style="padding: 5px 10px; font-size: 0.8rem;">❌ Cancel Line Drawing</button>[m
[32m+[m[32m                    </div>[m
                 </div>[m
                 <canvas id="pdfCanvas" class="pdf-canvas"></canvas>[m
             </div>[m
[36m@@ -445,6 +577,34 @@[m
             </div>[m
             [m
             <div class="config-content">[m
[32m+[m[32m                <!-- Mode Selector -->[m
[32m+[m[32m                <div class="section">[m
[32m+[m[32m                    <h3>🎯 Editing Mode</h3>[m
[32m+[m[32m                    <div class="mode-selector">[m
[32m+[m[32m                        <button class="mode-btn active" id="textMode" onclick="setMode('text')">📝 Text</button>[m
[32m+[m[32m                        <button class="mode-btn" id="imageMode" onclick="setMode('image')">🖼️ Images</button>[m
[32m+[m[32m                        <button class="mode-btn" id="shapeMode" onclick="setMode('shape')">🔲 Shapes</button>[m
[32m+[m[32m                    </div>[m
[32m+[m[32m                    <div id="modeInstructions" class="click-instruction">[m
[32m+[m[32m                        <strong>Text Mode:</strong> Click on the PDF to add text variables at specific positions.[m
[32m+[m[32m                    </div>[m
[32m+[m[32m                </div>[m
[32m+[m
[32m+[m[32m                <!-- Image Upload Section -->[m
[32m+[m[32m                <div class="section" id="imageUploadSection" style="display: none;">[m
[32m+[m[32m                    <h3>🖼️ Image Upload</h3>[m
[32m+[m[32m                    <div class="image-upload-area" id="imageUploadArea">[m
[32m+[m[32m                        <div>📷 Click to upload images (PNG, JPG, GIF)</div>[m
[32m+[m[32m                        <input type="file" id="imageInput" accept=".png,.jpg,.jpeg,.gif,.bmp" multiple style="display: none;">[m
[32m+[m[32m                    </div>[m
[32m+[m[32m                    <div style="display: flex; gap: 10px; margin-bottom: 10px;">[m
[32m+[m[32m                        <button class="btn btn-info" onclick="refreshImageList()" style="flex: 1;">🔄 Refresh Images</button>[m
[32m+[m[32m                    </div>[m
[32m+[m[32m                    <div id="imageList" class="image-list">[m
[32m+[m[32m                        <div>No images uploaded yet</div>[m
[32m+[m[32m                    </div>[m
[32m+[m[32m                </div>[m
[32m+[m
                 <!-- Sample Data Section -->[m
                 <div class="section">[m
                     <h3>📝 Sample Data</h3>[m
[36m@@ -469,15 +629,30 @@[m
                     <button class="btn btn-secondary btn-block" id="addVariableBtn">+ Add Variable</button>[m
                 </div>[m
 [m
[32m+[m[32m                <!-- Images Section -->[m
[32m+[m[32m                <div class="section">[m
[32m+[m[32m                    <h3>🖼️ Image Overlays</h3>[m
[32m+[m[32m                    <div id="imagesList">[m
[32m+[m[32m                        <!-- Images will be added here dynamically -->[m
[32m+[m[32m                    </div>[m
[32m+[m[32m                </div>[m
[32m+[m
[32m+[m[32m                <!-- Shapes Section -->[m
[32m+[m[32m                <div class="section">[m
[32m+[m[32m                    <h3>🔲 Shape Overlays</h3>[m
[32m+[m[32m                    <div id="shapesList">[m
[32m+[m[32m                        <!-- Shapes will be added here dynamically -->[m
[32m+[m[32m                    </div>[m
[32m+[m[32m                </div>[m
[32m+[m
                 <!-- Processing Section -->[m
                 <div class="section">[m
                     <h3>🔧 Process PDF</h3>[m
                     <div style="background: #fff3cd; padding: 10px; border-radius: 5px; margin-bottom: 10px; font-size: 0.85rem;">[m
[31m-                        🎯 <strong>Coordinate Tips:</strong> Click the center of checkboxes/fields. The tool automatically adjusts for text baseline positioning.[m
[31m-                        <br>• Blue dots = Simple text positions | Orange dots = Conditional positions[m
[31m-                        <br>• If text is still off, fine-tune coordinates by ±2-5 points in variable settings[m
[32m+[m[32m                        🎯 <strong>Tips:</strong> Click the center of elements for precise positioning. Different modes place different overlay types.[m
[32m+[m[32m                        <br>• Blue dots = Text positions | Green dots = Image positions | Orange dots = Shape positions[m
                     </div>[m
[31m-                    <button class="btn btn-block" id="processBtn" disabled>🚀 Process PDF with Overlays</button>[m
[32m+[m[32m                    <button class="btn btn-block" id="processBtn" disabled>🚀 Process PDF with All Overlays</button>[m
                     <div class="loading" id="processLoading">[m
                         <div>⚙️ Processing PDF...</div>[m
                     </div>[m
[36m@@ -491,16 +666,18 @@[m
                     <h3>📋 Generated Configuration</h3>[m
                     <div style="background: #e3f2fd; padding: 10px; border-radius: 5px; margin-bottom: 10px; font-size: 0.85rem;">[m
                         💡 <strong>Note:</strong> Page numbers in config are 0-based (Page 1 → 0, Page 2 → 1, etc.)[m
[31m-                        <br>📝 You can edit the configuration directly below - changes will be applied when you click "Load from Config"[m
[32m+[m[32m                        <br>📝 Shapes are converted to draw_shape variables with coordinates in inches (72 DPI conversion)[m
[32m+[m[32m                        <br>🎨 Colors are converted to RGB values (0.0-1.0) in the draw_shape format[m
                     </div>[m
                     <div class="form-group">[m
                         <label>Configuration JSON (Editable):</label>[m
[31m-                        <textarea class="config-output" id="configOutput" contenteditable="true">Click on the PDF to start adding variables...</textarea>[m
[32m+[m[32m                        <textarea class="config-output" id="configOutput" contenteditable="true">Click on the PDF to start adding elements...</textarea>[m
                     </div>[m
                     <div style="display: flex; gap: 10px; margin-top: 15px; flex-wrap: wrap;">[m
                         <button class="btn" id="copyConfigBtn" style="flex: 1; min-width: 120px;">📋 Copy Config</button>[m
                         <button class="btn btn-secondary" id="saveConfigBtn" style="flex: 1; min-width: 120px;">💾 Save Config</button>[m
                         <button class="btn btn-success" id="loadFromConfigBtn" style="flex: 1; min-width: 140px;">📥 Load from Config</button>[m
[32m+[m[32m                        <button class="btn btn-info" id="testImagesBtn" style="flex: 1; min-width: 120px;">🔍 Test Images</button>[m
                     </div>[m
                 </div>[m
             </div>[m
[36m@@ -518,11 +695,16 @@[m
         let pdfCanvas = null;[m
         let pdfCtx = null;[m
         let variables = [];[m
[32m+[m[32m        let images = [];[m
[32m+[m[32m        let shapes = [];[m
         let scale = 1.5;[m
         let pdfUploaded = false;[m
         let processedFilename = null;[m
         let pdfPageDimensions = {};[m
[31m-        let selectedVariableForConditional = -1;[m
[32m+[m[32m        let currentMode = 'text'; // text, image, shape[m
[32m+[m[32m        let uploadedImages = [];[m
[32m+[m[32m        let lineDrawingState = null; // null, 'waiting_for_start', 'waiting_for_end'[m
[32m+[m[32m        let tempLineStart = null; // stores start point for line drawing[m
 [m
         // Initialize PDF.js[m
         pdfjsLib.GlobalWorkerOptions.workerSrc = 'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.worker.min.js';[m
[36m@@ -538,6 +720,8 @@[m
         const prevPageBtn = document.getElementById('prevPage');[m
         const nextPageBtn = document.getElementById('nextPage');[m
         const variablesList = document.getElementById('variablesList');[m
[32m+[m[32m        const imagesList = document.getElementById('imagesList');[m
[32m+[m[32m        const shapesList = document.getElementById('shapesList');[m
         const addVariableBtn = document.getElementById('addVariableBtn');[m
         const configOutput = document.getElementById('configOutput');[m
         const copyConfigBtn = document.getElementById('copyConfigBtn');[m
[36m@@ -551,6 +735,15 @@[m
         const processLoading = document.getElementById('processLoading');[m
         const downloadSection = document.getElementById('downloadSection');[m
         const notification = document.getElementById('notification');[m
[32m+[m[32m        const imageUploadArea = document.getElementById('imageUploadArea');[m
[32m+[m[32m        const imageInput = document.getElementById('imageInput');[m
[32m+[m[32m        const imageList = document.getElementById('imageList');[m
[32m+[m[32m        const imageUploadSection = document.getElementById('imageUploadSection');[m
[32m+[m[32m        const currentModeSpan = document.getElementById('currentMode');[m
[32m+[m[32m        const modeInstructions = document.getElementById('modeInstructions');[m
[32m+[m[32m        const cancelLineBtn = document.getElementById('cancelLineBtn');[m
[32m+[m[32m        const lineDrawingControls = document.getElementById('lineDrawingControls');[m
[32m+[m[32m        const testImagesBtn = document.getElementById('testImagesBtn');[m
 [m
         // Event listeners[m
         uploadArea.addEventListener('click', () => pdfInput.click());[m
[36m@@ -567,6 +760,72 @@[m
         prefillBtn.addEventListener('click', prefillSampleData);[m
         processBtn.addEventListener('click', processDocument);[m
         downloadBtn.addEventListener('click', downloadProcessedPDF);[m
[32m+[m[32m        imageUploadArea.addEventListener('click', () => imageInput.click());[m
[32m+[m[32m        imageInput.addEventListener('change', handleImageUpload);[m
[32m+[m[32m        cancelLineBtn.addEventListener('click', cancelLineDrawing);[m
[32m+[m[32m        testImagesBtn.addEventListener('click', testImageAccessibility);[m
[32m+[m
[32m+[m[32m        // Mode management[m
[32m+[m[32m        function setMode(mode) {[m
[32m+[m[32m            // Reset line drawing state when switching modes[m
[32m+[m[32m            if (currentMode === 'shape' && lineDrawingState) {[m
[32m+[m[32m                lineDrawingState = null;[m
[32m+[m[32m                tempLineStart = null;[m
[32m+[m[32m                removeTemporaryLinePoints();[m
[32m+[m[32m            }[m
[32m+[m[41m            [m
[32m+[m[32m            currentMode = mode;[m
[32m+[m[41m            [m
[32m+[m[32m            // Update UI[m
[32m+[m[32m            document.querySelectorAll('.mode-btn').forEach(btn => btn.classList.remove('active'));[m
[32m+[m[32m            document.getElementById(mode + 'Mode').classList.add('active');[m
[32m+[m[41m            [m
[32m+[m[32m            currentModeSpan.textContent = mode.charAt(0).toUpperCase() + mode.slice(1);[m
[32m+[m[41m            [m
[32m+[m[32m            updateModeInstructions();[m
[32m+[m[41m            [m
[32m+[m[32m            // Show/hide relevant sections[m
[32m+[m[32m            imageUploadSection.style.display = mode === 'image' ? 'block' : 'none';[m
[32m+[m[41m            [m
[32m+[m[32m            // Update cursor[m
[32m+[m[32m            pdfCanvas.style.cursor = mode === 'text' ? 'crosshair' :[m[41m [m
[32m+[m[32m                                   mode === 'image' ? 'copy' : 'crosshair';[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        function updateModeInstructions() {[m
[32m+[m[32m            let instructions;[m
[32m+[m[41m            [m
[32m+[m[32m            if (currentMode === 'text') {[m
[32m+[m[32m                instructions = '<strong>Text Mode:</strong> Click on the PDF to add text variables at specific positions.';[m
[32m+[m[32m            } else if (currentMode === 'image') {[m
[32m+[m[32m                instructions = '<strong>Image Mode:</strong> First upload images, then click on the PDF to place them at specific positions.';[m
[32m+[m[32m            } else if (currentMode === 'shape') {[m
[32m+[m[32m                if (lineDrawingState === 'waiting_for_start') {[m
[32m+[m[32m                    instructions = '<strong>Shape Mode - Line Drawing:</strong> <span style="color: #ff4444;">●</span> Click to set the START point of the line.';[m
[32m+[m[32m                } else if (lineDrawingState === 'waiting_for_end') {[m
[32m+[m[32m                    instructions = '<strong>Shape Mode - Line Drawing:</strong> <span style="color: #44ff44;">●</span> Click to set the END point of the line.';[m
[32m+[m[32m                } else {[m
[32m+[m[32m                    instructions = '<strong>Shape Mode:</strong> Click on the PDF to add shapes (rectangles, circles, lines) at specific positions.';[m
[32m+[m[32m                }[m
[32m+[m[32m            }[m
[32m+[m[41m            [m
[32m+[m[32m            modeInstructions.innerHTML = instructions;[m
[32m+[m[41m            [m
[32m+[m[32m            // Show/hide line drawing controls[m
[32m+[m[32m            if (lineDrawingState) {[m
[32m+[m[32m                lineDrawingControls.style.display = 'block';[m
[32m+[m[32m            } else {[m
[32m+[m[32m                lineDrawingControls.style.display = 'none';[m
[32m+[m[32m            }[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        function cancelLineDrawing() {[m
[32m+[m[32m            lineDrawingState = null;[m
[32m+[m[32m            tempLineStart = null;[m
[32m+[m[32m            removeTemporaryLinePoints();[m
[32m+[m[32m            updateModeInstructions();[m
[32m+[m[32m            showNotification('Line drawing cancelled.', 'success');[m
[32m+[m[32m        }[m
 [m
         // Utility functions[m
         function showNotification(message, type = 'success') {[m
[36m@@ -608,6 +867,98 @@[m
             }[m
         }[m
 [m
[32m+[m[32m        // Session management for consistency[m
[32m+[m[32m        function ensureSessionConsistency() {[m
[32m+[m[32m            // This helps maintain the same session across page reloads[m
[32m+[m[32m            const sessionCookie = document.cookie.split(';').find(c => c.trim().startsWith('session='));[m
[32m+[m[32m            if (sessionCookie) {[m
[32m+[m[32m                console.log('Session cookie found:', sessionCookie);[m
[32m+[m[32m            } else {[m
[32m+[m[32m                console.log('No session cookie found - new session will be created');[m
[32m+[m[32m            }[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        // Initialize session consistency[m
[32m+[m[32m        ensureSessionConsistency();[m
[32m+[m
[32m+[m[32m        // Image handling[m
[32m+[m[32m        async function handleImageUpload(e) {[m
[32m+[m[32m            const files = Array.from(e.target.files);[m
[32m+[m[41m            [m
[32m+[m[32m            for (const file of files) {[m
[32m+[m[32m                if (file.size > 10 * 1024 * 1024) {[m
[32m+[m[32m                    showNotification(`Image ${file.name} too large. Maximum size is 10MB.`, 'error');[m
[32m+[m[32m                    continue;[m
[32m+[m[32m                }[m
[32m+[m[41m                [m
[32m+[m[32m                const formData = new FormData();[m
[32m+[m[32m                formData.append('image', file);[m
[32m+[m[41m                [m
[32m+[m[32m                try {[m
[32m+[m[32m                    const response = await fetch('/api/upload-image', {[m
[32m+[m[32m                        method: 'POST',[m
[32m+[m[32m                        body: formData[m
[32m+[m[32m                    });[m
[32m+[m[41m                    [m
[32m+[m[32m                    const result = await response.json();[m
[32m+[m[41m                    [m
[32m+[m[32m                    if (result.success) {[m
[32m+[m[32m                        showNotification(`Image ${result.filename} uploaded successfully!`);[m
[32m+[m[32m                        await loadUploadedImages();[m
[32m+[m[32m                    } else {[m
[32m+[m[32m                        showNotification(result.error, 'error');[m
[32m+[m[32m                    }[m
[32m+[m[32m                } catch (error) {[m
[32m+[m[32m                    showNotification('Image upload failed: ' + error.message, 'error');[m
[32m+[m[32m                }[m
[32m+[m[32m            }[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        async function refreshImageList() {[m
[32m+[m[32m            try {[m
[32m+[m[32m                console.log('Refreshing image list...');[m
[32m+[m[32m                const response = await fetch('/api/images');[m
[32m+[m[32m                const result = await response.json();[m
[32m+[m[41m                [m
[32m+[m[32m                if (result.success) {[m
[32m+[m[32m                    uploadedImages = result.images;[m
[32m+[m[32m                    updateImageList();[m
[32m+[m[32m                    console.log(`Loaded ${uploadedImages.length} images:`, uploadedImages);[m
[32m+[m[41m                    [m
[32m+[m[32m                    // Update sample data if it's empty or default[m
[32m+[m[32m                    const currentData = sampleData.value.trim();[m
[32m+[m[32m                    if (!currentData || currentData === '{}') {[m
[32m+[m[32m                        initializeSampleData();[m
[32m+[m[32m                    }[m
[32m+[m[32m                } else {[m
[32m+[m[32m                    console.error('Failed to load images:', result.error);[m
[32m+[m[32m                }[m
[32m+[m[32m            } catch (error) {[m
[32m+[m[32m                console.error('Error refreshing image list:', error);[m
[32m+[m[32m            }[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        async function loadUploadedImages() {[m
[32m+[m[32m            await refreshImageList();[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        function updateImageList() {[m
[32m+[m[32m            if (uploadedImages.length === 0) {[m
[32m+[m[32m                imageList.innerHTML = '<div>No images uploaded yet</div>';[m
[32m+[m[32m                return;[m
[32m+[m[32m            }[m
[32m+[m[41m            [m
[32m+[m[32m            imageList.innerHTML = uploadedImages.map(img =>[m[41m [m
[32m+[m[32m                `<div class="image-item-small">[m
[32m+[m[32m                    <span>📷 ${img.filename}</span>[m
[32m+[m[32m                    <div style="display: flex; flex-direction: column; align-items: flex-end;">[m
[32m+[m[32m                        <small>${new Date(img.upload_time).toLocaleDateString()}</small>[m
[32m+[m[32m                        <small style="color: #007bff; font-size: 0.7rem;">URL: ${window.location.origin}${img.url}</small>[m
[32m+[m[32m                    </div>[m
[32m+[m[32m                </div>`[m
[32m+[m[32m            ).join('');[m
[32m+[m[32m        }[m
[32m+[m
         // PDF upload and processing[m
         async function uploadPDF(file) {[m
             if (file.size > 16 * 1024 * 1024) {[m
[36m@@ -631,6 +982,7 @@[m
                 if (result.success) {[m
                     showNotification(result.message);[m
                     await loadPDFForPreview(file);[m
[32m+[m[32m                    await loadUploadedImages();[m
                     pdfUploaded = true;[m
                     processBtn.disabled = false;[m
                 } else {[m
[36m@@ -660,7 +1012,9 @@[m
                 await renderPage(currentPage);[m
                 updatePageInfo();[m
                 variables = [];[m
[31m-                updateVariablesList();[m
[32m+[m[32m                images = [];[m
[32m+[m[32m                shapes = [];[m
[32m+[m[32m                updateAllLists();[m
                 updateConfiguration();[m
             } catch (error) {[m
                 showNotification('Error loading PDF preview: ' + error.message, 'error');[m
[36m@@ -673,7 +1027,6 @@[m
                 const result = await response.json();[m
                 [m
                 if (result.success) {[m
[31m-                    // Store page dimensions for coordinate conversion[m
                     result.pages.forEach(page => {[m
                         pdfPageDimensions[page.page] = {[m
                             width: page.width,[m
[36m@@ -682,14 +1035,12 @@[m
                     });[m
                 } else {[m
                     console.warn('Could not get PDF dimensions:', result.error);[m
[31m-                    // Use default dimensions if we can't get actual ones[m
                     for (let i = 1; i <= totalPages; i++) {[m
[31m-                        pdfPageDimensions[i] = { width: 612, height: 792 }; // US Letter[m
[32m+[m[32m                        pdfPageDimensions[i] = { width: 612, height: 792 };[m
                     }[m
                 }[m
             } catch (error) {[m
                 console.warn('Error getting PDF dimensions:', error);[m
[31m-                // Use default dimensions[m
                 for (let i = 1; i <= totalPages; i++) {[m
                     pdfPageDimensions[i] = { width: 612, height: 792 };[m
                 }[m
[36m@@ -703,10 +1054,6 @@[m
                 [m
                 pdfCanvas.width = viewport.width;[m
                 pdfCanvas.height = viewport.height;[m
[31m-                [m
[31m-                // Store the actual viewport dimensions for accurate coordinate conversion[m
[31m-                const actualPageDim = pdfPageDimensions[pageNum] || { width: 612, height: 792 };[m
[31m-                console.log(`Page ${pageNum}: Canvas ${viewport.width}x${viewport.height}, PDF ${actualPageDim.width}x${actualPageDim.height}`);[m
 [m
                 const renderContext = {[m
                     canvasContext: pdfCtx,[m
[36m@@ -714,31 +1061,28 @@[m
                 };[m
                 [m
                 await page.render(renderContext).promise;[m
[31m-                renderTextOverlays();[m
[32m+[m[32m                renderAllOverlays();[m
             } catch (error) {[m
                 console.error('Error rendering page:', error);[m
             }[m
         }[m
 [m
[31m-        function renderTextOverlays() {[m
[32m+[m[32m        function renderAllOverlays() {[m
             // Remove existing overlays and dots[m
[31m-            const existingOverlays = pdfViewer.querySelectorAll('.text-overlay, .coordinate-dot');[m
[32m+[m[32m            const existingOverlays = pdfViewer.querySelectorAll('.text-overlay, .image-overlay, .shape-overlay, .coordinate-dot');[m
             existingOverlays.forEach(element => element.remove());[m
 [m
[32m+[m[32m            // Render text variables[m
             const currentPageVars = variables.filter(v => v.page === currentPage);[m
             currentPageVars.forEach(variable => {[m
                 if (variable.type === 'simple') {[m
[31m-                    // Use display coordinates for visual overlay (exact click position)[m
                     let canvasCoords;[m
                     if (variable.displayX && variable.displayY) {[m
[31m-                        // Use stored display coordinates[m
                         canvasCoords = pdfToCanvasCoordinates(variable.displayX, variable.displayY, currentPage, true);[m
                     } else {[m
[31m-                        // Fallback for old variables - reverse the adjustment[m
                         canvasCoords = pdfToCanvasCoordinates(variable.x, variable.y, currentPage, false);[m
                     }[m
 [m
[31m-                    // Create text overlay at exact click position[m
                     const overlay = document.createElement('div');[m
                     overlay.className = 'text-overlay';[m
                     overlay.textContent = `${variable.name} (${variable.x}, ${variable.y})`;[m
[36m@@ -746,7 +1090,6 @@[m
                     overlay.style.top = canvasCoords.y + 'px';[m
                     pdfViewer.appendChild(overlay);[m
 [m
[31m-                    // Create precision dot at exact click position[m
                     const dot = document.createElement('div');[m
                     dot.className = 'coordinate-dot simple';[m
                     dot.style.left = canvasCoords.x + 'px';[m
[36m@@ -754,7 +1097,6 @@[m
                     pdfViewer.appendChild(dot);[m
 [m
                 } else if (variable.type === 'conditional') {[m
[31m-                    // Render conditional coordinate overlays[m
                     variable.conditionalCoordinates.forEach((cond, index) => {[m
                         let canvasCoords;[m
                         if (cond.displayX && cond.displayY) {[m
[36m@@ -763,16 +1105,14 @@[m
                             canvasCoords = pdfToCanvasCoordinates(cond.x, cond.y, currentPage, false);[m
                         }[m
 [m
[31m-                        // Create text overlay[m
                         const overlay = document.createElement('div');[m
                         overlay.className = 'text-overlay';[m
[31m-                        overlay.style.background = 'rgba(255, 152, 0, 0.8)'; // Orange for conditional[m
[32m+[m[32m                        overlay.style.background = 'rgba(255, 152, 0, 0.8)';[m
                         overlay.textContent = `${variable.name}[${cond.if_value || '?'}] (${cond.x}, ${cond.y})`;[m
                         overlay.style.left = canvasCoords.x + 'px';[m
                         overlay.style.top = canvasCoords.y + 'px';[m
                         pdfViewer.appendChild(overlay);[m
 [m
[31m-                        // Create precision dot[m
                         const dot = document.createElement('div');[m
                         dot.className = 'coordinate-dot conditional';[m
                         dot.style.left = canvasCoords.x + 'px';[m
[36m@@ -781,6 +1121,44 @@[m
                     });[m
                 }[m
             });[m
[32m+[m
[32m+[m[32m            // Render images[m
[32m+[m[32m            const currentPageImages = images.filter(img => img.page === currentPage);[m
[32m+[m[32m            currentPageImages.forEach(image => {[m
[32m+[m[32m                const canvasCoords = pdfToCanvasCoordinates(image.x, image.y, currentPage, false);[m
[32m+[m
[32m+[m[32m                const overlay = document.createElement('div');[m
[32m+[m[32m                overlay.className = 'image-overlay';[m
[32m+[m[32m                overlay.textContent = `🖼️ ${image.name} (${image.width}x${image.height})`;[m
[32m+[m[32m                overlay.style.left = canvasCoords.x + 'px';[m
[32m+[m[32m                overlay.style.top = canvasCoords.y + 'px';[m
[32m+[m[32m                pdfViewer.appendChild(overlay);[m
[32m+[m
[32m+[m[32m                const dot = document.createElement('div');[m
[32m+[m[32m                dot.className = 'coordinate-dot image';[m
[32m+[m[32m                dot.style.left = canvasCoords.x + 'px';[m
[32m+[m[32m                dot.style.top = canvasCoords.y + 'px';[m
[32m+[m[32m                pdfViewer.appendChild(dot);[m
[32m+[m[32m            });[m
[32m+[m
[32m+[m[32m            // Render shapes[m
[32m+[m[32m            const currentPageShapes = shapes.filter(shape => shape.page === currentPage);[m
[32m+[m[32m            currentPageShapes.forEach(shape => {[m
[32m+[m[32m                const canvasCoords = pdfToCanvasCoordinates(shape.x, shape.y, currentPage, false);[m
[32m+[m
[32m+[m[32m                const overlay = document.createElement('div');[m
[32m+[m[32m                overlay.className = 'shape-overlay';[m
[32m+[m[32m                overlay.textContent = `${shape.type} (${shape.width}x${shape.height})`;[m
[32m+[m[32m                overlay.style.left = canvasCoords.x + 'px';[m
[32m+[m[32m                overlay.style.top = canvasCoords.y + 'px';[m
[32m+[m[32m                pdfViewer.appendChild(overlay);[m
[32m+[m
[32m+[m[32m                const dot = document.createElement('div');[m
[32m+[m[32m                dot.className = 'coordinate-dot shape';[m
[32m+[m[32m                dot.style.left = canvasCoords.x + 'px';[m
[32m+[m[32m                dot.style.top = canvasCoords.y + 'px';[m
[32m+[m[32m                pdfViewer.appendChild(dot);[m
[32m+[m[32m            });[m
         }[m
 [m
         function changePage(direction) {[m
[36m@@ -789,7 +1167,11 @@[m
                 currentPage = newPage;[m
                 renderPage(currentPage);[m
                 updatePageInfo();[m
[31m-                renderTextOverlays();[m
[32m+[m[41m                [m
[32m+[m[32m                // Clear line drawing state when changing pages[m
[32m+[m[32m                if (lineDrawingState) {[m
[32m+[m[32m                    cancelLineDrawing();[m
[32m+[m[32m                }[m
             }[m
         }[m
 [m
[36m@@ -804,85 +1186,250 @@[m
             const canvasX = Math.round(e.clientX - rect.left);[m
             const canvasY = Math.round(e.clientY - rect.top);[m
             [m
[31m-            // Check if Ctrl/Cmd is held down for adding conditional coordinates[m
[31m-            if (e.ctrlKey || e.metaKey) {[m
[31m-                // Get adjusted coordinates for conditional coordinates[m
[31m-                const pdfCoords = canvasToPDFCoordinates(canvasX, canvasY, currentPage, false);[m
[31m-                addConditionalCoordinateByClick(pdfCoords.x, pdfCoords.y);[m
[32m+[m[32m            if (currentMode === 'text') {[m
[32m+[m[32m                if (e.ctrlKey || e.metaKey) {[m
[32m+[m[32m                    const pdfCoords = canvasToPDFCoordinates(canvasX, canvasY, currentPage, false);[m
[32m+[m[32m                    addConditionalCoordinateByClick(pdfCoords.x, pdfCoords.y);[m
[32m+[m[32m                } else {[m
[32m+[m[32m                    addVariableAtPosition(canvasX, canvasY, currentPage);[m
[32m+[m[32m                }[m
[32m+[m[32m            } else if (currentMode === 'image') {[m
[32m+[m[32m                addImageAtPosition(canvasX, canvasY, currentPage);[m
[32m+[m[32m            } else if (currentMode === 'shape') {[m
[32m+[m[32m                handleShapeClick(canvasX, canvasY, currentPage);[m
[32m+[m[32m            }[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        function handleShapeClick(canvasX, canvasY, page) {[m
[32m+[m[32m            if (lineDrawingState === 'waiting_for_start') {[m
[32m+[m[32m                // First click for line - set start point[m
[32m+[m[32m                const pdfCoords = canvasToPDFCoordinates(canvasX, canvasY, page, false);[m
[32m+[m[32m                tempLineStart = {[m
[32m+[m[32m                    x: pdfCoords.x || 0,[m
[32m+[m[32m                    y: pdfCoords.y || 0,[m
[32m+[m[32m                    canvasX: canvasX,[m
[32m+[m[32m                    canvasY: canvasY[m
[32m+[m[32m                };[m
[32m+[m[32m                lineDrawingState = 'waiting_for_end';[m
[32m+[m[41m                [m
[32m+[m[32m                // Show temporary start point indicator[m
[32m+[m[32m                showTemporaryLinePoint(canvasX, canvasY, 'start');[m
[32m+[m[32m                updateModeInstructions();[m
[32m+[m[32m                showNotification('Line start point set. Click again to set end point.', 'success');[m
[32m+[m[41m                [m
[32m+[m[32m            } else if (lineDrawingState === 'waiting_for_end') {[m
[32m+[m[32m                // Second click for line - set end point and create line[m
[32m+[m[32m                const pdfCoords = canvasToPDFCoordinates(canvasX, canvasY, page, false);[m
[32m+[m[41m                [m
[32m+[m[32m                const shape = {[m
[32m+[m[32m                    type: 'line',[m
[32m+[m[32m                    x: tempLineStart.x,[m
[32m+[m[32m                    y: tempLineStart.y,[m
[32m+[m[32m                    page: page,[m
[32m+[m[32m                    width: 50,[m
[32m+[m[32m                    height: 50,[m
[32m+[m[32m                    color: '#000000',[m
[32m+[m[32m                    fill: false,[m
[32m+[m[32m                    stroke_width: 2,[m
[32m+[m[32m                    radius: 25,[m
[32m+[m[32m                    end_x: pdfCoords.x || 0,[m
[32m+[m[32m                    end_y: pdfCoords.y || 0[m
[32m+[m[32m                };[m
[32m+[m
[32m+[m[32m                shapes.push(shape);[m
[32m+[m[32m                updateShapesList();[m
[32m+[m[32m                updateConfiguration();[m
[32m+[m[32m                renderAllOverlays();[m
[32m+[m[41m                [m
[32m+[m[32m                // Reset line drawing state[m
[32m+[m[32m                lineDrawingState = null;[m
[32m+[m[32m                tempLineStart = null;[m
[32m+[m[32m                removeTemporaryLinePoints();[m
[32m+[m[32m                updateModeInstructions();[m
[32m+[m[32m                showNotification('Line created successfully!', 'success');[m
[32m+[m[41m                [m
             } else {[m
[31m-                // For regular variables, addVariableAtPosition will handle both display and process coords[m
[31m-                addVariableAtPosition(0, 0, currentPage); // Parameters not used anymore[m
[32m+[m[32m                // Regular shape drawing (rectangle/circle) or start line drawing[m
[32m+[m[32m                const shapeType = prompt('Select shape type:\n1. Rectangle\n2. Circle\n3. Line (two-point)');[m
[32m+[m[32m                let type;[m
[32m+[m[41m                [m
[32m+[m[32m                switch(shapeType) {[m
[32m+[m[32m                    case '1': type = 'rectangle'; break;[m
[32m+[m[32m                    case '2': type = 'circle'; break;[m
[32m+[m[32m                    case '3':[m[41m [m
[32m+[m[32m                        type = 'line';[m
[32m+[m[32m                        lineDrawingState = 'waiting_for_start';[m
[32m+[m[32m                        updateModeInstructions();[m
[32m+[m[32m                        showNotification('Click on the PDF to set line start point.', 'success');[m
[32m+[m[32m                        return; // Don't create shape yet, wait for two clicks[m
[32m+[m[32m                    default: return;[m
[32m+[m[32m                }[m
[32m+[m
[32m+[m[32m                const pdfCoords = canvasToPDFCoordinates(canvasX, canvasY, page, false);[m
[32m+[m[41m                [m
[32m+[m[32m                const shape = {[m
[32m+[m[32m                    type: type,[m
[32m+[m[32m                    x: pdfCoords.x || 0,[m
[32m+[m[32m                    y: pdfCoords.y || 0,[m
[32m+[m[32m                    page: page,[m
[32m+[m[32m                    width: 50,[m
[32m+[m[32m                    height: 50,[m
[32m+[m[32m                    color: '#000000',[m
[32m+[m[32m                    fill: false,[m
[32m+[m[32m                    stroke_width: 1,[m
[32m+[m[32m                    radius: 25,[m
[32m+[m[32m                    end_x: (pdfCoords.x || 0) + 50,[m
[32m+[m[32m                    end_y: pdfCoords.y || 0[m
[32m+[m[32m                };[m
[32m+[m
[32m+[m[32m                shapes.push(shape);[m
[32m+[m[32m                updateShapesList();[m
[32m+[m[32m                updateConfiguration();[m
[32m+[m[32m                renderAllOverlays();[m
             }[m
         }[m
 [m
[31m-        function addConditionalCoordinateByClick(x, y) {[m
[31m-            // Find conditional variables on the current page[m
[31m-            const conditionalVars = variables.filter(v => v.type === 'conditional' && v.page === currentPage);[m
[32m+[m[32m        function showTemporaryLinePoint(canvasX, canvasY, pointType) {[m
[32m+[m[32m            // Remove any existing temporary points[m
[32m+[m[32m            removeTemporaryLinePoints();[m
[32m+[m[41m            [m
[32m+[m[32m            // Create temporary point indicator[m
[32m+[m[32m            const tempPoint = document.createElement('div');[m
[32m+[m[32m            tempPoint.className = 'temp-line-point';[m
[32m+[m[32m            tempPoint.id = `temp-${pointType}-point`;[m
[32m+[m[32m            tempPoint.style.position = 'absolute';[m
[32m+[m[32m            tempPoint.style.left = canvasX + 'px';[m
[32m+[m[32m            tempPoint.style.top = canvasY + 'px';[m
[32m+[m[32m            tempPoint.style.width = '12px';[m
[32m+[m[32m            tempPoint.style.height = '12px';[m
[32m+[m[32m            tempPoint.style.borderRadius = '50%';[m
[32m+[m[32m            tempPoint.style.background = pointType === 'start' ? '#ff4444' : '#44ff44';[m
[32m+[m[32m            tempPoint.style.border = '2px solid white';[m
[32m+[m[32m            tempPoint.style.transform = 'translate(-50%, -50%)';[m
[32m+[m[32m            tempPoint.style.zIndex = '1001';[m
[32m+[m[32m            tempPoint.style.pointerEvents = 'none';[m
[32m+[m[32m            tempPoint.style.boxShadow = '0 2px 4px rgba(0,0,0,0.3)';[m
[32m+[m[41m            [m
[32m+[m[32m            // Add text label[m
[32m+[m[32m            const label = document.createElement('div');[m
[32m+[m[32m            label.style.position = 'absolute';[m
[32m+[m[32m            label.style.top = '-25px';[m
[32m+[m[32m            label.style.left = '50%';[m
[32m+[m[32m            label.style.transform = 'translateX(-50%)';[m
[32m+[m[32m            label.style.background = 'rgba(0,0,0,0.8)';[m
[32m+[m[32m            label.style.color = 'white';[m
[32m+[m[32m            label.style.padding = '2px 6px';[m
[32m+[m[32m            label.style.borderRadius = '3px';[m
[32m+[m[32m            label.style.fontSize = '10px';[m
[32m+[m[32m            label.style.whiteSpace = 'nowrap';[m
[32m+[m[32m            label.textContent = pointType === 'start' ? 'START' : 'END';[m
[32m+[m[32m            tempPoint.appendChild(label);[m
[32m+[m[41m            [m
[32m+[m[32m            pdfViewer.appendChild(tempPoint);[m
[32m+[m[32m        }[m
 [m
[31m-            if (conditionalVars.length === 0) {[m
[31m-                showNotification('No conditional variables on this page. Create a conditional variable first.', 'error');[m
[32m+[m[32m        function removeTemporaryLinePoints() {[m
[32m+[m[32m            const tempPoints = pdfViewer.querySelectorAll('.temp-line-point');[m
[32m+[m[32m            tempPoints.forEach(point => point.remove());[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        function addImageAtPosition(canvasX, canvasY, page) {[m
[32m+[m[32m            if (uploadedImages.length === 0) {[m
[32m+[m[32m                showNotification('Please upload images first', 'error');[m
                 return;[m
             }[m
 [m
[31m-            if (conditionalVars.length === 1) {[m
[31m-                // Automatically add to the only conditional variable[m
[31m-                const varIndex = variables.indexOf(conditionalVars[0]);[m
[31m-                addConditionalCoordinate(varIndex);[m
[31m-                // Update the last added coordinate with clicked position[m
[31m-                const lastCondIndex = variables[varIndex].conditionalCoordinates.length - 1;[m
[31m-                updateConditionalCoordinate(varIndex, lastCondIndex, 'x', x);[m
[31m-                updateConditionalCoordinate(varIndex, lastCondIndex, 'y', y);[m
[31m-                updateVariablesList();[m
[31m-                showNotification(`Added conditional coordinate to "${conditionalVars[0].name}"`);[m
[32m+[m[32m            let selectedImage;[m
[32m+[m[32m            if (uploadedImages.length === 1) {[m
[32m+[m[32m                selectedImage = uploadedImages[0];[m
             } else {[m
[31m-                // Multiple conditional variables - let user choose[m
[31m-                const varNames = conditionalVars.map((v, i) => `${i + 1}. ${v.name}`).join('\n');[m
[31m-                const choice = prompt(`Multiple conditional variables found. Enter the number for:\n${varNames}`);[m
[32m+[m[32m                const imageNames = uploadedImages.map((img, i) => `${i + 1}. ${img.filename}`).join('\n');[m
[32m+[m[32m                const choice = prompt(`Select an image:\n${imageNames}`);[m
                 const choiceIndex = parseInt(choice) - 1;[m
[31m-[m
[31m-                if (choiceIndex >= 0 && choiceIndex < conditionalVars.length) {[m
[31m-                    const varIndex = variables.indexOf(conditionalVars[choiceIndex]);[m
[31m-                    addConditionalCoordinate(varIndex);[m
[31m-                    const lastCondIndex = variables[varIndex].conditionalCoordinates.length - 1;[m
[31m-                    updateConditionalCoordinate(varIndex, lastCondIndex, 'x', x);[m
[31m-                    updateConditionalCoordinate(varIndex, lastCondIndex, 'y', y);[m
[31m-                    updateVariablesList();[m
[31m-                    showNotification(`Added conditional coordinate to "${conditionalVars[choiceIndex].name}"`);[m
[32m+[m[41m                [m
[32m+[m[32m                if (choiceIndex >= 0 && choiceIndex < uploadedImages.length) {[m
[32m+[m[32m                    selectedImage = uploadedImages[choiceIndex];[m
[32m+[m[32m                } else {[m
[32m+[m[32m                    return;[m
                 }[m
             }[m
[32m+[m
[32m+[m[32m            // Prompt for variable name (this will be used to reference the image URL in sample data)[m
[32m+[m[32m            const imageName = prompt('Enter variable name for this image (e.g., "logo", "signature"):', `image_${images.length + 1}`);[m
[32m+[m[32m            if (!imageName) return;[m
[32m+[m
[32m+[m[32m            const pdfCoords = canvasToPDFCoordinates(canvasX, canvasY, page, false);[m
[32m+[m[41m            [m
[32m+[m[32m            const image = {[m
[32m+[m[32m                name: imageName,[m
[32m+[m[32m                filename: selectedImage.filename,[m
[32m+[m[32m                x: pdfCoords.x,[m
[32m+[m[32m                y: pdfCoords.y,[m
[32m+[m[32m                page: page,[m
[32m+[m[32m                width: 100,[m
[32m+[m[32m                height: 100[m
[32m+[m[32m            };[m
[32m+[m
[32m+[m[32m            images.push(image);[m
[32m+[m[32m            updateImagesList();[m
[32m+[m[32m            updateConfiguration();[m
[32m+[m[32m            renderAllOverlays();[m
[32m+[m[32m            showNotification(`Added image variable "${imageName}". Add the image URL to sample data with key "${imageName}".`);[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        function addShapeAtPosition(canvasX, canvasY, page) {[m
[32m+[m[32m            const shapeType = prompt('Select shape type:\n1. Rectangle\n2. Circle\n3. Line');[m
[32m+[m[32m            let type;[m
[32m+[m[41m            [m
[32m+[m[32m            switch(shapeType) {[m
[32m+[m[32m                case '1': type = 'rectangle'; break;[m
[32m+[m[32m                case '2': type = 'circle'; break;[m
[32m+[m[32m                case '3': type = 'line'; break;[m
[32m+[m[32m                default: return;[m
[32m+[m[32m            }[m
[32m+[m
[32m+[m[32m            const pdfCoords = canvasToPDFCoordinates(canvasX, canvasY, page, false);[m
[32m+[m[41m            [m
[32m+[m[32m            const shape = {[m
[32m+[m[32m                type: type,[m
[32m+[m[32m                x: pdfCoords.x || 0,[m
[32m+[m[32m                y: pdfCoords.y || 0,[m
[32m+[m[32m                page: page,[m
[32m+[m[32m                width: 50,[m
[32m+[m[32m                height: 50,[m
[32m+[m[32m                color: '#000000',[m
[32m+[m[32m                fill: false,[m
[32m+[m[32m                stroke_width: 1,[m
[32m+[m[32m                radius: 25,[m
[32m+[m[32m                end_x: (pdfCoords.x || 0) + 50,[m
[32m+[m[32m                end_y: pdfCoords.y || 0[m
[32m+[m[32m            };[m
[32m+[m
[32m+[m[32m            shapes.push(shape);[m
[32m+[m[32m            updateShapesList();[m
[32m+[m[32m            updateConfiguration();[m
[32m+[m[32m            renderAllOverlays();[m
         }[m
 [m
         function canvasToPDFCoordinates(canvasX, canvasY, pageNum, forDisplay = false) {[m
[31m-            // Get actual PDF page dimensions[m
             const pdfPageDim = pdfPageDimensions[pageNum] || { width: 612, height: 792 };[m
             [m
[31m-            // Calculate the scale factors between canvas and PDF[m
             const scaleX = pdfPageDim.width / pdfCanvas.width;[m
             const scaleY = pdfPageDim.height / pdfCanvas.height;[m
             [m
[31m-            // Convert canvas coordinates to PDF coordinates[m
             const pdfX = Math.round(canvasX * scaleX);[m
[31m-            // PDF coordinate system has origin at bottom-left, canvas at top-left[m
             const pdfY = Math.round(pdfPageDim.height - (canvasY * scaleY));[m
             [m
             if (forDisplay) {[m
[31m-                // Return exact coordinates for visual display (no adjustment)[m
                 return { x: pdfX, y: pdfY };[m
             } else {[m
[31m-                // Apply adjustment for actual PDF text positioning[m
[31m-                const adjustedPdfX = pdfX - 3; // Slight left adjustment for horizontal center[m
[31m-                const adjustedPdfY = pdfY - 6; // SUBTRACT to move DOWN (lower Y value in PDF = lower position)[m
[31m-[m
[31m-                console.log(`Canvas: (${canvasX}, ${canvasY}) -> PDF Display: (${pdfX}, ${pdfY}) -> PDF Final: (${adjustedPdfX}, ${adjustedPdfY})`);[m
[31m-                console.log(`Canvas size: ${pdfCanvas.width}x${pdfCanvas.height}, PDF size: ${pdfPageDim.width}x${pdfPageDim.height}`);[m
[31m-                console.log(`Scale factors: X=${scaleX.toFixed(3)}, Y=${scaleY.toFixed(3)}`);[m
[31m-[m
[32m+[m[32m                const adjustedPdfX = pdfX - 3;[m
[32m+[m[32m                const adjustedPdfY = pdfY - 6;[m
                 return { x: adjustedPdfX, y: adjustedPdfY };[m
             }[m
         }[m
 [m
         function pdfToCanvasCoordinates(pdfX, pdfY, pageNum, isDisplayCoords = false) {[m
[31m-            // Convert PDF coordinates back to canvas coordinates for overlay display[m
             const pdfPageDim = pdfPageDimensions[pageNum] || { width: 612, height: 792 };[m
             [m
             const scaleX = pdfCanvas.width / pdfPageDim.width;[m
[36m@@ -891,16 +1438,11 @@[m
             let displayPdfX, displayPdfY;[m
 [m
             if (isDisplayCoords) {[m
[31m-                // These are already display coordinates, no adjustment needed[m
                 displayPdfX = pdfX + 89;[m
                 displayPdfY = pdfY - 89;[m
[31m-                console.log("display", displayPdfX, displayPdfY)[m
             } else {[m
[31m-                // These are adjusted coordinates, reverse the adjustment for display[m
[31m-                displayPdfX = pdfX - 2; // Reverse the left adjustment[m
[31m-                displayPdfY = pdfY - 2; // Reverse the down adjustment[m
[31m-[m
[31m-                console.log(displayPdfX, displayPdfY)[m
[32m+[m[32m                displayPdfX = pdfX - 2;[m
[32m+[m[32m                displayPdfY = pdfY - 2;[m
             }[m
 [m
             const canvasX = Math.round(displayPdfX * scaleX);[m
[36m@@ -909,22 +1451,16 @@[m
             return { x: canvasX, y: canvasY };[m
         }[m
 [m
[31m-        function addVariableAtPosition(x, y, page) {[m
[31m-            const canvasRect = pdfCanvas.getBoundingClientRect();[m
[31m-            const canvasX = Math.round(event.clientX - canvasRect.left);[m
[31m-            const canvasY = Math.round(event.clientY - canvasRect.top);[m
[31m-[m
[31m-            // Get display coordinates (exact click position) for visual overlay[m
[32m+[m[32m        function addVariableAtPosition(canvasX, canvasY, page) {[m
             const displayCoords = canvasToPDFCoordinates(canvasX, canvasY, page, true);[m
[31m-            // Get adjusted coordinates for actual PDF processing[m
             const processCoords = canvasToPDFCoordinates(canvasX, canvasY, page, false);[m
 [m
             const variableName = `var_${variables.length + 1}`;[m
             const variable = {[m
                 name: variableName,[m
[31m-                x: processCoords.x, // Adjusted coordinates for PDF processing[m
[32m+[m[32m                x: processCoords.x,[m
                 y: processCoords.y,[m
[31m-                displayX: displayCoords.x, // Exact coordinates for visual display[m
[32m+[m[32m                displayX: displayCoords.x,[m
                 displayY: displayCoords.y,[m
                 page: page,[m
                 fontSize: 12,[m
[36m@@ -935,83 +1471,43 @@[m
             variables.push(variable);[m
             updateVariablesList();[m
             updateConfiguration();[m
[31m-            renderTextOverlays();[m
[32m+[m[32m            renderAllOverlays();[m
         }[m
 [m
[31m-        function loadFromConfiguration() {[m
[31m-            try {[m
[31m-                const configText = configOutput.value || configOutput.textContent;[m
[31m-                if (!configText || configText === 'Click on the PDF to start adding variables...') {[m
[31m-                    showNotification('No configuration to load', 'error');[m
[31m-                    return;[m
[31m-                }[m
[31m-[m
[31m-                const config = JSON.parse(configText);[m
[31m-                if (!Array.isArray(config)) {[m
[31m-                    showNotification('Invalid configuration format - must be an array', 'error');[m
[31m-                    return;[m
[31m-                }[m
[32m+[m[32m        function addConditionalCoordinateByClick(x, y) {[m
[32m+[m[32m            const conditionalVars = variables.filter(v => v.type === 'conditional' && v.page === currentPage);[m
 [m
[31m-                // Convert configuration back to variables[m
[31m-                variables = [];[m
[31m-                config.forEach(pageConfig => {[m
[31m-                    const displayPage = pageConfig.page_number + 1; // Convert 0-based to 1-based for display[m
[31m-[m
[31m-                    if (!pageConfig.variables || !Array.isArray(pageConfig.variables)) {[m
[31m-                        console.warn(`Page ${pageConfig.page_number} has no variables array`);[m
[31m-                        return;[m
[31m-                    }[m
[31m-[m
[31m-                    pageConfig.variables.forEach(variable => {[m
[31m-                        if (variable.conditional_coordinates) {[m
[31m-                            // Conditional variable[m
[31m-                            const newVar = {[m
[31m-                                name: variable.name,[m
[31m-                                x: 0, // Not used for conditional[m
[31m-                                y: 0, // Not used for conditional[m
[31m-                                page: displayPage,[m
[31m-                                fontSize: 12,[m
[31m-                                type: 'conditional',[m
[31m-                                conditionalCoordinates: variable.conditional_coordinates.map(cond => ({[m
[31m-                                    if_value: cond.if_value || '',[m
[31m-                                    print_pattern: cond.print_pattern || '*',[m
[31m-                                    x: cond['x-coordinate'] || 0,[m
[31m-                                    y: cond['y-coordinate'] || 0,[m
[31m-                                    displayX: cond['x-coordinate'] || 0, // Use same coordinates for display[m
[31m-                                    displayY: cond['y-coordinate'] || 0[m
[31m-                                }))[m
[31m-                            };[m
[31m-                            variables.push(newVar);[m
[31m-                        } else {[m
[31m-                            // Simple variable[m
[31m-                            const newVar = {[m
[31m-                                name: variable.name,[m
[31m-                                x: variable['x-coordinate'] || 0,[m
[31m-                                y: variable['y-coordinate'] || 0,[m
[31m-                                displayX: variable['x-coordinate'] || 0, // Use same coordinates for display[m
[31m-                                displayY: variable['y-coordinate'] || 0,[m
[31m-                                page: displayPage,[m
[31m-                                fontSize: variable.font_size || 12,[m
[31m-                                type: 'simple',[m
[31m-                                conditionalCoordinates: [][m
[31m-                            };[m
[31m-                            variables.push(newVar);[m
[31m-                        }[m
[31m-                    });[m
[31m-                });[m
[32m+[m[32m            if (conditionalVars.length === 0) {[m
[32m+[m[32m                showNotification('No conditional variables on this page. Create a conditional variable first.', 'error');[m
[32m+[m[32m                return;[m
[32m+[m[32m            }[m
 [m
[32m+[m[32m            if (conditionalVars.length === 1) {[m
[32m+[m[32m                const varIndex = variables.indexOf(conditionalVars[0]);[m
[32m+[m[32m                addConditionalCoordinate(varIndex);[m
[32m+[m[32m                const lastCondIndex = variables[varIndex].conditionalCoordinates.length - 1;[m
[32m+[m[32m                updateConditionalCoordinate(varIndex, lastCondIndex, 'x', x);[m
[32m+[m[32m                updateConditionalCoordinate(varIndex, lastCondIndex, 'y', y);[m
                 updateVariablesList();[m
[31m-                renderTextOverlays();[m
[31m-                showNotification(`Configuration loaded successfully! ${variables.length} variables imported.`);[m
[32m+[m[32m                showNotification(`Added conditional coordinate to "${conditionalVars[0].name}"`);[m
[32m+[m[32m            } else {[m
[32m+[m[32m                const varNames = conditionalVars.map((v, i) => `${i + 1}. ${v.name}`).join('\n');[m
[32m+[m[32m                const choice = prompt(`Multiple conditional variables found. Enter the number for:\n${varNames}`);[m
[32m+[m[32m                const choiceIndex = parseInt(choice) - 1;[m
 [m
[31m-            } catch (error) {[m
[31m-                showNotification('Invalid JSON configuration: ' + error.message, 'error');[m
[31m-                console.error('Config parsing error:', error);[m
[32m+[m[32m                if (choiceIndex >= 0 && choiceIndex < conditionalVars.length) {[m
[32m+[m[32m                    const varIndex = variables.indexOf(conditionalVars[choiceIndex]);[m
[32m+[m[32m                    addConditionalCoordinate(varIndex);[m
[32m+[m[32m                    const lastCondIndex = variables[varIndex].conditionalCoordinates.length - 1;[m
[32m+[m[32m                    updateConditionalCoordinate(varIndex, lastCondIndex, 'x', x);[m
[32m+[m[32m                    updateConditionalCoordinate(varIndex, lastCondIndex, 'y', y);[m
[32m+[m[32m                    updateVariablesList();[m
[32m+[m[32m                    showNotification(`Added conditional coordinate to "${conditionalVars[choiceIndex].name}"`);[m
[32m+[m[32m                }[m
             }[m
         }[m
 [m
         function addVariable() {[m
[31m-            // Get center coordinates of current page in PDF coordinate system[m
             const pdfPageDim = pdfPageDimensions[currentPage] || { width: 612, height: 792 };[m
             const centerX = Math.round(pdfPageDim.width / 2);[m
             const centerY = Math.round(pdfPageDim.height / 2);[m
[36m@@ -1027,16 +1523,30 @@[m
             };[m
 [m
             variables.push(variable);[m
[31m-            updateVariablesList();[m
[32m+[m[32m            updateAllLists();[m
             updateConfiguration();[m
[31m-            renderTextOverlays();[m
[32m+[m[32m            renderAllOverlays();[m
         }[m
 [m
         function removeVariable(index) {[m
             variables.splice(index, 1);[m
[31m-            updateVariablesList();[m
[32m+[m[32m            updateAllLists();[m
[32m+[m[32m            updateConfiguration();[m
[32m+[m[32m            renderAllOverlays();[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        function removeImage(index) {[m
[32m+[m[32m            images.splice(index, 1);[m
[32m+[m[32m            updateAllLists();[m
             updateConfiguration();[m
[31m-            renderTextOverlays();[m
[32m+[m[32m            renderAllOverlays();[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        function removeShape(index) {[m
[32m+[m[32m            shapes.splice(index, 1);[m
[32m+[m[32m            updateAllLists();[m
[32m+[m[32m            updateConfiguration();[m
[32m+[m[32m            renderAllOverlays();[m
         }[m
 [m
         function updateVariable(index, field, value) {[m
[36m@@ -1047,7 +1557,6 @@[m
                     variables[index][field] = value;[m
                 }[m
 [m
[31m-                // If switching to conditional type, initialize conditional coordinates[m
                 if (field === 'type' && value === 'conditional' && !variables[index].conditionalCoordinates.length) {[m
                     variables[index].conditionalCoordinates = [{[m
                         if_value: '',[m
[36m@@ -1060,7 +1569,42 @@[m
                 updateVariablesList();[m
                 updateConfiguration();[m
                 if (field === 'x' || field === 'y' || field === 'page') {[m
[31m-                    renderTextOverlays();[m
[32m+[m[32m                    renderAllOverlays();[m
[32m+[m[32m                }[m
[32m+[m[32m            }[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        function updateImage(index, field, value) {[m
[32m+[m[32m            if (images[index]) {[m
[32m+[m[32m                if (field === 'width' || field === 'height' || field === 'x' || field === 'y' || field === 'page') {[m
[32m+[m[32m                    images[index][field] = parseInt(value) || 0;[m
[32m+[m[32m                } else {[m
[32m+[m[32m                    images[index][field] = value;[m
[32m+[m[32m                }[m
[32m+[m
[32m+[m[32m                updateImagesList();[m
[32m+[m[32m                updateConfiguration();[m
[32m+[m[32m                if (field === 'x' || field === 'y' || field === 'page') {[m
[32m+[m[32m                    renderAllOverlays();[m
[32m+[m[32m                }[m
[32m+[m[32m            }[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        function updateShape(index, field, value) {[m
[32m+[m[32m            if (shapes[index]) {[m
[32m+[m[32m                if (field === 'width' || field === 'height' || field === 'x' || field === 'y' || field === 'page' ||[m[41m [m
[32m+[m[32m                    field === 'radius' || field === 'end_x' || field === 'end_y' || field === 'stroke_width') {[m
[32m+[m[32m                    shapes[index][field] = parseInt(value) || 0;[m
[32m+[m[32m                } else if (field === 'fill') {[m
[32m+[m[32m                    shapes[index][field] = value === 'true';[m
[32m+[m[32m                } else {[m
[32m+[m[32m                    shapes[index][field] = value;[m
[32m+[m[32m                }[m
[32m+[m
[32m+[m[32m                updateShapesList();[m
[32m+[m[32m                updateConfiguration();[m
[32m+[m[32m                if (field === 'x' || field === 'y' || field === 'page' || field === 'end_x' || field === 'end_y') {[m
[32m+[m[32m                    renderAllOverlays();[m
                 }[m
             }[m
         }[m
[36m@@ -1076,7 +1620,7 @@[m
                 });[m
                 updateVariablesList();[m
                 updateConfiguration();[m
[31m-                renderTextOverlays();[m
[32m+[m[32m                renderAllOverlays();[m
             }[m
         }[m
 [m
[36m@@ -1085,7 +1629,7 @@[m
                 variables[variableIndex].conditionalCoordinates.splice(condIndex, 1);[m
                 updateVariablesList();[m
                 updateConfiguration();[m
[31m-                renderTextOverlays();[m
[32m+[m[32m                renderAllOverlays();[m
             }[m
         }[m
 [m
[36m@@ -1098,11 +1642,17 @@[m
                 }[m
                 updateConfiguration();[m
                 if (field === 'x' || field === 'y') {[m
[31m-                    renderTextOverlays();[m
[32m+[m[32m                    renderAllOverlays();[m
                 }[m
             }[m
         }[m
 [m
[32m+[m[32m        function updateAllLists() {[m
[32m+[m[32m            updateVariablesList();[m
[32m+[m[32m            updateImagesList();[m
[32m+[m[32m            updateShapesList();[m
[32m+[m[32m        }[m
[32m+[m
         function updateVariablesList() {[m
             variablesList.innerHTML = '';[m
 [m
[36m@@ -1189,7 +1739,6 @@[m
                         <div class="coordinate-display">[m
                             Display Page: ${variable.page} → Config Page: ${variable.page - 1} (0-based)[m
                             <br>PDF Coords: X: ${variable.x} | Y: ${variable.y}[m
[31m-                            <br><small style="color: #6c757d;">pdf_text_overlay uses 0-based page numbering</small>[m
                         </div>[m
                         <div class="form-group">[m
                             <label>Page Number:</label>[m
[36m@@ -1221,22 +1770,222 @@[m
             });[m
         }[m
 [m
[32m+[m[32m        function updateImagesList() {[m
[32m+[m[32m            imagesList.innerHTML = '';[m
[32m+[m
[32m+[m[32m            images.forEach((image, index) => {[m
[32m+[m[32m                const div = document.createElement('div');[m
[32m+[m[32m                div.className = 'image-item';[m
[32m+[m
[32m+[m[32m                div.innerHTML = `[m
[32m+[m[32m                    <div class="image-header">[m
[32m+[m[32m                        <strong>🖼️ Image ${index + 1}</strong>[m
[32m+[m[32m                        <button class="remove-btn" onclick="removeImage(${index})">Remove</button>[m
[32m+[m[32m                    </div>[m
[32m+[m[32m                    <div class="coordinate-display">[m
[32m+[m[32m                        Variable Name: ${image.name}[m
[32m+[m[32m                        <br>Reference File: ${image.filename}[m
[32m+[m[32m                        <br>Page: ${image.page} | Position: (${image.x}, ${image.y})[m
[32m+[m[32m                        <br>Size: ${image.width} x ${image.height}[m
[32m+[m[32m                        <br><small>💡 Add "${image.name}" key with image URL to sample data</small>[m
[32m+[m[32m                        <br><small style="color: #007bff;">Uploaded URL: ${(() => {[m
[32m+[m[32m                            const uploadedImg = uploadedImages.find(img => img.filename === image.filename);[m
[32m+[m[32m                            return uploadedImg ? window.location.origin + uploadedImg.url : 'Not found';[m
[32m+[m[32m                        })()}</small>[m
[32m+[m[32m                    </div>[m
[32m+[m[32m                    <div class="form-group">[m
[32m+[m[32m                        <label>Variable Name:</label>[m
[32m+[m[32m                        <input type="text" class="form-control" value="${image.name}"[m[41m [m
[32m+[m[32m                               placeholder="e.g., logo, signature"[m
[32m+[m[32m                               onchange="updateImage(${index}, 'name', this.value)">[m
[32m+[m[32m                    </div>[m
[32m+[m[32m                    <div class="form-group">[m
[32m+[m[32m                        <label>Reference Image File:</label>[m
[32m+[m[32m                        <select class="form-control" onchange="updateImage(${index}, 'filename', this.value)">[m
[32m+[m[32m                            ${uploadedImages.map(img =>[m[41m [m
[32m+[m[32m                                `<option value="${img.filename}" ${img.filename === image.filename ? 'selected' : ''}>${img.filename}</option>`[m
[32m+[m[32m                            ).join('')}[m
[32m+[m[32m                        </select>[m
[32m+[m[32m                        <small style="color: #666; font-size: 0.8rem;">This is just for reference. Actual image comes from sample data URL.</small>[m
[32m+[m[32m                    </div>[m
[32m+[m[32m                    <div class="form-group">[m
[32m+[m[32m                        <label>Page Number:</label>[m
[32m+[m[32m                        <input type="number" class="form-control" value="${image.page}" min="1" max="${totalPages || 999}"[m
[32m+[m[32m                               onchange="updateImage(${index}, 'page', this.value)">[m
[32m+[m[32m                    </div>[m
[32m+[m[32m                    <div style="display: flex; gap: 10px;">[m
[32m+[m[32m                        <div class="form-group" style="flex: 1;">[m
[32m+[m[32m                            <label>X Coordinate:</label>[m
[32m+[m[32m                            <input type="number" class="form-control" value="${image.x}"[m
[32m+[m[32m                                   onchange="updateImage(${index}, 'x', this.value)">[m
[32m+[m[32m                        </div>[m
[32m+[m[32m                        <div class="form-group" style="flex: 1;">[m
[32m+[m[32m                            <label>Y Coordinate:</label>[m
[32m+[m[32m                            <input type="number" class="form-control" value="${image.y}"[m
[32m+[m[32m                                   onchange="updateImage(${index}, 'y', this.value)">[m
[32m+[m[32m                        </div>[m
[32m+[m[32m                    </div>[m
[32m+[m[32m                    <div style="display: flex; gap: 10px;">[m
[32m+[m[32m                        <div class="form-group" style="flex: 1;">[m
[32m+[m[32m                            <label>Width:</label>[m
[32m+[m[32m                            <input type="number" class="form-control" value="${image.width}" min="10"[m
[32m+[m[32m                                   onchange="updateImage(${index}, 'width', this.value)">[m
[32m+[m[32m                        </div>[m
[32m+[m[32m                        <div class="form-group" style="flex: 1;">[m
[32m+[m[32m                            <label>Height:</label>[m
[32m+[m[32m                            <input type="number" class="form-control" value="${image.height}" min="10"[m
[32m+[m[32m                                   onchange="updateImage(${index}, 'height', this.value)">[m
[32m+[m[32m                        </div>[m
[32m+[m[32m                    </div>[m
[32m+[m[32m                `;[m
[32m+[m[32m                imagesList.appendChild(div);[m
[32m+[m[32m            });[m
[32m+[m
[32m+[m[32m            if (images.length === 0) {[m
[32m+[m[32m                imagesList.innerHTML = '<div style="text-align: center; color: #666;">No image overlays added yet. Switch to Image mode and click on the PDF to add images.</div>';[m
[32m+[m[32m            }[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        function updateShapesList() {[m
[32m+[m[32m            shapesList.innerHTML = '';[m
[32m+[m
[32m+[m[32m            shapes.forEach((shape, index) => {[m
[32m+[m[32m                const div = document.createElement('div');[m
[32m+[m[32m                div.className = 'shape-item';[m
[32m+[m
[32m+[m[32m                let shapeSpecificFields = '';[m
[32m+[m[32m                if (shape.type === 'circle') {[m
[32m+[m[32m                    shapeSpecificFields = `[m
[32m+[m[32m                        <div class="form-group">[m
[32m+[m[32m                            <label>Radius:</label>[m
[32m+[m[32m                            <input type="number" class="form-control" value="${shape.radius || 25}" min="5"[m
[32m+[m[32m                                   onchange="updateShape(${index}, 'radius', this.value)">[m
[32m+[m[32m                        </div>[m
[32m+[m[32m                    `;[m
[32m+[m[32m                } else if (shape.type === 'line') {[m
[32m+[m[32m                    shapeSpecificFields = `[m
[32m+[m[32m                        <div style="display: flex; gap: 10px;">[m
[32m+[m[32m                            <div class="form-group" style="flex: 1;">[m
[32m+[m[32m                                <label>End X:</label>[m
[32m+[m[32m                                <input type="number" class="form-control" value="${shape.end_x || shape.x + 50}"[m
[32m+[m[32m                                       onchange="updateShape(${index}, 'end_x', this.value)">[m
[32m+[m[32m                            </div>[m
[32m+[m[32m                            <div class="form-group" style="flex: 1;">[m
[32m+[m[32m                                <label>End Y:</label>[m
[32m+[m[32m                                <input type="number" class="form-control" value="${shape.end_y || shape.y}"[m
[32m+[m[32m                                       onchange="updateShape(${index}, 'end_y', this.value)">[m
[32m+[m[32m                            </div>[m
[32m+[m[32m                        </div>[m
[32m+[m[32m                    `;[m
[32m+[m[32m                } else {[m
[32m+[m[32m                    shapeSpecificFields = `[m
[32m+[m[32m                        <div style="display: flex; gap: 10px;">[m
[32m+[m[32m                            <div class="form-group" style="flex: 1;">[m
[32m+[m[32m                                <label>Width:</label>[m
[32m+[m[32m                                <input type="number" class="form-control" value="${shape.width}" min="5"[m
[32m+[m[32m                                       onchange="updateShape(${index}, 'width', this.value)">[m
[32m+[m[32m                            </div>[m
[32m+[m[32m                            <div class="form-group" style="flex: 1;">[m
[32m+[m[32m                                <label>Height:</label>[m
[32m+[m[32m                                <input type="number" class="form-control" value="${shape.height}" min="5"[m
[32m+[m[32m                                       onchange="updateShape(${index}, 'height', this.value)">[m
[32m+[m[32m                            </div>[m
[32m+[m[32m                        </div>[m
[32m+[m[32m                    `;[m
[32m+[m[32m                }[m
[32m+[m
[32m+[m[32m                div.innerHTML = `[m
[32m+[m[32m                    <div class="shape-header">[m
[32m+[m[32m                        <strong>🔲 ${shape.type} ${index + 1}</strong>[m
[32m+[m[32m                        <button class="remove-btn" onclick="removeShape(${index})">Remove</button>[m
[32m+[m[32m                    </div>[m
[32m+[m[32m                    <div class="coordinate-display">[m
[32m+[m[32m                        Type: ${shape.type} | Page: ${shape.page}[m
[32m+[m[32m                        <br>Position: (${shape.x}, ${shape.y}) PDF | (${(shape.x/72).toFixed(2)}", ${(shape.y/72).toFixed(2)}") inches[m
[32m+[m[32m                        <br>Color: ${shape.color} | Fill: ${shape.fill ? 'Yes' : 'No'}[m
[32m+[m[32m                        ${shape.type === 'line' ? `<br>End: (${shape.end_x}, ${shape.end_y}) PDF | (${(shape.end_x/72).toFixed(2)}", ${(shape.end_y/72).toFixed(2)}") inches` : ''}[m
[32m+[m[32m                        ${shape.type === 'line' ? `<br>Length: ${Math.sqrt(Math.pow(shape.end_x - shape.x, 2) + Math.pow(shape.end_y - shape.y, 2)).toFixed(1)} points` : ''}[m
[32m+[m[32m                    </div>[m
[32m+[m[32m                    <div class="form-group">[m
[32m+[m[32m                        <label>Shape Type:</label>[m
[32m+[m[32m                        <select class="form-control" onchange="updateShape(${index}, 'type', this.value)">[m
[32m+[m[32m                            <option value="rectangle" ${shape.type === 'rectangle' ? 'selected' : ''}>Rectangle</option>[m
[32m+[m[32m                            <option value="circle" ${shape.type === 'circle' ? 'selected' : ''}>Circle</option>[m
[32m+[m[32m                            <option value="line" ${shape.type === 'line' ? 'selected' : ''}>Line</option>[m
[32m+[m[32m                        </select>[m
[32m+[m[32m                    </div>[m
[32m+[m[32m                    <div class="form-group">[m
[32m+[m[32m                        <label>Page Number:</label>[m
[32m+[m[32m                        <input type="number" class="form-control" value="${shape.page}" min="1" max="${totalPages || 999}"[m
[32m+[m[32m                               onchange="updateShape(${index}, 'page', this.value)">[m
[32m+[m[32m                    </div>[m
[32m+[m[32m                    <div style="display: flex; gap: 10px;">[m
[32m+[m[32m                        <div class="form-group" style="flex: 1;">[m
[32m+[m[32m                            <label>${shape.type === 'line' ? 'Start X' : 'X Coordinate'}:</label>[m
[32m+[m[32m                            <input type="number" class="form-control" value="${shape.x}"[m
[32m+[m[32m                                   onchange="updateShape(${index}, 'x', this.value)">[m
[32m+[m[32m                        </div>[m
[32m+[m[32m                        <div class="form-group" style="flex: 1;">[m
[32m+[m[32m                            <label>${shape.type === 'line' ? 'Start Y' : 'Y Coordinate'}:</label>[m
[32m+[m[32m                            <input type="number" class="form-control" value="${shape.y}"[m
[32m+[m[32m                                   onchange="updateShape(${index}, 'y', this.value)">[m
[32m+[m[32m                        </div>[m
[32m+[m[32m                    </div>[m
[32m+[m[32m                    ${shapeSpecificFields}[m
[32m+[m[32m                    <div style="display: flex; gap: 10px;">[m
[32m+[m[32m                        <div class="form-group" style="flex: 1;">[m
[32m+[m[32m                            <label>Color:</label>[m
[32m+[m[32m                            <input type="color" class="form-control" value="${shape.color}" style="height: 40px;"[m
[32m+[m[32m                                   onchange="updateShape(${index}, 'color', this.value)">[m
[32m+[m[32m                        </div>[m
[32m+[m[32m                        <div class="form-group" style="flex: 1;">[m
[32m+[m[32m                            <label>Stroke Width:</label>[m
[32m+[m[32m                            <input type="number" class="form-control" value="${shape.stroke_width}" min="1" max="10"[m
[32m+[m[32m                                   onchange="updateShape(${index}, 'stroke_width', this.value)">[m
[32m+[m[32m                        </div>[m
[32m+[m[32m                    </div>[m
[32m+[m[32m                    <div class="form-group">[m
[32m+[m[32m                        <label>Fill Shape:</label>[m
[32m+[m[32m                        <select class="form-control" onchange="updateShape(${index}, 'fill', this.value)" ${shape.type === 'line' ? 'disabled' : ''}>[m
[32m+[m[32m                            <option value="false" ${!shape.fill ? 'selected' : ''}>No (Outline only)</option>[m
[32m+[m[32m                            <option value="true" ${shape.fill ? 'selected' : ''}>Yes (Filled)</option>[m
[32m+[m[32m                        </select>[m
[32m+[m[32m                        ${shape.type === 'line' ? '<small style="color: #666;">Lines cannot be filled</small>' : ''}[m
[32m+[m[32m                    </div>[m
[32m+[m[32m                    ${shape.type === 'line' ? `[m
[32m+[m[32m                        <div style="margin-top: 15px; padding: 10px; background: #e3f2fd; border-radius: 5px;">[m
[32m+[m[32m                            <small><strong>💡 Line Tips:</strong>[m[41m [m
[32m+[m[32m                            <br>• Use "Shape Mode" and select "Line (two-point)" for interactive drawing[m
[32m+[m[32m                            <br>• Click twice on PDF: first for start point, second for end point[m
[32m+[m[32m                            <br>• Manually adjust coordinates above for precise positioning</small>[m
[32m+[m[32m                        </div>[m
[32m+[m[32m                    ` : ''}[m
[32m+[m[32m                `;[m
[32m+[m[32m                shapesList.appendChild(div);[m
[32m+[m[32m            });[m
[32m+[m
[32m+[m[32m            if (shapes.length === 0) {[m
[32m+[m[32m                shapesList.innerHTML = '<div style="text-align: center; color: #666;">No shape overlays added yet. Switch to Shape mode and click on the PDF to add shapes.</div>';[m
[32m+[m[32m            }[m
[32m+[m[32m        }[m
[32m+[m
         function updateConfiguration() {[m
[31m-            if (variables.length === 0) {[m
[31m-                configOutput.textContent = 'Click on the PDF to start adding variables...';[m
[32m+[m[32m            if (variables.length === 0 && images.length === 0 && shapes.length === 0) {[m
[32m+[m[32m                configOutput.textContent = 'Click on the PDF to start adding elements...';[m
                 return;[m
             }[m
 [m
             const pageGroups = {};[m
[32m+[m[41m            [m
[32m+[m[32m            // Group variables by page[m
             variables.forEach(variable => {[m
[31m-                // Convert 1-based display page to 0-based page for pdf_text_overlay[m
                 const zeroBasedPage = variable.page - 1;[m
                 if (!pageGroups[zeroBasedPage]) {[m
[31m-                    pageGroups[zeroBasedPage] = [];[m
[32m+[m[32m                    pageGroups[zeroBasedPage] = { variables: [], images: [] };[m
                 }[m
 [m
                 if (variable.type === 'simple') {[m
[31m-                    pageGroups[zeroBasedPage].push({[m
[32m+[m[32m                    pageGroups[zeroBasedPage].variables.push({[m
                         name: variable.name,[m
                         "x-coordinate": variable.x,[m
                         "y-coordinate": variable.y,[m
[36m@@ -1252,20 +2001,205 @@[m
                             "y-coordinate": cond.y[m
                         }))[m
                     };[m
[31m-                    pageGroups[zeroBasedPage].push(conditionalVar);[m
[32m+[m[32m                    pageGroups[zeroBasedPage].variables.push(conditionalVar);[m
[32m+[m[32m                }[m
[32m+[m[32m            });[m
[32m+[m
[32m+[m[32m            // Group images by page (convert to image variables)[m
[32m+[m[32m            images.forEach(image => {[m
[32m+[m[32m                const zeroBasedPage = image.page - 1;[m
[32m+[m[32m                if (!pageGroups[zeroBasedPage]) {[m
[32m+[m[32m                    pageGroups[zeroBasedPage] = { variables: [], images: [] };[m
[32m+[m[32m                }[m
[32m+[m
[32m+[m[32m                pageGroups[zeroBasedPage].variables.push({[m
[32m+[m[32m                    name: image.name,[m
[32m+[m[32m                    image: {[m
[32m+[m[32m                        "x-coordinate": image.x,[m
[32m+[m[32m                        "y-coordinate": image.y,[m
[32m+[m[32m                        width: image.width,[m
[32m+[m[32m                        height: image.height[m
[32m+[m[32m                    }[m
[32m+[m[32m                });[m
[32m+[m[32m            });[m
[32m+[m
[32m+[m[32m            // Group shapes by page (convert to draw_shape variables)[m
[32m+[m[32m            shapes.forEach(shape => {[m
[32m+[m[32m                const zeroBasedPage = shape.page - 1;[m
[32m+[m[32m                if (!pageGroups[zeroBasedPage]) {[m
[32m+[m[32m                    pageGroups[zeroBasedPage] = { variables: [], images: [], shapes: [] };[m
[32m+[m[32m                }[m
[32m+[m
[32m+[m[32m                // Convert RGB hex color to individual components[m
[32m+[m[32m                const colorHex = shape.color.replace('#', '');[m
[32m+[m[32m                const r = parseInt(colorHex.substring(0, 2), 16) / 255.0;[m
[32m+[m[32m                const g = parseInt(colorHex.substring(2, 4), 16) / 255.0;[m
[32m+[m[32m                const b = parseInt(colorHex.substring(4, 6), 16) / 255.0;[m
[32m+[m
[32m+[m[32m                // Convert PDF coordinates to inches (assuming 72 DPI)[m
[32m+[m[32m                const x0_inches = shape.x / 72.0;[m
[32m+[m[32m                const y0_inches = shape.y / 72.0;[m
[32m+[m
[32m+[m[32m                const shapeConfig = {[m
[32m+[m[32m                    name: 'draw_shape',[m
[32m+[m[32m                    draw_shape: {[m
[32m+[m[32m                        r: parseFloat(r.toFixed(3)),[m
[32m+[m[32m                        g: parseFloat(g.toFixed(3)),[m
[32m+[m[32m                        b: parseFloat(b.toFixed(3)),[m
[32m+[m[32m                        shape: shape.type.charAt(0).toUpperCase() + shape.type.slice(1),[m
[32m+[m[32m                        'x0-coordinate': parseFloat(x0_inches.toFixed(3) - 0.95),[m
[32m+[m[32m                        'y0-coordinate': parseFloat(y0_inches.toFixed(3) - 0.95)[m
[32m+[m[32m                    }[m
[32m+[m[32m                };[m
[32m+[m
[32m+[m[32m                // Add shape-specific coordinates[m
[32m+[m[32m                if (shape.type === 'rectangle') {[m
[32m+[m[32m                    shapeConfig.draw_shape['x1-coordinate'] = parseFloat(((shape.x + shape.width) / 72.0).toFixed(3));[m
[32m+[m[32m                    shapeConfig.draw_shape['y1-coordinate'] = parseFloat(((shape.y + shape.height) / 72.0).toFixed(3));[m
[32m+[m[32m                } else if (shape.type === 'circle') {[m
[32m+[m[32m                    const radiusInches = shape.radius / 72.0;[m
[32m+[m[32m                    shapeConfig.draw_shape['x1-coordinate'] = parseFloat((x0_inches + radiusInches).toFixed(3));[m
[32m+[m[32m                    shapeConfig.draw_shape['y1-coordinate'] = parseFloat((y0_inches + radiusInches).toFixed(3));[m
[32m+[m[32m                } else if (shape.type === 'line') {[m
[32m+[m[32m                    shapeConfig.draw_shape['x1-coordinate'] = parseFloat((shape.end_x / 72.0).toFixed(3) - 0.95);[m
[32m+[m[32m                    shapeConfig.draw_shape['y1-coordinate'] = parseFloat((shape.end_y / 72.0).toFixed(3) - 0.95);[m
                 }[m
[32m+[m
[32m+[m[32m                pageGroups[zeroBasedPage].variables.push(shapeConfig);[m
             });[m
 [m
             const configuration = Object.keys(pageGroups).map(page => ({[m
[31m-                page_number: parseInt(page), // This will be 0-based[m
[31m-                variables: pageGroups[page][m
[32m+[m[32m                page_number: parseInt(page),[m
[32m+[m[32m                variables: pageGroups[page].variables[m
             }));[m
 [m
             configOutput.textContent = JSON.stringify(configuration, null, 2);[m
         }[m
 [m
[32m+[m[32m        function loadFromConfiguration() {[m
[32m+[m[32m            try {[m
[32m+[m[32m                const configText = configOutput.value || configOutput.textContent;[m
[32m+[m[32m                if (!configText || configText === 'Click on the PDF to start adding elements...') {[m
[32m+[m[32m                    showNotification('No configuration to load', 'error');[m
[32m+[m[32m                    return;[m
[32m+[m[32m                }[m
[32m+[m
[32m+[m[32m                const config = JSON.parse(configText);[m
[32m+[m[32m                if (!Array.isArray(config)) {[m
[32m+[m[32m                    showNotification('Invalid configuration format - must be an array', 'error');[m
[32m+[m[32m                    return;[m
[32m+[m[32m                }[m
[32m+[m
[32m+[m[32m                // Reset all arrays[m
[32m+[m[32m                variables = [];[m
[32m+[m[32m                images = [];[m
[32m+[m[32m                shapes = [];[m
[32m+[m
[32m+[m[32m                config.forEach(pageConfig => {[m
[32m+[m[32m                    const displayPage = pageConfig.page_number + 1;[m
[32m+[m
[32m+[m[32m                    // Load variables (including draw_shape variables)[m
[32m+[m[32m                    if (pageConfig.variables && Array.isArray(pageConfig.variables)) {[m
[32m+[m[32m                        pageConfig.variables.forEach(variable => {[m
[32m+[m[32m                            if (variable.name === 'draw_shape' && variable.draw_shape) {[m
[32m+[m[32m                                // Handle draw_shape variables[m
[32m+[m[32m                                const drawShape = variable.draw_shape;[m
[32m+[m[41m                                [m
[32m+[m[32m                                // Convert RGB values back to hex[m
[32m+[m[32m                                const r = Math.round((drawShape.r || 0) * 255);[m
[32m+[m[32m                                const g = Math.round((drawShape.g || 0) * 255);[m
[32m+[m[32m                                const b = Math.round((drawShape.b || 0) * 255);[m
[32m+[m[32m                                const colorHex = '#' + [r, g, b].map(x => x.toString(16).padStart(2, '0')).join('');[m
[32m+[m[41m                                [m
[32m+[m[32m                                // Convert inches back to PDF coordinates (72 DPI)[m
[32m+[m[32m                                const x0 = Math.round((drawShape['x0-coordinate'] || 0) * 72);[m
[32m+[m[32m                                const y0 = Math.round((drawShape['y0-coordinate'] || 0) * 72);[m
[32m+[m[32m                                const x1 = Math.round((drawShape['x1-coordinate'] || 0) * 72);[m
[32m+[m[32m                                const y1 = Math.round((drawShape['y1-coordinate'] || 0) * 72);[m
[32m+[m[41m                                [m
[32m+[m[32m                                const newShape = {[m
[32m+[m[32m                                    type: (drawShape.shape || 'rectangle').toLowerCase(),[m
[32m+[m[32m                                    x: x0,[m
[32m+[m[32m                                    y: y0,[m
[32m+[m[32m                                    page: displayPage,[m
[32m+[m[32m                                    color: colorHex,[m
[32m+[m[32m                                    fill: false,[m
[32m+[m[32m                                    stroke_width: 1[m
[32m+[m[32m                                };[m
[32m+[m[41m                                [m
[32m+[m[32m                                if (newShape.type === 'rectangle') {[m
[32m+[m[32m                                    newShape.width = Math.abs(x1 - x0);[m
[32m+[m[32m                                    newShape.height = Math.abs(y1 - y0);[m
[32m+[m[32m                                } else if (newShape.type === 'circle') {[m
[32m+[m[32m                                    newShape.radius = Math.abs(x1 - x0); // Using x difference as radius[m
[32m+[m[32m                                } else if (newShape.type === 'line') {[m
[32m+[m[32m                                    newShape.end_x = x1;[m
[32m+[m[32m                                    newShape.end_y = y1;[m
[32m+[m[32m                                }[m
[32m+[m[41m                                [m
[32m+[m[32m                                shapes.push(newShape);[m
[32m+[m[32m                            } else if (variable.conditional_coordinates) {[m
[32m+[m[32m                                // Handle conditional text variables[m
[32m+[m[32m                                const newVar = {[m
[32m+[m[32m                                    name: variable.name,[m
[32m+[m[32m                                    x: 0,[m
[32m+[m[32m                                    y: 0,[m
[32m+[m[32m                                    page: displayPage,[m
[32m+[m[32m                                    fontSize: 12,[m
[32m+[m[32m                                    type: 'conditional',[m
[32m+[m[32m                                    conditionalCoordinates: variable.conditional_coordinates.map(cond => ({[m
[32m+[m[32m                                        if_value: cond.if_value || '',[m
[32m+[m[32m                                        print_pattern: cond.print_pattern || '*',[m
[32m+[m[32m                                        x: cond['x-coordinate'] || 0,[m
[32m+[m[32m                                        y: cond['y-coordinate'] || 0,[m
[32m+[m[32m                                        displayX: cond['x-coordinate'] || 0,[m
[32m+[m[32m                                        displayY: cond['y-coordinate'] || 0[m
[32m+[m[32m                                    }))[m
[32m+[m[32m                                };[m
[32m+[m[32m                                variables.push(newVar);[m
[32m+[m[32m                            } else if (variable.image) {[m
[32m+[m[32m                                // Handle image variables[m
[32m+[m[32m                                const newImage = {[m
[32m+[m[32m                                    name: variable.name,[m
[32m+[m[32m                                    filename: 'placeholder.png', // Default filename since actual image comes from data[m
[32m+[m[32m                                    x: variable.image['x-coordinate'] || 0,[m
[32m+[m[32m                                    y: variable.image['y-coordinate'] || 0,[m
[32m+[m[32m                                    page: displayPage,[m
[32m+[m[32m                                    width: variable.image.width || 100,[m
[32m+[m[32m                                    height: variable.image.height || 100[m
[32m+[m[32m                                };[m
[32m+[m[32m                                images.push(newImage);[m
[32m+[m[32m                            } else {[m
[32m+[m[32m                                // Handle simple text variables[m
[32m+[m[32m                                const newVar = {[m
[32m+[m[32m                                    name: variable.name,[m
[32m+[m[32m                                    x: variable['x-coordinate'] || 0,[m
[32m+[m[32m                                    y: variable['y-coordinate'] || 0,[m
[32m+[m[32m                                    displayX: variable['x-coordinate'] || 0,[m
[32m+[m[32m                                    displayY: variable['y-coordinate'] || 0,[m
[32m+[m[32m                                    page: displayPage,[m
[32m+[m[32m                                    fontSize: variable.font_size || 12,[m
[32m+[m[32m                                    type: 'simple',[m
[32m+[m[32m                                    conditionalCoordinates: [][m
[32m+[m[32m                                };[m
[32m+[m[32m                                variables.push(newVar);[m
[32m+[m[32m                            }[m
[32m+[m[32m                        });[m
[32m+[m[32m                    }[m
[32m+[m[32m                });[m
[32m+[m
[32m+[m[32m                updateAllLists();[m
[32m+[m[32m                renderAllOverlays();[m
[32m+[m[32m                showNotification(`Configuration loaded successfully! ${variables.length} variables, ${images.length} images, ${shapes.length} shapes imported.`);[m
[32m+[m
[32m+[m[32m            } catch (error) {[m
[32m+[m[32m                showNotification('Invalid JSON configuration: ' + error.message, 'error');[m
[32m+[m[32m                console.error('Config parsing error:', error);[m
[32m+[m[32m            }[m
[32m+[m[32m        }[m
[32m+[m
         function copyConfiguration() {[m
[31m-            if (configOutput.textContent && configOutput.textContent !== 'Click on the PDF to start adding variables...') {[m
[32m+[m[32m            if (configOutput.textContent && configOutput.textContent !== 'Click on the PDF to start adding elements...') {[m
                 navigator.clipboard.writeText(configOutput.textContent).then(() => {[m
                     showNotification('Configuration copied to clipboard!');[m
                 });[m
[36m@@ -1273,7 +2207,7 @@[m
         }[m
 [m
         function saveConfiguration() {[m
[31m-            if (variables.length === 0) {[m
[32m+[m[32m            if (variables.length === 0 && images.length === 0 && shapes.length === 0) {[m
                 showNotification('No configuration to save', 'error');[m
                 return;[m
             }[m
[36m@@ -1281,40 +2215,8 @@[m
             const configName = prompt('Enter configuration name:', `config_${new Date().toISOString().slice(0,19).replace(/:/g, '-')}`);[m
             if (!configName) return;[m
 [m
[31m-            const pageGroups = {};[m
[31m-            variables.forEach(variable => {[m
[31m-                // Convert 1-based display page to 0-based page for pdf_text_overlay[m
[31m-                const zeroBasedPage = variable.page - 1;[m
[31m-                if (!pageGroups[zeroBasedPage]) {[m
[31m-                    pageGroups[zeroBasedPage] = [];[m
[31m-                }[m
[31m-[m
[31m-                if (variable.type === 'simple') {[m
[31m-                    pageGroups[zeroBasedPage].push({[m
[31m-                        name: variable.name,[m
[31m-                        "x-coordinate": variable.x,[m
[31m-                        "y-coordinate": variable.y,[m
[31m-                        font_size: variable.fontSize[m
[31m-                    });[m
[31m-                } else if (variable.type === 'conditional') {[m
[31m-                    const conditionalVar = {[m
[31m-                        name: variable.name,[m
[31m-                        conditional_coordinates: variable.conditionalCoordinates.map(cond => ({[m
[31m-                            if_value: cond.if_value,[m
[31m-                            print_pattern: cond.print_pattern,[m
[31m-                            "x-coordinate": cond.x,[m
[31m-                            "y-coordinate": cond.y[m
[31m-                        }))[m
[31m-                    };[m
[31m-                    pageGroups[zeroBasedPage].push(conditionalVar);[m
[31m-                }[m
[31m-            });[m
[31m-[m
[31m-            const configuration = Object.keys(pageGroups).map(page => ({[m
[31m-                page_number: parseInt(page), // This will be 0-based[m
[31m-                variables: pageGroups[page][m
[31m-            }));[m
[31m-[m
[32m+[m[32m            const configText = configOutput.textContent;[m
[32m+[m[41m            [m
             fetch('/api/save-config', {[m
                 method: 'POST',[m
                 headers: {[m
[36m@@ -1322,7 +2224,7 @@[m
                 },[m
                 body: JSON.stringify({[m
                     name: configName,[m
[31m-                    configuration: configuration[m
[32m+[m[32m                    configuration: JSON.parse(configText)[m
                 })[m
             })[m
             .then(response => response.json())[m
[36m@@ -1340,15 +2242,20 @@[m
 [m
         function prefillSampleData() {[m
             const variableNames = variables.map(v => v.name);[m
[31m-            if (variableNames.length === 0) {[m
[31m-                showNotification('Please add some variables first by clicking on the PDF.', 'error');[m
[32m+[m[32m            const imageNames = images.map(img => img.name);[m
[32m+[m[32m            const allNames = [...variableNames, ...imageNames];[m
[32m+[m[41m            [m
[32m+[m[32m            if (allNames.length === 0) {[m
[32m+[m[32m                showNotification('Please add some variables or images first by clicking on the PDF.', 'error');[m
                 return;[m
             }[m
 [m
             const sampleObj = {};[m
[32m+[m[41m            [m
[32m+[m[32m            // Add text variables[m
             variableNames.forEach(name => {[m
                 if (name.toLowerCase().includes('gender')) {[m
[31m-                    sampleObj[name] = 'Male'; // Will trigger conditional coordinates[m
[32m+[m[32m                    sampleObj[name] = 'Male';[m
                 } else if (name.toLowerCase().includes('name')) {[m
                     sampleObj[name] = 'John Doe';[m
                 } else if (name.toLowerCase().includes('email')) {[m
[36m@@ -1362,14 +2269,35 @@[m
                 } else if (name.toLowerCase().includes('company')) {[m
                     sampleObj[name] = 'Example Company Inc.';[m
                 } else if (name.toLowerCase().includes('status') || name.toLowerCase().includes('type')) {[m
[31m-                    sampleObj[name] = 'Active'; // Will trigger conditional coordinates[m
[32m+[m[32m                    sampleObj[name] = 'Active';[m
                 } else {[m
                     sampleObj[name] = `Sample ${name}`;[m
                 }[m
             });[m
[32m+[m[41m            [m
[32m+[m[32m            // Add image variables with actual uploaded image URLs[m
[32m+[m[32m            images.forEach(image => {[m
[32m+[m[32m                // Find the corresponding uploaded image URL[m
[32m+[m[32m                const uploadedImage = uploadedImages.find(img => img.filename === image.filename);[m
[32m+[m[32m                if (uploadedImage && uploadedImage.url) {[m
[32m+[m[32m                    // Use the actual uploaded image URL[m
[32m+[m[32m                    sampleObj[image.name] = window.location.origin + uploadedImage.url;[m
[32m+[m[32m                } else {[m
[32m+[m[32m                    // Fallback to example URL if uploaded image not found[m
[32m+[m[32m                    if (image.name.toLowerCase().includes('logo')) {[m
[32m+[m[32m                        sampleObj[image.name] = 'https://example.com/logo.png';[m
[32m+[m[32m                    } else if (image.name.toLowerCase().includes('signature')) {[m
[32m+[m[32m                        sampleObj[image.name] = 'https://example.com/signature.png';[m
[32m+[m[32m                    } else if (image.name.toLowerCase().includes('photo')) {[m
[32m+[m[32m                        sampleObj[image.name] = 'https://example.com/photo.jpg';[m
[32m+[m[32m                    } else {[m
[32m+[m[32m                        sampleObj[image.name] = `https://example.com/${image.name}.png`;[m
[32m+[m[32m                    }[m
[32m+[m[32m                }[m
[32m+[m[32m            });[m
 [m
             sampleData.value = JSON.stringify(sampleObj, null, 2);[m
[31m-            showNotification('Sample data generated based on variable names!');[m
[32m+[m[32m            showNotification('Sample data generated with actual uploaded image URLs!');[m
         }[m
 [m
         async function processDocument() {[m
[36m@@ -1378,8 +2306,8 @@[m
                 return;[m
             }[m
 [m
[31m-            if (variables.length === 0) {[m
[31m-                showNotification('Please add some variables first', 'error');[m
[32m+[m[32m            if (variables.length === 0 && images.length === 0 && shapes.length === 0) {[m
[32m+[m[32m                showNotification('Please add some elements first', 'error');[m
                 return;[m
             }[m
 [m
[36m@@ -1394,41 +2322,10 @@[m
             showLoading(processLoading);[m
             processBtn.disabled = true;[m
 [m
[31m-            const pageGroups = {};[m
[31m-            variables.forEach(variable => {[m
[31m-                // Convert 1-based display page to 0-based page for pdf_text_overlay[m
[31m-                const zeroBasedPage = variable.page - 1;[m
[31m-                if (!pageGroups[zeroBasedPage]) {[m
[31m-                    pageGroups[zeroBasedPage] = [];[m
[31m-                }[m
[31m-[m
[31m-                if (variable.type === 'simple') {[m
[31m-                    pageGroups[zeroBasedPage].push({[m
[31m-                        name: variable.name,[m
[31m-                        "x-coordinate": variable.x,[m
[31m-                        "y-coordinate": variable.y,[m
[31m-                        font_size: variable.fontSize[m
[31m-                    });[m
[31m-                } else if (variable.type === 'conditional') {[m
[31m-                    const conditionalVar = {[m
[31m-                        name: variable.name,[m
[31m-                        conditional_coordinates: variable.conditionalCoordinates.map(cond => ({[m
[31m-                            if_value: cond.if_value,[m
[31m-                            print_pattern: cond.print_pattern,[m
[31m-                            "x-coordinate": cond.x,[m
[31m-                            "y-coordinate": cond.y[m
[31m-                        }))[m
[31m-                    };[m
[31m-                    pageGroups[zeroBasedPage].push(conditionalVar);[m
[31m-                }[m
[31m-            });[m
[31m-[m
[31m-            const configuration = Object.keys(pageGroups).map(page => ({[m
[31m-                page_number: parseInt(page), // This will be 0-based[m
[31m-                variables: pageGroups[page][m
[31m-            }));[m
[31m-[m
             try {[m
[32m+[m[32m                const configText = configOutput.textContent;[m
[32m+[m[32m                const configuration = JSON.parse(configText);[m
[32m+[m
                 const response = await fetch('/api/process', {[m
                     method: 'POST',[m
                     headers: {[m
[36m@@ -1443,7 +2340,7 @@[m
                 const result = await response.json();[m
 [m
                 if (result.success) {[m
[31m-                    showNotification('PDF processed successfully!');[m
[32m+[m[32m                    showNotification('PDF processed successfully with all overlays!');[m
                     processedFilename = result.output_filename;[m
                     downloadSection.style.display = 'block';[m
                 } else {[m
[36m@@ -1466,16 +2363,66 @@[m
             window.open(`/api/download/${processedFilename}`, '_blank');[m
         }[m
 [m
[32m+[m[32m        async function testImageAccessibility() {[m
[32m+[m[32m            if (uploadedImages.length === 0) {[m
[32m+[m[32m                showNotification('No images uploaded to test', 'error');[m
[32m+[m[32m                return;[m
[32m+[m[32m            }[m
[32m+[m
[32m+[m[32m            showNotification('Testing image accessibility...', 'success');[m
[32m+[m[41m            [m
[32m+[m[32m            for (const img of uploadedImages) {[m
[32m+[m[32m                try {[m
[32m+[m[32m                    const response = await fetch(`/api/test-image/${img.filename}`);[m
[32m+[m[32m                    const result = await response.json();[m
[32m+[m[41m                    [m
[32m+[m[32m                    console.log(`Image test result for ${img.filename}:`, result);[m
[32m+[m[41m                    [m
[32m+[m[32m                    if (!result.exists) {[m
[32m+[m[32m                        showNotification(`Image ${img.filename} not accessible!`, 'error');[m
[32m+[m[32m                        console.error(`Image not found: ${img.filename}`, result);[m
[32m+[m[32m                    }[m
[32m+[m[32m                } catch (error) {[m
[32m+[m[32m                    console.error(`Failed to test image ${img.filename}:`, error);[m
[32m+[m[32m                }[m
[32m+[m[32m            }[m
[32m+[m[41m            [m
[32m+[m[32m            showNotification('Image accessibility test completed. Check console for details.', 'success');[m
[32m+[m[32m        }[m
[32m+[m
         // Initialize with sample data[m
[31m-        sampleData.value = `{[m
[31m-  "name": "John Doe",[m
[31m-  "email": "john.doe@example.com",[m
[31m-  "date": "2024-01-15",[m
[31m-  "company": "Example Corp",[m
[31m-  "position": "Software Engineer",[m
[31m-  "gender": "Male",[m
[31m-  "status": "Active"[m
[31m-}`;[m
[32m+[m[32m        function initializeSampleData() {[m
[32m+[m[32m            const baseSampleData = {[m
[32m+[m[32m                "name": "John Doe",[m
[32m+[m[32m                "email": "john.doe@example.com",[m
[32m+[m[32m                "date": "2024-01-15",[m
[32m+[m[32m                "company": "Example Corp",[m
[32m+[m[32m                "position": "Software Engineer",[m
[32m+[m[32m                "gender": "Male",[m
[32m+[m[32m                "status": "Active"[m
[32m+[m[32m            };[m
[32m+[m
[32m+[m[32m            // Add image URLs if images are uploaded[m
[32m+[m[32m            if (uploadedImages.length > 0) {[m
[32m+[m[32m                uploadedImages.forEach((img, index) => {[m
[32m+[m[32m                    const imageName = `image_${index + 1}`;[m
[32m+[m[32m                    baseSampleData[imageName] = window.location.origin + img.url;[m
[32m+[m[32m                });[m
[32m+[m[32m            } else {[m
[32m+[m[32m                // Default image URLs[m
[32m+[m[32m                baseSampleData.logo = "https://example.com/logo.png";[m
[32m+[m[32m                baseSampleData.signature = "https://example.com/signature.png";[m
[32m+[m[32m            }[m
[32m+[m
[32m+[m[32m            sampleData.value = JSON.stringify(baseSampleData, null, 2);[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        // Initialize sample data on load and after image uploads[m
[32m+[m[32m        initializeSampleData();[m
[32m+[m
[32m+[m[32m        // Initialize mode and load existing images[m
[32m+[m[32m        setMode('text');[m
[32m+[m[32m        refreshImageList();[m
     </script>[m
 </body>[m
 </html>[m
\ No newline at end of file[m

[33mcommit 9f4b62cdd2a9ade14ed0a7b0aa702e05dbae28b6[m
Author: shridhar <shridhar.p@zerodha.com>
Date:   Sat May 31 09:36:02 2025 +0530

    feat: load existing config

[1mdiff --git a/templates/index.html b/templates/index.html[m
[1mindex 2355b90..8562067 100644[m
[1m--- a/templates/index.html[m
[1m+++ b/templates/index.html[m
[36m@@ -150,8 +150,8 @@[m
 [m
         .coordinate-dot {[m
             position: absolute;[m
[31m-            width: 4px;[m
[31m-            height: 4px;[m
[32m+[m[32m            width: 8px;[m
[32m+[m[32m            height: 8px;[m
             border-radius: 50%;[m
             transform: translate(-50%, -50%);[m
             z-index: 999;[m
[36m@@ -323,6 +323,7 @@[m
             white-space: pre-wrap;[m
             border: 2px solid #4a5568;[m
             line-height: 1.4;[m
[32m+[m[32m            width: 100%;[m
         }[m
 [m
         .click-instruction {[m
[36m@@ -490,14 +491,16 @@[m
                     <h3>📋 Generated Configuration</h3>[m
                     <div style="background: #e3f2fd; padding: 10px; border-radius: 5px; margin-bottom: 10px; font-size: 0.85rem;">[m
                         💡 <strong>Note:</strong> Page numbers in config are 0-based (Page 1 → 0, Page 2 → 1, etc.)[m
[32m+[m[32m                        <br>📝 You can edit the configuration directly below - changes will be applied when you click "Load from Config"[m
                     </div>[m
                     <div class="form-group">[m
[31m-                        <label>Configuration JSON:</label>[m
[31m-                        <div class="config-output" id="configOutput">Click on the PDF to start adding variables...</div>[m
[32m+[m[32m                        <label>Configuration JSON (Editable):</label>[m
[32m+[m[32m                        <textarea class="config-output" id="configOutput" contenteditable="true">Click on the PDF to start adding variables...</textarea>[m
                     </div>[m
                     <div style="display: flex; gap: 10px; margin-top: 15px; flex-wrap: wrap;">[m
                         <button class="btn" id="copyConfigBtn" style="flex: 1; min-width: 120px;">📋 Copy Config</button>[m
                         <button class="btn btn-secondary" id="saveConfigBtn" style="flex: 1; min-width: 120px;">💾 Save Config</button>[m
[32m+[m[32m                        <button class="btn btn-success" id="loadFromConfigBtn" style="flex: 1; min-width: 140px;">📥 Load from Config</button>[m
                     </div>[m
                 </div>[m
             </div>[m
[36m@@ -539,6 +542,7 @@[m
         const configOutput = document.getElementById('configOutput');[m
         const copyConfigBtn = document.getElementById('copyConfigBtn');[m
         const saveConfigBtn = document.getElementById('saveConfigBtn');[m
[32m+[m[32m        const loadFromConfigBtn = document.getElementById('loadFromConfigBtn');[m
         const sampleData = document.getElementById('sampleData');[m
         const prefillBtn = document.getElementById('prefillBtn');[m
         const processBtn = document.getElementById('processBtn');[m
[36m@@ -559,6 +563,7 @@[m
         addVariableBtn.addEventListener('click', addVariable);[m
         copyConfigBtn.addEventListener('click', copyConfiguration);[m
         saveConfigBtn.addEventListener('click', saveConfiguration);[m
[32m+[m[32m        loadFromConfigBtn.addEventListener('click', loadFromConfiguration);[m
         prefillBtn.addEventListener('click', prefillSampleData);[m
         processBtn.addEventListener('click', processDocument);[m
         downloadBtn.addEventListener('click', downloadProcessedPDF);[m
[36m@@ -887,8 +892,9 @@[m
 [m
             if (isDisplayCoords) {[m
                 // These are already display coordinates, no adjustment needed[m
[31m-                displayPdfX = pdfX + 50;[m
[31m-                displayPdfY = pdfY - 80;[m
[32m+[m[32m                displayPdfX = pdfX + 89;[m
[32m+[m[32m                displayPdfY = pdfY - 89;[m
[32m+[m[32m                console.log("display", displayPdfX, displayPdfY)[m
             } else {[m
                 // These are adjusted coordinates, reverse the adjustment for display[m
                 displayPdfX = pdfX - 2; // Reverse the left adjustment[m
[36m@@ -932,6 +938,78 @@[m
             renderTextOverlays();[m
         }[m
 [m
[32m+[m[32m        function loadFromConfiguration() {[m
[32m+[m[32m            try {[m
[32m+[m[32m                const configText = configOutput.value || configOutput.textContent;[m
[32m+[m[32m                if (!configText || configText === 'Click on the PDF to start adding variables...') {[m
[32m+[m[32m                    showNotification('No configuration to load', 'error');[m
[32m+[m[32m                    return;[m
[32m+[m[32m                }[m
[32m+[m
[32m+[m[32m                const config = JSON.parse(configText);[m
[32m+[m[32m                if (!Array.isArray(config)) {[m
[32m+[m[32m                    showNotification('Invalid configuration format - must be an array', 'error');[m
[32m+[m[32m                    return;[m
[32m+[m[32m                }[m
[32m+[m
[32m+[m[32m                // Convert configuration back to variables[m
[32m+[m[32m                variables = [];[m
[32m+[m[32m                config.forEach(pageConfig => {[m
[32m+[m[32m                    const displayPage = pageConfig.page_number + 1; // Convert 0-based to 1-based for display[m
[32m+[m
[32m+[m[32m                    if (!pageConfig.variables || !Array.isArray(pageConfig.variables)) {[m
[32m+[m[32m                        console.warn(`Page ${pageConfig.page_number} has no variables array`);[m
[32m+[m[32m                        return;[m
[32m+[m[32m                    }[m
[32m+[m
[32m+[m[32m                    pageConfig.variables.forEach(variable => {[m
[32m+[m[32m                        if (variable.conditional_coordinates) {[m
[32m+[m[32m                            // Conditional variable[m
[32m+[m[32m                            const newVar = {[m
[32m+[m[32m                                name: variable.name,[m
[32m+[m[32m                                x: 0, // Not used for conditional[m
[32m+[m[32m                                y: 0, // Not used for conditional[m
[32m+[m[32m                                page: displayPage,[m
[32m+[m[32m                                fontSize: 12,[m
[32m+[m[32m                                type: 'conditional',[m
[32m+[m[32m                                conditionalCoordinates: variable.conditional_coordinates.map(cond => ({[m
[32m+[m[32m                                    if_value: cond.if_value || '',[m
[32m+[m[32m                                    print_pattern: cond.print_pattern || '*',[m
[32m+[m[32m                                    x: cond['x-coordinate'] || 0,[m
[32m+[m[32m                                    y: cond['y-coordinate'] || 0,[m
[32m+[m[32m                                    displayX: cond['x-coordinate'] || 0, // Use same coordinates for display[m
[32m+[m[32m                                    displayY: cond['y-coordinate'] || 0[m
[32m+[m[32m                                }))[m
[32m+[m[32m                            };[m
[32m+[m[32m                            variables.push(newVar);[m
[32m+[m[32m                        } else {[m
[32m+[m[32m                            // Simple variable[m
[32m+[m[32m                            const newVar = {[m
[32m+[m[32m                                name: variable.name,[m
[32m+[m[32m                                x: variable['x-coordinate'] || 0,[m
[32m+[m[32m                                y: variable['y-coordinate'] || 0,[m
[32m+[m[32m                                displayX: variable['x-coordinate'] || 0, // Use same coordinates for display[m
[32m+[m[32m                                displayY: variable['y-coordinate'] || 0,[m
[32m+[m[32m                                page: displayPage,[m
[32m+[m[32m                                fontSize: variable.font_size || 12,[m
[32m+[m[32m                                type: 'simple',[m
[32m+[m[32m                                conditionalCoordinates: [][m
[32m+[m[32m                            };[m
[32m+[m[32m                            variables.push(newVar);[m
[32m+[m[32m                        }[m
[32m+[m[32m                    });[m
[32m+[m[32m                });[m
[32m+[m
[32m+[m[32m                updateVariablesList();[m
[32m+[m[32m                renderTextOverlays();[m
[32m+[m[32m                showNotification(`Configuration loaded successfully! ${variables.length} variables imported.`);[m
[32m+[m
[32m+[m[32m            } catch (error) {[m
[32m+[m[32m                showNotification('Invalid JSON configuration: ' + error.message, 'error');[m
[32m+[m[32m                console.error('Config parsing error:', error);[m
[32m+[m[32m            }[m
[32m+[m[32m        }[m
[32m+[m
         function addVariable() {[m
             // Get center coordinates of current page in PDF coordinate system[m
             const pdfPageDim = pdfPageDimensions[currentPage] || { width: 612, height: 792 };[m

[33mcommit abb77eaf8c0f5d4cc3f7f8f2135eb5bc71b0d515[m
Author: shridhar <shridhar.p@zerodha.com>
Date:   Fri May 30 20:41:51 2025 +0530

    feat: docker compose and docker file

[1mdiff --git a/Dockerfile b/Dockerfile[m
[1mnew file mode 100644[m
[1mindex 0000000..6a80a05[m
[1m--- /dev/null[m
[1m+++ b/Dockerfile[m
[36m@@ -0,0 +1,49 @@[m
[32m+[m[32m# Use Python 3.11 slim image as base[m
[32m+[m[32mFROM python:3.11-slim[m
[32m+[m
[32m+[m[32m# Set environment variables[m
[32m+[m[32mENV PYTHONDONTWRITEBYTECODE=1[m
[32m+[m[32mENV PYTHONUNBUFFERED=1[m
[32m+[m[32mENV FLASK_APP=app.py[m
[32m+[m[32mENV FLASK_ENV=production[m
[32m+[m
[32m+[m[32m# Set work directory[m
[32m+[m[32mWORKDIR /app[m
[32m+[m
[32m+[m[32m# Install system dependencies[m
[32m+[m[32mRUN apt-get update && apt-get install -y \[m
[32m+[m[32m    gcc \[m
[32m+[m[32m    g++ \[m
[32m+[m[32m    libffi-dev \[m
[32m+[m[32m    libssl-dev \[m
[32m+[m[32m    && rm -rf /var/lib/apt/lists/*[m
[32m+[m
[32m+[m[32m# Copy requirements file[m
[32m+[m[32mCOPY requirements.txt .[m
[32m+[m
[32m+[m[32m# Install Python dependencies[m
[32m+[m[32mRUN pip install --no-cache-dir -r requirements.txt[m
[32m+[m
[32m+[m[32m# Copy application code[m
[32m+[m[32mCOPY . .[m
[32m+[m
[32m+[m[32m# Create necessary directories[m
[32m+[m[32mRUN mkdir -p uploads outputs fonts templates static[m
[32m+[m
[32m+[m[32m# Set permissions[m
[32m+[m[32mRUN chmod -R 755 /app[m
[32m+[m
[32m+[m[32m# Create non-root user for security[m
[32m+[m[32mRUN adduser --disabled-password --gecos '' appuser && \[m
[32m+[m[32m    chown -R appuser:appuser /app[m
[32m+[m[32mUSER appuser[m
[32m+[m
[32m+[m[32m# Expose port[m
[32m+[m[32mEXPOSE 5000[m
[32m+[m
[32m+[m[32m# Health check[m
[32m+[m[32mHEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \[m
[32m+[m[32m    CMD curl -f http://localhost:5000/ || exit 1[m
[32m+[m
[32m+[m[32m# Run the application[m
[32m+[m[32mCMD ["python", "app.py"][m
\ No newline at end of file[m
[1mdiff --git a/app.py b/app.py[m
[1mindex 48e79a0..50fa64e 100644[m
[1m--- a/app.py[m
[1m+++ b/app.py[m
[36m@@ -17,8 +17,7 @@[m [mimport traceback[m
 # Import the pdf_text_overlay library[m
 try:[m
     from pdf_text_overlay import pdf_writer, pdf_from_template[m
[31m-except ImportError as e:[m
[31m-    raise e[m
[32m+[m[32mexcept ImportError:[m
     print("Warning: pdf_text_overlay library not installed. Install with: pip install pdf_text_overlay")[m
     pdf_writer = None[m
     pdf_from_template = None[m
[36m@@ -112,30 +111,36 @@[m [mdef process_pdf():[m
             return jsonify({'error': 'Uploaded PDF not found'}), 404[m
         [m
         # Convert coordinates from canvas to PDF coordinate system[m
[31m-        # The frontend sends canvas coordinates, we need to convert them to PDF coordinates[m
[32m+[m[32m        # The frontend sends 0-based page numbers which is correct for pdf_text_overlay[m
         converted_config = [][m
         for page_config in configuration:[m
             converted_page = {[m
[31m-                'page_number': page_config['page_number'],[m
[32m+[m[32m                'page_number': page_config['page_number'],  # Already 0-based from frontend[m
                 'variables': [][m
             }[m
             [m
             for var in page_config['variables']:[m
[31m-                # The coordinates are already converted in the frontend[m
[31m-                # but we ensure they match the pdf_text_overlay format[m
[31m-                converted_var = {[m
[31m-                    'name': var['name'],[m
[31m-                    'x-coordinate': var['x-coordinate'],[m
[31m-                    'y-coordinate': var['y-coordinate'],[m
[31m-                    'font_size': var.get('font_size', 12)[m
[31m-                }[m
[32m+[m[32m                if 'conditional_coordinates' in var:[m
[32m+[m[32m                    # Handle conditional coordinates[m
[32m+[m[32m                    converted_var = {[m
[32m+[m[32m                        'name': var['name'],[m
[32m+[m[32m                        'conditional_coordinates': var['conditional_coordinates'][m
[32m+[m[32m                    }[m
[32m+[m[32m                else:[m
[32m+[m[32m                    # Handle simple coordinates[m
[32m+[m[32m                    converted_var = {[m
[32m+[m[32m                        'name': var['name'],[m
[32m+[m[32m                        'x-coordinate': var['x-coordinate'],[m
[32m+[m[32m                        'y-coordinate': var['y-coordinate'],[m
[32m+[m[32m                        'font_size': var.get('font_size', 12)[m
[32m+[m[32m                    }[m
                 converted_page['variables'].append(converted_var)[m
             [m
             converted_config.append(converted_page)[m
         [m
         # Default font (you can add custom font upload functionality)[m
[31m-        font_path = os.path.join(FONT_FOLDER, 'default.ttf')  # Will use default font if None[m
[31m-        [m
[32m+[m[32m        font_path = None  # Will use default font if None[m
[32m+[m[32m        font_path = os.path.join(FONT_FOLDER, 'default.ttf')[m
         # Process PDF[m
         with open(pdf_path, 'rb') as pdf_file:[m
             if font_path and os.path.exists(font_path):[m
[36m@@ -143,7 +148,7 @@[m [mdef process_pdf():[m
                     output = pdf_writer(pdf_file, converted_config, sample_data, font_file)[m
             else:[m
                 output = pdf_writer(pdf_file, converted_config, sample_data, None)[m
[31m-        print(output)[m
[32m+[m
         # Save output PDF[m
         session_id = get_session_id()[m
         output_filename = f"output_{session_id}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"[m
[1mdiff --git a/docker-compose.yml b/docker-compose.yml[m
[1mnew file mode 100644[m
[1mindex 0000000..c845f89[m
[1m--- /dev/null[m
[1m+++ b/docker-compose.yml[m
[36m@@ -0,0 +1,42 @@[m
[32m+[m[32mversion: '3.8'[m
[32m+[m
[32m+[m[32mservices:[m
[32m+[m[32m  pdf-overlay-app:[m
[32m+[m[32m    build: .[m
[32m+[m[32m    container_name: pdf-text-overlay[m
[32m+[m[32m    ports:[m
[32m+[m[32m      - "5000:5000"[m
[32m+[m[32m    environment:[m
[32m+[m[32m      - FLASK_ENV=production[m
[32m+[m[32m      - SECRET_KEY=your-production-secret-key-change-this[m
[32m+[m[32m      - MAX_FILE_SIZE=16777216  # 16MB in bytes[m
[32m+[m[32m    volumes:[m
[32m+[m[32m      # Persistent storage for uploads and outputs[m
[32m+[m[32m      - pdf_uploads:/app/uploads[m
[32m+[m[32m      - pdf_outputs:/app/outputs[m
[32m+[m[32m      - pdf_fonts:/app/fonts[m
[32m+[m[32m      # Optional: Mount custom fonts directory[m
[32m+[m[32m      # - ./custom_fonts:/app/fonts[m
[32m+[m[32m    restart: unless-stopped[m
[32m+[m[32m    networks:[m
[32m+[m[32m      - pdf-network[m
[32m+[m[32m    healthcheck:[m
[32m+[m[32m      test: ["CMD", "curl", "-f", "http://localhost:5000/"][m
[32m+[m[32m      interval: 30s[m
[32m+[m[32m      timeout: 10s[m
[32m+[m[32m      retries: 3[m
[32m+[m[32m      start_period: 40s[m
[32m+[m
[32m+[m[32mvolumes:[m
[32m+[m[32m  pdf_uploads:[m
[32m+[m[32m    driver: local[m
[32m+[m[32m  pdf_outputs:[m
[32m+[m[32m    driver: local[m
[32m+[m[32m  pdf_fonts:[m
[32m+[m[32m    driver: local[m
[32m+[m[32m  redis_data:[m
[32m+[m[32m    driver: local[m
[32m+[m
[32m+[m[32mnetworks:[m
[32m+[m[32m  pdf-network:[m
[32m+[m[32m    driver: bridge[m
\ No newline at end of file[m
[1mdiff --git a/fonts/Swiss721CondensedBT.ttf b/fonts/Swiss721CondensedBT.ttf[m
[1mdeleted file mode 100644[m
[1mindex 38417db..0000000[m
Binary files a/fonts/Swiss721CondensedBT.ttf and /dev/null differ
[1mdiff --git a/outputs/output_f725f5f1-4ac2-4a42-bb44-f7f74eb9003f_20250530_165403.pdf b/outputs/output_f725f5f1-4ac2-4a42-bb44-f7f74eb9003f_20250530_165403.pdf[m
[1mdeleted file mode 100644[m
[1mindex e69de29..0000000[m
[1mdiff --git a/outputs/output_f725f5f1-4ac2-4a42-bb44-f7f74eb9003f_20250530_165515.pdf b/outputs/output_f725f5f1-4ac2-4a42-bb44-f7f74eb9003f_20250530_165515.pdf[m
[1mdeleted file mode 100644[m
[1mindex e69de29..0000000[m
[1mdiff --git a/outputs/output_f725f5f1-4ac2-4a42-bb44-f7f74eb9003f_20250530_170335.pdf b/outputs/output_f725f5f1-4ac2-4a42-bb44-f7f74eb9003f_20250530_170335.pdf[m
[1mdeleted file mode 100644[m
[1mindex 7079e8d..0000000[m
Binary files a/outputs/output_f725f5f1-4ac2-4a42-bb44-f7f74eb9003f_20250530_170335.pdf and /dev/null differ
[1mdiff --git a/outputs/output_f725f5f1-4ac2-4a42-bb44-f7f74eb9003f_20250530_170418.pdf b/outputs/output_f725f5f1-4ac2-4a42-bb44-f7f74eb9003f_20250530_170418.pdf[m
[1mdeleted file mode 100644[m
[1mindex e2b4405..0000000[m
Binary files a/outputs/output_f725f5f1-4ac2-4a42-bb44-f7f74eb9003f_20250530_170418.pdf and /dev/null differ
[1mdiff --git a/outputs/output_f725f5f1-4ac2-4a42-bb44-f7f74eb9003f_20250530_170917.pdf b/outputs/output_f725f5f1-4ac2-4a42-bb44-f7f74eb9003f_20250530_170917.pdf[m
[1mdeleted file mode 100644[m
[1mindex c3fc536..0000000[m
Binary files a/outputs/output_f725f5f1-4ac2-4a42-bb44-f7f74eb9003f_20250530_170917.pdf and /dev/null differ
[1mdiff --git a/outputs/output_f725f5f1-4ac2-4a42-bb44-f7f74eb9003f_20250530_170950.pdf b/outputs/output_f725f5f1-4ac2-4a42-bb44-f7f74eb9003f_20250530_170950.pdf[m
[1mdeleted file mode 100644[m
[1mindex ac6bd11..0000000[m
Binary files a/outputs/output_f725f5f1-4ac2-4a42-bb44-f7f74eb9003f_20250530_170950.pdf and /dev/null differ
[1mdiff --git a/outputs/output_f725f5f1-4ac2-4a42-bb44-f7f74eb9003f_20250530_171100.pdf b/outputs/output_f725f5f1-4ac2-4a42-bb44-f7f74eb9003f_20250530_171100.pdf[m
[1mdeleted file mode 100644[m
[1mindex 979bc92..0000000[m
Binary files a/outputs/output_f725f5f1-4ac2-4a42-bb44-f7f74eb9003f_20250530_171100.pdf and /dev/null differ
[1mdiff --git a/requirements.txt b/requirements.txt[m
[1mindex c558d0f..91c5252 100644[m
[1m--- a/requirements.txt[m
[1m+++ b/requirements.txt[m
[36m@@ -1,6 +1,7 @@[m
 Flask==2.3.3[m
 Werkzeug==2.3.7[m
 pdf_text_overlay[m
[32m+[m[32mpdfkit[m
 PyPDF2==3.0.1[m
 Jinja2==3.1.2[m
 MarkupSafe==2.1.3[m
[1mdiff --git a/templates/index.html b/templates/index.html[m
[1mindex 5105e30..2355b90 100644[m
[1m--- a/templates/index.html[m
[1m+++ b/templates/index.html[m
[36m@@ -3,7 +3,7 @@[m
 <head>[m
     <meta charset="UTF-8">[m
     <meta name="viewport" content="width=device-width, initial-scale=1.0">[m
[31m-    <title>PDF Text Overlay Tool - Flask App</title>[m
[32m+[m[32m    <title>PDF Text Overlay Tool</title>[m
     <script src="https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.min.js"></script>[m
     <style>[m
         * {[m
[36m@@ -145,6 +145,25 @@[m
             pointer-events: none;[m
             transform: translate(-50%, -100%);[m
             white-space: nowrap;[m
[32m+[m[32m            z-index: 1000;[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .coordinate-dot {[m
[32m+[m[32m            position: absolute;[m
[32m+[m[32m            width: 4px;[m
[32m+[m[32m            height: 4px;[m
[32m+[m[32m            border-radius: 50%;[m
[32m+[m[32m            transform: translate(-50%, -50%);[m
[32m+[m[32m            z-index: 999;[m
[32m+[m[32m            pointer-events: none;[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .coordinate-dot.simple {[m
[32m+[m[32m            background-color: #667eea;[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .coordinate-dot.conditional {[m
[32m+[m[32m            background-color: #ff9800;[m
         }[m
 [m
         /* Configuration Section */[m
[36m@@ -294,13 +313,16 @@[m
         .config-output {[m
             background: #2d3748;[m
             color: #e2e8f0;[m
[31m-            padding: 15px;[m
[32m+[m[32m            padding: 20px;[m
             border-radius: 8px;[m
             font-family: 'Courier New', monospace;[m
[31m-            font-size: 0.85rem;[m
[31m-            max-height: 300px;[m
[32m+[m[32m            font-size: 0.9rem;[m
[32m+[m[32m            min-height: 400px;[m
[32m+[m[32m            max-height: 600px;[m
             overflow-y: auto;[m
             white-space: pre-wrap;[m
[32m+[m[32m            border: 2px solid #4a5568;[m
[32m+[m[32m            line-height: 1.4;[m
         }[m
 [m
         .click-instruction {[m
[36m@@ -375,7 +397,7 @@[m
 </head>[m
 <body>[m
     <div class="header">[m
[31m-        <h1>🚀 PDF Text Overlay Tool </h1>[m
[32m+[m[32m        <h1>🚀 PDF Text Overlay Tool</h1>[m
         <p>Upload, configure, and process PDF text overlays with real-time preview</p>[m
     </div>[m
 [m
[36m@@ -402,7 +424,10 @@[m
 [m
             <div class="pdf-viewer" id="pdfViewer">[m
                 <div class="click-instruction">[m
[31m-                    💡 Click anywhere on the PDF to add text overlay positions[m
[32m+[m[32m                    💡 <strong>Click the CENTER of checkboxes or text fields</strong>[m
[32m+[m[32m                    <br><small>The tool automatically adjusts coordinates for proper text positioning</small>[m
[32m+[m[32m                    <br><small>Blue overlays = Simple variables | Orange overlays = Conditional coordinates</small>[m
[32m+[m[32m                    <br><small>Hold <strong>Ctrl/Cmd</strong> + Click to add conditional coordinate to selected variable</small>[m
                 </div>[m
                 <canvas id="pdfCanvas" class="pdf-canvas"></canvas>[m
             </div>[m
[36m@@ -446,6 +471,11 @@[m
                 <!-- Processing Section -->[m
                 <div class="section">[m
                     <h3>🔧 Process PDF</h3>[m
[32m+[m[32m                    <div style="background: #fff3cd; padding: 10px; border-radius: 5px; margin-bottom: 10px; font-size: 0.85rem;">[m
[32m+[m[32m                        🎯 <strong>Coordinate Tips:</strong> Click the center of checkboxes/fields. The tool automatically adjusts for text baseline positioning.[m
[32m+[m[32m                        <br>• Blue dots = Simple text positions | Orange dots = Conditional positions[m
[32m+[m[32m                        <br>• If text is still off, fine-tune coordinates by ±2-5 points in variable settings[m
[32m+[m[32m                    </div>[m
                     <button class="btn btn-block" id="processBtn" disabled>🚀 Process PDF with Overlays</button>[m
                     <div class="loading" id="processLoading">[m
                         <div>⚙️ Processing PDF...</div>[m
[36m@@ -461,10 +491,13 @@[m
                     <div style="background: #e3f2fd; padding: 10px; border-radius: 5px; margin-bottom: 10px; font-size: 0.85rem;">[m
                         💡 <strong>Note:</strong> Page numbers in config are 0-based (Page 1 → 0, Page 2 → 1, etc.)[m
                     </div>[m
[31m-                    <div class="config-output" id="configOutput">Click on the PDF to start adding variables...</div>[m
[31m-                    <div style="display: flex; gap: 10px; margin-top: 10px;">[m
[31m-                        <button class="btn" id="copyConfigBtn" style="flex: 1;">📋 Copy Config</button>[m
[31m-                        <button class="btn btn-secondary" id="saveConfigBtn" style="flex: 1;">💾 Save Config</button>[m
[32m+[m[32m                    <div class="form-group">[m
[32m+[m[32m                        <label>Configuration JSON:</label>[m
[32m+[m[32m                        <div class="config-output" id="configOutput">Click on the PDF to start adding variables...</div>[m
[32m+[m[32m                    </div>[m
[32m+[m[32m                    <div style="display: flex; gap: 10px; margin-top: 15px; flex-wrap: wrap;">[m
[32m+[m[32m                        <button class="btn" id="copyConfigBtn" style="flex: 1; min-width: 120px;">📋 Copy Config</button>[m
[32m+[m[32m                        <button class="btn btn-secondary" id="saveConfigBtn" style="flex: 1; min-width: 120px;">💾 Save Config</button>[m
                     </div>[m
                 </div>[m
             </div>[m
[36m@@ -485,7 +518,8 @@[m
         let scale = 1.5;[m
         let pdfUploaded = false;[m
         let processedFilename = null;[m
[31m-        let pdfPageDimensions = {}; // Store actual PDF page dimensions[m
[32m+[m[32m        let pdfPageDimensions = {};[m
[32m+[m[32m        let selectedVariableForConditional = -1;[m
 [m
         // Initialize PDF.js[m
         pdfjsLib.GlobalWorkerOptions.workerSrc = 'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.worker.min.js';[m
[36m@@ -665,6 +699,10 @@[m
                 pdfCanvas.width = viewport.width;[m
                 pdfCanvas.height = viewport.height;[m
                 [m
[32m+[m[32m                // Store the actual viewport dimensions for accurate coordinate conversion[m
[32m+[m[32m                const actualPageDim = pdfPageDimensions[pageNum] || { width: 612, height: 792 };[m
[32m+[m[32m                console.log(`Page ${pageNum}: Canvas ${viewport.width}x${viewport.height}, PDF ${actualPageDim.width}x${actualPageDim.height}`);[m
[32m+[m
                 const renderContext = {[m
                     canvasContext: pdfCtx,[m
                     viewport: viewport[m
[36m@@ -678,20 +716,65 @@[m
         }[m
 [m
         function renderTextOverlays() {[m
[31m-            const existingOverlays = pdfViewer.querySelectorAll('.text-overlay');[m
[31m-            existingOverlays.forEach(overlay => overlay.remove());[m
[32m+[m[32m            // Remove existing overlays and dots[m
[32m+[m[32m            const existingOverlays = pdfViewer.querySelectorAll('.text-overlay, .coordinate-dot');[m
[32m+[m[32m            existingOverlays.forEach(element => element.remove());[m
 [m
             const currentPageVars = variables.filter(v => v.page === currentPage);[m
             currentPageVars.forEach(variable => {[m
[31m-                // Convert PDF coordinates back to canvas coordinates for display[m
[31m-                const canvasCoords = pdfToCanvasCoordinates(variable.x, variable.y, currentPage);[m
[31m-                [m
[31m-                const overlay = document.createElement('div');[m
[31m-                overlay.className = 'text-overlay';[m
[31m-                overlay.textContent = `${variable.name} (${variable.x}, ${variable.y})`;[m
[31m-                overlay.style.left = canvasCoords.x + 'px';[m
[31m-                overlay.style.top = canvasCoords.y + 'px';[m
[31m-                pdfViewer.appendChild(overlay);[m
[32m+[m[32m                if (variable.type === 'simple') {[m
[32m+[m[32m                    // Use display coordinates for visual overlay (exact click position)[m
[32m+[m[32m                    let canvasCoords;[m
[32m+[m[32m                    if (variable.displayX && variable.displayY) {[m
[32m+[m[32m                        // Use stored display coordinates[m
[32m+[m[32m                        canvasCoords = pdfToCanvasCoordinates(variable.displayX, variable.displayY, currentPage, true);[m
[32m+[m[32m                    } else {[m
[32m+[m[32m                        // Fallback for old variables - reverse the adjustment[m
[32m+[m[32m                        canvasCoords = pdfToCanvasCoordinates(variable.x, variable.y, currentPage, false);[m
[32m+[m[32m                    }[m
[32m+[m
[32m+[m[32m                    // Create text overlay at exact click position[m
[32m+[m[32m                    const overlay = document.createElement('div');[m
[32m+[m[32m                    overlay.className = 'text-overlay';[m
[32m+[m[32m                    overlay.textContent = `${variable.name} (${variable.x}, ${variable.y})`;[m
[32m+[m[32m                    overlay.style.left = canvasCoords.x + 'px';[m
[32m+[m[32m                    overlay.style.top = canvasCoords.y + 'px';[m
[32m+[m[32m                    pdfViewer.appendChild(overlay);[m
[32m+[m
[32m+[m[32m                    // Create precision dot at exact click position[m
[32m+[m[32m                    const dot = document.createElement('div');[m
[32m+[m[32m                    dot.className = 'coordinate-dot simple';[m
[32m+[m[32m                    dot.style.left = canvasCoords.x + 'px';[m
[32m+[m[32m                    dot.style.top = canvasCoords.y + 'px';[m
[32m+[m[32m                    pdfViewer.appendChild(dot);[m
[32m+[m
[32m+[m[32m                } else if (variable.type === 'conditional') {[m
[32m+[m[32m                    // Render conditional coordinate overlays[m
[32m+[m[32m                    variable.conditionalCoordinates.forEach((cond, index) => {[m
[32m+[m[32m                        let canvasCoords;[m
[32m+[m[32m                        if (cond.displayX && cond.displayY) {[m
[32m+[m[32m                            canvasCoords = pdfToCanvasCoordinates(cond.displayX, cond.displayY, currentPage, true);[m
[32m+[m[32m                        } else {[m
[32m+[m[32m                            canvasCoords = pdfToCanvasCoordinates(cond.x, cond.y, currentPage, false);[m
[32m+[m[32m                        }[m
[32m+[m
[32m+[m[32m                        // Create text overlay[m
[32m+[m[32m                        const overlay = document.createElement('div');[m
[32m+[m[32m                        overlay.className = 'text-overlay';[m
[32m+[m[32m                        overlay.style.background = 'rgba(255, 152, 0, 0.8)'; // Orange for conditional[m
[32m+[m[32m                        overlay.textContent = `${variable.name}[${cond.if_value || '?'}] (${cond.x}, ${cond.y})`;[m
[32m+[m[32m                        overlay.style.left = canvasCoords.x + 'px';[m
[32m+[m[32m                        overlay.style.top = canvasCoords.y + 'px';[m
[32m+[m[32m                        pdfViewer.appendChild(overlay);[m
[32m+[m
[32m+[m[32m                        // Create precision dot[m
[32m+[m[32m                        const dot = document.createElement('div');[m
[32m+[m[32m                        dot.className = 'coordinate-dot conditional';[m
[32m+[m[32m                        dot.style.left = canvasCoords.x + 'px';[m
[32m+[m[32m                        dot.style.top = canvasCoords.y + 'px';[m
[32m+[m[32m                        pdfViewer.appendChild(dot);[m
[32m+[m[32m                    });[m
[32m+[m[32m                }[m
             });[m
         }[m
 [m
[36m@@ -716,20 +799,59 @@[m
             const canvasX = Math.round(e.clientX - rect.left);[m
             const canvasY = Math.round(e.clientY - rect.top);[m
             [m
[31m-            // Convert canvas coordinates to PDF coordinates[m
[31m-            const pdfCoords = canvasToPDFCoordinates(canvasX, canvasY, currentPage);[m
[31m-            [m
[31m-            addVariableAtPosition(pdfCoords.x, pdfCoords.y, currentPage);[m
[32m+[m[32m            // Check if Ctrl/Cmd is held down for adding conditional coordinates[m
[32m+[m[32m            if (e.ctrlKey || e.metaKey) {[m
[32m+[m[32m                // Get adjusted coordinates for conditional coordinates[m
[32m+[m[32m                const pdfCoords = canvasToPDFCoordinates(canvasX, canvasY, currentPage, false);[m
[32m+[m[32m                addConditionalCoordinateByClick(pdfCoords.x, pdfCoords.y);[m
[32m+[m[32m            } else {[m
[32m+[m[32m                // For regular variables, addVariableAtPosition will handle both display and process coords[m
[32m+[m[32m                addVariableAtPosition(0, 0, currentPage); // Parameters not used anymore[m
[32m+[m[32m            }[m
         }[m
 [m
[31m-        function canvasToPDFCoordinates(canvasX, canvasY, pageNum) {[m
[31m-            // Get the current page dimensions[m
[31m-            const page = pdfDoc.getPage(pageNum);[m
[31m-            [m
[32m+[m[32m        function addConditionalCoordinateByClick(x, y) {[m
[32m+[m[32m            // Find conditional variables on the current page[m
[32m+[m[32m            const conditionalVars = variables.filter(v => v.type === 'conditional' && v.page === currentPage);[m
[32m+[m
[32m+[m[32m            if (conditionalVars.length === 0) {[m
[32m+[m[32m                showNotification('No conditional variables on this page. Create a conditional variable first.', 'error');[m
[32m+[m[32m                return;[m
[32m+[m[32m            }[m
[32m+[m
[32m+[m[32m            if (conditionalVars.length === 1) {[m
[32m+[m[32m                // Automatically add to the only conditional variable[m
[32m+[m[32m                const varIndex = variables.indexOf(conditionalVars[0]);[m
[32m+[m[32m                addConditionalCoordinate(varIndex);[m
[32m+[m[32m                // Update the last added coordinate with clicked position[m
[32m+[m[32m                const lastCondIndex = variables[varIndex].conditionalCoordinates.length - 1;[m
[32m+[m[32m                updateConditionalCoordinate(varIndex, lastCondIndex, 'x', x);[m
[32m+[m[32m                updateConditionalCoordinate(varIndex, lastCondIndex, 'y', y);[m
[32m+[m[32m                updateVariablesList();[m
[32m+[m[32m                showNotification(`Added conditional coordinate to "${conditionalVars[0].name}"`);[m
[32m+[m[32m            } else {[m
[32m+[m[32m                // Multiple conditional variables - let user choose[m
[32m+[m[32m                const varNames = conditionalVars.map((v, i) => `${i + 1}. ${v.name}`).join('\n');[m
[32m+[m[32m                const choice = prompt(`Multiple conditional variables found. Enter the number for:\n${varNames}`);[m
[32m+[m[32m                const choiceIndex = parseInt(choice) - 1;[m
[32m+[m
[32m+[m[32m                if (choiceIndex >= 0 && choiceIndex < conditionalVars.length) {[m
[32m+[m[32m                    const varIndex = variables.indexOf(conditionalVars[choiceIndex]);[m
[32m+[m[32m                    addConditionalCoordinate(varIndex);[m
[32m+[m[32m                    const lastCondIndex = variables[varIndex].conditionalCoordinates.length - 1;[m
[32m+[m[32m                    updateConditionalCoordinate(varIndex, lastCondIndex, 'x', x);[m
[32m+[m[32m                    updateConditionalCoordinate(varIndex, lastCondIndex, 'y', y);[m
[32m+[m[32m                    updateVariablesList();[m
[32m+[m[32m                    showNotification(`Added conditional coordinate to "${conditionalVars[choiceIndex].name}"`);[m
[32m+[m[32m                }[m
[32m+[m[32m            }[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        function canvasToPDFCoordinates(canvasX, canvasY, pageNum, forDisplay = false) {[m
             // Get actual PDF page dimensions[m
             const pdfPageDim = pdfPageDimensions[pageNum] || { width: 612, height: 792 };[m
             [m
[31m-            // Calculate the scale factors[m
[32m+[m[32m            // Calculate the scale factors between canvas and PDF[m
             const scaleX = pdfPageDim.width / pdfCanvas.width;[m
             const scaleY = pdfPageDim.height / pdfCanvas.height;[m
             [m
[36m@@ -738,32 +860,72 @@[m
             // PDF coordinate system has origin at bottom-left, canvas at top-left[m
             const pdfY = Math.round(pdfPageDim.height - (canvasY * scaleY));[m
             [m
[31m-            return { x: pdfX, y: pdfY };[m
[32m+[m[32m            if (forDisplay) {[m
[32m+[m[32m                // Return exact coordinates for visual display (no adjustment)[m
[32m+[m[32m                return { x: pdfX, y: pdfY };[m
[32m+[m[32m            } else {[m
[32m+[m[32m                // Apply adjustment for actual PDF text positioning[m
[32m+[m[32m                const adjustedPdfX = pdfX - 3; // Slight left adjustment for horizontal center[m
[32m+[m[32m                const adjustedPdfY = pdfY - 6; // SUBTRACT to move DOWN (lower Y value in PDF = lower position)[m
[32m+[m
[32m+[m[32m                console.log(`Canvas: (${canvasX}, ${canvasY}) -> PDF Display: (${pdfX}, ${pdfY}) -> PDF Final: (${adjustedPdfX}, ${adjustedPdfY})`);[m
[32m+[m[32m                console.log(`Canvas size: ${pdfCanvas.width}x${pdfCanvas.height}, PDF size: ${pdfPageDim.width}x${pdfPageDim.height}`);[m
[32m+[m[32m                console.log(`Scale factors: X=${scaleX.toFixed(3)}, Y=${scaleY.toFixed(3)}`);[m
[32m+[m
[32m+[m[32m                return { x: adjustedPdfX, y: adjustedPdfY };[m
[32m+[m[32m            }[m
         }[m
 [m
[31m-        function pdfToCanvasCoordinates(pdfX, pdfY, pageNum) {[m
[32m+[m[32m        function pdfToCanvasCoordinates(pdfX, pdfY, pageNum, isDisplayCoords = false) {[m
             // Convert PDF coordinates back to canvas coordinates for overlay display[m
             const pdfPageDim = pdfPageDimensions[pageNum] || { width: 612, height: 792 };[m
             [m
             const scaleX = pdfCanvas.width / pdfPageDim.width;[m
             const scaleY = pdfCanvas.height / pdfPageDim.height;[m
[31m-            [m
[31m-            const canvasX = Math.round(pdfX * scaleX);[m
[31m-            const canvasY = Math.round((pdfPageDim.height - pdfY) * scaleY);[m
[31m-            [m
[32m+[m
[32m+[m[32m            let displayPdfX, displayPdfY;[m
[32m+[m
[32m+[m[32m            if (isDisplayCoords) {[m
[32m+[m[32m                // These are already display coordinates, no adjustment needed[m
[32m+[m[32m                displayPdfX = pdfX + 50;[m
[32m+[m[32m                displayPdfY = pdfY - 80;[m
[32m+[m[32m            } else {[m
[32m+[m[32m                // These are adjusted coordinates, reverse the adjustment for display[m
[32m+[m[32m                displayPdfX = pdfX - 2; // Reverse the left adjustment[m
[32m+[m[32m                displayPdfY = pdfY - 2; // Reverse the down adjustment[m
[32m+[m
[32m+[m[32m                console.log(displayPdfX, displayPdfY)[m
[32m+[m[32m            }[m
[32m+[m
[32m+[m[32m            const canvasX = Math.round(displayPdfX * scaleX);[m
[32m+[m[32m            const canvasY = Math.round((pdfPageDim.height - displayPdfY) * scaleY);[m
[32m+[m
             return { x: canvasX, y: canvasY };[m
         }[m
 [m
         function addVariableAtPosition(x, y, page) {[m
[32m+[m[32m            const canvasRect = pdfCanvas.getBoundingClientRect();[m
[32m+[m[32m            const canvasX = Math.round(event.clientX - canvasRect.left);[m
[32m+[m[32m            const canvasY = Math.round(event.clientY - canvasRect.top);[m
[32m+[m
[32m+[m[32m            // Get display coordinates (exact click position) for visual overlay[m
[32m+[m[32m            const displayCoords = canvasToPDFCoordinates(canvasX, canvasY, page, true);[m
[32m+[m[32m            // Get adjusted coordinates for actual PDF processing[m
[32m+[m[32m            const processCoords = canvasToPDFCoordinates(canvasX, canvasY, page, false);[m
[32m+[m
             const variableName = `var_${variables.length + 1}`;[m
             const variable = {[m
                 name: variableName,[m
[31m-                x: x,[m
[31m-                y: y,[m
[32m+[m[32m                x: processCoords.x, // Adjusted coordinates for PDF processing[m
[32m+[m[32m                y: processCoords.y,[m
[32m+[m[32m                displayX: displayCoords.x, // Exact coordinates for visual display[m
[32m+[m[32m                displayY: displayCoords.y,[m
                 page: page,[m
[31m-                fontSize: 12[m
[32m+[m[32m                fontSize: 12,[m
[32m+[m[32m                type: 'simple',[m
[32m+[m[32m                conditionalCoordinates: [][m
             };[m
[31m-            [m
[32m+[m
             variables.push(variable);[m
             updateVariablesList();[m
             updateConfiguration();[m
[36m@@ -775,15 +937,17 @@[m
             const pdfPageDim = pdfPageDimensions[currentPage] || { width: 612, height: 792 };[m
             const centerX = Math.round(pdfPageDim.width / 2);[m
             const centerY = Math.round(pdfPageDim.height / 2);[m
[31m-            [m
[32m+[m
             const variable = {[m
                 name: `var_${variables.length + 1}`,[m
                 x: centerX,[m
                 y: centerY,[m
                 page: currentPage,[m
[31m-                fontSize: 12[m
[32m+[m[32m                fontSize: 12,[m
[32m+[m[32m                type: 'simple',[m
[32m+[m[32m                conditionalCoordinates: [][m
             };[m
[31m-            [m
[32m+[m
             variables.push(variable);[m
             updateVariablesList();[m
             updateConfiguration();[m
[36m@@ -799,8 +963,23 @@[m
 [m
         function updateVariable(index, field, value) {[m
             if (variables[index]) {[m
[31m-                variables[index][field] = field === 'fontSize' || field === 'x' || field === 'y' || field === 'page' ? [m
[31m-                    parseInt(value) || 0 : value;[m
[32m+[m[32m                if (field === 'fontSize' || field === 'x' || field === 'y' || field === 'page') {[m
[32m+[m[32m                    variables[index][field] = parseInt(value) || 0;[m
[32m+[m[32m                } else {[m
[32m+[m[32m                    variables[index][field] = value;[m
[32m+[m[32m                }[m
[32m+[m
[32m+[m[32m                // If switching to conditional type, initialize conditional coordinates[m
[32m+[m[32m                if (field === 'type' && value === 'conditional' && !variables[index].conditionalCoordinates.length) {[m
[32m+[m[32m                    variables[index].conditionalCoordinates = [{[m
[32m+[m[32m                        if_value: '',[m
[32m+[m[32m                        print_pattern: '*',[m
[32m+[m[32m                        x: variables[index].x,[m
[32m+[m[32m                        y: variables[index].y[m
[32m+[m[32m                    }];[m
[32m+[m[32m                }[m
[32m+[m
[32m+[m[32m                updateVariablesList();[m
                 updateConfiguration();[m
                 if (field === 'x' || field === 'y' || field === 'page') {[m
                     renderTextOverlays();[m
[36m@@ -808,12 +987,108 @@[m
             }[m
         }[m
 [m
[32m+[m[32m        function addConditionalCoordinate(variableIndex) {[m
[32m+[m[32m            if (variables[variableIndex]) {[m
[32m+[m[32m                const pdfPageDim = pdfPageDimensions[variables[variableIndex].page] || { width: 612, height: 792 };[m
[32m+[m[32m                variables[variableIndex].conditionalCoordinates.push({[m
[32m+[m[32m                    if_value: '',[m
[32m+[m[32m                    print_pattern: '*',[m
[32m+[m[32m                    x: Math.round(pdfPageDim.width / 2),[m
[32m+[m[32m                    y: Math.round(pdfPageDim.height / 2)[m
[32m+[m[32m                });[m
[32m+[m[32m                updateVariablesList();[m
[32m+[m[32m                updateConfiguration();[m
[32m+[m[32m                renderTextOverlays();[m
[32m+[m[32m            }[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        function removeConditionalCoordinate(variableIndex, condIndex) {[m
[32m+[m[32m            if (variables[variableIndex] && variables[variableIndex].conditionalCoordinates[condIndex]) {[m
[32m+[m[32m                variables[variableIndex].conditionalCoordinates.splice(condIndex, 1);[m
[32m+[m[32m                updateVariablesList();[m
[32m+[m[32m                updateConfiguration();[m
[32m+[m[32m                renderTextOverlays();[m
[32m+[m[32m            }[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        function updateConditionalCoordinate(variableIndex, condIndex, field, value) {[m
[32m+[m[32m            if (variables[variableIndex] && variables[variableIndex].conditionalCoordinates[condIndex]) {[m
[32m+[m[32m                if (field === 'x' || field === 'y') {[m
[32m+[m[32m                    variables[variableIndex].conditionalCoordinates[condIndex][field] = parseInt(value) || 0;[m
[32m+[m[32m                } else {[m
[32m+[m[32m                    variables[variableIndex].conditionalCoordinates[condIndex][field] = value;[m
[32m+[m[32m                }[m
[32m+[m[32m                updateConfiguration();[m
[32m+[m[32m                if (field === 'x' || field === 'y') {[m
[32m+[m[32m                    renderTextOverlays();[m
[32m+[m[32m                }[m
[32m+[m[32m            }[m
[32m+[m[32m        }[m
[32m+[m
         function updateVariablesList() {[m
             variablesList.innerHTML = '';[m
[31m-            [m
[32m+[m
             variables.forEach((variable, index) => {[m
                 const div = document.createElement('div');[m
                 div.className = 'variable-item';[m
[32m+[m
[32m+[m[32m                let conditionalSection = '';[m
[32m+[m[32m                if (variable.type === 'conditional') {[m
[32m+[m[32m                    let conditionalInputs = '';[m
[32m+[m[32m                    variable.conditionalCoordinates.forEach((cond, condIndex) => {[m
[32m+[m[32m                        conditionalInputs += `[m
[32m+[m[32m                            <div style="background: #fff3cd; padding: 10px; border-radius: 5px; margin-bottom: 10px; border: 1px solid #ffeaa7;">[m
[32m+[m[32m                                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;">[m
[32m+[m[32m                                    <strong>Condition ${condIndex + 1}</strong>[m
[32m+[m[32m                                    <button type="button" onclick="removeConditionalCoordinate(${index}, ${condIndex})"[m[41m [m
[32m+[m[32m                                            style="background: #dc3545; color: white; border: none; padding: 3px 8px; border-radius: 3px; font-size: 0.75rem;">Remove</button>[m
[32m+[m[32m                                </div>[m
[32m+[m[32m                                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 8px; margin-bottom: 8px;">[m
[32m+[m[32m                                    <div>[m
[32m+[m[32m                                        <label style="font-size: 0.8rem; font-weight: 600;">If Value:</label>[m
[32m+[m[32m                                        <input type="text" class="form-control" style="padding: 6px;" value="${cond.if_value || ''}"[m[41m [m
[32m+[m[32m                                               placeholder="e.g., Male, Yes, Option1"[m
[32m+[m[32m                                               onchange="updateConditionalCoordinate(${index}, ${condIndex}, 'if_value', this.value)"[m
[32m+[m[32m                                               oninput="updateConditionalCoordinate(${index}, ${condIndex}, 'if_value', this.value)">[m
[32m+[m[32m                                    </div>[m
[32m+[m[32m                                    <div>[m
[32m+[m[32m                                        <label style="font-size: 0.8rem; font-weight: 600;">Print Pattern:</label>[m
[32m+[m[32m                                        <input type="text" class="form-control" style="padding: 6px;" value="${cond.print_pattern || '*'}"[m[41m [m
[32m+[m[32m                                               placeholder="e.g., *, ✓, X"[m
[32m+[m[32m                                               onchange="updateConditionalCoordinate(${index}, ${condIndex}, 'print_pattern', this.value)"[m
[32m+[m[32m                                               oninput="updateConditionalCoordinate(${index}, ${condIndex}, 'print_pattern', this.value)">[m
[32m+[m[32m                                    </div>[m
[32m+[m[32m                                </div>[m
[32m+[m[32m                                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 8px;">[m
[32m+[m[32m                                    <div>[m
[32m+[m[32m                                        <label style="font-size: 0.8rem; font-weight: 600;">X Coordinate:</label>[m
[32m+[m[32m                                        <input type="number" class="form-control" style="padding: 6px;" value="${cond.x || 0}"[m
[32m+[m[32m                                               onchange="updateConditionalCoordinate(${index}, ${condIndex}, 'x', this.value)"[m
[32m+[m[32m                                               oninput="updateConditionalCoordinate(${index}, ${condIndex}, 'x', this.value)">[m
[32m+[m[32m                                    </div>[m
[32m+[m[32m                                    <div>[m
[32m+[m[32m                                        <label style="font-size: 0.8rem; font-weight: 600;">Y Coordinate:</label>[m
[32m+[m[32m                                        <input type="number" class="form-control" style="padding: 6px;" value="${cond.y || 0}"[m
[32m+[m[32m                                               onchange="updateConditionalCoordinate(${index}, ${condIndex}, 'y', this.value)"[m
[32m+[m[32m                                               oninput="updateConditionalCoordinate(${index}, ${condIndex}, 'y', this.value)">[m
[32m+[m[32m                                    </div>[m
[32m+[m[32m                                </div>[m
[32m+[m[32m                            </div>[m
[32m+[m[32m                        `;[m
[32m+[m[32m                    });[m
[32m+[m
[32m+[m[32m                    conditionalSection = `[m
[32m+[m[32m                        <div style="margin-top: 15px;">[m
[32m+[m[32m                            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px;">[m
[32m+[m[32m                                <label style="font-weight: 600; color: #ff8c00;">Conditional Coordinates:</label>[m
[32m+[m[32m                                <button type="button" onclick="addConditionalCoordinate(${index})"[m
[32m+[m[32m                                        style="background: #28a745; color: white; border: none; padding: 5px 10px; border-radius: 5px; font-size: 0.8rem;">+ Add Condition</button>[m
[32m+[m[32m                            </div>[m
[32m+[m[32m                            ${conditionalInputs}[m
[32m+[m[32m                        </div>[m
[32m+[m[32m                    `;[m
[32m+[m[32m                }[m
[32m+[m
                 div.innerHTML = `[m
                     <div class="variable-header">[m
                         <strong>Variable ${index + 1}</strong>[m
[36m@@ -824,33 +1099,45 @@[m
                         <input type="text" class="form-control" value="${variable.name}" [m
                                onchange="updateVariable(${index}, 'name', this.value)">[m
                     </div>[m
[31m-                    <div class="coordinate-display">[m
[31m-                        Display Page: ${variable.page} → Config Page: ${variable.page - 1} (0-based)[m
[31m-                        <br>PDF Coords: X: ${variable.x} | Y: ${variable.y}[m
[31m-                        <br><small style="color: #6c757d;">pdf_text_overlay uses 0-based page numbering</small>[m
[31m-                    </div>[m
                     <div class="form-group">[m
[31m-                        <label>Page Number:</label>[m
[31m-                        <input type="number" class="form-control" value="${variable.page}" min="1" max="${totalPages || 999}"[m
[31m-                               onchange="updateVariable(${index}, 'page', this.value)">[m
[32m+[m[32m                        <label>Variable Type:</label>[m
[32m+[m[32m                        <select class="form-control" onchange="updateVariable(${index}, 'type', this.value)">[m
[32m+[m[32m                            <option value="simple" ${variable.type === 'simple' ? 'selected' : ''}>Simple (Single Position)</option>[m
[32m+[m[32m                            <option value="conditional" ${variable.type === 'conditional' ? 'selected' : ''}>Conditional (Multiple Positions)</option>[m
[32m+[m[32m                        </select>[m
                     </div>[m
[31m-                    <div style="display: flex; gap: 10px;">[m
[31m-                        <div class="form-group" style="flex: 1;">[m
[31m-                            <label>X Coordinate:</label>[m
[31m-                            <input type="number" class="form-control" value="${variable.x}"[m
[31m-                                   onchange="updateVariable(${index}, 'x', this.value)">[m
[32m+[m
[32m+[m[32m                    ${variable.type === 'simple' ? `[m
[32m+[m[32m                        <div class="coordinate-display">[m
[32m+[m[32m                            Display Page: ${variable.page} → Config Page: ${variable.page - 1} (0-based)[m
[32m+[m[32m                            <br>PDF Coords: X: ${variable.x} | Y: ${variable.y}[m
[32m+[m[32m                            <br><small style="color: #6c757d;">pdf_text_overlay uses 0-based page numbering</small>[m
                         </div>[m
[31m-                        <div class="form-group" style="flex: 1;">[m
[31m-                            <label>Y Coordinate:</label>[m
[31m-                            <input type="number" class="form-control" value="${variable.y}"[m
[31m-                                   onchange="updateVariable(${index}, 'y', this.value)">[m
[32m+[m[32m                        <div class="form-group">[m
[32m+[m[32m                            <label>Page Number:</label>[m
[32m+[m[32m                            <input type="number" class="form-control" value="${variable.page}" min="1" max="${totalPages || 999}"[m
[32m+[m[32m                                   onchange="updateVariable(${index}, 'page', this.value)">[m
                         </div>[m
[31m-                    </div>[m
[31m-                    <div class="form-group">[m
[31m-                        <label>Font Size:</label>[m
[31m-                        <input type="number" class="form-control" value="${variable.fontSize}" min="6" max="72"[m
[31m-                               onchange="updateVariable(${index}, 'fontSize', this.value)">[m
[31m-                    </div>[m
[32m+[m[32m                        <div style="display: flex; gap: 10px;">[m
[32m+[m[32m                            <div class="form-group" style="flex: 1;">[m
[32m+[m[32m                                <label>X Coordinate:</label>[m
[32m+[m[32m                                <input type="number" class="form-control" value="${variable.x}"[m
[32m+[m[32m                                       onchange="updateVariable(${index}, 'x', this.value)">[m
[32m+[m[32m                            </div>[m
[32m+[m[32m                            <div class="form-group" style="flex: 1;">[m
[32m+[m[32m                                <label>Y Coordinate:</label>[m
[32m+[m[32m                                <input type="number" class="form-control" value="${variable.y}"[m
[32m+[m[32m                                       onchange="updateVariable(${index}, 'y', this.value)">[m
[32m+[m[32m                            </div>[m
[32m+[m[32m                        </div>[m
[32m+[m[32m                        <div class="form-group">[m
[32m+[m[32m                            <label>Font Size:</label>[m
[32m+[m[32m                            <input type="number" class="form-control" value="${variable.fontSize}" min="6" max="72"[m
[32m+[m[32m                                   onchange="updateVariable(${index}, 'fontSize', this.value)">[m
[32m+[m[32m                        </div>[m
[32m+[m[32m                    ` : ''}[m
[32m+[m
[32m+[m[32m                    ${conditionalSection}[m
                 `;[m
                 variablesList.appendChild(div);[m
             });[m
[36m@@ -869,12 +1156,26 @@[m
                 if (!pageGroups[zeroBasedPage]) {[m
                     pageGroups[zeroBasedPage] = [];[m
                 }[m
[31m-                pageGroups[zeroBasedPage].push({[m
[31m-                    name: variable.name,[m
[31m-                    "x-coordinate": variable.x,[m
[31m-                    "y-coordinate": variable.y,[m
[31m-                    font_size: variable.fontSize[m
[31m-                });[m
[32m+[m
[32m+[m[32m                if (variable.type === 'simple') {[m
[32m+[m[32m                    pageGroups[zeroBasedPage].push({[m
[32m+[m[32m                        name: variable.name,[m
[32m+[m[32m                        "x-coordinate": variable.x,[m
[32m+[m[32m                        "y-coordinate": variable.y,[m
[32m+[m[32m                        font_size: variable.fontSize[m
[32m+[m[32m                    });[m
[32m+[m[32m                } else if (variable.type === 'conditional') {[m
[32m+[m[32m                    const conditionalVar = {[m
[32m+[m[32m                        name: variable.name,[m
[32m+[m[32m                        conditional_coordinates: variable.conditionalCoordinates.map(cond => ({[m
[32m+[m[32m                            if_value: cond.if_value,[m
[32m+[m[32m                            print_pattern: cond.print_pattern,[m
[32m+[m[32m                            "x-coordinate": cond.x,[m
[32m+[m[32m                            "y-coordinate": cond.y[m
[32m+[m[32m                        }))[m
[32m+[m[32m                    };[m
[32m+[m[32m                    pageGroups[zeroBasedPage].push(conditionalVar);[m
[32m+[m[32m                }[m
             });[m
 [m
             const configuration = Object.keys(pageGroups).map(page => ({[m
[36m@@ -909,12 +1210,26 @@[m
                 if (!pageGroups[zeroBasedPage]) {[m
                     pageGroups[zeroBasedPage] = [];[m
                 }[m
[31m-                pageGroups[zeroBasedPage].push({[m
[31m-                    name: variable.name,[m
[31m-                    "x-coordinate": variable.x,[m
[31m-                    "y-coordinate": variable.y,[m
[31m-                    font_size: variable.fontSize[m
[31m-                });[m
[32m+[m
[32m+[m[32m                if (variable.type === 'simple') {[m
[32m+[m[32m                    pageGroups[zeroBasedPage].push({[m
[32m+[m[32m                        name: variable.name,[m
[32m+[m[32m                        "x-coordinate": variable.x,[m
[32m+[m[32m                        "y-coordinate": variable.y,[m
[32m+[m[32m                        font_size: variable.fontSize[m
[32m+[m[32m                    });[m
[32m+[m[32m                } else if (variable.type === 'conditional') {[m
[32m+[m[32m                    const conditionalVar = {[m
[32m+[m[32m                        name: variable.name,[m
[32m+[m[32m                        conditional_coordinates: variable.conditionalCoordinates.map(cond => ({[m
[32m+[m[32m                            if_value: cond.if_value,[m
[32m+[m[32m                            print_pattern: cond.print_pattern,[m
[32m+[m[32m                            "x-coordinate": cond.x,[m
[32m+[m[32m                            "y-coordinate": cond.y[m
[32m+[m[32m                        }))[m
[32m+[m[32m                    };[m
[32m+[m[32m                    pageGroups[zeroBasedPage].push(conditionalVar);[m
[32m+[m[32m                }[m
             });[m
 [m
             const configuration = Object.keys(pageGroups).map(page => ({[m
[36m@@ -954,7 +1269,9 @@[m
 [m
             const sampleObj = {};[m
             variableNames.forEach(name => {[m
[31m-                if (name.toLowerCase().includes('name')) {[m
[32m+[m[32m                if (name.toLowerCase().includes('gender')) {[m
[32m+[m[32m                    sampleObj[name] = 'Male'; // Will trigger conditional coordinates[m
[32m+[m[32m                } else if (name.toLowerCase().includes('name')) {[m
                     sampleObj[name] = 'John Doe';[m
                 } else if (name.toLowerCase().includes('email')) {[m
                     sampleObj[name] = 'john.doe@example.com';[m
[36m@@ -966,6 +1283,8 @@[m
                     sampleObj[name] = '123 Main St, City, State 12345';[m
                 } else if (name.toLowerCase().includes('company')) {[m
                     sampleObj[name] = 'Example Company Inc.';[m
[32m+[m[32m                } else if (name.toLowerCase().includes('status') || name.toLowerCase().includes('type')) {[m
[32m+[m[32m                    sampleObj[name] = 'Active'; // Will trigger conditional coordinates[m
                 } else {[m
                     sampleObj[name] = `Sample ${name}`;[m
                 }[m
[36m@@ -1004,12 +1323,26 @@[m
                 if (!pageGroups[zeroBasedPage]) {[m
                     pageGroups[zeroBasedPage] = [];[m
                 }[m
[31m-                pageGroups[zeroBasedPage].push({[m
[31m-                    name: variable.name,[m
[31m-                    "x-coordinate": variable.x,[m
[31m-                    "y-coordinate": variable.y,[m
[31m-                    font_size: variable.fontSize[m
[31m-                });[m
[32m+[m
[32m+[m[32m                if (variable.type === 'simple') {[m
[32m+[m[32m                    pageGroups[zeroBasedPage].push({[m
[32m+[m[32m                        name: variable.name,[m
[32m+[m[32m                        "x-coordinate": variable.x,[m
[32m+[m[32m                        "y-coordinate": variable.y,[m
[32m+[m[32m                        font_size: variable.fontSize[m
[32m+[m[32m                    });[m
[32m+[m[32m                } else if (variable.type === 'conditional') {[m
[32m+[m[32m                    const conditionalVar = {[m
[32m+[m[32m                        name: variable.name,[m
[32m+[m[32m                        conditional_coordinates: variable.conditionalCoordinates.map(cond => ({[m
[32m+[m[32m                            if_value: cond.if_value,[m
[32m+[m[32m                            print_pattern: cond.print_pattern,[m
[32m+[m[32m                            "x-coordinate": cond.x,[m
[32m+[m[32m                            "y-coordinate": cond.y[m
[32m+[m[32m                        }))[m
[32m+[m[32m                    };[m
[32m+[m[32m                    pageGroups[zeroBasedPage].push(conditionalVar);[m
[32m+[m[32m                }[m
             });[m
 [m
             const configuration = Object.keys(pageGroups).map(page => ({[m
[36m@@ -1061,7 +1394,9 @@[m
   "email": "john.doe@example.com",[m
   "date": "2024-01-15",[m
   "company": "Example Corp",[m
[31m-  "position": "Software Engineer"[m
[32m+[m[32m  "position": "Software Engineer",[m
[32m+[m[32m  "gender": "Male",[m
[32m+[m[32m  "status": "Active"[m
 }`;[m
     </script>[m
 </body>[m
[1mdiff --git a/uploads/f725f5f1-4ac2-4a42-bb44-f7f74eb9003f_NRIOnline.pdf.pdf b/uploads/f725f5f1-4ac2-4a42-bb44-f7f74eb9003f_NRIOnline.pdf.pdf[m
[1mdeleted file mode 100644[m
[1mindex faaec9f..0000000[m
Binary files a/uploads/f725f5f1-4ac2-4a42-bb44-f7f74eb9003f_NRIOnline.pdf.pdf and /dev/null differ

[33mcommit a0309a8827130b522c62ed7b47a0929e9073ab9c[m
Author: shridhar <shridhar.p@zerodha.com>
Date:   Fri May 30 20:40:04 2025 +0530

    fix: gitignore

[1mdiff --git a/.gitignore b/.gitignore[m
[1mnew file mode 100644[m
[1mindex 0000000..f0b0c39[m
[1m--- /dev/null[m
[1m+++ b/.gitignore[m
[36m@@ -0,0 +1,2 @@[m
[32m+[m[32moutputs/*.pdf[m
[32m+[m[32muploads/*.pdf[m

[33mcommit e0ac6625a194747e184de192882d4a9270826b79[m
Author: shridhar <shridhar.p@zerodha.com>
Date:   Fri May 30 17:19:22 2025 +0530

    initial commit

[1mdiff --git a/app.py b/app.py[m
[1mnew file mode 100644[m
[1mindex 0000000..48e79a0[m
[1m--- /dev/null[m
[1m+++ b/app.py[m
[36m@@ -0,0 +1,330 @@[m
[32m+[m[32m"""[m
[32m+[m[32mFlask PDF Text Overlay Application[m
[32m+[m[32m==================================[m
[32m+[m[32mA complete web application for configuring and applying text overlays to PDF documents.[m
[32m+[m[32m"""[m
[32m+[m
[32m+[m[32mfrom flask import Flask, render_template, request, jsonify, send_file, session[m
[32m+[m[32mfrom werkzeug.utils import secure_filename[m
[32m+[m[32mimport os[m
[32m+[m[32mimport json[m
[32m+[m[32mimport io[m
[32m+[m[32mimport uuid[m
[32m+[m[32mfrom datetime import datetime[m
[32m+[m[32mimport tempfile[m
[32m+[m[32mimport traceback[m
[32m+[m
[32m+[m[32m# Import the pdf_text_overlay library[m
[32m+[m[32mtry:[m
[32m+[m[32m    from pdf_text_overlay import pdf_writer, pdf_from_template[m
[32m+[m[32mexcept ImportError as e:[m
[32m+[m[32m    raise e[m
[32m+[m[32m    print("Warning: pdf_text_overlay library not installed. Install with: pip install pdf_text_overlay")[m
[32m+[m[32m    pdf_writer = None[m
[32m+[m[32m    pdf_from_template = None[m
[32m+[m
[32m+[m[32mapp = Flask(__name__)[m
[32m+[m[32mapp.secret_key = 'your-secret-key-change-this-in-production'[m
[32m+[m
[32m+[m[32m# Configuration[m
[32m+[m[32mUPLOAD_FOLDER = 'uploads'[m
[32m+[m[32mOUTPUT_FOLDER = 'outputs'[m
[32m+[m[32mFONT_FOLDER = 'fonts'[m
[32m+[m[32mALLOWED_EXTENSIONS = {'pdf'}[m
[32m+[m[32mMAX_FILE_SIZE = 16 * 1024 * 1024  # 16MB[m
[32m+[m
[32m+[m[32m# Create necessary directories[m
[32m+[m[32mfor folder in [UPLOAD_FOLDER, OUTPUT_FOLDER, FONT_FOLDER]:[m
[32m+[m[32m    os.makedirs(folder, exist_ok=True)[m
[32m+[m
[32m+[m[32mdef allowed_file(filename):[m
[32m+[m[32m    """Check if file extension is allowed"""[m
[32m+[m[32m    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS[m
[32m+[m
[32m+[m[32mdef get_session_id():[m
[32m+[m[32m    """Get or create session ID"""[m
[32m+[m[32m    if 'session_id' not in session:[m
[32m+[m[32m        session['session_id'] = str(uuid.uuid4())[m
[32m+[m[32m    return session['session_id'][m
[32m+[m
[32m+[m[32m@app.route('/')[m
[32m+[m[32mdef index():[m
[32m+[m[32m    """Main page with the PDF overlay configuration tool"""[m
[32m+[m[32m    return render_template('index.html')[m
[32m+[m
[32m+[m[32m@app.route('/api/upload', methods=['POST'])[m
[32m+[m[32mdef upload_pdf():[m
[32m+[m[32m    """Handle PDF file upload"""[m
[32m+[m[32m    try:[m
[32m+[m[32m        if 'pdf' not in request.files:[m
[32m+[m[32m            return jsonify({'error': 'No file uploaded'}), 400[m
[32m+[m[41m        [m
[32m+[m[32m        file = request.files['pdf'][m
[32m+[m[32m        if file.filename == '':[m
[32m+[m[32m            return jsonify({'error': 'No file selected'}), 400[m
[32m+[m[41m        [m
[32m+[m[32m        if not allowed_file(file.filename):[m
[32m+[m[32m            return jsonify({'error': 'Invalid file type. Only PDF files are allowed'}), 400[m
[32m+[m[41m        [m
[32m+[m[32m        # Save file with session-specific name[m
[32m+[m[32m        session_id = get_session_id()[m
[32m+[m[32m        filename = secure_filename(file.filename)[m
[32m+[m[32m        file_path = os.path.join(UPLOAD_FOLDER, f"{session_id}_{filename}")[m
[32m+[m[32m        file.save(file_path)[m
[32m+[m[41m        [m
[32m+[m[32m        # Store file info in session[m
[32m+[m[32m        session['uploaded_pdf'] = {[m
[32m+[m[32m            'filename': filename,[m
[32m+[m[32m            'path': file_path,[m
[32m+[m[32m            'upload_time': datetime.now().isoformat()[m
[32m+[m[32m        }[m
[32m+[m[41m        [m
[32m+[m[32m        return jsonify({[m
[32m+[m[32m            'success': True,[m
[32m+[m[32m            'filename': filename,[m
[32m+[m[32m            'message': 'PDF uploaded successfully'[m
[32m+[m[32m        })[m
[32m+[m[41m        [m
[32m+[m[32m    except Exception as e:[m
[32m+[m[32m        return jsonify({'error': f'Upload failed: {str(e)}'}), 500[m
[32m+[m
[32m+[m[32m@app.route('/api/process', methods=['POST'])[m
[32m+[m[32mdef process_pdf():[m
[32m+[m[32m    """Process PDF with text overlays"""[m
[32m+[m[32m    try:[m
[32m+[m[32m        if pdf_writer is None:[m
[32m+[m[32m            return jsonify({'error': 'pdf_text_overlay library not installed'}), 500[m
[32m+[m[41m        [m
[32m+[m[32m        if 'uploaded_pdf' not in session:[m
[32m+[m[32m            return jsonify({'error': 'No PDF uploaded'}), 400[m
[32m+[m[41m        [m
[32m+[m[32m        data = request.get_json()[m
[32m+[m[32m        configuration = data.get('configuration', [])[m
[32m+[m[32m        sample_data = data.get('sample_data', {})[m
[32m+[m[41m        [m
[32m+[m[32m        if not configuration:[m
[32m+[m[32m            return jsonify({'error': 'No configuration provided'}), 400[m
[32m+[m[41m        [m
[32m+[m[32m        # Get uploaded PDF path[m
[32m+[m[32m        pdf_path = session['uploaded_pdf']['path'][m
[32m+[m[41m        [m
[32m+[m[32m        if not os.path.exists(pdf_path):[m
[32m+[m[32m            return jsonify({'error': 'Uploaded PDF not found'}), 404[m
[32m+[m[41m        [m
[32m+[m[32m        # Convert coordinates from canvas to PDF coordinate system[m
[32m+[m[32m        # The frontend sends canvas coordinates, we need to convert them to PDF coordinates[m
[32m+[m[32m        converted_config = [][m
[32m+[m[32m        for page_config in configuration:[m
[32m+[m[32m            converted_page = {[m
[32m+[m[32m                'page_number': page_config['page_number'],[m
[32m+[m[32m                'variables': [][m
[32m+[m[32m            }[m
[32m+[m[41m            [m
[32m+[m[32m            for var in page_config['variables']:[m
[32m+[m[32m                # The coordinates are already converted in the frontend[m
[32m+[m[32m                # but we ensure they match the pdf_text_overlay format[m
[32m+[m[32m                converted_var = {[m
[32m+[m[32m                    'name': var['name'],[m
[32m+[m[32m                    'x-coordinate': var['x-coordinate'],[m
[32m+[m[32m                    'y-coordinate': var['y-coordinate'],[m
[32m+[m[32m                    'font_size': var.get('font_size', 12)[m
[32m+[m[32m                }[m
[32m+[m[32m                converted_page['variables'].append(converted_var)[m
[32m+[m[41m            [m
[32m+[m[32m            converted_config.append(converted_page)[m
[32m+[m[41m        [m
[32m+[m[32m        # Default font (you can add custom font upload functionality)[m
[32m+[m[32m        font_path = os.path.join(FONT_FOLDER, 'default.ttf')  # Will use default font if None[m
[32m+[m[41m        [m
[32m+[m[32m        # Process PDF[m
[32m+[m[32m        with open(pdf_path, 'rb') as pdf_file:[m
[32m+[m[32m            if font_path and os.path.exists(font_path):[m
[32m+[m[32m                with open(font_path, 'rb') as font_file:[m
[32m+[m[32m                    output = pdf_writer(pdf_file, converted_config, sample_data, font_file)[m
[32m+[m[32m            else:[m
[32m+[m[32m                output = pdf_writer(pdf_file, converted_config, sample_data, None)[m
[32m+[m[32m        print(output)[m
[32m+[m[32m        # Save output PDF[m
[32m+[m[32m        session_id = get_session_id()[m
[32m+[m[32m        output_filename = f"output_{session_id}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"[m
[32m+[m[32m        output_path = os.path.join(OUTPUT_FOLDER, output_filename)[m
[32m+[m[41m        [m
[32m+[m[32m        with open(output_path, 'wb') as output_file:[m
[32m+[m[32m            output.write(output_file)[m
[32m+[m[41m        [m
[32m+[m[32m        return jsonify({[m
[32m+[m[32m            'success': True,[m
[32m+[m[32m            'output_filename': output_filename,[m
[32m+[m[32m            'message': 'PDF processed successfully'[m
[32m+[m[32m        })[m
[32m+[m[41m        [m
[32m+[m[32m    except Exception as e:[m
[32m+[m[32m        error_msg = f'Processing failed: {str(e)}'[m
[32m+[m[32m        print(f"Error processing PDF: {traceback.format_exc()}")[m
[32m+[m[32m        return jsonify({'error': error_msg}), 500[m
[32m+[m
[32m+[m[32m@app.route('/api/download/<filename>')[m
[32m+[m[32mdef download_file(filename):[m
[32m+[m[32m    """Download processed PDF"""[m
[32m+[m[32m    try:[m
[32m+[m[32m        file_path = os.path.join(OUTPUT_FOLDER, filename)[m
[32m+[m[32m        if not os.path.exists(file_path):[m
[32m+[m[32m            return jsonify({'error': 'File not found'}), 404[m
[32m+[m[41m        [m
[32m+[m[32m        return send_file(file_path, as_attachment=True, download_name=filename)[m
[32m+[m[41m        [m
[32m+[m[32m    except Exception as e:[m
[32m+[m[32m        return jsonify({'error': f'Download failed: {str(e)}'}), 500[m
[32m+[m
[32m+[m[32m@app.route('/api/template', methods=['POST'])[m
[32m+[m[32mdef process_template():[m
[32m+[m[32m    """Process HTML template to PDF"""[m
[32m+[m[32m    try:[m
[32m+[m[32m        if pdf_from_template is None:[m
[32m+[m[32m            return jsonify({'error': 'pdf_text_overlay library not installed'}), 500[m
[32m+[m[41m        [m
[32m+[m[32m        data = request.get_json()[m
[32m+[m[32m        html_template = data.get('html_template', '')[m
[32m+[m[32m        template_data = data.get('template_data', {})[m
[32m+[m[41m        [m
[32m+[m[32m        if not html_template:[m
[32m+[m[32m            return jsonify({'error': 'No HTML template provided'}), 400[m
[32m+[m[41m        [m
[32m+[m[32m        # Process template[m
[32m+[m[32m        output = pdf_from_template(html_template, template_data)[m
[32m+[m[41m        [m
[32m+[m[32m        # Save output PDF[m
[32m+[m[32m        session_id = get_session_id()[m
[32m+[m[32m        output_filename = f"template_{session_id}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"[m
[32m+[m[32m        output_path = os.path.join(OUTPUT_FOLDER, output_filename)[m
[32m+[m[41m        [m
[32m+[m[32m        with open(output_path, 'wb') as output_file:[m
[32m+[m[32m            output_file.write(output)[m
[32m+[m[41m        [m
[32m+[m[32m        return jsonify({[m
[32m+[m[32m            'success': True,[m
[32m+[m[32m            'output_filename': output_filename,[m
[32m+[m[32m            'message': 'Template processed successfully'[m
[32m+[m[32m        })[m
[32m+[m[41m        [m
[32m+[m[32m    except Exception as e:[m
[32m+[m[32m        error_msg = f'Template processing failed: {str(e)}'[m
[32m+[m[32m        print(f"Error processing template: {traceback.format_exc()}")[m
[32m+[m[32m        return jsonify({'error': error_msg}), 500[m
[32m+[m
[32m+[m[32m@app.route('/api/save-config', methods=['POST'])[m
[32m+[m[32mdef save_config():[m
[32m+[m[32m    """Save configuration for later use"""[m
[32m+[m[32m    try:[m
[32m+[m[32m        data = request.get_json()[m
[32m+[m[32m        config_name = data.get('name', f'config_{datetime.now().strftime("%Y%m%d_%H%M%S")}')[m
[32m+[m[32m        configuration = data.get('configuration', [])[m
[32m+[m[41m        [m
[32m+[m[32m        session_id = get_session_id()[m
[32m+[m[32m        config_path = os.path.join(UPLOAD_FOLDER, f"config_{session_id}_{config_name}.json")[m
[32m+[m[41m        [m
[32m+[m[32m        with open(config_path, 'w') as f:[m
[32m+[m[32m            json.dump({[m
[32m+[m[32m                'name': config_name,[m
[32m+[m[32m                'configuration': configuration,[m
[32m+[m[32m                'created': datetime.now().isoformat()[m
[32m+[m[32m            }, f, indent=2)[m
[32m+[m[41m        [m
[32m+[m[32m        return jsonify({[m
[32m+[m[32m            'success': True,[m
[32m+[m[32m            'message': f'Configuration saved as {config_name}'[m
[32m+[m[32m        })[m
[32m+[m[41m        [m
[32m+[m[32m    except Exception as e:[m
[32m+[m[32m        return jsonify({'error': f'Failed to save configuration: {str(e)}'}), 500[m
[32m+[m
[32m+[m[32m@app.route('/api/pdf-info', methods=['GET'])[m
[32m+[m[32mdef get_pdf_info():[m
[32m+[m[32m    """Get PDF page dimensions for coordinate conversion"""[m
[32m+[m[32m    try:[m
[32m+[m[32m        if 'uploaded_pdf' not in session:[m
[32m+[m[32m            return jsonify({'error': 'No PDF uploaded'}), 400[m
[32m+[m[41m        [m
[32m+[m[32m        pdf_path = session['uploaded_pdf']['path'][m
[32m+[m[41m        [m
[32m+[m[32m        if not os.path.exists(pdf_path):[m
[32m+[m[32m            return jsonify({'error': 'Uploaded PDF not found'}), 404[m
[32m+[m[41m        [m
[32m+[m[32m        # Import PyPDF2 or similar to get page dimensions[m
[32m+[m[32m        try:[m
[32m+[m[32m            import PyPDF2[m
[32m+[m[32m            with open(pdf_path, 'rb') as pdf_file:[m
[32m+[m[32m                pdf_reader = PyPDF2.PdfReader(pdf_file)[m
[32m+[m[32m                pages_info = [][m
[32m+[m[41m                [m
[32m+[m[32m                for i, page in enumerate(pdf_reader.pages):[m
[32m+[m[32m                    mediabox = page.mediabox[m
[32m+[m[32m                    pages_info.append({[m
[32m+[m[32m                        'page': i + 1,[m
[32m+[m[32m                        'width': float(mediabox.width),[m
[32m+[m[32m                        'height': float(mediabox.height)[m
[32m+[m[32m                    })[m
[32m+[m[41m                [m
[32m+[m[32m                return jsonify({[m
[32m+[m[32m                    'success': True,[m
[32m+[m[32m                    'total_pages': len(pages_info),[m
[32m+[m[32m                    'pages': pages_info[m
[32m+[m[32m                })[m
[32m+[m[32m        except ImportError:[m
[32m+[m[32m            # Fallback: use standard PDF dimensions (US Letter)[m
[32m+[m[32m            return jsonify({[m
[32m+[m[32m                'success': True,[m
[32m+[m[32m                'total_pages': 1,[m
[32m+[m[32m                'pages': [{'page': 1, 'width': 612, 'height': 792}],[m
[32m+[m[32m                'note': 'Using default dimensions - install PyPDF2 for accurate dimensions'[m
[32m+[m[32m            })[m
[32m+[m[41m        [m
[32m+[m[32m    except Exception as e:[m
[32m+[m[32m        return jsonify({'error': f'Failed to get PDF info: {str(e)}'}), 500[m
[32m+[m[32m    """Load saved configuration"""[m
[32m+[m[32m    try:[m
[32m+[m[32m        session_id = get_session_id()[m
[32m+[m[32m        config_path = os.path.join(UPLOAD_FOLDER, f"config_{session_id}_{config_name}.json")[m
[32m+[m[41m        [m
[32m+[m[32m        if not os.path.exists(config_path):[m
[32m+[m[32m            return jsonify({'error': 'Configuration not found'}), 404[m
[32m+[m[41m        [m
[32m+[m[32m        with open(config_path, 'r') as f:[m
[32m+[m[32m            config_data = json.load(f)[m
[32m+[m[41m        [m
[32m+[m[32m        return jsonify(config_data)[m
[32m+[m[41m        [m
[32m+[m[32m    except Exception as e:[m
[32m+[m[32m        return jsonify({'error': f'Failed to load configuration: {str(e)}'}), 500[m
[32m+[m
[32m+[m[32m# Error handlers[m
[32m+[m[32m@app.errorhandler(413)[m
[32m+[m[32mdef too_large(e):[m
[32m+[m[32m    return jsonify({'error': 'File too large. Maximum size is 16MB'}), 413[m
[32m+[m
[32m+[m[32m@app.errorhandler(404)[m
[32m+[m[32mdef not_found(e):[m
[32m+[m[32m    return jsonify({'error': 'Resource not found'}), 404[m
[32m+[m
[32m+[m[32m@app.errorhandler(500)[m
[32m+[m[32mdef server_error(e):[m
[32m+[m[32m    return jsonify({'error': 'Internal server error'}), 500[m
[32m+[m
[32m+[m[32mif __name__ == '__main__':[m
[32m+[m[32m    # Create a simple default font file if none exists[m
[32m+[m[32m    default_font_path = os.path.join(FONT_FOLDER, 'default.ttf')[m
[32m+[m[32m    if not os.path.exists(default_font_path):[m
[32m+[m[32m        print(f"Note: No default font found at {default_font_path}")[m
[32m+[m[32m        print("You may want to add a TTF font file for better text rendering")[m
[32m+[m[41m    [m
[32m+[m[32m    print("Starting Flask PDF Text Overlay Application...")[m
[32m+[m[32m    print("Available endpoints:")[m
[32m+[m[32m    print("  GET  /                    - Main application interface")[m
[32m+[m[32m    print("  POST /api/upload          - Upload PDF file")[m
[32m+[m[32m    print("  POST /api/process         - Process PDF with overlays")[m
[32m+[m[32m    print("  POST /api/template        - Process HTML template to PDF")[m
[32m+[m[32m    print("  GET  /api/download/<file> - Download processed PDF")[m
[32m+[m[32m    print("  POST /api/save-config     - Save configuration")[m
[32m+[m[32m    print("  GET  /api/load-config     - Load saved configuration")[m
[32m+[m[41m    [m
[32m+[m[32m    app.run(debug=True, host='0.0.0.0', port=5000)[m
\ No newline at end of file[m
[1mdiff --git a/fonts/Swiss721CondensedBT.ttf b/fonts/Swiss721CondensedBT.ttf[m
[1mnew file mode 100644[m
[1mindex 0000000..38417db[m
Binary files /dev/null and b/fonts/Swiss721CondensedBT.ttf differ
[1mdiff --git a/fonts/default.ttf b/fonts/default.ttf[m
[1mnew file mode 100644[m
[1mindex 0000000..38417db[m
Binary files /dev/null and b/fonts/default.ttf differ
[1mdiff --git a/outputs/output_f725f5f1-4ac2-4a42-bb44-f7f74eb9003f_20250530_165403.pdf b/outputs/output_f725f5f1-4ac2-4a42-bb44-f7f74eb9003f_20250530_165403.pdf[m
[1mnew file mode 100644[m
[1mindex 0000000..e69de29[m
[1mdiff --git a/outputs/output_f725f5f1-4ac2-4a42-bb44-f7f74eb9003f_20250530_165515.pdf b/outputs/output_f725f5f1-4ac2-4a42-bb44-f7f74eb9003f_20250530_165515.pdf[m
[1mnew file mode 100644[m
[1mindex 0000000..e69de29[m
[1mdiff --git a/outputs/output_f725f5f1-4ac2-4a42-bb44-f7f74eb9003f_20250530_170335.pdf b/outputs/output_f725f5f1-4ac2-4a42-bb44-f7f74eb9003f_20250530_170335.pdf[m
[1mnew file mode 100644[m
[1mindex 0000000..7079e8d[m
Binary files /dev/null and b/outputs/output_f725f5f1-4ac2-4a42-bb44-f7f74eb9003f_20250530_170335.pdf differ
[1mdiff --git a/outputs/output_f725f5f1-4ac2-4a42-bb44-f7f74eb9003f_20250530_170418.pdf b/outputs/output_f725f5f1-4ac2-4a42-bb44-f7f74eb9003f_20250530_170418.pdf[m
[1mnew file mode 100644[m
[1mindex 0000000..e2b4405[m
Binary files /dev/null and b/outputs/output_f725f5f1-4ac2-4a42-bb44-f7f74eb9003f_20250530_170418.pdf differ
[1mdiff --git a/outputs/output_f725f5f1-4ac2-4a42-bb44-f7f74eb9003f_20250530_170917.pdf b/outputs/output_f725f5f1-4ac2-4a42-bb44-f7f74eb9003f_20250530_170917.pdf[m
[1mnew file mode 100644[m
[1mindex 0000000..c3fc536[m
Binary files /dev/null and b/outputs/output_f725f5f1-4ac2-4a42-bb44-f7f74eb9003f_20250530_170917.pdf differ
[1mdiff --git a/outputs/output_f725f5f1-4ac2-4a42-bb44-f7f74eb9003f_20250530_170950.pdf b/outputs/output_f725f5f1-4ac2-4a42-bb44-f7f74eb9003f_20250530_170950.pdf[m
[1mnew file mode 100644[m
[1mindex 0000000..ac6bd11[m
Binary files /dev/null and b/outputs/output_f725f5f1-4ac2-4a42-bb44-f7f74eb9003f_20250530_170950.pdf differ
[1mdiff --git a/outputs/output_f725f5f1-4ac2-4a42-bb44-f7f74eb9003f_20250530_171100.pdf b/outputs/output_f725f5f1-4ac2-4a42-bb44-f7f74eb9003f_20250530_171100.pdf[m
[1mnew file mode 100644[m
[1mindex 0000000..979bc92[m
Binary files /dev/null and b/outputs/output_f725f5f1-4ac2-4a42-bb44-f7f74eb9003f_20250530_171100.pdf differ
[1mdiff --git a/requirements.txt b/requirements.txt[m
[1mnew file mode 100644[m
[1mindex 0000000..c558d0f[m
[1m--- /dev/null[m
[1m+++ b/requirements.txt[m
[36m@@ -0,0 +1,8 @@[m
[32m+[m[32mFlask==2.3.3[m
[32m+[m[32mWerkzeug==2.3.7[m
[32m+[m[32mpdf_text_overlay[m
[32m+[m[32mPyPDF2==3.0.1[m
[32m+[m[32mJinja2==3.1.2[m
[32m+[m[32mMarkupSafe==2.1.3[m
[32m+[m[32mitsdangerous==2.1.2[m
[32m+[m[32mclick==8.1.7[m
\ No newline at end of file[m
[1mdiff --git a/templates/index.html b/templates/index.html[m
[1mnew file mode 100644[m
[1mindex 0000000..5105e30[m
[1m--- /dev/null[m
[1m+++ b/templates/index.html[m
[36m@@ -0,0 +1,1068 @@[m
[32m+[m[32m<!DOCTYPE html>[m
[32m+[m[32m<html lang="en">[m
[32m+[m[32m<head>[m
[32m+[m[32m    <meta charset="UTF-8">[m
[32m+[m[32m    <meta name="viewport" content="width=device-width, initial-scale=1.0">[m
[32m+[m[32m    <title>PDF Text Overlay Tool - Flask App</title>[m
[32m+[m[32m    <script src="https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.min.js"></script>[m
[32m+[m[32m    <style>[m
[32m+[m[32m        * {[m
[32m+[m[32m            margin: 0;[m
[32m+[m[32m            padding: 0;[m
[32m+[m[32m            box-sizing: border-box;[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        body {[m
[32m+[m[32m            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;[m
[32m+[m[32m            background: #f5f7fa;[m
[32m+[m[32m            color: #333;[m
[32m+[m[32m            overflow-x: hidden;[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .header {[m
[32m+[m[32m            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);[m
[32m+[m[32m            color: white;[m
[32m+[m[32m            padding: 20px;[m
[32m+[m[32m            text-align: center;[m
[32m+[m[32m            box-shadow: 0 4px 20px rgba(0,0,0,0.1);[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .header h1 {[m
[32m+[m[32m            font-size: 2rem;[m
[32m+[m[32m            margin-bottom: 5px;[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .header p {[m
[32m+[m[32m            opacity: 0.9;[m
[32m+[m[32m            font-size: 1rem;[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .main-container {[m
[32m+[m[32m            display: flex;[m
[32m+[m[32m            height: calc(100vh - 100px);[m
[32m+[m[32m            gap: 20px;[m
[32m+[m[32m            padding: 20px;[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        /* PDF Preview Section */[m
[32m+[m[32m        .pdf-section {[m
[32m+[m[32m            flex: 1;[m
[32m+[m[32m            background: white;[m
[32m+[m[32m            border-radius: 15px;[m
[32m+[m[32m            box-shadow: 0 10px 30px rgba(0,0,0,0.1);[m
[32m+[m[32m            display: flex;[m
[32m+[m[32m            flex-direction: column;[m
[32m+[m[32m            overflow: hidden;[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .pdf-header {[m
[32m+[m[32m            background: linear-gradient(90deg, #667eea, #764ba2);[m
[32m+[m[32m            color: white;[m
[32m+[m[32m            padding: 15px 20px;[m
[32m+[m[32m            display: flex;[m
[32m+[m[32m            justify-content: space-between;[m
[32m+[m[32m            align-items: center;[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .pdf-controls {[m
[32m+[m[32m            display: flex;[m
[32m+[m[32m            gap: 10px;[m
[32m+[m[32m            align-items: center;[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .page-nav {[m
[32m+[m[32m            background: rgba(255,255,255,0.2);[m
[32m+[m[32m            color: white;[m
[32m+[m[32m            border: none;[m
[32m+[m[32m            padding: 5px 10px;[m
[32m+[m[32m            border-radius: 5px;[m
[32m+[m[32m            cursor: pointer;[m
[32m+[m[32m            font-size: 0.9rem;[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .page-nav:hover {[m
[32m+[m[32m            background: rgba(255,255,255,0.3);[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .page-nav:disabled {[m
[32m+[m[32m            opacity: 0.5;[m
[32m+[m[32m            cursor: not-allowed;[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .upload-area {[m
[32m+[m[32m            flex: 1;[m
[32m+[m[32m            display: flex;[m
[32m+[m[32m            align-items: center;[m
[32m+[m[32m            justify-content: center;[m
[32m+[m[32m            border: 3px dashed #667eea;[m
[32m+[m[32m            margin: 20px;[m
[32m+[m[32m            border-radius: 15px;[m
[32m+[m[32m            cursor: pointer;[m
[32m+[m[32m            transition: all 0.3s ease;[m
[32m+[m[32m            background: linear-gradient(45deg, rgba(102, 126, 234, 0.05) 0%, rgba(118, 75, 162, 0.05) 100%);[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .upload-area:hover {[m
[32m+[m[32m            border-color: #764ba2;[m
[32m+[m[32m            background: linear-gradient(45deg, rgba(102, 126, 234, 0.1) 0%, rgba(118, 75, 162, 0.1) 100%);[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .upload-content {[m
[32m+[m[32m            text-align: center;[m
[32m+[m[32m            padding: 40px;[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .upload-icon {[m
[32m+[m[32m            font-size: 4rem;[m
[32m+[m[32m            color: #667eea;[m
[32m+[m[32m            margin-bottom: 20px;[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .pdf-viewer {[m
[32m+[m[32m            flex: 1;[m
[32m+[m[32m            position: relative;[m
[32m+[m[32m            overflow: auto;[m
[32m+[m[32m            background: #f8f9fa;[m
[32m+[m[32m            display: none;[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .pdf-canvas {[m
[32m+[m[32m            display: block;[m
[32m+[m[32m            margin: 20px auto;[m
[32m+[m[32m            border: 1px solid #ddd;[m
[32m+[m[32m            border-radius: 10px;[m
[32m+[m[32m            box-shadow: 0 5px 20px rgba(0,0,0,0.1);[m
[32m+[m[32m            cursor: crosshair;[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .text-overlay {[m
[32m+[m[32m            position: absolute;[m
[32m+[m[32m            background: rgba(102, 126, 234, 0.8);[m
[32m+[m[32m            color: white;[m
[32m+[m[32m            padding: 2px 6px;[m
[32m+[m[32m            border-radius: 3px;[m
[32m+[m[32m            font-size: 12px;[m
[32m+[m[32m            pointer-events: none;[m
[32m+[m[32m            transform: translate(-50%, -100%);[m
[32m+[m[32m            white-space: nowrap;[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        /* Configuration Section */[m
[32m+[m[32m        .config-section {[m
[32m+[m[32m            flex: 1;[m
[32m+[m[32m            background: white;[m
[32m+[m[32m            border-radius: 15px;[m
[32m+[m[32m            box-shadow: 0 10px 30px rgba(0,0,0,0.1);[m
[32m+[m[32m            display: flex;[m
[32m+[m[32m            flex-direction: column;[m
[32m+[m[32m            overflow: hidden;[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .config-header {[m
[32m+[m[32m            background: linear-gradient(90deg, #764ba2, #667eea);[m
[32m+[m[32m            color: white;[m
[32m+[m[32m            padding: 15px 20px;[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .config-content {[m
[32m+[m[32m            flex: 1;[m
[32m+[m[32m            overflow-y: auto;[m
[32m+[m[32m            padding: 20px;[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .section {[m
[32m+[m[32m            margin-bottom: 25px;[m
[32m+[m[32m            padding: 20px;[m
[32m+[m[32m            border: 1px solid #e1e5e9;[m
[32m+[m[32m            border-radius: 10px;[m
[32m+[m[32m            background: #f8f9fa;[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .section h3 {[m
[32m+[m[32m            margin-bottom: 15px;[m
[32m+[m[32m            color: #667eea;[m
[32m+[m[32m            font-size: 1.2rem;[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .form-group {[m
[32m+[m[32m            margin-bottom: 15px;[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .form-group label {[m
[32m+[m[32m            display: block;[m
[32m+[m[32m            margin-bottom: 5px;[m
[32m+[m[32m            font-weight: 600;[m
[32m+[m[32m            color: #555;[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .form-control {[m
[32m+[m[32m            width: 100%;[m
[32m+[m[32m            padding: 10px;[m
[32m+[m[32m            border: 2px solid #e1e5e9;[m
[32m+[m[32m            border-radius: 8px;[m
[32m+[m[32m            font-size: 0.9rem;[m
[32m+[m[32m            transition: border-color 0.3s ease;[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .form-control:focus {[m
[32m+[m[32m            outline: none;[m
[32m+[m[32m            border-color: #667eea;[m
[32m+[m[32m            box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        textarea.form-control {[m
[32m+[m[32m            resize: vertical;[m
[32m+[m[32m            min-height: 120px;[m
[32m+[m[32m            font-family: 'Courier New', monospace;[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .btn {[m
[32m+[m[32m            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);[m
[32m+[m[32m            color: white;[m
[32m+[m[32m            border: none;[m
[32m+[m[32m            padding: 12px 20px;[m
[32m+[m[32m            border-radius: 8px;[m
[32m+[m[32m            cursor: pointer;[m
[32m+[m[32m            font-size: 0.9rem;[m
[32m+[m[32m            transition: all 0.3s ease;[m
[32m+[m[32m            font-weight: 600;[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .btn:hover {[m
[32m+[m[32m            transform: translateY(-2px);[m
[32m+[m[32m            box-shadow: 0 5px 15px rgba(102, 126, 234, 0.3);[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .btn:disabled {[m
[32m+[m[32m            opacity: 0.5;[m
[32m+[m[32m            cursor: not-allowed;[m
[32m+[m[32m            transform: none;[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .btn-secondary {[m
[32m+[m[32m            background: linear-gradient(135deg, #6c757d 0%, #495057 100%);[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .btn-success {[m
[32m+[m[32m            background: linear-gradient(135deg, #28a745 0%, #20c997 100%);[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .btn-danger {[m
[32m+[m[32m            background: linear-gradient(135deg, #dc3545 0%, #c82333 100%);[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .btn-block {[m
[32m+[m[32m            width: 100%;[m
[32m+[m[32m            margin-bottom: 10px;[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .variable-item {[m
[32m+[m[32m            background: white;[m
[32m+[m[32m            border: 1px solid #dee2e6;[m
[32m+[m[32m            border-radius: 8px;[m
[32m+[m[32m            padding: 15px;[m
[32m+[m[32m            margin-bottom: 10px;[m
[32m+[m[32m            position: relative;[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .variable-header {[m
[32m+[m[32m            display: flex;[m
[32m+[m[32m            justify-content: space-between;[m
[32m+[m[32m            align-items: center;[m
[32m+[m[32m            margin-bottom: 10px;[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .remove-btn {[m
[32m+[m[32m            background: #dc3545;[m
[32m+[m[32m            color: white;[m
[32m+[m[32m            border: none;[m
[32m+[m[32m            padding: 5px 10px;[m
[32m+[m[32m            border-radius: 5px;[m
[32m+[m[32m            cursor: pointer;[m
[32m+[m[32m            font-size: 0.8rem;[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .coordinate-display {[m
[32m+[m[32m            background: #e9ecef;[m
[32m+[m[32m            padding: 8px;[m
[32m+[m[32m            border-radius: 5px;[m
[32m+[m[32m            font-family: 'Courier New', monospace;[m
[32m+[m[32m            font-size: 0.9rem;[m
[32m+[m[32m            margin-bottom: 10px;[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .config-output {[m
[32m+[m[32m            background: #2d3748;[m
[32m+[m[32m            color: #e2e8f0;[m
[32m+[m[32m            padding: 15px;[m
[32m+[m[32m            border-radius: 8px;[m
[32m+[m[32m            font-family: 'Courier New', monospace;[m
[32m+[m[32m            font-size: 0.85rem;[m
[32m+[m[32m            max-height: 300px;[m
[32m+[m[32m            overflow-y: auto;[m
[32m+[m[32m            white-space: pre-wrap;[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .click-instruction {[m
[32m+[m[32m            background: #fff3cd;[m
[32m+[m[32m            border: 1px solid #ffeaa7;[m
[32m+[m[32m            color: #856404;[m
[32m+[m[32m            padding: 10px;[m
[32m+[m[32m            border-radius: 8px;[m
[32m+[m[32m            margin-bottom: 15px;[m
[32m+[m[32m            text-align: center;[m
[32m+[m[32m            font-size: 0.9rem;[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .current-page-indicator {[m
[32m+[m[32m            background: rgba(255,255,255,0.2);[m
[32m+[m[32m            padding: 5px 10px;[m
[32m+[m[32m            border-radius: 5px;[m
[32m+[m[32m            font-size: 0.9rem;[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .notification {[m
[32m+[m[32m            position: fixed;[m
[32m+[m[32m            top: 20px;[m
[32m+[m[32m            right: 20px;[m
[32m+[m[32m            padding: 15px 20px;[m
[32m+[m[32m            border-radius: 8px;[m
[32m+[m[32m            color: white;[m
[32m+[m[32m            font-weight: 600;[m
[32m+[m[32m            z-index: 1000;[m
[32m+[m[32m            max-width: 300px;[m
[32m+[m[32m            opacity: 0;[m
[32m+[m[32m            transform: translateY(-20px);[m
[32m+[m[32m            transition: all 0.3s ease;[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .notification.show {[m
[32m+[m[32m            opacity: 1;[m
[32m+[m[32m            transform: translateY(0);[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .notification.success {[m
[32m+[m[32m            background: linear-gradient(135deg, #28a745 0%, #20c997 100%);[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .notification.error {[m
[32m+[m[32m            background: linear-gradient(135deg, #dc3545 0%, #c82333 100%);[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .loading {[m
[32m+[m[32m            display: none;[m
[32m+[m[32m            text-align: center;[m
[32m+[m[32m            padding: 20px;[m
[32m+[m[32m            color: #667eea;[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        .loading.show {[m
[32m+[m[32m            display: block;[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        @media (max-width: 1200px) {[m
[32m+[m[32m            .main-container {[m
[32m+[m[32m                flex-direction: column;[m
[32m+[m[32m                height: auto;[m
[32m+[m[32m            }[m
[32m+[m[41m            [m
[32m+[m[32m            .pdf-section, .config-section {[m
[32m+[m[32m                flex: none;[m
[32m+[m[32m                min-height: 500px;[m
[32m+[m[32m            }[m
[32m+[m[32m        }[m
[32m+[m[32m    </style>[m
[32m+[m[32m</head>[m
[32m+[m[32m<body>[m
[32m+[m[32m    <div class="header">[m
[32m+[m[32m        <h1>🚀 PDF Text Overlay Tool </h1>[m
[32m+[m[32m        <p>Upload, configure, and process PDF text overlays with real-time preview</p>[m
[32m+[m[32m    </div>[m
[32m+[m
[32m+[m[32m    <div class="main-container">[m
[32m+[m[32m        <!-- PDF Preview Section -->[m
[32m+[m[32m        <div class="pdf-section">[m
[32m+[m[32m            <div class="pdf-header">[m
[32m+[m[32m                <h3>📖 PDF Preview</h3>[m
[32m+[m[32m                <div class="pdf-controls" id="pdfControls" style="display: none;">[m
[32m+[m[32m                    <button class="page-nav" id="prevPage">← Previous</button>[m
[32m+[m[32m                    <span class="current-page-indicator" id="pageInfo">Page 1 of 1</span>[m
[32m+[m[32m                    <button class="page-nav" id="nextPage">Next →</button>[m
[32m+[m[32m                </div>[m
[32m+[m[32m            </div>[m
[32m+[m[41m            [m
[32m+[m[32m            <div class="upload-area" id="uploadArea">[m
[32m+[m[32m                <div class="upload-content">[m
[32m+[m[32m                    <div class="upload-icon">📁</div>[m
[32m+[m[32m                    <h3>Upload Your PDF</h3>[m
[32m+[m[32m                    <p>Drag and drop a PDF file here or click to browse</p>[m
[32m+[m[32m                    <input type="file" id="pdfInput" accept=".pdf" style="display: none;">[m
[32m+[m[32m                </div>[m
[32m+[m[32m            </div>[m
[32m+[m
[32m+[m[32m            <div class="pdf-viewer" id="pdfViewer">[m
[32m+[m[32m                <div class="click-instruction">[m
[32m+[m[32m                    💡 Click anywhere on the PDF to add text overlay positions[m
[32m+[m[32m                </div>[m
[32m+[m[32m                <canvas id="pdfCanvas" class="pdf-canvas"></canvas>[m
[32m+[m[32m            </div>[m
[32m+[m
[32m+[m[32m            <div class="loading" id="uploadLoading">[m
[32m+[m[32m                <div>📤 Uploading PDF...</div>[m
[32m+[m[32m            </div>[m
[32m+[m[32m        </div>[m
[32m+[m
[32m+[m[32m        <!-- Configuration Section -->[m
[32m+[m[32m        <div class="config-section">[m
[32m+[m[32m            <div class="config-header">[m
[32m+[m[32m                <h3>⚙️ Configuration & Processing</h3>[m
[32m+[m[32m            </div>[m
[32m+[m[41m            [m
[32m+[m[32m            <div class="config-content">[m
[32m+[m[32m                <!-- Sample Data Section -->[m
[32m+[m[32m                <div class="section">[m
[32m+[m[32m                    <h3>📝 Sample Data</h3>[m
[32m+[m[32m                    <div class="form-group">[m
[32m+[m[32m                        <label>Sample JSON Data (for overlay processing):</label>[m
[32m+[m[32m                        <textarea class="form-control" id="sampleData" placeholder='Enter sample data in JSON format, e.g.:[m
[32m+[m[32m{[m
[32m+[m[32m  "name": "John Doe",[m
[32m+[m[32m  "email": "john@example.com",[m
[32m+[m[32m  "date": "2024-01-15"[m
[32m+[m[32m}'></textarea>[m
[32m+[m[32m                    </div>[m
[32m+[m[32m                    <button class="btn btn-success btn-block" id="prefillBtn">✨ Prefill Data Based on Config</button>[m
[32m+[m[32m                </div>[m
[32m+[m
[32m+[m[32m                <!-- Variables Section -->[m
[32m+[m[32m                <div class="section">[m
[32m+[m[32m                    <h3>🎯 Text Variables</h3>[m
[32m+[m[32m                    <div id="variablesList">[m
[32m+[m[32m                        <!-- Variables will be added here dynamically -->[m
[32m+[m[32m                    </div>[m
[32m+[m[32m                    <button class="btn btn-secondary btn-block" id="addVariableBtn">+ Add Variable</button>[m
[32m+[m[32m                </div>[m
[32m+[m
[32m+[m[32m                <!-- Processing Section -->[m
[32m+[m[32m                <div class="section">[m
[32m+[m[32m                    <h3>🔧 Process PDF</h3>[m
[32m+[m[32m                    <button class="btn btn-block" id="processBtn" disabled>🚀 Process PDF with Overlays</button>[m
[32m+[m[32m                    <div class="loading" id="processLoading">[m
[32m+[m[32m                        <div>⚙️ Processing PDF...</div>[m
[32m+[m[32m                    </div>[m
[32m+[m[32m                    <div id="downloadSection" style="display: none; margin-top: 15px;">[m
[32m+[m[32m                        <button class="btn btn-success btn-block" id="downloadBtn">💾 Download Processed PDF</button>[m
[32m+[m[32m                    </div>[m
[32m+[m[32m                </div>[m
[32m+[m
[32m+[m[32m                <!-- Configuration Output -->[m
[32m+[m[32m                <div class="section">[m
[32m+[m[32m                    <h3>📋 Generated Configuration</h3>[m
[32m+[m[32m                    <div style="background: #e3f2fd; padding: 10px; border-radius: 5px; margin-bottom: 10px; font-size: 0.85rem;">[m
[32m+[m[32m                        💡 <strong>Note:</strong> Page numbers in config are 0-based (Page 1 → 0, Page 2 → 1, etc.)[m
[32m+[m[32m                    </div>[m
[32m+[m[32m                    <div class="config-output" id="configOutput">Click on the PDF to start adding variables...</div>[m
[32m+[m[32m                    <div style="display: flex; gap: 10px; margin-top: 10px;">[m
[32m+[m[32m                        <button class="btn" id="copyConfigBtn" style="flex: 1;">📋 Copy Config</button>[m
[32m+[m[32m                        <button class="btn btn-secondary" id="saveConfigBtn" style="flex: 1;">💾 Save Config</button>[m
[32m+[m[32m                    </div>[m
[32m+[m[32m                </div>[m
[32m+[m[32m            </div>[m
[32m+[m[32m        </div>[m
[32m+[m[32m    </div>[m
[32m+[m
[32m+[m[32m    <!-- Notification area -->[m
[32m+[m[32m    <div id="notification" class="notification"></div>[m
[32m+[m
[32m+[m[32m    <script>[m
[32m+[m[32m        // Global variables[m
[32m+[m[32m        let pdfDoc = null;[m
[32m+[m[32m        let currentPage = 1;[m
[32m+[m[32m        let totalPages = 0;[m
[32m+[m[32m        let pdfCanvas = null;[m
[32m+[m[32m        let pdfCtx = null;[m
[32m+[m[32m        let variables = [];[m
[32m+[m[32m        let scale = 1.5;[m
[32m+[m[32m        let pdfUploaded = false;[m
[32m+[m[32m        let processedFilename = null;[m
[32m+[m[32m        let pdfPageDimensions = {}; // Store actual PDF page dimensions[m
[32m+[m
[32m+[m[32m        // Initialize PDF.js[m
[32m+[m[32m        pdfjsLib.GlobalWorkerOptions.workerSrc = 'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.worker.min.js';[m
[32m+[m
[32m+[m[32m        // DOM elements[m
[32m+[m[32m        const uploadArea = document.getElementById('uploadArea');[m
[32m+[m[32m        const pdfInput = document.getElementById('pdfInput');[m
[32m+[m[32m        const pdfViewer = document.getElementById('pdfViewer');[m
[32m+[m[32m        const pdfControls = document.getElementById('pdfControls');[m
[32m+[m[32m        pdfCanvas = document.getElementById('pdfCanvas');[m
[32m+[m[32m        pdfCtx = pdfCanvas.getContext('2d');[m
[32m+[m[32m        const pageInfo = document.getElementById('pageInfo');[m
[32m+[m[32m        const prevPageBtn = document.getElementById('prevPage');[m
[32m+[m[32m        const nextPageBtn = document.getElementById('nextPage');[m
[32m+[m[32m        const variablesList = document.getElementById('variablesList');[m
[32m+[m[32m        const addVariableBtn = document.getElementById('addVariableBtn');[m
[32m+[m[32m        const configOutput = document.getElementById('configOutput');[m
[32m+[m[32m        const copyConfigBtn = document.getElementById('copyConfigBtn');[m
[32m+[m[32m        const saveConfigBtn = document.getElementById('saveConfigBtn');[m
[32m+[m[32m        const sampleData = document.getElementById('sampleData');[m
[32m+[m[32m        const prefillBtn = document.getElementById('prefillBtn');[m
[32m+[m[32m        const processBtn = document.getElementById('processBtn');[m
[32m+[m[32m        const downloadBtn = document.getElementById('downloadBtn');[m
[32m+[m[32m        const uploadLoading = document.getElementById('uploadLoading');[m
[32m+[m[32m        const processLoading = document.getElementById('processLoading');[m
[32m+[m[32m        const downloadSection = document.getElementById('downloadSection');[m
[32m+[m[32m        const notification = document.getElementById('notification');[m
[32m+[m
[32m+[m[32m        // Event listeners[m
[32m+[m[32m        uploadArea.addEventListener('click', () => pdfInput.click());[m
[32m+[m[32m        uploadArea.addEventListener('dragover', handleDragOver);[m
[32m+[m[32m        uploadArea.addEventListener('drop', handleDrop);[m
[32m+[m[32m        pdfInput.addEventListener('change', handleFileSelect);[m
[32m+[m[32m        pdfCanvas.addEventListener('click', handleCanvasClick);[m
[32m+[m[32m        prevPageBtn.addEventListener('click', () => changePage(-1));[m
[32m+[m[32m        nextPageBtn.addEventListener('click', () => changePage(1));[m
[32m+[m[32m        addVariableBtn.addEventListener('click', addVariable);[m
[32m+[m[32m        copyConfigBtn.addEventListener('click', copyConfiguration);[m
[32m+[m[32m        saveConfigBtn.addEventListener('click', saveConfiguration);[m
[32m+[m[32m        prefillBtn.addEventListener('click', prefillSampleData);[m
[32m+[m[32m        processBtn.addEventListener('click', processDocument);[m
[32m+[m[32m        downloadBtn.addEventListener('click', downloadProcessedPDF);[m
[32m+[m
[32m+[m[32m        // Utility functions[m
[32m+[m[32m        function showNotification(message, type = 'success') {[m
[32m+[m[32m            notification.textContent = message;[m
[32m+[m[32m            notification.className = `notification ${type}`;[m
[32m+[m[32m            notification.classList.add('show');[m
[32m+[m[32m            setTimeout(() => {[m
[32m+[m[32m                notification.classList.remove('show');[m
[32m+[m[32m            }, 4000);[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        function showLoading(element) {[m
[32m+[m[32m            element.classList.add('show');[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        function hideLoading(element) {[m
[32m+[m[32m            element.classList.remove('show');[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        // File handling[m
[32m+[m[32m        function handleDragOver(e) {[m
[32m+[m[32m            e.preventDefault();[m
[32m+[m[32m            uploadArea.classList.add('dragover');[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        function handleDrop(e) {[m
[32m+[m[32m            e.preventDefault();[m
[32m+[m[32m            uploadArea.classList.remove('dragover');[m
[32m+[m[32m            const files = e.dataTransfer.files;[m
[32m+[m[32m            if (files.length > 0) {[m
[32m+[m[32m                uploadPDF(files[0]);[m
[32m+[m[32m            }[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        function handleFileSelect(e) {[m
[32m+[m[32m            const file = e.target.files[0];[m
[32m+[m[32m            if (file) {[m
[32m+[m[32m                uploadPDF(file);[m
[32m+[m[32m            }[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        // PDF upload and processing[m
[32m+[m[32m        async function uploadPDF(file) {[m
[32m+[m[32m            if (file.size > 16 * 1024 * 1024) {[m
[32m+[m[32m                showNotification('File too large. Maximum size is 16MB.', 'error');[m
[32m+[m[32m                return;[m
[32m+[m[32m            }[m
[32m+[m
[32m+[m[32m            showLoading(uploadLoading);[m
[32m+[m[41m            [m
[32m+[m[32m            const formData = new FormData();[m
[32m+[m[32m            formData.append('pdf', file);[m
[32m+[m
[32m+[m[32m            try {[m
[32m+[m[32m                const response = await fetch('/api/upload', {[m
[32m+[m[32m                    method: 'POST',[m
[32m+[m[32m                    body: formData[m
[32m+[m[32m                });[m
[32m+[m
[32m+[m[32m                const result = await response.json();[m
[32m+[m[41m                [m
[32m+[m[32m                if (result.success) {[m
[32m+[m[32m                    showNotification(result.message);[m
[32m+[m[32m                    await loadPDFForPreview(file);[m
[32m+[m[32m                    pdfUploaded = true;[m
[32m+[m[32m                    processBtn.disabled = false;[m
[32m+[m[32m                } else {[m
[32m+[m[32m                    showNotification(result.error, 'error');[m
[32m+[m[32m                }[m
[32m+[m[32m            } catch (error) {[m
[32m+[m[32m                showNotification('Upload failed: ' + error.message, 'error');[m
[32m+[m[32m            } finally {[m
[32m+[m[32m                hideLoading(uploadLoading);[m
[32m+[m[32m            }[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        async function loadPDFForPreview(file) {[m
[32m+[m[32m            try {[m
[32m+[m[32m                const arrayBuffer = await file.arrayBuffer();[m
[32m+[m[32m                pdfDoc = await pdfjsLib.getDocument({data: arrayBuffer}).promise;[m
[32m+[m[32m                totalPages = pdfDoc.numPages;[m
[32m+[m[32m                currentPage = 1;[m
[32m+[m[41m                [m
[32m+[m[32m                // Get actual PDF page dimensions from server[m
[32m+[m[32m                await getPDFDimensions();[m
[32m+[m[41m                [m
[32m+[m[32m                uploadArea.style.display = 'none';[m
[32m+[m[32m                pdfViewer.style.display = 'block';[m
[32m+[m[32m                pdfControls.style.display = 'flex';[m
[32m+[m[41m                [m
[32m+[m[32m                await renderPage(currentPage);[m
[32m+[m[32m                updatePageInfo();[m
[32m+[m[32m                variables = [];[m
[32m+[m[32m                updateVariablesList();[m
[32m+[m[32m                updateConfiguration();[m
[32m+[m[32m            } catch (error) {[m
[32m+[m[32m                showNotification('Error loading PDF preview: ' + error.message, 'error');[m
[32m+[m[32m            }[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        async function getPDFDimensions() {[m
[32m+[m[32m            try {[m
[32m+[m[32m                const response = await fetch('/api/pdf-info');[m
[32m+[m[32m                const result = await response.json();[m
[32m+[m[41m                [m
[32m+[m[32m                if (result.success) {[m
[32m+[m[32m                    // Store page dimensions for coordinate conversion[m
[32m+[m[32m                    result.pages.forEach(page => {[m
[32m+[m[32m                        pdfPageDimensions[page.page] = {[m
[32m+[m[32m                            width: page.width,[m
[32m+[m[32m                            height: page.height[m
[32m+[m[32m                        };[m
[32m+[m[32m                    });[m
[32m+[m[32m                } else {[m
[32m+[m[32m                    console.warn('Could not get PDF dimensions:', result.error);[m
[32m+[m[32m                    // Use default dimensions if we can't get actual ones[m
[32m+[m[32m                    for (let i = 1; i <= totalPages; i++) {[m
[32m+[m[32m                        pdfPageDimensions[i] = { width: 612, height: 792 }; // US Letter[m
[32m+[m[32m                    }[m
[32m+[m[32m                }[m
[32m+[m[32m            } catch (error) {[m
[32m+[m[32m                console.warn('Error getting PDF dimensions:', error);[m
[32m+[m[32m                // Use default dimensions[m
[32m+[m[32m                for (let i = 1; i <= totalPages; i++) {[m
[32m+[m[32m                    pdfPageDimensions[i] = { width: 612, height: 792 };[m
[32m+[m[32m                }[m
[32m+[m[32m            }[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        async function renderPage(pageNum) {[m
[32m+[m[32m            try {[m
[32m+[m[32m                const page = await pdfDoc.getPage(pageNum);[m
[32m+[m[32m                const viewport = page.getViewport({scale: scale});[m
[32m+[m[41m                [m
[32m+[m[32m                pdfCanvas.width = viewport.width;[m
[32m+[m[32m                pdfCanvas.height = viewport.height;[m
[32m+[m[41m                [m
[32m+[m[32m                const renderContext = {[m
[32m+[m[32m                    canvasContext: pdfCtx,[m
[32m+[m[32m                    viewport: viewport[m
[32m+[m[32m                };[m
[32m+[m[41m                [m
[32m+[m[32m                await page.render(renderContext).promise;[m
[32m+[m[32m                renderTextOverlays();[m
[32m+[m[32m            } catch (error) {[m
[32m+[m[32m                console.error('Error rendering page:', error);[m
[32m+[m[32m            }[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        function renderTextOverlays() {[m
[32m+[m[32m            const existingOverlays = pdfViewer.querySelectorAll('.text-overlay');[m
[32m+[m[32m            existingOverlays.forEach(overlay => overlay.remove());[m
[32m+[m
[32m+[m[32m            const currentPageVars = variables.filter(v => v.page === currentPage);[m
[32m+[m[32m            currentPageVars.forEach(variable => {[m
[32m+[m[32m                // Convert PDF coordinates back to canvas coordinates for display[m
[32m+[m[32m                const canvasCoords = pdfToCanvasCoordinates(variable.x, variable.y, currentPage);[m
[32m+[m[41m                [m
[32m+[m[32m                const overlay = document.createElement('div');[m
[32m+[m[32m                overlay.className = 'text-overlay';[m
[32m+[m[32m                overlay.textContent = `${variable.name} (${variable.x}, ${variable.y})`;[m
[32m+[m[32m                overlay.style.left = canvasCoords.x + 'px';[m
[32m+[m[32m                overlay.style.top = canvasCoords.y + 'px';[m
[32m+[m[32m                pdfViewer.appendChild(overlay);[m
[32m+[m[32m            });[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        function changePage(direction) {[m
[32m+[m[32m            const newPage = currentPage + direction;[m
[32m+[m[32m            if (newPage >= 1 && newPage <= totalPages) {[m
[32m+[m[32m                currentPage = newPage;[m
[32m+[m[32m                renderPage(currentPage);[m
[32m+[m[32m                updatePageInfo();[m
[32m+[m[32m                renderTextOverlays();[m
[32m+[m[32m            }[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        function updatePageInfo() {[m
[32m+[m[32m            pageInfo.textContent = `Page ${currentPage} of ${totalPages}`;[m
[32m+[m[32m            prevPageBtn.disabled = currentPage <= 1;[m
[32m+[m[32m            nextPageBtn.disabled = currentPage >= totalPages;[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        function handleCanvasClick(e) {[m
[32m+[m[32m            const rect = pdfCanvas.getBoundingClientRect();[m
[32m+[m[32m            const canvasX = Math.round(e.clientX - rect.left);[m
[32m+[m[32m            const canvasY = Math.round(e.clientY - rect.top);[m
[32m+[m[41m            [m
[32m+[m[32m            // Convert canvas coordinates to PDF coordinates[m
[32m+[m[32m            const pdfCoords = canvasToPDFCoordinates(canvasX, canvasY, currentPage);[m
[32m+[m[41m            [m
[32m+[m[32m            addVariableAtPosition(pdfCoords.x, pdfCoords.y, currentPage);[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        function canvasToPDFCoordinates(canvasX, canvasY, pageNum) {[m
[32m+[m[32m            // Get the current page dimensions[m
[32m+[m[32m            const page = pdfDoc.getPage(pageNum);[m
[32m+[m[41m            [m
[32m+[m[32m            // Get actual PDF page dimensions[m
[32m+[m[32m            const pdfPageDim = pdfPageDimensions[pageNum] || { width: 612, height: 792 };[m
[32m+[m[41m            [m
[32m+[m[32m            // Calculate the scale factors[m
[32m+[m[32m            const scaleX = pdfPageDim.width / pdfCanvas.width;[m
[32m+[m[32m            const scaleY = pdfPageDim.height / pdfCanvas.height;[m
[32m+[m[41m            [m
[32m+[m[32m            // Convert canvas coordinates to PDF coordinates[m
[32m+[m[32m            const pdfX = Math.round(canvasX * scaleX);[m
[32m+[m[32m            // PDF coordinate system has origin at bottom-left, canvas at top-left[m
[32m+[m[32m            const pdfY = Math.round(pdfPageDim.height - (canvasY * scaleY));[m
[32m+[m[41m            [m
[32m+[m[32m            return { x: pdfX, y: pdfY };[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        function pdfToCanvasCoordinates(pdfX, pdfY, pageNum) {[m
[32m+[m[32m            // Convert PDF coordinates back to canvas coordinates for overlay display[m
[32m+[m[32m            const pdfPageDim = pdfPageDimensions[pageNum] || { width: 612, height: 792 };[m
[32m+[m[41m            [m
[32m+[m[32m            const scaleX = pdfCanvas.width / pdfPageDim.width;[m
[32m+[m[32m            const scaleY = pdfCanvas.height / pdfPageDim.height;[m
[32m+[m[41m            [m
[32m+[m[32m            const canvasX = Math.round(pdfX * scaleX);[m
[32m+[m[32m            const canvasY = Math.round((pdfPageDim.height - pdfY) * scaleY);[m
[32m+[m[41m            [m
[32m+[m[32m            return { x: canvasX, y: canvasY };[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        function addVariableAtPosition(x, y, page) {[m
[32m+[m[32m            const variableName = `var_${variables.length + 1}`;[m
[32m+[m[32m            const variable = {[m
[32m+[m[32m                name: variableName,[m
[32m+[m[32m                x: x,[m
[32m+[m[32m                y: y,[m
[32m+[m[32m                page: page,[m
[32m+[m[32m                fontSize: 12[m
[32m+[m[32m            };[m
[32m+[m[41m            [m
[32m+[m[32m            variables.push(variable);[m
[32m+[m[32m            updateVariablesList();[m
[32m+[m[32m            updateConfiguration();[m
[32m+[m[32m            renderTextOverlays();[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        function addVariable() {[m
[32m+[m[32m            // Get center coordinates of current page in PDF coordinate system[m
[32m+[m[32m            const pdfPageDim = pdfPageDimensions[currentPage] || { width: 612, height: 792 };[m
[32m+[m[32m            const centerX = Math.round(pdfPageDim.width / 2);[m
[32m+[m[32m            const centerY = Math.round(pdfPageDim.height / 2);[m
[32m+[m[41m            [m
[32m+[m[32m            const variable = {[m
[32m+[m[32m                name: `var_${variables.length + 1}`,[m
[32m+[m[32m                x: centerX,[m
[32m+[m[32m                y: centerY,[m
[32m+[m[32m                page: currentPage,[m
[32m+[m[32m                fontSize: 12[m
[32m+[m[32m            };[m
[32m+[m[41m            [m
[32m+[m[32m            variables.push(variable);[m
[32m+[m[32m            updateVariablesList();[m
[32m+[m[32m            updateConfiguration();[m
[32m+[m[32m            renderTextOverlays();[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        function removeVariable(index) {[m
[32m+[m[32m            variables.splice(index, 1);[m
[32m+[m[32m            updateVariablesList();[m
[32m+[m[32m            updateConfiguration();[m
[32m+[m[32m            renderTextOverlays();[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        function updateVariable(index, field, value) {[m
[32m+[m[32m            if (variables[index]) {[m
[32m+[m[32m                variables[index][field] = field === 'fontSize' || field === 'x' || field === 'y' || field === 'page' ?[m[41m [m
[32m+[m[32m                    parseInt(value) || 0 : value;[m
[32m+[m[32m                updateConfiguration();[m
[32m+[m[32m                if (field === 'x' || field === 'y' || field === 'page') {[m
[32m+[m[32m                    renderTextOverlays();[m
[32m+[m[32m                }[m
[32m+[m[32m            }[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        function updateVariablesList() {[m
[32m+[m[32m            variablesList.innerHTML = '';[m
[32m+[m[41m            [m
[32m+[m[32m            variables.forEach((variable, index) => {[m
[32m+[m[32m                const div = document.createElement('div');[m
[32m+[m[32m                div.className = 'variable-item';[m
[32m+[m[32m                div.innerHTML = `[m
[32m+[m[32m                    <div class="variable-header">[m
[32m+[m[32m                        <strong>Variable ${index + 1}</strong>[m
[32m+[m[32m                        <button class="remove-btn" onclick="removeVariable(${index})">Remove</button>[m
[32m+[m[32m                    </div>[m
[32m+[m[32m                    <div class="form-group">[m
[32m+[m[32m                        <label>Variable Name:</label>[m
[32m+[m[32m                        <input type="text" class="form-control" value="${variable.name}"[m[41m [m
[32m+[m[32m                               onchange="updateVariable(${index}, 'name', this.value)">[m
[32m+[m[32m                    </div>[m
[32m+[m[32m                    <div class="coordinate-display">[m
[32m+[m[32m                        Display Page: ${variable.page} → Config Page: ${variable.page - 1} (0-based)[m
[32m+[m[32m                        <br>PDF Coords: X: ${variable.x} | Y: ${variable.y}[m
[32m+[m[32m                        <br><small style="color: #6c757d;">pdf_text_overlay uses 0-based page numbering</small>[m
[32m+[m[32m                    </div>[m
[32m+[m[32m                    <div class="form-group">[m
[32m+[m[32m                        <label>Page Number:</label>[m
[32m+[m[32m                        <input type="number" class="form-control" value="${variable.page}" min="1" max="${totalPages || 999}"[m
[32m+[m[32m                               onchange="updateVariable(${index}, 'page', this.value)">[m
[32m+[m[32m                    </div>[m
[32m+[m[32m                    <div style="display: flex; gap: 10px;">[m
[32m+[m[32m                        <div class="form-group" style="flex: 1;">[m
[32m+[m[32m                            <label>X Coordinate:</label>[m
[32m+[m[32m                            <input type="number" class="form-control" value="${variable.x}"[m
[32m+[m[32m                                   onchange="updateVariable(${index}, 'x', this.value)">[m
[32m+[m[32m                        </div>[m
[32m+[m[32m                        <div class="form-group" style="flex: 1;">[m
[32m+[m[32m                            <label>Y Coordinate:</label>[m
[32m+[m[32m                            <input type="number" class="form-control" value="${variable.y}"[m
[32m+[m[32m                                   onchange="updateVariable(${index}, 'y', this.value)">[m
[32m+[m[32m                        </div>[m
[32m+[m[32m                    </div>[m
[32m+[m[32m                    <div class="form-group">[m
[32m+[m[32m                        <label>Font Size:</label>[m
[32m+[m[32m                        <input type="number" class="form-control" value="${variable.fontSize}" min="6" max="72"[m
[32m+[m[32m                               onchange="updateVariable(${index}, 'fontSize', this.value)">[m
[32m+[m[32m                    </div>[m
[32m+[m[32m                `;[m
[32m+[m[32m                variablesList.appendChild(div);[m
[32m+[m[32m            });[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        function updateConfiguration() {[m
[32m+[m[32m            if (variables.length === 0) {[m
[32m+[m[32m                configOutput.textContent = 'Click on the PDF to start adding variables...';[m
[32m+[m[32m                return;[m
[32m+[m[32m            }[m
[32m+[m
[32m+[m[32m            const pageGroups = {};[m
[32m+[m[32m            variables.forEach(variable => {[m
[32m+[m[32m                // Convert 1-based display page to 0-based page for pdf_text_overlay[m
[32m+[m[32m                const zeroBasedPage = variable.page - 1;[m
[32m+[m[32m                if (!pageGroups[zeroBasedPage]) {[m
[32m+[m[32m                    pageGroups[zeroBasedPage] = [];[m
[32m+[m[32m                }[m
[32m+[m[32m                pageGroups[zeroBasedPage].push({[m
[32m+[m[32m                    name: variable.name,[m
[32m+[m[32m                    "x-coordinate": variable.x,[m
[32m+[m[32m                    "y-coordinate": variable.y,[m
[32m+[m[32m                    font_size: variable.fontSize[m
[32m+[m[32m                });[m
[32m+[m[32m            });[m
[32m+[m
[32m+[m[32m            const configuration = Object.keys(pageGroups).map(page => ({[m
[32m+[m[32m                page_number: parseInt(page), // This will be 0-based[m
[32m+[m[32m                variables: pageGroups[page][m
[32m+[m[32m            }));[m
[32m+[m
[32m+[m[32m            configOutput.textContent = JSON.stringify(configuration, null, 2);[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        function copyConfiguration() {[m
[32m+[m[32m            if (configOutput.textContent && configOutput.textContent !== 'Click on the PDF to start adding variables...') {[m
[32m+[m[32m                navigator.clipboard.writeText(configOutput.textContent).then(() => {[m
[32m+[m[32m                    showNotification('Configuration copied to clipboard!');[m
[32m+[m[32m                });[m
[32m+[m[32m            }[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        function saveConfiguration() {[m
[32m+[m[32m            if (variables.length === 0) {[m
[32m+[m[32m                showNotification('No configuration to save', 'error');[m
[32m+[m[32m                return;[m
[32m+[m[32m            }[m
[32m+[m
[32m+[m[32m            const configName = prompt('Enter configuration name:', `config_${new Date().toISOString().slice(0,19).replace(/:/g, '-')}`);[m
[32m+[m[32m            if (!configName) return;[m
[32m+[m
[32m+[m[32m            const pageGroups = {};[m
[32m+[m[32m            variables.forEach(variable => {[m
[32m+[m[32m                // Convert 1-based display page to 0-based page for pdf_text_overlay[m
[32m+[m[32m                const zeroBasedPage = variable.page - 1;[m
[32m+[m[32m                if (!pageGroups[zeroBasedPage]) {[m
[32m+[m[32m                    pageGroups[zeroBasedPage] = [];[m
[32m+[m[32m                }[m
[32m+[m[32m                pageGroups[zeroBasedPage].push({[m
[32m+[m[32m                    name: variable.name,[m
[32m+[m[32m                    "x-coordinate": variable.x,[m
[32m+[m[32m                    "y-coordinate": variable.y,[m
[32m+[m[32m                    font_size: variable.fontSize[m
[32m+[m[32m                });[m
[32m+[m[32m            });[m
[32m+[m
[32m+[m[32m            const configuration = Object.keys(pageGroups).map(page => ({[m
[32m+[m[32m                page_number: parseInt(page), // This will be 0-based[m
[32m+[m[32m                variables: pageGroups[page][m
[32m+[m[32m            }));[m
[32m+[m
[32m+[m[32m            fetch('/api/save-config', {[m
[32m+[m[32m                method: 'POST',[m
[32m+[m[32m                headers: {[m
[32m+[m[32m                    'Content-Type': 'application/json',[m
[32m+[m[32m                },[m
[32m+[m[32m                body: JSON.stringify({[m
[32m+[m[32m                    name: configName,[m
[32m+[m[32m                    configuration: configuration[m
[32m+[m[32m                })[m
[32m+[m[32m            })[m
[32m+[m[32m            .then(response => response.json())[m
[32m+[m[32m            .then(result => {[m
[32m+[m[32m                if (result.success) {[m
[32m+[m[32m                    showNotification(result.message);[m
[32m+[m[32m                } else {[m
[32m+[m[32m                    showNotification(result.error, 'error');[m
[32m+[m[32m                }[m
[32m+[m[32m            })[m
[32m+[m[32m            .catch(error => {[m
[32m+[m[32m                showNotification('Failed to save configuration: ' + error.message, 'error');[m
[32m+[m[32m            });[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        function prefillSampleData() {[m
[32m+[m[32m            const variableNames = variables.map(v => v.name);[m
[32m+[m[32m            if (variableNames.length === 0) {[m
[32m+[m[32m                showNotification('Please add some variables first by clicking on the PDF.', 'error');[m
[32m+[m[32m                return;[m
[32m+[m[32m            }[m
[32m+[m
[32m+[m[32m            const sampleObj = {};[m
[32m+[m[32m            variableNames.forEach(name => {[m
[32m+[m[32m                if (name.toLowerCase().includes('name')) {[m
[32m+[m[32m                    sampleObj[name] = 'John Doe';[m
[32m+[m[32m                } else if (name.toLowerCase().includes('email')) {[m
[32m+[m[32m                    sampleObj[name] = 'john.doe@example.com';[m
[32m+[m[32m                } else if (name.toLowerCase().includes('date')) {[m
[32m+[m[32m                    sampleObj[name] = new Date().toISOString().split('T')[0];[m
[32m+[m[32m                } else if (name.toLowerCase().includes('phone')) {[m
[32m+[m[32m                    sampleObj[name] = '+1-234-567-8900';[m
[32m+[m[32m                } else if (name.toLowerCase().includes('address')) {[m
[32m+[m[32m                    sampleObj[name] = '123 Main St, City, State 12345';[m
[32m+[m[32m                } else if (name.toLowerCase().includes('company')) {[m
[32m+[m[32m                    sampleObj[name] = 'Example Company Inc.';[m
[32m+[m[32m                } else {[m
[32m+[m[32m                    sampleObj[name] = `Sample ${name}`;[m
[32m+[m[32m                }[m
[32m+[m[32m            });[m
[32m+[m
[32m+[m[32m            sampleData.value = JSON.stringify(sampleObj, null, 2);[m
[32m+[m[32m            showNotification('Sample data generated based on variable names!');[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        async function processDocument() {[m
[32m+[m[32m            if (!pdfUploaded) {[m
[32m+[m[32m                showNotification('Please upload a PDF first', 'error');[m
[32m+[m[32m                return;[m
[32m+[m[32m            }[m
[32m+[m
[32m+[m[32m            if (variables.length === 0) {[m
[32m+[m[32m                showNotification('Please add some variables first', 'error');[m
[32m+[m[32m                return;[m
[32m+[m[32m            }[m
[32m+[m
[32m+[m[32m            let parsedSampleData;[m
[32m+[m[32m            try {[m
[32m+[m[32m                parsedSampleData = JSON.parse(sampleData.value || '{}');[m
[32m+[m[32m            } catch (error) {[m
[32m+[m[32m                showNotification('Invalid JSON in sample data', 'error');[m
[32m+[m[32m                return;[m
[32m+[m[32m            }[m
[32m+[m
[32m+[m[32m            showLoading(processLoading);[m
[32m+[m[32m            processBtn.disabled = true;[m
[32m+[m
[32m+[m[32m            const pageGroups = {};[m
[32m+[m[32m            variables.forEach(variable => {[m
[32m+[m[32m                // Convert 1-based display page to 0-based page for pdf_text_overlay[m
[32m+[m[32m                const zeroBasedPage = variable.page - 1;[m
[32m+[m[32m                if (!pageGroups[zeroBasedPage]) {[m
[32m+[m[32m                    pageGroups[zeroBasedPage] = [];[m
[32m+[m[32m                }[m
[32m+[m[32m                pageGroups[zeroBasedPage].push({[m
[32m+[m[32m                    name: variable.name,[m
[32m+[m[32m                    "x-coordinate": variable.x,[m
[32m+[m[32m                    "y-coordinate": variable.y,[m
[32m+[m[32m                    font_size: variable.fontSize[m
[32m+[m[32m                });[m
[32m+[m[32m            });[m
[32m+[m
[32m+[m[32m            const configuration = Object.keys(pageGroups).map(page => ({[m
[32m+[m[32m                page_number: parseInt(page), // This will be 0-based[m
[32m+[m[32m                variables: pageGroups[page][m
[32m+[m[32m            }));[m
[32m+[m
[32m+[m[32m            try {[m
[32m+[m[32m                const response = await fetch('/api/process', {[m
[32m+[m[32m                    method: 'POST',[m
[32m+[m[32m                    headers: {[m
[32m+[m[32m                        'Content-Type': 'application/json',[m
[32m+[m[32m                    },[m
[32m+[m[32m                    body: JSON.stringify({[m
[32m+[m[32m                        configuration: configuration,[m
[32m+[m[32m                        sample_data: parsedSampleData[m
[32m+[m[32m                    })[m
[32m+[m[32m                });[m
[32m+[m
[32m+[m[32m                const result = await response.json();[m
[32m+[m
[32m+[m[32m                if (result.success) {[m
[32m+[m[32m                    showNotification('PDF processed successfully!');[m
[32m+[m[32m                    processedFilename = result.output_filename;[m
[32m+[m[32m                    downloadSection.style.display = 'block';[m
[32m+[m[32m                } else {[m
[32m+[m[32m                    showNotification(result.error, 'error');[m
[32m+[m[32m                }[m
[32m+[m[32m            } catch (error) {[m
[32m+[m[32m                showNotification('Processing failed: ' + error.message, 'error');[m
[32m+[m[32m            } finally {[m
[32m+[m[32m                hideLoading(processLoading);[m
[32m+[m[32m                processBtn.disabled = false;[m
[32m+[m[32m            }[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        function downloadProcessedPDF() {[m
[32m+[m[32m            if (!processedFilename) {[m
[32m+[m[32m                showNotification('No processed file available', 'error');[m
[32m+[m[32m                return;[m
[32m+[m[32m            }[m
[32m+[m
[32m+[m[32m            window.open(`/api/download/${processedFilename}`, '_blank');[m
[32m+[m[32m        }[m
[32m+[m
[32m+[m[32m        // Initialize with sample data[m
[32m+[m[32m        sampleData.value = `{[m
[32m+[m[32m  "name": "John Doe",[m
[32m+[m[32m  "email": "john.doe@example.com",[m
[32m+[m[32m  "date": "2024-01-15",[m
[32m+[m[32m  "company": "Example Corp",[m
[32m+[m[32m  "position": "Software Engineer"[m
[32m+[m[32m}`;[m
[32m+[m[32m    </script>[m
[32m+[m[32m</body>[m
[32m+[m[32m</html>[m
\ No newline at end of file[m
[1mdiff --git a/uploads/f725f5f1-4ac2-4a42-bb44-f7f74eb9003f_NRIOnline.pdf.pdf b/uploads/f725f5f1-4ac2-4a42-bb44-f7f74eb9003f_NRIOnline.pdf.pdf[m
[1mnew file mode 100644[m
[1mindex 0000000..faaec9f[m
Binary files /dev/null and b/uploads/f725f5f1-4ac2-4a42-bb44-f7f74eb9003f_NRIOnline.pdf.pdf differ
