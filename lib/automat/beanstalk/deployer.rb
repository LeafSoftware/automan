require 'automat/mixins/aws_caller'
require 'pathname'
require 'logger'

#
# TODO: check status of environments and only update if status is 'Ready'
# * change exits to exceptions
#

module Automat::Beanstalk
  class Deployer
    attr_accessor :name,
                  :version_label,
                  :bucket,
                  :environment,
                  :configuration_template,
                  :configuration_options,
                  :solution_stack_name,
                  :max_versions,
                  :logger

    include Automat::Mixins::AwsCaller

    def initialize(options=nil)
      @logger = Logger.new(STDOUT)
      @log_aws_calls = false

      @max_versions = 0

      if !options.nil?
        options.each_pair do |k,v|
          accessor = (k.to_s + '=').to_sym
          send(accessor, v)
        end
      end
    end

    def log_options
      message = "called with:\n"
      message += "name:                   #{name}\n"
      message += "version_label:          #{version_label}\n"
      message += "bucket:                 #{bucket}\n"
      message += "environment:            #{environment}\n"
      message += "configuration_template: #{configuration_template}\n"
      message += "solution_stack_name:    #{solution_stack_name}\n"
      message += "max_versions:           #{max_versions}\n"
      logger.info message
    end

    def package_name
      "#{name}.zip"
    end

    def package_s3_key
      [name, version_label, package_name].join('/')
    end

    def package_exists?
      mybucket = s3.buckets[bucket]
      obj = mybucket.objects[package_s3_key]
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

      response = eb.delete_configuration_template opts

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

      application_versions.each do |v|
        if v[:application_name] == name && v[:version_label] == version_label
          return true
        end
      end

      return false
    end

    def create_version
      logger.info "creating version #{version_label}"
      opts = {
        application_name: name,
        version_label:    version_label,
        source_bundle: {
          s3_bucket:      bucket,
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
      logger.info "updating environment #{eb_environment_name} with version #{version_lable}"

      opts = {
        environment_name: eb_environment_name,
        version_label:    version_label
      }

      response = eb.update_environment opts

      unless response.successful?
        logger.error "update_environment failed: #{response.error}"
        exit 1
      end

    end

    def create_environment
      logger.info "creating environment #{eb_environment_name} for #{name} with version #{version_label}"

      opts = {
        application_name: name,
        environment_name: eb_environment_name,
        version_label:    version_label,
        template_name:    configuration_template,
        cname_prefix:     eb_environment_name
      }

      response = eb.create_environment opts

      unless response.successful?
        logger.error "create_environment failed: #{response.error}"
        exit 1
      end

    end

    def terminate_environment
      logger.info "terminating environment #{eb_environment_name}"

      opts = {
        environment_name: eb_environment_name
      }

      response = eb.terminate_environment opts

      unless response.successful?
        logger.error "terminate_environment failed: #{response.error}"
        exit 1
      end
    end

    def application_versions
      logger.info "listing application versions for #{name}"

      opts = {
        application_name: name
      }

      response = eb.describe_application_versions opts

      unless response.successful?
        logger.error "describe_application_versions failed: #{response.error}"
        exit 1
      end

      response.data[:application_versions]
    end

    def delete_application_version(version)
      logger.info "deleting version #{version} for application #{name}"

      opts = {
        application_name: name,
        version_label: version,
        delete_source_bundle: true
      }

      response = eb.delete_application_versions opts

      unless response.successful?
        logger.error "delete_application_version failed #{response.error}"
        exit 1
      end
    end

    def cull_versions
      versions = application_versions
      if versions.size <= max_versions.to_i
        return
      end

      to_cull = versions.size - max_versions.to_i
      logger.info "culling oldest #{to_cull} versions"

      condemned = versions.sort_by {|v| v[:date_created] }[0..to_cull-1]

      condemned.each do |i|
        delete_application_version(i[:version_label])
      end
    end

    def deploy
      logger.info "Deploying service."

      log_options

      # unless application_exists?
      #   create_application
      # end

      # unless config_template_exists?
      #   create_configuration_template
      # end

      unless package_exists?
        logger.error "package s3://#{bucket}/#{package_s3_key} does not exist."
        exit 1
      end

      unless version_exists?
        create_version

        if max_versions.to_i > 0
          cull_versions
        end
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

    def terminate
      logger.info "terminating service"
      log_options
      terminate_environment
    end

  end
end