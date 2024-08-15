# spec/modspec/normative_statements_class_spec.rb

RSpec.describe Modspec::NormativeStatementsClass do
  let(:yaml_content) { File.read("spec/fixtures/basic-ypr-rc.yaml") }
  let(:suite) { Modspec::Suite.from_yaml(yaml_content) }
  let(:nsc) { suite.normative_statements_classes.first }

  it "has an identifier" do
    expect(nsc.identifier).not_to be_nil
  end

  it "has a name" do
    expect(nsc.name).not_to be_nil
  end

  it "has normative statements" do
    expect(nsc.normative_statements).not_to be_empty
  end

  describe "#validate" do
    it "returns no errors for a valid normative statements class" do
      errors = nsc.validate
      expect(errors).to be_empty
    end

    it "returns errors if there are no normative statements" do
      nsc.normative_statements = []
      errors = nsc.validate
      expect(errors).not_to be_empty
    end
  end
end
