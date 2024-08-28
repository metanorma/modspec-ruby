# frozen_string_literal: true

RSpec.describe Modspec::ConformanceTest do
  let(:normative_statement) do
    Modspec::NormativeStatement.new(
      identifier: "/req/basic-ypr/position",
      name: "Expression of outer frame",
      statement: "The `Basic_YPR.position` attribute shall represent the outer frame, specified by an implicit WGS-84 CRS and an implicit EPSG 4461-CS (LTP-ENU) coordinate system and explicit parameters to define the tangent point."
    )
  end

  let(:normative_statements_class) do
    Modspec::NormativeStatementsClass.new(
      identifier: "/req/basic-ypr",
      name: "Basic-YPR logical model SDU",
      normative_statements: [normative_statement]
    )
  end

  let(:conformance_test) do
    Modspec::ConformanceTest.new(
      identifier: "/conf/basic-ypr/position",
      name: "Verify expression of outer frame",
      targets: ["/req/basic-ypr/position"],
      description: "To confirm that an implementation of a Basic-YPR consists of an Outer Frame specified by an implicit WGS-84 CRS and an implicit EPSG 4461-CS (LTP-ENU) coordinate system and explicit parameters to define the tangent point.",
      purpose: "Verify that this requirement is satisfied.",
      method: "Inspection"
    )
  end

  let(:conformance_class) do
    Modspec::ConformanceClass.new(
      identifier: "/conf/basic-ypr",
      name: "Basic-YPR logical model SDU conformance",
      tests: [conformance_test]
    )
  end

  let(:suite) do
    suite = Modspec::Suite.new
    suite.normative_statements_classes = [normative_statements_class]
    suite.conformance_classes = [conformance_class]
    suite.setup_relationships
    suite
  end

  before do
    suite # Ensure the suite is created and relationships are set up
  end

  it "has an identifier" do
    expect(conformance_test.identifier).to eq("/conf/basic-ypr/position")
  end

  it "has a description" do
    expect(conformance_test.description).not_to be_nil
  end

  it "has targets" do
    expect(conformance_test.targets).to eq(["/req/basic-ypr/position"])
  end

  describe "#validate_all" do
    it "returns no errors for a valid conformance test" do
      errors = conformance_test.validate_all
      expect(errors).to be_empty
    end
  end

  it "has a corresponding requirement" do
    expect(conformance_test.corresponding_requirements).to include(normative_statement)
  end

  it "belongs to a conformance class" do
    expect(conformance_test.parent_class).to eq(conformance_class)
  end
end
