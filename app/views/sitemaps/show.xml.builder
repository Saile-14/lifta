xml.instruct! :xml, version: "1.0", encoding: "UTF-8"
xml.urlset xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9", "xmlns:xhtml": "http://www.w3.org/1999/xhtml" do
  @pages.each do |page|
    I18n.available_locales.each do |locale|
      xml.url do
        xml.loc page.call(locale)
        I18n.available_locales.each do |alternate|
          xml.tag! "xhtml:link", rel: "alternate", hreflang: alternate, href: page.call(alternate)
        end
      end
    end
  end
end
