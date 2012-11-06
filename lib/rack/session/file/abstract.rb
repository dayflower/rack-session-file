# coding: utf-8
require 'rubygems'
require 'rack/session/abstract/id'

module Rack
  module Session
    module File
      class InvalidSessionIDError < SecurityError; end

      class Abstract < Rack::Session::Abstract::ID
        DEFAULT_OPTIONS = Rack::Session::Abstract::ID::DEFAULT_OPTIONS.merge({
          :storage             => Dir.tmpdir,
          :clear_expired_after => 30 * 60,
        })

        def initialize(app, options = {})
          super

          @storage               = @default_options.delete(:storage)
          @recheck_expire_period = @default_options.delete(:clear_expired_after).to_i

          @next_expire_period = nil

          @transaction_options = {
            :storage => @storage,
          }
        end

        def get_session(env, sid)
          new_transaction(env).with_lock do |transaction|
            session = find_session(env, sid) if sid
            unless sid and session
              env['rack.errors'].puts("Session '#{sid}' not found, initializing...")  if $VERBOSE and not sid.nil?
              session = {}
              sid = new_sid(env)
              transaction.save_session(sid)
            end
            session.instance_variable_set('@old', {}.merge(session))
            session.instance_variable_set('@sid', sid)
            return [sid, session]
          end
        end

        def set_session(env, sid, new_session, options)
          new_transaction(env).with_lock do |transaction|
            expires = Time.now + options[:expire_after]  if ! options[:expire_after].nil?
            session = find_session(env, sid) || {}

            if options[:renew] or options[:drop]
              transaction.delete_session(sid)
              return false  if options[:drop]
              sid = new_sid(env)
              #transaction.save_session(sid, session, expires)
            end

            old_session = new_session.instance_variable_defined?('@old') ? new_session.instance_variable_get('@old') : {}
            session = merge_sessions(sid, old_session, new_session, session)
            transaction.save_session(sid, session, expires)
            return sid
          end
        end

        def destroy_session(env, sid, options)
          new_transaction(env).with_lock do |transaction|
            transaction.delete_session(sid)
            new_sid(env)  unless options[:drop]
          end
        end

        private

        def new_transaction(env)
          raise '#new_transaction not implemented'
        end

        def new_sid(env)
          loop do
            sid = generate_sid()
            break sid unless find_session(env, sid)
          end
        end

        def find_session(env, sid)
          transaction = new_transaction(env)

          time = Time.now
          if @recheck_expire_period != -1 && (@next_expire_period.nil? || @next_expire_period < time)
            @next_expire_period = time + @recheck_expire_period
            transaction.expire_sessions(time)
          end

          transaction.find_session(sid)
        end

        def merge_sessions(sid, old, new, current = nil)
          current ||= {}
          unless Hash === old and Hash === new
            warn 'Bad old or new sessions provided.'
            return current
          end

          # delete keys that are not in common
          deletes = current.keys - (new.keys & current.keys)
          warn "//@#{sid}: dropping #{deletes*','}"  if $DEBUG and not deletes.empty?
          deletes.each { |k| current.delete(k) }

          updates = new.keys.select { |k| ! current.has_key?(k) || new[k] != current[k] || new[k].kind_of?(Hash) || new[k].kind_of?(Array) }
          warn "//@#{sid}: updating #{updates*','}"  if $DEBUG and not updates.empty?
          updates.each { |k| current[k] = new[k] }

          return current
        end

        class Transaction
          def initialize(env, options = {})
            @env = env
            @storage = options[:storage]
            @mutex = Mutex.new if want_thread_safe?
          end

          def with_lock
            @mutex.lock if want_thread_safe?
            begin
              yield(self)
            ensure
              @mutex.unlock if want_thread_safe?
            end
          end

          def find_session(sid)
            session = load_session(sid)

            if session && session[:expires] != nil && session[:expires] < Time.now
              delete_session(sid)
              session = nil
            end

            return session ? session[:data] : nil
          end

          def save_session(sid, session = {}, expires = nil)
            store_session(sid, { :data => session, :expires => expires })
          end

          def store_session(sid, data)
            raise '#store_session not implemented'
          end

          def load_session(sid)
            raise '#load_session not implemented'
          end

          def delete_session(sid)
            raise '#delete_session not implemented'
          end

          def expire_sessions(time)
            raise '#expire_sessions not implemented'
          end

          private

          def want_thread_safe?
            @env['rack.multithread']
          end

          def ensure_sid_is_valid(sid)
            unless /^[0-9A-Fa-f]+$/ =~ sid
              raise InvalidSessionIDError.new("'#{sid}' is not suitable for session ID")
            end

            true
          end
        end
      end
    end
  end
end
