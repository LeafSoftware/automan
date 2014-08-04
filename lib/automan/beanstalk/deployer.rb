require 'automan'
require 'pathname'
require 'logger'
require 'json'

module Automan::Beanstalk
  class Deployer < Automan::Base
    add_option :name,
               :version_label,
               :package,
               :environment,
               :manifest,
               :configuration_template,
               :configuration_options,
               :solution_stack_name,
               :number_to_keep,
               :beanstalk_name

    include Automan::Mixins::Utils

    def initialize(options=nil)
      @number_to_keep = 0
      super
    end

    def manifest_exists?
      s3_object_exists? manifest
    end

    def read_manifest

      if !manifest_exists?
        raise MissingManifestError, "Manifest #{manifest} does not exist"
      end

      # read manifest from s3 location
      json = s3_read(manifest)

      # parse it from json
      data = JSON.parse json

      # set version_label and package
      self.version_label = data['version_label']
      self.package       = data['package']
    end

    def package_exists?
      s3_object_exists? package
    end

    def eb_environment_name
      # Constraint: Must be from 4 to 23 characters in length.
      # The name can contain only letters, numbers, and hyphens.
      # It cannot start or end with a hyphen.
      env_name = "#{name}-#{environment}"
      unless beanstalk_name.nil?
        env_name = beanstalk_name.dup
      end

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
      logger.info "updating environment #{eb_environment_name} with version #{version_label}"

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

    def get_version
      v = Automan::Beanstalk::Version.new
      v.application = name
      v.label = version_label
      v
    end

    def ensure_version_exists
      version = get_version()

      if version.exists?
        logger.warn "version #{version_label} for #{name} already exists. Not creating."
      else
        version.create(package)

        if number_to_keep > 0
          version.cull_versions(number_to_keep)
        end
      end
    end

    def create_or_update_environment
      case environment_status
      when nil, "Terminated"
        create_environment
      when "Ready"
        update_environment
      else
        raise InvalidEnvironmentStatusError, "Could not update environment as it's status is #{environment_status}"
      end
    end

    def deploy
      logger.info "Deploying service."

      if !manifest.nil?
        read_manifest
      end

      log_options

      unless package_exists?
        raise MissingPackageFileError, "package #{package} does not exist."
      end

      ensure_version_exists

      create_or_update_environment

      logger.info "Finished deploying service."
    end

  end
end