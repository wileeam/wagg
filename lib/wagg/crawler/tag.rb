# encoding: utf-8

module Wagg
  module Crawler
    class Tag
      attr_reader :name

      def initialize(name)
        @name = name
      end

      def to_s
        "TAG : %{n}" % {n:@name}
      end

    end
  end
end