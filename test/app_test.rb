# frozen_string_literal: true

# require 'mocha/minitest'
require 'C:\Users\FrontA\skippy\src\Entity2'

class EntityTest

  def setup
    p 'HERE2'

    # @mock_land_use = mock('land_use')
    # @entity = UrbanA::Entity.new(@mock_land_use)
  end

  def test_initialization
    # Test that entity initializes with correct attributes
    assert_equal(@mock_land_use, @entity.land_use, 'Land use should be set correctly')
    assert_nil(@entity.superior, 'Superior should be nil by default')
    assert_kind_of(Hash, @entity.ucvs, 'UCVs should be a hash')
    assert_kind_of(Hash, @entity.params, 'Params should be a hash')
  end
end
