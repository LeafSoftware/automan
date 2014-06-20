require 'json'

require 'automat/base'
require 'automat/mixins/utils'
require 'automat/beanstalk/errors'

module Automat::Beanstalk
  class Configuration < Automat::Base
    add_option :name,
               :application,
               :template,
               :platform

    include Automat::Mixins::Utils

    def config_template_exists?
      opts = {
        application_name: application,
        template_name:    name
      }

      begin
        response = eb.describe_configuration_settings opts
      rescue AWS::ElasticBeanstalk::Errors::InvalidParameterValue => e
        if e.message.start_with? "No Configuration Template named"
          return false
        end
      end

      unless response.successful?
        raise RequestFailedError, "describe_configuration_settings failed: #{response.error}"
      end

      response.data[:configuration_settings].each do |settings|
        if settings[:application_name] == application && settings[:template_name] == name
          return true
        end
      end

      return false
    end

    def delete_config_template
      opts = {
        application_name: application,
        template_name:    name
      }

      response = eb.delete_configuration_template opts

      unless response.successful?
        raise RequestFailedError, "delete_configuration_template failed: #{response.error}"
      end
    end

    # config_option files are stored in json format compatible
    # with elastic-beanstalk-create-configuration-template cli.
    # The keys of each object are in json CamelCase.
    # We need to convert them to ruby snake_case to work with aws-sdk
    def fix_config_keys(config_array)
      result = []
      config_array.each do |i|
        fixed_hash = {}
        i.each do |key, value|
          fixed_key = key.underscore
          fixed_hash[ fixed_key ] = value.to_s
        end
        result << fixed_hash
      end
      result
    end

    # TODO: read options file (from local or s3) into array of hashes
    # http://docs.aws.amazon.com/AWSRubySDK/latest/AWS/ElasticBeanstalk/Client/V20101201.html#create_configuration_template-instance_method
    def configuration_options
      json_config = ""

      if looks_like_s3_path? template
        bucket, key = parse_s3_path template
        json_config = s3.buckets[bucket].objects[key].read
      else
        json_config = File.read template
      end

      config = JSON.parse json_config
      config = fix_config_keys config

      config
    end

    # where are we getting configuration data?
    def create_config_template
      opts = {
        application_name:    application,
        template_name:       name,
        solution_stack_name: platform,
        option_settings:     configuration_options
      }

      response = eb.create_configuration_template opts

      unless response.successful?
        raise RequestFailedError, "create_configuration_template failed: #{response.error}"
      end
    end

    def create
      log_options
      if config_template_exists?
        logger.warn "Configuration template #{name} for #{application} already exists. Doing nothing."
      end
      logger.info "Creating configuration template #{name} for #{application}."
      create_config_template
    end

    def delete
      log_options
      if !config_template_exists?
        logger.warn "Configuration #{name} for #{application} does not exist. Doing nothing."
        return
      end
      logger.info "Deleting configuration template #{name} for #{application}."
      delete_config_template
    end

    def update
      log_options

      if config_template_exists?
        logger.info "Configuration template #{name} for #{application} exists. Deleting it."
        delete_config_template
      end

      logger.info "Creating configuration template #{name} for #{application}"
      create_config_template
    end
  end

end
