require 'automat/base'
require 'automat/mixins/utils'
require 'automat/beanstalk/errors'
require 'pathname'
require 'json'

module Automat::Beanstalk
  class Package < Automat::Base
    add_option :destination, :source, :manifest, :version_label

    include Automat::Mixins::Utils

    def upload_package
      log_options

      # verify local package exists
      unless File.exists? source
        raise MissingPackageFile, "package file #{source} does not exist"
      end

      logger.info "Uploading #{source} to #{destination}"

      # upload package file
      bucket, key = parse_s3_path destination
      s3.buckets[bucket].objects[key].write(Pathname.new(source))

      # upload manifest file
      if !manifest.nil?
        logger.info "Uploading manifest file for #{version_label} to #{manifest}"
        contents = {
          "version_label" => version_label,
          "package" => destination
        }.to_json

        bucket, key = parse_s3_path manifest
        s3.buckets[bucket].objects[key].write(contents)
      end

    end
  end
end