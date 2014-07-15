module Automat::Mixins
  module Utils

    def region_from_az(availability_zone)
      availability_zone[0..-2]
    end

    class ::String
      def underscore
        self.gsub(/::/, '/').
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr("-", "_").
        downcase
      end
    end
  end
end
