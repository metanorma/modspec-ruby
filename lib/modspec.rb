# frozen_string_literal: true

require_relative "modspec/version"
require "lutaml/model"

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

require "lutaml/model/xml_adapter/nokogiri_adapter"
require "lutaml/model/json_adapter/standard_json_adapter"
require "lutaml/model/toml_adapter/toml_rb_adapter"
require "lutaml/model/yaml_adapter/standard_yaml_adapter"

Lutaml::Model::Config.configure do |config|
  config.xml_adapter = Lutaml::Model::XmlAdapter::NokogiriAdapter
  config.yaml_adapter = Lutaml::Model::YamlAdapter::StandardYamlAdapter
  config.json_adapter = Lutaml::Model::JsonAdapter::StandardJsonAdapter
  config.toml_adapter = Lutaml::Model::TomlAdapter::TomlRbAdapter
end
