require 'automat/base'
require 'automat/s3/errors'
require 'automat/mixins/utils'

module Automat::S3
  class Uploader < Automat::Base
    add_option :localfile, :s3file

    include Automat::Mixins::Utils

    def upload
      log_options

      logger.info "uploading #{localfile} to #{s3file}"

      bucket, key = parse_s3_path s3file
      s3.buckets[bucket].objects[key].write(:file => localfile)

    end

  end
end