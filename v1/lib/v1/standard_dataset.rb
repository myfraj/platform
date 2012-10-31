require 'v1/config'
require 'json'

module V1

  module StandardDataset

    def self.recreate_index!
      # Delete and create the index
      #TODO: add production env check

      items = process_input_file("../standard_dataset/items.json")

      import_result = nil
      Tire.index(V1::Config::SEARCH_INDEX) do
        delete

        #"enabled" => false  turns off indexing for that doc
        create :mappings => {
          :item => {
            :properties => {
              #NOTE: No longer needed now that the source data uses _id, I think. -phunk
              #:id       => { :type => 'string' },  
              :title    => { :type => 'string' },
              :dplaContributor    => { :type => 'string' },
              :collection    => { :type => 'string' },
              :creator    => { :type => 'string' },
              :publisher   => { :type => 'string' },
              :created => { :type => 'date' }, #"format" : "YYYY-MM-dd"
              :type    => { :type => 'string' }, #image, text, etc
              :format    => { :type => 'string' }, #mime-type
              :language    => { :type => 'string' }, 
              :subject    => { :type => 'string' },
              :description    => { :type => 'string' },
              :rights    => { :type => 'string' },
              :spatial   => {
                :properties => {
                  :name => { :type => 'string' },
                  :state => { :type => 'string' },
                  :city => { :type => 'string' },
                  'iso3166-2' => { :type => 'string' },
                  :coordinates => { :type => "geo_point", :lat_lon => true }
                 }
              },
              :temporal => {
                :properties => {
                  #:type => 'nested',
                  :name => { :type => 'string' },
                  :start => { :type => 'date', :null_value => "-9999" }, #requiredevenifnull #, :format=>"YYYY G"}
                  :end => { :type => 'date', :null_value => "9999" } #requiredevenifnull
                 }
              },
              :relation    => { :type => 'string' },
              :source    => { :type => 'string' },
              :contributor    => { :type => 'string' },
              :sourceRecord    => { :type => 'string' }
            }
          }
        }

        import_result = import items
        refresh
      end

      return display_import_result(import_result)
    end

    def self.display_import_result(import_result)
      result = JSON.load(import_result.body.as_json)
      failures = result['items'].select {|item| !item['index']['error'].nil? }
      result_count = result['items'].size
      puts "Imported #{result_count - failures.size}/#{result_count} items OK"

      if failures.any?
        puts "\nERROR: The following items failed to import correctly:"
        failures.each do |item|
          puts "#{ item['index']['_id'] }: #{ item['index']['error'] }"
        end
      end
      return result['items']
    end

    def self.process_input_file(json_file)
      # Load and pre-process items from the json file
      items_file = File.expand_path(json_file, __FILE__)
      items = JSON.load( File.read(items_file) )
      puts "Loaded #{items.size} items from source JSON file"
      #TODO: Should not need the below if we are posting to the item type within ES
      items.each {|item| item['_type'] = "item"}
    end

    def self.recreate_river!
      repository_uri = URI.parse(V1::Config.get_repository_endpoint)

      river_payload = {
        type: "couchdb",
        couchdb: {
          host: repository_uri.host,
          port: repository_uri.port,
          db: V1::Config::REPOSITORY_DATABASE,
          filter: nil
        },
        index: {
          index: V1::Config::SEARCH_INDEX,
          type: 'item'
        }
      }

      Tire::Configuration.url(V1::Config.get_search_endpoint)
      delete_river!
      create_result = Tire::Configuration.client.put(
                                                  "#{Tire::Configuration.url}/_river/items/_meta",
                                                  river_payload.to_json
                                                  )
      puts "River create: #{create_result.inspect}"
      refresh_result = Tire.index('_river').refresh
      puts "River refresh: #{refresh_result.inspect}"
    end

    def self.delete_river!
      Tire::Configuration.client.delete("#{V1::Config.get_search_endpoint}/_river/items")
    end
  end

end
