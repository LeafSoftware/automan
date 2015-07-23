require 'automan'

# TODO: this has too many assumptions about customer env

module Automan::ElastiCache
  class Router < Automan::Base

    add_option :environment,
      :hosted_zone_name,
      :redis_host

    def node_name_from_elasticache_environment(env)

      response = ec.describe_cache_clusters({
        cache_cluster_id: "redis-#{env}",
        show_cache_node_info: true
      })

      unless response.successful?
        raise RequestFailedError, "describe_cache_clusters failed: #{response.error}"
      end

      return nil if response.cache_clusters.empty?

      # assert only one redis cluster for this env
      if response.cache_clusters > 1
        raise TooManyRedisClusters, "Too many redis clusters for env: #{env}"
      end

      nodes = response.cache_clusters.first.cache_nodes

      return nil if nodes.empty?

      # assert only one redis node in the cluster
      if nodes > 1
        raise TooManyRedisNodes, "Too many redis nodes in cluster for env: #{env}"
      end

      logger.info "found redis endpoint at #{node.endpoint.address}"
      node.endpoint.address
    end

    # be sure alias_name ends in period
    def update_dns_alias(zone_name, redis_cname, primary_endpoint)
      zone = r53.hosted_zones.select {|z| z.name == zone_name}.first
      rrset = zone.rrsets[redis_cname + '.', 'CNAME']

      if rrset.exists?
        logger.info "removing old record at #{redis_cname}"
        rrset.delete
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
