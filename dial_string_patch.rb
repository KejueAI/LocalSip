class DialString
  attr_reader :options

  DEFAULT_SIP_PROFILE = "nat_gateway".freeze

  def initialize(options)
    @options = options.symbolize_keys
  end

  def to_s
    if outbound_registration?
      # Route through the profile directly (like IP auth), not through the gateway.
      # The gateway only maintains registration. Auth credentials are passed as
      # channel variables in case the remote PBX challenges the INVITE.
      host = outbound_host_name
      vars = ["sofia_suppress_url_encoding=true", "sip_invite_domain=#{host}"]
      auth_username = options[:auth_user].presence || options[:username]
      vars << "sip_auth_username=#{auth_username}" if auth_username.present?
      vars << "sip_auth_password=#{options[:password]}" if options[:password].present?
      "{#{vars.join(',')}}sofia/#{external_profile}/#{formatted_destination}@#{outbound_host}"
    else
      "{sofia_suppress_url_encoding=true,sip_invite_domain=#{destination_host}}sofia/#{external_profile}/#{address}"
    end
  end

  def address
    options.fetch(:address) { routing_parameters.address }
  end

  def format_number(...)
    routing_parameters.format_number(...)
  end

  private

  def outbound_registration?
    options[:authentication_mode] == "outbound_registration"
  end

  def gateway_name
    options.fetch(:gateway_name)
  end

  def outbound_host
    options.fetch(:host)
  end

  def outbound_host_name
    outbound_host.split(":").first
  end

  def formatted_destination
    routing_parameters.format_number(options.fetch(:destination)).gsub(/\D/, "")
  end

  def destination_host
    address.split("@").last.split(":").first
  end

  def routing_parameters
    @routing_parameters ||= RoutingParameters.new(options)
  end

  def external_profile
    options.fetch(:sip_profile, DEFAULT_SIP_PROFILE)
  end
end
