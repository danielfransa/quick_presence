class PurgeExpiredAttendanceResponsesJob < ApplicationJob
  queue_as :default

  def perform
    AttendanceResponsesPurger.call(AttendanceList.responses_retention_expired)
  end
end
