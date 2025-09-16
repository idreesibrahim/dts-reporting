class Users::SessionsController < Devise::SessionsController
  def new
    IdiCaptcha::Captcha.generate(session)
    super
  end

  def create
    unless IdiCaptcha::Captcha.valid?(session, params[:captcha])
      flash.now[:alert] = "Invalid CAPTCHA"
      self.resource = resource_class.new(sign_in_params)
      IdiCaptcha::Captcha.generate(session) ## Regenerate captcha
      respond_with_navigational(resource) { render :new }
      return
    end

    super do
      session[:modal_shown] = true
    end
  end

  def destroy
    session.delete(:modal_shown)
    super
  end
end
