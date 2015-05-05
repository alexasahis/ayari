require 'rspec_helper'
require 'ayari/storage'


describe Ayari::Storage do

	before do

		FileUtils.expects(:mkdir_p).returns(nil)
		@mem_db = Sequel.sqlite
		Sequel.expects(:connect).returns(@mem_db)

		@storage = Ayari::Storage.new

	end

	it 'should return true in #exists? if the remote_path is registered' do

		remote_path = 'remote01.txt'
		local_filename = 'local01.txt'
		@storage.update(remote_path, local_filename)
		expect(@storage.exists?(remote_path)).to eq true

	end

	it 'should return a valid path in #get_local_path if the remote_path is registered' do

		remote_path = 'remote02.txt'
		local_filename = 'local02.txt'
		@storage.update(remote_path, local_filename)
		local_path = @storage.get_local_path(remote_path)
		expect(local_path).to eq File.join(Ayari::Storage::CACHE_DIRECTORY, local_filename)

	end

	it 'should return false in #exists? if the remote_path is not registered' do

		remote_path = 'remote03.txt'
		expect(@storage.exists?(remote_path)).to eq false

	end

	it 'should raise an error in #get_local_path if the remote_path is not registered' do

		remote_path = 'remote04.txt'
		expect{@storage.get_local_path(remote_path)}.to raise_error

	end

	it 'should return false in #exists? if the remote_path is removed' do

		remote_path = 'remote05.txt'
		local_filename = 'local05.txt'
		@storage.update(remote_path, local_filename)
		@storage.remove_r(remote_path)
		expect(@storage.exists?(remote_path)).to eq false

	end

	it 'should raise an error in #get_local_path if the remote_path is removed' do

		remote_path = 'remote06.txt'
		local_filename = 'local06.txt'
		@storage.update(remote_path, local_filename)
		@storage.remove_r(remote_path)
		expect{@storage.get_local_path(remote_path)}.to raise_error

	end

	it 'should remove all files in the directory when the param of #remove_r is a directory' do

		remote_filename = 'remote07.txt'
		remote_dir_paths = ['dir1', 'dir2/', '']
		local_filename = 'local07.txt'

		remote_dir_paths.each do |remote_dir|
			remote_path = File.join(remote_dir, remote_filename)
			@storage.update(remote_path, local_filename)
			@storage.remove_r(remote_dir)
			expect(@storage.exists?(remote_path)).to eq false
			expect{@storage.get_local_path(remote_path)}.to raise_error
		end

	end

end
