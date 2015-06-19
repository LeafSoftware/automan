require 'automan'

module Automan::Cloudformation
  class Terminator < Automan::Base
    add_option :name, :wait_for_completion

    def initialize(options={})
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

    def terminate(stack)
      log_options

      unless stack.exists?
        logger.warn "Stack #{stack.name} does not exist. Doing nothing."
        return
      end

      logger.info "terminating stack #{stack.name}"
      stack.delete

      if wait_for_completion
        logger.info "waiting for stack #{stack.name} to be deleted"
        wait_until { stack.delete_complete? }
      end
    end

    def run
      stack = Stack.new(name: name)
      terminate(stack)
    end
  end
end