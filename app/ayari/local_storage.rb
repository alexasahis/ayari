require 'sqlite3'
require 'sequel'
require 'fileutils'


module Ayari

	class LocalStorage

		CACHE_DIRECTORY = File.join(File.dirname(__FILE__), "ayari_cache")
		SEQUEL_CONNECTION_STRING = "sqlite://#{File.join(CACHE_DIRECTORY, "cache.db")}"
		TABLE_NAME = :content

		private_constant :CACHE_DIRECTORY
		private_constant :SEQUEL_CONNECTION_STRING
		private_constant :TABLE_NAME


		def initialize(cache_directory=CACHE_DIRECTORY,
			sequel_connection_string=SEQUEL_CONNECTION_STRING)

			@root = cache_directory
			FileUtils.mkdir_p(cache_directory)
			@db = Sequel.connect(sequel_connection_string)

			initialize_database()

			@table = @db[TABLE_NAME]

		end

		def initialize_database(force=false)

			@db.transaction(isolation: :serializable) do

				if force
					@db.drop_table(TABLE_NAME) if @db.table_exists?(TABLE_NAME)
				end

				if !@db.table_exists?(TABLE_NAME)

					@db.create_table(TABLE_NAME) do
						String :remote_path, text: true, primary_key: true
						String :local_filename, text: true
					end

				end

			end

		end

		def exists?(remote_path)

			@table.where(remote_path: remote_path.downcase).count > 0

		end

		def get_local_filesize(local_file)

			local_path = File.join(@root, local_file)
			size = nil
			begin
				size = File.size(local_path)
			rescue
			end
			size
		end

		def get_local_path(remote_path)

			results = @table.where(remote_path: remote_path.downcase).all
			if results.count != 1
				raise StandardError.new('invalid path')
			end

			File.join(@root, results.first[:local_filename])

		end

		def get_content(path)

			data = nil

			@db.transaction(isolation: :repeatable) do

				local_path = get_local_path(path)
				data = File.binread(local_path)

			end

			data

		end

		def update_local_filename(remote_path, local_filename)

			@db.transaction(isolation: :serializable) do

				target = @table.where(remote_path: remote_path.downcase).for_update
				if target.count == 0
					@table.insert(remote_path: remote_path.downcase, local_filename: local_filename)
				else
					target.update(local_filename: local_filename)
				end

			end

		end

		def update_content(local_filename, content)

			@db.transaction(isolation: :serializable) do

				local_path = File.join(@root, local_filename)
				FileUtils.mkdir_p(File.dirname(local_path))
				File.binwrite(local_path, content)

			end

		end

		def remove_r(remote_path)

			remote_path = remote_path[0..-2] if remote_path[-1] == "/"
			escaped_path = @table.escape_like(remote_path.downcase)
			target = escaped_path + '/%'

			local_path_list = []

			@db.transaction(isolation: :serializable) do

				@table.where(Sequel.like(:remote_path, target)).delete
				@table.where(remote_path: remote_path).delete

			end

		end

	end

end
