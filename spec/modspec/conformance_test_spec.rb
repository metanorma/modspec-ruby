# spec/modspec/conformance_test_spec.rb

RSpec.describe Modspec::ConformanceTest do
  let(:yaml_content) { File.read("spec/fixtures/basic-ypr-cc.yaml") }
  let(:suite) { Modspec::Suite.from_yaml(yaml_content) }
  let(:ct) { suite.conformance_classes.first.tests.first }

  before do
    suite.setup_relationships
  end

  it "has an identifier" do
    expect(ct.identifier).not_to be_nil
  end

  it "has a description" do
    expect(ct.description).not_to be_nil
  end

  it "has targets" do
    expect(ct.targets).not_to be_empty
  end

  describe "#validate" do
    it "returns no errors for a valid conformance test" do
      errors = ct.validate
      expect(errors).to be_empty
    end

    # Add more specific validation tests as needed
  end
end
