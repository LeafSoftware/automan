require 'json'
require 'cloudformation-ruby-dsl/cfntemplate'

module <%= @app_name.split('_').map {|x| x.capitalize}.join('') %>
  module Helpers

    def includes_path
      cwd = File.expand_path(File.dirname(__FILE__))
      File.join(cwd, '..', '..', 'includes')
    end

    def templates_path
      cwd = File.expand_path(File.dirname(__FILE__))
      File.join(cwd, '..', '..', 'templates')
    end

    def include_file(filename, locals={})
      cwd = File.expand_path(File.dirname(__FILE__))
      path = File.join( includes_path, filename )
      interpolate(file(path), locals)
    end

    def add_environment_map
      environment_map = 'environment_map.rb'
      mapping 'EnvironmentMap', File.join(includes_path, environment_map)
    end

    def find_in_env(name)
      find_in_map('EnvironmentMap', ref('Environment'), name)
    end

    def write_template(name, template)
      path = File.join(templates_path, "#{name}.json")
      $stderr.puts "Writing template to #{File.realdirpath(path)}"
      File.open(path, 'w') do |file|
        file.puts(JSON.pretty_generate(template))
      end
    end

    def write_parameter_mappings(name, mappings)
      path = File.join(templates_path, "#{name}.parameters")
      $stderr.puts "Writing parameters to #{File.realdirpath(path)}"
      File.open(path, 'w') do |file|
        file.puts(mappings.join(' '))
      end
    end
  end
end
