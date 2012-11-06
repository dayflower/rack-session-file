# Rack::Session::File

Rack session store on plain file system.

## Usage

### In Rack Applications

On Gemfile:

```ruby
gem 'rack-session-file'
```

And use `Rack::Session::File` as Rack Middleware:

```ruby
use Rack::Session::File, :storage => ENV['TEMP'],
                         :expire_after => 1800
```

**NOTICE**: Never use this module in conjunction with other session middlewares (especially `Rack::Session::Cookie`).  That would brake session handling.

#### For Sinatra and Padrino

Do not enable session mechanism by `enable :session`.  Built-in session of Sinatra (and Padrino) utilizes `Rack::Session::Cookie`, so it will interfere this module's behavior.  Using this middleware makes `session[]` available in your application without `enable :session`.

### In Rails 3 Applications

On Gemfile:

```ruby
gem 'rack-session-file', :require => 'rails-session-file'
```

And modify your config/initializers/session_store.rb to something like:

```ruby
FooBar::Application.config.session_store :file_store,
  :key => '_foobar_session', :driver => 'YAML'
```

### Options

#### File storage directory (`:storage`)

Default is `Dir.tmpdir`.

#### Backend serializer (`:driver`)

You can specify backend serializer via `:driver` option.

```ruby
use Rack::Session::File, :driver => :YAML
```

Bundled drivers are:

* `:PStore` (default)
* `:YAML`
* `:Marshal` (discouraged to use)

Also you can `use` backend driver class explicitly.

```ruby
use Rack::Session::File::YAML
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Acknowledgement

Most of main code and test codes are derived from
titanous's [mongo-store](https://github.com/titanous/mongo-store)
and udzura's [rack-session-dbm](https://github.com/udzura/rack-session-dbm).

## Copyright and license

Copyright © 2012 ITO Nobuaki.  
Copyright © 2011 Uchio Kondo. (as the author of
  [rack-session-dbm](https://github.com/udzura/rack-session-dbm) )  
Copyright © 2010 Jonathan Rudenberg. (as the author of
  [mongo-store](https://github.com/titanous/mongo-store) )  
See LICENSE for details (MIT License).
