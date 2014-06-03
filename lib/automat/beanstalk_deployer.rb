require 'aws-sdk'
require 'pathname'
require 'logger'

module Automat
  class BeanstalkDeployer
    attr_accessor :name,
                  :version,
                  :package_bucket,
                  :environment,
                  :configuration_template,
                  :logger

    attr_writer   :eb, :s3

    attr_reader   :log_aws_calls

    def initialize
      @logger = Logger.new(STDOUT)
      @log_aws_calls = false
    end

    def log_aws_calls=(value)
      if value == true
        AWS.config(logger: @logger)
      end
      @log_aws_calls = value
    end

    def print_options
      message = "called with:\n"
      message += "name:                   #{name}\n"
      message += "version:                #{version}\n"
      message += "package_bucket:         #{package_bucket}\n"
      message += "environment:            #{environment}\n"
      message += "configuration_template: #{configuration_template}\n"
      logger.info message
    end

    def eb
      if @eb.nil?
        @eb = AWS::ElasticBeanstalk.new.client
      end
      @eb
    end

    def s3
      if @s3.nil?
        @s3 = AWS::S3.new
      end
      @s3
    end

    def package_name
      "#{name}.zip"
    end

    def package_s3_key
      [name, version, package_name].join('/')
    end

    def package_exists?
      bucket = s3.buckets[package_bucket]
      obj = bucket.objects[package_s3_key]
      obj.exists?
    end

    def eb_environment_name
      # Constraint: Must be from 4 to 23 characters in length.
      # The name can contain only letters, numbers, and hyphens.
      # It cannot start or end with a hyphen.
      env_name = "#{name}-#{environment}"

      if env_name.length > 23
        env_name = env_name[0,23]
      end

      env_name.gsub!(/[^A-Za-z0-9\-]/, '-')

      env_name.gsub!(/(^\-+)|(\-+$)/, '')

      if env_name.length < 4
        env_name += "-Env"
      end

      env_name
    end

    def version_exists?
      opts = {
        application_name: name,
        version_labels: [version]
      }

      response = eb.describe_application_versions opts

      unless response.successful?
        logger.error "create_application_version failed: #{response.error}"
        exit 1
      end

      response.data[:application_versions].each do |v|
        if v[:application_name] == name && v[:version_label] == version
          return true
        end
      end

      return false
    end

    def create_version
      logger.info "creating version #{version}"
      opts = {
        application_name: name,
        version_label: version,
        source_bundle: {
          s3_bucket: package_bucket,
          s3_key: package_s3_key
        }
      }

      response = eb.create_application_version opts

      unless response.successful?
        logger.error "create_application_version failed: #{response.error}"
        exit 1
      end
    end

    def environment_exists?
      opts = {
        environment_names: [eb_environment_name]
      }

      response = eb.describe_environments opts

      unless response.successful?
        logger.error "describe_environments failed: #{response.error}"
        exit 1
      end

      response.data[:environments].each do |env|
        if env[:environment_name] == eb_environment_name
          return true
        end
      end

      return false
    end

    def update_environment
      logger.info "updating environment #{eb_environment_name} with version #{version}"

      opts = {
        environment_name: eb_environment_name,
        version_label: version
      }

      response = eb.update_environment opts

      unless response.successful?
        logger.error "update_environment failed: #{response.error}"
        exit 1
      end

    end

    def create_environment
      logger.info "creating environment #{eb_environment_name} for #{name} with version #{version}"

      opts = {
        application_name: name,
        environment_name: eb_environment_name,
        version_label: version,
        template_name: configuration_template
      }

      response = eb.create_environment opts

      unless response.successful?
        logger.error "create_environment failed: #{response.error}"
        exit 1
      end

    end

    def run
      logger.info "Deploying service."

      print_options

      unless package_exists?
        logger.error "package s3://#{package_bucket}/#{package_s3_key} does not exist."
        exit 1
      end

      unless version_exists?
        create_version
      end

      if environment_exists?
        update_environment
      else
        create_environment
      end

      logger.info "Finished deploying service."
    end

  end
end