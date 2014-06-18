require 'automat/base'

module Automat::Cloudformation
  class Terminator < Automat::Base
    add_option :name

    def terminate
      log_options
      logger.info "terminating stack #{name}"
      cfn.stacks[name].delete
    end
  end
end