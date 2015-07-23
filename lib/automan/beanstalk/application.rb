require 'automan'

module Automan::Beanstalk
  class Application < Automan::Base
    add_option :name

    def exists?
      response = eb.describe_applications({
        application_names: [ name ]
      })

      unless response.successful?
        raise RequestFailedError, "describe_applications failed: #{response.error}"
      end

      response.applications.each do |app|
        return true if app.application_name == name
      end

      return false
    end

    def create
      logger.info "creating application #{name}"

      response = eb.create_application({
        application_name: name
      })

      unless response.successful?
        raise RequestFailedError, "create application failed: #{response.error}"
      end
    end

    def delete
      logger.info "deleting application #{name}"

      response = eb.delete_application({
        application_name: name
      })

      unless response.successful?
        raise RequestFailedError, "delete application failed: #{response.error}"
      end
    end

    def versions
      logger.info "listing versions for #{name}"

      response = eb.describe_application_versions({
        application_name: name
      })

      unless response.successful?
        raise RequestFailedError, "list versions for application failed: #{response.error}"
      end

      response.application_versions
    end

    def version_exists?(version_label)
      versions.each do |version|
        if version.version_label == version_label
          return true
        end
      end
      false
    end

    def create_version(package_path, version_label)
      logger.info "creating version #{version_label}"

      bucket, key = parse_s3_path(package_path)

      response = eb.create_application_version({
        application_name: name,
        version_label:    version_label,
        source_bundle: {
          s3_bucket:      bucket,
          s3_key:         key
        }
      })

      unless response.successful?
        raise RequestFailedError, "create_application_version failed: #{response.error}"
      end
    end

    def delete_version(version_label)
      logger.info "deleting version #{version_label} for application #{name}"

      begin
        response = eb.delete_application_version({
          application_name: name,
          version_label: version_label,
          delete_source_bundle: true
        })
      rescue Aws::ElasticBeanstalk::Errors::SourceBundleDeletionFailure => e
        logger.warn e.message
      end

      unless response.successful?
        raise RequestFailedError, "delete version failed #{response.error}"
      end
    end

    def cull_versions(number_to_keep)
      my_versions = versions
      if my_versions.size <= number_to_keep
        return
      end

      to_cull = my_versions.size - number_to_keep
      logger.info "culling oldest #{to_cull} application versions for #{name}"

      condemned = my_versions.sort_by {|v| v.date_created }[0..to_cull-1]

      condemned.each do |i|
        delete_version i.version_label
      end
    end
  end
end
