require 'automan'

module Automan::S3
  class Downloader < Automan::Base
    add_option :localfile, :s3file

    include Automan::Mixins::Utils

    def download
      log_options

      logger.info "downloading #{s3file} to #{localfile}"

      bucket, key = parse_s3_path s3file

      File.open(localfile, 'wb') do |file|
        s3.buckets[bucket].objects[key].read do |chunk|
          file.write(chunk)
        end
      end
    end

    def read
      log_options

      logger.info "returning contents of #{s3file} as string"

      bucket, key = parse_s3_path s3file

      s3.buckets[bucket].objects[key].read
    end

  end
end