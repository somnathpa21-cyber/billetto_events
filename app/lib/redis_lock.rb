require "securerandom"

class RedisLock
  LOCK_TTL = 30.minutes.to_i

  RELEASE_SCRIPT = <<~LUA.freeze
    if redis.call("GET", KEYS[1]) == ARGV[1] then
      return redis.call("DEL", KEYS[1])
    else
      return 0
    end
  LUA

  def initialize(key:, ttl: LOCK_TTL)
    @key = key
    @ttl = ttl
    @token = SecureRandom.uuid
  end

  def acquire
    result = Sidekiq.redis do |redis|
      redis.set(key, token, nx: true, ex: ttl)
    end

    result == "OK"
  end

  def release
    Sidekiq.redis do |redis|
      redis.call("EVAL", RELEASE_SCRIPT, 1, key, token)
    end
  end

  private

  attr_reader :key, :ttl, :token
end
