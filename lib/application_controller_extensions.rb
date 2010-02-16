module ApplicationControllerExtensions
  def self.included(base)
    base.class_eval do

      helper_method :exclude_stylesheet, :clear_stylesheets, :exclude_javascript, :clear_javascripts

      def exclude_stylesheet(sheet)
        @stylesheets.delete(sheet)
      end

      def clear_stylesheets()
        @stylesheets.clear
      end

      def exclude_javascript(script)
        @javascripts.delete(script)
      end

      def clear_javascripts()
        @javascripts.clear
      end

    end
  end
end
