require_relative './spec_helper'
require_relative '../main'
require_relative '../transaction'

RSpec.describe Moldindconbank do
  before do
    expect(Watir::Browser).to receive(:new).and_return("BROWSER")
  end

  describe "parse_account" do
    let(:file) { File.open("./account_info.html","r") { |f| f.read } } # add your file
    let(:html) { Nokogiri::HTML.fragment(file).css("#contract-information") }

    it "parses account information" do
      expect(subject.send(:parse_account, html)).to eq({
        :balance     => 100000.0,
        :name        => "Ivan Ivanov Ivanovi4",
        :currency    => "USD",
        :description => "MasterCard Standard Contactless"
      })
    end
  end

  describe "parse_transaction" do
    let(:file)   { File.open("./transactions.html","r") { |f| f.read } } # add your file
    let(:body)   { Nokogiri::HTML.fragment(file).css(".operation-details-body") }
    let(:header) { Nokogiri::HTML.fragment(file).css(".operation-details-header") }

    it "parses transaction" do
      transaction = subject.send(:parse_transaction, body, header)
      expect(transaction).to be_a_kind_of(Transaction)
      expect(transaction.to_hash).to eq({
        :amount       => 12.4,
        :date         => "2018-09-20 00:00:00 +0300",
        :description  => "Plata retail PAYPAL *FACEBOOK 35314369001 Ireland"
      })
    end
  end
end
