# Medical Referral AI Smart Intake System

## Overview
This application provides AI-powered OCR extraction for medical referral documents including PDFs, JPGs, PNGs, and email referrals. Built for HIPAA compliance and audit-ready processing.

## Features

### Phase 1: OCR Text Extraction ✅ COMPLETE
- **Upload Support**: PDF, JPG, PNG, TIFF files
- **Text-based PDF**: Direct text extraction from digital PDFs
- **Scanned PDF**: OCR processing for scanned/image-based PDFs
- **Image OCR**: Tesseract OCR for image files
- **Real-time Display**: View extracted text immediately

### Phase 2: AI Smart Field Extraction 🚧 UPCOMING
Automatically extract structured data:
- Patient Name
- Date of Birth (DOB)
- Phone Number
- Email Address
- Insurance Information
- Referring Provider
- Referral Reason
- Notes/Comments

## Technology Stack

### Ruby Gems
- `rtesseract` - Ruby wrapper for Tesseract OCR
- `pdf-reader` - Text extraction from PDFs
- `mini_magick` - Image processing for OCR
- `image_processing` - Image manipulation utilities

### System Dependencies
- **Tesseract OCR** 5.5.1 - Text recognition engine
- **ImageMagick** 7.1.2-8 - Image processing
- **Ghostscript** 10.06.0 - PDF/PostScript support

## Installation

### 1. Install System Dependencies (macOS)
```bash
brew install tesseract imagemagick ghostscript
```

### 2. Install Ruby Dependencies
```bash
bundle install
```

### 3. Setup Database
```bash
rails db:create
rails db:migrate
```

## Running the Application

### Start the Server
```bash
bin/rails server
```

Visit: **http://localhost:3000**

## Usage

### Testing OCR Extraction

1. **Open the Application**: Navigate to http://localhost:3000
2. **Upload a Document**: 
   - Click "Choose File"
   - Select a PDF, JPG, PNG, or TIFF file
   - Try the example files: `Example Athena Provider Referral 1_1_.pdf` or `Example Google Contact Form Email (1).pdf`
3. **Extract Data**: Click "Extract Data with OCR"
4. **View Results**: See extracted text and file information

### Example Files
The project includes sample medical referral PDFs:
- `Example Athena Provider Referral 1_1_.pdf` - Provider referral form
- `Example Google Contact Form Email (1).pdf` - Email referral

## Architecture

### File Structure
```
app/
├── controllers/
│   └── referrals_controller.rb      # Upload & extraction logic
├── services/
│   └── ocr_extractor_service.rb     # OCR processing engine
└── views/
    └── referrals/
        ├── index.html.erb           # Upload form
        └── results.html.erb         # Extraction results
```

### Service Layer

**OcrExtractorService** handles multiple extraction methods:

1. **Text-based PDFs**: Direct text extraction using `pdf-reader`
2. **Scanned PDFs**: Converts to images, then OCR with Tesseract
3. **Image Files**: Direct Tesseract OCR processing

### Routes
```
GET  /                    # Upload form
POST /referrals/extract   # Process file and show results
```

## Development

### File Processing Flow
1. User uploads file via form
2. File saved temporarily in `tmp/uploads/`
3. `OcrExtractorService` processes based on file type:
   - PDF → Try text extraction first, fall back to OCR
   - Image → Direct OCR processing
4. Results displayed on results page
5. Temporary file cleaned up

### Security Considerations (HIPAA)
- Files are processed in memory/temp storage only
- No database persistence in Phase 1
- Temporary files deleted after processing
- Ready for audit logging implementation

## Phase 2 Implementation Plan

### AI Integration Options
1. **OpenAI GPT-4** - Structured data extraction
2. **AWS Textract** - Medical document analysis
3. **Google Document AI** - Healthcare form parsing

### Smart Extraction Features
- Pattern recognition for medical data
- Validation of extracted fields
- Confidence scoring
- Manual override/correction interface
- Audit trail logging

## Testing

### Manual Testing Steps
1. Test with text-based PDF (should extract instantly)
2. Test with scanned PDF (should use OCR)
3. Test with image files (JPG, PNG)
4. Test with various document layouts
5. Verify special characters and formatting

### Expected Behavior
- Text PDFs: Fast extraction (< 1 second)
- Scanned PDFs: OCR processing (2-5 seconds)
- Images: OCR processing (1-3 seconds)
- Large files: May take longer based on page count

## Troubleshooting

### "tesseract not found"
```bash
brew install tesseract
```

### "convert: not authorized"
ImageMagick PDF security - edit `/etc/ImageMagick-7/policy.xml`:
```xml
<policy domain="coder" rights="read|write" pattern="PDF" />
```

### Poor OCR Quality
- Ensure source document is high quality
- Try preprocessing images (contrast, brightness)
- Consider using Tesseract language data files

## Next Steps

1. ✅ Complete Phase 1: OCR extraction
2. ⏳ Add AI service integration (OpenAI/AWS/Google)
3. ⏳ Implement structured field extraction
4. ⏳ Add database persistence
5. ⏳ Create audit logging
6. ⏳ Add authentication/authorization
7. ⏳ HIPAA compliance hardening

## License
Private Project - Medical Data Processing

## Support
For questions or issues, contact the development team.
