require 'automan'

module Automan::Cloudformation
  class Uploader < Automan::Base
    add_option :template_files, :s3_path

    def glob_templates
      Dir.glob(template_files)
    end

    def upload(file)
      opts = {
        localfile: file,
        s3file:    "#{s3_path}/#{File.basename(file)}"
      }
      s = Automan::S3::Uploader.new opts
      s.upload
    end

    def upload_templates
      log_options

      glob_templates.each do |file|
        template = Template.new(template_path: file)

        unless template.valid?
          raise InvalidTemplateError, "There are invalid templates. Halting upload."
        end
      end

      glob_templates.each do |file|
        upload file
      end
    end
  end
end
