# frozen_string_literal: true

module SeoHelper
  # Set page title and meta tags for SEO
  def set_page_meta(title:, description:, keywords: nil, type: 'website', image: nil)
    content_for :title, title
    content_for :meta_description, description
    content_for :meta_keywords, keywords if keywords.present?
    content_for :og_type, type
    content_for :og_description, description
    content_for :og_image, image || asset_path('og-image.png') if image.present?
  end

  # Add breadcrumbs structured data
  def set_breadcrumbs(breadcrumbs)
    items = breadcrumbs.map.with_index do |item, index|
      {
        "@type": "BreadcrumbList",
        "position": index + 1,
        "name": item[:name],
        "item": item[:url]
      }
    end

    schema = {
      "@context": "https://schema.org",
      "@type": "BreadcrumbList",
      "itemListElement": items
    }

    content_for :breadcrumbs, schema.to_json
  end


  # Product/Service schema markup
  def item_schema(item)
    {
      "@context": "https://schema.org",
      "@type": "Product",
      "name": item.name,
      "description": item.desc,
      "sku": item.sku,
      "brand": {
        "@type": "Brand",
        "name": item.brand&.name
      },
      "offers": {
        "@type": "Offer",
        "price": item.price,
        "priceCurrency": "MXN",
        "availability": "https://schema.org/InStock"
      }
    }.to_json
  end

  # Organization schema
  def organization_schema
    {
      "@context": "https://schema.org",
      "@type": "Organization",
      "name": "MiiNegocio",
      "url": root_url,
      "logo": asset_path('logo3.svg'),
      "description": "Plataforma de gestión de ventas, eventos y reservas online",
      "contactPoint": {
        "@type": "ContactPoint",
        "contactType": "Customer Service"
      }
    }.to_json
  end
end
