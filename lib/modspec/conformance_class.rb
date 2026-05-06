# frozen_string_literal: true

require "lutaml/model"

module Modspec
  class ConformanceClass < Lutaml::Model::Serializable
    include ChildContainer

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

    validates_children :tests, empty_label: "Conformance class",
                               child_label: "conformance tests"

    xml do
      element "conformance-class"
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
      errors = super
      errors.concat(validate_children_identifier_prefix)
      errors.concat(validate_children_presence)
      errors.concat(tests.flat_map(&:validate))
      errors
    end
  end
end
