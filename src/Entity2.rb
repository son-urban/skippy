module UrbanA
class Entity
  attr_reader :ucvs, :params
  attr_accessor :land_use, :superior

  def initialize(land_use, ucv_factory: nil)
    @ucvs = {}
    @params = {}
    @superior = nil
    @dictionary = nil
    @ucv_factory = ucv_factory
    init_ucvs if @ucv_factory
    @land_use = land_use
  end

  def add_input_param(name, value)
    @params[name] = Core.new_PAR_class_instance name: name, value: value, dictionary: @dictionary
  end

  def remove_input_param(name)
    @params.delete name
    @dictionary.delete_key(name)
    update_default_params_list
  end

  def has_param?(name)
    @params.has_key?(name)
  end

  def recursive_param_value(par_name)
    return @params[par_name].value if @params.include? par_name

    superior.recursive_param_value(par_name)
  end

  def recursive_param_external_value(par_name)
    return @params[par_name].external_value if @params.include? par_name

    superior.recursive_param_external_value(par_name)
  end

  def update_param(value); end

  def recalculate_ucvs
    recalculate_primary_ucvs
    recalculate_derived_ucvs
  end

  # Declared in the subclass
  def recalculate_primary_ucvs; end

  # Usage: To calculate ucv values that have REQ_ like UCV_required_parking_lots, net area, UCV_num_of_units1, etc.
  def recalculate_derived_ucvs
    UrbanA.debug('recalculate_derived_ucvs')
    ordered_lu_list = @land_use.ordered_dep_list(nil)
    return unless ordered_lu_list

    ucv_list = @ucvs.keys
    ordered_lu_list.each do |ucv|
      next unless ucv_list.include? ucv

      calculate_ucv(ucv)
    end
  end

  def primary_ucv_list
    @ucvs.keys.select { |k| @ucvs[k].is_primary }
  end

  def secondary_ucv_list
    @ucvs.keys.select { |k| !@ucvs[k].is_primary }
  end

  ###################################
  private

  def init_ucvs
    ucv_list = @ucv_factory.types_for(self.class)
    return unless ucv_list

    ucv_list.each do |ucv|
      @ucvs[ucv] = @ucv_factory.create_ucv(name: ucv, used_in: self.class) if @ucvs[ucv].class.to_s != ucv
    end
  end

  def calculate_ucv(ucv)
    req = @land_use.ucv_requirements[ucv]
    input_values = req.input.collect { |ucv_name| @ucvs[ucv_name].value }
    @ucvs[ucv].value = (req.calculate_output(input_values) if input_values == input_values.compact)
  end

  def update_combined_ucvs(entities, ucv_list = nil)
    ucv_list = primary_ucv_list if ucv_list.nil?
    ucv_list.each do |ucv_name|
      value = 0
      entities.each do |ent|
        addition = ent.ucvs[ucv_name].value if ent.ucvs.has_key? ucv_name
        value += addition if addition
      end
      @ucvs[ucv_name].value = if @ucvs[ucv_name].casting_type.to_s.include? 'Length'
                                value.to_l
                              else
                                value
                              end
    end
    true
  end

  def get_params_from_dictionary(params_list = self.class.class_variable_get(:@@params_list))
    keys = @dictionary.keys.select { |key| key.include? 'PAR_' }

    keys.each do |key|
      key = key.to_sym
      next unless params_list.include? key

      if @params.has_key?(key)
        @params[key].value = @dictionary[key]
      else
        add_input_param(key, @dictionary[key])
      end
    end
  end

end # Entity
end # UrbanA
