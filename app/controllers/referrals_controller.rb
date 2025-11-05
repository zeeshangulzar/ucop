class ReferralsController < ApplicationController
  def index
    # Upload form page
  end

  def extract
    # Handle file upload and extraction
    if params[:file].present?
      uploaded_file = params[:file]

      # Save the file temporarily
      temp_path = Rails.root.join("tmp", "uploads", uploaded_file.original_filename)
      FileUtils.mkdir_p(File.dirname(temp_path))
      File.binwrite(temp_path, uploaded_file.read)

      # Extract text using OCR service
      extractor = OcrExtractorService.new(temp_path)
      @extracted_text = extractor.extract
      @file_name = uploaded_file.original_filename
      @file_type = uploaded_file.content_type

      # Clean up temporary file
      File.delete(temp_path) if File.exist?(temp_path)

      render :results
    else
      flash[:error] = "Please select a file to upload"
      redirect_to referrals_path
    end
  rescue => e
    flash[:error] = "Error processing file: #{e.message}"
    redirect_to referrals_path
  end
end
