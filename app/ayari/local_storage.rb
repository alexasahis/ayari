require 'sqlite3'
require 'sequel'
require 'fileutils'


module Ayari

	class LocalStorage

		CACHE_DIRECTORY = File.join(File.dirname(__FILE__), "ayari_cache")
		SEQUEL_CONNECTION_STRING = "sqlite://#{File.join(CACHE_DIRECTORY, "cache.db")}"
		TABLE_NAME = :content

		private_constant :SEQUEL_CONNECTION_STRING
		private_constant :TABLE_NAME

		def raw_initialize()
			FileUtils.mkdir_p(CACHE_DIRECTORY) if !Dir.exists?(CACHE_DIRECTORY)
		end

		def raw_write(local_path, content)
			File.binwrite(local_path, content)
		end

		def raw_read(local_path)
			File.binread(local_path)
		end

		def raw_size(local_path)
			begin
				return File.size(local_path)
			rescue
			end
			return nil
		end

		def initialize()

			raw_initialize()

			@db = Sequel.connect(SEQUEL_CONNECTION_STRING)

			if !@db.table_exists?(TABLE_NAME)

				@db.create_table(TABLE_NAME) do
					String :remote_path, text: true, primary_key: true
					String :local_filename, text: true
				end

			end

			@table = @db[TABLE_NAME]

		end

		def exists?(remote_path)

			@table.where(remote_path: remote_path.downcase).count > 0

		end

		def get_local_filesize(local_file)

			local_path = File.join(CACHE_DIRECTORY, local_file)
			raw_size(local_path)

		end

		def get_local_path(remote_path)

			results = @table.where(remote_path: remote_path.downcase).all
			if results.count != 1
				raise StandardError.new('invalid path')
			end

			File.join(CACHE_DIRECTORY, results.first[:local_filename])

		end

		def get_content(path)

			local_path = get_local_path(path)
			raw_read(local_path)

		end

		def update_local_filename(remote_path, local_filename)

			@db.transaction do

				target = @table.where(remote_path: remote_path.downcase).for_update
				if target.count == 0
					@table.insert(remote_path: remote_path.downcase, local_filename: local_filename)
				else
					target.update(local_filename: local_filename)
				end

			end

		end

		def update_content(local_filename, content)

			local_path = File.join(CACHE_DIRECTORY, local_filename)
			raw_write(local_path, content)

		end

		def remove_r(remote_path)

			remote_path = remote_path[0..-2] if remote_path[-1] == "/"
			escaped_path = @table.escape_like(remote_path.downcase)
			target = escaped_path + '/%'

			local_path_list = []

			@db.transaction() do

				@table.where(Sequel.like(:remote_path, target)).delete
				@table.where(remote_path: remote_path).delete

			end

		end

	end

end
