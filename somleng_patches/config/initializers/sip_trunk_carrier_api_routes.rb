Rails.application.routes.draw do
  scope(
    as: :api,
    constraints: {
      subdomain: [ AppSettings.fetch(:api_subdomain) ]
    },
    defaults: { format: "json" }
  ) do
    scope "/carrier", as: :carrier, module: :carrier_api do
      namespace :v1, defaults: { format: :json } do
        resources :sip_trunks, only: %i[index create show update destroy]
      end
    end
  end
end
