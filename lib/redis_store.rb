module RedisStore
  # Calling it Redis will interfere with the Gem
  # Gets value of a single Redis hash key
  def hget(hash, field)
    redis.hget(hash, field)
  end

# Get value of multiple keys in a Redis hash
  def hmget(hash, *fields)
    redis.hmget(hash, *fields)
  end

# Get all fields and values from Redis at once by passing in the hash name
  def hgetall(hash)
    redis.hgetall(hash)
  end

# Saves the current token as a hash with user info
  def hmset(hash, *field_value)
    redis.hmset(hash, *field_value)
  end

# Expire an item
  def expire(hash, time)
    redis.expire(hash, time)
  end

  private
# Create our own instance of the $redis global so as not to interfere with its use elsewhere
  def redis
    $redis
  end

end