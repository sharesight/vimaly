$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'obeya'

require 'maxitest/autorun'
require 'shoulda-context'
require 'pry'

require 'webmock/minitest'
WebMock.disable_net_connect!
