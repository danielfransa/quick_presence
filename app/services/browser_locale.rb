class BrowserLocale
  PORTUGUESE_BRAZIL = :"pt-BR"

  def self.resolve(accept_language)
    new(accept_language).resolve
  end

  def initialize(accept_language)
    @accept_language = accept_language.to_s
  end

  def resolve
    accepts_portuguese_brazil? ? PORTUGUESE_BRAZIL : I18n.default_locale
  end

  private

  attr_reader :accept_language

  def accepts_portuguese_brazil?
    accept_language.split(",").any? do |language_range|
      language, *parameters = language_range.strip.split(";")

      language.casecmp("pt-BR").zero? && quality(parameters).positive?
    end
  end

  def quality(parameters)
    quality_parameter = parameters.find { |parameter| parameter.strip.start_with?("q=") }
    return 1.0 unless quality_parameter

    quality_parameter.split("=", 2).last.to_f
  end
end
