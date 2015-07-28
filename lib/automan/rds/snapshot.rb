require 'automan'
require 'time'
require 'wait'

# TODO: wait to convert RDS to aws-sdk-v2
# The resources just aren't there yet.

module Automan::RDS
  class Snapshot < Automan::Base
    add_option :database,
               :name,
               :environment,
               :prune,
               :wait_for_completion

    attr_accessor :max_snapshots

    def initialize(options={})
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

      if ENV['MAX_SNAPSHOTS'].nil?
        @max_snapshots = 50
      else
        @max_snapshots = ENV['MAX_SNAPSHOTS'].to_i
      end
    end

    include Automan::Mixins::Utils

    # TODO move this and dependecies to an RDS utils class
    # so we can re-use it
    def find_db
      db = nil
      if !database.nil?
        db = rds.db_instances[database]
      elsif !environment.nil?
        db = find_db_by_environment(environment)
      end
      db
    end

    def database_available?(database)
      database.db_instance_status == 'available'
    end

    def wait_until_database_available(database)
      state_wait = Wait.new({
        delay:    10,
        attempts: 20,
        debug:    true,
        rescuer:  WaitRescuer.new(),
        logger:   @logger
      })

      state_wait.until do
        logger.info "Waiting for database #{database.id} to be available"
        database_available?(database)
      end
    end

    def snapshot_count
      rds.db_instances[database].snapshots.count
    end

    def create
      log_options

      db = find_db

      if db.nil? || !db.exists?
        raise DatabaseDoesNotExistError, "Database for #{environment} does not exist"
      end

      myname = name.nil? ? default_snapshot_name(db) : name.dup

      wait_until_database_available(db)

      if snapshot_count >= max_snapshots
        logger.info "Too many snapshots (>= #{max_snapshots}), deleting oldest prunable."
        old = nil
        AWS.memoize do
          old = oldest_prunable_snapshot
        end
        logger.info "Deleting #{old.id}"
        old.delete
      end

      logger.info "Creating snapshot #{myname} for #{db.id}"
      snap = db.create_snapshot(myname)

      if prune == true
        logger.info "Setting snapshot to be prunable and tagging environment"
        set_prunable_and_env(snap,environment)
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
      stime = Time.new.strftime("%Y-%m-%dT%H-%M")

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
    def set_prunable_and_env(snapshot,environment)
      opts = {
        resource_name: snapshot_arn(snapshot),
        tags: [ {key: 'CanPrune', value: 'yes'}, {key: 'Environment', value: environment} ]
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

    def can_prune?(snapshot)
      tagged_can_prune?(snapshot) && available?(snapshot) && manual?(snapshot)
    end

    def is_env?(snapshot,environment)
      tagged_env?(snapshot,environment) && available?(snapshot) && manual?(snapshot)
    end

    def tagged_env?(snapshot,environment)
      arn = snapshot_arn(snapshot)
      tags(arn)['Environment']  == environment
    end

    def tagged_can_prune?(snapshot)
      arn = snapshot_arn(snapshot)
      tags(arn)['CanPrune']  == 'yes'
    end

    def available?(snapshot)
      snapshot.status == 'available'
    end

    def manual?(snapshot)
      snapshot.snapshot_type == 'manual'
    end

    # older than a month?
    def too_old?(time)
      time.utc < (Time.now.utc - 60*60*24*30)
    end

    def get_all_snapshots
      rds.db_snapshots
    end

    def prunable_snapshots
      snapshots = get_all_snapshots
      snapshots.select { |s| can_prune?(s) }
    end

    def oldest_prunable_snapshot
      prunable_snapshots.sort_by { |s| s.created_at }.first
    end

    def prune_snapshots
      logger.info "Pruning old db snapshots"

      AWS.memoize do
        prunable_snapshots.each do |snapshot|

          timestamp = snapshot.created_at
          snapshot_name = snapshot.db_snapshot_identifier

          if too_old?(timestamp)
            logger.info "Deleting #{snapshot_name} because it is too old."
            snapshot.delete
          end
        end
      end
    end

    def latest
      log_options
      logger.info "Finding most recent snapshot for #{environment}"

      allsnaps=get_all_snapshots

      envsnaps=[]
      allsnaps.each do |onesnap|
        if is_env?(onesnap,environment)
          envsnaps.push(onesnap)
        end
      end

      s=envsnaps.sort_by {|i| i.created_at }.last
      logger.info "Most recent snapshot is #{s.id}"
      s.id
    end
  end
end
