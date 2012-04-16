# Rack::Session::File

Rack session store on plain file system.

## Installation

Add this line to your application's Gemfile:

    gem 'rack-session-file', :git =>
      'git://github.com/dayflower/rack-session-file.git'

And then execute:

    $ bundle install

## Usage

    use Rack::Session::File, :storage => ENV['TEMP'],
                             :expire_after => 1800

### Options

#### File storage directory (`:storage`)

Default is `Dir.tmpdir`.

#### Backend serializer (`:driver`)

You can specify backend serializer via `:driver` option.

    use Rack::Session::File, :driver => :YAML

Bundled drivers are:

* `:PStore` (default)
* `:YAML`
* `:Marshal` (discouraged to use)

Also you can `use` backend driver class explicitly.

    use Rack::Session::File::YAML

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
