require 'automan'

module Automan::Cloudformation
  class Stack < Automan::Base
    def initialize(options={})
      super
      @cfn = Aws::CloudFormation::Resource.new
    end

    add_option :name

    def exists?
      begin
        cfn.stack(name).stack_id
        true
      rescue Aws::CloudFormation::Errors::ValidationError
        false
      end
    end

    def status
      cfn.stack(name).stack_status
    end

    def launch_complete?
      case status
      when 'CREATE_COMPLETE'
        true
      when 'CREATE_FAILED', /^ROLLBACK_/
        raise StackCreationError, "Stack #{name} failed to launch"
      else
        false
      end
    end

    def update_complete?
      case status
      when 'UPDATE_COMPLETE'
        true
      when 'UPDATE_FAILED', /^UPDATE_ROLLBACK_/
        raise StackUpdateError, "Stack #{name} failed to update"
      else
        false
      end
    end

    def delete_complete?
      return true unless exists?

      case status
      when 'DELETE_COMPLETE'
        true
      when 'DELETE_FAILED'
        raise StackDeletionError, "#{name} failed to delete"
      else
        false
      end
    end

    def update(options)
      stack = cfn.stack(name)
      stack.update({
        template_body: options[:template_body],
        parameters:    convert_parameters(options[:parameters]),
        capabilities:  options[:capabilities]
      })
    end

    # Takes a parameter hash like {'Environment' => 'dev'}
    # and returns a list of hashes create_stack expects:
    # [{ parameter_key: 'Environment', parameter_value: 'dev' }]
    #
    def convert_parameters(parameters)
      parameters.map { |k,v| { parameter_key: k, parameter_value: v } }
    end

    def launch(options)
      cfn.create_stack({
        stack_name:       name,
        template_body:    options[:template_body],
        parameters:       convert_parameters(options[:parameters]),
        disable_rollback: options[:disable_rollback],
        capabilities:     options[:capabilities]
      })
    end

    def delete
      cfn.stack(name).delete
    end
  end
end