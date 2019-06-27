class EmployeesController < ApplicationController

  ### Constants ###

  HEADER_EMPLOYEE_NAME = 'Employee Name'
  HEADER_EMAIL = 'Email'
  HEADER_PHONE = 'Phone'
  HEADER_ASSIGNED_POLICIES = 'Assigned Policies'

  ### Constants ###

  before_action :set_employee, only: [:show, :edit, :update, :destroy]

  # GET /employees
  # GET /employees.json
  def index
    @employees = Employee.all
  end

  # GET /employees/1
  # GET /employees/1.json
  def show
  end

  # GET /employees/new
  def new
    @employee = Employee.new
  end

  # GET /employees/1/edit
  def edit
  end

  # POST /employees
  # POST /employees.json
  def create
    @employee = Employee.new(employee_params)

    respond_to do |format|
      if @employee.save
        format.html { redirect_to @employee, notice: 'Employee was successfully created.' }
        format.json { render :show, status: :created, location: @employee }
      else
        format.html { render :new }
        format.json { render json: @employee.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /employees/1
  # PATCH/PUT /employees/1.json
  def update
    respond_to do |format|
      if @employee.update(employee_params)
        format.html { redirect_to @employee, notice: 'Employee was successfully updated.' }
        format.json { render :show, status: :ok, location: @employee }
      else
        format.html { render :edit }
        format.json { render json: @employee.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /employees/1
  # DELETE /employees/1.json
  def destroy
    @employee.destroy
    respond_to do |format|
      format.html { redirect_to employees_url, notice: 'Employee was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def create_employee_csv
    @company = Company.all
  end

  def save_csv_data
    @company = Company.all
    @message = ''
    if params[:company_id].present? && params[:file].content_type == "text/csv"
      csv_data, error = validate_csv_file(params[:file], params[:company_id])
      if error.present?
        @message = error
      else
        ActiveRecord::Base.transaction do
          policy_id = []
          csv_data.each do |data|
            data[:policy_ids].each do |policy_name|
              policy = Policy.where(name: policy_name, company_id: params[:company_id].to_i).first_or_create
              policy_id.push(policy.id)
            end
            data[:policy_ids] = policy_id
            employee = Employee.create(data)
            @message = employee.errors.messages unless employee.save
          end
          raise ActiveRecord::Rollback if @message.present?
        end
      end
    else
      @message = params[:company_id].present? ? 'Please provide valid file format(.csv)' : 'Please select a company'
    end
    if @message.present?
      render :create_employee_csv
    else
      format.html { redirect_to @employee, notice: 'File successfully uploaded' }
      format.json { render :show, status: :ok, location: @employee }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_employee
    @employee = Employee.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def employee_params
    params.require(:employee).permit(:name, :email, :phone, :company_id)
  end

  # validate data of csv file
  def validate_csv_file(csv_data, selected_company)
    error_arr, save_data = [], []
    line_num = 1
    CSV.foreach(csv_data.path, headers: true) do |row|
      if row[HEADER_EMPLOYEE_NAME].blank? || row[HEADER_EMAIL].blank? || row[HEADER_PHONE].blank?
        error_arr << "Employee Name can't be blank in line number #{line_num}" if row[HEADER_EMPLOYEE_NAME].blank?
        error_arr << "Email can't be blank in line number #{line_num}" if row[HEADER_EMAIL].blank?
        error_arr << "Phone number can't be blank in line number #{line_num}" if row[HEADER_PHONE].blank?
        line_num += 1
      else
        company_policies = row[HEADER_ASSIGNED_POLICIES].split('|')
        save_data << ({name: row[HEADER_EMPLOYEE_NAME], email: row[HEADER_EMAIL], phone: row[HEADER_PHONE], company_id: selected_company, policy_ids: company_policies})
        line_num += 1
      end
    end
    error_arr << 'Data in file is not present' if line_num == 1

    return [save_data, error_arr]
  end
end

