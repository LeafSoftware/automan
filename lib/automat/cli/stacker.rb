require 'thor'
require 'automat'

module Automat::Cli
  class Stacker < Thor
    desc "launch", "launches a cloudformation stack"

    option :name,
      required: true,
      aliases: "-n",
      desc: "name of the stack"

    option :template,
      required: true,
      aliases: "-t",
      desc: "path to local json template file"

    option :disable_rollback,
      type: :boolean,
      default: false,
      desc: "set to true to disable rollback of failed stacks"

    option :enable_iam,
      type: :boolean,
      default: false,
      desc: "set to true to enable IAM capabilities"

    option :enable_update,
      type: :boolean,
      default: false,
      desc: "set to true to update existing stack"

    option :parameters,
      type: :hash,
      default: {},
      aliases: "-p",
      desc: "stack parameters (e.g. -p Environment=dev InstanceType=m1.small)"

    def launch
      Automat::Cloudformation::Launcher.new(options).run
    end
  end
end