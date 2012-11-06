# coding: utf-8
require 'rubygems'
require 'fileutils'
require 'pstore'
require File.expand_path(File.dirname(__FILE__) + '/abstract')

module Rack
  module Session
    module File
      class PStore < Abstract
        def new_transaction(env)
          Rack::Session::File::PStore::Transaction.new(env, @transaction_options)
        end

        class Transaction < Rack::Session::File::Abstract::Transaction
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
            begin
              store_for_sid(sid).transaction(true) do |db|
                db.roots.each do |key|
                  data[key] = db[key]
                end
              end
            rescue InvalidSessionIDError
              return nil
            rescue TypeError
              return nil
            end
            return data
          end

          def delete_session(sid)
            begin
              filename = store_for_sid(sid).path
              if ::File.exists?(filename)
                ::File.unlink(filename)
              end
            rescue InvalidSessionIDError
            end
          end

          def expire_sessions(time)
            # TODO
          end

          private

          def store_for_sid(sid)
            begin
              ::PStore.new(session_file_name(sid), want_thread_safe?)
            rescue ArgumentError
              ::PStore.new(session_file_name(sid))
            end
          end

          def session_file_name(sid)
            ensure_sid_is_valid(sid)
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
