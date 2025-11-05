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
    when ".jpg", ".jpeg", ".png", ".tiff", ".bmp"
      extract_from_image
    else
      "Unsupported file format: #{@file_extension}"
    end
  end

  private

  def extract_text_from_pdf
    reader = PDF::Reader.new(@file_path)
    text = ""

    reader.pages.each_with_index do |page, index|
      text += "\n\n=== PAGE #{index + 1} ===\n\n" if reader.pages.length > 1
      text += page.text
    end

    text
  rescue => e
    Rails.logger.error "Error extracting text from PDF: #{e.message}"
    ""
  end

  def extract_from_pdf
    # Convert PDF pages to images and run OCR on each page
    text = ""

    begin
      # Get total number of pages
      pdf = MiniMagick::Image.open(@file_path)
      total_pages = pdf.pages.length

      Rails.logger.info "Processing #{total_pages} pages from PDF"

      # Process each page
      (0...total_pages).each do |page_num|
        Rails.logger.info "Extracting text from page #{page_num + 1}/#{total_pages}"

        image_path = convert_pdf_page_to_image(@file_path, page_num)

        if image_path
          page_text = RTesseract.new(image_path).to_s
          text += "\n\n=== PAGE #{page_num + 1} ===\n\n" + page_text
          File.delete(image_path) if File.exist?(image_path)
        end
      end
    rescue => e
      Rails.logger.error "Error processing PDF pages: #{e.message}"
      return "Error: #{e.message}"
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

  def convert_pdf_page_to_image(pdf_path, page_num = 0)
    # Convert specific page of PDF to image
    output_path = pdf_path.sub(".pdf", "_page#{page_num}.png")

    # Use system command for ImageMagick convert
    # Escape the path properly and specify the page
    input_spec = "#{pdf_path}[#{page_num}]"

    # Run ImageMagick convert command
    system("convert", "-density", "300", input_spec, output_path)

    if File.exist?(output_path)
      output_path
    else
      Rails.logger.error "Failed to create image for page #{page_num}"
      nil
    end
  rescue => e
    Rails.logger.error "Error converting PDF page #{page_num} to image: #{e.message}"
    nil
  end
end
