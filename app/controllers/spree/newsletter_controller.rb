module Spree
  class NewsletterController < StoreController
    skip_before_action :verify_authenticity_token,
                       only: [:subscribe, :create_profile, :update_profile, :unsubscribe, :suppress_profile]
    before_action :find_or_create_by_unsubscribe_user, only: [:unsubscribe, :update_profile, :suppress_profile]

    def subscribe
      email = params.fetch('email', '')

      NewsletterSubscribeJob.perform_later(email) if ENV['NEWSLETTER_JOB_ACTIVE']

      render js: "
        setTimeout(function () {
          document.getElementById('completed_newsletter').style.display = 'block';
        }, 300);
        document.getElementById('newsletter_user_email').innerHTML = '#{email}';

        document.getElementById('body_email').value='';
        document.getElementById('email').value='';
      "
    end

    def create_profile
      # email_validation_result = validate_email(params[:email])

      # if %w[valid unknown].include?(email_validation_result)
         @response = Klaviyo::Guest.new(params).sync

        if @response
          redirect_to newsletter_error_path
        else
          @error_message = 'Oops! Invalid email. Please provide a valid email address'
        end
    end

    def unsubscribe
    end

    def update_profile
      @update_response = if @k_unsubscribe_user.update(user_preferences_form: build_prefrences_params)
                           { message: Spree.t(:successfully_updated, scope: :klaviyo) }
                         else
                           { message: Spree.t(:failed, scope: :klaviyo) }
                         end
    end

    # suppressed profile from all mail on klaviyo
    def suppress_profile
      if @k_unsubscribe_user.update(suppressed_profile: true)
        @suppress_response = { message: Spree.t(:unsubscribed, scope: :klaviyo) }
      else
        redirect_to newsletter_error_path
      end
    end

    def error
      raise ActionController::RoutingError, 'Not Found'
    end

    private

    def build_prefrences_params
      preferences = {}

      @k_unsubscribe_user.user_preferences_form.keys.each do |preference|
        preferences[preference] = if params[:user_preferences_form]
                                    params[:user_preferences_form][preference] ? 'true' : 'false'
                                  else
                                    'false'
                                  end
      end

      preferences
    end

    def find_or_create_by_unsubscribe_user
      @k_unsubscribe_user = Spree::KlaviyoUnsubscribe.find_or_create_by(email: params[:email].gsub(' ', '+'))
    end

    def validate_email(email)
      client = QuickEmailVerification::Client.new(ENV['QUICKEMAIL_KEY'])
      quickemailverification = client.quickemailverification()
      response = if ENV['QUICKEMAIL_SANDBOX'] == 'true'
                   quickemailverification.sandbox(email)
                 else
                   quickemailverification.verify(email)
                 end
      response.body['result']
    end
  end
end
