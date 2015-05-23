require 'ayari/local_storage'


module Ayari

	class Storage

		def self.create_storage()
			Ayari::LocalStorage.new
		end

	end

end
