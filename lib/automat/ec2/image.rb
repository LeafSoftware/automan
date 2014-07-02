require 'automat/base'
require 'automat/ec2/errors'

module Automat::Ec2
  class Image < Automat::Base
    add_option :instance, :name, :prune

    include Automat::Mixins::Utils

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
      newami=ec2.images.create(:instance_id=>instance,:name=>myname,:no_reboot=>true)
      if prune == true
        set_prunable(newami)
      end
    end

    def is_more_than_month_old?(mytime)
      if mytime.class == Time && mytime<Time.now.utc-(60*60*24*30)
        true
      else
        false
      end
    end

    def default_image_name()
      stime = Time.new.iso8601.gsub(/:/,'-')
      return name + "-" + stime
    end

    def check_for_ebs(block_devices)
      block_devices.each do |device|
        if (!device.nil? && !device[:ebs].nil? && !device[:ebs][:snapshot_id].nil?)
          return true
        end
      end
      return false
    end

    def set_prunable(newami)
      logger.info "setting prunable for AMI #{newami.image_id}"
      newami.tags["CanPrune"]="yes"
      until check_for_ebs(newami.block_devices)
        logger.info "waiting 5sec for a valid snapshot so that we can tag it"
        sleep 5
      end
      newami.block_devices.each do |device|
        if device[:ebs]
          logger.info "setting prunable for snapshot #{ec2.snapshots[device[:ebs][:snapshot_id]].id}"
          ec2.snapshots[device[:ebs][:snapshot_id]].tags["CanPrune"]="yes"
        end
      end
    end

    def deregister_images(snaplist)
      my_images=ec2.images.with_owner('self')
      my_images.each do |oneimage|
        next unless oneimage.state == :available
        if oneimage.tags["CanPrune"]=="yes" and snaplist.include?(oneimage.block_devices[0][:ebs][:snapshot_id])
          logger.info "deregistering AMI #{oneimage.id}"
          oneimage.delete
        end
      end
    end

    def delete_snapshots(snaplist)
      allsnapshots=ec2.snapshots.with_owner('self')
      allsnapshots.each do |onesnapshot|
        next unless onesnapshot.status == :completed
        if snaplist.include?(onesnapshot.id)
          logger.info "deleting snapshot #{onesnapshot.id}"
          onesnapshot.delete
        end
      end
    end

    def prune_amis()
      condemnedsnaps=[]
      allsnapshots=ec2.snapshots.with_owner('self')
      allsnapshots.each do |onesnapshot|
        next unless onesnapshot.status == :completed
        mycreatetime=onesnapshot.start_time
        if is_more_than_month_old?(mycreatetime) and onesnapshot.tags["CanPrune"]=="yes"
          logger.info "adding snapshot #{onesnapshot.id} to condemed list"
          condemnedsnaps.push(onesnapshot.id)
        end
      end
      if !condemnedsnaps.empty?
        deregister_images(condemnedsnaps)
        delete_snapshots(condemnedsnaps)
      end
    end

  end
end