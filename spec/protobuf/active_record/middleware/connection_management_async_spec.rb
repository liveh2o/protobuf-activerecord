require "spec_helper"

RSpec.describe Protobuf::ActiveRecord::Middleware::ConnectionManagementAsync do
  subject(:middleware) { described_class.new(app) }

  let(:app) { ->(env) { env } }
  let(:timer_task) { instance_double(Concurrent::TimerTask) }

  before do
    allow(Concurrent::TimerTask).to receive(:new).and_return(timer_task)
    allow(timer_task).to receive(:execute)
  end

  after do
    described_class.instance_variable_set(:@timed_task_started, nil)
  end

  describe ".timed_task_started" do
    it "returns an AtomicBoolean" do
      expect(described_class.timed_task_started).to be_a(Concurrent::AtomicBoolean)
    end

    it "defaults to false" do
      expect(described_class.timed_task_started).to be_false
    end
  end

  describe ".start_timed_task!" do
    it "creates a TimerTask with configured intervals" do
      expect(Concurrent::TimerTask).to receive(:new).with(
        hash_including(
          execution_interval: Protobuf::ActiveRecord.config.connection_reaping_interval,
          timeout_interval: Protobuf::ActiveRecord.config.connection_reaping_timeout_interval
        )
      )
      described_class.start_timed_task!
    end

    it "executes the timer task" do
      expect(timer_task).to receive(:execute)
      described_class.start_timed_task!
    end

    it "marks the task as started" do
      described_class.start_timed_task!
      expect(described_class.timed_task_started).to be_true
    end

    it "clears active connections on each tick" do
      ActiveRecord::Base.connection
      expect(ActiveRecord::Base.connection_pool.active_connection?).to be_truthy

      allow(Concurrent::TimerTask).to receive(:new) do |*args, &block|
        block.call
        timer_task
      end
      described_class.start_timed_task!

      expect(ActiveRecord::Base.connection_pool.active_connection?).to be_falsy
    end

    it "is idempotent" do
      described_class.start_timed_task!
      expect(Concurrent::TimerTask).not_to receive(:new)
      described_class.start_timed_task!
    end

    it "is thread-safe via a mutex" do
      expect(described_class::START_MUTEX).to receive(:synchronize)
      described_class.start_timed_task!
    end
  end

  describe "#call" do
    it "invokes the app" do
      expect(app).to receive(:call).with(:env).and_call_original
      middleware.call(:env)
    end

    it "wraps the app call in a connection from the pool" do
      expect(ActiveRecord::Base.connection_pool).to receive(:with_connection).and_call_original
      middleware.call(:env)
    end

    context "on subsequent invocations" do
      before do
        first = described_class.new(->(env) { env })
        first.call(:env)
      end

      it "does not call start_timed_task! again" do
        expect(described_class).not_to receive(:start_timed_task!)
        middleware.call(:env)
      end

      it "invokes the app" do
        expect(app).to receive(:call).with(:env).and_call_original
        middleware.call(:env)
      end

      it "wraps the app call in a connection from the pool" do
        expect(ActiveRecord::Base.connection_pool).to receive(:with_connection).and_call_original
        middleware.call(:env)
      end
    end
  end
end
