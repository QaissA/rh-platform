# Minimal JWT helper. The signing secret is shared across services via the
# JWT_SECRET env var so the gateway can validate tokens issued here.
class JsonWebToken
  SECRET = ENV.fetch("JWT_SECRET", "dev-insecure-secret-change-me")
  ALGORITHM = "HS256".freeze

  def self.encode(payload, exp: 24.hours.from_now)
    payload = payload.dup
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET, ALGORITHM)
  end

  def self.decode(token)
    body, = JWT.decode(token, SECRET, true, algorithm: ALGORITHM)
    HashWithIndifferentAccess.new(body)
  rescue JWT::DecodeError
    nil
  end
end
