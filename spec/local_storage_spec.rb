require 'tmpdir'
require 'rspec_helper'
require 'ayari/local_storage'


describe Ayari::LocalStorage do

	subject(:tempdir) { Dir.mktmpdir }
	subject(:sequel_string) { "sqlite://#{File.join(tempdir, "cache.db")}" }
	subject(:storage) { Ayari::LocalStorage.new(tempdir, sequel_string) }

	context 'when only 1 file is registered' do

		let(:remote_path) { '/remote/path.txt' }
		let(:content) { 'file-content' }
		let(:updated_at) { Time.new(2010, 1, 23, 4, 5, 6) }

		let(:local_filename) { 'local-filename.txt' }
		let(:local_path) { File.join(tempdir, local_filename) }

		let(:wrong_remote_path) { '/remote/wrong-path.txt' }

		before(:each) do
			Time.stubs(:now).returns(updated_at)
			storage.update(remote_path, local_filename, content)
		end

		it 'should create the local file' do
			expect(File.exists?(local_path)).to eq true
		end

		describe '#exists?' do
			it 'should return true if the file exists' do
				expect(storage.exists?(remote_path)).to eq true
			end
			it 'should return false if the file does not exist' do
				expect(storage.exists?(wrong_remote_path)).to eq false
			end
		end

		describe '#get_local_path' do
			it 'should return a valid path if the file exists' do
				expect(storage.get_local_path(remote_path)).to eq local_path
			end
			it 'should raise an error if the file does not exist' do
				expect{ storage.get_local_path(wrong_remote_path) }.to raise_error(ArgumentError)
			end
		end

		describe '#get_content' do
			it 'should store contents correctly' do
				expect(storage.get_content(remote_path)).to eq content
			end
			it 'should raise an error if the file does not exist' do
				expect{ storage.get_content(wrong_remote_path) }.to raise_error(ArgumentError)
			end
		end

		describe '#get_updated_time' do
			it 'should store the time when the file is updated' do
				expect(storage.get_updated_time(remote_path)).to eq updated_at
			end
			it 'should raise an error if the file does not exist' do
				expect{ storage.get_updated_time(wrong_remote_path) }.to raise_error(ArgumentError)
			end
		end

	end

	context 'when a file is overwrote' do

		let(:remote_path) { '/remote/path.txt' }
		let(:old_content) { 'old-file-content' }
		let(:new_content) { 'new-file-content' }
		let(:old_updated_at) { Time.new(2010, 1, 23, 4, 5, 6) }
		let(:new_updated_at) { Time.new(2015, 2, 24, 8, 16, 32) }

		let(:old_local_filename) { 'old-local-filename.txt' }
		let(:new_local_filename) { 'new-local-filename.txt' }
		let(:old_local_path) { File.join(tempdir, old_local_filename) }
		let(:new_local_path) { File.join(tempdir, new_local_filename) }

		before(:each) do
			Time.stubs(:now).returns(old_updated_at)
			storage.update(remote_path, old_local_filename, old_content)
			Time.stubs(:now).returns(new_updated_at)
			storage.update(remote_path, new_local_filename, new_content)
		end

		it 'should remove the old local file' do
			expect(File.exists?(old_local_path)).to eq false
		end

		it 'should create the new local file' do
			expect(File.exists?(new_local_path)).to eq true
		end

		describe '#exists?' do
			it 'should return true' do
				expect(storage.exists?(remote_path)).to eq true
			end
		end

		describe '#get_local_path' do
			it 'should return the new local path' do
				expect(storage.get_local_path(remote_path)).to eq new_local_path
			end
		end

		describe '#get_content' do
			it 'should return the new content' do
				expect(storage.get_content(remote_path)).to eq new_content
			end
		end

		describe '#get_updated_time' do
			it 'should store the time when the new file is updated' do
				expect(storage.get_updated_time(remote_path)).to eq new_updated_at
			end
		end

	end

	describe '#remove_r' do

		context 'when 1 file is deleted' do

			let(:remaining_remote_path) { '/remote/remaining-path.txt' }
			let(:deleted_remote_path) { '/remote/deleted-path.txt' }
			let(:content) { 'new-file-content' }

			let(:remaining_local_filename) { 'remaining-local-filename.txt' }
			let(:deleted_local_filename) { 'deleted-local-filename.txt' }
			let(:remaining_local_path) { File.join(tempdir, remaining_local_filename) }
			let(:deleted_local_path) { File.join(tempdir, deleted_local_filename) }

			before(:each) do
				storage.update(remaining_remote_path, remaining_local_filename, content)
				storage.update(deleted_remote_path, deleted_local_filename, content)
				storage.remove_r(deleted_remote_path)
			end

			it 'should remove the specified file' do

				# TODO: split this

				expect(storage.exists?(deleted_remote_path)).to eq false
				expect{ storage.get_local_path(deleted_remote_path) }.to raise_error(ArgumentError)
				expect{ storage.get_content(deleted_remote_path) }.to raise_error(ArgumentError)
				expect{ storage.get_updated_time(deleted_remote_path) }.to raise_error(ArgumentError)
				expect(File.exists?(deleted_local_path)).to eq false

			end

		end

		context 'when 1 directory is deleted' do

			let(:remote_paths) { [
				'/dir01/file01.txt',
				'/dir02/file02.txt',
				'/dir03/file03.txt',
				'/dir03/dir04/file04.txt',
				'/file05.txt',
			] }

			let(:content) { 'file-content' }

			before(:each) do
				remote_paths.each do |remote_path|
					local_filename = File.basename(remote_path)
					storage.update(remote_path, local_filename, content)
				end
			end

			# TODO: check whether the local files exist
			# TODO: split the examples

			context 'deleted with /dirname style' do

				let(:target) { '/dir01' }

				before(:each) do
					storage.remove_r(target)
				end

				it 'should delete the specified directory' do
					expect(storage.exists?(remote_paths[0])).to eq false
				end

				it 'should not delete other files' do
					remote_paths[1..-1].each do |p|
						expect(storage.exists?(p)).to eq true
					end
				end

			end

			context 'deleted with /dirname/ style' do

				let(:target) { '/dir01/' }

				before(:each) do
					storage.remove_r(target)
				end

				it 'should delete the specified directory' do
					expect(storage.exists?(remote_paths[0])).to eq false
				end

				it 'should not delete other files' do
					remote_paths[1..-1].each do |p|
						expect(storage.exists?(p)).to eq true
					end
				end

			end

			context 'deleted with /' do

				let(:target) { '/' }

				before(:each) do
					storage.remove_r(target)
				end

				it 'should delete all files' do
					remote_paths.each do |p|
						expect(storage.exists?(p)).to eq false
					end
				end

			end

		end

	end

end
