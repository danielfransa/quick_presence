class AttendanceResponse < ApplicationRecord
  belongs_to :attendance_list

  has_many :attendance_answers, dependent: :destroy, inverse_of: :attendance_response

  accepts_nested_attributes_for :attendance_answers

  before_validation :set_submitted_at, on: :create

  validates :submitted_at, presence: true
  validate :attendance_list_must_be_open

  private

  def set_submitted_at
    self.submitted_at ||= Time.current
  end

  def attendance_list_must_be_open
    return if attendance_list&.open?

    errors.add(:base, :closed)
  end
end
