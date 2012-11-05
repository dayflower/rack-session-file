require 'action_dispatch/middleware/session/abstract_store'
require File.expand_path(File.dirname(__FILE__) + '/rack/session/file')
require File.expand_path(File.dirname(__FILE__) + '/rack/session/file/abstract')

class Rack::Session::File::Abstract
  include ActionDispatch::Session::Compatibility
  include ActionDispatch::Session::StaleSessionCheck
end

module ActionDispatch
  module Session
    class FileStore
      def self.new(app, options={})
        options[:expire_after] ||= options[:expires]
        return Rack::Session::File.new(app, options)
      end
    end
  end
end
