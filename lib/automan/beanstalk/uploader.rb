require 'automan'
require 'json'

module Automan::Beanstalk
  class Uploader < Automan::Base
    add_option :template_files, :s3_path

    def config_templates
      Dir.glob template_files
    end

    def read_config_template(file)
      File.read file
    end

    def config_templates_valid?
      valid = true
      templates = config_templates

      if templates.empty?
        raise NoConfigurationTemplatesError, "No configuration template files found for #{template_files}"
      end

      templates.each do |template|
        raw = read_config_template template
        begin
          JSON.parse(raw)
        rescue Exception => e
          logger.warn "#{template} is invalid json: #{e.message}"
          valid = false
          next
        end
        logger.debug "#{template} is valid json"
      end

      valid
    end

    def upload_file(file)
      opts = {
        localfile: file,
        s3file:    "#{s3_path}/#{File.basename(file)}"
      }
      s = Automan::S3::Uploader.new opts
      s.upload
    end

    def upload_config_templates
      unless config_templates_valid?
        raise InvalidConfigurationTemplateError, "There are invalid configuration templates. Halting upload."
      end

      config_templates.each do |template|
        upload_file(template)
      end
    end
  end
end