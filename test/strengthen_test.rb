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
  
  test "required not present" do   
    assert_raises(ActionController::ParameterMissing) do
      @params.strengthen(:something_else => :required).permitted?
    end
  end
  
  test "require not present" do   
    assert_raises(ActionController::ParameterMissing) do
      @params.strengthen(:something_else => :require).permitted?
    end
  end
    
  test "parameters persent that are not in require" do
    assert(
      !@params.strengthen(:foo => :require).permitted?
    )
  end
    
  test "everything required is present" do
    assert(
      @params.strengthen(
        :foo => :require, 
        :things => {:one => :require, :two => :require}
      ).permitted?,
      "should return true when everything required is present"
    )
  end
  
  test "not permitted as no permitted params present" do  
    assert(
      !@params.strengthen(:something_else => :permit).permitted?
    )
  end
  
  test 'not permitted as only some permitted params present' do
    assert(
      !@params.strengthen(:foo => :permit).permitted?,
      'should '
    )
  end
    
  test 'everything present is permit' do
    assert(
      @params.strengthen(
        :foo => :permit, 
        :things => {:one => :permit, :two => :permit}
      ).permitted?
    )
  end
  
  test 'everything present is permitted' do
    assert(
      @params.strengthen(
        :foo => :permitted, 
        :things => {:one => :permitted, :two => :permitted}
      ).permitted?
    )
  end
  
  test 'everything present is within permitted' do
   assert(
      @params.strengthen(
        :foo => :permit, 
        :things => {:one => :permit, :two => :permit},
        :something_else => :permit
      ).permitted?
    )
  end
  
  test "everything present is permitted or required" do
    assert(
      @params.strengthen(
        :foo => :require, 
        :things => {:one => :permit, :two => :permit}
      ).permitted?
    )
  end
  
  test "everything present is within permitted or is required" do 
   assert(
      @params.strengthen(
        :foo => :require, 
        :things => {:one => :permit, :two => :permit},
        :something_else => :permit
      ).permitted?
    )   
  end
  
  test "something required is missing in mixed require and permit" do   
    assert_raises(ActionController::ParameterMissing) do
      @params.strengthen(
        :foo => :require, 
        :things => {:one => :permit, :two => :permit},
        :something_else => :require
      ).permitted?
    end
  end
  
  test "child has missing required parameter" do 
   assert_raises(ActionController::ParameterMissing) do
      @params.strengthen(
        :foo => :require, 
        :things => {:one => :permit, :two => :permit, :three => :require},
        :something_else => :permit
      ).permitted?
   end   
  end  
end
