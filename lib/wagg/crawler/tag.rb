# frozen_string_literal: true

module Wagg
  module Crawler
    class Tag
      # @!attribute [r] name
      #   @return [String] the name of the tag
      attr_reader :name

      def initialize(name, snapshot_timestamp = nil, json_data = nil)
        if json_data.nil?
          @snapshot_timestamp = snapshot_timestamp.nil? ? Time.now.utc : snapshot_timestamp
          @name = name
        else
          @snapshot_timestamp = snapshot_timestamp.nil? ? Time.now.utc : snapshot_timestamp
          @name = json_data.name
        end
      end

      class << self
        def from_json(string)
          os_object = JSON.parse(string, { object_class: OpenStruct, quirks_mode: true })

          # Some validation that we have the right object
          if os_object.type == name.split('::').last
            data = os_object.data

            name = data.name
            snapshot_timestamp = Time.at(os_object.timestamp).utc

            Tag.new(nil, snapshot_timestamp, data)
          end
        end
      end

      def as_json(_options = {})
        {
          type: self.class.name.downcase,
          timestamp: ::Wagg::Utils::Functions.timestamp_to_text(@snapshot_timestamp),
          data: {
            name: @name
          }
        }
      end

      def to_json(*options)
        as_json(*options).to_json(*options)
      end
    end
  end
end
