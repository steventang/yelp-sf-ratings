require 'yelp'
require 'csv'

@client = Yelp::Client.new({ consumer_key: ENV['YELP_CONSUMER_KEY'],
                            consumer_secret: ENV['YELP_CONSUMER_SCECRET'],
                            token: ENV['YELP_TOKEN'],
                            token_secret: ENV['YELP_TOKEN_SECRET']
                          })

@params = { term: 'restaurant',
					 limit: 10,
					 category_filter: 'restaurants',
					 sort: 0 }

def make_box(swlo, swla, nelo, nela) # order rearranged to fit yelp order
	{ sw_latitude: swla, sw_longitude: swlo, ne_latitude: nela, ne_longitude: nelo }
end

def split_into_boxes(big_box, longitude_size, latitude_size)
	box_array = []
	# subtract latitude and longitude size to prevent spillage past borders
	for lat in (big_box[:sw_latitude]..big_box[:ne_latitude]).step(latitude_size) do
		for lon in (big_box[:sw_longitude]..big_box[:ne_longitude]).step(longitude_size) do
			box_array << make_box(lon, lat, lon+longitude_size, lat+latitude_size) # fit yelp order
		end
	end
	box_array
end

def bounding_box_search(box)
	@client.search_by_bounding_box(box, @params).businesses
end

def calculate_box_rating(box)
	box_total = 0
	biz = bounding_box_search box
#	puts "In bounding box #{box} #{'*' * 30}"
#	output biz
	biz.each { |b| box_total += b.rating if b.review_count > 9 } # require to have 10 or more reviews to count
	avg_rating = if biz.count { |b| b.review_count > 9 } > 1 then box_total / biz.count{ |b| b.review_count > 9 } else 0 end # require sample size of 5 to get a rating
	avg_rating.round(2)
end

# output some stuff about the response
def output(biz_array)
	biz_array.each do |b|
		puts "#{b.name}, #{b.rating}, #{b.location.postal_code}"
	end
end

def generate_csv(box_array)
	CSV.open('data/yelp_data.csv', "w") do |csv|
		csv << ["sw_longitude", "sw_latitude", "ne_longitude", "ne_latitude", "box_rating"]
		box_array.each do |box|
			csv << [box[:sw_longitude], box[:sw_latitude], box[:ne_longitude], box[:ne_latitude], calculate_box_rating(box)]
		end
	end
	puts "CSV generated"
end

sf_box = make_box(-122.514941,37.70814,-122.35714,37.811675)
box_array = split_into_boxes(sf_box, 0.006, 0.004)
generate_csv(box_array)