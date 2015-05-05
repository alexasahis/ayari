require 'sqlite3'
require 'sequel'
require 'dropbox_sdk'
require 'httpclient'
require 'ayari/storage'


module Ayari

	class SyncClient

		LONGPOLL_DELTA_URL = 'https://api-notify.dropbox.com/1/longpoll_delta'
		private_constant :LONGPOLL_DELTA_URL

		def put_log(msg)
			@logger.info(msg) if @logger
		end

		def initialize(access_token, logger=nil)

			@dropbox_client = DropboxClient.new(access_token)
			@storage = Ayari::Storage.new
			@cursor = nil
			@logger = logger

		end

		def to_cache_filename(metadata)

			def to_md5(text)
				Digest::MD5.new.update(text).to_s
			end

			rev = metadata['rev']
			path = metadata['path']

			to_md5(to_md5(path) + rev) + File.extname(path)

		end

		def block_until_delta_notification()

			return if !@cursor

			timeout = 90
			http_client = HTTPClient.new
			http_client.receive_timeout = timeout + 100
			http_client.ssl_config.ssl_version = :SSLv23
			params = {cursor: @cursor, timeout: timeout}

			loop do
				raw_res = http_client.get_content(LONGPOLL_DELTA_URL, params)
				res = JSON.parse(raw_res)
				return res['backoff'] if res['changes']
			end

		end

		def clear()

			@storage.remove_r('')
			Dir.foreach(Ayari::Storage::CACHE_DIRECTORY).each do |fname|
				path = File.join(Ayari::Storage::CACHE_DIRECTORY, fname)
				next if File.directory?(path)
				File.delete(path)
				put_log("deleted: #{path}")
			end

		end

		def sync()

			delta_info = @dropbox_client.delta(@cursor)
			entries = delta_info['entries']
			@cursor = delta_info['cursor']

			@storage.remove_r('') if delta_info['reset']

			entries.each do |remote_path, metadata|

				if !metadata
					@storage.remove_r(remote_path)
					put_log("deleted: #{remote_path}")
					next
				end

				next if metadata['is_dir']

				registering_path = remote_path

				cache_filename = to_cache_filename(metadata)
				cache_path = File.join(Ayari::Storage::CACHE_DIRECTORY, cache_filename)
				size = metadata['bytes']

				if !File.exists?(cache_path) || File.size(cache_path) != size
					content = @dropbox_client.get_file(remote_path)
					File.write(cache_path, content)
					put_log("created: #{cache_filename}")
				end

				@storage.update(registering_path, cache_filename)
				put_log("linked: #{registering_path} -> #{cache_filename}")

			end

			@cursor

		end

	end

end
