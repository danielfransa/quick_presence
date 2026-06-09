require "test_helper"
require "yaml"

class EnglishLocaleTest < ActiveSupport::TestCase
  test "locale files do not define duplicate leaf keys" do
    definitions = Hash.new { |hash, key| hash[key] = [] }

    locale_files.each do |file|
      collect_leaf_keys(YAML.load_file(file), file, definitions)
    end

    duplicates = definitions.select { |_key, files| files.many? }
    assert_empty duplicates, duplicate_message(duplicates)
  end

  test "english locale contains each application domain" do
    %w[
      accounts
      activerecord
      app
      attendance_lists
      common
      devise
      exports
      home
      public_attendance
    ].each do |domain|
      assert I18n.exists?(domain, :en), "Missing English I18n domain: #{domain}"
    end
  end

  private

  def locale_files
    Rails.root.glob("config/locales/*.yml")
  end

  def collect_leaf_keys(value, file, definitions, path = [])
    if value.is_a?(Hash)
      value.each do |key, child|
        collect_leaf_keys(child, file, definitions, path + [ key.to_s ])
      end
    else
      definitions[path.join(".")] << file.basename.to_s
    end
  end

  def duplicate_message(duplicates)
    duplicates.map { |key, files| "#{key}: #{files.join(", ")}" }.join("\n")
  end
end
