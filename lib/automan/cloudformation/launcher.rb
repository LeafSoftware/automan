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

    def initialize(options={})
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

    def validate_parameters(stack_template)
      if parameters.nil?
        raise MissingParametersError, "there are no parameters!"
      end

      unless stack_template.valid?
        raise BadTemplateError, "template did not validate"
      end

      # make sure any template parameters w/o a default are specified
      stack_template.required_parameters.each do |rp|
        unless parameters.has_key? rp.parameter_key
          raise MissingParametersError, "required parameter #{rp.parameter_key} was not specified"
        end
      end

      # add iam capabilities if needed
      self.enable_iam = true if stack_template.capabilities.include?('CAPABILITY_IAM')
    end

    def launch(stack, template_body)
      logger.info "launching stack #{name}"

      stack.launch({
        template_body:    template_body,
        parameters:       parameters,
        capabilities:     enable_iam ? ['CAPABILITY_IAM'] : [],
        disable_rollback: disable_rollback
      })
      # cfn.stacks.create name, template_handle(template), opts

      if wait_for_completion
        logger.info "waiting for stack #{name} to launch"
        wait_until { stack.launch_complete? }
      end
    end

    def update(stack, template_body)
      logger.info "updating stack #{name}"
      no_updates_needed = false

      # If cfn determines that no updates are to be performed,
      # it raises a ValidationError
      begin
        stack.update({
          template:     template_body,
          parameters:   parameters,
          capabilities: enable_iam ? ['CAPABILITY_IAM'] : [],
        })
      rescue Aws::CloudFormation::Errors::ValidationError => e
        if e.message != "No updates are to be performed."
          raise e
        else
          logger.info e.message
          no_updates_needed = true
        end
      end

      if !no_updates_needed && wait_for_completion
        logger.info "waiting for stack #{name} to update"
        wait_until { stack.update_complete? }
      end

    end

    def run
      stack = Stack.new(name: name)
      stack_template = Template.new(template_path: template)
      launch_or_update(stack, stack_template)
    end

    def launch_or_update(stack, stack_template)

      read_manifest if manifest

      log_options

      validate_parameters(stack_template)

      if stack.exists?
        logger.info "stack #{name} exists"

        if enable_update == true
          update(stack, stack_template.template_contents)
        else
          raise StackExistsError, "stack #{name} already exists"
        end

      else
        launch(stack, stack_template.template_contents)
      end

    end
  end

end
