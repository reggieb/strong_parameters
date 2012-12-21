require 'test_helper'
require 'action_controller/parameters'

class StrengthenTest < ActiveSupport::TestCase
  def setup
    @params = ActionController::Parameters.new(
      {
        :things => {
          :one => 1,
          :two => 2
        }, 
          
        :foo => :bar
      }
    )
  end
  
  test "everything required" do
    
    assert_raises(ActionController::ParameterMissing) do
      @params.strengthen(:something_else => :require)
    end
    
    assert_raises(ActionController::ParameterMissing) do
      @params.strengthen(:foo => :require)
    end
    
    assert(
      @params.strengthen(
        :foo => :required, 
        :things => {:one => :require, :two => :require}
      ),
      "should return true when everything required is present"
    )
  end
  
  test "everything permitted" do
    
    assert(
      !@params.strengthen(:something_else => :permit).permitted?,
      'should not be permitted as no permitted params present'
    )

    
    assert(
      !@params.strengthen(:foo => :permit).permitted?,
      'should not be permitted as only some permitted params present'
    )
    
    assert(
      @params.strengthen(
        :foo => :permit, 
        :things => {:one => :permit, :two => :permit}
      ).permitted?,
      "should return true when everything present is permitted"
    )
    
   assert(
      @params.strengthen(
        :foo => :permit, 
        :things => {:one => :permit, :two => :permit},
        :something_else => :permit
      ).permitted?,
      "should return true when everything present is within permitted"
    )
  end
  
  test "mix of required and permitted" do
    assert(
      @params.strengthen(
        :foo => :require, 
        :things => {:one => :permit, :two => :permit}
      ).permitted?,
      "should return true when everything present is permitted or required"
    )
    
   assert(
      @params.strengthen(
        :foo => :require, 
        :things => {:one => :permit, :two => :permit},
        :something_else => :permit
      ).permitted?,
      "should return true when everything present is within permitted or is required"
    )
    
    assert_raises(ActionController::ParameterMissing) do
      !@params.strengthen(
        :foo => :require, 
        :things => {:one => :permit, :two => :permit},
        :something_else => :required
      )
    end
  end
end
