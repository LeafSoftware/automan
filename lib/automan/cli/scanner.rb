require 'automan'

module Automan::Cli
  class Scanner < Base

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
      i = Automan::Ec2::Instance.new(options)
      i.show_env
    end
  end
end