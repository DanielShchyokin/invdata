require 'faraday'
require 'pry'
require 'rubygems'
require 'nokogiri'
require 'uri'

@url = "http://www.bestplaces.net"
def scrape_cities_by_metro metro

  metro_path = metro[:metro_link].gsub("../","/")
  conn = Faraday.new @url
  response = conn.get metro_path
  page = Nokogiri::HTML(response.body)
  #extract the cities link
  links = page.css("a")
  link_index =links.find_index {|e|e.to_s.include? ">Cities<"}
  link = links[link_index]
  cities_uri = URI(link.attributes['href'].value)
  #follow the nice url
  conn = Faraday.new "http://"+cities_uri.host
  response = conn.get cities_uri.path + "?" +cities_uri.query
  page = Nokogiri::HTML(response.body)
  #parse out the cities_uri
  city_links = page.xpath("//div[contains(@class, '4u')]/*")
  city_links = city_links.select do |city_link|
       city_link.attributes['href'].value.include? "../city/#{metro[:state]}" unless city_link.attributes['href'].nil?
  end
  #cities in metro
  cities = []
  city_links.each do |city_link|
    cl = city_link.attributes['href'].value
    x = cl.gsub("../city/#{metro[:state]}/","")
    cities << {city_link: cl, city_name: x }.merge(metro)
  end
  File.open("data/city_data.yaml", 'a') { |file| file.write(cities.to_yaml) }
end

def scrape_metros
  metro_links = []
  states.each do |state|
    conn = Faraday.new @url
    response = conn.get "/find/metro.aspx?st=#{state[1]}"
    page = Nokogiri::HTML(response.body)
    links = page.css("a")
    metros = links.map do |link|
      unless link.attributes['href'].nil?
        if link.attributes['href'].value.include?(state[1].downcase)
          raw_link =link.attributes['href'].value
          metro_links << {state: state[1].downcase,state_code:state[0], metro:raw_link.gsub("../metro/#{state[1].downcase}/",""), metro_link: raw_link}
        end
      end
    end
    sleep 2
  end
  File.open("data/metro_data.yaml", 'a') { |file| file.write(metro_links.to_yaml) }
end

def states
  states = [ ["AK", "Alaska"],
              ["AL", "Alabama"],
              ["AR", "Arkansas"],
              ["AS", "American Samoa"],
              ["AZ", "Arizona"],
              ["CA", "California"],
              ["CO", "Colorado"],
              ["CT", "Connecticut"],
              ["DC", "District of Columbia"],
              ["DE", "Delaware"],
              ["FL", "Florida"],
              ["GA", "Georgia"],
              ["GU", "Guam"],
              ["HI", "Hawaii"],
              ["IA", "Iowa"],
              ["ID", "Idaho"],
              ["IL", "Illinois"],
              ["IN", "Indiana"],
              ["KS", "Kansas"],
              ["KY", "Kentucky"],
              ["LA", "Louisiana"],
              ["MA", "Massachusetts"],
              ["MD", "Maryland"],
              ["ME", "Maine"],
              ["MI", "Michigan"],
              ["MN", "Minnesota"],
              ["MO", "Missouri"],
              ["MS", "Mississippi"],
              ["MT", "Montana"],
              ["NC", "North Carolina"],
              ["ND", "North Dakota"],
              ["NE", "Nebraska"],
              ["NH", "New Hampshire"],
              ["NJ", "New Jersey"],
              ["NM", "New Mexico"],
              ["NV", "Nevada"],
              ["NY", "New York"],
              ["OH", "Ohio"],
              ["OK", "Oklahoma"],
              ["OR", "Oregon"],
              ["PA", "Pennsylvania"],
              ["PR", "Puerto Rico"],
              ["RI", "Rhode Island"],
              ["SC", "South Carolina"],
              ["SD", "South Dakota"],
              ["TN", "Tennessee"],
              ["TX", "Texas"],
              ["UT", "Utah"],
              ["VA", "Virginia"],
              ["VI", "Virgin Islands"],
              ["VT", "Vermont"],
              ["WA", "Washington"],
              ["WI", "Wisconsin"],
              ["WV", "West Virginia"],
              ["WY", "Wyoming"]
            ]
end
#scrape_metros
#scrape_cities
x =  {state: "wyoming", state_code: "WY", metro: "cheyenne", metro_link: "../metro/wyoming/cheyenne"}
scrape_cities_by_metro x
