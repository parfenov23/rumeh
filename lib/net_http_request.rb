require 'net/http'
require 'net/https'
class NetHttpRequest
  def self.request(path, params={})
    is_log = Rails.env.development? || params[:log] == true || ENV['http_log'] == "true"
    logger = Logger.new(is_log ? STDOUT : nil)

    uri = URI(path)
    agent = params[:type] == :post ? Net::HTTP::Post : Net::HTTP::Get
    agent = Net::HTTP::Put if params[:type] == :put
    request = agent.new(uri)
    request["Content-Type"] = 'application/json'
    (params[:headers] || {}).each do |k, v|
      request[k] = v
    end
    request.body = params[:data].compact.to_json if params[:data].present?
    request.set_form_data(params[:form].compact) if params[:form].present?
    request.set_form(params[:form_data].compact, 'multipart/form-data') if params[:form_data].present?
    request.body_stream = params[:file] if params[:file].present?

    req_options = {
      use_ssl: uri.scheme == "https",
      read_timeout: params[:read_timeout],
      open_timeout: params[:read_timeout]
    }.compact

    logger.info "Request url: #{uri}, type: #{params[:type] || 'get'}, payload: #{params[:data] || params[:form] || params[:form_data]}, headers: #{params[:headers]}" if is_log

    if Rails.env.development?
      OpenSSL::SSL.const_set(:VERIFY_PEER, OpenSSL::SSL::VERIFY_NONE) if path.scan("https").present?
    end

    time_hash = Rails.env.production? && params[:cache] == true ? (params[:cache_time] || 5) : 0
    id_cache = Digest::MD5.hexdigest(path)
    Rails.cache.fetch(id_cache, expires_in: time_hash.minute, race_condition_ttl: time_hash.minute) do
      http_response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end
      logger.info "Response: #{http_response.body}" if is_log
      response = params[:file_type] != :xml ? JSON.parse(http_response.body) : Hash.from_xml(http_response.body)
      if response.kind_of?(Array)
        response
      else
        response.deep_symbolize_keys rescue {}
      end
    end
  end
end