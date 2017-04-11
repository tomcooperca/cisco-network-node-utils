# Cisco folks can insert the appropriate license info here... :)

require_relative 'node_util'
require_relative 'interface'

module Cisco
  class SpanSession < NodeUtil
    attr_reader :session_id

    def initialize(session_id)
      validate_args(session_id)
    end

    def self.sessions
      hash = {}
      all = config_get('span_session', 'all_sessions')
      return hash if all.nil?

      all.each do |id|
        id = id.downcase
        hash[id] = SpanSession.new(id)
      end
      hash
    end

    def validate_args(session_id)
      fail TypeError unless session_id.is_a?(Integer)
      fail ArgumentError unless session_id >= 1 || session_id <= 32
      @session_id = session_id.downcase
      set_args_keys
    end

    def create
      config_set('span_session', 'create', @session_id)
    end

    def destroy
      config_set('span_session', 'destroy', @session_id)
    end

    def description
      config_get('span_session', 'description', id: @session_id)
    end

    def description=(val)
      val = val.to_s
      if val.empty?
        config_set('span_session', 'description', id: @session_id,
                    state: 'no', description: '')
      else
        config_set('span_session', 'description', id: @session_id,
                    state: '', description: val)
      end
    end

    def destination
      config_get('span_session', 'destination', id: @session_id)
    end

    def destination=(int)
      # fail if int is not a valid interface
      fail TypeError if !int in Interface.interfaces.keys
      config_set('span_session', 'destination', id: @session_id, intf_name: int)
    end

    def session_id
      config_get('span_session', 'session_id')
    end

    def session_id=(id)
      fail TypeError unless id.is_a?(Integer)
      config_set('span_session', 'session_id', id: id, state: '')
    end

    def shutdown
      config_get('span_session', 'shutdown', id: @session_id)
    end

    def shutdown=(bool)
      fail TypeError unless bool.is_a?(Boolean)
      config_set('span_session', 'shutdown', id: @session_id, shutdown: bool)
    end

    def source_interface
      config_get('span_session', 'source_interface', id: @session_id)
    end

    def source_interface=(sources)
      # fail if int is not a valid interface
      if sources.empty?
        # do something
      fail TypeError unless sources.is_a?(Hash)
      sources.each do |name,dir|
        fail TypeError if !name in Interface.interfaces.keys
        config_set('span_session', 'source_interface', id: @session_id
                    state: '', int_name: name, direction: dir)
      end
    end

    def source_vlan
      config_get('span_session', 'source_vlan', id: @session_id)
    end

    def source_vlan=(sources)
      # fail if int is not a valid interface
      if sources.empty?
        # do something
      fail TypeError unless sources.is_a?(Hash)
      sources.each do |vlans,dir|
        fail TypeError unless vlans.is_a?(String)
        config_set('span_session', 'source_interface', id: @session_id
                    state: '', vlans: vlans, direction: dir)
      end
    end

    def type
      config_get('span_session', 'type')
    end

    def type=(str)
      valid_types = ['local', 'rspan', 'erspan-source']
      fail TypeError if !str in valid_types
      if str.empty?
        config_set('span_session', 'type', id: @session_id, type: 'local')
      else
        config_set('span_session', 'type', id: @session_id, type: str)
      end
    end
  end
end