require "securerandom"

# Generates a readable, reasonably strong temporary password.
# Ambiguous characters (l/1/I/O/0) are excluded so it is easy to read aloud.
class PasswordGenerator
  LOWER   = ("a".."z").to_a - %w[l o]
  UPPER   = ("A".."Z").to_a - %w[I O]
  DIGITS  = ("2".."9").to_a
  SYMBOLS = %w[! @ # $ % & * ? +].freeze
  ALL     = (LOWER + UPPER + DIGITS + SYMBOLS).freeze

  # Guarantees at least one character from each class.
  def self.generate(length = 14)
    length = 8 if length < 8
    chars = [pick(LOWER), pick(UPPER), pick(DIGITS), pick(SYMBOLS)]
    (length - chars.length).times { chars << pick(ALL) }
    chars.shuffle(random: SecureRandom).join
  end

  def self.pick(set)
    set.sample(random: SecureRandom)
  end
  private_class_method :pick
end
