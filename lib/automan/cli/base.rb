require 'thor'

module Automan::Cli
  class Base < Thor
    def self.exit_on_failure?
        return true
    end

    desc "version", "Show version"
    def version
      say Automan::VERSION
    end
  end
end