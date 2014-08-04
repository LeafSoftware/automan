require 'automan'
require 'json'

module Automan::Cli
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
      Automan::Cloudformation::Launcher.new(options).launch_or_update
    end

    desc "terminate", "terminate stack"

    option :name,
      required: true,
      aliases: "-n",
      desc: "name of the stack"

    def terminate
      Automan::Cloudformation::Terminator.new(options).terminate
    end

    desc "replace-instances", "terminate and replace running asg instances"

    option :name,
      required: true,
      aliases: "-n",
      desc: "name of the stack"

    def replace_instances
      Automan::Cloudformation::Replacer.new(options).replace_instances
    end

    desc "upload-templates", "validate and upload cloudformation templates"

    option :template_files,
      required: true,
      aliases: "-t",
      desc: "single or globbed templates"

    option :s3_path,
      required: true,
      aliases: "-p",
      desc: "s3 path to folder to drop the templates"

    def upload_templates
      Automan::Cloudformation::Uploader.new(options).upload_templates
    end

    desc "params", "print output from validate_template"

    option :template,
      required: true,
      aliases: "-t",
      desc: "path to template file (s3://bucket/template or local file)"

    def params
      h = Automan::Cloudformation::Launcher.new(options).parse_template_parameters
      say JSON.pretty_generate h
    end
  end
end