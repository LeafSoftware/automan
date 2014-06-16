require 'automat/mixins/aws_caller'

module Automat
  class Stacker
    attr_accessor :template_file

    include Automat::Mixins::AwsCaller

    def run
      results = parse_template_parameters
      puts results.inspect
    end

    def parse_template_parameters
      if template_file.nil?
        raise MissingAttributeError, "template_file missing"
      end

      cfn.validate_template(File.read(template_file))
    end
  end

  class MissingAttributeError < StandardError
  end
end