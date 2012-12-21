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
  
  test "required with one present and one missing" do   
    assert_raises(ActionController::ParameterMissing) do
      @params.require(:foo).require(:something_else)
    end
  end
  
  test "required is present" do
    assert(
      @params.require(:foo).require(:things => [:one, :two]).permitted?
    )
  end
  
  test "part of param not within permitted" do
    assert(
      !@params.permit(:foo).permit(:something_else).permitted?
    )
  end
  
  test 'when everything present is permitted' do   
    assert(
      @params.permit(:foo).permit(:things => [:one, :two]).permitted?
    )
  end
  
  test 'everything present is within permitted' do
   assert(
      @params.permit(:foo).permit(:things => [:one, :two]).permit(:something_else).permitted?
    )
  end
  
  test "everything present is permitted or required" do
    assert(
      @params.require(:foo).permit(:things => [:one, :two]).permitted?
    )
  end
  
  test 'everything present is within permitted or is required' do
   assert(
      @params.require(:foo).permit(:things => [:one, :two]).permit(:something_else).permitted?
    )
  end
    
  test 'everything present is within permitted or is required, but something else is required' do
    assert_raises(ActionController::ParameterMissing) do
      !@params.require(:foo).permit(:things => [:one, :two]).require(:something_else)
    end
  end
end
