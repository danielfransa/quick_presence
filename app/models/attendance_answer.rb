class AttendanceAnswer < ApplicationRecord
  belongs_to :attendance_response, inverse_of: :attendance_answers
  belongs_to :attendance_field

  validates :attendance_field_id, uniqueness: { scope: :attendance_response_id }
  validate :required_field_must_have_value

  private

  def required_field_must_have_value
    return unless attendance_field&.required?

    errors.add(:value, "can't be blank") if value.blank?
  end
end
