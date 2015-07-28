require 'automan'

module Automan::Ec2
  class Instance < Automan::Base
    add_option :environment, :private_key_file

    def windows_password(instance_id, private_key)
      pass = nil
      instance = ec2.instance(instance_id)
      begin
        pass = instance.decrypt_windows_password(private_key)
      rescue Aws::EC2::Errors::ServiceError => e
        logger.warn "could not decrypt password for #{instance.id}: #{e.message}"
      end
      pass
    end

    def windows_name(ip_address)
      return nil if ip_address.nil?
      return nil if ip_address.empty?

      quads = ip_address.split('.')
      quad_str = quads.map { |q| q.to_i.to_s(16).rjust(2,'0') }.join('')
      "ip-#{quad_str}"
    end

    def show_env
      data = []
      instances = ec2.instances({
        filters: [
          name: 'tag:Name',
          values: [ "*-#{environment}" ]
        ]
      })
      instances.each do |i|
        next unless i.state.name == 'running'

        tokens = []
        tokens << i.tags.find {|x| x.key == 'Name'}.value
        tokens << i.private_ip_address
        tokens << windows_name(i.private_ip_address)
        if i.platform == "windows"
          tokens << windows_password(i.id, private_key_file)
        else
          tokens << ""
        end

        data << tokens
      end

      return if data.empty?

      # find longest name tag
      max_name_size = data.max_by {|i| i[0].size }.first.size
      data.map {|i| i[0] = i[0].ljust(max_name_size) }

      data.each do |i|
        puts i.join("\t")
      end
    end
  end
end