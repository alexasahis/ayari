require 'sqlite3'
require 'sequel'
require 'dropbox_sdk'
require 'httpclient'
require 'ayari/storage'


module Ayari

	class SyncClient

		LONGPOLL_DELTA_URL = 'https://api-notify.dropbox.com/1/longpoll_delta'
		POLL_TIMEOUT = 90
		private_constant :LONGPOLL_DELTA_URL
		private_constant :POLL_TIMEOUT

		def put_log(msg)
			@logger.info(msg) if @logger
		end

		def initialize(access_token, logger=nil)

			@dropbox_client = DropboxClient.new(access_token)
			@storage = Ayari::Storage.create_storage
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

			http_client = HTTPClient.new
			http_client.receive_timeout = POLL_TIMEOUT + 100
			http_client.ssl_config.ssl_version = :SSLv23
			params = {cursor: @cursor, timeout: POLL_TIMEOUT}

			loop do
				raw_res = http_client.get_content(LONGPOLL_DELTA_URL, params)
				res = JSON.parse(raw_res)
				return res['backoff'] if res['changes']
			end

		end

		def sync()

			delta_info = @dropbox_client.delta(@cursor)
			entries = delta_info['entries']
			@cursor = delta_info['cursor']

			if delta_info['reset']
				@storage.remove_r('')
				put_log("reset")
			end

			entries.each do |remote_path, metadata|

				if !metadata
					@storage.remove_r(remote_path)
					put_log("removed: #{remote_path}")
					next
				end

				next if metadata['is_dir']

				cache_filename = to_cache_filename(metadata)
				size = metadata['bytes']

				begin
					content = @dropbox_client.get_file(remote_path)
				rescue
					put_log("error when downloading: #{remote_path}")
					next
				end

				existed = @storage.exists?(remote_path)
				@storage.update(remote_path, cache_filename, content)

				event_str = existed ? 'updated' : 'created'
				put_log("#{event_str}: #{remote_path} -> #{cache_filename}")

			end

			@cursor

		end

	end

end
