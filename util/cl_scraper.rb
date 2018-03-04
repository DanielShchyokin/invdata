require 'faraday'
require 'pry'
require 'rubygems'
require 'nokogiri'
require 'uri'
require 'csv'

module CRAIGS_LIST_SCRAPER
  @@host_part = "craigslist.org"
  @@cities = {columbus_oh:"columbus"}
  @@uri = "/d/apts-housing-for-rent/search/apa"
  @@city = ""

  def connect_to_cl city
    @@city=city
    h=@@host_part
    url = "https://#{city}.#{h}"
    conn = Faraday.new url
  end

  def fetch_rentals_page(conn, page = 0)
    path =  "/search/apa"
    offset = 120 * page
    path = path.concat("?s=#{offset.to_s}") unless page == 0
    response = conn.get path
    page = Nokogiri::HTML(response.body)
  end

  def fetch_apartment_ad_page link
    response = Faraday.new.get link
    page = Nokogiri::HTML(response.body)
  end

  def scrape_link_data_from_apartment_search_page page
    links = page.css(".result-title").map{|link|link['href']}
    ad_list =[]
    links.each_with_index do |link,index|
      ad = {'link': link}
      ad['hood'] = page.css(".result-meta")[index].css('.result-hood').text
      ad_list << ad
    end
    ad_list
  end

  def bbsqft page, city, state, hood, link
    begin
     bbsqft = page.css(".shared-line-bubble").children.to_s.split("/")
     ad = {}
     ad['bedrooms'] = bbsqft[0][/\d+/].strip
     ad['baths'] = bbsqft[2][/\d+/].strip
     ad['sqft'] = bbsqft[3][/\d+/].strip unless bbsqft[3][/\d+/].to_i < 50
     ad
    rescue StandardError => e
      puts "no bbsqft data: "+link
      ad['bedrooms'] = ""
      ad['baths'] = ""
      ad['sqft'] = ""
      ad
    end
  end

  def tags page, city, state, hood, link
    #@todo open houses can be the second element instead of tags fix this
    begin
     tags = []
     tag_elements = page.css(".attrgroup")[1].children
     tag_elements.each {|el| tags << el.children.text.strip unless el.children.text.empty?}
     tags
    rescue StandardError => e
      puts "no_tag_data: " + link
      tags =[]
    end
  end

  def address page, city, state, hood, link
    begin
     ad = {}
    #@todo some ads have no address but a map location, others have only a map location
     ad['address'] = page.css(".mapaddress")[0].children.to_s.strip
     ad['map_address'] = page.css(".mapaddress")[1].children.css('a')[0].attributes['href'].value.strip
     ad
    rescue StandardError => e
      puts "no address or map data: " + link
      ad['tags'] = ""
      ad['address'] = ""
      ad['map_address'] = ""
      ad
    end
  end

  def scrape_data_from_apartment_ad page, city, state, hood, link
    ad = {city: city, state: state}
    ad["link"] = link
     ad['title'] = page.css("#titletextonly").children.to_s.strip
     ad['price'] = page.css(".price").children.to_s.strip
     ad['tags'] = tags page, city, state, hood, link
    ad = ad.merge(address(page, city, state, hood, link))
    ad = ad.merge(bbsqft(page, city, state, hood, link))
    puts link
    sleep 5
  end

  def run_cl_scraper(pages,city, state)
    conn = connect_to_cl(city)
    ad_data = []
    pages.each do |pg|
      binding.pry
      page = fetch_rentals_page(conn,pg)
      ad_list = scrape_link_data_from_apartment_search_page page
      ad_list.each do |ad_ref|
        page = fetch_apartment_ad_page ad_ref[:link]
        tmp = scrape_data_from_apartment_ad page,city, state, ad_ref['hood'], ad_ref[:link]
        ad_data << tmp unless tmp.nil?
      end
    end
    ad_data
  end
end

include CRAIGS_LIST_SCRAPER
city="columbus"
state = "ohio"
pages = 0...9
ad_data = run_cl_scraper(pages,city,state)
t = Time.now
csv_filename = "#{city}_#{state}_cl_rental_data_for#{t.strftime("%Y-%m-%d")}"
CSV.open(csv_filename, "wb") do |csv|
  csv << ad_data.first.keys # adds the attributes name on the first line
  ad_data.each do |hash|
    csv << hash.values
  end
end
