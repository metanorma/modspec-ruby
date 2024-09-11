# frozen_string_literal: true

require "lutaml/model"
require_relative "conformance_test"
require_relative "identifier"

module Modspec
  class ConformanceClass < Lutaml::Model::Serializable
    attribute :identifier, Identifier
    attribute :name, :string
    attribute :description, :string
    attribute :guidance, :string, collection: true
    attribute :classification, :string
    attribute :dependencies, Identifier, collection: true
    attribute :target, Identifier, collection: true
    attribute :tests, ConformanceTest, collection: true
    attribute :belongs_to, Identifier, collection: true
    attribute :reference, :string

    xml do
      root "conformance-class"
      map_attribute "identifier", to: :identifier
      map_element "name", to: :name
      map_element "dependencies", to: :dependencies
      map_element "target", to: :target
      map_element "classification", to: :classification
      map_element "tests", to: :tests
      map_element "belongs_to", to: :belongs_to
      map_element "description", to: :description
      map_element "guidance", to: :guidance
      map_element "reference", to: :reference
    end

    def validate
      errors = super()
      errors.concat(validate_identifier_prefix)
      errors.concat(validate_class_children_mapping)
      errors.concat(tests.flat_map(&:validate))
      errors
    end

    private

    def validate_class_children_mapping
      if tests.empty?
        ["Conformance class #{identifier} has no child conformance tests"]
      else
        []
      end
    end

    def validate_identifier_prefix
      errors = []
      expected_prefix = "#{identifier}/"
      tests.each do |test|
        unless test.identifier.to_s.start_with?(expected_prefix)
          errors << "Conformance test #{test.identifier} does not share the expected prefix #{expected_prefix}"
        end
      end
      errors
    end
  end
end
