require "spec_helper"

RSpec.describe Protobuf::ActiveRecord::Middleware::ConnectionManagement do
  subject(:middleware) { described_class.new(app) }

  let(:app) { ->(env) { env } }

  describe "#call" do
    it "calls the app" do
      expect(app).to receive(:call).with(:env)
      middleware.call(:env)
    end

    it "releases checked-out connections after the call" do
      ActiveRecord::Base.connection
      expect(ActiveRecord::Base.connection_pool.active_connection?).to be_truthy

      middleware.call(:env)

      expect(ActiveRecord::Base.connection_pool.active_connection?).to be_falsy
    end

    it "releases checked-out connections even when the app raises" do
      app = ->(_env) { raise "boom" }
      middleware = described_class.new(app)

      ActiveRecord::Base.connection
      expect(ActiveRecord::Base.connection_pool.active_connection?).to be_truthy

      expect { middleware.call(:env) }.to raise_error("boom")

      expect(ActiveRecord::Base.connection_pool.active_connection?).to be_falsy
    end
  end
end
