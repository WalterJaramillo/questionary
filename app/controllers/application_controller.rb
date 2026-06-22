class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  stale_when_importmap_changes

  def after_sign_in_path_for(resource)
    admin_dashboard_path
  end

  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end
end
