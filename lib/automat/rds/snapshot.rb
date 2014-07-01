require 'automat/base'
require 'automat/rds/errors'
require 'time'
require 'wait'

module Automat::RDS
  class Snapshot < Automat::Base
    add_option :database,
               :name,
               :environment,
               :prune,
               :wait_for_completion

    def initialize(options=nil)
      @prune = true
      @wait_for_completion = false
      super
      @wait = Wait.new({
        delay: 30,
        attempts: 20, # 20 x 30s == 10m
        debug: true,
        rescuer:  WaitRescuer.new(),
        logger:   @logger
      })
    end

    include Automat::Mixins::Utils

    def find_db
      db = nil
      if !database.nil?
        db = rds.db_instances[database]
      elsif !environment.nil?
        db = find_db_by_environment(environment)
      end
      db
    end

    def create
      log_options

      db = find_db

      myname = name.nil? ? default_snapshot_name(db) : name.dup

      self.log_aws_calls = true
      self.rds = AWS::RDS.new
      logger.info "Creating snapshot #{myname} for #{db.id}"
      snap = db.create_snapshot(myname)

      if prune == true
        logger.info "Setting snapshot to be prunable"
        set_prunable(snap)
      end

      if wait_for_completion == true
        wait.until do
          logger.info "Waiting for snapshot to complete..."
          snapshot_finished?(snap)
        end
        logger.info "Snapshot finished (or timed out)."
      end
    end

    def snapshot_finished?(snapshot)
      unless snapshot.exists?
        return false
      end
      snapshot.status == "available"
    end

    def db_environment(db)
      arn = db_arn(db)
      return tags(arn)['Name']
    end

    def default_snapshot_name(db)
      env   = db_environment db
      stime = Time.new.iso8601.gsub(/:/,'-')

      return env + "-" + stime
    end

    def find_db_by_environment(environment)
      rds.db_instances.each do |db|
        if db_environment(db) == environment
          return db
        end
      end
      return nil
    end

    def db_arn(database)
      region = region_from_az(database.availability_zone_name)
      "arn:aws:rds:#{region}:#{account}:db:#{database.id}"
    end

    def snapshot_arn(snapshot)
      region = region_from_az(snapshot.availability_zone_name)
      "arn:aws:rds:#{region}:#{account}:snapshot:#{snapshot.id}"
    end

    # tag with CanPrune
    def set_prunable(snapshot)
      opts = {
        resource_name: snapshot_arn(snapshot),
        tags: [ {key: 'CanPrune', value: 'yes'} ]
      }
      response = rds.client.add_tags_to_resource opts

      unless response.successful?
        raise RequestFailedError "add_tags_to_resource failed: #{response.error}"
      end
    end

    def delete
      log_options

      logger.info "Deleting snapshot #{name}"
      rds.db_snapshots[name].delete
    end

    def tags(arn)
      opts = {
        resource_name: arn
      }
      response = rds.client.list_tags_for_resource opts

      unless response.successful?
        raise RequestFailedError "list_tags_for_resource failed: #{response.error}"
      end

      result = {}
      response.data[:tag_list].each do |t|
        result[ t[:key] ] = t[:value]
      end
      result
    end

    def can_prune?(snapshot_name)
      arn = snapshot_arn(snapshot_name)
      tags(arn)['CanPrune'] == 'yes'
    end

    # older than a month?
    def too_old?(time)
      time.utc < (Time.now.utc - 60*60*24*30)
    end

    def prune_snapshots
      logger.info "Pruning old db snapshots"

      snapshots = rds.db_instances[database].snapshots
      snapshots.each do |snapshot|

        next unless snapshot.status == 'available'

        timestamp = snapshot.created_at
        snapshot_name = snapshot.db_snapshot_identifier

        if too_old?(timestamp) && can_prune?(snapshot_name)
          logger.info "Deleting #{snapshot_name} because it is too old."
          snapshot.delete
        end
      end
    end

    def latest
      log_options
      db = find_db
      logger.info "Finding most recent snapshot for #{db.id}"
      s = db.snapshots.sort_by {|i| i.created_at }.last
      logger.info "Most recent snapshot is #{s.id}"
    end
  end
end