require 'automat'

module Automat::Beanstalk
  class Application < Automat::Base
    add_option :name

    def application_exists?
      opts = {
        application_names: [ name ]
      }

      response = eb.describe_applications opts

      unless response.successful?
        raise RequestFailedError, "describe_applications failed: #{response.error}"
      end

      response.data[:applications].each do |app|
        if app[:application_name] == name
          return true
        end
      end

      return false
    end

    def create_application
      logger.info "creating application #{name}"

      opts = {
        application_name: name
      }

      response = eb.create_application opts

      unless response.successful?
        raise RequestFailedError, "create_application failed: #{response.error}"
      end
    end

    def delete_application
      logger.info "deleting application #{name}"

      opts = {
        application_name: name
      }

      response = eb.delete_application opts

      unless response.successful?
        raise RequestFailedError, "delete_application failed: #{response.error}"
      end
    end

    def create
      log_options
      if application_exists?
        logger.warn "Application #{name} already exists. Doing nothing."
        return
      end
      create_application
    end

    def delete
      log_options
      if !application_exists?
        logger.warn "Application #{name} does not exist. Doing nothing."
        return
      end
      delete_application
    end
  end

end
