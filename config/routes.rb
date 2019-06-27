Rails.application.routes.draw do
  resources :policies
  resources :companies
  resources :employees
  get 'create_employee_csv' => 'employees#create_employee_csv'
  post 'save_csv_data' => 'employees#save_csv_data'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
