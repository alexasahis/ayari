require 'rspec_helper'
require 'ayari/local_storage'


describe Ayari::LocalStorage do

	before do

		Ayari::LocalStorage.any_instance.stubs(:raw_initialize).returns(nil)
		Ayari::LocalStorage.any_instance.stubs(:raw_write).returns(nil)
		Ayari::LocalStorage.any_instance.stubs(:raw_read).returns('')
		Ayari::LocalStorage.any_instance.stubs(:raw_size).returns(nil)

	end

	before :each do

		@mem_db = Sequel.sqlite
		Sequel.expects(:connect).returns(@mem_db)
		@storage = Ayari::LocalStorage.new

	end

	it 'should return true in #exists? if the remote_path is registered' do

		remote_path = '/remote/path.txt'
		local_filename = 'local-filename.txt'
		content = 'file-content'

		@storage.update_content(remote_path, content)
		@storage.update_local_filename(remote_path, local_filename)
		expect(@storage.exists?(remote_path)).to eq true

	end

	it 'should return a valid path in #get_local_path if the remote_path is registered' do

		remote_path = '/remote/path.txt'
		local_filename = 'local-filename.txt'
		content = 'file-content'

		@storage.update_content(remote_path, content)
		@storage.update_local_filename(remote_path, local_filename)
		local_path = @storage.get_local_path(remote_path)
		expect(local_path).to eq File.join(Ayari::LocalStorage::CACHE_DIRECTORY, local_filename)

	end

	it 'should return false in #exists? if the remote_path is not registered' do

		remote_path = '/remote/path.txt'
		expect(@storage.exists?(remote_path)).to eq false

	end

	it 'should raise an error in #get_local_path if the remote_path is not registered' do

		remote_path = '/remote/path.txt'
		expect{@storage.get_local_path(remote_path)}.to raise_error

	end

	it 'should respond as if there are no such file if the registered file is removed' do

		remote_path = '/remote/path.txt'
		local_filename = 'local-filename.txt'
		content = 'file-content'

		@storage.update_content(remote_path, content)
		@storage.update_local_filename(remote_path, local_filename)
		@storage.remove_r(remote_path)

		expect(@storage.exists?(remote_path)).to eq false
		expect{@storage.get_local_path(remote_path)}.to raise_error

	end

	it 'should remove all files in the directory when the param of #remove_r is a directory' do

		remote_filename = 'remote-filename.txt'
		remote_dir_paths = ['/dir-1', '/dir-2/', '/dir-3/dir-3-1', '']
		local_filename = 'local-filename.txt'
		content = 'file-content'

		remote_dir_paths.each do |remote_dir|

			remote_path = File.join(remote_dir, remote_filename)
			@storage.update_content(remote_path, content)
			@storage.update_local_filename(remote_path, local_filename)
			expect(@storage.exists?(remote_path)).to eq true
			@storage.remove_r(remote_dir)
			expect(@storage.exists?(remote_path)).to eq false
			expect{@storage.get_local_path(remote_path)}.to raise_error

		end

	end

	it 'should not update local filename when only #update_content is called' do

		remote_path = '/remote/path.txt'
		local_filename = 'local-filename.txt'
		content = 'file-content'

		@storage.update_content(local_filename, content)
		expect(@storage.exists?(remote_path)).to eq false
		expect{@storage.get_local_path(remote_path)}.to raise_error

	end

end
