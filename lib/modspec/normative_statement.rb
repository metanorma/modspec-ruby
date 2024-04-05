require "shale"
require_relative "./identifier"

module Modspec
  class NormativeStatementPart < Shale::Mapper
    attribute :statement, Shale::Type::String
  end

  class NormativeStatement < Shale::Mapper
    attribute :identifier, Identifier
    attribute :name, Shale::Type::String
    attribute :subject, Shale::Type::String
    attribute :statement, Shale::Type::String
    attribute :condition, Shale::Type::String
    attribute :guidance, Shale::Type::String
    attribute :inherit, Identifier, collection: true
    attribute :indirect_dependency, Identifier, collection: true
    attribute :implements, Identifier, collection: true
    attribute :dependencies, Identifier, collection: true
    attribute :belongs_to, Identifier, collection: true
    attribute :reference, Shale::Type::String
    attribute :parts, NormativeStatementPart, collection:true

    # in the future validate: recommendation, permission, requirement
    attribute :obligation, Shale::Type::String

    xml do
      root "normative-statement"
      map_attribute "identifier", to: :identifier
      map_element "name", to: :name
      map_element "subject", to: :subject
      map_element "statement", to: :statement
      map_element "condition", to: :condition
      map_element "guidance", to: :guidance
      map_element "inherit", to: :inherit
      map_element "indirect-dependency", to: :indirect_dependency
      map_element "implements", to: :implements
      map_element "dependencies", to: :dependencies
      map_element "belongs_to", to: :belongs_to
      map_element "reference", to: :reference
      map_element "obligation", to: :obligation
      map_element "parts", to: :parts
    end
  end

end
