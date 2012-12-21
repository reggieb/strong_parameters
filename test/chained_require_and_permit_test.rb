require 'test_helper'
require 'action_controller/parameters'

class ChainedRequireAndPermitTest < ActiveSupport::TestCase
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
    
    assert_raises(ActiveModel::ForbiddenAttributes) do
      @params.require(:foo).require(:something_else)
    end
    
    assert(
      @params.require(:foo).require(:things => [:one, :two]).permitted?,
      "should return true when everything required is present"
    )
  end
  
  test "everything permitted" do
    assert(
      !@params.permit(:foo).permit(:something_else).permitted?,
      "should not return true when part of param not within permitted"
    )
    
    assert(
      @params.permit(:foo).permit(:things => [:one, :two]).permitted?,
      "should return true when everything present is permitted"
    )
    
   assert(
      @params.permit(:foo).permit(:things => [:one, :two]).permit(:something_else).permitted?,
      "should return true when everything present is within permitted"
    )
  end
  
  test "mix of required and permitted" do
    assert(
      @params.require(:foo).permit(:things => [:one, :two]).permitted?,
      "should return true when everything present is permitted or required"
    )
    
   assert(
      @params.require(:foo).permit(:things => [:one, :two]).permit(:something_else).permitted?,
      "should return true when everything present is within permitted or is required"
    )
    
    assert_raises(ActionController::ParameterMissing) do
      !@params.require(:foo).permit(:things => [:one, :two]).require(:something_else)
    end
  end
end
