require "lutaml/model"

module Modspec
  class Suite < Lutaml::Model::Serializable
    attribute :identifier, Identifier
    attribute :name, :string
    attribute :normative_statements_classes, NormativeStatementsClass, collection: true
    attribute :conformance_classes, ConformanceClass, collection: true

    xml do
      root "suite"
      map_attribute "identifier", to: :identifier
      map_element "name", to: :name
      map_element "normative-statements-classes", to: :normative_statements_classes
      map_element "conformance-classes", to: :conformance_classes
    end
  end
end
