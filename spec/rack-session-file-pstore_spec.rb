require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/common')

describe Rack::Session::File::PStore do
  it_behaves_like Rack::Session::File
end
