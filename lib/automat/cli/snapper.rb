require 'thor'
require 'automat'
require 'time'

module Automat::Cli
  class Snapper < Thor
    def self.exit_on_failure?
        return true
    end

    desc "create", "create a snapshot"

    option :name,
      aliases: "-n",
      desc: "what to name the snapshot"

    option :database,
      aliases: "-d",
      desc: "name of the database to snapshot"

    option :environment,
      aliases: "-e",
      desc: "environment of database to snapshot"

    option :enable_pruning,
      aliases: "-p",
      type: :boolean,
      default: true,
      desc: "delete snapshots older than 30 days"

    def create
      if options[:database].nil? && options[:environment].nil?
        puts "Must specify either database or environment"
        help "create"
        exit 1
      end

      stime=Time.new.iso8601.gsub(/:/,'-')

      if options[:name].nil?
        if options[:environment].nil?
          options[:name]="#{options[:database]}-#{stime}"
        else
          options[:name]="#{options[:environment]}-#{stime}"
        end
      end

      s = Automat::RDS::Snapshot.new(options)
      s.create
      s.prune if options[:enable_pruning]
    end

    desc "delete", "delete a snapshot"

    option :name,
      required: true,
      aliases: "-n",
      desc: "name of snapshot to delete"

    def delete
      Automat::RDS::Snapshot.new(options).delete
    end

    desc "latest", "find the most recent snapshot"

    option :database,
      aliases: "-d",
      desc: "name of the database to snapshot"

    option :environment,
      aliases: "-e",
      desc: "environment of database to snapshot"

    def latest
      if options[:database].nil? && options[:environment].nil?
        puts "Must specify either database or environment"
        help "latest"
        exit 1
      end

      Automat::RDS::Snapshot.new(options).latest
    end

  end
end
