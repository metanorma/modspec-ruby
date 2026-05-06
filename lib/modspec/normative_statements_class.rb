# frozen_string_literal: true

require "lutaml/model"

module Modspec
  class NormativeStatementsClass < Lutaml::Model::Serializable
    include ChildContainer

    attribute :identifier, Identifier
    attribute :name, :string
    attribute :description, :string
    attribute :subject, :string
    attribute :guidance, :string, collection: true
    attribute :dependencies, Identifier, collection: true
    attribute :implements, Identifier, collection: true
    attribute :normative_statements, NormativeStatement, collection: true
    attribute :belongs_to, Identifier, collection: true
    attribute :reference, :string
    attribute :source, :string

    validates_children :normative_statements, empty_label: "Requirement class",
                                              child_label: "requirements"

    xml do
      element "normative-statements-class"
      map_attribute "identifier", to: :identifier
      map_element "name", to: :name
      map_element "description", to: :description
      map_element "subject", to: :subject
      map_element "guidance", to: :guidance
      map_element "dependencies", to: :dependencies
      map_element "implements", to: :implements
      map_element "normative-statements", to: :normative_statements
      map_element "belongs_to", to: :belongs_to
      map_element "reference", to: :reference
      map_element "source", to: :source
    end

    def validate
      errors = super
      errors.concat(validate_children_identifier_prefix)
      errors.concat(validate_children_presence)
      errors.concat(normative_statements.flat_map(&:validate))
      errors
    end
  end
end
