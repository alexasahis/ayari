require 'sqlite3'
require 'sequel'
require 'fileutils'


module Ayari

	class LocalStorage

		CACHE_DIRECTORY = File.join(File.dirname(__FILE__), '..', '..', "ayari_cache")
		SEQUEL_CONNECTION_STRING = "sqlite://#{File.join(CACHE_DIRECTORY, "cache.db")}"
		TABLE_NAME = :content

		private_constant :CACHE_DIRECTORY
		private_constant :SEQUEL_CONNECTION_STRING
		private_constant :TABLE_NAME


		def initialize(cache_directory=CACHE_DIRECTORY,
			sequel_connection_string=SEQUEL_CONNECTION_STRING)

			@root = cache_directory.dup.freeze
			@sequel_connection_string = sequel_connection_string.dup.freeze
			FileUtils.mkdir_p(cache_directory)
			@db = Sequel.connect(sequel_connection_string)

			# remove the connection from Sequel's cache
			#   in order to prevent file descriptor leakage
			#   when using sqlite as the database server
			Sequel::DATABASES.delete(@db)

			initialize_database()

			@table = @db[TABLE_NAME]

		end

		def initialize_database(force=false)

			# delete all files before the transaction begins because
			#   deleting sqlite's file in the transaction causes an Exception
			# this is not good in terms of consistency
			if force
				FileUtils.rm_r(@root)
				FileUtils.mkdir_p(@root)
			end

			@db.transaction(isolation: :serializable) do

				if force
					@db.drop_table(TABLE_NAME) if @db.table_exists?(TABLE_NAME)
				end

				if !@db.table_exists?(TABLE_NAME)

					@db.create_table(TABLE_NAME) do
						String :remote_path, text: true, primary_key: true
						String :local_filename, text: true
						DateTime :updated_at
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
				raise ArgumentError.new('invalid path')
			end

			File.join(@root, results.first[:local_filename])

		end

		def get_content(remote_path)

			data = nil

			begin

				@db.transaction(isolation: :repeatable) do

					local_path = get_local_path(remote_path)
					data = File.binread(local_path)

				end

			rescue Sequel::DatabaseError => db_err

				raise db_err.wrapped_exception

			end

			data

		end

		def get_updated_time(remote_path)

			results = @table.where(remote_path: remote_path.downcase).all
			if results.count != 1
				raise ArgumentError.new('invalid path')
			end

			results.first[:updated_at]

		end

		def update(remote_path, local_filename, content)

			@db.transaction(isolation: :serializable) do

				target = @table.where(remote_path: remote_path.downcase).for_update
				local_path = File.join(@root, local_filename)

				if target.count == 0
					@table.insert(remote_path: remote_path.downcase,
						local_filename: local_filename,
						updated_at: Time.now)
				else
					old_path = File.join(@root, target.first[:local_filename])
					FileUtils.rm(old_path)
					target.update(local_filename: local_filename,
						updated_at: Time.now)
				end

				FileUtils.mkdir_p(File.dirname(local_path))
				File.binwrite(local_path, content)

			end

		end

		def remove_r(remote_path)

			remote_path = remote_path[0..-2] if remote_path[-1] == "/"
			escaped_path = @table.escape_like(remote_path.downcase)
			target = escaped_path + '/%'

			@db.transaction(isolation: :serializable) do

				children_cursor = @table.where(Sequel.like(:remote_path, target))
				file_cursor = @table.where(remote_path: escaped_path)

				del_children = children_cursor.all.map{ |item| File.join(@root, item[:local_filename]) }
				del_file = file_cursor.all.map {|item| File.join(@root, item[:local_filename]) }

				(del_children + del_file).each do |del_target|
					FileUtils.rm(del_target)
				end

				children_cursor.delete
				file_cursor.delete

			end

		end

	end

end
