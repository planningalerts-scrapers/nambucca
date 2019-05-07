require 'scraperwiki'
require 'mechanize'

case ENV['MORPH_PERIOD']
  when 'lastmonth'
    date = Date.today.prev_month
  	dateFrom = Date.new(date.year, date.month, 1).strftime('%d/%m/%Y')
  	dateTo   = Date.new(date.year, date.month, -1).strftime('%d/%m/%Y')
  when 'thismonth'
    date = Date.today
  	dateFrom = Date.new(date.year, date.month, 1).strftime('%d/%m/%Y')
  	dateTo   = Date.new(date.year, date.month, -1).strftime('%d/%m/%Y')
  else
    unless ENV['MORPH_PERIOD'].nil?
      matches = ENV['MORPH_PERIOD'].scan(/^(19[0-9]{2}|20[0-9]{2})$/)
    end
    unless matches.nil?
      dateFrom = Date.new(matches[0][0].to_i, 1, 1).strftime('%d/%m/%Y')
      dateTo   = Date.new(matches[0][0].to_i, 12, 31).strftime("%d/%m/%Y")
    else
      ENV['MORPH_PERIOD'] = 'thisweek'
      date = Date.today
      dateTo   = Date.new(date.year, date.month, date.day).strftime('%d/%m/%Y')
      date = Date.today - 10
      dateFrom = Date.new(date.year, date.month, date.day).strftime('%d/%m/%Y')
    end
end
puts "Getting data in `" + ENV['MORPH_PERIOD'] + "`, changable via MORPH_PERIOD environment"

comment_url = 'mailto:council@nambucca.nsw.gov.au'
info_url = 'https://eservices.nambucca.nsw.gov.au/eservice/daEnquiryInit.do?doc_typ=10&nodeNum=2811'

# Grab the starting page and put in the date and her we go
agent = Mechanize.new
page = agent.get(info_url)
form = page.form_with(name: "daEnquiryForm")
form['lodgeRangeType'] = 'on'
form['dateFrom'] = dateFrom
form['dateTo']   = dateTo
page = form.submit()

(0..page.search('.non_table_headers').size - 1).each do |i|
  date_received = Date.strptime(page.search('.non_table_headers ~ div')[i].at('span:contains("Date Lodged") ~ span').inner_text, '%d/%m/%Y').to_s rescue nil

  record = {
    'council_reference' => page.search('.non_table_headers ~ div')[i].at('span:contains("Application No.") ~ span').inner_text,
    'address' => page.search('.non_table_headers')[i].inner_text,
    'description' => page.search('.non_table_headers ~ div')[i].at('span:contains("Type of Work") ~ span').inner_text,
    'info_url' => info_url,
    'comment_url' => comment_url,
    'date_scraped' => Date.today.to_s,
    'date_received' => date_received
  }

  puts "Saving record " + record['council_reference'] + ' - ' + record['address']
#     puts record
  ScraperWiki.save_sqlite(['council_reference'], record)

end
