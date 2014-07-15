require 'automat'
require 'json'

# TODO: add timeout

module Automat::Cloudformation
  class Launcher < Automat::Base
    add_option :name,
               :template,
               :disable_rollback,
               :enable_iam,
               :enable_update,
               :parameters,
               :manifest

    include Automat::Mixins::Utils

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

      # merge manifest parameters into cli parameters
      parameters.merge!(data)
    end

    def template_handle(template_path)
      if looks_like_s3_path? template_path
        bucket, key = parse_s3_path template_path
        return s3.buckets[bucket].objects[key]
      else
        return File.read(template_path)
      end
    end

    def parse_template_parameters
      cfn.validate_template( template_handle(template) )
    end

    def validate_parameters
      if parameters.nil?
        raise MissingParametersError, "there are no parameters!"
      end

      template_params_hash = parse_template_parameters

      if template_params_hash.has_key? :code
        mesg = template_params_hash[:message]
        raise BadTemplateError, "template did not validate: #{mesg}"
      end

      # make sure any template parameters w/o a default are specified
      template_params = template_params_hash[:parameters]
      required_params = template_params.select { |x| !x.has_key? :default_value}
      required_params.each do |rp|
        unless parameters.has_key? rp[:parameter_key]
          raise MissingParametersError, "required parameter #{rp[:parameter_key]} was not specified"
        end
      end

      # add iam capabilities if needed
      if template_params_hash.has_key?(:capabilities) &&
        template_params_hash[:capabilities].include?('CAPABILITY_IAM')
        self.enable_iam = true
      end

    end

    def stack_exists?
      cfn.stacks[name].exists?
    end

    def launch
      opts = {
        parameters: parameters
      }
      opts[:capabilities] = ['CAPABILITY_IAM'] if enable_iam
      opts[:disable_rollback] = disable_rollback

      logger.info "launching stack #{name}"
      cfn.stacks.create name, template_handle(template), opts
    end

    def update_stack(name, opts)
      cfn.stacks[name].update( opts )
    end

    def update
      opts = {
        template: template_handle(template),
        parameters: parameters
      }
      opts[:capabilities] = ['CAPABILITY_IAM'] if enable_iam

      logger.info "updating stack #{name}"

      # if cfn determines that no updates are to be performed,
      # it raises a ValidationError
      begin
        update_stack(name, opts)
      rescue AWS::CloudFormation::Errors::ValidationError => e
        if e.message != "No updates are to be performed."
          raise e
        else
          logger.info e.message
        end
      end
    end

    def launch_or_update

      if !manifest.nil?
        read_manifest
      end

      log_options

      validate_parameters

      if stack_exists?

        logger.info "stack #{name} exists"
        if enable_update == true
          update
        else
          raise StackExistsError, "stack #{name} already exists"
        end

      else
        launch
      end

    end
  end

end