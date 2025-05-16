class PdfGeneratorService
  def self.generate_certificate(inspection)
    require "prawn/table"

    Prawn::Document.new do |pdf|
      setup_pdf_fonts(pdf)
      generate_pdf_header(pdf, inspection)
      generate_pdf_equipment_details(pdf, inspection)
      generate_pdf_test_results(pdf, inspection)
      generate_pdf_comments(pdf, inspection) if inspection.comments.present?
      generate_pdf_qr_code(pdf, inspection)
      generate_pdf_footer(pdf)
    end
  end

  def self.setup_pdf_fonts(pdf)
    font_path = Rails.root.join("app", "assets", "fonts")
    pdf.font_families.update(
      "NotoSans" => {
        normal: "#{font_path}/NotoSans-Regular.ttf",
        bold: "#{font_path}/NotoSans-Bold.ttf",
        italic: "#{font_path}/NotoSans-Regular.ttf",
        bold_italic: "#{font_path}/NotoSans-Bold.ttf"
      },
      "NotoEmoji" => {
        normal: "#{font_path}/NotoEmoji-Regular.ttf"
      }
    )
    pdf.font "NotoSans"
  end

  def self.generate_pdf_header(pdf, inspection)
    pdf.text "Inspection Certificate", size: 20, style: :bold, align: :center
    pdf.move_down 20

    pdf.bounding_box([0, pdf.cursor], width: pdf.bounds.width, height: 50) do
      pdf.stroke_bounds
      pdf.move_down 5
      pdf.text "Serial Number: #{inspection.serial}", align: :center, size: 14
      pdf.move_down 2
      pdf.text (inspection.passed ? "PASSED" : "FAILED").to_s, align: :center, size: 14,
        style: :bold, color: inspection.passed ? "009900" : "CC0000"
    end
    pdf.move_down 20
  end

  def self.generate_pdf_equipment_details(pdf, inspection)
    pdf.text "Equipment Details", size: 14, style: :bold
    pdf.stroke_horizontal_rule
    pdf.move_down 10

    data = [
      ["Serial Number", inspection.serial],
      ["Manufacturer", inspection.manufacturer.presence || "Not specified"],
      ["Location", inspection.location]
    ]

    create_pdf_table(pdf, data)
    pdf.move_down 20
  end

  def self.generate_pdf_test_results(pdf, inspection)
    pdf.text "Inspection Results", size: 14, style: :bold
    pdf.stroke_horizontal_rule
    pdf.move_down 10

    results = [
      ["Inspection Date", inspection.inspection_date&.strftime("%d/%m/%Y")],
      ["Re-inspection Due", inspection.reinspection_date&.strftime("%d/%m/%Y")],
      ["Inspector", inspection.inspector],
      ["Overall Result", inspection.passed ? "PASS" : "FAIL"]
    ]

    create_pdf_table(pdf, results) do |table|
      table.row(results.length - 1).background_color = inspection.passed ? "CCFFCC" : "FFCCCC"
    end
  end

  def self.generate_pdf_comments(pdf, inspection)
    pdf.move_down 20
    pdf.text "Comments", size: 14, style: :bold
    pdf.stroke_horizontal_rule
    pdf.move_down 10
    pdf.text inspection.comments
  end


  def self.generate_pdf_qr_code(pdf, inspection)
    pdf.move_down 20
    pdf.text "Certificate Verification", size: 14, style: :bold
    pdf.stroke_horizontal_rule
    pdf.move_down 10

    # Generate QR code
    qr_code_png = QrCodeService.generate_qr_code(inspection)
    qr_code_temp_file = Tempfile.new(["qr_code", ".png"])

    begin
      qr_code_temp_file.binmode
      qr_code_temp_file.write(qr_code_png)
      qr_code_temp_file.close

      # Add QR code image and URL text
      pdf.image qr_code_temp_file.path, position: :center, width: 180
      pdf.move_down 5
      pdf.text "Scan to verify certificate or visit:", align: :center, size: 10
      pdf.text "#{ENV["BASE_URL"]}/c/#{inspection.id}",
        align: :center, size: 10, style: :italic
    ensure
      qr_code_temp_file.unlink
    end
  end

  def self.generate_pdf_footer(pdf)
    pdf.move_down 30
    pdf.text "This certificate was generated on #{Time.now.strftime("%d/%m/%Y at %H:%M")}",
      size: 10, align: :center, style: :italic
    pdf.text "Inspection Logger", size: 10, align: :center, style: :italic
  end

  def self.create_pdf_table(pdf, data)
    table = pdf.table(data, width: pdf.bounds.width) do |t|
      t.cells.borders = []
      t.cells.padding = [5, 10]
      t.columns(0).font_style = :bold
      t.columns(0).width = 150
      t.row(0..data.length - 1).background_color = "EEEEEE"
      t.row(0..data.length - 1).borders = [:bottom]
      t.row(0..data.length - 1).border_color = "DDDDDD"
    end

    yield table if block_given?
    table
  end
end
