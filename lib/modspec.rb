# frozen_string_literal: true

require_relative "modspec/version"
require "lutaml/model"
require "set"

module Modspec
  class Error < StandardError; end

  # Your code goes here...
end

require_relative "modspec/identifier"
require_relative "modspec/normative_statement"
require_relative "modspec/normative_statements_class"
require_relative "modspec/conformance_test"
require_relative "modspec/conformance_class"
require_relative "modspec/suite"
