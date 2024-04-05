require "shale"
require_relative "./identifier"

module Modspec

  class ConformanceTest < Shale::Mapper
    attribute :identifier, Identifier
    attribute :name, Shale::Type::String
    attribute :dependencies, Identifier, collection: true
    attribute :targets, Identifier, collection: true
    attribute :belongs_to, Identifier, collection: true
    attribute :description, Shale::Type::String
    attribute :guidance, Shale::Type::String, collection: true
    attribute :purpose, Shale::Type::String
    attribute :method, Shale::Type::String # Inspection, etc.
    attribute :type, Shale::Type::String
    attribute :reference, Shale::Type::String
    attribute :abstract, Shale::Type::Boolean

    xml do
      root "conformance-test"
      map_attribute "identifier", to: :identifier
      map_attribute "abstract", to: :abstract
      map_element "name", to: :name
      map_element "targets", to: :targets
      map_element "dependencies", to: :dependencies
      map_element "belongs_to", to: :belongs_to
      map_element "description", to: :description
      map_element "guidance", to: :guidance
      map_element "purpose", to: :purpose
      map_element "method", to: :method
      map_element "type", to: :type
      map_element "reference", to: :reference
    end
  end

end
