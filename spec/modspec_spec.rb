# frozen_string_literal: true

RSpec.describe Modspec do
  it "has a version number" do
    expect(Modspec::VERSION).not_to be nil
  end

  Dir.glob("spec/fixtures/*-rc.yaml").each do |file|
    it "parses normative statements class #{file}" do
      yaml = IO.read(file)
      Modspec::Suite.from_yaml(yaml)

      # TODO: tests
    end
  end

  Dir.glob("spec/fixtures/*-cc.yaml").each do |file|
    it "parses conformance class #{file}" do
      yaml = IO.read(file)
      Modspec::Suite.from_yaml(yaml)

      # TODO: tests
    end
  end
end
