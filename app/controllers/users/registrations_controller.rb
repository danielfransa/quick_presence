module Users
  class RegistrationsController < Devise::RegistrationsController
    protected

    def after_sign_out_path_for(_resource_or_scope)
      account_deleted_path
    end
  end
end
