require "csv"

class AttendanceListExport
  def initialize(attendance_list)
    @attendance_list = attendance_list
  end

  def to_csv
    CSV.generate do |csv|
      rows.each { |row| csv << row }
    end
  end

  def to_xlsx
    AttendanceListXlsx.new(rows).render
  end

  private

  attr_reader :attendance_list

  def rows
    @rows ||= [ header ] + response_rows
  end

  def header
    [ translate("columns.number") ] +
      fields.map(&:label) +
      [ translate("columns.timestamp") ]
  end

  def response_rows
    responses.each_with_index.map do |response, index|
      answers_by_field_id = response.attendance_answers.index_by(&:attendance_field_id)

      [ index + 1 ] +
        fields.map { |field| answers_by_field_id[field.id]&.value } +
        [ response.submitted_at.strftime(translate("timestamp_format")) ]
    end
  end

  def fields
    @fields ||= attendance_list.attendance_fields.load
  end

  def responses
    @responses ||= attendance_list.attendance_responses.with_answers.chronological
  end

  def translate(key)
    I18n.t("exports.attendance_list.#{key}")
  end
end
