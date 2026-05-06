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

    it "detects cross-type identifier collisions" do
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
                identifier: "/req/test/a",
                name: "CT collision",
              ),
            ],
          ),
        ],
      )

      errors = suite.validate
      expect(errors).to include(a_string_matching(/Duplicate identifier.*\/req\/test\/a/))
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

  describe "#setup_relationships" do
    it "links conformance tests to their target normative statements" do
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
                targets: ["/req/test/a"],
              ),
            ],
          ),
        ],
      )

      suite.setup_relationships
      ct = suite.conformance_classes.first.tests.first
      expect(ct.corresponding_requirements.map(&:identifier)).to eq(["/req/test/a"])
      expect(ct.parent_class).to eq(suite.conformance_classes.first)
    end

    it "handles missing target gracefully (no matching requirement)" do
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
                targets: ["/req/test/missing"],
              ),
            ],
          ),
        ],
      )

      suite.setup_relationships
      ct = suite.conformance_classes.first.tests.first
      expect(ct.corresponding_requirements).to be_empty
    end

    it "returns early when conformance_classes is nil" do
      suite = described_class.new(
        identifier: "/suite",
        name: "Test",
        normative_statements_classes: [
          Modspec::NormativeStatementsClass.new(
            identifier: "/req/test",
            normative_statements: [],
          ),
        ],
        conformance_classes: nil,
      )

      expect { suite.setup_relationships }.not_to raise_error
    end
  end

  describe "#resolve_conflicts" do
    let(:nsc_with_data) do
      Modspec::NormativeStatementsClass.new(
        identifier: "/req/test",
        name: "Original",
        description: "First description",
        normative_statements: [
          Modspec::NormativeStatement.new(identifier: "/req/test/a",
                                          name: "A", statement: "a"),
        ],
      )
    end

    let(:nsc_partial) do
      Modspec::NormativeStatementsClass.new(
        identifier: "/req/test",
        name: "Original",
        description: "Second description",
        subject: "Added subject",
        normative_statements: [],
      )
    end

    let(:nsc_other) do
      Modspec::NormativeStatementsClass.new(
        identifier: "/req/test2",
        name: "Two",
        normative_statements: [
          Modspec::NormativeStatement.new(identifier: "/req/test2/b",
                                          name: "B", statement: "b"),
        ],
      )
    end

    it "merges attributes of items with matching identifiers" do
      suite1 = described_class.new(
        identifier: "/suite", name: "Test1",
        normative_statements_classes: [nsc_with_data],
        conformance_classes: []
      )
      suite2 = described_class.new(
        identifier: "/suite", name: "Test2",
        normative_statements_classes: [nsc_partial],
        conformance_classes: []
      )

      suite1.resolve_conflicts(suite2)
      nsc = suite1.normative_statements_classes.first
      expect(nsc.description).to eq("First description")
      expect(nsc.subject).to eq("Added subject")
    end

    it "appends items with new identifiers" do
      suite1 = described_class.new(
        identifier: "/suite", name: "Test1",
        normative_statements_classes: [nsc_with_data],
        conformance_classes: []
      )
      suite2 = described_class.new(
        identifier: "/suite", name: "Test2",
        normative_statements_classes: [nsc_other],
        conformance_classes: []
      )

      suite1.resolve_conflicts(suite2)
      expect(suite1.normative_statements_classes.map(&:identifier)).to eq(
        ["/req/test", "/req/test2"],
      )
    end
  end

  describe "YAML round-trip" do
    it "serializes and deserializes a normative statements class" do
      original = described_class.from_yaml(rc_yaml)
      yaml_out = original.to_yaml
      round_tripped = described_class.from_yaml(yaml_out)

      expect(round_tripped.identifier).to eq(original.identifier)
      expect(round_tripped.name).to eq(original.name)
      expect(round_tripped.normative_statements_classes.count).to eq(
        original.normative_statements_classes.count,
      )
    end

    it "serializes and deserializes a conformance class" do
      original = described_class.from_yaml(cc_yaml)
      yaml_out = original.to_yaml
      round_tripped = described_class.from_yaml(yaml_out)

      expect(round_tripped.identifier).to eq(original.identifier)
      expect(round_tripped.conformance_classes.count).to eq(
        original.conformance_classes.count,
      )
    end
  end

  describe "JSON round-trip" do
    let(:json_rc) { File.read("spec/fixtures/basic-ypr-json-rc.yaml") }
    let(:json_cc) { File.read("spec/fixtures/basic-ypr-json-cc.yaml") }

    it "parses JSON-format YAML fixtures" do
      suite = described_class.from_yaml(json_rc)
      expect(suite.normative_statements_classes).not_to be_empty
    end

    it "round-trips through JSON serialization" do
      original = described_class.from_yaml(rc_yaml)
      json_out = original.to_json
      round_tripped = described_class.from_json(json_out)

      expect(round_tripped.identifier).to eq(original.identifier)
      expect(round_tripped.name).to eq(original.name)
    end
  end
end
