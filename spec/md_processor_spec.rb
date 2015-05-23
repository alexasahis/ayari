require 'rspec_helper'
require 'ayari/md_processor'


describe Ayari::MdProcessor do

	before do

		@md_1 = '''---
			template: hoge.haml
			markdown:
			  hard_wrap: true
			  safe_links_only: true
			other: "options"
			are:
			  contained: "within"
			  locals: true
			flavor: ayari
			---
			##waf {.class-arg #id-arg}
			relka
			dotnet
			[safe link](http://example.com)
			[unsafe link](hoge://example.com)
			'''.lines.map { |l| l.gsub("\t", '').chomp }.join("\n")

	end

	it 'should process valid extended md text without an error' do

		expect{ Ayari::MdProcessor.process_md(@md_1) }.not_to raise_error

	end

	it 'should process template name option correctly' do

		raw_html, locals, template_name = Ayari::MdProcessor.process_md(@md_1)
		expect(template_name).to eq 'hoge.haml'

	end

	it 'should process markdown options and pass them to redcarpet correctly' do

		raw_html, locals, template_name = Ayari::MdProcessor.process_md(@md_1)
		expect(raw_html).to include('<br>')
		expect(raw_html).to include('href="http://example.com"')
		expect(raw_html).not_to include('href="hoge://example.com"')

	end

	it 'should return other unknown options as locals' do

		raw_html, locals, template_name = Ayari::MdProcessor.process_md(@md_1)
		expect(locals).not_to include(:markdown)
		expect(locals).not_to include(:template)
		expect(locals).to include(other: 'options')
		expect(locals).to include(are: {contained: 'within', locals: true})

	end

	it 'should process arguments of h elements' do

		raw_html, locals, template_name = Ayari::MdProcessor.process_md(@md_1)
		expect(raw_html).to include('class="class-arg"')
		expect(raw_html).to include('id="id-arg"')
		expect(raw_html).not_to include('{.class-arg #id-arg}')

	end

end
