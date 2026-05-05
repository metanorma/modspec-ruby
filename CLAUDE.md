# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`modspec` is a Ruby gem for working with OGC ModSpec — a specification format (OGC 08-131r3) for defining requirements and conformance tests for standards. All models use `lutaml-model` (`Lutaml::Model::Serializable`) for serialization to/from YAML, JSON, and XML.

## Commands

- **Run all tests:** `bundle exec rake` or `bundle exec rspec`
- **Run a single test file:** `bundle exec rspec spec/modspec/suite_spec.rb`
- **Run a single example:** `bundle exec rspec spec/modspec/suite_spec.rb:42`
- **Lint:** RuboCop is configured but not in the default rake task. Run with `bundle exec rubocop` if needed.
- **Console:** `bin/console` (loads IRB with the gem)

## Architecture

All model classes inherit from `Lutaml::Model::Serializable` and define attributes via the `attribute` DSL with serialization mappings in `xml do` blocks. YAML/JSON serialization comes from lutaml-model automatically.

### Identifier convention (critical)

Identifiers are URIs with a specific structure:
- Class-level: `/<type>/<class>` (e.g., `/req/example`, `/conf/example`)
- Instance-level: `/<type>/<class>/<name>` (e.g., `/req/example/foo`)
- Type prefix: `req` = normative statements, `conf` = conformance tests

Validation enforces that children share their parent's identifier prefix.

### Model hierarchy

```
Suite
├── NormativeStatementsClass (collection) → groups normative statements
│   └── NormativeStatement (collection)
│       └── NormativeStatementPart (collection) → sub-parts of a statement
├── ConformanceClass (collection) → groups conformance tests
│   └── ConformanceTest (collection)
```

- `NormativeStatement` has obligation (`requirement`/`recommendation`/`permission`), dependencies, inherit, indirect_dependency, implements, parts
- `ConformanceTest` has targets (referencing normative statement identifiers), abstract flag, method, purpose
- `ConformanceTest` uses runtime-only `corresponding_requirements` and `parent_class` attrs set by `Suite#setup_relationships`

### Validation

Each model class has a `validate` method that returns an array of error strings. `Suite#validate` orchestrates full validation: cycles (dependency graph via DFS), label uniqueness, dependency resolution, and delegating to child class validators.

### Key Suite operations

- `combine(other_suite)` — merges two suites, deduplicating by identifier
- `from_yaml_files(*files)` — loads and combines multiple YAML files
- `setup_relationships` — cross-links conformance tests to their target normative statements

### Custom types

`Modspec::Identifier` extends `Lutaml::Model::Type::String` — used as the type for all identifier attributes and reference fields (dependencies, targets, inherit, etc.).

## Key dependency

`lutaml-model ~> 0.7.7` — provides the `Serializable` base class, attribute DSL, and serialization adapters. Breaking changes in lutaml-model may affect this gem.
