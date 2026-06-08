module QrCodeHelper
  def qr_code_svg(url)
    qrcode = RQRCode::QRCode.new(url)

    qrcode.as_svg(
      color: "000",
      shape_rendering: "crispEdges",
      module_size: 6,
      standalone: true,
      use_path: true
    ).html_safe
  end
end
