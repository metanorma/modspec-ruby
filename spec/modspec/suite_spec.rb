# spec/modspec/suite_spec.rb

RSpec.describe Modspec::Suite do
  let(:rc_yaml) { File.read("spec/fixtures/basic-ypr-rc.yaml") }
  let(:cc_yaml) { File.read("spec/fixtures/basic-ypr-cc.yaml") }

  describe ".from_yaml" do
    it "parses a requirements class YAML file" do
      suite = described_class.from_yaml(rc_yaml)
      expect(suite).to be_a(described_class)
      expect(suite.normative_statements_classes).not_to be_empty
    end

    it "parses a conformance class YAML file" do
      suite = described_class.from_yaml(cc_yaml)
      expect(suite).to be_a(described_class)
      expect(suite.conformance_classes).not_to be_empty
    end
  end

  describe "#validate" do
    it "returns no errors for a valid suite" do
      suite = described_class.from_yaml(rc_yaml)
      errors = suite.validate
      expect(errors).to be_empty
    end
  end

  describe "#combine" do
    let(:suite1) { described_class.from_yaml(File.read("spec/fixtures/basic-ypr-rc.yaml")) }
    let(:suite2) { described_class.from_yaml(File.read("spec/fixtures/basic-quaternion-rc.yaml")) }

    it "combines two suites" do
      combined_suite = suite1.combine(suite2)
      expect(combined_suite.name).to eq("#{suite1.name} + #{suite2.name}")
      expect(combined_suite.normative_statements_classes.count).to be >= suite1.normative_statements_classes.count
      expect(combined_suite.normative_statements_classes.count).to be >= suite2.normative_statements_classes.count
    end

    it "resolves conflicts when combining suites" do
      combined_suite = suite1.combine(suite2)
      expect(combined_suite.validate).to be_empty
    end
  end

  describe ".from_yaml_files" do
    it "combines all YAML files in spec/fixtures and validates the combined suite" do
      yaml_files = Dir.glob("spec/fixtures/*.yaml")
      expect(yaml_files).not_to be_empty

      combined_suite = described_class.from_yaml_files(*yaml_files)
      expect(combined_suite).to be_a(described_class)
      expect(combined_suite.name).to eq("Combined Suite")

      # Ensure the combined suite has content
      expect(combined_suite.normative_statements_classes).not_to be_empty
      expect(combined_suite.conformance_classes).not_to be_empty

      # Validate the combined suite
      errors = combined_suite.validate

      if errors.any?
        puts "Validation errors:"
        errors.each { |error| puts "  #{error}" }
      end

      expect(errors).to be_empty
    end
  end
end
