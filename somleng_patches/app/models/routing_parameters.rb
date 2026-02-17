class RoutingParameters
  attr_reader :sip_trunk, :destination

  def initialize(sip_trunk:, destination:)
    @sip_trunk = sip_trunk
    @destination = destination.to_s
  end

  def to_h
    {
      destination:,
      dial_string_prefix: sip_trunk.outbound_dial_string_prefix,
      plus_prefix: sip_trunk.outbound_plus_prefix?,
      national_dialing: sip_trunk.outbound_national_dialing?,
      host: sip_trunk.outbound_host,
      username: sip_trunk.username,
      password: sip_trunk.password,
      auth_user: sip_trunk.auth_user,
      sip_profile: sip_trunk.sip_profile,
      authentication_mode: sip_trunk.authentication_mode,
      gateway_name: sip_trunk.id
    }
  end
end
