require 'digest/sha2'
require 'haml'
require 'sinatra/base'
require 'ayari/storage'
require 'ayari/md_processor'


module Ayari

	class Router < Sinatra::Base

		INFERRING_EXTS = ['.md']
		INFERRING_FILENAMES = ['index.md', 'top.md']

		configure :development do
			enable :logging
		end

		get /\A(.*)\z/ do |req_path|

			storage = Ayari::Storage.create_storage

			remote_path_list = [req_path]
			remote_path_list += INFERRING_FILENAMES.map { |fname| File.join(req_path, fname) }
			if File.extname(req_path) == ""
				remote_path_list += INFERRING_EXTS.map { |ext| req_path + ext }
			end

			remote_path = remote_path_list.find { |path| storage.exists?(path) }

			raise Sinatra::NotFound if !remote_path

			case File.extname(remote_path)
			when '.haml'

				last_modified storage.get_updated_time(remote_path)
				haml storage.get_content(remote_path).force_encoding('utf-8')

			when '.md'

				md_text = storage.get_content(remote_path).force_encoding('utf-8')
				raw_html, locals, template_name = Ayari::MdProcessor.process_md(md_text)
				if template_name[0] != '/'
					template_name = File.join(File.dirname(remote_path), template_name)
				end
				raise Sinatra::NotFound if ! storage.exists?(template_name)

				all_files = [remote_path, template_name]
				updated_times = all_files.map{ |path| storage.get_updated_time(path) }
				last_modified updated_times.max

				haml_text = storage.get_content(template_name).force_encoding('utf-8')
				locals[:content] = raw_html
				haml haml_text, locals: locals, ugly: true

			else

				send_file storage.get_local_path(remote_path)

			end

		end

	end

end
