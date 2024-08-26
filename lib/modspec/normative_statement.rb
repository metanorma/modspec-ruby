# frozen_string_literal: true

require "lutaml/model"
require_relative "identifier"

module Modspec
  class NormativeStatementPart < Lutaml::Model::Serializable
    attribute :statement, :string
  end

  class NormativeStatement < Lutaml::Model::Serializable
    attribute :identifier, Identifier
    attribute :name, :string
    attribute :subject, :string
    attribute :statement, :string
    attribute :condition, :string
    attribute :guidance, :string, collection: true
    attribute :inherit, Identifier, collection: true
    attribute :indirect_dependency, Identifier, collection: true
    attribute :implements, Identifier, collection: true
    attribute :dependencies, Identifier, collection: true
    attribute :belongs_to, Identifier, collection: true
    attribute :reference, :string
    attribute :parts, NormativeStatementPart, collection: true

    # in the future validate: recommendation, permission, requirement
    attribute :obligation, :string,
              values: %w[recommendation permission requirement],
              default: -> { "requirement" }

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

    def validate_all(suite)
      errors = []
      errors.concat(validate_dependencies(suite))
      errors.concat(validate_nested_requirement)
      errors
    end

    private

    def validate_dependencies(suite)
      errors = []
      all_dependencies = (dependencies + indirect_dependency + implements).flatten.compact.map(&:to_s)
      all_identifiers = suite.all_identifiers.map(&:to_s)
      all_dependencies.each do |dep|
        errors << "Requirement #{identifier} has an invalid dependency: #{dep}" unless all_identifiers.include?(dep)
      end
      errors
    end

    def validate_nested_requirement
      if has_parent_requirement?
        ["Nested requirement detected: #{identifier}"]
      else
        []
      end
    end

    def has_parent_requirement?
      # Implementation depends on how you determine if a requirement is nested
      false
    end
  end
end
