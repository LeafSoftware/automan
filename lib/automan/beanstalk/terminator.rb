require 'automan'

module Automan::Beanstalk
  class Terminator < Automan::Base
    add_option :name

    def environment_exists?(environment_name)
      response = eb.describe_environments({
        environment_names: [ environment_name ]
      })

      unless response.successful?
        raise RequestFailedError "describe_environments failed: #{response.error}"
      end

      response.environments.each do |e|
        if e.environment_name == environment_name
          logger.debug "#{environment_name} has status: #{e.status}"

          case e.status
          when 'Terminated', 'Terminating'
            return false
          else
            return true
          end

        end
      end

      false
    end

    def terminate_environment
      logger.info "terminating environment #{name}"

      response = eb.terminate_environment({
        environment_name: name
      })

      unless response.successful?
        raise RequestFailedError "terminate_environment failed: #{response.error}"
      end
    end

    def terminate
      log_options

      if !environment_exists?(name)
        logger.warn "Environment #{name} does not exist. Doing nothing."
        return
      end

      terminate_environment
    end
  end
end