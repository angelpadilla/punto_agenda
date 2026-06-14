# frozen_string_literal: true

class SitemapsController < ApplicationController
  layout false
  skip_before_action :verify_authenticity_token

  def index
    @pages = generate_sitemap_index
    respond_to do |format|
      format.xml { render :index, content_type: "application/xml" }
    end
  end

  def pages
    @urls = [
      { loc: root_url, lastmod: Time.current, changefreq: "weekly", priority: 1.0 },
      { loc: corp_home_url(sku: "example"), lastmod: Time.current, changefreq: "daily", priority: 0.9 }
    ]
    respond_to do |format|
      format.xml { render :page_sitemap, content_type: "application/xml" }
    end
  end

  def corps
    @corps = Corp.activos.order(updated_at: :desc)

    respond_to do |format|
      format.xml { render :corp_sitemap, content_type: "application/xml" }
    end
  end

  def articles
    @articles = Post.default

    respond_to do |format|
      format.xml { render :articles, content_type: "application/xml" }
    end
  end


  private

  def generate_sitemap_index
    [
      { loc: sitemaps_pages_url(format: :xml), lastmod: Time.current },
      { loc: sitemaps_corps_url(format: :xml), lastmod: Corp.maximum(:updated_at) }
    ]
  end
end
