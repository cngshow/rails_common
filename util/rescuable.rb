#monkey patch to handle java exceptions
module ActiveSupport
  module Rescuable
    module ClassMethods
      def rescue_from(*klasses, &block)
        options = klasses.extract_options!

        unless options.has_key?(:with)
          if block_given?
            options[:with] = block
          else
            raise ArgumentError, "Need a handler. Supply an options hash that has a :with key as the last argument."
          end
        end

        klasses.each do |klass|
          key = if (klass.is_a?(Class) && ((klass <= Exception) || (klass <= java.lang.Throwable)))
                  klass.name
                elsif klass.is_a?(String)
                  klass
                else
                  raise ArgumentError, "#{klass} is neither an Exception nor a String"
                end

          # put the new handler at the end because the list is read in reverse
          self.rescue_handlers += [[key, options[:with]]]
        end
      end
    end
  end
end
