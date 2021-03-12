require "rails_helper"

RSpec.describe CodepenTag, type: :liquid_tag do
  describe "#link" do
    let(:codepen_link) { "https://codepen.io/twhite96/pen/XKqrJX" }
    let(:codepen_team_link) { "https://codepen.io/team/keyframers/pen/ZMRMEw" }
    let(:codepen_link_with_default_tab) { "https://codepen.io/twhite96/pen/XKqrJX default-tab=js,result" }

    xss_links = %w(
      //evil.com/?codepen.io
      https://codepen.io.evil.com
      https://codepen.io/some_username/pen/" onload='alert("xss")'
    )

    def generate_new_liquid(link)
      Liquid::Template.register_tag("codepen", CodepenTag)
      Liquid::Template.parse("{% codepen #{link} %}")
    end

    def page_with_codepen_tag
      <<~HTML
        <!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd">
        <html xmlns="http://www.w3.org/1999/xhtml">
          <body>
            <iframe height="600" src="https://codepen.io/twhite96/embed/XKqrJX?height=600&amp;default-tab=result&amp;embed-version=2" scrolling="no" frameborder="no" allowtransparency="true" loading="lazy" style="width: 100%;">
            </iframe>
          </body>
        </html>
      HTML
    end

    it "accepts codepen link" do
      liquid = generate_new_liquid(codepen_link)
      rendered_codepen_iframe = liquid.render
      # Approvals.verify(rendered_codepen_iframe, name: "codepen_liquid_tag", format: :html)
      expect(page_with_codepen_tag).to include(rendered_codepen_iframe)
    end

    it "accepts codepen link with a / at the end" do
      codepen_link = "https://codepen.io/twhite96/pen/XKqrJX/"
      expect do
        generate_new_liquid(codepen_link)
      end.not_to raise_error
    end

    it "accepts codepen team link" do
      codepen_link = codepen_team_link
      expect do
        generate_new_liquid(codepen_link)
      end.not_to raise_error
    end

    it "accepts codepen link with an underscore in the username" do
      codepen_link = "https://codepen.io/t_white96/pen/XKqrJX/"
      expect do
        generate_new_liquid(codepen_link)
      end.not_to raise_error
    end

    it "rejects invalid codepen link" do
      expect do
        generate_new_liquid("invalid_codepen_link")
      end.to raise_error(StandardError)
    end

    it "rejects codepen link with more than 30 characters in the username" do
      codepen_link = "https://codepen.io/t_white96_this_is_31_characters/pen/XKqrJX/"
      expect do
        generate_new_liquid(codepen_link)
      end.to raise_error(StandardError)
    end

    it "accepts codepen link with a default-tab parameter" do
      expect do
        generate_new_liquid(codepen_link_with_default_tab)
      end.not_to raise_error
    end

    it "rejects XSS attempts" do
      xss_links.each do |link|
        expect { generate_new_liquid(link) }.to raise_error(StandardError)
      end
    end

    it "rejects multiline XSS attempt" do
      xss_multiline_link = <<~XSS
        javascript:exploit_code();/*
        #{codepen_link}
        */
      XSS
      expect { generate_new_liquid(xss_multiline_link) }.to raise_error(StandardError)
    end
  end
end
