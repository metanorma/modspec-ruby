RSpec.describe Modspec::Suite do
  let(:rc_yaml) { File.read("spec/fixtures/basic-ypr-rc.yaml") }
  let(:cc_yaml) { File.read("spec/fixtures/basic-ypr-cc.yaml") }

  let(:global_rc) { File.read("spec/fixtures/global-rc.yaml") }
  let(:tangent_point_rc) { File.read("spec/fixtures/tangent-point-rc.yaml") }
  let(:time_rc) { File.read("spec/fixtures/time-rc.yaml") }
  let(:frame_spec_rc) { File.read("spec/fixtures/frame-spec-rc.yaml") }

  let(:global_suite) { Modspec::Suite.from_yaml(global_rc) }
  let(:tangent_point_suite) { Modspec::Suite.from_yaml(tangent_point_rc) }
  let(:time_suite) { Modspec::Suite.from_yaml(time_rc) }
  let(:frame_spec_suite) { Modspec::Suite.from_yaml(frame_spec_rc) }

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
    it "returns no errors for a valid combined suite" do
      base_suite = described_class.from_yaml(rc_yaml)
      combined_suite = base_suite
        .combine(global_suite)
        .combine(tangent_point_suite)
        .combine(time_suite)
        .combine(frame_spec_suite)

      errors = combined_suite.validate
      if errors.any?
        puts "Validation errors:"
        errors.each { |error| puts "  #{error}" }
      end
      expect(errors).to be_empty
    end
  end

  describe "#combine" do
    let(:suite1) { described_class.from_yaml(File.read("spec/fixtures/basic-ypr-rc.yaml")) }
    let(:suite2) { described_class.from_yaml(File.read("spec/fixtures/basic-quaternion-rc.yaml")) }

    it "combines two suites" do
      combined_suite = suite1.combine(suite2)
      expect(combined_suite.name).to eq("#{suite1.name} + #{suite2.name}")
      expect(combined_suite.normative_statements_classes.count).to eq(
        suite1.normative_statements_classes.count +
        suite2.normative_statements_classes.count
      )
    end

    it "resolves conflicts when combining suites" do
      combined_suite = suite1
        .combine(suite2)
        .combine(global_suite)
        .combine(tangent_point_suite)
        .combine(time_suite)
        .combine(frame_spec_suite)

      errors = combined_suite.validate
      if errors.any?
        puts "Validation errors:"
        errors.each { |error| puts "  #{error}" }
      end
      expect(errors).to be_empty
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

      # Check for specific error types
      expect(errors).not_to include(a_string_matching(/Conformance test .* has no corresponding requirement/))
      expect(errors).not_to include(a_string_matching(/Cycle detected/))
      expect(errors).not_to include(a_string_matching(/Requirement .* has an invalid dependency/))

      # If there are still errors, they should be of a different nature
      expect(errors).to be_empty
    end
  end
end
