require "rails_helper"

# Every English string has a Japanese counterpart and vice versa. Plural forms
# differ by language (English has "one" and "other", Japanese only "other"),
# so pluralized strings are compared at the key that holds them.
RSpec.describe "Locale files" do
  def strings(locale)
    flatten(YAML.load_file(Rails.root.join("config/locales/#{locale}.yml")).fetch(locale))
  end

  def flatten(hash, prefix = nil)
    hash.each_with_object({}) do |(key, value), strings|
      path = [ prefix, key ].compact.join(".")
      if value.is_a?(Hash) && !plural?(value)
        strings.merge!(flatten(value, path))
      else
        strings[path] = value.is_a?(Hash) ? value.values.join(" ") : value
      end
    end
  end

  def plural?(hash)
    hash.keys.all? { |key| %w[ zero one two few many other ].include?(key) }
  end

  def interpolations(string)
    string.to_s.scan(/%\{(\w+)\}/).flatten.uniq.sort
  end

  let(:english) { strings("en") }
  let(:japanese) { strings("ja") }

  it "has a Japanese translation for every English string" do
    expect(english.keys - japanese.keys).to be_empty
  end

  it "has no Japanese strings without an English one" do
    expect(japanese.keys - english.keys).to be_empty
  end

  it "has no blank translations" do
    expect(english.select { |_, value| value.blank? }.keys).to be_empty
    expect(japanese.select { |_, value| value.blank? }.keys).to be_empty
  end

  it "uses the same %{placeholders} in both languages" do
    mismatched = english.keys.reject { |key| interpolations(english[key]) == interpolations(japanese[key]) }
    expect(mismatched).to be_empty
  end
end
