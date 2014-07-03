require 'automat/base'

module Automat::Cloudformation
  class Uploader < Automat::Base
    add_option :templatefiles, :s3path

    def validate_templates
      healthy=true
      Dir.glob(templatefiles) do |cfnfile|
        cfnstring=File.open(cfnfile, 'rb') { |f| f.read }
        if cfn.validate_template(cfnstring).has_key?(:code)
          logger.error "Validation failure on #{cfnfile}"
          healthy=false
        end
      end
      return healthy
    end

    def upload_templates
      log_options

      if validate_templates
        Dir.glob(templatefiles) do |cfnfile|
          logger.info "uploading #{cfnfile}"
          options={ :localfile => cfnfile, :s3file => "#{s3path}/#{File.basename(cfnfile)}" }
          s = Automat::S3::Uploader.new(options)
          s.upload
        end
      else
        logger.error "Aborting upload due to validation failure(s)"
        exit 1
      end
    end
  end
end