# frozen_string_literal: true

RSpec.describe Modspec::Suite do
  let(:rc_yaml) { File.read("spec/fixtures/basic-ypr-rc.yaml") }
  let(:cc_yaml) { File.read("spec/fixtures/basic-ypr-cc.yaml") }

  let(:global_rc) { File.read("spec/fixtures/global-rc.yaml") }
  let(:tangent_point_rc) { File.read("spec/fixtures/tangent-point-rc.yaml") }
  let(:time_rc) { File.read("spec/fixtures/time-rc.yaml") }
  let(:frame_spec_rc) { File.read("spec/fixtures/frame-spec-rc.yaml") }

  let(:global_suite) { described_class.from_yaml(global_rc) }
  let(:tangent_point_suite) { described_class.from_yaml(tangent_point_rc) }
  let(:time_suite) { described_class.from_yaml(time_rc) }
  let(:frame_spec_suite) { described_class.from_yaml(frame_spec_rc) }

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
      expect(errors).to be_empty
    end

    it "detects duplicate identifiers" do
      suite = described_class.new(
        identifier: "/suite",
        name: "Test",
        normative_statements_classes: [
          Modspec::NormativeStatementsClass.new(
            identifier: "/req/test",
            normative_statements: [
              Modspec::NormativeStatement.new(identifier: "/req/test/a",
                                              name: "A", statement: "a"),
              Modspec::NormativeStatement.new(identifier: "/req/test/a",
                                              name: "A2", statement: "a2"),
            ],
          ),
        ],
        conformance_classes: [],
      )

      errors = suite.validate
      expect(errors).to include(a_string_matching(/Duplicate identifier/))
    end

    it "detects dependency cycles" do
      ns_a = Modspec::NormativeStatement.new(
        identifier: "/req/test/a", name: "A", statement: "a",
        dependencies: ["/req/test/b"]
      )
      ns_b = Modspec::NormativeStatement.new(
        identifier: "/req/test/b", name: "B", statement: "b",
        dependencies: ["/req/test/a"]
      )

      suite = described_class.new(
        identifier: "/suite",
        name: "Test",
        normative_statements_classes: [
          Modspec::NormativeStatementsClass.new(
            identifier: "/req/test",
            normative_statements: [ns_a, ns_b],
          ),
        ],
        conformance_classes: [],
      )

      errors = suite.validate
      expect(errors).to include(a_string_matching(/Cycle detected/))
    end

    it "detects invalid dependencies" do
      suite = described_class.new(
        identifier: "/suite",
        name: "Test",
        normative_statements_classes: [
          Modspec::NormativeStatementsClass.new(
            identifier: "/req/test",
            dependencies: ["/req/nonexistent"],
            normative_statements: [
              Modspec::NormativeStatement.new(
                identifier: "/req/test/a", name: "A", statement: "a",
                dependencies: ["/req/missing"]
              ),
            ],
          ),
        ],
        conformance_classes: [],
      )

      errors = suite.validate
      expect(errors).to include(a_string_matching(/Invalid dependencies .* in \/req\/test\b/))
      expect(errors).to include(a_string_matching(/Invalid dependencies .* in \/req\/test\/a/))
    end

    it "detects invalid conformance test targets" do
      suite = described_class.new(
        identifier: "/suite",
        name: "Test",
        normative_statements_classes: [
          Modspec::NormativeStatementsClass.new(
            identifier: "/req/test",
            normative_statements: [
              Modspec::NormativeStatement.new(identifier: "/req/test/a",
                                              name: "A", statement: "a"),
            ],
          ),
        ],
        conformance_classes: [
          Modspec::ConformanceClass.new(
            identifier: "/conf/test",
            tests: [
              Modspec::ConformanceTest.new(
                identifier: "/conf/test/a",
                name: "CT-A",
                targets: ["/req/nonexistent"],
              ),
            ],
          ),
        ],
      )

      errors = suite.validate
      expect(errors).to include(a_string_matching(/Invalid targets .* in \/conf\/test\/a/))
    end

    it "detects invalid indirect_dependency references" do
      suite = described_class.new(
        identifier: "/suite",
        name: "Test",
        normative_statements_classes: [
          Modspec::NormativeStatementsClass.new(
            identifier: "/req/test",
            normative_statements: [
              Modspec::NormativeStatement.new(
                identifier: "/req/test/a", name: "A", statement: "a",
                indirect_dependency: ["/req/ghost"]
              ),
            ],
          ),
        ],
        conformance_classes: [],
      )

      errors = suite.validate
      expect(errors).to include(a_string_matching(/indirect dependency.*in \/req\/test\/a/))
    end

    it "detects invalid implements references" do
      suite = described_class.new(
        identifier: "/suite",
        name: "Test",
        normative_statements_classes: [
          Modspec::NormativeStatementsClass.new(
            identifier: "/req/test",
            implements: ["/req/phantom"],
            normative_statements: [],
          ),
        ],
        conformance_classes: [],
      )

      errors = suite.validate
      expect(errors).to include(a_string_matching(/implements.*in \/req\/test/))
    end

    it "detects invalid conformance test dependencies" do
      suite = described_class.new(
        identifier: "/suite",
        name: "Test",
        normative_statements_classes: [],
        conformance_classes: [
          Modspec::ConformanceClass.new(
            identifier: "/conf/test",
            tests: [
              Modspec::ConformanceTest.new(
                identifier: "/conf/test/a",
                name: "CT-A",
                dependencies: ["/conf/nonexistent"],
              ),
            ],
          ),
        ],
      )

      errors = suite.validate
      expect(errors).to include(a_string_matching(/Invalid dependencies .* in \/conf\/test\/a/))
    end
  end

  describe "#combine" do
    let(:suite1) do
      described_class.from_yaml(File.read("spec/fixtures/basic-ypr-rc.yaml"))
    end
    let(:suite2) do
      described_class.from_yaml(File.read("spec/fixtures/basic-quaternion-rc.yaml"))
    end

    it "combines two suites" do
      combined_suite = suite1.combine(suite2)
      expect(combined_suite.name).to eq("#{suite1.name} + #{suite2.name}")
      expect(combined_suite.normative_statements_classes.count).to eq(
        suite1.normative_statements_classes.count +
        suite2.normative_statements_classes.count,
      )
    end

    it "raises ArgumentError for non-Suite argument" do
      expect { suite1.combine("not a suite") }.to raise_error(ArgumentError)
    end

    it "deduplicates by identifier" do
      combined = suite1.combine(suite1)
      nsc_count = combined.normative_statements_classes.count
      expect(nsc_count).to eq(suite1.normative_statements_classes.count)
    end

    it "resolves conflicts when combining suites" do
      combined_suite = suite1
        .combine(suite2)
        .combine(global_suite)
        .combine(tangent_point_suite)
        .combine(time_suite)
        .combine(frame_spec_suite)

      errors = combined_suite.validate
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

      expect(combined_suite.normative_statements_classes).not_to be_empty
      expect(combined_suite.conformance_classes).not_to be_empty

      errors = combined_suite.validate
      expect(errors).not_to include(a_string_matching(/has no corresponding requirement/))
      expect(errors).not_to include(a_string_matching(/Cycle detected/))
      expect(errors).not_to include(a_string_matching(/has an invalid dependency/))
      expect(errors).to be_empty
    end
  end
end
