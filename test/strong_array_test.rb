require 'test_helper'
require 'action_controller/parameters'


class StrongArrayTest < ActiveSupport::TestCase

  def setup
    @params = ActionController::StrongArray.new([
      ActionController::Parameters.new({
        :name => "William Shakespeare",
        :born => "1564-04-26"
      }), 
      ActionController::Parameters.new({
        :name => "Christopher Marlowe"
      })
    ])
  end

  test 'permit' do
    permitted = @params.strengthen(name: :permit, born: :permit)
    assert_not_equal [], permitted
    permitted.each_with_index do |item, index|
      assert_equal(item.keys, @params[index].keys)
      assert_equal(item.values, @params[index].values)
    end
  end

  test 'require' do
    permitted = @params.strengthen(name: :require, born: :permit)
    assert_not_equal [], permitted
    permitted.each_with_index do |item, index|
      assert_equal(item.keys, @params[index].keys)
      assert_equal(item.values, @params[index].values)
    end  
  end

  test 'require with parameter missing' do
    assert_raise(ActionController::ParameterMissing) do
      permitted = @params.strengthen(name: :require, born: :require)
    end
  end

  test 'permit with parameter missing' do
    permitted = @params.strengthen(name: :permit)
    assert_equal 1, permitted.length
    assert_equal(permitted.first.keys, @params[1].keys)
    assert_equal(permitted.first.values, @params[1].values)
  end
end
