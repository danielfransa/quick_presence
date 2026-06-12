class AttendanceListsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_attendance_list, only: %i[show edit update destroy responses export qr_code_pdf close]
  before_action :load_fields, only: %i[show responses]

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
      redirect_to @attendance_list, notice: t("attendance_lists.notices.created")
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
      redirect_to @attendance_list, notice: t("attendance_lists.notices.updated")
    else
      build_missing_fields
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @attendance_list.destroy
    redirect_to attendance_lists_path, notice: t("attendance_lists.notices.deleted")
  end

  def responses
    @attendance_list.purge_expired_responses!

    @responses = @attendance_list.attendance_responses
      .with_answers
      .reverse_chronological
  end

  def export
    @attendance_list.purge_expired_responses!
    export = AttendanceListExport.new(@attendance_list)

    respond_to do |format|
      format.csv do
        send_data export.to_csv,
          filename: t("exports.attendance_list.filenames.csv", id: @attendance_list.id),
          type: "text/csv"
      end
      format.xlsx do
        send_data export.to_xlsx,
          filename: t("exports.attendance_list.filenames.xlsx", id: @attendance_list.id),
          type: AttendanceListXlsx::CONTENT_TYPE
      end
    end
  end

  def qr_code_pdf
    pdf = AttendanceListQrCodePdf.new(
      @attendance_list,
      public_attendance_url(@attendance_list.public_token)
    )

    send_data pdf.render,
      filename: t("exports.attendance_list.filenames.qr_pdf", id: @attendance_list.id),
      type: "application/pdf",
      disposition: "inline"
  end

  def close
    @attendance_list.update!(active: false)
    redirect_to @attendance_list, notice: t("attendance_lists.notices.closed")
  end

  private

  def set_attendance_list
    @attendance_list = current_user.attendance_lists.find(params[:id])
  end

  def load_fields
    @fields = @attendance_list.attendance_fields.load
  end

  def build_missing_fields
    fields = @attendance_list.attendance_fields.load
    current_fields_count = fields.size
    fields_to_build = [ 5 - current_fields_count, 0 ].max

    fields_to_build.times do |index|
      fields.build(position: current_fields_count + index)
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
