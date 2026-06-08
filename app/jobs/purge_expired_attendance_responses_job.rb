class PurgeExpiredAttendanceResponsesJob < ApplicationJob
  queue_as :default

  def perform
    AttendanceList.responses_retention_expired.find_each do |attendance_list|
      attendance_list.purge_expired_responses!
    end
  end
end
