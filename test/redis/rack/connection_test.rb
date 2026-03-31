# frozen_string_literal: true

require 'test_helper'
require 'connection_pool'
require 'redis/rack/connection'

describe Redis::Rack::Connection do # rubocop:disable Metrics/BlockLength
  def setup
    @defaults = {
      host: 'localhost'
    }
  end

  it "can create it's own pool" do
    conn = Redis::Rack::Connection.new @defaults.merge(pool_size: 5, pool_timeout: 10)

    _(conn.pooled?).must_equal true
    _(conn.pool.class).must_equal ConnectionPool
    _(conn.pool.instance_variable_get(:@size)).must_equal 5
  end

  it "can create it's own pool using default Redis server" do
    conn = Redis::Rack::Connection.new @defaults.merge(pool_size: 5, pool_timeout: 10)

    _(conn.pooled?).must_equal true

    conn.with do |connection|
      _(connection.to_s).must_match(/localhost:6379 against DB 0$/)
    end
  end

  it "can create it's own pool using provided Redis server" do
    conn = Redis::Rack::Connection.new(redis_server: 'redis://127.0.0.1:6380/1', pool_size: 5, pool_timeout: 10)

    _(conn.pooled?).must_equal true
    conn.with do |connection|
      _(connection.to_s).must_match(/127\.0\.0\.1:6380 against DB 1$/)
    end
  end

  it 'can establish a new connection pool with the provided Redis server' do
    pool_size = 5
    conn = Redis::Rack::Connection.new(redis_server: 'redis://127.0.0.1:6380/1', pool_size: pool_size)

    clients = []
    mutex = Mutex.new
    Array.new(pool_size) do |i|
      Thread.new do
        conn.with do |connection|
          mutex.synchronize do
            clients[i] = connection
          end

          # Wait for all clients to be established
          loop do
            break if clients.size == pool_size && clients.all?

            sleep(0.01)
          end
        end
      end
    end.each(&:join)

    _(conn.pooled?).must_equal true
    _(clients.map(&:object_id).uniq.size).must_equal pool_size
  end

  it 'can use a supplied pool' do
    pool = ConnectionPool.new size: 1, timeout: 1 do
      Redis::Store::Factory.create('redis://127.0.0.1:6380/1')
    end
    conn = Redis::Rack::Connection.new pool: pool

    _(conn.pooled?).must_equal true
    _(conn.pool.class).must_equal ConnectionPool
    _(conn.pool.instance_variable_get(:@size)).must_equal 1
  end

  it 'uses the specified Redis store when provided' do
    store = Redis::Store::Factory.create('redis://127.0.0.1:6380/1')
    conn = Redis::Rack::Connection.new(redis_store: store)

    _(conn.pooled?).must_equal false
    _(conn.store.to_s).must_match(/127\.0\.0\.1:6380 against DB 1$/)
    _(conn.store).must_equal(store)
  end

  it 'throws an error when provided Redis store is not the expected type' do
    assert_raises ArgumentError do
      Redis::Rack::Connection.new(redis_store: Redis.new)
    end
  end

  it 'uses the specified Redis server when provided' do
    conn = Redis::Rack::Connection.new(redis_server: 'redis://127.0.0.1:6380/1')

    _(conn.pooled?).must_equal false
    _(conn.store.to_s).must_match(/127\.0\.0\.1:6380 against DB 1$/)
  end

  it 'does not include nil options for the connection pool' do
    conn = Redis::Rack::Connection.new

    _(conn.pool_options).must_be_empty

    conn = Redis::Rack::Connection.new(pool_size: nil)

    _(conn.pool_options).must_be_empty

    conn = Redis::Rack::Connection.new(pool_timeout: nil)

    _(conn.pool_options).must_be_empty
  end
end
