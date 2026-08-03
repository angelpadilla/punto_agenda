class TrafficVisit < ApplicationRecord
  validates :source, presence: true
  validates :path, presence: true
  validates :event_type, presence: true

  scope :facebook, -> { where(source: "facebook") }
  scope :for_period, ->(start_date, end_date = Time.current) { where(created_at: start_date..end_date) }

  Sources = [
    [ "Facebook", "facebook" ],
    [ "Other", "other" ]
  ]

  Types = [
    [ "Visit", "visit" ]
  ]

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at event_type fbclid id path referer referer_host source updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end

  def self.extract_fbclid(request)
    params = request.params || {}
    query_params = request.query_parameters || {}

    fbclid = [
      params[:fbclid],
      params["fbclid"],
      query_params[:fbclid],
      query_params["fbclid"],
      request.GET[:fbclid],
      request.GET["fbclid"]
    ].compact.find(&:present?)

    fbclid ||= request.original_fullpath.to_s[/[?&]fbclid=([^&]+)/, 1]
    fbclid = CGI.unescape(fbclid.to_s) if fbclid.present?
    fbclid.presence
  end

  def self.track!(request:, event_type: "visit", source: nil)
    resolved_source = source || detect_source(request: request)
    return nil unless resolved_source == "facebook"

    referer_host = begin
      URI.parse(request.referer.to_s).host
    rescue StandardError
      nil
    end

    create!(
      source: resolved_source,
      path: request.path,
      event_type: event_type,
      referer: request.referer,
      referer_host: referer_host,
      fbclid: extract_fbclid(request)
    )
  end

  def self.detect_source(request:)
    referer = request.referer.to_s
    referer_host = URI.parse(referer).host.to_s.downcase rescue ""
    params = request.params || {}
    query_params = request.query_parameters || {}

    fbclid = extract_fbclid(request)

    return "facebook" if fbclid.present?
    return "facebook" if referer_host.match?(/(^|\.)facebook\.com$/)
    return "facebook" if referer_host.match?(/(^|\.)fb\.com$/)
    return "facebook" if referer.include?("facebook.com")
    return "facebook" if referer.include?("fb.com")

    utm_source = (params[:utm_source].presence || query_params[:utm_source].presence).to_s.downcase
    return "facebook" if utm_source == "facebook"

    "other"
  end
end
