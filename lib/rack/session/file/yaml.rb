# coding: utf-8
require 'rubygems'
require 'fileutils'
require 'yaml/store'
require File.expand_path(File.dirname(__FILE__) + '/abstract')

module Rack
  module Session
    module File
      class YAML < Abstract
        def initialize(app, options = {})
          super
          @transaction_options['yaml'] = @default_options.delete(:yaml) || {}
        end

        def new_transaction(env)
          Rack::Session::File::YAML::Transaction.new(env, @transaction_options)
        end

        class Transaction < Rack::Session::File::Abstract::Transaction
          def initialize(env, options = {})
            super
            @yaml_options = options[:yaml] || {}
          end

          def store_session(sid, data)
            ensure_storage_accessible()

            store_for_sid(sid).transaction do |db|
              data.keys.each do |key|
                db[key] = data[key]
              end
            end
          end

          def load_session(sid)
            ensure_storage_accessible()

            data = {}
            store_for_sid(sid).transaction(true) do |db|
              db.roots.each do |key|
                data[key] = db[key]
              end
            end
            return data
          end

          def delete_session(sid)
            filename = store_for_sid(sid).path
            if ::File.exists?(filename)
              ::File.unlink(filename)
            end
          end

          def expire_sessions(time)
            # TODO
          end

          private

          def store_for_sid(sid)
            ::YAML::Store.new(session_file_name(sid), @yaml_options)
          end

          def session_file_name(sid)
            return ::File.join(@storage, sid)
          end

          def ensure_storage_accessible
            FileUtils.mkdir_p(@storage)
          end
        end
      end
    end
  end
end
