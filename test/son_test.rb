# frozen_string_literal: true

# require 'test_helper'
require 'minitest/autorun'
require 'minitest/reporters'
require_relative '../src/Entity2'
require 'mocha/minitest'

Minitest::Reporters.use!

class SonTest < Minitest::Test
  def setup
    # super
    @mock_land_use = mock('land_use')

    # Create mock UCV factory
    @mock_ucv_factory = mock('ucv_factory')
    @mock_ucv_factory.stubs(:types_for).returns([])
    @mock_ucv_factory.stubs(:create_ucv).returns(mock('ucv'))

    @entity = UrbanA::Entity.new(@mock_land_use, ucv_factory: @mock_ucv_factory)
  end

  def test_initialization
    assert_equal(@mock_land_use, @entity.land_use, 'Land use should be set correctly')
    assert_nil(@entity.superior, 'Superior should be nil by default')
    assert_kind_of(Hash, @entity.ucvs, 'UCVs should be a hash')
    assert_kind_of(Hash, @entity.params, 'Params should be a hash')
  end
end
