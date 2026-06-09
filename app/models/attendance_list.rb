class AttendanceList < ApplicationRecord
  RESPONSES_RETENTION_PERIOD = 48.hours

  belongs_to :user

  has_many :attendance_fields, -> { ordered }, dependent: :destroy, inverse_of: :attendance_list
  has_many :attendance_responses, dependent: :destroy

  accepts_nested_attributes_for :attendance_fields,
    allow_destroy: true,
    reject_if: ->(attributes) { attributes["label"].blank? }

  before_validation :set_default_time_zone
  before_validation :generate_public_token, on: :create

  validates :title, presence: true
  validates :ends_at, presence: true
  validates :time_zone, presence: true
  validates :public_token, presence: true, uniqueness: true
  validate :time_zone_must_be_supported
  validate :maximum_of_five_fields
  validate :ends_at_after_starts_at

  scope :responses_retention_expired, lambda {
    where.not(ends_at: nil).where(ends_at: ..RESPONSES_RETENTION_PERIOD.ago)
  }

  def starts_at_local
    format_local_datetime(starts_at)
  end

  def starts_at_local=(value)
    self.starts_at = parse_local_datetime(value)
  end

  def ends_at_local
    format_local_datetime(ends_at)
  end

  def ends_at_local=(value)
    self.ends_at = parse_local_datetime(value)
  end

  def local_time(datetime)
    return if datetime.blank?

    datetime.in_time_zone(time_zone)
  end

  def open?
    return false unless active?

    now = Time.current

    return false if starts_at.present? && now < starts_at
    return false if ends_at.present? && now > ends_at

    true
  end

  def closed?
    !open?
  end

  def not_started?
    active? && starts_at.present? && Time.current < starts_at
  end

  def expired?
    active? && ends_at.present? && Time.current > ends_at
  end

  def responses_retention_expires_at
    return if ends_at.blank?

    ends_at + RESPONSES_RETENTION_PERIOD
  end

  def responses_retention_expired?
    responses_retention_expires_at.present? && Time.current >= responses_retention_expires_at
  end

  def purge_expired_responses!
    return 0 unless responses_retention_expired?

    attendance_responses.destroy_all.size
  end

  private

  def set_default_time_zone
    self.time_zone = Time.zone.name if time_zone.blank?
  end

  def generate_public_token
    self.public_token ||= SecureRandom.urlsafe_base64(10)
  end

  def zone
    ActiveSupport::TimeZone[time_zone] || Time.zone
  end

  def time_zone_must_be_supported
    errors.add(:time_zone, :unsupported) if ActiveSupport::TimeZone[time_zone].blank?
  end

  def parse_local_datetime(value)
    return if value.blank?

    zone.parse(value)
  end

  def format_local_datetime(datetime)
    local_time(datetime)&.strftime("%Y-%m-%dT%H:%M")
  end

  def maximum_of_five_fields
    active_fields = attendance_fields.reject(&:marked_for_destruction?)

    errors.add(:attendance_fields, :too_many) if active_fields.size > 5
  end

  def ends_at_after_starts_at
    return if starts_at.blank? || ends_at.blank?

    errors.add(:ends_at, :before_start) if ends_at <= starts_at
  end
end
