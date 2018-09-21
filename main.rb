
require 'watir'
require 'nokogiri'
require 'pry'
require_relative 'transaction'

class Accounts

  attr_reader :browser

  def initialize
    @browser = Watir::Browser.new(:chrome)
  end

  def collect_data
    log_in
    result = {accounts: parse_accounts[0].merge!(transactions: parse_transactions)}
    log_out

    result
  end

  private

  def log_in
    browser.goto("https://wb.micb.md/")
    puts "Write your Username: "
    browser.text_field(class: "username").set(gets.chomp)  # Enter your login
    puts "Write your Password: "
    browser.text_field(id: "password").set(gets.chomp)     # Enter your password
    browser.button(class: "wb-button").click
    raise "Invalid Username or Password" if browser.div(class: %w(page-message error)).present?
    wait_until { browser.div(class: "contract-cards").present? }
  end

  def parse_accounts
    accounts_div = browser.divs(class: %w(contract status-active))

    accounts_div.map do |element|
      element.div(class: "contract-cards").a.click
      wait_until { browser.a(href: "#contract-information").present? }

      browser.a(href: "#contract-information").click
      wait_until { browser.div(id: "contract-information").present? }

      parse_account(Nokogiri::HTML(browser.div(id: "contract-information").html))
    end
  end

  def parse_account(html)
    {
      name: 		html.css('tr')[-3].css('td')[1].text,
      balance: 		html.css('tr')[-1].css('td')[1].css('span')[0].text.gsub(",",".").to_f,
      currency: 	html.css('tr')[-1].css('td')[1].css('span')[1].text,
      description: 	html.css('tr')[3].css('td')[1].text.gsub("2. De baza - ","")
    }
  end

  def go_to_transactions_info
    browser.link(href: "#contract-history").click
    wait_until { browser.text_field(class: %w(filter-date from maxDateToday hasDatepicker)).present? }

    browser.text_field(class: %w(filter-date from maxDateToday hasDatepicker)).click
    wait_until { browser.link(class: %w(ui-datepicker-prev ui-corner-all)).present? }

    browser.link(class: %w(ui-datepicker-prev ui-corner-all)).click
    wait_until { browser.link(class: "ui-state-default").present? }

    browser.link(class: "ui-state-default").click
    wait_until { browser.div(class: "operations").li.present? }
  end

  def parse_transactions
  	go_to_transactions_info

    transaction_list = browser.div(class: "operations").lis

    transaction_list.map do |li|
      li.link(class: "operation-details").click

      wait_until { browser.div(class: "operation-details-body").present? && browser.div(class: "operation-details-header").present? }

      transaction_body	 = Nokogiri::HTML.parse(browser.div(class: "operation-details-body").html)
      transaction_header = Nokogiri::HTML.parse(browser.div(class: "operation-details-header").html)

      browser.send_keys :escape

      parse_transaction(transaction_body, transaction_header).to_hash
    end
  end

  def parse_transaction(transaction_body, transaction_header)
    date 		= transaction_body.css('.operation-details-body').css('.details-section')[0].css('.value')[0].text
    description = transaction_header.css('.operation-details-header').text.gsub("  ", "")
    amount 		= transaction_body.css('.details-section.amounts').css('.value')[0].text.split[0].gsub(",", ".").to_f

    Transactions.new(date, description, amount)
  end

  def log_out
    browser.span(class: "logout-link-wrapper").click
    wait_until { browser.text_field(class: "username").present? }
  end

  def wait_until(&block)
  	Watir::Wait.until {yield}
  end

end

if __FILE__ == $0

webbanking = Moldindconbank.new
puts JSON.pretty_generate(webbanking.collect_data)

end
