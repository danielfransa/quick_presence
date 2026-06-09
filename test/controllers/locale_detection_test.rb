require "test_helper"

class LocaleDetectionTest < ActionDispatch::IntegrationTest
  test "uses Brazilian Portuguese when the browser accepts pt-BR" do
    get root_url, headers: { "Accept-Language" => "pt-BR,pt;q=0.9,en;q=0.8" }

    assert_response :success
    assert_includes response.body, I18n.t("home.index.title", locale: :"pt-BR")
    assert_includes response.body, 'lang="pt-BR"'
  end

  test "matches pt-BR without case sensitivity" do
    get root_url, headers: { "Accept-Language" => "PT-br" }

    assert_response :success
    assert_includes response.body, I18n.t("home.index.sign_in", locale: :"pt-BR")
  end

  test "uses English for unsupported browser languages" do
    get root_url, headers: { "Accept-Language" => "es-ES,es;q=0.9" }

    assert_response :success
    assert_includes response.body, I18n.t("home.index.title", locale: :en)
    assert_includes response.body, 'lang="en"'
  end

  test "does not select pt-BR when its quality is zero" do
    get root_url, headers: { "Accept-Language" => "pt-BR;q=0,en;q=1" }

    assert_response :success
    assert_includes response.body, I18n.t("home.index.title", locale: :en)
  end

  test "translates CSV columns for Brazilian Portuguese" do
    sign_in users(:organizer)

    get export_attendance_list_url(attendance_lists(:open_list), format: :csv),
      headers: { "Accept-Language" => "pt-BR" }

    rows = CSV.parse(response.body)
    assert_equal [
      I18n.t("exports.attendance_list.columns.number", locale: :"pt-BR"),
      "Name",
      "Student code",
      I18n.t("exports.attendance_list.columns.timestamp", locale: :"pt-BR")
    ], rows.first
    assert_match(%r{\A\d{2}/\d{2}/\d{4} \d{2}:\d{2}:\d{2}\z}, rows.second.last)
  end

  test "translates validation errors for Brazilian Portuguese" do
    post user_registration_url,
      params: {
        user: {
          username: "novo_usuario",
          password: "password123",
          password_confirmation: "password123"
        }
      },
      headers: { "Accept-Language" => "pt-BR" }

    assert_response :unprocessable_entity
    assert_includes response.body, I18n.t("errors.messages.accepted", locale: :"pt-BR")
    assert_includes response.body, User.human_attribute_name(:inactivity_terms_accepted, locale: :"pt-BR")
  end
end
