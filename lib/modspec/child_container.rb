# frozen_string_literal: true

module Modspec
  module ChildContainer
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def validates_children(collection_name, empty_label:, child_label:)
        define_method(:validate_children_presence) do
          children = send(collection_name)
          if children.nil? || children.empty?
            ["#{empty_label} #{identifier} has no child #{child_label}"]
          else
            []
          end
        end

        define_method(:validate_children_identifier_prefix) do
          children = send(collection_name)
          return [] unless children

          expected_prefix = "#{identifier}/"
          children.filter_map do |child|
            unless child.identifier.to_s.start_with?(expected_prefix)
              msg = "#{child_label} #{child.identifier} "
              msg += "does not share the expected prefix #{expected_prefix}"
              msg
            end
          end
        end
      end
    end
  end
end
