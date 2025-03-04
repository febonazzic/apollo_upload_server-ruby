require 'apollo_upload_server/graphql_data_builder'
require "active_support/configurable"

module ApolloUploadServer
  class Middleware
    include ActiveSupport::Configurable

    # Strict mode requires that all mapped files are present in the mapping arrays.
    config_accessor :strict_mode do
      false
    end

    def initialize(app)
      @app = app
    end

    def call(env)
      unless env['CONTENT_TYPE'].to_s.include?('multipart/form-data')
        return @app.call(env)
      end

      params = env['rack.request.form_hash']

      if params['operations'].present? && params['map'].present?
        request = ActionDispatch::Request.new(env)

        result = GraphQLDataBuilder.new(strict_mode: self.class.strict_mode).call(request.params)
        result&.each do |key, value|
          request.update_param(key, value)
        end
      end

      @app.call(env)
    end
  end
end
