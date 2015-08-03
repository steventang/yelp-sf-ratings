require 'yelp'
require 'csv'

@client = Yelp::Client.new({ consumer_key: 'atcOW8wzksokuJjV_RDQTw',
                            consumer_secret: 'zz5t3khY4vQbA5CchwizLzQ7mEo',
                            token: 'vX0RFFkAOK0Nxy-f8IgfzAuUCAhEPyc2',
                            token_secret: '93c_gj4GWrNI8__uyMUvqELJlcY'
                          })

@params = { term: 'restaurant',
					 limit: 3,
					 sort: 0 }

location = { location: '94109' }

biz = []
sum_ratings = 0

def make_box(swlo, swla, nelo, nela) # order rearranged to fit yelp order
	{ sw_latitude: swla, sw_longitude: swlo, ne_latitude: nela, ne_longitude: nelo }
end

def split_into_boxes(big_box, latitude_size, longitude_size)
	box_array = []
	# subtract latitude and longitude size to prevent spillage past borders
	for lat in (big_box[:sw_latitude]..big_box[:ne_latitude]-latitude_size).step(latitude_size) do
		for lon in (big_box[:sw_longitude]..big_box[:ne_longitude]-longitude_size).step(longitude_size) do
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
	output(biz)
	biz.each.each { |b| box_total += b.rating }
	avg_rating = if biz.length != 0 then box_total/biz.length else 0 end
	avg_rating
end

# output some stuff about the response
def output(biz)
	biz.each do |b|
		puts "#{b.name}, #{b.rating}, #{b.location.postal_code}"
	end
end

def generate_csv(box_array)
	CSV.open('yelp_data.csv', "w") do |csv|
		box_array.each do |box|
			csv << [box[:sw_longitude], box[:sw_latitude], box[:ne_longitude], box[:ne_latitude], calculate_box_rating(box)]
		end
	end
end

sample_box = make_box(-122.512452,37.713436,-122.386966,37.807809)
box_array = split_into_boxes(sample_box, 0.02, 0.02)
generate_csv(box_array)

# for b in box_array
# 	puts "In the box #{b}"
# 	puts "The rating is #{calculate_box_rating b}"
# end