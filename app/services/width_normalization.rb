# Japanese keyboards type through an IME, which produces full-width forms of
# characters that are ASCII everywhere else: "１００" for "100", "ｄｅｍｏ"
# for "demo", "＠" for "@". They look nearly identical on screen but are
# different codepoints, so "１００".to_f is 0.0 and a username format check
# rejects "ｄｅｍｏ" with an error that makes no sense to the person who
# typed it.
#
# NFKC folds those onto their ASCII equivalents. It also folds half-width
# katakana ("ｱｲｳ") onto normal katakana, and leaves ordinary kana and kanji
# untouched, so it's safe to run over Japanese text.
#
# Applied wherever a value has to be machine-readable -- numbers, usernames,
# email addresses, search terms. Deliberately NOT applied to passwords:
# silently changing what someone typed would lock out anyone whose password
# contains full-width characters.
module WidthNormalization
  module_function

  def normalize(value)
    value.is_a?(String) ? value.unicode_normalize(:nfkc) : value
  end
end
