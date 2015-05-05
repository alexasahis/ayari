require 'sqlite3'
require 'sequel'
require 'fileutils'


module Ayari

	class Storage

		CACHE_DIRECTORY = File.join(File.dirname(__FILE__), "ayari_cache")
		SEQUEL_CONNECTION_STRING = "sqlite://#{File.join(CACHE_DIRECTORY, "cache.db")}"
		TABLE_NAME = :content

		private_constant :SEQUEL_CONNECTION_STRING
		private_constant :TABLE_NAME

		def initialize()

			FileUtils.mkdir_p(CACHE_DIRECTORY)

			@db = Sequel.connect(SEQUEL_CONNECTION_STRING)

			if !@db.table_exists?(TABLE_NAME)

				@db.create_table(TABLE_NAME) do
					String :remote_path, text: true, primary_key: true
					String :local_filename, text: true
				end

			end

			@table = @db[TABLE_NAME]

		end

		def exists?(path)

			@table.where(remote_path: path.downcase).count > 0

		end

		def get_local_path(path)

			results = @table.where(remote_path: path.downcase).all
			if results.count != 1
				raise StandardError.new('invalid path')
			end

			File.join(CACHE_DIRECTORY, results.first[:local_filename])

		end

		def update(remote_path, local_filename)

			@db.transaction do

				target = @table.where(remote_path: remote_path.downcase).for_update
				if target.count == 0
					@table.insert(remote_path: remote_path.downcase, local_filename: local_filename)
				else
					target.update(local_filename: local_filename)
				end

			end

		end

		def remove_r(remote_path)

			remote_path = remote_path[0..-2] if remote_path[-1] == "/"
			escaped_path = @table.escape_like(remote_path.downcase)
			target = escaped_path + '/%'

			@db.transaction do

				@table.where(Sequel.like(:remote_path, target)).delete
				@table.where(remote_path: remote_path).delete

			end

		end

	end

end
