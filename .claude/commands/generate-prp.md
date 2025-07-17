# Create PRP

## Feature file: INITIAL-SCRUM-$ARGUMENTS

Generate a complete PRP for general feature implementation with thorough research. You will find the full initial feature description {{$ARGUMENTS}} located inside the full path /issues/SCRUM-{{$ARGUMENTS}}/INITIAL-SCRUM-{{$ARGUMENTS}}.md. Ensure context is passed to the AI agent to enable self-validation and iterative refinement. Read the feature file first to understand what needs to be created, how the examples provided help, and any other considerations.

The AI agent only gets the context you are appending to the PRP and training data. Assuma the AI agent has access to the codebase and the same knowledge cutoff as you, so its important that your research findings are included or referenced in the PRP. The Agent has Websearch capabilities, so pass urls to documentation and examples.

## Research Process

1. **Previous PRP Results Review**
   - Check for existing `/PRPs/*-results.md` files as well as `/PRPs/*-execution-logs.md` in PRPs directory to quickly learn about the latest progress within the repository after execution of previous scrum PRPs.
   - Review any related PRP results files for context and dependencies
   - Identify completed work that can be built upon
   - Note any pending items or blockers from previous implementations
   - Note that some of the scrum issues might have part of its descriptions outdated, so include always a step trying to verify the tasks to be executed as some of them might be already implemented. If that is the case use the current MCPs to update the github issue and the Jira and Confluence documentation as well with what you just learned. This will ensure we have the project documentation up to date.
   - Only If you confirm that in deed the issue is completly done and you must close the issue, still generate the PRP file with the instruction to attemp update the documentation on jira, confluence and github. The PRP still need to complete the flow so we have all PRP files involved available in the repo and we do not have missing files (e.g. no prp file) explaining the complete picture of the progress. 

2. **Codebase Analysis**
   - Search for similar features/patterns in the codebase
   - Identify files to reference in PRP
   - Note existing conventions to follow
   - Check test patterns for validation approach
   - Run local tests to learn details of the failing tests that the issue must resolve (if any)

3. **External Research**
   - Search for similar features/patterns online
   - Library documentation (include specific URLs)
   - Implementation examples (GitHub/StackOverflow/blogs)
   - Best practices and common pitfalls

4. **User Clarification** (if needed)
   - Specific patterns to mirror and where to find them?
   - Integration requirements and where to find them?

5. **Development process**
   - THIS IS IMPORTANT. DO NOT FORGET: Check the /README.md file for detailed instructions of how to Running Tests in Development with Skaffold for this repository. Then add this instructions to PRPs/{{$ARGUMENTS}}.md so running tests work with no issues, and you never forget how to run tests.

## PRP Generation

Using PRPs/templates/prp_base.md as template:

### Critical Context to Include and pass to the AI agent as part of the PRP
- **Documentation**: URLs with specific sections
- **Code Examples**: Real snippets from codebase
- **Gotchas**: Library quirks, version issues
- **Patterns**: Existing approaches to follow

### Implementation Blueprint
- Start with pseudocode showing approach
- Reference real files for patterns
- Include error handling strategy
- list tasks to be completed to fullfill the PRP in the order they should be completed
- When possible plan to run and pass all related tests for new implemented code before moving to the next relevant task. This will help you fix tests progressiveley, and not wait until the end.
- Include ready to use scripts to run common actions like running tests, or runnig migrations, execute scripts, etc, for the current environment. You must become aware of how are basic things executed in the current environment. For this check the readme.md, .claude.md, changelog.md or even old prp execution files located inside `/PRPs/*-execution-log.md` as well as `/PRPs/*.md` files. All with the idea to extract key information that will help you execute your actions within the PRP under construction. Find below some examples of this instructions using rails code examples:

### Rails Example: Run Existing Migrations. example for Rails on a k8s / `skaffold dev` driven environment
```bash
#  Check current migration status
kubectl exec -n raycesv3 $(kubectl get pods -n raycesv3 | grep rails-rayces | grep Running | awk '{print $1}') -- bundle exec rails db:migrate:status

# Run pending migrations
kubectl exec -n raycesv3 $(kubectl get pods -n raycesv3 | grep rails-rayces | grep Running | awk '{print $1}') -- bundle exec rails db:migrate

#  Verify schema
kubectl exec -n raycesv3 $(kubectl get pods -n raycesv3 | grep rails-rayces | grep Running | awk '{print $1}') -- bundle exec rails db:schema:dump

# Run all tests to ensure no regressions
kubectl exec -n raycesv3 $(kubectl get pods -n raycesv3 | grep rails-rayces | grep Running | awk '{print $1}') -- bundle exec rspec

# Check for migration-specific tests
kubectl exec -n raycesv3 $(kubectl get pods -n raycesv3 | grep rails-rayces | grep Running | awk '{print $1}') -- bundle exec rspec spec/migrations/ --format documentation


# Run Rubocop
kubectl exec -n raycesv3 $(kubectl get pods -n raycesv3 | grep rails-rayces | grep Running | awk '{print $1}') -- bundle exec rubocop app/models/
```

*** CRITICAL AFTER YOU ARE DONE RESEARCHING AND EXPLORING THE CODEBASE BEFORE YOU START WRITING THE PRP ***

*** ULTRATHINK ABOUT THE PRP AND PLAN YOUR APPROACH THEN START WRITING THE PRP ***

## Output
Save as: `PRPs/{{$ARGUMENTS}}.md`

## Quality Checklist
- [ ] All necessary context included
- [ ] Validation gates are executable by AI
- [ ] References existing patterns
- [ ] Clear implementation path
- [ ] Error handling documented

Score the PRP on a scale of 1-10 (confidence level to succeed in one-pass implementation using claude codes)

Remember: The goal is one-pass implementation success through comprehensive context.