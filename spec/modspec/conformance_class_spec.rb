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
          statement: "The `Basic_YPR.position` attribute shall represent the outer frame, specified by an implicit WGS-84 CRS and an implicit EPSG 4461-CS (LTP-ENU) coordinate system and explicit parameters to define the tangent point.",
        ),
        Modspec::NormativeStatement.new(
          identifier: "/req/basic-ypr/angles",
          name: "Expression of inner frame",
          statement: "The `Basic_YPR.angles` attribute shall represent the inner frame, which is a rotation-only transformation with Yaw, Pitch, and Roll (YPR) angles.",
        ),
      ],
    )
  end

  let(:conformance_class) do
    Modspec::ConformanceClass.new(
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
          description: "To confirm that an implementation of a Basic-YPR consists of an Outer Frame specified by an implicit WGS-84 CRS and an implicit EPSG 4461-CS (LTP-ENU) coordinate system and explicit parameters to define the tangent point.",
          purpose: "Verify that this requirement is satisfied.",
          method: "Inspection",
        ),
        Modspec::ConformanceTest.new(
          identifier: "/conf/basic-ypr/angles",
          name: "Verify expression of inner frame",
          targets: ["/req/basic-ypr/angles"],
          description: "To confirm that the Inner Frame is expressed as a rotation-only transformation using Yaw, Pitch, and Roll angles.",
          purpose: "Verify that this requirement is satisfied.",
          method: "Inspection",
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
    Modspec::ConformanceClass.new(
      identifier: "/conf/global",
      name: "Global conformance",
      tests: [
        Modspec::ConformanceTest.new(
          identifier: "/conf/global/sdu",
          name: "Verify SDU conformance",
          targets: ["/req/global/sdu"],
          description: "To confirm that an implementation of an SDU conforms to the logical model.",
          purpose: "Verify that this requirement is satisfied.",
          method: "Inspection",
        ),
      ],
    )
  end

  let(:tangent_point_conf_class) do
    Modspec::ConformanceClass.new(
      identifier: "/conf/tangent-point",
      name: "Tangent point conformance",
      tests: [
        Modspec::ConformanceTest.new(
          identifier: "/conf/tangent-point/height",
          name: "Verify tangent point height",
          targets: ["/req/tangent-point/height"],
          description: "To confirm that an implementation of a Tangent Point specifies the height of the Tangent Point.",
          purpose: "Verify that this requirement is satisfied.",
          method: "Inspection",
        ),

      ],
    )
  end

  let(:suite) do
    suite = Modspec::Suite.new
    suite.conformance_classes = [conformance_class, global_conf_class, tangent_point_conf_class]
    suite.normative_statements_classes = [normative_statements_class, global_class, tangent_point_class]
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
      if errors.any?
        puts "Validation errors:"
        errors.each { |error| puts "  #{error}" }
      end
      expect(errors).to be_empty
    end

    it "returns errors if there are no conformance tests" do
      conformance_class.tests = []
      errors = conformance_class.validate
      expect(errors).not_to be_empty
    end
  end
end
