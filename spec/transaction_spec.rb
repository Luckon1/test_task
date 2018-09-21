require_relative './spec_helper'
require_relative '../transaction'

RSpec.describe Transaction do
  context "to_hash" do
    it "serializes data as needed" do
      expect(described_class.new("2018-02-20", "description", 30.5).to_hash).to eq({
       :amount      => 30.5,
       :date        => "2018-02-20 00:00:00 +0200",
       :description => "description"
      })
    end
  end
end
