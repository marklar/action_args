require 'test/unit'
%w( arg_cfg_test hash_cfg_test arg_test accessor_test ).each do |fn|
  require File.expand_path(File.dirname(__FILE__) + '/' + fn)
end
