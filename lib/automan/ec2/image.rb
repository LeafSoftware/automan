require 'automan/base'
require 'automan/ec2/errors'

module Automan::Ec2
  class Image < Automan::Base
    add_option :instance, :name, :prune

    include Automan::Mixins::Utils

    def initialize(options=nil)
      super
      @wait = Wait.new({
        delay: 5,
        attempts: 24, # 24 x 5s == 2m
        debug: true,
        rescuer:  WaitRescuer.new,
        logger:   @logger
      })
    end

    def find_inst
      inst = nil
      if !instance.nil?
        inst = ec2.instances[instance]
      end
      inst
    end

    def create
      inst = find_inst
      myname = default_image_name
      logger.info "Creating image #{myname} for #{inst.id}"
      newami = ec2.images.create(instance_id: instance, name: myname, no_reboot: true)
      if prune == true
        set_prunable(newami)
      end
    end

    def is_more_than_month_old?(mytime)
      if mytime.class == Time && mytime < Time.now.utc - (60*60*24*30)
        true
      else
        false
      end
    end

    def default_image_name
      stime = Time.new.iso8601.gsub(/:/, '-')
      return name + "-" + stime
    end

    def image_snapshot_exists?(image)
      !image_snapshot(image).nil?
    end

    def image_snapshot(image)
      image.block_devices.each do |device|
        if !device.nil? &&
           !device[:ebs].nil? &&
           !device[:ebs][:snapshot_id].nil?

          return device[:ebs][:snapshot_id]
        end
      end
      nil
    end

    def set_prunable(newami)
      logger.info "Setting prunable for AMI #{newami.image_id}"
      newami.tags["CanPrune"] = "yes"

      wait.until do
        logger.info "Waiting for a valid snapshot so we can tag it."
        image_snapshot_exists? newami
      end

      snapshot = image_snapshot(newami)
      logger.info "Setting prunable for snapshot #{snapshot}"
      ec2.snapshots[snapshot].tags["CanPrune"] = "yes"
    end

    def my_images
      ec2.images.with_owner('self')
    end

    def deregister_images(snaplist)
      my_images.each do |image|
        my_snapshot = image_snapshot(image)

        next unless snaplist.include?(my_snapshot)

        if image.state != :available
          logger.warn "AMI #{image.id} could not be deleted because its state is #{image.state}"
          next
        end

        if image.tags["CanPrune"] == "yes"
          logger.info "Deregistering AMI #{image.id}"
          image.delete
        end
      end
    end

    def delete_snapshots(snaplist)
      snaplist.each do |snap|
        if snap.status != :completed
          logger.warn "Snapshot #{snap.id} could not be deleted because its status is #{snap.status}"
          next
        end

        logger.info "Deleting snapshot #{snap.id}"
        snap.delete
      end

    end

    def prune_amis
      condemned_snaps = []
      allsnapshots = ec2.snapshots.with_owner('self')
      allsnapshots.each do |onesnapshot|
        next unless onesnapshot.status == :completed

        mycreatetime = onesnapshot.start_time
        if is_more_than_month_old?(mycreatetime) and onesnapshot.tags["CanPrune"] == "yes"
          logger.info "Adding snapshot #{onesnapshot.id} to condemed list"
          condemned_snaps.push onesnapshot
        end
      end

      unless condemned_snaps.empty?
        deregister_images condemned_snaps.map {|s| s.id }
        delete_snapshots  condemned_snaps
      end
    end

  end
end