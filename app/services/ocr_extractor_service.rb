require "rtesseract"
require "pdf/reader"
require "mini_magick"

class OcrExtractorService
  def initialize(file_path)
    @file_path = file_path.to_s
    @file_extension = File.extname(@file_path).downcase
  end

  def extract
    case @file_extension
    when ".pdf"
      extract_from_pdf
    when '.jpg', '.jpeg', '.png', '.tiff', '.bmp'
      extract_from_image
    else
      "Unsupported file format: #{@file_extension}"
    end
  end

  private

  def extract_from_pdf
    # Try to extract text directly from PDF first (for text-based PDFs)
    text = extract_text_from_pdf

    # If no text found, it might be a scanned PDF - use OCR
    if text.strip.empty?
      text = extract_from_scanned_pdf
    end

    text
  end

  def extract_text_from_pdf
    reader = PDF::Reader.new(@file_path)
    text = ""

    reader.pages.each do |page|
      text += page.text
    end

    text
  rescue => e
    Rails.logger.error "Error extracting text from PDF: #{e.message}"
    ""
  end

  def extract_from_scanned_pdf
    # Convert PDF pages to images and run OCR on each
    text = ""

    # Convert first page for now (can extend to all pages)
    image_path = convert_pdf_to_image(@file_path)

    if image_path
      text = RTesseract.new(image_path).to_s
      File.delete(image_path) if File.exist?(image_path)
    end

    text
  rescue => e
    Rails.logger.error "Error extracting from scanned PDF: #{e.message}"
    "Error: #{e.message}"
  end

  def extract_from_image
    # Use Tesseract OCR directly on the image
    RTesseract.new(@file_path).to_s
  rescue => e
    Rails.logger.error "Error extracting from image: #{e.message}"
    "Error: #{e.message}"
  end

  def convert_pdf_to_image(pdf_path)
    # Convert first page of PDF to image using MiniMagick
    output_path = pdf_path.sub(".pdf", "_page1.png")

    image = MiniMagick::Image.open(pdf_path)
    image.format "png"
    image.write output_path

    output_path
  rescue => e
    Rails.logger.error "Error converting PDF to image: #{e.message}"
    nil
  end
end
