# frozen_string_literal: true

class Redis
  module Rack
    class Connection
      POOL_KEYS = %i[pool pool_size pool_timeout].freeze

      def initialize(options = {})
        @options = options
        @store = options[:redis_store]
        @pool = options[:pool]

        if @pool && !@pool.is_a?(ConnectionPool) # rubocop:disable Style/IfUnlessModifier
          raise ArgumentError, 'pool must be an instance of ConnectionPool'
        end

        if @store && !@store.is_a?(Redis::Store) # rubocop:disable Style/GuardClause
          raise ArgumentError, "redis_store must be an instance of Redis::Store (currently #{@store.class.name})"
        end
      end

      def with(&block)
        if pooled?
          pool.with(&block)
        else
          yield(store)
        end
      end

      def pooled?
        return @pooled if defined?(@pooled)

        @pooled = POOL_KEYS.any? { |key| @options.key?(key) }
      end

      def pool
        @pool ||= build_pool if pooled?
      end

      def store
        @store ||= build_store
      end

      def pool_options
        {
          size: @options[:pool_size],
          timeout: @options[:pool_timeout]
        }.compact.to_h
      end

      private

      def build_store
        Redis::Store::Factory.create(@options[:redis_server])
      end

      def build_pool
        if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.2.0')
          ConnectionPool.new(**pool_options) { build_store }
        else
          ConnectionPool.new(pool_options) { build_store }
        end
      end
    end
  end
end
