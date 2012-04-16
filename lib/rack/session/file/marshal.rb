# coding: utf-8
require 'rubygems'
require 'fileutils'
require File.expand_path(File.dirname(__FILE__) + '/abstract')

module Rack
  module Session
    module File
      class Marshal < Abstract
        def new_transaction(env)
          Rack::Session::File::Marshal::Transaction.new(env, @transaction_options)
        end

        class Transaction < Rack::Session::File::Abstract::Transaction
          def store_session(sid, data)
            open_session_file(sid, 'w') do |file|
              ::Marshal.dump(data, file)
            end
          end

          def load_session(sid)
            begin
              open_session_file(sid, 'r') do |file|
                return ::Marshal.load(file)
              end
            rescue Errno::ENOENT
              return nil
          end
          end

          def delete_session(sid)
            filename = session_file_name(sid)
            if ::File.exists?(filename)
              ::File.unlink(filename)
            end
          end

          def expire_sessions(time)
            # TODO
          end

          private

          def open_session_file(sid, mode = 'r')
            ensure_storage_accessible() if mode =~ /^w/
            if block_given?
              open(session_file_name(sid), mode) do |file|
                yield file
              end
            else
              return open(session_file_name(sid), mode)
            end
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
