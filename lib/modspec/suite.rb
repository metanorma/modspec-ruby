require "shale"

module Modspec
  class Suite < Shale::Mapper
    attribute :identifier, Identifier
    attribute :name, Shale::Type::String
    attribute :normative_statements_classes, NormativeStatementsClass, collection:true
    attribute :conformance_classes, ConformanceClass, collection:true

    xml do
      root "suite"
      map_attribute "identifier", to: :identifier
      map_element "name", to: :name
      map_element "normative-statements-classes", to: :normative_statements_classes
      map_element "conformance-classes", to: :conformance_classes
    end
  end
end
