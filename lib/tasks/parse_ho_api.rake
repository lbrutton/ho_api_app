desc "fill database with bulk API apps, cross-check with offers from HasOffers, then fill empty creative slots"
task :parse_ho_api => :environment do 

api_uri = URI #{HO_API_here}
proxy = URI "http://quotaguard2619:dd0d6e315d59@us-east-1-static-brooks.quotaguard.com:9293"
response = Net::HTTP.start(api_uri.host, api_uri.port, proxy.host, proxy.port, proxy.user, 'dd0d6e315d59') do |http|
  request = Net::HTTP::Get.new api_uri.request_uri
  http.request request
end
response_body = JSON.parse response.body
@response_array = response_body["response"]["data"].values
# cross-check with games already in DB, and add bundle ids that aren't already there
for i in (0..(@response_array.length - 1))
  preview = @response_array[i]["Offer"]["preview_url"]
  @game_name = @response_array[i]["Offer"]["name"]
  # exclude every offer with redirect in the name
  if !@game_name.match('(?i)redirect') and !@game_name["Pro Sniper"]
    # check for iOS bundle id
    if preview.match('(?<=/id).*(?=\/)')
      @bundle_id = preview.match('(?<=/id).*(?=\/)')
      if find_game
        i += 1
      else
        create_game("iOS", i)
      end
    elsif preview.match('(?<=/id).*(?=\?)')
      @bundle_id = preview.match('(?<=/id).*(?=\?)')
      if find_game
        i += 1
      else
        create_game("iOS", i)
      end
    elsif preview.match('(?<=/id).*')
      @bundle_id = preview.match('(?<=id).*')
      if find_game
        i += 1
      else
       create_game("iOS", i)
      end 
    # check for play store bundle id, with "hl=" at the end, or something similar
    elsif preview.match('(?<=id=).*(?=\&)')
      @bundle_id = preview.match('(?<=id=).*(?=\&)')
      if find_game
        i += 1
      else
        create_game("Android", i)
      end 
    #  finally, look for preview links with just a bundle id at the end, then nothing
    elsif preview.match('(?<=id=).*')
      @bundle_id = preview.match('(?<=id=).*')
      if find_game
        i += 1
      else
        create_game("Android", i)
      end 
    # if not found, move to next element              
    else
      i += 1
    end
  end
end