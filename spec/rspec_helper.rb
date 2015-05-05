$:.unshift(File.join(File.dirname(File.expand_path(__FILE__)), '..', 'app'))
require 'mocha'


RSpec.configure do |config|
	config.mock_framework = :mocha
end
