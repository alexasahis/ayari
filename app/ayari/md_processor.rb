require 'redcarpet'
require 'yaml'
require 'deep_hash_transform'
require 'ayari/storage'
require 'ayari/ayari_flavored_renderer'


module Ayari

	module MdProcessor

		HEADER_MARK = '---'

		def self.process_md(md_text)

			md_lines = md_text.lines.map { |l| l.rstrip }
			if !md_lines[1..-1].index(HEADER_MARK) || md_lines[0] != HEADER_MARK
				raise StandardError.new('header not found')
			end
			begin_index, end_index = 0, md_lines[1..-1].index(HEADER_MARK) + 1

			body_md = md_lines[(end_index+1)..-1].join("\n")
			header_md = md_lines[(begin_index+1)..(end_index-1)].join("\n")
			header = YAML.load(header_md).deep_symbolize_keys

			special_options = [:template, :markdown]
			locals = header.reject {|key, val| special_options.include?(key) }
			template_name = header[:template] || ''
			redcarpet_options = header[:markdown] || {}

			renderer = Ayari::AyariFlavoredRenderer.new(redcarpet_options)
			redcarpet = Redcarpet::Markdown.new(renderer)
			raw_html = redcarpet.render(body_md)

			[raw_html, locals, template_name]

		end

	end

end
