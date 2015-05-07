require 'redcarpet'


module Ayari

	class AyariFlavoredRenderer < Redcarpet::Render::HTML

		def initialize(options)
			@h_level = 1
			super(options)
		end

		def construct_attr_str(arg_str)

			args = arg_str.split
			classes = args.select{|item| item[0] == '.'}
			ids = args.select{|item| item[0] == '#'}
			classes_str = classes.map{|s|s[1..-1]}.join(' ')
			ids_str = ids.map{|s|s[1..-1]}.join(' ')

			attrs = []
			attrs << "class=\"#{classes_str}\"" if !classes_str.empty?
			attrs << "id=\"#{ids_str}\"" if !ids_str.empty?

			attrs.join(' ')

		end

		def header(text, level)

			appendix_div = ''
			appendix_div += '<section>' * (level - @h_level - 1) if level > @h_level
			appendix_div += '</section>' * (@h_level - level + 1) if level <= @h_level
			appendix_div += "\n" if appendix_div != ''
			@h_level = level

			mo = text.match(/\A(.+?)(\s\{(.*?)\})?\z/)

			h_title, sec_arg = mo[1], mo[3]
			sec_attr = construct_attr_str(sec_arg || '')
			sec_attr = ' ' + sec_attr if !sec_attr.empty?

			"#{appendix_div}<section#{sec_attr}>\n<h#{level}>#{h_title}</h#{level}>"

		end

		def doc_footer()

			'</section>' * (@h_level - 1)

		end

	end

end
