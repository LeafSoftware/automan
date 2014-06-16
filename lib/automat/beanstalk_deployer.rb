require 'automat/mixins/aws_caller'
require 'pathname'
require 'logger'

#
# TODO: check status of environments and only update if status is 'Ready'
# * change exits to exceptions
#

module Automat
  class BeanstalkDeployer
    attr_accessor :name,
                  :version,
                  :package_bucket,
                  :environment,
                  :configuration_template,
                  :configuration_options,
                  :solution_stack_name,
                  :logger

    include Automat::Mixins::AwsCaller

    def initialize
      @logger = Logger.new(STDOUT)
      @log_aws_calls = false
    end

    def print_options
      message = "called with:\n"
      message += "name:                   #{name}\n"
      message += "version:                #{version}\n"
      message += "package_bucket:         #{package_bucket}\n"
      message += "environment:            #{environment}\n"
      message += "configuration_template: #{configuration_template}\n"
      message += "solution_stack_name:    #{solution_stack_name}\n"
      logger.info message
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

    def application_exists?
      opts = {
        application_names: [ name ]
      }

      response = eb.describe_applications opts

      unless response.successful?
        logger.error "describe_applications failed: #{response.error}"
        exit 1
      end

      response.data[:applications].each do |app|
        if app[:application_name] == name
          return true
        end
      end

      return false
    end

    def create_application
      logger.info "creating application #{name}"

      opts = {
        application_name: name
      }

      response = eb.create_application opts

      unless response.successful?
        logger.error "create_application failed: #{response.error}"
        exit 1
      end
    end

    def config_template_exists?
      opts = {
        application_name: name,
        template_name:    configuration_template
      }

      response = eb.describe_configuration_settings opts

      unless response.successful?
        logger.error "describe_configuration_settings failed: #{response.error}"
        exit 1
      end

      response.data[:configuration_settings].each do |settings|
        if settings[:application_name] == name && settings[:template_name] == configuration_template
          return true
        end
      end

      return false
    end

    def delete_config_template
      opts = {
        application_name: name,
        template_name:    configuration_template
      }

      reponse = eb.delete_configuration_template opts

      unless response.successful?
        logger.error "delete_configuration_template failed: #{response.error}"
        exit 1
      end
    end

    # where are we getting configuration data?
    def create_config_template
      opts = {
        application_name:    name,
        template_name:       configuration_template,
        solution_stack_name: solution_stack_name,
        option_settings:     configuration_options
      }

      response = eb.create_configuration_template opts

      unless response.successful?
        logger.error "create_configuration_template failed: #{response.error}"
        exit 1
      end
    end

    def version_exists?
      opts = {
        application_name: name,
        version_labels:   [ version ]
      }

      response = eb.describe_application_versions opts

      unless response.successful?
        logger.error "describe_application_versions failed: #{response.error}"
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
        version_label:    version,
        source_bundle: {
          s3_bucket:      package_bucket,
          s3_key:         package_s3_key
        }
      }

      response = eb.create_application_version opts

      unless response.successful?
        logger.error "create_application_version failed: #{response.error}"
        exit 1
      end
    end

    # Possible status states:
    # Launching
    # Updating
    # Ready
    # Terminating
    # Terminated
    def environment_status
      opts = {
        environment_names: [eb_environment_name]
      }

      response = eb.describe_environments opts

      unless response.successful?
        logger.error "describe_environments failed: #{response.error}"
        exit 1
      end

      status = nil
      response.data[:environments].each do |env|
        if env[:environment_name] == eb_environment_name
          status = env[:status]
          break
        end
      end
      status
    end

    def update_environment
      logger.info "updating environment #{eb_environment_name} with version #{version}"

      opts = {
        environment_name: eb_environment_name,
        version_label:    version
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
        version_label:    version,
        template_name:    configuration_template,
        cname_prefix:     eb_environment_name
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

      unless application_exists?
        create_application
      end

      unless config_template_exists?
        create_configuration_template
      end

      unless package_exists?
        logger.error "package s3://#{package_bucket}/#{package_s3_key} does not exist."
        exit 1
      end

      unless version_exists?
        create_version
      end

      case environment_status
      when nil, "Terminated"
        create_environment
      when "Ready"
        update_environment
      else
        logger.error "Could not update environment as it's status is #{environment_status}"
        exit 1
      end

      logger.info "Finished deploying service."
    end

  end
end