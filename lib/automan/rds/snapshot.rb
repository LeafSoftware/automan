require 'automan'
require 'time'
require 'wait'

module Automan::RDS
  class Snapshot < Automan::Base
    add_option :database,
               :name,
               :environment,
               :prune,
               :type,
               :max_snapshots,
               :quiet,
               :wait_for_completion

    def initialize(options={})
      @prune = true
      @wait_for_completion = false
      @max_snapshots = 50
      super
      @wait = Wait.new({
        delay: 30,
        attempts: 20, # 20 x 30s == 10m
        debug: true,
        rescuer:  WaitRescuer.new(),
        logger:   @logger
      })

      # DEPRECATED: use --max-snapshots instead
      if ENV['MAX_SNAPSHOTS']
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
      AWS.memoize do
        rds.db_instances[find_db.id].snapshots.count
      end
    end

    def create
      log_options

      db = find_db

      if db.nil? || !db.exists?
        if quiet
          logger.warn "Database for #{environment} does not exist"
          exit
        else
          raise DatabaseDoesNotExistError, "Database for #{environment} does not exist"
        end
      end

      myname = name.nil? ? default_snapshot_name(db) : name.dup

      wait_until_database_available(db)

      logger.info "Creating snapshot #{myname} for #{db.id}"
      snap = db.create_snapshot(myname)

      if prune == true
        logger.info "Setting snapshot to be prunable and tagging environment"
        set_prunable_and_env(snap)
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
      return db_tags(db)['Name']
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
    def set_prunable_and_env(snapshot)
      opts = {
        resource_name: snapshot_arn(snapshot),
        tags: [
          { key: 'CanPrune',    value: 'yes'},
          { key: 'Environment', value: environment},
          { key: 'Type',        value: type }
        ]
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

    def db_tags(db)
      arn = db_arn(db)
      resource_tags(arn)
    end

    def snapshot_tags(snapshot)
      arn = snapshot_arn(snapshot)
      resource_tags(arn)
    end

    def resource_tags(arn)
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

    def available?(snapshot)
      snapshot.status == 'available'
    end

    def get_all_snapshots
      rds.snapshots
    end

    # tags = {'mytagkey' => 'mytagvalue', ...}
    def snapshot_has_tags?(snapshot, tags)
      snap_tags = snapshot_tags(snapshot)
      tags.each do |tk,tv|
        if snap_tags[tk] != tv
          #logger.info("qtags: #{tags.to_json} snap_tags: #{snap_tags.to_json}")
          return false
        end
      end
      true
    end

    # tags = {'mytagkey' => 'mytagvalue', ...}
    def snapshots_with_tags(tags)
      rds.snapshots.select {|s| snapshot_has_tags?(s, tags)}
    end

    def prune_snapshots
      logger.info "Pruning old db snapshots"

      tags = {
        'Environment' => environment,
        'Type'        => type,
        'CanPrune'    => 'yes'
      }
      sorted_snaps = nil
      AWS.memoize do
        sorted_snaps = snapshots_with_tags(tags).sort_by {|s| s.created_at}
      end

      logger.info "snaps #{sorted_snaps.count} max #{max_snapshots}"

      if sorted_snaps.count >= max_snapshots
        logger.info "Too many snapshots ( #{sorted_snaps.count} >= #{max_snapshots})."
        number_to_delete = sorted_snaps.count - max_snapshots + 1
        logger.info "deleting #{number_to_delete}."

        condemned = sorted_snaps.take(number_to_delete)
        condemned.each do |snap|
          logger.info "Deleting #{snap.id}"
          snap.delete
        end
      end
    end

    def count_snapshots
      log_options
      db = find_db
      if db.nil?
        logger.info "Database not found"
      else
        logger.info "Number of snapshots for database #{db.id} is #{snapshot_count}"
        logger.info "Number of prunable snapshots for database #{db.id} is #{prunable_snapshots.count}"
      end
    end

    def latest
      log_options
      logger.info "Finding most recent snapshot for #{environment}"

      tags = { 'Environment' => environment }
      s = snapshots_with_tags(tags).sort_by {|s| s.created_at}.last

      logger.info "Most recent snapshot is #{s.id}"
      s.id
    end
  end
end
