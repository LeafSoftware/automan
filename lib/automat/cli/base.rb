require 'thor'

module Automat::Cli
  class Base < Thor
    def self.exit_on_failure?
        return true
    end

    desc "version", "Show version"
    def version
      say Automat::VERSION
    end
  end
end