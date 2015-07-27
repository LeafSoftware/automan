require 'automan/base'
require 'automan/ec2/errors'

module Automan::Ec2
  class Image < Automan::Base
    add_option :instance, :name, :prune

    include Automan::Mixins::Utils

    def initialize(options={})
      super
      @wait = Wait.new({
        delay: 5,
        attempts: 24, # 24 x 5s == 2m
        debug: true,
        rescuer:  WaitRescuer.new,
        logger:   @logger
      })
    end

    def create
      image_name = default_image_name

      logger.info "Creating image #{myname} for #{instance}"
      # TODO: verify instance exists
      inst = ec2.instance(instance)

      image = inst.create_image({
        name: image_name,
        no_reboot: true
      })

      set_prunable(image) if prune
    end

    def is_more_than_month_old?(mytime)
      if mytime.class == Time && mytime < Time.now.utc - (60*60*24*30)
        true
      else
        false
      end
    end

    def default_image_name
      stime = Time.now.utc.iso8601.gsub(/:/, '')
      return name + "-" + stime
    end

    def image_snapshot_exists?(image_id)
      !image_snapshot(image_id).nil?
    end

    # HACK: assumes one block device on the image
    def image_snapshot(image_id)
      image = ec2.image(image_id)
      bdm = image.block_device_mappings.first

      if !bdm.nil? && !bdm.ebs.nil? && !bdm.ebs.snapshot_id.nil?
        return bdm.ebs.snapshot_id
      end

      nil
    end

    def set_prunable(image)
      logger.info "Setting prunable for AMI #{image.image_id}"
      image.create_tags({
        tags: [
          { key: 'CanPrune', value: 'yes' }
        ]
      })

      wait.until do
        logger.info "Waiting for a valid snapshot so we can tag it."
        image_snapshot_exists? image.id
      end

      snapshot = image_snapshot(image.id)
      logger.info "Setting prunable for snapshot #{snapshot}"
      snapshot.create_tags({
        tags: [
          { key: 'CanPrune', value: 'yes' }
        ]
      })
    end

    def my_images
      ec2.images(owners: ['self'])
    end

    def deregister_images(snaplist)
      my_images.each do |image|
        my_snapshot = image_snapshot(image.id)

        next unless snaplist.include?(my_snapshot)

        if image.state != 'available'
          logger.warn "AMI #{image.id} could not be deleted because its state is #{image.state}"
          next
        end

        if image.tags.include?({key: 'CanPrune', value: 'yes'})
          logger.info "Deregistering AMI #{image.id}"
          image.deregister
        end
      end
    end

    def delete_snapshots(snaplist)
      snaplist.each do |snap|
        if snap.state != 'completed'
          logger.warn "Snapshot #{snap.id} could not be deleted because its status is #{snap.state}"
          next
        end

        logger.info "Deleting snapshot #{snap.id}"
        snap.delete
      end

    end

    def prune_amis
      condemned_snaps = []
      allsnapshots = ec2.snapshots(owner_ids: ['self'])
      allsnapshots.each do |onesnapshot|
        next unless onesnapshot.state == 'completed'

        mycreatetime = onesnapshot.start_time
        if is_more_than_month_old?(mycreatetime) and onesnapshot.tags.include?({name: "CanPrune", value: "yes"})
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