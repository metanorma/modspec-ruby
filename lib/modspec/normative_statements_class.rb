require "shale"
require_relative "./normative_statement"
require_relative "./identifier"

module Modspec

  class NormativeStatementsClass < Shale::Mapper
    attribute :identifier, Identifier
    attribute :name, Shale::Type::String
    attribute :description, Shale::Type::String
    attribute :subject, Shale::Type::String
    attribute :guidance, Shale::Type::String
    attribute :dependencies, Identifier, collection: true
    attribute :normative_statements, NormativeStatement, collection: true
    attribute :belongs_to, Identifier, collection: true
    attribute :reference, Shale::Type::String
    attribute :source, Shale::Type::String

    xml do
      root "normative-statements-class"
      map_attribute "identifier", to: :identifier
      map_element "name", to: :name
      map_element "description", to: :description
      map_element "subject", to: :subject
      map_element "guidance", to: :guidance
      map_element "dependencies", to: :dependencies
      map_element "normative-statements", to: :normative_statements
      map_element "belongs_to", to: :belongs_to
      map_element "reference", to: :reference
      map_element "source", to: :source
    end
  end

end
