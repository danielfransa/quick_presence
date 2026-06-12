class AttendanceAnswer < ApplicationRecord
  belongs_to :attendance_response, inverse_of: :attendance_answers
  belongs_to :attendance_field, inverse_of: :attendance_answers

  validates :attendance_field_id, uniqueness: { scope: :attendance_response_id }
  validate :required_field_must_have_value

  private

  def required_field_must_have_value
    return unless attendance_field&.required?

    errors.add(:value, :blank) if value.blank?
  end
end
