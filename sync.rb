$:.unshift(File.join(File.dirname(File.expand_path(__FILE__)), 'app'))
require 'logger'
require 'yaml'
require 'ayari/sync_client'


if __FILE__ == $0

	yaml_path = File.join(File.dirname(__FILE__), 'config.yaml')
	config = YAML.load_file(yaml_path)

	token = config['dropbox_token']
	logger = ARGV.include?('--verbose') ? Logger.new(STDOUT) : nil
	logger.datetime_format = '%Y/%m/%d-%H:%M:%S.%L' if logger
	client = Ayari::SyncClient.new(token, logger)

	if ARGV.include?('--reset')
		client.clear
		exit
	end


	loop do

		backoff = nil

		begin

			client.sync
			backoff = client.block_until_delta_notification

		rescue StandardError => err

			logger.error(err) if logger
			sleep 60
			retry

		end

		if backoff
			sleep backoff
			logger.info("backoff: #{backoff}") if logger
		end

	end

end