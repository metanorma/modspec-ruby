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
      self.all_identifiers = nil
      errors = super
      errors.concat(validate_cycles)
      errors.concat(validate_label_uniqueness)
      errors.concat(validate_dependencies)
      unless normative_statements_classes.nil?
        errors.concat(normative_statements_classes.flat_map do |n|
          n.validate(self)
        end)
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
      combined_suite.all_identifiers = nil
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

    def all_identifiers
      return @all_identifiers if @all_identifiers

      nsc = normative_statements_classes || []
      cc = conformance_classes || []

      @all_identifiers = (nsc.flat_map(&:normative_statements) +
              cc.flat_map(&:tests) +
              nsc +
              cc).map(&:identifier)
    end

    attr_writer :all_identifiers

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
      cycles.map { |cycle| "Cycle detected: #{cycle.join(' -> ')}" }
    end

    # Combine all statements into a single array
    # This includes both normative statements and conformance tests
    def all_statements
      nsc = if normative_statements_classes
              normative_statements_classes.flat_map(&:normative_statements)
            else
              []
            end
      cc = if conformance_classes
             conformance_classes.flat_map(&:tests)
           else
             []
           end

      nsc + cc
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
      labels = {}
      errors = []
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
      all_ids = collect_all_identifiers

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

    def collect_all_identifiers
      identifiers = {}

      normative_statements_classes&.each do |nsc|
        identifiers[nsc.identifier.to_s] = nsc
        nsc.normative_statements.each do |ns|
          identifiers[ns.identifier.to_s] = ns
        end
      end

      conformance_classes&.each do |cc|
        identifiers[cc.identifier.to_s] = cc
        cc.tests.each do |ct|
          identifiers[ct.identifier.to_s] = ct
        end
      end

      identifiers
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
