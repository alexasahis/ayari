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

			storage = Ayari::Storage.new

			remote_path_list = [req_path]
			if req_path[-1] == '/'
				remote_path_list += INFERRING_FILENAMES.map { |fname| req_path + fname }
			elsif File.extname(req_path) == ""
				remote_path_list += INFERRING_EXTS.map { |ext| req_path + ext }
			end

			remote_path = remote_path_list.find { |path| storage.exists?(path) }

			raise Sinatra::NotFound if !remote_path

			case File.extname(remote_path)
			when '.haml'
				local_path = storage.get_local_path(remote_path)
				haml File.read(local_path, encoding: 'utf-8')
			when '.md'
				md_path = storage.get_local_path(remote_path)
				md_text = File.read(md_path, encoding: 'utf-8')
				raw_html, locals, template_name = Ayari::MdProcessor.process_md(md_text)
				if template_name[0] != '/'
					template_name = File.join(File.dirname(remote_path), template_name)
				end
				haml_path = storage.get_local_path(template_name)
				haml_text = File.read(haml_path, encoding: 'utf-8')
				locals[:content] = raw_html
				haml haml_text, locals: locals, ugly: true
			else
				send_file storage.get_local_path(remote_path)
			end

		end

	end

end
