#!/usr/bin/env ruby

require 'rubygems'
require 'net/http'
require 'rexml/document'
require 'nestful'
require 'nokogiri'

class FPV
  def initialize(feed)
    @feed = feed.dup
    @xml = Net::HTTP.get_response( URI.parse( @feed ) ).body
    @xml_doc = REXML::Document.new(@xml)
    @base_url = get_base_url
    @page_urls = get_page_list
    @page_html = get_page_html

    @validator_url = 'http://html5.validator.nu/'

    @validator_results = validate_html
    log_results
  end
  def get_base_url
    @feed.gsub('content.xml','')
  end
  def get_page_list
    pages = []
    @xml_doc.elements.each('//entry/link[@type="text/html"]') do |link|
      pages << @base_url + link.attributes['href']
    end
    pages
  end
  def get_page_html
    html = []
    @page_urls.each do |link|
      html << Net::HTTP.get_response( URI.parse( link ) ).body
    end
    html
  end
  def validate_html
    results = []
    @page_html.each_with_index do |html,i|

      local_filename = "#{i}.html"

      File.open(local_filename, 'w') {|f| f.write(html) }
      file = File.new(local_filename)
      retries = 10

      begin
        Timeout::timeout(5) do
          puts "Validating #{@page_urls[i]}"
          results << Nestful.post( @validator_url, :format => :multipart, :params => {:file => File.open(local_filename)} )
        end
      rescue Timeout::Error
        if retries > 0
          print "Timeout - Retrying...\r\n"
          retries -= 1
          retry
        else
          puts "ERROR: Not responding after 10 retries!  Giving up!"
          exit
        end
      end

      File.delete(local_filename)
    end
    results
  end
  def log_results
    builder = Nokogiri::HTML::Builder.new do |doc|
      doc.html {
        doc.head {
          doc.link(:href => 'css/style.css', :rel => "stylesheet", :type => "text/css")
        }
        doc.body {
          doc.h1 {
            doc.text "Validation results for #{@feed}"
          }
          @validator_results.each_with_index do |result,i|
            html = result
            parsed_data = Nokogiri::HTML.parse(html)
            doc.h1 {
              doc.a(:href => @page_urls[i]) {
                doc.text @page_urls[i]
              }
              doc.text " results"
            }
            doc.ul {
              parsed_data.css('.error').each do |error|
                doc << error.to_html
              end
            }
          end
        }
      }
    end
    File.open('results.html', 'w') {|f| f.write(builder.to_html) }
  end
end

FPV.new ARGV[0]
