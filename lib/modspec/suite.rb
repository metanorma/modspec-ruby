# frozen_string_literal: true

require "lutaml/model"

module Modspec
  class Suite < Lutaml::Model::Serializable
    attribute :identifier, Identifier
    attribute :name, :string
    attribute :normative_statements_classes, NormativeStatementsClass,
              collection: true
    attribute :conformance_classes, ConformanceClass, collection: true

    xml do
      element "suite"
      map_attribute "identifier", to: :identifier
      map_element "name", to: :name
      map_element "normative-statements-classes",
                  to: :normative_statements_classes
      map_element "conformance-classes", to: :conformance_classes
    end

    def validate
      setup_relationships
      reset_statement_index
      errors = super
      errors.concat(validate_cycles)
      errors.concat(validate_label_uniqueness)
      errors.concat(validate_dependencies)
      unless normative_statements_classes.nil?
        errors.concat(normative_statements_classes.flat_map(&:validate))
      end
      errors.concat(conformance_classes.flat_map(&:validate)) unless conformance_classes.nil?
      errors
    end

    def combine(other_suite)
      unless other_suite.is_a?(Modspec::Suite)
        raise ArgumentError,
              "Argument must be a Modspec::Suite"
      end

      combined_suite = dup
      combined_suite.reset_statement_index
      if other_suite.normative_statements_classes
        combined_suite.normative_statements_classes ||= []
        combined_suite.normative_statements_classes += other_suite.normative_statements_classes
      end

      if other_suite.conformance_classes
        combined_suite.conformance_classes ||= []
        combined_suite.conformance_classes += other_suite.conformance_classes
      end

      # Ensure uniqueness of identifiers
      combined_suite.normative_statements_classes&.uniq!(&:identifier)

      combined_suite.conformance_classes&.uniq!(&:identifier)

      combined_suite.name = "#{name} + #{other_suite.name}"

      combined_suite
    end

    def statement_index
      @statement_index ||= build_statement_index
    end

    def reset_statement_index
      @statement_index = nil
    end

    def all_identifiers
      statement_index.keys
    end

    def resolve_conflicts(other_suite)
      resolve_conflicts_for(normative_statements_classes,
                            other_suite.normative_statements_classes)
      resolve_conflicts_for(conformance_classes,
                            other_suite.conformance_classes)
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
      return unless normative_statements_classes && conformance_classes

      req_index = normative_statements_classes
        .flat_map(&:normative_statements)
        .to_h { |r| [r.identifier.to_s, r] }

      conformance_classes.each do |cc|
        cc.tests.each do |ct|
          targets = Array(ct.targets).map(&:to_s)
          ct.corresponding_requirements = targets.filter_map do |t|
            req_index[t]
          end
          ct.parent_class = cc
        end
      end
    end

    private

    def resolve_conflicts_for(self_collection, other_collection)
      return if self_collection.nil? || other_collection.nil?

      other_collection.each do |other_item|
        existing_item = self_collection.find do |item|
          item.identifier == other_item.identifier
        end
        if existing_item
          # Merge attributes of conflicting items
          merge_attributes(existing_item, other_item)
        else
          self_collection << other_item
        end
      end
    end

    def merge_attributes(existing_item, other_item)
      existing_item.class.attributes.each_key do |attr|
        next if %i[identifier name].include?(attr)

        existing_val = existing_item.send(attr)
        other_val = other_item.send(attr)

        if existing_val.is_a?(Array)
          existing_item.send(attr).concat(other_val).uniq!
        elsif existing_val.nil? && !other_val.nil?
          existing_item.send("#{attr}=", other_val)
        end
      end
    end

    def validate_cycles
      graph = build_dependency_graph
      cycles = detect_cycles(graph)
      cycles.map { |cycle| "Cycle detected: #{cycle.join(' -> ')}" }
    end

    def all_statements
      statement_index.values
    end

    def each_statement(&block)
      normative_statements_classes&.each do |nsc|
        yield nsc
        nsc.normative_statements.each(&block)
      end

      conformance_classes&.each do |cc|
        yield cc
        cc.tests.each(&block)
      end
    end

    def build_dependency_graph
      graph = {}

      all_statements.each do |statement|
        id = statement.identifier.to_s
        deps = Set.new

        %i[dependencies indirect_dependency implements targets].each do |prop|
          refs = statement.send(prop) if statement.respond_to?(prop)
          deps.merge(refs.map(&:to_s)) if refs
        end

        graph[id] = deps
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

      graph[node]&.each do |neighbor|
        if !visited.include?(neighbor)
          cycle = detect_cycle_util(neighbor, graph, visited,
                                    recursion_stack, path)
          return cycle if cycle
        elsif recursion_stack.include?(neighbor)
          return path[path.index(neighbor)..] + [neighbor]
        end
      end

      path.pop
      recursion_stack.delete(node)
      nil
    end

    def validate_label_uniqueness
      seen = {}
      errors = []
      each_statement do |statement|
        id = statement.identifier.to_s
        if seen[id]
          errors << "Duplicate identifier found: #{statement.identifier}"
        else
          seen[id] = true
        end
      end
      errors
    end

    def validate_dependencies
      all_ids = statement_index

      errors = []
      normative_statements_classes&.each do |nsc|
        errors.concat(validate_refs(nsc, all_ids, :dependencies))
        errors.concat(validate_refs(nsc, all_ids, :implements))
        nsc.normative_statements.each do |ns|
          errors.concat(validate_refs(ns, all_ids, :dependencies))
          errors.concat(validate_refs(ns, all_ids, :indirect_dependency))
          errors.concat(validate_refs(ns, all_ids, :implements))
        end
      end

      conformance_classes&.each do |cc|
        errors.concat(validate_refs(cc, all_ids, :dependencies))
        cc.tests.each do |ct|
          errors.concat(validate_refs(ct, all_ids, :dependencies))
          errors.concat(validate_refs(ct, all_ids, :targets))
        end
      end

      errors
    end

    def build_statement_index
      index = {}
      each_statement { |s| index[s.identifier.to_s] = s }
      index
    end

    def validate_refs(obj, all_ids, property)
      refs = obj.send(property)
      return [] unless refs

      refs.filter_map do |ref|
        unless all_ids.key?(ref.to_s)
          "Invalid #{property.to_s.tr('_',
                                      ' ')} #{ref} in #{obj.identifier}"
        end
      end
    end
  end
end
