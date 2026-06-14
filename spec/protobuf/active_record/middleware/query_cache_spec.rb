require "spec_helper"

RSpec.describe Protobuf::ActiveRecord::Middleware::QueryCache do
  subject(:middleware) { described_class.new(app) }

  describe "#call" do
    it "calls the app" do
      app = ->(env) { env }
      expect(app).to receive(:call).with(:env)
      described_class.new(app).call(:env)
    end

    it "enables query cache during the call and restores it after" do
      ActiveRecord::Base.connection.disable_query_cache!
      expect(ActiveRecord::Base.connection.query_cache_enabled).to be false

      call_state = nil
      app = ->(_env) { call_state = ActiveRecord::Base.connection.query_cache_enabled }
      middleware = described_class.new(app)

      middleware.call(:env)

      expect(call_state).to be true
      expect(ActiveRecord::Base.connection.query_cache_enabled).to be false
    end

    it "cleans up thread-local storage" do
      middleware = described_class.new(->(env) { env })
      middleware.call(:env)
      expect(Thread.current[described_class::CURRENT_CONNECTION]).to be_nil
    end

    context "when query cache was already enabled" do
      it "clears the cache but leaves it enabled" do
        ActiveRecord::Base.connection.enable_query_cache!
        expect(ActiveRecord::Base.connection.query_cache_enabled).to be true

        call_state = nil
        app = ->(_env) { call_state = ActiveRecord::Base.connection.query_cache_enabled }
        middleware = described_class.new(app)

        middleware.call(:env)

        expect(call_state).to be true
        expect(ActiveRecord::Base.connection.query_cache_enabled).to be true
      end
    end

    it "restores settings even when the app raises" do
      app = ->(_env) { raise "error" }
      middleware = described_class.new(app)

      ActiveRecord::Base.connection.disable_query_cache!
      expect(ActiveRecord::Base.connection.query_cache_enabled).to be false

      expect { middleware.call(:env) }.to raise_error("error")

      expect(ActiveRecord::Base.connection.query_cache_enabled).to be false
    end
  end
end
