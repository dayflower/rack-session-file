# coding: utf-8

module Rack
  module Session
    module File
      VERSION = '0.5.0'

      autoload :Marshal, 'rack/session/file/marshal'
      autoload :PStore, 'rack/session/file/pstore'
      autoload :YAML, 'rack/session/file/yaml'

      def self.new(app, options = {})
        mapping = {
          :pstore  => :PStore,
          :yaml    => :YAML,
          :marshal => :Marshal,
        }

        driver = options.delete(:driver) || :pstore
        driver = mapping[driver.to_s.downcase.to_sym] || driver if driver.is_a?(Symbol)
        if ! driver.is_a?(Class)
          require autoload?(driver) if autoload?(driver)
          driver = const_get(driver)
        end

        return driver.new(app, options)
      end
    end
  end
end
