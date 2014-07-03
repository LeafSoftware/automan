require 'thor'
require 'automat'

module Automat::Cli
  class Baker < Thor
    def self.exit_on_failure?
        return true
    end

    desc "create", "create an image"

    option :instance,
      aliases: "-i",
      desc: "instance to image",
      required: true

    option :name,
      aliases: "-n",
      desc: "what to name the image",
      required: true

    option :prune,
      aliases: "-p",
      type: :boolean,
      default: true,
      desc: "delete AMIs older than 30 days"

    def create

      s = Automat::Ec2::Image.new(options)
      s.create
      s.prune_amis if options[:prune]
    end

  end
end
