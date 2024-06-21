module Klaviyo
  module Base
    attr_reader :user

    CUSTOM_PROPERTIES = ['All News',
                         'All Fairs',
                         'UK fairs',
                         'EU fairs',
                         'North American fairs',
                         'US Wine Club',
                         'UK Wine Shop']
    CUSTOM_CATEGORY = { wine_lover: 'Wine Lover',
                        industry_trade: 'Industry / Trade',
                        grower_maker: 'Grower / Maker',
                        press: 'Press',
                        importer_distributor: 'Importer / Distributor' }
    KLAVIYO_SUCCESS_RESPONSE = { status: :success, message: Spree.t(:subscribed, scope: :klaviyo) }
    KLAVIYO_FAILURE_RESPONSE = { status: :error, message: Spree.t(:failed, scope: :klaviyo) }

    def fetch_profile(profile_id)
      response = Klaviyo::Profiles.get_person_attributes(profile_id)

      if response.status == 200
        KLAVIYO_SUCCESS_RESPONSE.merge({ data: JSON.parse(response.body) })
      else
        capture_error_message('KLAVIYO: fetch_profile', response.body, "profile_id: #{profile_id}")
      end
    end

    def update_email_preferences(id, user_email_preferences)
      response = Klaviyo::Profiles.update_person_attributes(id, user_email_preferences)

      if response.status == 200
        { status: :success, message: Spree.t(:successfully_updated, scope: :klaviyo) }
      else
        KLAVIYO_FAILURE_RESPONSE
      end
    end

    def profile_id_by_email(email)
      response = Klaviyo::Profiles.get_profile_id_by_email(email)

      if response.status == 200
        KLAVIYO_SUCCESS_RESPONSE.merge(id: JSON.parse(response.body)['id'])
      else
        KLAVIYO_FAILURE_RESPONSE
      end
    end

    def user_details(email, rawwine_user)
      {
        email: email,
        rawwine_user: rawwine_user
      }
    end

    def custom_properties
      properties = {}

      CUSTOM_PROPERTIES.each do |property|
        properties[property] = user.newsletter.to_s
      end

      properties
    end

    def category
      {
        category: user_klaviyo_category
      }
    end

    def user_klaviyo_category
      vendor = user.vendors.first

      profile = vendor.present? ? vendor.profilable.class.name : ''
      case profile
      when 'Spree::Producer'
        'Grower / Maker'
      when 'Spree::Merchant'
        'Importer / Distributor'
      when 'Spree::Shop'
        'Industry / Trade'
      else
        'Wine Lover'
      end
    end

    def capture_error_message(_action, _error_message, _option)
      KLAVIYO_FAILURE_RESPONSE
    end
  end
end
