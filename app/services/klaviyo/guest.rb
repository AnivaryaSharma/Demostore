module Klaviyo
  class Guest
    include Klaviyo::Base

    attr_reader :params

    def initialize(params)
      @params = params
    end

    def sync
      debugger
      opts = {
        "header_params": {
          "Authorization": "Klaviyo-API-Key pk_5ef38656403996fcb8a53fb7015f8deba1"
        }
      }
      # begin
        response = KlaviyoAPI::ProfilesApi.new.create_profile(data, opts)
      # rescue KlaviyoAPI::ApiError => e
      #   puts "Profile Already exists #{e}"
      # end
      # if response.success?
      #   KLAVIYO_SUCCESS_RESPONSE.merge(email: params[:email])
      # else
      #   capture_error_message('KLAVIYO: guest::sync', response.body, "data: #{data}")
      # end
    end

    private

    def data
      defaults = {
        "data": {
          "type": "profile",
          "attributes": {
            "email": params[:email].gsub(' ', '+'),
            "properties":{}
          }
        }
      }


      defaults[:data][:attributes][:properties] = defaults[:data][:attributes][:properties].merge(custom_properties, user_details(params[:email], 'false'), category)

      defaults
    end

    def category
      types = []

      Klaviyo::Base::CUSTOM_CATEGORY.keys.each do |prfile_type|
        types.push(Klaviyo::Base::CUSTOM_CATEGORY[prfile_type]) unless params[prfile_type].to_i.zero?
      end

      {
        category: types.join(', ')
      }
    end

    def custom_properties
      properties = {}

      Klaviyo::Base::CUSTOM_PROPERTIES.each do |property|
        properties[property] = true.to_s
      end

      properties
    end
  end
end
