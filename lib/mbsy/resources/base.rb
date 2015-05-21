module Mbsy
  class MbsyError < StandardError; end
  class BadRequestError < MbsyError; end
  class UnauthorizedError < MbsyError; end
  class RecordNotFound < MbsyError; end
  class ServerError < MbsyError; end
  class BadResponse < MbsyError; end

  class Base

    def self.element_name
      name.split(/::/).last.underscore
    end

    def self.api_url(method)
      Mbsy.site_uri + self.element_name + '/' + method
    end

    def self.call(method, params = {})
      url = api_url(method)
      conn = Faraday.new(:url => url) do |faraday|
        faraday.request :url_encoded
        faraday.response :logger
        faraday.adapter Faraday.default_adapter # Net::HTTP
      end

      response = conn.get do |req|
        req.url url
        req.options.timeout = 30
        req.params = params
        req.params[:output] = 'json'
      end

      response = JSON.parse(response.body)['response']
      case response['code']
      when '200' # Nothing to do here...
      when '400'
        raise BadRequestError.new(response['errors']['error'])
      when '401'
        raise UnauthorizedError.new(response['errors']['error'])
      when '404'
        raise RecordNotFound.new(response['errors']['error'])
      when '500'
        raise ServerError.new(response['errors']['error'])
      else
        raise BadResponse.new(response: response)
      end

      response['data']
    end
  end
end
