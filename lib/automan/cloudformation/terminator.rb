require 'automan'

module Automan::Cloudformation
  class Terminator < Automan::Base
    add_option :name, :wait_for_completion

    def initialize(options=nil)
      @wait_for_completion = false
      super
      @wait = Wait.new({
        delay: 60,
        attempts: 20, # 20 x 60s == 20m
        debug: true,
        rescuer:  WaitRescuer.new(),
        logger:   @logger
      })
    end

    def stack_exists?(stack_name)
      cfn.stacks[stack_name].exists?
    end

    def delete_stack(stack_name)
      cfn.stacks[stack_name].delete
    end

    def stack_status(stack_name)
      cfn.stacks[stack_name].status
    end

    def stack_deleted?(stack_name)
      case stack_status(stack_name)
      when 'DELETE_COMPLETE'
        true
      when 'DELETE_FAILED'
        raise StackDeletionError, "#{stack_name} failed to delete"
      else
        false
      end
    end

    def terminate
      log_options

      if !stack_exists? name
        logger.warn "Stack #{name} does not exist. Doing nothing."
        return
      end

      logger.info "terminating stack #{name}"
      delete_stack name

      if wait_for_completion
        logger.info "waiting for stack #{name} to be deleted"
        wait_until { stack_deleted? name }
      end
    end
  end
end