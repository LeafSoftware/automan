require 'automat'
require 'json'

module Automat::Cli
  class Stacker < Base

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

    option :manifest,
      aliases: "-m",
      desc: "s3 path to manifest file containing version and package location"

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
      say JSON.pretty_generate h
    end
  end
end