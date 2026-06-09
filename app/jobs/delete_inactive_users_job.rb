class DeleteInactiveUsersJob < ApplicationJob
  queue_as :default

  def perform
    User.inactive_for_deletion.find_each do |user|
      user.with_lock do
        user.destroy! if user.inactive_for_deletion?
      end
    end
  end
end
