require 'automan'
require 'json'
require 'pp'

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

    option :wait_for_completion,
      aliases: "-w",
      type: :boolean,
      default: false,
      desc: "wait until stack launches/updates before exiting script"


    def launch
      Automan::Cloudformation::Launcher.new(options).run
    end

    desc "terminate", "terminate stack"

    option :name,
      required: true,
      aliases: "-n",
      desc: "name of the stack"

    option :wait_for_completion,
      aliases: "-w",
      type: :boolean,
      default: false,
      desc: "wait until stack terminates before exiting script"

    def terminate
      Automan::Cloudformation::Terminator.new(options).run
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

    option :template_path,
      required: true,
      aliases: "-t",
      desc: "path to template file (s3://bucket/template or local file)"

    def params
      resp = Automan::Cloudformation::Template.new(options).validation_response
      say resp.pretty_inspect
    end

    include Thor::Actions
    def self.source_root
      File.join(File.dirname(__FILE__),'..','..', '..')
    end

    desc "project APP_NAME", "create stacker project"

    attr_reader :app_name

    def project(app_name)
      @app_name = app_name

      say "\nCreating stacker project: #{app_name}\n", :yellow
      directory 'templates/stacker', app_name
      [app_name, "launch_#{app_name}.sh"].each do |file|
        chmod File.join(app_name, 'bin', file), 0755
      end
    end
  end
end