# frozen_string_literal: true

RSpec.describe Modspec::NormativeStatement do
  let(:global_sdu_statement) do
    Modspec::NormativeStatement.new(
      identifier: "/req/global/sdu",
      name: "SDU conforms to the 'Structural Data Unit - SDU' stereotype",
      statement: "Implementations using encoded SDUs SHALL conform to the logical description of the Logical Model elements with the 'Structural Data Unit - SDU' stereotype."
    )
  end

  let(:tangent_point_statement) do
    Modspec::NormativeStatement.new(
      identifier: "/req/tangent-point",
      name: "Tangent point requirements",
      statement: "Common tangent point requirements for SDUs that include tangent points."
    )
  end

  let(:normative_statement) do
    Modspec::NormativeStatement.new(
      identifier: "/req/basic-ypr/position",
      name: "Expression of outer frame",
      statement: "The `Basic_YPR.position` attribute shall represent the outer frame, specified by an implicit WGS-84 CRS and an implicit EPSG 4461-CS (LTP-ENU) coordinate system and explicit parameters to define the tangent point.",
      obligation: "requirement",
      subject: "Basic_YPR.position",
      inherit: ["/req/global/sdu"],
      dependencies: ["/req/tangent-point"],
      guidance: "Ensure the coordinate system is correctly specified."
    )
  end

  let(:suite) do
    suite = Modspec::Suite.new
    global_class = Modspec::NormativeStatementsClass.new(
      identifier: "/req/global",
      normative_statements: [global_sdu_statement]
    )
    tangent_point_class = Modspec::NormativeStatementsClass.new(
      identifier: "/req/tangent-point",
      normative_statements: [tangent_point_statement]
    )
    basic_ypr_class = Modspec::NormativeStatementsClass.new(
      identifier: "/req/basic-ypr",
      normative_statements: [normative_statement]
    )
    suite.normative_statements_classes = [global_class, tangent_point_class, basic_ypr_class]
    suite
  end

  before do
    allow(Modspec::Suite).to receive(:instance).and_return(suite)
  end

  it "has an identifier" do
    expect(normative_statement.identifier).to eq("/req/basic-ypr/position")
  end

  it "has a name" do
    expect(normative_statement.name).to eq("Expression of outer frame")
  end

  it "has a statement" do
    expect(normative_statement.statement).not_to be_nil
  end

  it "has a valid obligation" do
    expect(%w[requirement recommendation permission]).to include(normative_statement.obligation)
  end

  describe "#validate_all" do
    it "returns no errors for a valid normative statement" do
      errors = normative_statement.validate_all
      expect(errors).to be_empty
    end

    it "returns errors for an invalid obligation" do
      expect { normative_statement.obligation = "invalid" }.to raise_error(Lutaml::Model::InvalidValueError)
    end
  end
end
