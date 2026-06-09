require "zip"

class AttendanceListXlsx
  CONTENT_TYPE = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"

  def initialize(rows)
    @rows = rows
  end

  def render
    Zip::OutputStream.write_buffer do |zip|
      write_entry(zip, "[Content_Types].xml", content_types_xml)
      write_entry(zip, "_rels/.rels", root_relationships_xml)
      write_entry(zip, "xl/workbook.xml", workbook_xml)
      write_entry(zip, "xl/_rels/workbook.xml.rels", workbook_relationships_xml)
      write_entry(zip, "xl/styles.xml", styles_xml)
      write_entry(zip, "xl/worksheets/sheet1.xml", worksheet_xml)
    end.string
  end

  private

  def write_entry(zip, path, contents)
    zip.put_next_entry(path)
    zip.write(contents)
  end

  def worksheet_xml
    builder = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
      xml.worksheet(xmlns: "http://schemas.openxmlformats.org/spreadsheetml/2006/main") do
        xml.sheetViews do
          xml.sheetView(workbookViewId: 0) do
            xml.pane(ySplit: 1, topLeftCell: "A2", activePane: "bottomLeft", state: "frozen")
          end
        end
        xml.cols do
          column_widths.each_with_index do |width, index|
            xml.col(min: index + 1, max: index + 1, width: width, customWidth: 1)
          end
        end
        xml.sheetData do
          @rows.each_with_index do |row, row_index|
            xml.row(r: row_index + 1) do
              row.each_with_index do |value, column_index|
                attributes = {
                  r: "#{column_name(column_index + 1)}#{row_index + 1}",
                  t: "inlineStr"
                }
                attributes[:s] = 1 if row_index.zero?

                xml.c(attributes) do
                  xml.is { xml.t(value.to_s, "xml:space": "preserve") }
                end
              end
            end
          end
        end
        xml.autoFilter(ref: "A1:#{column_name(@rows.first.length)}#{@rows.length}")
      end
    end

    builder.to_xml
  end

  def column_widths
    @rows.transpose.map do |column|
      [ column.map { |value| value.to_s.length }.max + 2, 50 ].min
    end
  end

  def column_name(number)
    name = +""

    while number.positive?
      number, remainder = (number - 1).divmod(26)
      name.prepend((65 + remainder).chr)
    end

    name
  end

  def content_types_xml
    <<~XML
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
        <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
        <Default Extension="xml" ContentType="application/xml"/>
        <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
        <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
        <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
      </Types>
    XML
  end

  def root_relationships_xml
    <<~XML
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
        <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
      </Relationships>
    XML
  end

  def workbook_xml
    <<~XML
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
        <sheets>
          <sheet name="Responses" sheetId="1" r:id="rId1"/>
        </sheets>
      </workbook>
    XML
  end

  def workbook_relationships_xml
    <<~XML
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
        <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
        <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
      </Relationships>
    XML
  end

  def styles_xml
    <<~XML
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
        <fonts count="2">
          <font><sz val="11"/><name val="Calibri"/></font>
          <font><b/><color rgb="FFFFFFFF"/><sz val="11"/><name val="Calibri"/></font>
        </fonts>
        <fills count="3">
          <fill><patternFill patternType="none"/></fill>
          <fill><patternFill patternType="gray125"/></fill>
          <fill><patternFill patternType="solid"><fgColor rgb="FF0D6EFD"/><bgColor indexed="64"/></patternFill></fill>
        </fills>
        <borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>
        <cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
        <cellXfs count="2">
          <xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>
          <xf numFmtId="0" fontId="1" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1"/>
        </cellXfs>
        <cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>
      </styleSheet>
    XML
  end
end
