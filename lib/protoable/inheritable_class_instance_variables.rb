require 'thread'

module Protoable
  module InheritableClassInstanceVariables
    def self.included(klass)
      Thread.exclusive do
        klass.extend(Protoable::InheritableClassInstanceVariables::ClassMethods)

        klass.class_eval do
          @_inheritable_class_instance_variables = [ :_inheritable_class_instance_variables ]
        end
      end
    end

    module ClassMethods
      def inheritable_attributes(*args)
        Thread.exclusive do
          args.flatten.compact.uniq.each do |class_instance_variable|
            unless @_inheritable_class_instance_variables.include?(class_instance_variable)
              @_inheritable_class_instance_variables << class_instance_variable
            end
          end

          @_inheritable_class_instance_variables.each do |attr_symbol|
            unless self.respond_to?("#{attr_symbol}")
              class_eval %Q{
                class << self; attr_reader :#{attr_symbol}; end
              }
            end

            unless self.respond_to?("#{attr_symbol}=")
              class_eval %Q{
                class << self; attr_writer :#{attr_symbol}; end
              }
            end
          end

          @_inheritable_class_instance_variables
        end
      end

      def inherited(klass)
        super # ActiveRecord needs the inherited hook to setup fields

        Thread.exclusive do
          @_inheritable_class_instance_variables.each do |attribute|
            attr_sym = :"@#{attribute}"
            klass.instance_variable_set(attr_sym, self.instance_variable_get(attr_sym))
          end
        end
      end
    end
  end
end
