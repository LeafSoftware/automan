require 'automan'

module Automan::Cloudformation
  class Template < Automan::Base
    include Automan::Mixins::Utils

    def initialize(options={})
      super
      @cfn = Aws::CloudFormation::Client.new
    end

    add_option :template_path # either s3:// or local file

    # given template_path returns contents
    def template_contents
      if looks_like_s3_path? template_path
        s3_read template_path
      else
        File.read template_path
      end
    end

    # cache the validation response so we don't keep making api calls
    def validation_response
      if @validation_resp.nil?
        @validation_resp = cfn.validate_template(template_body: template_contents)
      end
      @validation_resp
    end

    def valid?
      begin
        validation_response
        true
      rescue Aws::CloudFormation::Errors::ValidationError
        false
      end
    end

    def required_parameters
      validation_response.parameters.
        select {|p| p.default_value.nil? }.
        map {|p| p.parameter_key}
    end

    def capabilities
      validation_response.capabilities
    end

  end
end
