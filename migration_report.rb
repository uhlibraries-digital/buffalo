require 'hunting'
require './lib/buffalo.rb'
require './lib/buffalo/cdm.rb'
require './lib/buffalo/map.rb'
require './lib/buffalo/crosswalk.rb'
require './lib/buffalo/element.rb'
require './lib/buffalo/report.rb'
require './lib/buffalo/aspace.rb'
require 'csv'
require 'yaml'
require 'json'
require 'open-uri'
require 'linkeddata'
require 'uri'
require 'active_support'
require 'active_support/core_ext'
require 'httparty'
require 'securerandom'

COLLECTION = ARGV[0]
CROSSWALK = ARGV[1]
NAME = ARGV[2]

if COLLECTION == nil or CROSSWALK == nil or NAME == nil
  puts "\nPlease enter a CDM collection alias, crosswalk file name from the 'dmwg' directory, and your name.\n\n=== Example ===\nruby migration_report.rb p15195coll38 p15195coll38_crosswalk andy\n"
  exit
else
  Hunting.configure_with("O:/Metadata and Digitization Services/Metadata/Migration/config/uhdl.yml")
  Buffalo.configure_with("O:/Metadata and Digitization Services/Metadata/Migration/config/#{NAME}.yml")
  DMWG = Buffalo.config[:dmwg]
  MAP = Buffalo.config[:map]
  ITEMS = Buffalo.config[:items]
  puts ''
  puts 'Loading MAP...'
  bcdams = Map.new(JSON.parse(open('https://vocab.lib.uh.edu/bcdams-map/api/elements.json').read))
  puts 'Loading Crosswalk...'
  elements = Crosswalk.elements("#{DMWG}/#{COLLECTION}/#{CROSSWALK}.yml", bcdams)
  uhdl = Repository.scout([COLLECTION])
  uhdl.collections.each do |c_alias, collection|
    filename = Report.migration(collection, elements, { path: "#{MAP}/migration", cdm_domain: "digital.lib.uh.edu", items: ITEMS })
    Buffalo.append("#{MAP}/_data/migration.yml", "\n- label: #{filename}\n  file: #{filename}\n")
  end
end
