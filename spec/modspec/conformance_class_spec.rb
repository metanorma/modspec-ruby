# spec/modspec/conformance_class_spec.rb

RSpec.describe Modspec::ConformanceClass do
  let(:yaml_content) { File.read("spec/fixtures/basic-ypr-cc.yaml") }
  let(:suite) { Modspec::Suite.from_yaml(yaml_content) }
  let(:cc) { suite.conformance_classes.first }

  before do
    suite.setup_relationships
  end

  it "has an identifier" do
    expect(cc.identifier).not_to be_nil
  end

  it "has a name" do
    expect(cc.name).not_to be_nil
  end

  it "has conformance tests" do
    expect(cc.tests).not_to be_empty
  end

  describe "#validate" do
    it "returns no errors for a valid conformance class" do
      errors = cc.validate
      expect(errors).to be_empty
    end

    it "returns errors if there are no conformance tests" do
      cc.tests = []
      errors = cc.validate
      expect(errors).not_to be_empty
    end
  end
end
