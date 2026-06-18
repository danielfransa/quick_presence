class PublicAttendanceController < ApplicationController
  before_action :set_attendance_list

  def show
    unless @attendance_list.open?
      render :closed
      return
    end

    @attendance_response = @attendance_list.attendance_responses.new
    load_fields
  end

  def create
    unless @attendance_list.open?
      redirect_to public_attendance_path(@attendance_list.public_token),
        alert: t("public_attendance.notices.closed"),
        status: :see_other
      return
    end

    @attendance_response = @attendance_list.attendance_responses.new(
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )

    load_fields
    build_answers

    if @attendance_response.save
      redirect_to public_attendance_confirmation_path(@attendance_list.public_token),
        notice: t("public_attendance.notices.recorded"),
        status: :see_other
    else
      render :show, status: :unprocessable_entity
    end
  end

  def confirmed
  end

  private

  def set_attendance_list
    @attendance_list = AttendanceList.find_by!(public_token: params[:public_token])
  end

  def build_answers
    answers = params.fetch(:answers, {})

    @fields.each do |field|
      @attendance_response.attendance_answers.build(
        attendance_field: field,
        value: answers[field.id.to_s]
      )
    end
  end

  def load_fields
    @fields = @attendance_list.attendance_fields.load
  end
end
