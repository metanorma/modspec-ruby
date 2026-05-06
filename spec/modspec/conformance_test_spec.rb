# frozen_string_literal: true

RSpec.describe Modspec::ConformanceTest do
  let(:normative_statement) do
    Modspec::NormativeStatement.new(
      identifier: "/req/basic-ypr/position",
      name: "Expression of outer frame",
      statement: "The `Basic_YPR.position` attribute shall represent the outer frame.",
    )
  end

  let(:normative_statements_class) do
    Modspec::NormativeStatementsClass.new(
      identifier: "/req/basic-ypr",
      name: "Basic-YPR logical model SDU",
      normative_statements: [normative_statement],
    )
  end

  let(:conformance_test) do
    described_class.new(
      identifier: "/conf/basic-ypr/position",
      name: "Verify expression of outer frame",
      targets: ["/req/basic-ypr/position"],
      description: "To confirm outer frame.",
      purpose: "Verify that this requirement is satisfied.",
      test_method: "Inspection",
    )
  end

  let(:conformance_class) do
    Modspec::ConformanceClass.new(
      identifier: "/conf/basic-ypr",
      name: "Basic-YPR logical model SDU conformance",
      tests: [conformance_test],
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
    suite
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

  describe "#validate" do
    it "returns no errors for a valid conformance test" do
      errors = conformance_test.validate
      expect(errors).to be_empty
    end

    it "returns errors when corresponding_requirements is nil" do
      conformance_test.corresponding_requirements = nil
      errors = conformance_test.validate
      expect(errors).to include(a_string_matching(/no corresponding requirements/))
    end

    it "returns errors when corresponding_requirements is empty" do
      conformance_test.corresponding_requirements = []
      errors = conformance_test.validate
      expect(errors).to include(a_string_matching(/no corresponding requirements/))
    end

    it "returns errors when parent_class is nil" do
      conformance_test.parent_class = nil
      errors = conformance_test.validate
      expect(errors).to include(a_string_matching(/does not belong to its parent class/))
    end
  end

  it "has a corresponding requirement" do
    expect(conformance_test.corresponding_requirements).to include(normative_statement)
  end

  it "belongs to a conformance class" do
    expect(conformance_test.parent_class).to eq(conformance_class)
  end
end
