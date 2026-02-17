Rails.application.config.to_prepare do
  SIPTrunk.class_eval do
    # Extend the authentication_mode enum to include outbound_registration
    enumerize :authentication_mode, in: %i[ip_address client_credentials outbound_registration], override: true

    private

    # Override to skip auto-generation for outbound_registration mode
    # (user provides their own credentials)
    def generate_client_credentials
      if authentication_mode.client_credentials?
        return if username.present?

        self.username = generate_username
        self.password = SecureRandom.alphanumeric(24)
      elsif authentication_mode.outbound_registration?
        # Keep user-provided username and password as-is
        nil
      else
        self.username = nil
        self.password = nil
      end
    end
  end
end
