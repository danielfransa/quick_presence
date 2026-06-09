class User < ApplicationRecord
  INACTIVITY_PERIOD = 120.days

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :rememberable

  has_many :attendance_lists, dependent: :destroy

  USERNAME_FORMAT = /\A[a-zA-Z0-9_]+\z/

  attr_accessor :inactivity_terms_accepted

  before_validation :normalize_username
  before_create :record_inactivity_terms_acceptance
  before_create :set_initial_last_login_at

  scope :inactive_for_deletion, -> { where(last_login_at: ..INACTIVITY_PERIOD.ago) }

  validates :username,
    presence: true,
    uniqueness: { case_sensitive: false },
    length: { in: 3..32 },
    format: { with: USERNAME_FORMAT, message: "can only contain letters, numbers, and underscores" }

  validates :password,
    presence: true,
    confirmation: true,
    length: { in: Devise.password_length },
    if: :password_required?

  validates :password_confirmation, presence: true, if: :password_required?
  validates :inactivity_terms_accepted, acceptance: { allow_nil: false }, on: :create

  def inactive_for_deletion?
    last_login_at <= INACTIVITY_PERIOD.ago
  end

  def email_required?
    false
  end

  def email_changed?
    false
  end

  private

  def password_required?
    new_record? || password.present? || password_confirmation.present?
  end

  def normalize_username
    self.username = username.to_s.strip.downcase if username.present?
  end

  def record_inactivity_terms_acceptance
    self.inactivity_terms_accepted_at = Time.current
  end

  def set_initial_last_login_at
    self.last_login_at = Time.current
  end
end
