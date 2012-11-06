require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'fileutils'
require 'tempfile'

shared_examples_for Rack::Session::File do
  before(:all) do
    if described_class.constants.include?(:DEFAULT_OPTIONS)
      @session_key = described_class::DEFAULT_OPTIONS[:key]
    else
      require 'rack/session/abstract/id'
      @session_key = Rack::Session::Abstract::ID::DEFAULT_OPTIONS[:key]
    end
    @session_match = /#{@session_key}=[0-9A-Fa-f]+;/

    tf = Tempfile.open("racksess")
    @storage = tf.path
    tf.close!

    @increment_mockapp = lambda do |env|
      env['rack.session']['counter'] ||= 0
      env['rack.session']['counter'] += 1
      Rack::Response.new(env['rack.session'].inspect).finish
    end

    @drop_session_mockapp = lambda do |env|
      env['rack.session.options'][:drop] = true
      @increment_mockapp.call(env)
    end

    @renew_session_mockapp = lambda do |env|
      env['rack.session.options'][:renew] = true
      @increment_mockapp.call(env)
    end

    @defer_session_mockapp = lambda do |env|
      env['rack.session.options'][:defer] = true
      @increment_mockapp.call(env)
    end
  end

  after(:all) do
    FileUtils.remove_dir(@storage)
  end

  let(:pool) { pool = described_class.new(@increment_mockapp, :storage => @storage) }

  it 'creates a new cookie' do
    res = Rack::MockRequest.new(pool).get('/')

    res['Set-Cookie'].should match(/#{@session_key}=/)
    res.body.should == '{"counter"=>1}'
  end

  it 'determines session from a cookie' do
    req = Rack::MockRequest.new(pool)

    res = req.get('/')
    cookie = res['Set-Cookie']

    res = req.get('/', 'HTTP_COOKIE' => cookie)
    res.body.should == '{"counter"=>2}'

    res = req.get('/', 'HTTP_COOKIE' => cookie)
    res.body.should == '{"counter"=>3}'
  end

  it 'survives nonexistent cookies' do
    bad_cookie = 'rack.session=00000001'
    res = Rack::MockRequest.new(pool) \
            .get('/', 'HTTP_COOKIE' => bad_cookie)

    res.body.should == '{"counter"=>1}'
    cookie = res['Set-Cookie'][@session_match]
    cookie.should_not match(/#{bad_cookie}(?:;|$)/)
  end

  it 'survives broken session data' do
    open(::File.join(@storage, '00000002'), 'w') do |f|
      f.write "\x1\x1o"     # broken data for Marshal and YAML
    end
    bad_cookie = 'rack.session=00000002'
    res = Rack::MockRequest.new(pool) \
            .get('/', 'HTTP_COOKIE' => bad_cookie)

    res.body.should == '{"counter"=>1}'
    cookie = res['Set-Cookie'][@session_match]
    cookie.should_not match(/#{bad_cookie}(?:;|$)/)
  end

  it 'should maintain freshness' do
    pool2 = described_class.new(@increment_mockapp, :storage => @storage, :expire_after => 2)
    expired_time = Time.now + 5
    res = Rack::MockRequest.new(pool2).get('/')
    res.body.should include('"counter"=>1')

    cookie = res['Set-Cookie']

    res = Rack::MockRequest.new(pool2).get('/', 'HTTP_COOKIE' => cookie)
    res['Set-Cookie'].should == cookie
    res.body.should include('"counter"=>2')

    Time.stub!(:now).and_return(expired_time)

    res = Rack::MockRequest.new(pool2).get('/', 'HTTP_COOKIE' => cookie)
    res['Set-Cookie'].should_not == cookie
    res.body.should include('"counter"=>1')
  end

  it 'deletes cookies with :drop option' do
    req = Rack::MockRequest.new(pool)
    drop = Rack::Utils::Context.new(pool, @drop_session_mockapp)
    dreq = Rack::MockRequest.new(drop)

    res0 = req.get('/')
    session = (cookie = res0['Set-Cookie'])[@session_match]
    res0.body.should == '{"counter"=>1}'

    res1 = req.get('/', 'HTTP_COOKIE' => cookie)
#   res1['Set-Cookie'][@session_match].should == session
    res1.body.should == '{"counter"=>2}'

    res2 = dreq.get('/', 'HTTP_COOKIE' => cookie)
    res2['Set-Cookie'].should be_nil
    res2.body.should == '{"counter"=>3}'

    res3 = req.get('/', 'HTTP_COOKIE' => cookie)
    res3['Set-Cookie'][@session_match].should_not == session
    res3.body.should == '{"counter"=>1}'
  end

  it 'provides new session id with :renew option' do
    req = Rack::MockRequest.new(pool)
    renew = Rack::Utils::Context.new(pool, @renew_session_mockapp)
    rreq = Rack::MockRequest.new(renew)

    res0 = req.get('/')
    session = (cookie = res0['Set-Cookie'])[@session_match]
    res0.body.should == '{"counter"=>1}'

    res1 = req.get('/', 'HTTP_COOKIE' => cookie)
#   res1['Set-Cookie'][@session_match].should == session
    res1.body.should == '{"counter"=>2}'

    res2 = rreq.get('/', 'HTTP_COOKIE' => cookie)
    new_cookie = res2['Set-Cookie']
    new_session = new_cookie[@session_match]
    new_session.should_not == session
    res2.body.should == '{"counter"=>3}'

    res3 = req.get('/', 'HTTP_COOKIE' => new_cookie)
#   res3['Set-Cookie'][@session_match].should == new_session
    res3.body.should == '{"counter"=>4}'
  end

  it 'omits cookie with :defer option' do
    req = Rack::MockRequest.new(pool)
    defer = Rack::Utils::Context.new(pool, @defer_session_mockapp)
    dreq = Rack::MockRequest.new(defer)

    res0 = req.get('/')
    session = (cookie = res0['Set-Cookie'])[@session_match]
    res0.body.should == '{"counter"=>1}'

    res1 = req.get('/', 'HTTP_COOKIE' => cookie)
#   res1['Set-Cookie'][@session_match].should == session
    res1.body.should == '{"counter"=>2}'

    res2 = dreq.get('/', 'HTTP_COOKIE' => cookie)
    res2['Set-Cookie'].should be_nil
    res2.body.should == '{"counter"=>3}'

    res3 = req.get('/', 'HTTP_COOKIE' => cookie)
#   res3['Set-Cookie'][@session_match].should == session
    res3.body.should == '{"counter"=>4}'
  end

  it 'omit cookie with bad session id' do
    bad_cookie = 'rack.session=/etc/passwd'
    res = Rack::MockRequest.new(pool) \
            .get('/', 'HTTP_COOKIE' => bad_cookie)

    res.body.should == '{"counter"=>1}'
    cookie = res['Set-Cookie'][@session_match]
    cookie.should_not match(/#{bad_cookie}(?:;|$)/)
  end
end

