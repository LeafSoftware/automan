require 'automat/base'
require 'automat/ec2/errors'

module Automat::Ec2
  class Instance < Automat::Base
    add_option :environment, :private_key_file

    def password_data(instance_id)
      opts = { instance_id: instance_id }
      response = ec2.client.get_password_data opts

      unless response.successful?
        raise RequestFailedError, "get_password_data failed: #{response.error}"
      end

      response.data[:password_data]
    end

    def decrypt_password(encrypted, private_key)
      pk = OpenSSL::PKey::RSA.new(private_key)
      begin
        decoded = Base64.decode64(encrypted)
        password = pk.private_decrypt(decoded)
      rescue OpenSSL::PKey::RSAError => e
        logger.warn "Decrypt failed: #{e.message}"
        return nil
      end
      password
    end

    def windows_password(instance_id, private_key)
      begin
        encrypted = password_data(instance_id)
      rescue RequestFailedError => e
        logger.warn e.message
        return nil
      end

      if encrypted.nil?
        return nil
      end

      decrypt_password(encrypted, private_key)
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
      ec2.instances.with_tag("Name", "*-#{environment}").each do |i|
        next unless i.status == :running

        tokens = []
        tokens << i.tags.Name
        tokens << i.private_ip_address
        tokens << windows_name(i.private_ip_address)
        if i.platform == "windows"
          tokens << windows_password(i.id, File.read(private_key_file))
        else
          tokens << ""
        end

        data << tokens
      end

      # find longest name tag
      max_name_size = data.max_by {|i| i[0].size }.first.size
      data.map {|i| i[0] = i[0].ljust(max_name_size) }

      data.each do |i|
        puts i.join("\t")
      end
    end
  end
end