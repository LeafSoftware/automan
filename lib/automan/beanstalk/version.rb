require 'automan'

module Automan::Beanstalk
  class Version < Automan::Base
    add_option :application, :label

    include Automan::Mixins::Utils

    def versions
      logger.info "listing versions for #{application}"

      opts = {
        application_name: application
      }

      response = eb.describe_application_versions opts

      unless response.successful?
        raise RequestFailedError "describe_application_versions failed: #{response.error}"
      end

      response.data[:application_versions]
    end

    def exists?
      versions.each do |v|
        if v[:application_name] == application && v[:version_label] == label
          return true
        end
      end

      return false
    end

    def create(package)
      logger.info "creating version #{label}"

      bucket, key = parse_s3_path(package)
      opts = {
        application_name: application,
        version_label:    label,
        source_bundle: {
          s3_bucket:      bucket,
          s3_key:         key
        }
      }

      response = eb.create_application_version opts

      unless response.successful?
        raise RequestFailedError, "create_application_version failed: #{response.error}"
      end
    end

    def delete_by_label(version_label)
      logger.info "deleting version #{version_label} for application #{application}"

      opts = {
        application_name: application,
        version_label: version_label,
        delete_source_bundle: true
      }

      begin
        response = eb.delete_application_version opts
        unless response.successful?
          raise RequestFailedError, "delete_application_version failed #{response.error}"
        end
      rescue AWS::ElasticBeanstalk::Errors::SourceBundleDeletionFailure => e
        logger.warn e.message
      end
    end

    def delete
      log_options

      delete_by_label label
    end

    def cull_versions(max_versions)
      log_options

      my_versions = versions
      if my_versions.size <= max_versions
        return
      end

      to_cull = my_versions.size - max_versions
      logger.info "culling oldest #{to_cull} versions"

      condemned = my_versions.sort_by {|v| v[:date_created] }[0..to_cull-1]

      condemned.each do |i|
        delete_by_label i[:version_label]
      end
    end

  end

end
