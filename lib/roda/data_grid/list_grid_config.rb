# frozen_string_literal: true

module Crossbeams
  module DataGrid
    class ListGridConfig
      attr_reader :id, :root, :multiselect_key, :fit_height, :grid_caption,
                  :dataminer_definition, :tree, :page_control_defs,
                  :multiselect_opts, :nested_grid, :conditions_key, :conditions, :actions

      def initialize(options)
        @id = options.fetch(:id)
        @root = options.fetch(:root_path)
        @multiselect_key = options[:multi_key]&.to_sym
        @fit_height = options[:params]&.delete(:fit_height)
        @conditions_key = conditions_key_from_params(options[:params])
        @grid_caption = options[:grid_caption]
        @config_loader = options[:config_loader] || -> { load_config_from_file }
        load_config
      end

      def multiselect
        !@multiselect_key.nil?
      end

      private

      def load_config
        config = @config_loader.call
        @dataminer_definition = config[:dataminer_definition]
        @tree = config[:tree]
        @actions = config[:actions]
        @page_control_defs = config[:page_controls] || []
        @multiselect_opts = if @multiselect_key
                              config[:multiselect][@multiselect_key]
                            else
                              {}
                            end
        @nested_grid = !config[:nesting].nil?
        @grid_caption = @multiselect_opts[:grid_caption] if @multiselect_opts[:grid_caption] && @grid_caption.nil?
        @grid_caption = config[:grid_caption] if @grid_caption.nil?
        condition_sets = config[:conditions] || {}
        @conditions = if @multiselect_key && @multiselect_opts[:conditions]
                        condition_sets[@multiselect_opts[:conditions].to_sym]
                      elsif @conditions_key
                        condition_sets[@conditions_key]
                      else
                        []
                      end
      end

      def conditions_key_from_params(params)
        return nil unless params && params[:query_string]
        key_a = params[:query_string].split('&').select { |k| k.start_with?('key=') }
        return nil if key_a.empty?
        key_a.first.delete('key=').to_sym
      end

      def load_config_from_file
        YAML.load(read_file)
      end

      def read_file
        path = File.join(@root, 'grid_definitions', 'lists', @id.sub('.yml', '') << '.yml')
        File.read(path)
      end
    end
  end
end