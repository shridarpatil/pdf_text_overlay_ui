# Enhanced PDF Text Overlay Tool Documentation

## 📋 Table of Contents

1. [Overview](#overview)
2. [Features](#features)
3. [Installation](#installation)
4. [Quick Start Guide](#quick-start-guide)
5. [User Interface](#user-interface)
6. [Text Variables](#text-variables)
7. [Image Overlays](#image-overlays)
8. [Shape Drawing](#shape-drawing)
9. [Configuration Format](#configuration-format)
10. [API Reference](#api-reference)
11. [Troubleshooting](#troubleshooting)
12. [Advanced Usage](#advanced-usage)

---

## Overview

The Enhanced PDF Text Overlay Tool is a web-based application that allows you to dynamically add text, images, and shapes to PDF documents. Built with Flask and modern web technologies, it provides an intuitive interface for creating professional PDF overlays with pixel-perfect positioning.

### Key Capabilities
- **Text Overlays**: Add dynamic text with conditional positioning
- **Image Overlays**: Insert images from URLs or uploaded files
- **Shape Drawing**: Draw rectangles, circles, and lines
- **Interactive Positioning**: Click-to-place elements with visual feedback
- **Real-time Preview**: See overlays on the PDF as you configure them
- **JSON Configuration**: Export/import configurations for reuse

---

## Features

### ✨ **Core Features**
- 📝 **Dynamic Text Variables** with conditional positioning
- 🖼️ **Image Overlays** with size and position control
- 🔲 **Shape Drawing** (rectangles, circles, lines)
- 🎯 **Interactive Placement** via click-to-position
- 📋 **Configuration Management** (save/load/export)
- 🔄 **Real-time Preview** with visual overlays

### 🎨 **Advanced Features**
- **Conditional Text**: Different text/positions based on data values
- **Two-point Line Drawing**: Interactive start/end point selection
- **Session Management**: Secure file handling per user session
- **Multiple File Formats**: Support for PNG, JPG, GIF, BMP images
- **Coordinate System**: Automatic PDF point to inch conversion
- **Error Handling**: Comprehensive validation and debugging tools

---

## Installation

### Prerequisites
- Python 3.8+
- Flask
- pdf_text_overlay library
- PyPDF2 (optional, for accurate PDF dimensions)

### Setup Instructions

1. **Clone/Download the Application**
   ```bash
   git clone <repository-url>
   cd pdf-text-overlay-tool
   ```

2. **Install Dependencies**
   ```bash
   pip install flask werkzeug pdf_text_overlay PyPDF2
   ```

3. **Create Required Directories**
   ```bash
   mkdir uploads outputs fonts images
   ```

4. **Run the Application**
   ```bash
   python app.py
   ```

5. **Access the Interface**
   - Open browser to `http://localhost:5000`
   - The application will automatically create necessary folders

### Optional: Add Custom Fonts
- Place TTF font files in the `fonts/` directory
- Rename your preferred font to `default.ttf` for automatic use

---

## Quick Start Guide

### 🚀 **5-Minute Tutorial**

#### Step 1: Upload Your PDF
1. Click the upload area or drag & drop a PDF file
2. Wait for the preview to load
3. Navigate between pages using the arrow buttons

#### Step 2: Add Text Variables
1. Select **📝 Text** mode
2. Click anywhere on the PDF to place a text variable
3. Configure the variable name and properties in the right panel
4. Repeat for all text positions needed

#### Step 3: Add Images (Optional)
1. Select **🖼️ Images** mode  
2. Upload images using the upload area
3. Click on the PDF to place images
4. Enter a variable name (e.g., "logo", "signature")
5. Adjust size and position as needed

#### Step 4: Add Shapes (Optional)
1. Select **🔲 Shapes** mode
2. Click on the PDF and choose shape type
3. For lines: click start point, then end point
4. Customize colors, fill, and stroke width

#### Step 5: Configure Sample Data
1. Review the generated JSON configuration
2. Click **✨ Prefill Data Based on Config**
3. Modify the sample data with your actual values
4. Ensure image variables have valid URLs

#### Step 6: Process and Download
1. Click **🚀 Process PDF with All Overlays**
2. Wait for processing to complete
3. Click **💾 Download Processed PDF**

---

## User Interface

### 📖 **PDF Preview Section**
- **Upload Area**: Drag & drop or click to upload PDFs
- **Page Navigation**: Previous/Next buttons with page indicator
- **Canvas Overlay**: Visual representation of placed elements
- **Mode Instructions**: Dynamic help text based on current mode

### ⚙️ **Configuration Section**

#### 🎯 **Editing Mode Selector**
- **📝 Text Mode**: Place text variables by clicking
- **🖼️ Image Mode**: Place image overlays by clicking  
- **🔲 Shape Mode**: Draw shapes by clicking

#### 📝 **Sample Data Panel**
- JSON editor for variable values
- Auto-prefill based on configuration
- Real-time validation

#### 🎯 **Text Variables Panel**
- List of all text variables
- Individual configuration for each variable
- Support for simple and conditional variables

#### 🖼️ **Image Overlays Panel**
- List of placed images
- Size and position controls
- Reference to uploaded files

#### 🔲 **Shape Overlays Panel**
- List of drawn shapes
- Color, size, and style controls
- Line endpoint management

#### 📋 **Generated Configuration**
- Live JSON configuration
- Copy, save, and load functions
- Manual editing capability

---

## Text Variables

### Simple Text Variables
Basic text replacement at fixed positions.

**Configuration Example:**
```json
{
  "name": "customer_name",
  "x-coordinate": 150,
  "y-coordinate": 200,
  "font_size": 12
}
```

**Sample Data:**
```json
{
  "customer_name": "John Doe"
}
```

### Conditional Text Variables
Different text/positions based on data values.

**Configuration Example:**
```json
{
  "name": "gender",
  "conditional_coordinates": [
    {
      "if_value": "Male",
      "print_pattern": "✓",
      "x-coordinate": 100,
      "y-coordinate": 150
    },
    {
      "if_value": "Female", 
      "print_pattern": "✓",
      "x-coordinate": 200,
      "y-coordinate": 150
    }
  ]
}
```

**Sample Data:**
```json
{
  "gender": "Male"
}
```

### Variable Properties
- **name**: Unique identifier for the variable
- **x-coordinate**: Horizontal position in PDF points
- **y-coordinate**: Vertical position in PDF points (bottom-left origin)
- **font_size**: Text size (6-72 points)
- **if_value**: Condition value for conditional variables
- **print_pattern**: Text to display when condition matches

### Adding Variables
1. **Click Placement**: Select Text mode and click on PDF
2. **Manual Addition**: Use "+ Add Variable" button
3. **Configuration Import**: Load from saved JSON configuration

---

## Image Overlays

### Image Variable Format
Images are configured as variables with special image properties.

**Configuration Example:**
```json
{
  "name": "company_logo",
  "image": {
    "x-coordinate": 460,
    "y-coordinate": 190,
    "width": 100,
    "height": 50
  }
}
```

**Sample Data:**
```json
{
  "company_logo": "https://example.com/logo.png"
}
```

### Image Workflow
1. **Upload Images**: Use the image upload area in Image mode
2. **Place on PDF**: Click where you want the image positioned
3. **Variable Naming**: Enter a descriptive variable name
4. **Sample Data**: Add the image URL to sample data
5. **Size Adjustment**: Configure width and height in the panel

### Supported Formats
- PNG (recommended for logos/graphics)
- JPEG (good for photos)
- GIF (basic support)
- BMP (basic support)

### Image Properties
- **name**: Variable name to reference in sample data
- **x-coordinate**: Left edge position in PDF points
- **y-coordinate**: Bottom edge position in PDF points
- **width**: Image width in PDF points
- **height**: Image height in PDF points

### Image URLs
- **Uploaded Images**: Automatically generates URLs like `/api/image/filename.png`
- **External URLs**: Use any publicly accessible image URL
- **Local Development**: Use `http://localhost:5000/api/image/filename.png`

---

## Shape Drawing

### Supported Shapes
- **Rectangle**: Defined by position, width, and height
- **Circle**: Defined by center position and radius
- **Line**: Defined by start and end coordinates

### Shape Configuration Format
All shapes are converted to `draw_shape` variables.

**Rectangle Example:**
```json
{
  "name": "draw_shape",
  "draw_shape": {
    "r": 0.0,
    "g": 0.0, 
    "b": 1.0,
    "shape": "Rectangle",
    "x0-coordinate": 1.0,
    "y0-coordinate": 2.0,
    "x1-coordinate": 3.0,
    "y1-coordinate": 4.0
  }
}
```

**Line Example:**
```json
{
  "name": "draw_shape",
  "draw_shape": {
    "r": 1.0,
    "g": 0.0,
    "b": 0.0,
    "shape": "Line",
    "x0-coordinate": 1.0,
    "y0-coordinate": 2.0,
    "x1-coordinate": 4.0,
    "y1-coordinate": 3.0
  }
}
```

### Shape Properties
- **r, g, b**: RGB color values (0.0-1.0)
- **shape**: Shape type ("Rectangle", "Circle", "Line")
- **x0-coordinate, y0-coordinate**: Start/center position in inches
- **x1-coordinate, y1-coordinate**: End/corner position in inches

### Interactive Line Drawing
1. Select Shape mode
2. Choose "Line (two-point)" from the dialog
3. Click for start point (red indicator appears)
4. Click for end point (line is created)
5. Use "❌ Cancel Line Drawing" to abort

### Shape Styling
- **Color**: Visual color picker
- **Fill**: Solid fill vs outline only (not available for lines)
- **Stroke Width**: Line thickness (1-10 points)

---

## Configuration Format

### Page-Based Structure
Configurations are organized by page (0-based indexing).

```json
[
  {
    "page_number": 0,
    "variables": [
      // Text variables
      {
        "name": "customer_name",
        "x-coordinate": 150,
        "y-coordinate": 200,
        "font_size": 12
      },
      // Image variables
      {
        "name": "logo",
        "image": {
          "x-coordinate": 460,
          "y-coordinate": 190,
          "width": 100,
          "height": 50
        }
      },
      // Shape variables
      {
        "name": "draw_shape",
        "draw_shape": {
          "r": 0.0,
          "g": 0.0,
          "b": 1.0,
          "shape": "Rectangle",
          "x0-coordinate": 1.0,
          "y0-coordinate": 2.0,
          "x1-coordinate": 3.0,
          "y1-coordinate": 4.0
        }
      }
    ]
  }
]
```

### Coordinate System
- **PDF Points**: Internal coordinate system (1 point = 1/72 inch)
- **Origin**: Bottom-left corner of the page
- **Conversion**: Frontend automatically converts canvas clicks to PDF coordinates
- **Inches**: Shapes use inch-based coordinates for the pdf_text_overlay library

### Page Numbering
- **Display**: Pages shown as 1, 2, 3, etc.
- **Configuration**: Pages stored as 0, 1, 2, etc. (0-based indexing)
- **Automatic Conversion**: Interface handles conversion automatically

---

## API Reference

### Core Endpoints

#### `POST /api/upload`
Upload a PDF file for processing.

**Request:**
- `multipart/form-data` with `pdf` field
- Maximum file size: 16MB

**Response:**
```json
{
  "success": true,
  "filename": "document.pdf",
  "message": "PDF uploaded successfully"
}
```

#### `POST /api/upload-image`
Upload images for use in overlays.

**Request:**
- `multipart/form-data` with `image` field
- Supported formats: PNG, JPG, GIF, BMP
- Maximum file size: 10MB

**Response:**
```json
{
  "success": true,
  "filename": "logo.png",
  "message": "Image uploaded successfully"
}
```

#### `GET /api/images`
List uploaded images for current session.

**Response:**
```json
{
  "success": true,
  "images": [
    {
      "filename": "logo.png",
      "upload_time": "2024-01-15T10:30:00",
      "url": "/api/image/logo.png"
    }
  ]
}
```

#### `GET /api/image/<filename>`
Serve uploaded images.

**Response:** Image file binary data

#### `POST /api/process`
Process PDF with overlays.

**Request:**
```json
{
  "configuration": [/* configuration array */],
  "sample_data": {/* variable values */}
}
```

**Response:**
```json
{
  "success": true,
  "output_filename": "output_123_20240115_143000.pdf",
  "message": "PDF processed successfully"
}
```

#### `GET /api/download/<filename>`
Download processed PDF files.

**Response:** PDF file binary data

### Utility Endpoints

#### `GET /api/pdf-info`
Get PDF page dimensions and information.

**Response:**
```json
{
  "success": true,
  "total_pages": 3,
  "pages": [
    {
      "page": 1,
      "width": 612,
      "height": 792
    }
  ]
}
```

#### `POST /api/save-config`
Save configuration for later use.

**Request:**
```json
{
  "name": "my_config",
  "configuration": [/* configuration array */]
}
```

#### `GET /api/test-image/<filename>`
Test image accessibility (debugging).

**Response:**
```json
{
  "filename": "logo.png",
  "exists": true,
  "expected_path": "/path/to/image"
}
```

---

## Troubleshooting

### Common Issues

#### 🚫 **PDF Upload Fails**
**Symptoms:** Error message on upload
**Solutions:**
- Check file size (max 16MB)
- Ensure file is a valid PDF
- Try a different PDF file
- Check browser console for errors

#### 🖼️ **Images Not Found (404 Error)**
**Symptoms:** "Image not found" or "Cannot open resource" errors
**Solutions:**
1. Click **🔄 Refresh Images** button
2. Re-upload images if necessary
3. Use **🔍 Test Images** to diagnose
4. Check that image URLs in sample data match uploaded files

#### 📍 **Incorrect Text Positioning**
**Symptoms:** Text appears in wrong location
**Solutions:**
- Click the center of target areas (checkboxes, text fields)
- Fine-tune coordinates by ±2-5 points in variable settings
- Remember PDF uses bottom-left origin coordinate system
- Check page dimensions with different PDF viewers

#### ⚙️ **Processing Fails**
**Symptoms:** Error during PDF generation
**Solutions:**
1. Validate JSON in sample data
2. Ensure all image URLs are accessible
3. Check that variable names match between config and data
4. Verify shape coordinates are reasonable values

#### 🔄 **Session Issues**
**Symptoms:** Previously uploaded images not found
**Solutions:**
- Use **🔄 Refresh Images** to reload current session
- Re-upload images if they've been lost
- Avoid opening multiple tabs simultaneously

### Debug Tools

#### 🔍 **Test Images Button**
- Click to verify image accessibility
- Check browser console for detailed results
- Shows expected vs actual file paths

#### 📋 **Configuration Validation**
- Copy configuration and validate JSON syntax
- Use online JSON validators if needed
- Check for missing commas or brackets

#### 🖥️ **Browser Console**
- Press F12 to open developer tools
- Check Console tab for JavaScript errors
- Look for network request failures

#### 📊 **Server Logs**
- Check terminal/console where Flask is running
- Look for file path information
- Check for processing errors and stack traces

### Error Messages

#### "No PDF uploaded"
Upload a PDF file first before trying to process.

#### "Invalid JSON in sample data"
Check sample data for proper JSON formatting.

#### "Image not found: filename.png"
The referenced image file cannot be accessed. Use refresh or re-upload.

#### "Cannot open resource http://..."
Image URL is not accessible. Check image upload and URL generation.

#### "Processing failed: unsupported operand type"
Usually indicates None values in shape coordinates. Check shape configuration.

---

## Advanced Usage

### Batch Processing
For processing multiple PDFs with the same configuration:

1. **Create Master Configuration**
   - Set up your template with one PDF
   - Export the configuration JSON
   - Save for reuse

2. **Process Multiple Files**
   - Upload each PDF individually
   - Load the saved configuration
   - Adjust sample data for each document
   - Process and download

### Custom Coordinate Systems
For precise positioning:

1. **Measure in PDF Viewer**
   - Use ruler tools in PDF applications
   - Note measurements in points or inches
   - Convert: 1 inch = 72 points

2. **Manual Coordinate Entry**
   - Bypass click-to-place by editing coordinates directly
   - Use coordinate display for reference
   - Test with small adjustments

### Integration with External Systems

#### API Integration
```python
import requests

# Upload PDF
with open('document.pdf', 'rb') as f:
    response = requests.post('http://localhost:5000/api/upload', 
                           files={'pdf': f})

# Process with configuration
config_data = {
    'configuration': [...],  # Your configuration
    'sample_data': {...}     # Your data
}
response = requests.post('http://localhost:5000/api/process', 
                        json=config_data)

# Download result
if response.json()['success']:
    filename = response.json()['output_filename']
    pdf_response = requests.get(f'http://localhost:5000/api/download/{filename}')
    with open('output.pdf', 'wb') as f:
        f.write(pdf_response.content)
```

### Performance Optimization

#### Large Files
- Keep PDFs under 16MB for best performance
- Use compressed/optimized PDFs when possible
- Process pages individually for very large documents

#### Many Variables
- Group related variables by page
- Use conditional variables to reduce total count
- Consider template-based approach for repeated layouts

#### Image Optimization
- Use appropriate image formats (PNG for graphics, JPEG for photos)
- Optimize image sizes before upload
- Keep images under 10MB each

### Security Considerations

#### Session Management
- Each user session is isolated
- Files are automatically prefixed with session IDs
- Sessions expire when browser is closed

#### File Storage
- Uploaded files are stored in session-specific folders
- Clean up old files periodically
- Consider implementing file expiration

#### Input Validation
- All file uploads are validated for type and size
- JSON configurations are parsed safely
- Coordinate values are bounded and validated

---

## Support and Contributing

### Getting Help
- Check this documentation first
- Use the built-in debugging tools
- Check browser console and server logs
- Create minimal test cases to isolate issues

### Reporting Issues
When reporting problems, include:
- Browser type and version
- PDF file characteristics (size, pages, format)
- Configuration JSON (if relevant)
- Error messages from console/logs
- Steps to reproduce

### Feature Requests
Consider contributing:
- New shape types
- Additional image formats
- Enhanced coordinate systems
- Batch processing improvements
- UI/UX enhancements

---

*Last updated: June 2025*
*Version: 2.0*
