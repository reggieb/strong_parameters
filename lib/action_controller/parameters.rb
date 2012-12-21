require 'active_support/concern'
require 'active_support/core_ext/hash/indifferent_access'
require 'action_controller'

module ActionController
  class ParameterMissing < IndexError
    attr_reader :param

    def initialize(param)
      @param = param
      super("key not found: #{param}")
    end
  end

  class Parameters < ActiveSupport::HashWithIndifferentAccess
    attr_accessor :permitted

    def permitted?
      to_check.empty? && !self.empty?
    end

    def initialize(attributes = nil)
      super(attributes)
    end

    def permit!
      each_pair do |key, value|
        convert_hashes_to_parameters(key, value)
        self[key].permit! if self[key].respond_to? :permit!
      end
      @to_check = []
      self
    end
    
    def strengthen(filters)

      filters.each do |key, value|
        
        key = key.to_s
  
        if value.to_s == 'require' 
          if !has_key? key
            missing_required_fields << key 
          elsif self[key].kind_of? Hash and self[key].empty?
            missing_required_fields << key
          end
        end
        
        if value.kind_of? Hash
          child = self.class.new(self[key])
          begin
            check_key(key) if child.strengthen(value).permitted? 
          rescue ActionController::ParameterMissing => e
            missing_required_fields << "#{key}:[#{e.message}]"
          end
        else
          check_key(key)
        end
            
      end
 
      unless missing_required_fields.empty?
        raise(ActionController::ParameterMissing.new(missing_required_fields.join(', ')))
      end
      
      self
    end
    
    def hash_from(array, value)
      array = [array] unless array.kind_of? Array
      array.collect! do |a| 
        if a.kind_of?(Hash)
          key = a.keys.first
          [key, hash_from(a[key], value)]
        else
          [a, value]
        end  
      end
      Hash[array]
    end

    def require(*filters)
      strengthen(hash_from(filters, 'require'))
    end

    alias :required :require

    def permit(*filters)
      strengthen(hash_from(filters, 'permit'))
    end
    
    def [](key)
      convert_hashes_to_parameters(key, super)
    end

    def fetch(key, *args)
      convert_hashes_to_parameters(key, super)
    rescue KeyError, IndexError
      raise ActionController::ParameterMissing.new(key)
    end

    def slice(*keys)
      self.class.new(super).tap do |new_instance|
        new_instance.instance_variable_set :@to_check, @to_check
      end
    end

    def dup
      self.class.new(self).tap do |duplicate|
        duplicate.default = default
        duplicate.instance_variable_set :@to_check, @to_check
      end
    end

    protected
      def convert_value(value)
        if value.class == Hash
          self.class.new_from_hash_copying_default(value)
        elsif value.is_a?(Array)
          value.dup.replace(value.map { |e| convert_value(e) })
        else
          value
        end
      end
      
      def each_element(object)
        if object.is_a?(Array)
          object.map { |el| yield el }.compact
        # fields_for on an array of records uses numeric hash keys
        elsif object.is_a?(Hash) && object.keys.all? { |k| k =~ /\A-?\d+\z/ }
          hash = object.class.new
          object.each { |k,v| hash[k] = yield v }
          hash
        else
          yield object
        end
      end

    private
      def convert_hashes_to_parameters(key, value)
        if value.is_a?(Parameters) || !value.is_a?(Hash)
          value
        else
          # Convert to Parameters on first access
          self[key] = self.class.new(value)
        end
      end

      def been_checked
        @been_checked ||= self.class.new
      end

      def to_check
        @to_check ||= clone
      end
      
      def missing_required_fields
        @missing_required_fields ||= []
      end

      def check_key(filter)
        check_matching_key(filter)
        check_matching_multi_parameter_keys(filter)
      end

      def check_matching_key(filter)
        been_checked[filter] = to_check.delete(filter) if to_check.has_key?(filter)
      end

      def check_matching_multi_parameter_keys(filter)
        to_check.keys.grep(/\A#{Regexp.escape(filter.to_s)}\(\d+[if]?\)\z/).each { |key| been_checked[key] = to_check.delete(key) }
      end
      
      def check_each_key_and_children(filter)
      
        filter = filter.with_indifferent_access

        to_check.slice(*filter.keys).each do |key, value|
          return unless value

          key = key.to_sym

          been_checked[key] = to_check.each_element(value) do |value|
            # filters are a Hash, so we expect value to be a Hash too
            next if filter.is_a?(Hash) && !value.is_a?(Hash)

            value = self.class.new(value) if !value.respond_to?(:permit)

            value.permit(*Array.wrap(filter[key]))
          end
        end
      end
  end

  module StrongParameters
    extend ActiveSupport::Concern

    included do
      rescue_from(ActionController::ParameterMissing) do |parameter_missing_exception|
        render :text => "Required parameter missing: #{parameter_missing_exception.param}", :status => :bad_request
      end
    end

    def params
      @_params ||= Parameters.new(request.parameters)
    end

    def params=(val)
      @_params = val.is_a?(Hash) ? Parameters.new(val) : val
    end
  end
end

ActionController::Base.send :include, ActionController::StrongParameters
