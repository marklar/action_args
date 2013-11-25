require 'test_helper'

class ArgTest < Test::Unit::TestCase

  include ActionArgs

  INT_CFG    = ReqArgCfg.new(:id).as(:int)
  BOOL_CFG   = ReqArgCfg.new(:in_stock).as(:bool)
  FLOAT_CFG  = ReqArgCfg.new(:rating).as(:float)
  STRING_CFG = ReqArgCfg.new(:query)

  def test_required_cannot_have_nil_string
    arg_cfg = INT_CFG.dup.validate {|i| i > 0 }
    assert_raises ArgumentError do
      ReqArg.new(nil, arg_cfg)
    end
  end

  def test_bad_ctor_params
    assert_raises ArgumentError do ReqArg.new(1, INT_CFG) end     # should be '1'
    assert_raises ArgumentError do OptArg.new(true, BOOL_CFG) end # should be 'true'
  end

  def test_validate_in
    cfg = ReqArgCfg.new(:foo).as(:int).validate_in(0..9)
    a = ReqArg.new('1', cfg)
    assert a.valid?
    assert_raises ArgumentError do
      ReqArg.new('12', cfg)
    end
  end

  #--------

  def test_int_array
    cfg = ReqArgCfg.new(:foo).as(:int_array)
    a = ReqArg.new('1,2,3', cfg)
    assert a.valid?
    assert_equal [1,2,3], a.value
  end

  #--------
  
  def test_munge_called_on_supplied_value
    cfg = INT_CFG.dup.munge {|i| i * 3 }
    a = ReqArg.new('3', cfg)
    assert a.valid?
    assert_equal 9, a.value
  end

  def test_munge_called_before_must
    cfg = ReqArgCfg.new(:id).as(:int).munge {|i| i*3 }.validate {|i| i<5 }
    assert_raises ArgumentError do
      OptArg.new('3', cfg)
    end
  end

  def test_munge_NOT_called_on_default_so_still_validates
    cfg = OptArgCfg.new(:id).as(:int).munge {|i| i*3 }.default(3).validate {|i| i<5 }
    a = OptArg.new(nil, cfg)
    assert a.valid?
    assert_equal 3, a.value
  end

  #----------
  # optional

  def test_nil_default_ok
    cfg = OptArgCfg.new(:id).as(:int)  # no default
    a = OptArg.new('3', cfg)
    assert a.valid?
    assert_equal 3, a.value
  end

  def test_nil_param_string_and_nil_default_ok
    cfg = OptArgCfg.new(:id).as(:int)  # no default
    a = OptArg.new(nil, cfg)
    assert a.valid?
    assert_equal nil, a.value
  end

  #--------
  # bools

  def test_bool_falses
    ['f', 'false', '0'].each do |str|
      arg = ReqArg.new(str, BOOL_CFG)
      assert arg.valid?
      assert_equal false, arg.value
    end
  end

  def test_bool_trues
    ['t', 'true', '1'].each do |str|
      arg = ReqArg.new(str, BOOL_CFG)
      assert arg.valid?
      assert_equal true, arg.value
    end
  end

  #---------
  # floats

  def test_float_simple
    arg = ReqArg.new('3.5', FLOAT_CFG)
    assert arg.valid?
    assert_equal 3.5, arg.value
  end

  def test_float_should_trim
    arg = ReqArg.new(' 3.5  ', FLOAT_CFG)
    assert arg.valid?
    assert_equal 3.5, arg.value
  end

  #----------
  # strings

  def test_string_simple
    arg = ReqArg.new('foo', STRING_CFG)
    assert arg.valid?
    assert_equal 'foo', arg.value
  end

  def test_string_should_be_trimmed
    arg = ReqArg.new('   foo   ', STRING_CFG)
    assert arg.valid?
    assert_equal 'foo', arg.value
  end

  #-------
  # ints

  def test_int_with_comma
    arg = ReqArg.new('10,000', INT_CFG)
    assert arg.valid?
    assert_equal 10_000, arg.value
  end

  def test_bad_int_with_period
    assert_raises ArgumentError do
      ReqArg.new('10.0', INT_CFG)
    end
  end

  def test_bad_int_not_digits
    assert_raises ArgumentError do
      ReqArg.new('foo', INT_CFG)
    end
    # assert 0, ReqArg.new('foo', INT_CFG).value
  end

  def test_int_validates
    cfg = INT_CFG.dup.validate {|i| i > 0 }
    arg = ReqArg.new('10', cfg)
    assert arg.valid?
    assert_equal 10, arg.value
  end

  def test_int_does_not_validate
    cfg = INT_CFG.dup.validate {|i| i > 0 }
    assert_raises ArgumentError do
      arg = ReqArg.new('-3', cfg)
      assert !arg.valid?
      assert_equal -3, arg.value
    end
  end

  #----------------------
  # other kinds of ints

  def test_positive_int
    cfg = ReqArgCfg.new(:id).as(:positive_int)
    assert_raises ArgumentError do
      ReqArg.new('0', cfg)
    end
  end

  def test_unsigned_int
    cfg = ReqArgCfg.new(:id).as(:unsigned_int)
    assert_raises ArgumentError do
      ReqArg.new('-1', cfg)
    end
  end

end
