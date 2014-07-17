require 'automat'

module Automat::Cloudformation
  class Terminator < Automat::Base
    add_option :name

    def stack_exists?(stack_name)
      cfn.stacks[stack_name].exists?
    end

    def delete_stack(stack_name)
      cfn.stacks[stack_name].delete
    end

    def terminate
      log_options

      if !stack_exists? name
        logger.warn "Stack #{name} does not exist. Doing nothing."
        return
      end

      logger.info "terminating stack #{name}"
      delete_stack name
    end
  end
end