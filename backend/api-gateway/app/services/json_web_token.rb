# Validates JWTs issued by auth-service. Shares the JWT_SECRET env var.
class JsonWebToken
  SECRET = ENV.fetch("JWT_SECRET", "dev-insecure-secret-change-me")
  ALGORITHM = "HS256".freeze

  def self.decode(token)
    body, = JWT.decode(token, SECRET, true, algorithm: ALGORITHM)
    HashWithIndifferentAccess.new(body)
  rescue JWT::DecodeError, JWT::ExpiredSignature
    nil
  end
end
