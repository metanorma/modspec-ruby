# spec/modspec/normative_statement_spec.rb

RSpec.describe Modspec::NormativeStatement do
  let(:yaml_content) { File.read("spec/fixtures/basic-ypr-rc.yaml") }
  let(:suite) { Modspec::Suite.from_yaml(yaml_content) }
  let(:ns) { suite.normative_statements_classes.first.normative_statements.first }

  it "has an identifier" do
    expect(ns.identifier).not_to be_nil
  end

  it "has a statement" do
    expect(ns.statement).not_to be_nil
  end

  it "has a valid obligation" do
    expect(["requirement", "recommendation", "permission"]).to include(ns.obligation)
  end

  describe "#validate" do
    it "returns no errors for a valid normative statement" do
      errors = ns.validate
      expect(errors).to be_empty
    end

    it "returns errors for an invalid obligation" do
      expect { ns.obligation = "invalid" }.to raise_error(Lutaml::Model::InvalidValueError)
    end
  end
end
