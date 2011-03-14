require 'test/unit'
require File.expand_path(File.dirname(__FILE__) + '/../init')

class HashCfgTest < Test::Unit::TestCase
  include ActionArgs

  def test_good_at_least_one_of
    cfg = HashCfg.new do
      req(:foo).as(:int)
      at_least_one_of do
        opt(:bar).as(:int)
        opt(:baz).as(:int)
      end
    end
    assert cfg
    assert_equal [[:bar, :baz]], cfg.non_null_sets
  end

  def test_bobo_at_least_one_of_members_cannot_be_declared_req
    assert_raises ConfigError do
      HashCfg.new do
        at_least_one_of do
          req(:foo).as(:int)  # cannot be 'req'
        end
      end
    end
  end

  def test_bobo
    assert_raises ConfigError do
      ReqHashCfg.new do
        req(:id).as(:int).default(1)  # req() doesn't take default
      end
    end
    assert_raises ConfigError do
      ReqHashCfg.new do
        opt(:id).as(:positive_int).default(0)  # def not in range
      end
    end
    assert_raises ConfigError do
      ReqHashCfg.new do
        opt(:id).as(:positive_int).
          default(10).
          validate {|i| i < 10 }  # def doesn't validate
      end
    end
  end

  def test_good_hash_cfg
    cfg = ReqHashCfg.new do
      req_hash(:name) do
        req(:first)
        opt(:last)
      end
      req_hash(:address) do
        opt(:number).as(:int)
        at_least_one_of do  # User might:
          opt(:street_1)    #   - skip 1; put in 2
          opt(:street_2)    #   - supply both
        end
        req(:city)
        opt(:state)
        req(:zip).munge {|str| str.gsub(/\D/,'') }.
          validate {|str| [5,9].include?(str.size) }
      end
    end
    assert cfg
    assert_equal :string,   cfg[:address][:city].type_name
    assert_equal :int,      cfg[:address][:number].type_name
    assert_equal ReqArgCfg, cfg[:name][:first].class
    assert_equal OptArgCfg, cfg[:name][:last].class
  end

  def test_hashes_cannot_have_same_name
    assert_raises ConfigError do
      ReqHashCfg.new do
        req_hash(:name) do
          req(:first)
        end
        opt_hash(:name) do  # same name as above.
          req(:city)
        end
      end
    end
  end

  def test_cannot_spec_same_param_more_than_once
    assert_raises ConfigError do
      HashCfg.new do
        req(:foo)
        opt(:foo)
      end
    end
  end

  def test_hash_cannot_contain_same_arg_twice
    assert_raises ConfigError do
      ReqHashCfg.new do  # these all happen to be strings.
        req_hash(:name) do
          req(:first)
          opt(:first)  # same name twice
        end
      end
    end
  end

  def test_different_hashes_can_contain_the_same_args
    cfg = ReqHashCfg.new do  # these all happen to be strings.
      req_hash(:name) do
        req(:first)
        opt(:last)
      end
      opt_hash(:users) do
        req(:first)  # same name as in other hash, ok.
      end
    end
  end

  def test_good
    cfg = ReqHashCfg.new do
      req(:id).as(:int).munge {|i| i*3 }.validate {|i| i>0 }
      
      opt(:query).munge(:downcase).validate {|q| q.size < 100 }

      opt(:vertical).munge(:downcase).default('books').
        validate {|s| ['books', 'videos'].include? s }

      opt(:in_stock).as(:bool).default(false)
    end

    assert cfg
    assert_equal ReqArgCfg, cfg[:id].class
    assert_equal :int, cfg[:id].type_name
    assert cfg[:id].munger
    assert cfg[:id].validator

    assert_equal OptArgCfg, cfg[:query].class
    assert_equal :string, cfg[:query].type_name
    assert cfg[:query].munger
    assert cfg[:query].validator

    assert_equal OptArgCfg, cfg[:vertical].class
    assert_equal :string, cfg[:vertical].type_name
    assert cfg[:vertical].munger
    assert cfg[:vertical].validator

    assert_equal OptArgCfg, cfg[:in_stock].class
    assert_equal :bool, cfg[:in_stock].type_name

    assert_equal nil, cfg[:bobo]
  end

end
