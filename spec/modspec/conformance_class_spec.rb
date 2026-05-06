# frozen_string_literal: true

RSpec.describe Modspec::ConformanceClass do
  let(:normative_statements_class) do
    Modspec::NormativeStatementsClass.new(
      identifier: "/req/basic-ypr",
      name: "Basic-YPR logical model SDU",
      description: "The Basic-YPR Target has a simple structure with no options.",
      dependencies: ["/req/global", "/req/tangent-point"],
      normative_statements: [
        Modspec::NormativeStatement.new(
          identifier: "/req/basic-ypr/position",
          name: "Expression of outer frame",
          statement: "The `Basic_YPR.position` attribute shall represent the outer frame.",
        ),
        Modspec::NormativeStatement.new(
          identifier: "/req/basic-ypr/angles",
          name: "Expression of inner frame",
          statement: "The `Basic_YPR.angles` attribute shall represent the inner frame.",
        ),
      ],
    )
  end

  let(:conformance_class) do
    described_class.new(
      identifier: "/conf/basic-ypr",
      name: "Basic-YPR logical model SDU conformance",
      target: ["/req/basic-ypr"],
      classification: "Target Type: SDU",
      description: "Conformance with Basic-YPR logical model SDU",
      dependencies: ["/conf/global", "/conf/tangent-point"],
      tests: [
        Modspec::ConformanceTest.new(
          identifier: "/conf/basic-ypr/position",
          name: "Verify expression of outer frame",
          targets: ["/req/basic-ypr/position"],
          description: "To confirm outer frame.",
          purpose: "Verify that this requirement is satisfied.",
          test_method: "Inspection",
        ),
        Modspec::ConformanceTest.new(
          identifier: "/conf/basic-ypr/angles",
          name: "Verify expression of inner frame",
          targets: ["/req/basic-ypr/angles"],
          description: "To confirm inner frame.",
          purpose: "Verify that this requirement is satisfied.",
          test_method: "Inspection",
        ),
      ],
    )
  end

  let(:global_class) do
    Modspec::NormativeStatementsClass.new(
      identifier: "/req/global",
      name: "Global requirements",
      normative_statements: [
        Modspec::NormativeStatement.new(
          identifier: "/req/global/sdu",
          name: "SDU conformance",
          statement: "SDUs shall conform to the logical model.",
        ),
      ],
    )
  end

  let(:tangent_point_class) do
    Modspec::NormativeStatementsClass.new(
      identifier: "/req/tangent-point",
      name: "Tangent point requirements",
      normative_statements: [
        Modspec::NormativeStatement.new(
          identifier: "/req/tangent-point/height",
          name: "Tangent point height",
          statement: "Tangent point height shall be specified.",
        ),
      ],
    )
  end

  let(:global_conf_class) do
    described_class.new(
      identifier: "/conf/global",
      name: "Global conformance",
      tests: [
        Modspec::ConformanceTest.new(
          identifier: "/conf/global/sdu",
          name: "Verify SDU conformance",
          targets: ["/req/global/sdu"],
          description: "To confirm SDU conformance.",
          purpose: "Verify that this requirement is satisfied.",
          test_method: "Inspection",
        ),
      ],
    )
  end

  let(:tangent_point_conf_class) do
    described_class.new(
      identifier: "/conf/tangent-point",
      name: "Tangent point conformance",
      tests: [
        Modspec::ConformanceTest.new(
          identifier: "/conf/tangent-point/height",
          name: "Verify tangent point height",
          targets: ["/req/tangent-point/height"],
          description: "To confirm tangent point height.",
          purpose: "Verify that this requirement is satisfied.",
          test_method: "Inspection",
        ),
      ],
    )
  end

  let(:suite) do
    suite = Modspec::Suite.new
    suite.conformance_classes = [conformance_class, global_conf_class,
                                 tangent_point_conf_class]
    suite.normative_statements_classes = [normative_statements_class,
                                          global_class, tangent_point_class]
    suite.setup_relationships
    suite
  end

  it "has an identifier" do
    expect(conformance_class.identifier).to eq("/conf/basic-ypr")
  end

  it "has a name" do
    expect(conformance_class.name).to eq("Basic-YPR logical model SDU conformance")
  end

  it "has conformance tests" do
    expect(conformance_class.tests).not_to be_empty
    expect(conformance_class.tests.length).to eq(2)
  end

  describe "#validate" do
    it "returns no errors for a valid conformance class" do
      errors = suite.validate
      expect(errors).to be_empty
    end

    it "returns errors if there are no conformance tests" do
      conformance_class.tests = []
      errors = conformance_class.validate
      expect(errors).to include(a_string_matching(/no child conformance tests/))
    end

    it "returns errors if test identifier does not share prefix" do
      conformance_class.tests = [
        Modspec::ConformanceTest.new(
          identifier: "/conf/other/test",
          name: "Mismatched test",
          targets: ["/req/basic-ypr/position"],
        ),
      ]
      errors = conformance_class.validate
      expect(errors).to include(a_string_matching(/does not share the expected prefix/))
    end
  end
end
