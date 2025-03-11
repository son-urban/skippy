require 'mocha/minitest'
# require_relative '../../src/UrbanA/ruby/Entity'
require 'D:\UACodebase\UrbanA\src\UrbanA\ruby\Entity'

class TC_EntityTest
  def setup
    # Create a mock land use using Mocha
    @mock_land_use = mock('land_use')
    @mock_land_use.stubs(:ucv_requirements).returns({})
    @mock_land_use.stubs(:ordered_dep_list).returns(nil)

    # Mock Core parameter instance
    @mock_parameter = mock('parameter')
    @mock_parameter.stubs(:value).returns(42)
    @mock_parameter.stubs(:external_value).returns(42)

    # Mock Core.new_PAR_class_instance to return our mock parameter
    UrbanA.const_set(:Core, Class.new) unless UrbanA.const_defined?(:Core)
    UrbanA::Core.stubs(:new_PAR_class_instance).returns(@mock_parameter)

    # Mock Spec_UCV singleton class and its methods
    mock_spec_ucv = mock('spec_ucv')
    mock_spec_ucv.stubs(:types_of).returns({ UrbanA::Entity => [:UCV_test] })

    # Create Core class if it doesn't exist and add Spec_UCV
    unless UrbanA.const_defined?(:Core)
      UrbanA.const_set(:Core, Module.new)
    end

    UrbanA::Core.const_set(:Spec_UCV, Class.new)
    UrbanA::Core::Spec_UCV.stubs(:instance).returns(mock_spec_ucv)

    # Mock Core.new_UCV_class_instance
    mock_ucv = mock('ucv')
    mock_ucv.stubs(:is_primary).returns(true)
    mock_ucv.stubs(:value).returns(0)
    UrbanA::Core.stubs(:new_UCV_class_instance).returns(mock_ucv)

    @entity = UrbanA::Entity.new(@mock_land_use)

    # Setup Sketchup model and dictionary
    @model = Sketchup.active_model
    @model.start_operation('Test Dictionary Setup', true)
    @model.set_attribute('TestDictionary', 'placeholder', 'value')
    @dictionary = @model.attribute_dictionaries['TestDictionary']
    @entity.instance_variable_set(:@dictionary, @dictionary)
    @model.commit_operation

    # Stub the update_default_params_list method
    @entity.stubs(:update_default_params_list)
  end

  def teardown
    # Clean up after tests
    model = Sketchup.active_model
    model.start_operation('Test Dictionary Cleanup', true)
    if model.attribute_dictionaries && model.attribute_dictionaries['TestDictionary']
      model.attribute_dictionaries.delete('TestDictionary')
    end
    if model.attribute_dictionaries && model.attribute_dictionaries['ParentTestDictionary']
      model.attribute_dictionaries.delete('ParentTestDictionary')
    end
    model.commit_operation

    @entity = nil
    @mock_land_use = nil
  end

  def test_initialization
    # Test that entity initializes with correct attributes
    assert_equal(@mock_land_use, @entity.land_use, 'Land use should be set correctly')
    assert_nil(@entity.superior, 'Superior should be nil by default')
    assert_kind_of(Hash, @entity.ucvs, 'UCVs should be a hash')
    assert_kind_of(Hash, @entity.params, 'Params should be a hash')
  end

  def test_add_input_param
    # Test adding a parameter
    @entity.add_input_param(:PAR_test, 42)
    assert(@entity.has_param?(:PAR_test), 'Parameter should be added')
    assert_equal(42, @entity.params[:PAR_test].value, 'Parameter value should be set correctly')
  end

  def test_remove_input_param
    # Test removing a parameter
    @entity.add_input_param(:PAR_test, 42)
    assert(@entity.has_param?(:PAR_test), 'Parameter should be added')

    @entity.remove_input_param(:PAR_test)
    refute(@entity.has_param?(:PAR_test), 'Parameter should be removed')
  end

  def test_has_param
    # Test has_param? method
    refute(@entity.has_param?(:PAR_nonexistent), 'Should return false for nonexistent param')

    @entity.add_input_param(:PAR_test, 42)
    assert(@entity.has_param?(:PAR_test), 'Should return true for existing param')
  end

  def test_recursive_param_value
    # Create mocked parent entity
    parent_entity = UrbanA::Entity.new(@mock_land_use)

    # Mock the dictionary operations
    model = Sketchup.active_model
    model.start_operation('Parent Dictionary Setup', true)
    model.set_attribute('ParentTestDictionary', 'placeholder', 'value')
    parent_dictionary = model.attribute_dictionaries['ParentTestDictionary']
    parent_entity.instance_variable_set(:@dictionary, parent_dictionary)
    model.commit_operation

    # Stub the update_default_params_list method on parent
    parent_entity.stubs(:update_default_params_list)

    # Mock parameter behaviors
    mock_parent_param = mock('parameter')
    mock_parent_param.stubs(:value).returns(100)
    mock_child_param = mock('parameter')
    mock_child_param.stubs(:value).returns(50)

    # Setup the test scenario
    parent_entity.params[:PAR_parent] = mock_parent_param
    @entity.superior = parent_entity
    @entity.params[:PAR_child] = mock_child_param

    assert_equal(50, @entity.recursive_param_value(:PAR_child))
    assert_equal(100, @entity.recursive_param_value(:PAR_parent))
  end

  def test_recursive_param_external_value
    # Test recursive parameter external value lookup
    parent_entity = UrbanA::Entity.new(@mock_land_use)

    # Create a parent dictionary
    model = Sketchup.active_model
    model.start_operation('Parent Dictionary Setup', true)
    model.set_attribute('ParentTestDictionary', 'placeholder', 'value')
    parent_dictionary = model.attribute_dictionaries['ParentTestDictionary']
    parent_entity.instance_variable_set(:@dictionary, parent_dictionary)
    model.commit_operation

    # Create specific mock parameters for parent and child
    mock_parent_param = mock('parent_parameter')
    mock_parent_param.stubs(:value).returns(100)
    mock_parent_param.stubs(:external_value).returns(100)

    mock_child_param = mock('child_parameter')
    mock_child_param.stubs(:value).returns(50)
    mock_child_param.stubs(:external_value).returns(50)

    # Stub Core.new_PAR_class_instance to return different parameters based on value
    UrbanA::Core.stubs(:new_PAR_class_instance)
      .returns(mock_parent_param)
      .then.returns(mock_child_param)

    # Add parameters to entities
    parent_entity.add_input_param(:PAR_parent, 100)
    @entity.superior = parent_entity
    @entity.add_input_param(:PAR_child, 50)

    assert_equal(50, @entity.recursive_param_external_value(:PAR_child),
      'Should find param external value in self')
    assert_equal(100, @entity.recursive_param_external_value(:PAR_parent),
      'Should find param external value in superior')
  end

  def test_primary_and_secondary_ucv_lists
    # Mock UCVs using Mocha
    primary_ucv = mock('primary_ucv')
    primary_ucv.stubs(:is_primary).returns(true)

    secondary_ucv = mock('secondary_ucv')
    secondary_ucv.stubs(:is_primary).returns(false)

    @entity.ucvs[:UCV_primary] = primary_ucv
    @entity.ucvs[:UCV_secondary] = secondary_ucv

    assert_equal([:UCV_primary], @entity.primary_ucv_list)
    assert_equal([:UCV_secondary], @entity.secondary_ucv_list)
  end
end
