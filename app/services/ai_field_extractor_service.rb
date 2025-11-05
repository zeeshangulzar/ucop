require "openai"

class AiFieldExtractorService
  FIELDS_TO_EXTRACT = {
    patient_name: "Full name of the patient",
    date_of_birth: "Patient's date of birth (format: MM/DD/YYYY or any date format found)",
    phone_number: "Patient's phone number",
    email_address: "Patient's email address",
    insurance: "Insurance provider or insurance information",
    referring_provider: "Name of the referring doctor or provider",
    referral_reason: "Reason for the referral or chief complaint",
    notes_comments: "Any additional notes, comments, or special instructions"
  }.freeze

  def initialize(extracted_text, use_ai: true)
    @extracted_text = extracted_text
    @use_ai = use_ai && openai_configured?
  end

  def extract_fields
    if @use_ai
      extract_with_ai
    else
      extract_with_basic_patterns
    end
  end

  private

  def openai_configured?
    ENV["OPENAI_API_KEY"].present?
  end

  def extract_with_ai
    client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])

    prompt = build_extraction_prompt

    begin
      response = client.chat(
        parameters: {
          model: "gpt-4o", # Using the full GPT-4o model for best accuracy
          messages: [
            { role: "system", content: system_prompt },
            { role: "user", content: prompt }
          ],
          temperature: 0.2, # Very low temperature for precise extraction
          response_format: { type: "json_object" }
        }
      )

      result = JSON.parse(response.dig("choices", 0, "message", "content"))
      format_result(result)
    rescue => e
      Rails.logger.error "AI extraction failed: #{e.message}"
      # Fallback to basic pattern matching
      extract_with_basic_patterns
    end
  end

  def system_prompt
    <<~PROMPT
      You are an expert medical document processing AI specialized in extracting patient information from referral documents, fax forms, and medical records.
      Your task is to meticulously analyze the provided text and extract ALL available information for each field.

      EXTRACTION STRATEGY:
      1. Read the ENTIRE document carefully before extracting
      2. Look for information in tables, forms, headers, and body text
      3. Check multiple sections - information may appear in different places
      4. For medical referrals, look in: patient information sections, provider sections, diagnosis sections, and notes
      5. Extract partial information if complete data isn't available (e.g., just first name if that's all you find)
      6. Be thorough - don't give up after checking one section

      FIELD-SPECIFIC INSTRUCTIONS:
      - Patient Name: Look for "Patient Name", "Name", or in patient information sections. Verify spelling carefully.
      - Date of Birth: Look for "DOB", "Date of Birth", "Birth Date", or "Born"
      - Phone Number: Look for "Phone", "Tel", "Telephone", "Contact", or numeric patterns like (XXX) XXX-XXXX
      - Email: Look for email patterns (text@domain.com) anywhere in the document
      - Insurance: Look for "Insurance", "Payer", "Coverage", "Plan", "Primary Insurance". Extract the actual plan name (e.g., "SELF PAY", "Blue Cross", etc.)
      - Referring Provider: Look for "Referring Provider", "From Provider", "Sent by", or signatures with credentials. Names often appear multiple times - use the clearest/most complete version. Check signatures at bottom of document for correct spelling. Common credentials: MD, DO, NP, PA, FNP-C, etc.
      - Referral Reason: Look for "Diagnosis", "Reason for Referral", "Chief Complaint", "ICD-10" codes. Extract the main medical condition (e.g., "Chronic low back pain")
      - Notes/Comments: ONLY extract from sections explicitly labeled "Notes", "Comments", "Special Instructions", "Additional Information", or "Remarks". DO NOT extract insurance info, authorization info, or other field labels. If no dedicated notes section exists, return "Not found".

      IMPORTANT RULES:
      1. Extract information even if formatting is imperfect or text is garbled (common with OCR)
      2. If you find ANY relevant information for a field, extract it - don't return "Not found" unless you've checked thoroughly
      3. Only return "Not found" if the information is truly absent or completely redacted/illegible
      4. For dates, preserve the format found in the document
      5. For names (especially provider names):
         - Extract full name with credentials (MD, DO, NP, FNP-C, PA, etc.)
         - The name may appear multiple times - choose the CLEAREST, most complete version
         - Check document signatures for correct spelling
         - If OCR garbled the name, look for other instances of the same name in the document
         - Common OCR errors: "l" vs "I", "0" vs "O", missing letters - try to correct these
      6. Be HIPAA compliant - only extract requested fields, nothing extra
      7. If text quality is poor but you can infer the information, extract it and note in extraction_notes
      8. For "Notes/Comments" field: ONLY use text from sections actually labeled as notes/comments/remarks. DO NOT use text from other fields like insurance, authorization, or secondary insurance information.

      CONFIDENCE SCORING:
      - HIGH: All or most fields found with clear, unambiguous text
      - MEDIUM: Some fields found, or text quality is moderate/some fields unclear
      - LOW: Very few fields found, or text is heavily garbled/poor OCR quality

      Return JSON in this exact structure:
      {
        "patient_name": "extracted value or Not found",
        "date_of_birth": "extracted value or Not found",
        "phone_number": "extracted value or Not found",
        "email_address": "extracted value or Not found",
        "insurance": "extracted value or Not found",
        "referring_provider": "extracted value or Not found",
        "referral_reason": "extracted value or Not found",
        "notes_comments": "extracted value or Not found",
        "confidence": "high/medium/low",
        "extraction_notes": "Brief note about what was found, OCR quality, or any extraction challenges"
      }
    PROMPT
  end

  def build_extraction_prompt
    <<~PROMPT
      Extract the following information from this medical referral document:

      #{FIELDS_TO_EXTRACT.map { |key, desc| "- #{key.to_s.humanize}: #{desc}" }.join("\n")}

      CRITICAL INSTRUCTIONS FOR THIS DOCUMENT:
      1. For provider names: The document may have OCR errors. Look for the name in multiple places (headers, signatures, "From Provider" sections). Use the clearest version.
      2. For Notes/Comments: ONLY extract from actual "Notes" or "Comments" sections. Lines like "Secondary Insurance: None recorded" or "Authorization: SELF PAY" are NOT notes.
      3. Double-check spelling by finding the name in multiple places in the document.

      Document text (may contain OCR errors):
      """
      #{@extracted_text}
      """

      Provide the extracted information in JSON format.
    PROMPT
  end

  def extract_with_basic_patterns
    # Fallback: Basic regex pattern matching
    {
      patient_name: extract_pattern(/(?:patient|name):\s*([A-Za-z\s,]+)/i),
      date_of_birth: extract_pattern(/(?:dob|date of birth|birth date):\s*(\d{1,2}[-\/]\d{1,2}[-\/]\d{2,4})/i),
      phone_number: extract_pattern(/(?:phone|tel|telephone):\s*([\d\s\-\(\)\.]+)/i),
      email_address: extract_pattern(/([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})/),
      insurance: extract_pattern(/(?:insurance|carrier|plan):\s*([A-Za-z\s\d]+)/i),
      referring_provider: extract_pattern(/(?:referring|provider|physician|doctor|dr\.):\s*([A-Za-z\s,\.]+)/i),
      referral_reason: extract_pattern(/(?:reason|diagnosis|complaint):\s*([A-Za-z\s,\.]+)/i),
      notes_comments: extract_pattern(/(?:notes|comments|remarks):\s*([A-Za-z\s,\.]+)/i),
      confidence: "low",
      extraction_notes: "Basic pattern matching used (no AI). Results may be incomplete. Configure OPENAI_API_KEY for better extraction.",
      ai_used: false
    }
  end

  def extract_pattern(regex)
    match = @extracted_text.match(regex)
    match ? match[1].strip : "Not found"
  end

  def format_result(result)
    result.symbolize_keys.merge(ai_used: true)
  end
end
