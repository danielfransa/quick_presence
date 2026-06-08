class AttendanceListQrCodePdf
  PRIVACY_NOTICE = "The submitted data belongs to the attendance list creator and will not be used outside this context."

  def initialize(attendance_list, public_url)
    @attendance_list = attendance_list
    @public_url = public_url
  end

  def render
    Prawn::Document.new(page_size: "A4", page_layout: :portrait, margin: 54) do |pdf|
      draw_header(pdf)
      draw_qr_code(pdf)
      draw_footer(pdf)
    end.render
  end

  private

  attr_reader :attendance_list, :public_url

  def draw_header(pdf)
    pdf.text attendance_list.title, align: :center, size: 28, style: :bold

    return if attendance_list.description.blank?

    pdf.move_down 14
    pdf.text attendance_list.description, align: :center, size: 14, color: "444444"
  end

  def draw_qr_code(pdf)
    pdf.move_down 28

    qr_svg = RQRCode::QRCode.new(public_url).as_svg(
      color: "000",
      shape_rendering: "crispEdges",
      module_size: 8,
      standalone: true,
      use_path: true
    )

    qr_size = 300
    x_position = (pdf.bounds.width - qr_size) / 2

    pdf.svg qr_svg,
      at: [ x_position, pdf.cursor ],
      width: qr_size,
      height: qr_size,
      enable_web_requests: false
  end

  def draw_footer(pdf)
    pdf.bounding_box([ 0, 58 ], width: pdf.bounds.width, height: 58) do
      pdf.stroke_horizontal_rule
      pdf.move_down 12
      pdf.text PRIVACY_NOTICE, align: :center, size: 10, color: "555555"
    end
  end
end
