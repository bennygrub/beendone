Beendone::Application.routes.draw do
  resources :categories

  resources :places

  resources :mates

  resources :highlights

  resources :flight_fixes do
    collection do
      get "fixup"
      get "cleardead"
    end
  end

  resources :airport_mappings
  resources :trips do
    get :autocomplete_airport_city, :on => :collection
  end

  resources :airlines

  resources :airports

  post "auth/connect"
  get "auth/receive"
  get "auth/recheck"
  get "auth/clear"
  get "user/edit"
  get "pages/home"
  get "pages/about"
  get "pages/how"
  get "pages/contact"
  get "pages/usairways"
  get "pages/jetblue"
  get "pages/virgin"
  get "pages/orbitz"
  get "pages/united"
  get "pages/cheapo"
  get "pages/all"
  get "pages/import"
  get "pages/priceline"
  get "pages/flighthub"
  get "pages/taca"
  get "pages/playground"
  get "pages/northwest"
  get "pages/southwest"
  get "pages/delta"
  get "pages/hotwire"
  get "pages/emirates"
  get "pages/easyjet"
  get "pages/travelocity"
  
  devise_for :users, :controllers => { omniauth_callbacks: 'omniauth_callbacks', :registrations => "registrations"  }
  resources :users, only: [:show, :index, :edit, :destroy] do
    member do
      get :share
    end
  end
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'pages#home'
  mount Resque::Server, :at => "/resque"
  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
