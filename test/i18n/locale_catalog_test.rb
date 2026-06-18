require "test_helper"
require "yaml"

class LocaleCatalogTest < ActiveSupport::TestCase
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
      privacy
      public_attendance
    ].each do |domain|
      assert I18n.exists?(domain, :en), "Missing English I18n domain: #{domain}"
    end
  end

  test "portuguese locale contains every english translation key" do
    Rails.root.glob("config/locales/*.en.yml").each do |english_file|
      portuguese_file = Pathname(english_file.to_s.sub(".en.yml", ".pt-BR.yml"))
      assert portuguese_file.exist?, "Missing Portuguese locale file: #{portuguese_file.basename}"

      english_keys = leaf_keys(YAML.load_file(english_file).fetch("en"))
      portuguese_keys = leaf_keys(YAML.load_file(portuguese_file).fetch("pt-BR"))

      assert_empty english_keys - portuguese_keys,
        "Missing Portuguese keys in #{portuguese_file.basename}"
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

  def leaf_keys(value, path = [], keys = [])
    if value.is_a?(Hash)
      value.each do |key, child|
        leaf_keys(child, path + [ key.to_s ], keys)
      end
    else
      keys << path.join(".")
    end

    keys
  end
end
