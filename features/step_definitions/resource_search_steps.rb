# This file will end up with resource-agnostic versions of all the item steps

Then /^the API should return (\d+) (collection)s with "(.*?)"$/ do |count, resource, keyword|
  expect(@resource).to eq resource
  
  json = resource_query_to_json(@resource, @params)
  expect(json).to have(count).items
  json.each_with_index do |result, idx|
    expect(result.to_s.downcase).to have_content(keyword.downcase)
  end
end

When /^I (.+)-search for( the phrase)? "(.*?)"( in the "(.*?)" field)?$/ do |resource, is_phrase, keyword, junk, query_field|
  @resource = resource
  @query_field = query_field || 'q'
  @query_string = keyword
  # phrase queries get wrapped in double quotes
  query_phrase = '"' + @query_string + '"'

  @params.merge!({
                   @query_field => is_phrase.nil? ? @query_string : query_phrase
                 })
end

# When /^I search the "(.*?)" field for records with a date between "(.*?)" and "(.*?)"$/ do |field, start_date, end_date|
#   @params.merge!({
#     "#{field}.after" => start_date,
#     "#{field}.before" => end_date,
#   })
# end

# When /^I search the "(.*?)" field for records with a date (before|after) "(.*?)"$/ do |field, modifier, target_date|
#   @params.merge!({ "#{field}.#{modifier}" => target_date })
# end

# Then /^the API should return records? (.*?)$/ do |id_list|
#   json = item_query_to_json(@params, true)

#   if json.nil?
#     raise RSpec::Expectations::ExpectationNotMetError, "Query unexpectedly returned zero results for params: #{@params}"
#   end

#   expect(
#     json.map {|doc| doc['_id'] }
#   ).to match_array id_list.split(/,\s*/)
# end

# Then /^the API should return no records$/ do
#   json = item_query_to_json(@params)
#   expect(json.size).to eq 0
# end

Given /^the default search radius for location search is (\d+) miles$/ do |arg1|
  expect(V1::Searchable::Filter::DEFAULT_GEO_DISTANCE).to eq "#{arg1}mi"
end

When /^I search for records with "(.*?)" near coordinates "(.*?)"( with a range of (\d+) miles)?$/ do |field, lat_long, junk, distance|
  @params.merge!({field => lat_long})
  if distance
    distance_field = field.gsub(/^(.+)\.(.+)$/, '\1.distance')
    @params[distance_field] = distance + 'mi'
  end
end

When(/^I search for records with "(.*?)" inside the bounding box defined by "(.*?)" and "(.*?)"$/) do |field, upper_left, lower_right|
  # puts "UL: #{upper_left}"
  # puts "LR: #{lower_right}"
  @params[field] = upper_left + ':' + lower_right
end

# When(/^I (.+)-search for the date "(.*?)" in the "(.*?)" field$/) do |resource, date, field|
#   @resource = resource
#   @params[field] = date
# end
