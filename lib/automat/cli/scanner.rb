require 'thor'
require 'automat'

module Automat::Cli
  class Scanner < Thor
    def self.exit_on_failure?
        return true
    end

    desc "show-instances", "Show instance ips and passwords for an environment"

    option :environment,
      required: true,
      aliases: "-e",
      default: "dev1",
      desc: "Show instances from this environment"

    option :private_key_file,
      required: true,
      aliases: "-p",
      desc: "Path to private key to use when decrypting windows password"

    def show_instances
      i = Automat::Ec2::Instance.new(options)
      i.logger = Logger.new('/dev/null')
      i.show_env
    end
  end
end