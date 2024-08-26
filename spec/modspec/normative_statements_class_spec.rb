# frozen_string_literal: true

RSpec.describe Modspec::NormativeStatementsClass do
  let(:normative_statement1) do
    Modspec::NormativeStatement.new(
      identifier: "/req/basic-ypr/position",
      name: "Expression of outer frame",
      statement: "The `Basic_YPR.position` attribute shall represent the outer frame, specified by an implicit WGS-84 CRS and an implicit EPSG 4461-CS (LTP-ENU) coordinate system and explicit parameters to define the tangent point."
    )
  end

  let(:normative_statement2) do
    Modspec::NormativeStatement.new(
      identifier: "/req/basic-ypr/angles",
      name: "Expression of inner frame",
      statement: "The `Basic_YPR.angles` attribute shall represent the inner frame, which is a rotation-only transformation with Yaw, Pitch, and Roll (YPR) angles."
    )
  end

  let(:normative_statements_class) do
    Modspec::NormativeStatementsClass.new(
      identifier: "/req/basic-ypr",
      name: "Basic-YPR logical model SDU",
      description: "The Basic-YPR Target has a simple structure with no options. Position is specified as a point in an LTP-ENU frame and rotation is specified by yaw, pitch, and roll angles specified in decimal degrees.",
      dependencies: ["/req/global", "/req/tangent-point"],
      normative_statements: [normative_statement1, normative_statement2]
    )
  end

  it "has an identifier" do
    expect(normative_statements_class.identifier).to eq("/req/basic-ypr")
  end

  it "has a name" do
    expect(normative_statements_class.name).to eq("Basic-YPR logical model SDU")
  end

  it "has normative statements" do
    expect(normative_statements_class.normative_statements).not_to be_empty
    expect(normative_statements_class.normative_statements.length).to eq(2)
  end

  describe "#validate_all" do
    it "returns no errors for a valid normative statements class" do
      errors = normative_statements_class.validate_all
      expect(errors).to be_empty
    end

    it "returns errors if there are no normative statements" do
      normative_statements_class.normative_statements = []
      errors = normative_statements_class.validate_all
      expect(errors).not_to be_empty
    end
  end
end
