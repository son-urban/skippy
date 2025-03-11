# frozen_string_literal: true

require 'test_helper'

require_relative 'D:\UACodebase\UrbanA\src\UrbanA\ruby\street\ua_street\CachedTransitionGenerator'

class CachedTransitionGeneratorTest
  include SkippyTestHelper

  def setup
    UrbanA.const_set(:Core, Class.new) unless UrbanA.const_defined?(:Core)

    # Mock Core and Street Layer
    @mock_street_layer = mock('street_layer')
    @mock_street_layer.stubs(:node2segments).returns({})

    UrbanA::Core.stubs(:street_layer).returns(@mock_street_layer)

    # Create the generator instance
    @generator = UrbanA::Street::CachedTransitionGenerator.new

    # Mock street type object
    @mock_street_type = mock('street_type')
    @mock_street_type.stubs(:graphs).returns([])
    @mock_street_type.stubs(:recursive_param_value).with(:PAR_street_width).returns(10)
    @mock_street_type.stubs(:recursive_param_value).with(:PAR_sidewalk_left).returns(2)
    @mock_street_type.stubs(:recursive_param_value).with(:PAR_sidewalk_right).returns(2)

    # Mock Core.street_types
    UrbanA::Core.stubs(:street_types).returns({
      default_type: @mock_street_type,
    })
  end

  def teardown
    @generator = nil
  end

  def test_initialization
    1 / 0
    assert_empty(@generator.node2transition, 'Node2transition should be empty')
    assert_empty(@generator.segment2connection, 'Segment2connection should be empty')
    refute_nil(@generator.tmp_transition_ctx, 'TransitionContext should be initialized')
    refute_nil(@generator.tmp_connector_ctx, 'ConnectorContext should be initialized')
    assert_nil(1, 'Not nil')
  end

  def test_clear
    # Add some data first
    @generator.node2transition['test_node'] = 'test_transition'
    @generator.segment2connection['test_segment'] = [0, 1]

    # Test clear
    @generator.clear

    assert_empty(@generator.node2transition, 'Node2transition should be cleared')
    assert_empty(@generator.segment2connection, 'Segment2connection should be cleared')
  end

  def test_get_transition_with_connected_segments
    mock_node = mock('node')
    mock_node.stubs(:layer).returns(true)
    mock_node.stubs(:node_position).returns(Geom::Point3d.new(0, 0, 0))

    # Create mock segment with all required methods
    mock_segment = mock('segment')
    mock_segment.stubs(:curve_handle0).returns(nil)
    mock_segment.stubs(:curve_handle1).returns(nil)
    mock_segment.stubs(:node0).returns(mock_node)
    mock_segment.stubs(:node1).returns(mock('other_node'))
    mock_segment.stubs(:end_position).returns(Geom::Point3d.new(10, 0, 0))
    mock_segment.stubs(:start_position).returns(Geom::Point3d.new(0, 0, 0))
    mock_segment.stubs(:other_node).with(mock_node).returns(mock('other_node'))

    # Return mock_segment instead of string
    mock_node.stubs(:connected_segments).returns([mock_segment])

    # Mock graph and its attributes
    mock_graph = mock('graph')
    mock_graph.stubs(:get_attribute).returns({})
    mock_segment.stubs(:graph).returns(mock_graph)

    # Mock node2segments hash
    @mock_street_layer.stubs(:node2segments).returns({ mock_node => [mock_segment] })

    # Mock StreetUtilities
    UrbanA::Street::StreetUtilities.stubs(:get_segment_attributes).returns({
      PAR_street_type: 'default_type',
      PAR_street_width: 10,
      PAR_sidewalk_left: 2,
      PAR_sidewalk_right: 2,
    })
    UrbanA::Street::StreetUtilities.stubs(:get_precision).returns(0.001)
    UrbanA::Street::StreetUtilities.stubs(:get_sidewalk_width).returns(2)

    transition = @generator.get_transition(mock_node)
    refute_nil(transition, 'Should create transition for node with segments')
  end

  def test_get_connection
    mock_segment = mock('segment')
    mock_node = mock('node')
    mock_node.stubs(:layer).returns(true)
    mock_node.stubs(:connected_segments).returns([mock_segment])
    mock_node.stubs(:node_position).returns(Geom::Point3d.new(0, 0, 0))

    mock_segment.stubs(:node0).returns(mock_node)
    mock_segment.stubs(:node1).returns(mock('other_node'))
    mock_segment.stubs(:curve_handle0).returns(nil)
    mock_segment.stubs(:curve_handle1).returns(nil)
    mock_segment.stubs(:end_position).returns(Geom::Point3d.new(10, 0, 0))
    mock_segment.stubs(:graph).returns(mock('graph'))
    mock_segment.stubs(:start_position).returns(Geom::Point3d.new(0, 0, 0))

    # Mock the node2segments hash with our test data
    @mock_street_layer.stubs(:node2segments).returns({ mock_node => [mock_segment] })

    # Additional mocks needed for create method
    mock_graph = mock('graph')
    mock_graph.stubs(:get_attribute).returns({})
    mock_segment.stubs(:graph).returns(mock_graph)

    # Mock StreetUtilities with proper street type
    UrbanA::Street::StreetUtilities.stubs(:get_segment_attributes).returns({
      PAR_street_type: 'default_type',
      PAR_street_width: 10,
      PAR_sidewalk_left: 2,
      PAR_sidewalk_right: 2,
    })
    UrbanA::Street::StreetUtilities.stubs(:get_precision).returns(0.001)
    UrbanA::Street::StreetUtilities.stubs(:get_sidewalk_width).returns(2)

    connection = @generator.get_connection(mock_segment, true)
    assert_kind_of(Integer, connection, 'Should return connection index')
  end
end
