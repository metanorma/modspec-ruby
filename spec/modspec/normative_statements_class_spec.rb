# frozen_string_literal: true

RSpec.describe Modspec::NormativeStatementsClass do
  let(:normative_statement1) do
    Modspec::NormativeStatement.new(
      identifier: "/req/basic-ypr/position",
      name: "Expression of outer frame",
      statement: "The `Basic_YPR.position` attribute shall represent the outer frame.",
    )
  end

  let(:normative_statement2) do
    Modspec::NormativeStatement.new(
      identifier: "/req/basic-ypr/angles",
      name: "Expression of inner frame",
      statement: "The `Basic_YPR.angles` attribute shall represent the inner frame.",
    )
  end

  let(:normative_statements_class) do
    described_class.new(
      identifier: "/req/basic-ypr",
      name: "Basic-YPR logical model SDU",
      description: "The Basic-YPR Target has a simple structure.",
      dependencies: ["/req/global", "/req/tangent-point"],
      normative_statements: [normative_statement1, normative_statement2],
    )
  end

  let(:suite) do
    suite = Modspec::Suite.new
    suite.normative_statements_classes = [normative_statements_class]
    suite
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

  describe "#validate" do
    it "returns no errors for a valid normative statements class" do
      errors = normative_statements_class.validate
      expect(errors).to be_empty
    end

    it "returns errors if there are no normative statements" do
      normative_statements_class.normative_statements = []
      errors = normative_statements_class.validate
      expect(errors).to include(a_string_matching(/no child requirements/))
    end

    it "returns errors if statement identifier does not share prefix" do
      normative_statements_class.normative_statements = [
        Modspec::NormativeStatement.new(
          identifier: "/req/other/mismatch",
          name: "Mismatched",
          statement: "stmt",
        ),
      ]
      errors = normative_statements_class.validate
      expect(errors).to include(a_string_matching(/does not share the expected prefix/))
    end
  end
end
