require "csv"
require "prawn"
require "prawn-svg"

class AttendanceListsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_attendance_list, only: %i[show edit update destroy responses export qr_code_pdf close]

  def index
    @attendance_lists = current_user.attendance_lists.order(created_at: :desc)
  end

  def show
  end

  def new
    @attendance_list = current_user.attendance_lists.new(active: true)
    build_missing_fields
  end

  def create
    @attendance_list = current_user.attendance_lists.new(attendance_list_params)

    if @attendance_list.save
      redirect_to @attendance_list, notice: "Attendance list was created successfully."
    else
      build_missing_fields
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    build_missing_fields
  end

  def update
    if @attendance_list.update(attendance_list_params)
      redirect_to @attendance_list, notice: "Attendance list was updated successfully."
    else
      build_missing_fields
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @attendance_list.destroy
    redirect_to attendance_lists_path, notice: "Attendance list was deleted successfully."
  end

  def responses
    @attendance_list.purge_expired_responses!

    @responses = @attendance_list.attendance_responses
      .includes(attendance_answers: :attendance_field)
      .order(submitted_at: :desc)
  end

  def export
    @attendance_list.purge_expired_responses!

    fields = @attendance_list.attendance_fields.ordered
    responses = @attendance_list.attendance_responses
      .includes(attendance_answers: :attendance_field)
      .order(:submitted_at)

    csv_data = CSV.generate(headers: true) do |csv|
      csv << [ "Timestamp" ] + fields.map(&:label)

      responses.each do |response|
        answers_by_field_id = response.attendance_answers.index_by(&:attendance_field_id)
        csv << [ response.submitted_at.strftime("%Y-%m-%d %H:%M:%S") ] +
          fields.map { |field| answers_by_field_id[field.id]&.value }
      end
    end

    send_data csv_data,
      filename: "attendance-list-#{@attendance_list.id}.csv",
      type: "text/csv"
  end

  def qr_code_pdf
    pdf = AttendanceListQrCodePdf.new(
      @attendance_list,
      public_attendance_url(@attendance_list.public_token)
    )

    send_data pdf.render,
      filename: "attendance-list-#{@attendance_list.id}-qr-code.pdf",
      type: "application/pdf",
      disposition: "inline"
  end

  def close
    @attendance_list.update!(active: false)
    redirect_to @attendance_list, notice: "Attendance list was closed successfully."
  end

  private

  def set_attendance_list
    @attendance_list = current_user.attendance_lists.find(params[:id])
  end

  def build_missing_fields
    current_fields_count = @attendance_list.attendance_fields.size
    fields_to_build = [ 5 - current_fields_count, 0 ].max

    fields_to_build.times do |index|
      @attendance_list.attendance_fields.build(position: current_fields_count + index)
    end
  end

  def attendance_list_params
    params.require(:attendance_list).permit(
      :title,
      :description,
      :time_zone,
      :starts_at_local,
      :ends_at_local,
      :active,
      attendance_fields_attributes: [
        :id,
        :label,
        :field_type,
        :required,
        :position,
        :_destroy
      ]
    )
  end
end
