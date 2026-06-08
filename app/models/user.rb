class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :rememberable

  has_many :attendance_lists, dependent: :destroy

  USERNAME_FORMAT = /\A[a-zA-Z0-9_]+\z/

  before_validation :normalize_username

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
end
