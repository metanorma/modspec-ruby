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

    def validate_all
      setup_relationships
      errors = []
      errors.concat(validate_cycles)
      errors.concat(validate_label_uniqueness)
      errors.concat(validate_dependencies)
      errors.concat(normative_statements_classes.flat_map(&:validate_all))
      errors.concat(conformance_classes.flat_map(&:validate_all))
      errors
    end

    def combine(other_suite)
      raise ArgumentError, "Argument must be a Modspec::Suite" unless other_suite.is_a?(Modspec::Suite)

      combined_suite = dup
      combined_suite.normative_statements_classes += other_suite.normative_statements_classes
      combined_suite.conformance_classes += other_suite.conformance_classes

      # Ensure uniqueness of identifiers
      combined_suite.normative_statements_classes.uniq!(&:identifier)
      combined_suite.conformance_classes.uniq!(&:identifier)

      combined_suite.name = "#{name} + #{other_suite.name}"

      errors = combined_suite.validate_all
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
                            conformance_classes.flat_map(&:tests) +
                            normative_statements_classes +
                            conformance_classes).map(&:identifier)
    end

    def resolve_conflicts(other_suite)
      resolve_conflicts_for(normative_statements_classes, other_suite.normative_statements_classes)
      resolve_conflicts_for(conformance_classes, other_suite.conformance_classes)
    end

    def self.from_yaml_files(*files)
      combined_suite = new
      files.each do |file|
        suite = from_yaml(File.read(file))
        combined_suite = combined_suite.combine(suite)
      end
      combined_suite.name = "Combined Suite"
      combined_suite
    end

    def setup_relationships
      all_requirements = normative_statements_classes.flat_map(&:normative_statements)

      conformance_classes.each do |cc|
        cc.tests.each do |ct|
          ct.corresponding_requirements = all_requirements.select do |r|
            ct.targets.map(&:to_s).include?(r.identifier.to_s)
          end
          ct.parent_class = cc
        end
      end
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
        next if %i[identifier name].include?(attr)

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

      all_statements.each do |statement|
        id = statement.identifier.to_s
        graph[id] = Set.new
        graph[id].merge(statement.dependencies.map(&:to_s)) if statement.respond_to?(:dependencies)
        graph[id].merge(statement.indirect_dependency.map(&:to_s)) if statement.respond_to?(:indirect_dependency)
        graph[id].merge(statement.implements.map(&:to_s)) if statement.respond_to?(:implements)
        graph[id].merge(statement.targets.map(&:to_s)) if statement.respond_to?(:targets)
      end

      graph
    end

    def detect_cycles(graph)
      cycles = []
      visited = Set.new
      recursion_stack = Set.new

      graph.each_key do |node|
        unless visited.include?(node)
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
            return path[path.index(neighbor)..] + [neighbor]
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

    def validate_dependencies
      all_identifiers = collect_all_identifiers

      errors = []
      normative_statements_classes.each do |nsc|
        errors.concat(validate_class_dependencies(nsc, all_identifiers))
        nsc.normative_statements.each do |ns|
          errors.concat(validate_statement_dependencies(ns, all_identifiers))
        end
      end

      conformance_classes.each do |cc|
        errors.concat(validate_class_dependencies(cc, all_identifiers))
        cc.tests.each do |ct|
          errors.concat(validate_test_targets(ct, all_identifiers))
        end
      end

      errors
    end

    def collect_all_identifiers
      identifiers = {}

      normative_statements_classes.each do |nsc|
        identifiers[nsc.identifier.to_s] = nsc
        nsc.normative_statements.each do |ns|
          identifiers[ns.identifier.to_s] = ns
        end
      end

      conformance_classes.each do |cc|
        identifiers[cc.identifier.to_s] = cc
        cc.tests.each do |ct|
          identifiers[ct.identifier.to_s] = ct
        end
      end

      identifiers
    end

    def validate_class_dependencies(klass, all_identifiers)
      errors = []
      klass.dependencies&.each do |dep|
        errors << "Invalid dependency #{dep} in #{klass.identifier}" unless all_identifiers.key?(dep.to_s)
      end
      errors
    end

    def validate_statement_dependencies(statement, all_identifiers)
      errors = []
      statement.dependencies&.each do |dep|
        errors << "Invalid dependency #{dep} in #{statement.identifier}" unless all_identifiers.key?(dep.to_s)
      end
      errors
    end

    def validate_test_targets(test, all_identifiers)
      errors = []
      test.targets&.each do |target|
        errors << "Invalid target #{target} in #{test.identifier}" unless all_identifiers.key?(target.to_s)
      end
      errors
    end
  end
end
