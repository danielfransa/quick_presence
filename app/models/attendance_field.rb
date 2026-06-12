class AttendanceField < ApplicationRecord
  belongs_to :attendance_list, inverse_of: :attendance_fields
  has_many :attendance_answers, dependent: :destroy, inverse_of: :attendance_field

  FIELD_TYPES = %w[text].freeze

  validates :label, presence: true
  validates :field_type, presence: true, inclusion: { in: FIELD_TYPES }
  validates :position, numericality: { greater_than_or_equal_to: 0, only_integer: true }

  scope :ordered, -> { order(:position, :id) }
end
