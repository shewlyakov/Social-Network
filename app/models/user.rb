class User < ApplicationRecord
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i

  attr_accessor :remember_token, :activation_token

  has_secure_password

  before_save :downcase_email
  before_save { self.email = email.downcase }
  before_create :create_activation_digest

  validates :name, presence: true, length: { maximum: 50 }
  validates :email, presence: true, length: { maximum: 255 }, format: { with: VALID_EMAIL_REGEX },
             uniqueness: { case_sensitive:false }
  validates :password, presence: true, length: { minimum: 6 }, allow_nil: true

  def User.digest(string) # Returns the hash digest of the given string.
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST : BCrypt::Engine.cost
    BCrypt::Password.create(string, cost: cost)
  end

  def User.new_token # Returns a random token.
    SecureRandom.urlsafe_base64
  end

  def remember # Remembers a user in the database for use in persistent sessions.
    self.remember_token = User.new_token
    update_attribute(:remember_digest, User.digest(remember_token))
  end

  def authenticated?(attribute, token)  #Returns true if the given token matches the digest.
    digest = send("#{attribute}_digest")
    return false if digest.nil?
    BCrypt::Password.new(digest).is_password?(token)
  end

  def forget # Forgets a user.
    update_attribute(:remember_digest, nil)
  end

  def activate # Activates an account.
    update_columns(activated: true, activated_at: Time.zone.now)
  end

  def send_activation_email # Sends activation email.
    UserMailer.account_activation(self).deliver_now
  end

  private

  def downcase_email # Converts email to all lower-case.
    self.email = email.downcase
  end

  def create_activation_digest # Creates and assigns the activation token and digest.
    self.activation_token = User.new_token
    self.activation_digest = User.digest(activation_token)
  end
end
