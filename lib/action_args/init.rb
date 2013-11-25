
# Config
%w( config_error  argument_error
    arg_cfg   req_arg_cfg   opt_arg_cfg
    hash_cfg  req_hash_cfg  opt_hash_cfg
    arg       req_arg       opt_arg
    accessor  opt_accessor
).each do |file_name|
  require File.expand_path(File.dirname(__FILE__) + "/#{file_name}")
end
