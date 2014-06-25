require 'thor'
require 'automat'

module Automat::Cli
  class Stacker < Thor
    def self.exit_on_failure?
        return true
    end

    desc "launch", "launches a cloudformation stack"

    option :name,
      required: true,
      aliases: "-n",
      desc: "name of the stack"

    option :template,
      required: true,
      aliases: "-t",
      desc: "path to template file (s3://bucket/template or local file)"

    option :disable_rollback,
      type: :boolean,
      default: false,
      desc: "set to true to disable rollback of failed stacks"

    option :enable_update,
      type: :boolean,
      default: false,
      desc: "set to true to update existing stack"

    option :parameters,
      type: :hash,
      default: {},
      aliases: "-p",
      desc: "stack parameters (e.g. -p Environment:dev InstanceType:m1.small)"

    def launch
      Automat::Cloudformation::Launcher.new(options).launch_or_update
    end

    desc "terminate", "terminate stack"

    option :name,
      required: true,
      aliases: "-n",
      desc: "name of the stack"

    def terminate
      Automat::Cloudformation::Terminator.new(options).terminate
    end

    desc "replace-instances", "terminate and replace running asg instances"

    option :name,
      required: true,
      aliases: "-n",
      desc: "name of the stack"

    def replace_instances
      Automat::Cloudformation::Replacer.new(options).replace_instances
    end

    desc "params", "print output from validate_template"

    option :template,
      required: true,
      aliases: "-t",
      desc: "path to template file (s3://bucket/template or local file)"

    def params
      h = Automat::Cloudformation::Launcher.new(options).parse_template_parameters
      puts h.inspect
    end
  end
end