# require "xml"

LayerType.delete_all
ActiveRecord::Base.connection.execute("TRUNCATE TABLE layer_types;")

Layer.delete_all
ActiveRecord::Base.connection.execute("TRUNCATE TABLE layers;")

["single","repeat","box", "color", "repeat_box"].each do |type|
	layer_type = LayerType.create! :name => type.titleize, :slug => type
	layer_type.icon.store! (File.open(File.join(Rails.root, "db/seed/layer_type/#{type}.png")))
	layer_type.save!
end

	Layer.create! :name => "root"	, :layer_type => LayerType.find(3)
# @file = "#{Rails.root}/db/externe.xml"

# doc = XML::Document.file(@file)
# reader = XML::Reader.document(doc)

# @layers = Hash.new
# @root
# #XML::Reader.file(@svg_file, :options => XML::Parser::Options::NOBLANKS | XML::Parser::Options::NOENT)
# while reader.read
# 	unless reader.node_type == XML::Reader::TYPE_END_ELEMENT
# 		node = reader.expand
# 		case  reader.name
# 		when "psd"
# 			@root = Layer.create! :name => "root",
# 				:width => node.attributes["width"],
# 				:height => node.attributes["height"],
# 				:scale => node.attributes["scale"]

# 		when "layer"
# 			Layer.create! :name => node.attributes["name"],
# 				:layer_width => node.attributes["layerwidth"],
# 				:layer_height => node.attributes["layerheight"],
# 				:scale => node.attributes["scale"],
# 				:layer_type => LayerType.find(1),
# 				:parent => @root
# 		end
# 	end
# end
