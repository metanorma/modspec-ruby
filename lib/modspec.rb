# frozen_string_literal: true

require_relative "modspec/version"
require "lutaml/model"
require "set"

module Modspec
  autoload :ChildContainer, "modspec/child_container"
  autoload :Identifier, "modspec/identifier"
  autoload :NormativeStatement, "modspec/normative_statement"
  autoload :NormativeStatementPart, "modspec/normative_statement"
  autoload :NormativeStatementsClass, "modspec/normative_statements_class"
  autoload :ConformanceTest, "modspec/conformance_test"
  autoload :ConformanceClass, "modspec/conformance_class"
  autoload :Suite, "modspec/suite"
end
