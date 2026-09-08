# Maps a route prefix to the downstream service base URL.
# In docker-compose each service is reachable by its container name.
module ServiceRegistry
  MAP = {
    "auth"       => ENV.fetch("AUTH_SERVICE_URL", "http://localhost:3001"),
    "leave"      => ENV.fetch("LEAVE_SERVICE_URL", "http://localhost:3002"),
    "admin-docs" => ENV.fetch("ADMIN_DOC_SERVICE_URL", "http://localhost:3003")
  }.freeze

  def self.base_url_for(prefix)
    MAP[prefix]
  end
end
