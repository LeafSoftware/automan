require 'automan'
require 'json'

# TODO: add timeout

module Automan::Cloudformation
  class Launcher < Automan::Base
    add_option :name,
               :template,
               :disable_rollback,
               :enable_iam,
               :enable_update,
               :parameters,
               :manifest,
               :wait_for_completion

    include Automan::Mixins::Utils

    def initialize(options=nil)
      @wait_for_completion = false
      super
      @wait = Wait.new({
        delay: 120,
        attempts: 15, # 15 x 2m == 30m
        debug: true,
        rescuer:  WaitRescuer.new(),
        logger:   @logger
      })
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

    def stack_status
      cfn.stacks[name].status
    end

    def stack_launch_complete?
      case stack_status
      when 'CREATE_COMPLETE'
        true
      when 'CREATE_FAILED', /^ROLLBACK_/
        raise StackCreationError, "Stack #{name} failed to launch"
      else
        false
      end
    end

    def stack_update_complete?
      case stack_status
      when 'UPDATE_COMPLETE'
        true
      when 'UPDATE_FAILED', /^UPDATE_ROLLBACK_/
        raise StackUpdateError, "Stack #{name} failed to update"
      else
        false
      end
    end

    def launch
      opts = {
        parameters: parameters
      }
      opts[:capabilities] = ['CAPABILITY_IAM'] if enable_iam
      opts[:disable_rollback] = disable_rollback

      logger.info "launching stack #{name}"
      cfn.stacks.create name, template_handle(template), opts

      if wait_for_completion
        logger.info "waiting for stack #{name} to launch"
        wait_until { stack_launch_complete? }
      end
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

      if wait_for_completion
        logger.info "waiting for stack #{name} to update"
        wait_until { stack_update_complete? }
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