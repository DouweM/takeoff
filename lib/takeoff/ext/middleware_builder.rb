require "middleware"

module Takeoff
  module Ext
    module MiddlewareBuilder
      def middlewares
        self.stack.map(&:first)
      end

      def index(object)
        stack.each_with_index do |item, i|
          klass = item[0]
          return i if klass == object || (klass.respond_to?(:name) && klass.name.split("::").last == object)
        end

        nil
      end

      def insert(index, middlewares, *args, &block)
        index = self.index(index) unless index.is_a?(Integer)

        if middlewares.is_a?(Array)
          middlewares.each_with_index do |middleware, i|
            super(index + i, middleware, *args, &block)
          end
        else
          super
        end
      end

      alias_method :insert_before, :insert

      def insert_after(index, middlewares, *args, &block)
        index = self.index(index) unless index.is_a?(Integer)

        if middlewares.is_a?(Array)
          middlewares.each_with_index do |middleware, i|
            super(index + i, middleware, *args, &block)
          end
        else
          super
        end
      end
      
      def delete(index)
        index = self.index(index) unless index.is_a?(Integer)
        raise "no such middleware to delete: #{index.inspect}" unless index
        stack.delete_at(index)
      end
    end
  end
end

Middleware::Builder.prepend Takeoff::Ext::MiddlewareBuilder