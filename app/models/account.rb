require 'digest/sha1'

class Account < ActiveRecord::Base
  include Authentication
  include Authentication::ByPassword
  include Authentication::ByCookieToken
  include Authorization::AasmRoles

  DEFAULT_PHOTO_URL = '/images/avatar-missing.png'

  validates_presence_of     :login
  validates_length_of       :login,    :within => 3..40
  validates_uniqueness_of   :login
  validates_format_of       :login,    :with => Authentication.login_regex, :message => Authentication.bad_login_message

  validates_format_of       :name,     :with => Authentication.name_regex,  :message => Authentication.bad_name_message, :allow_nil => true
  validates_length_of       :name,     :maximum => 100

  validates_presence_of     :email
  validates_length_of       :email,    :within => 6..100 #r@a.wk
  validates_uniqueness_of   :email
  validates_format_of       :email,    :with => Authentication.email_regex, :message => Authentication.bad_email_message

  has_one :user

  has_attachment :content_type => :image, 
                 :storage => :file_system,
                 :resize_to => '100x100>',
                 :path_prefix => 'public/images/accounts'

  cattr_accessor :current_account, :session_token

  # HACK HACK HACK -- how to do attr_accessible from here?
  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :login, :email, :name, :password, :password_confirmation, :uploaded_data, :session_token
  
  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  #
  # uff.  this is really an authorization, not authentication routine.  
  # We really need a Dispatch Chain here or something.
  # This will also let us return a human error message.
  #
  def self.authenticate(login, password)
    return nil if login.blank? || password.blank?
    u = find_in_state :first, :active, :conditions => {:login => login} # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end
  
  def session_token
    Account.session_token
  end

  def login=(value)
    write_attribute :login, (value ? value.downcase : nil)
  end

  def email=(value)
    write_attribute :email, (value ? value.downcase : nil)
  end
  
  def photo_url
    begin
      public_filename
    rescue
      DEFAULT_PHOTO_URL
    end
  end
  
  protected
    
    def make_activation_code
        self.deleted_at = nil
        self.activation_code = self.class.make_token
    end


end
