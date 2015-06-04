require 'rspec_helper'
require 'ayari/md_processor'


describe Ayari::MdProcessor do

	describe '::process_md' do

		context 'when it is called with a valid ayari-style markdown text' do

			subject(:md_text) {
				'''---
					template: "hoge.haml"
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
			}

			it 'should process the text without an error' do

				expect{ Ayari::MdProcessor.process_md(md_text) }.not_to raise_error

			end

			it 'should return the correct template name' do

				_, __, res_template_name = Ayari::MdProcessor.process_md(md_text)
				expect(res_template_name).to eq 'hoge.haml'

			end

			it 'should process markdown options and pass them to redcarpet' do

				raw_html, _, __ = Ayari::MdProcessor.process_md(md_text)
				expect(raw_html).to include('<br>')
				expect(raw_html).to include('href="http://example.com"')
				expect(raw_html).not_to include('href="hoge://example.com"')

			end

			it 'should return other unknown options as locals' do

				_, locals, __ = Ayari::MdProcessor.process_md(md_text)
				expect(locals).not_to include(:markdown)
				expect(locals).not_to include(:template)
				expect(locals).to include(other: 'options')
				expect(locals).to include(are: {contained: 'within', locals: true})

			end

			it 'should process arguments of h elements' do

				raw_html, _, __ = Ayari::MdProcessor.process_md(md_text)
				expect(raw_html).to include('class="class-arg"')
				expect(raw_html).to include('id="id-arg"')
				expect(raw_html).not_to include('{.class-arg #id-arg}')

			end

		end

		context 'when it is called with a normal-style markdown text' do

			subject(:md_text) {
				'''---
					template: "hoge.haml"
					markdown:
					hard_wrap: true
					safe_links_only: true
					other: "options"
					are:
					contained: "within"
					locals: true
					---
					##waf {.class-arg #id-arg}
					relka
					dotnet
					[safe link](http://example.com)
					[unsafe link](hoge://example.com)
				'''.lines.map { |l| l.gsub("\t", '').chomp }.join("\n")
			}

			it 'should not process arguments of h elements' do

				raw_html, _, __ = Ayari::MdProcessor.process_md(md_text)
				expect(raw_html).not_to include('class="class-arg"')
				expect(raw_html).not_to include('id="id-arg"')
				expect(raw_html).to include('{.class-arg #id-arg}')

			end

		end

		context 'when it is called with an invalid markdown text' do

			subject(:md_text) {
				'''---
					template: "hoge.haml"

					##waf {.class-arg #id-arg}
					relka
					dotnet
					[safe link](http://example.com)
					[unsafe link](hoge://example.com)
				'''.lines.map { |l| l.gsub("\t", '').chomp }.join("\n")
			}

			it 'should raise an error' do

				expect{ Ayari::MdProcessor.process_md(md_text) }.to raise_error

			end

		end

	end

end
