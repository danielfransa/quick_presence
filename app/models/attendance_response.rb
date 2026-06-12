class AttendanceResponse < ApplicationRecord
  belongs_to :attendance_list, counter_cache: true, inverse_of: :attendance_responses

  has_many :attendance_answers, dependent: :destroy, inverse_of: :attendance_response

  before_validation :set_submitted_at, on: :create

  validates :submitted_at, presence: true
  validate :attendance_list_must_be_open

  scope :chronological, -> { order(:submitted_at, :id) }
  scope :reverse_chronological, -> { order(submitted_at: :desc, id: :desc) }
  scope :with_answers, -> { includes(:attendance_answers) }

  private

  def set_submitted_at
    self.submitted_at ||= Time.current
  end

  def attendance_list_must_be_open
    return if attendance_list&.open?

    errors.add(:base, :closed)
  end
end
