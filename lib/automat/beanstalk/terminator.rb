require 'automat/base'
require 'automat/beanstalk/errors'

module Automat::Beanstalk
  class Terminator < Automat::Base
    add_option :name

    def terminate_environment
      logger.info "terminating environment #{name}"

      opts = {
        environment_name: name
      }

      response = eb.terminate_environment opts

      unless response.successful?
        raise RequestFailedError "terminate_environment failed: #{response.error}"
      end
    end

    def terminate
      log_options
      terminate_environment
    end
  end
end