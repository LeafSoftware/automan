require 'thor'
require 'automat'

module Automat::Cli
  class Snapper < Thor
    desc "create", "create a snapshot"

    option :name,
      required: true,
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

  end
end