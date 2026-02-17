class AddOutboundProxyAndAuthUserToSipTrunks < ActiveRecord::Migration[8.0]
  def change
    add_column :sip_trunks, :outbound_proxy, :string
    add_column :sip_trunks, :auth_user, :string
  end
end
