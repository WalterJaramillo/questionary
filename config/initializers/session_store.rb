Rails.application.config.session_store :cookie_store,
  key: '_questionary_session',
  expire_after: 2.hours,
  secure: false,
  same_site: :lax
