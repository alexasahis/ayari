require 'tmpdir'
require 'rspec_helper'
require 'ayari/local_storage'


describe Ayari::LocalStorage do

	before :each do

		@tempdir = Dir.mktmpdir
		@sequel_string = "sqlite://#{File.join(@tempdir, "cache.db")}"
		@storage = Ayari::LocalStorage.new(@tempdir, @sequel_string)

	end

	it 'should return true in #exists? if the remote_path is registered' do

		remote_path = '/remote/path.txt'
		local_filename = 'local-filename.txt'
		content = 'file-content'

		@storage.update(remote_path, local_filename, content)
		expect(@storage.exists?(remote_path)).to eq true

	end

	it 'should return a valid path in #get_local_path if the remote_path is registered' do

		remote_path = '/remote/path.txt'
		local_filename = 'local-filename.txt'
		content = 'file-content'

		@storage.update(remote_path, local_filename, content)
		local_path = @storage.get_local_path(remote_path)
		expect(local_path).to eq File.join(@tempdir, local_filename)

	end

	it 'should return false in #exists? if the remote_path is not registered' do

		remote_path = '/remote/path.txt'
		expect(@storage.exists?(remote_path)).to eq false

	end

	it 'should raise an error in #get_local_path if the remote_path is not registered' do

		remote_path = '/remote/path.txt'
		expect{@storage.get_local_path(remote_path)}.to raise_error

	end

	it 'should remove the file when #remove_r is called' do

		remote_path = '/remote/path.txt'
		local_filename = 'local-filename.txt'
		content = 'file-content'

		@storage.update(remote_path, local_filename, content)
		@storage.remove_r(remote_path)

		expect(@storage.exists?(remote_path)).to eq false
		expect{@storage.get_local_path(remote_path)}.to raise_error
		expect(File.exists?(File.join(@tempdir, local_filename))).to eq false

	end

	it 'should remove all files in the directory when the param of #remove_r is a directory' do

		remote_filename = 'remote-filename.txt'
		remote_dir_paths = ['/dir-1', '/dir-2/', '/dir-3/dir-3-1', '']
		local_filename = 'local-filename.txt'
		content = 'file-content'

		remote_dir_paths.each do |remote_dir|

			remote_path = File.join(remote_dir, remote_filename)
			@storage.update(remote_path, local_filename, content)
			@storage.remove_r(remote_dir)

			expect(@storage.exists?(remote_path)).to eq false
			expect{@storage.get_local_path(remote_path)}.to raise_error
			expect(File.exists?(File.join(@tempdir, local_filename))).to eq false

		end

	end

end
