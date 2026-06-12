class AttendanceResponsesPurger
  def self.call(attendance_lists)
    new(attendance_lists).call
  end

  def initialize(attendance_lists)
    @attendance_lists = attendance_lists
  end

  def call
    deleted_count = responses.count
    return 0 if deleted_count.zero?

    AttendanceList.transaction do
      AttendanceAnswer.where(attendance_response_id: responses.select(:id)).delete_all
      responses.delete_all
      attendance_lists.update_all(attendance_responses_count: 0)
    end

    deleted_count
  end

  private

  attr_reader :attendance_lists

  def responses
    @responses ||= AttendanceResponse.where(
      attendance_list_id: attendance_lists.select(:id)
    )
  end
end
