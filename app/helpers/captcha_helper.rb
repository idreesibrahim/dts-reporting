# app/helpers/captcha_helper.rb
module CaptchaHelper
  def ensure_captcha_initialized
    IdiCaptcha::Captcha.generate(session) unless session[:captcha_question].present?
  end
end
