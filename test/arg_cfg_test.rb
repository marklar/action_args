require 'test/unit'
require File.expand_path(File.dirname(__FILE__) + '/../init')

class ArgCfgTest < Test::Unit::TestCase

  include ActionArgs

  def setup
    @cfg = ArgCfg.new(:foo)
    @opt_cfg = OptArgCfg.new(:foo)
  end

  # Munge is meant to be used to normalize the input.
  # For example, to downcase strings.
  # But it should maintain type.

  #
  # array
  #
  def test_int_array
    cfg = OptArgCfg.new(:foo).as(:int_array).
      munge {|ary| ary.map {|i| i+1 } }.
      default([1,2,3]).
      validate {|ary| ary.all? {|i| i>0 } }
    assert cfg.valid?
  end

  def test_positive_int_array
    # OK
    cfg = OptArgCfg.new(:foo).as(:positive_int_array).default([1,2,3])
    assert cfg.valid?

    # 1.1 is a float (not int)
    cfg = OptArgCfg.new(:foo).as(:positive_int_array).default([1.1, 2, 3])
    assert !cfg.valid?

    # 0 is not positive
    cfg = OptArgCfg.new(:foo).as(:positive_int_array).default([0, 2, 3])
    assert !cfg.valid?
  end

  def test_unsigned_int_array
    # OK
    cfg = OptArgCfg.new(:foo).as(:unsigned_int_array).default([0,1,2])
    assert cfg.valid?

    # 0.1 is a float (not int)
    cfg = OptArgCfg.new(:foo).as(:unsigned_int_array).default([0.1, 1, 2])
    assert !cfg.valid?

    # -1 is negative
    cfg = OptArgCfg.new(:foo).as(:unsigned_int_array).default([-1, 0, 1])
    assert !cfg.valid?
  end

  def test_float_array
    # OK
    cfg = OptArgCfg.new(:foo).as(:float_array).default([0.0, 1.1, 2.2])
    assert cfg.valid?

    # 0 can be treated as a float, too
    cfg = OptArgCfg.new(:foo).as(:float_array).default([0, 1.1, 2.2])
    assert cfg.valid?
  end

=begin
  def test_string_array
    cfg = OptArgCfg.new(:foo).as(:string_array).
      munge {|ary| ary.map(:downcase) }.     # Downcase each one.
      default(['foo', 'bar', 'baz']).
      validate {|ary| ary.all? {|i| i>'a' } } # On WHOLE list -- '>(int)' doesn't work with strings.
    assert cfg.valid?
  end

  def test_validation_on_default_may_raise_exception
    cfg = OptArgCfg.new(:foo).as(:string_array).
      default(['foo', 'bar', 'baz']).
      validate {|ary| ary.all? {|i| i>0 } }     # '>(int)' doesn't work with strings.
    assert_raises ::ArgumentError do cfg.valid? end
  end

  def test_bool_array
    cfg = OptArgCfg.new(:foo).as(:bool_array).
      default([true, true, false])
    assert cfg.valid?
    assert_equal [true, true, false], cfg.default_value

    cfg = OptArgCfg.new(:foo).as(:bool_array).
      default(['t', true, false])  # 't' not a bool
    assert !cfg.valid?
  end

  def test_float_array
    cfg = OptArgCfg.new(:foo).as(:float_array).
      munge {|ary| ary.map {|i| i+1 } }.
      default([1.0, 2, 3.0]).
      validate {|ary| ary.all? {|i| i>0 } }
    assert cfg.valid?

    cfg = OptArgCfg.new(:foo).as(:float_array).
      default([1.0, '2.0', 3.0])  # String, not float.
    assert !cfg.valid?
  end

  def test_symbol_array
    cfg = OptArgCfg.new(:foo).as(:symbol_array).
      default([:books, :games]).
      validate do |ary| 
        ary.all? {|i| [:books, :games, :videos, :music].include? i }
      end
    assert cfg.valid?

    cfg = OptArgCfg.new(:foo).as(:symbol_array).
      default([:books, 'games'])  # String, not float.
    assert !cfg.valid?
  end

  def test_default_for_array_must_be_proper_monomorphic_array
    cfg = OptArgCfg.new(:foo).as(:string_array).default(['foo', 'bar', 'baz'])
    assert cfg.valid?

    cfg = OptArgCfg.new(:foo).as(:string_array).default(['foo', 2, 'baz'])
    assert !cfg.valid?
  end

  def test_default_for_array_cannot_be_simple_list
    assert_raises ::ArgumentError do
      OptArgCfg.new(:foo).as(:string_array).default('foo', 'bar', 'baz')
    end
  end
=end

  # name
  def test_name_should_be_symbol
    assert_raises ConfigError do ArgCfg.new('foo') end
  end

  # type
  def test_default_type_is_string
    assert_equal ArgCfg,  @cfg.class
    assert_equal :string, @cfg.type_name
  end

  def test_good_type_names
    ArgCfg::TYPE_NAMES.each do |sym|
      assert @cfg.as(sym)
      assert_equal sym, @cfg.type_name
    end
  end

  def test_type_name_must_be_symbol
    assert_raises ConfigError do @cfg.as('string') end
  end

  def test_type_name_must_be_in_enum
    assert_raises ConfigError do @cfg.as(:bobo_type) end
  end

  def test_unsigned_int
    # default not ok.
    c = @opt_cfg.as(:unsigned_int).default(-1)
    assert c
    assert !c.valid?
    # default ok.  validate bobo.
    c = @opt_cfg.as(:unsigned_int).default(1).validate {|i| i < 0 }
    assert c
    assert !c.valid?
  end

  def test_positive_int
    # default not ok.
    c = @opt_cfg.as(:positive_int).default(0)
    assert c
    assert !c.valid?
    # default ok.  validate bobo.
    c = @opt_cfg.as(:positive_int).default(1).validate {|i| i < 1 }
    assert c
    assert !c.valid?
  end

  # munge
  def test_munge_can_be_block_or_proc_or_sym
    assert @cfg.munge {|i| i.abs }
    assert_equal Proc, @cfg.munger.class

    make_non_neg = lambda {|i| i.abs }
    assert @cfg.munge(make_non_neg)
    assert_equal Proc, @cfg.munger.class

    assert @cfg.munge(:abs)
    assert_equal Proc, @cfg.munger.class

    assert_raises ConfigError do @cfg.munge('odd?') end
  end

  def test_munge_should_have_arity_of_1
    assert @cfg.munge {|i| i.abs }
    assert_equal Proc, @cfg.munger.class
    assert_equal 1, @cfg.munger.arity

    # Block of wrong arity.
    assert_raises ConfigError do @cfg.munge {|a,b| a > b } end
    # Proc of wrong arity.
    is_bigger = lambda {|a,b| a > b }
    assert_raises ConfigError do @cfg.munge(is_bigger) end
  end

  def test_munge_cannot_provide_both_arg_and_block
    assert_raises ConfigError do @cfg.munge(:abs) {|i| i.abs } end
  end

  # must
  def test_must_can_be_block_or_proc_or_sym
    assert @cfg.validate {|i| i.odd? }
    is_odd = lambda {|i| i.odd? }
    assert @cfg.validate(is_odd)
    assert @cfg.validate(:odd?)

    assert_raises ConfigError do @cfg.validate('odd?') end
  end

  def test_that_validate_has_arity_of_1
    assert_raises ConfigError do @cfg.validate {|a,b| a > b } end
  end

  def test_that_validate_cannot_accept_both_arg_and_block
    assert_raises ConfigError do @cfg.validate(:odd) {|i| i.odd? } end
  end

  def test_that_validate_in_works
    assert @cfg.validate_in(1..3)
    assert @cfg.validate_in(['asc', 'desc'])
    assert_raises ::ArgumentError do @cfg.validate_in('asc', 'desc') end
  end

  # *no* default
  def test_required_may_not_have_default
    assert_raises NoMethodError do @cfg.default('bar') end
  end

  #-----------
  # optional

  def test_default_must_validate
    assert @opt_cfg.as(:int)
    assert @opt_cfg.default(0)
    assert @opt_cfg.validate {|i| i > 0 }
    assert !@opt_cfg.valid?

    assert @opt_cfg.default(1)
    assert @opt_cfg.valid?
  end

  def test_default_must_match_type
    assert @opt_cfg.as(:int)
    assert @opt_cfg.default('foo')
    assert !@opt_cfg.valid?

    assert @opt_cfg.default(0)
    assert @opt_cfg.valid?
  end

  def test_munge_does_not_impact_default
    assert @opt_cfg.as(:int)
    assert @opt_cfg.default(-2)
    assert @opt_cfg.munge(:abs)
    assert @opt_cfg.validate {|i| i >= 0 }
    assert !@opt_cfg.valid?

    assert @opt_cfg.default(+2)
    assert @opt_cfg.valid?
  end
  
end
