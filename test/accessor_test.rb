require 'test/unit'
require File.expand_path(File.dirname(__FILE__) + '/../init')

class AccessorTest < Test::Unit::TestCase

  include ActionArgs

  def setup
    @cfg = HashCfg.new do
      req(:id).as(:int).munge {|i| i*3 }
      req(:my_string).munge(:downcase)
      opt(:my_int).as(:positive_int).default(1234).validate {|i| i>3 }
      opt_hash(:extra_info) do
        req(:name)
        req(:score).as(:float).validate {|f| f>=0 && f<=5 }
      end
      at_least_one_of do
        opt(:street_1)
        opt(:street_2)
      end
      opt(:related_ids).as(:positive_int_array)
    end
  end

  def test_foo
    @cfg = HashCfg.new do
      at_least_one_of do
        opt(:listing_id).as(:positive_int)
        opt_hash(:sku) do
          req(:id).as(:positive_int)
        end
      end
    end
    params = {
      # :listing_id => "3",
      :sku => {:id => nil}
    }
    acc = Accessor.new(params, @cfg)
    assert !acc.valid?
  end

  def test_not_valid_if_missing_all_at_least_one_ofs
    acc = Accessor.new({:id => '1', :my_string => 'FOO'}, @cfg)
    assert !acc.valid?
  end

  def test_not_valid_if_missing_all_at_least_one_ofs_even_if_some_have_defaults
    cfg = HashCfg.new do
      at_least_one_of do
        opt(:street_1).default('White House') # default != provided
        opt(:street_2)
      end
    end
    acc = Accessor.new({}, cfg)
    assert !acc.valid?
  end

  def test_valid_if_has_one_of_at_least_one_ofs
    # street *1*
    acc = Accessor.new({ :id => '1',
                         :my_string => 'FOO',
                         :street_1 => '1600 Pennsylvania Ave.'
                       }, @cfg)
    assert acc.valid?
    # street *2*
    acc = Accessor.new({ :id => '1',
                         :my_string => 'FOO',
                         :street_2 => '1600 Pennsylvania Ave.'
                       }, @cfg)
    assert acc.valid?
  end

  def test_valid_if_has_multiple_at_least_one_ofs
    # BOTH street_*
    acc = Accessor.new({ :id => '1',
                         :my_string => 'FOO',
                         :street_1 => 'White House',
                         :street_2 => '1600 Pennsylvania Ave.'
                       }, @cfg)
    assert acc.valid?
  end

  def test_good
    # not actually valid.  (missing 'at_least_one_of')
    acc = Accessor.new({:id => '1', :my_string => 'FOO'}, @cfg)
    assert_equal 3,     acc[:id]
    assert_equal 'foo', acc[:my_string]
    assert_equal 1234,  acc[:my_int]
  end

  def test_should_raise_if_no_such_arg
    # not actually valid.  (missing 'at_least_one_of')
    acc = Accessor.new({:id => '1', :my_string => 'FOO'}, @cfg)
    assert_raises ArgumentError do
      acc[:blurfl]
    end
  end

  def test_int_array
    acc = Accessor.new({:id => '1', :my_string => 'FOO'}, @cfg)
    assert_equal nil, acc[:related_ids]
    acc = Accessor.new({:id => '1', :my_string => 'foo', :related_ids => '2,3,4'}, @cfg)
    assert acc
    assert_equal [2,3,4], acc[:related_ids]
  end

  def test_int_array_cannot_be_actual_array_in_params_but_rather_a_CSV_string
    acc = Accessor.new({ :id => '1', :my_string => 'foo',
                         :street_1 => '1600 Pennsylvania Ave.',
                         :related_ids => ['2','3','4']
                       }, @cfg)
    assert !acc.valid?
    # puts acc.errors.inspect
  end

  def test_optional_hash
    # not actually valid.  (missing 'at_least_one_of')
    acc = Accessor.new({:id => '1', :my_string => 'FOO'}, @cfg)
    assert_equal nil, acc[:extra_info]
  end

  def test_including_optional_hash
    # not actually valid.  (missing 'at_least_one_of')
    acc = Accessor.new({ :id => '1', :my_string => 'FOO',
                         :extra_info => {:name => 'foo', :score => '3.3'}},
                       @cfg)
    assert_equal 3.3,   acc[:extra_info][:score]
    assert_equal 'foo', acc[:extra_info][:name]
  end

  def test_missing_required_arg
    c = HashCfg.new do
      req(:bar)
      req(:foo)  # missing below
    end
    a = Accessor.new( {:bar => 'hello' }, c )
    assert !a.valid?
  end

end

