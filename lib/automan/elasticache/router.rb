require 'automan'

module Automan::ElastiCache
  class Router < Automan::Base

    add_option :environment,
    :hosted_zone_name,
    :redis_host

    def node_name_from_elasticache_environment(env)

      opts = {
        cache_cluster_id: "redis-#{env}",
        show_cache_node_info: true
      }

      response = ec.client.describe_cache_clusters opts

      unless response.successful?
        raise RequestFailedError, "describe_cache_clusters failed: #{response.error}"
      end

      cluster=response.data[:cache_clusters]
      if cluster.empty?
        return nil
      end

      nodes=Hash[*cluster][:cache_nodes]
      if nodes.empty?
        return nil
      end

      endpoint=Hash[*nodes][:endpoint]
      if endpoint.empty?
        return nil
      end

      endpoint[:address]
    end

    # be sure alias_name ends in period
    def update_dns_alias(zone_name, redis_cname, primary_endpoint)
      zone = r53.hosted_zones.select {|z| z.name == zone_name}.first
      rrset = zone.rrsets[redis_cname + '.', 'CNAME']

      if rrset.exists?
        if rrset.alias_target[:dns_name] == primary_endpoint + '.'
          logger.info "record exists: #{redis_cname} -> #{rrset.alias_target[:dns_name]}"
          return
        else
          logger.info "removing old record #{redis_cname} -> #{rrset.alias_target[:dns_name]}"
          rrset.delete
        end
      end

      logger.info "creating record #{redis_cname} -> #{primary_endpoint}"
      zone.rrsets.create(
        redis_cname + '.',
        'CNAME',
        :ttl => 300,
        :resource_records => [{:value => primary_endpoint}]
        )
    end

    def run
      log_options

      logger.info "getting redis primary node name..."
      primary_endpoint = node_name_from_elasticache_environment environment

      if primary_endpoint.nil?
        false
      else
        update_dns_alias(
          hosted_zone_name,
          redis_host,
          primary_endpoint
          )
        true
      end
    end
  end
end
