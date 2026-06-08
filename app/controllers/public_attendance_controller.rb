class PublicAttendanceController < ApplicationController
  before_action :set_attendance_list

  def show
    unless @attendance_list.open?
      render :closed
      return
    end

    @attendance_response = @attendance_list.attendance_responses.new
  end

  def create
    unless @attendance_list.open?
      redirect_to public_attendance_path(@attendance_list.public_token),
        alert: "This attendance list is closed."
      return
    end

    @attendance_response = @attendance_list.attendance_responses.new(
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )

    build_answers

    if @attendance_response.save
      redirect_to public_attendance_path(@attendance_list.public_token),
        notice: "Attendance was recorded successfully."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_attendance_list
    @attendance_list = AttendanceList.find_by!(public_token: params[:public_token])
  end

  def build_answers
    answers = params.fetch(:answers, {})

    @attendance_list.attendance_fields.ordered.each do |field|
      @attendance_response.attendance_answers.build(
        attendance_field: field,
        value: answers[field.id.to_s]
      )
    end
  end
end
