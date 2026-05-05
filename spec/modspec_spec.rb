# frozen_string_literal: true

RSpec.describe Modspec do
  it "has a version number" do
    expect(Modspec::VERSION).not_to be_nil
  end

  Dir.glob("spec/fixtures/*-rc.yaml").each do |file|
    it "parses normative statements class #{file}" do
      source_yaml = File.read(file)
      output_yaml = Modspec::Suite.from_yaml(source_yaml).to_yaml

      expect(output_yaml).to be_yaml_equivalent_to(source_yaml)
    end
  end

  Dir.glob("spec/fixtures/*-cc.yaml").each do |file|
    it "parses conformance class #{file}" do
      source_yaml = File.read(file)
      output_yaml = Modspec::Suite.from_yaml(source_yaml).to_yaml

      expect(output_yaml).to be_yaml_equivalent_to(source_yaml)
    end
  end
end
