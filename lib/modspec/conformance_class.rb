require "lutaml/model"
require_relative "conformance_test"
require_relative "identifier"

module Modspec
  class ConformanceClass < Lutaml::Model::Serializable
    attribute :identifier, Identifier
    attribute :name, :string
    attribute :description, :string
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
      map_element "reference", to: :reference
    end
  end
end
