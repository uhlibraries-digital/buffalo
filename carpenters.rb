require 'hunting'
require './lib/buffalo'
require './lib/buffalo/cdm'
require './lib/buffalo/map'
require './lib/buffalo/crosswalk'
require './lib/buffalo/element'
require './lib/buffalo/report'
require './lib/buffalo/aspace'
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
require 'fileutils'
require 'pathname'

COLLECTION = ARGV[0]
CROSSWALK = ARGV[1]
NAME = ARGV[2]

if COLLECTION == nil or CROSSWALK == nil or NAME == nil
  puts "\nPlease enter a CDM collection alias, crosswalk file name from the 'dmwg' directory, and your name.\n\n=== Example ===\nruby cdm_element_list.rb p15195coll4 crosswalk_controlled_vocab andy\n"
  exit
else
  Hunting.configure_with("O:/Metadata and Digitization Services/Metadata/Migration/config/uhdl.yml")
  Buffalo.configure_with("O:/Metadata and Digitization Services/Metadata/Migration/config/#{NAME}.yml")
  DMWG = Buffalo.config[:dmwg]
  MAP = Buffalo.config[:map]
  ITEMS = Buffalo.config[:items]
  ARCHIVAL = Buffalo.config[:archival]
  ASPACE = Buffalo.config[:aspace]
  COLLECTION_URI = Buffalo.config[:collection_uri]
  puts ''
  puts 'Loading MAP...'
  bcdams = Map.new(JSON.parse(open('https://vocab.lib.uh.edu/bcdams-map/api/elements.json').read))
  puts 'Loading Crosswalk...'
  elements = Crosswalk.elements("#{DMWG}/#{COLLECTION}/#{CROSSWALK}.yml", bcdams)
  uhdl = Repository.scout([COLLECTION])
  uhdl.collections.each do |c_alias, collection|
    Report.carpenters(collection, elements, { path: "#{DMWG}/#{COLLECTION}", items: ITEMS, aspace: ASPACE, archival: ARCHIVAL, collection_uri: COLLECTION_URI })
  end
end
