# frozen_string_literal: true

require "lutaml/model"

module Modspec
  class Suite < Lutaml::Model::Serializable
    attribute :identifier, Identifier
    attribute :name, :string
    attribute :normative_statements_classes, NormativeStatementsClass, collection: true
    attribute :conformance_classes, ConformanceClass, collection: true

    xml do
      root "suite"
      map_attribute "identifier", to: :identifier
      map_element "name", to: :name
      map_element "normative-statements-classes", to: :normative_statements_classes
      map_element "conformance-classes", to: :conformance_classes
    end

    def validate
      errors = []
      errors.concat(validate_cycles)
      errors.concat(validate_label_uniqueness)
      errors.concat(normative_statements_classes.flat_map(&:validate))
      errors.concat(conformance_classes.flat_map(&:validate))
      errors
    end

    def combine(other_suite)
      raise ArgumentError, "Argument must be a Modspec::Suite" unless other_suite.is_a?(Modspec::Suite)

      combined_suite = self.dup
      combined_suite.resolve_conflicts(other_suite)

      # Update name to reflect combination
      combined_suite.name = "#{self.name} + #{other_suite.name}"

      # Revalidate the combined suite
      errors = combined_suite.validate
      if errors.any?
        puts "Warning: The combined suite has validation errors:"
        errors.each { |error| puts "  #{error}" }
      end

      combined_suite
    end

    def self.instance
      @instance ||= new
    end

    def all_identifiers
      @all_identifiers ||= (normative_statements_classes.flat_map(&:normative_statements) +
                            conformance_classes.flat_map(&:tests)).map(&:identifier)
    end

    def resolve_conflicts(other_suite)
      resolve_conflicts_for(normative_statements_classes, other_suite.normative_statements_classes)
      resolve_conflicts_for(conformance_classes, other_suite.conformance_classes)
    end

    private

    def resolve_conflicts_for(self_collection, other_collection)
      other_collection.each do |other_item|
        existing_item = self_collection.find { |item| item.identifier == other_item.identifier }
        if existing_item
          # Merge attributes of conflicting items
          merge_attributes(existing_item, other_item)
        else
          self_collection << other_item
        end
      end
    end

    def merge_attributes(existing_item, other_item)
      existing_item.class.attribute_names.each do |attr|
        next if [:identifier, :name].include?(attr)
        if existing_item.send(attr).is_a?(Array)
          existing_item.send(attr).concat(other_item.send(attr)).uniq!
        elsif existing_item.send(attr).nil?
          existing_item.send("#{attr}=", other_item.send(attr))
        end
      end
    end

    def validate_cycles
      graph = build_dependency_graph
      cycles = detect_cycles(graph)
      cycles.map { |cycle| "Cycle detected: #{cycle.join(" -> ")}" }
    end

    def build_dependency_graph
      graph = {}
      all_statements = normative_statements_classes.flat_map(&:normative_statements) +
                       conformance_classes.flat_map(&:tests)

      # First, create an entry for every statement
      all_statements.each do |statement|
        graph[statement.identifier] = []
      end

      # Then, add dependencies
      all_statements.each do |statement|
        graph[statement.identifier] += statement.dependencies if statement.respond_to?(:dependencies)
        graph[statement.identifier] += statement.indirect_dependency if statement.respond_to?(:indirect_dependency)
        graph[statement.identifier] += statement.implements if statement.respond_to?(:implements)
        graph[statement.identifier] += statement.targets if statement.respond_to?(:targets)
      end

      graph
    end

    def detect_cycles(graph)
      cycles = []
      visited = Set.new
      recursion_stack = Set.new

      graph.keys.each do |node|
        if !visited.include?(node)
          cycle = detect_cycle_util(node, graph, visited, recursion_stack, [])
          cycles << cycle if cycle
        end
      end

      cycles
    end

    def detect_cycle_util(node, graph, visited, recursion_stack, path)
      visited.add(node)
      recursion_stack.add(node)
      path.push(node)

      # Check if the node exists in the graph and has dependencies
      if graph[node]
        graph[node].each do |neighbor|
          if !visited.include?(neighbor)
            cycle = detect_cycle_util(neighbor, graph, visited, recursion_stack, path)
            return cycle if cycle
          elsif recursion_stack.include?(neighbor)
            return path[path.index(neighbor)..-1] + [neighbor]
          end
        end
      else
        # If the node doesn't exist in the graph, log a warning
        puts "Warning: Node #{node} referenced but not found in the graph"
      end

      path.pop
      recursion_stack.delete(node)
      nil
    end

    def validate_label_uniqueness
      labels = {}
      errors = []
      all_statements = normative_statements_classes.flat_map(&:normative_statements) +
                       conformance_classes.flat_map(&:tests)
      all_statements.each do |statement|
        if labels[statement.identifier]
          errors << "Duplicate identifier found: #{statement.identifier}"
        else
          labels[statement.identifier] = true
        end
      end
      errors
    end
  end
end
