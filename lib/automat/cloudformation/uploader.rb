require 'automat'

module Automat::Cloudformation
  class Uploader < Automat::Base
    add_option :template_files, :s3_path

    def templates
      Dir.glob(template_files)
    end

    def template_valid?(template)
      contents = File.read template
      response = cfn.validate_template(contents)
      if response.has_key?(:code)
        logger.warn "#{template} is invalid: #{response[:message]}"
        return false
      else
        return true
      end
    end

    def all_templates_valid?
      if templates.empty?
        raise NoTemplatesError, "No stack templates found for #{template_files}"
      end

      valid = true
      templates.each do |template|
        unless template_valid?(template)
          valid = false
        end
      end
      valid
    end

    def upload_file(file)
      opts = {
        localfile: file,
        s3file:    "#{s3_path}/#{File.basename(file)}"
      }
      s = Automat::S3::Uploader.new opts
      s.upload
    end

    def upload_templates
      log_options

      unless all_templates_valid?
        raise InvalidTemplateError, "There are invalid templates. Halting upload."
      end

      templates.each do |template|
        upload_file(template)
      end
    end
  end
end
