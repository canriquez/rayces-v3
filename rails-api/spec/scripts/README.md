# Test Scripts

This directory contains utility scripts for testing and verifying system functionality.

## Available Scripts

### test_fresh_boot.rb
Tests that the Rails application can boot successfully from a fresh state without encountering initialization errors.

**What it tests:**
- Database drop and recreation
- `rails db:create` without NameError crashes
- `rails db:migrate` execution
- Model loading after migrations
- acts_as_tenant initializer boot safety
- Rails server startup

**How to run from Kubernetes:**

```bash
# From local machine - run the test in the Rails pod
kubectl exec -n raycesv3 $(kubectl get pods -n raycesv3 | grep rails-rayces | grep Running | awk '{print $1}') -- bundle exec ruby /var/www/rails-api/spec/scripts/test_fresh_boot.rb

# With options
kubectl exec -n raycesv3 $(kubectl get pods -n raycesv3 | grep rails-rayces | grep Running | awk '{print $1}') -- bundle exec ruby /var/www/rails-api/spec/scripts/test_fresh_boot.rb --verbose

# Skip database drop (if databases don't exist)
kubectl exec -n raycesv3 $(kubectl get pods -n raycesv3 | grep rails-rayces | grep Running | awk '{print $1}') -- bundle exec ruby /var/www/rails-api/spec/scripts/test_fresh_boot.rb --skip-drop
```

**How to run after bashing into the Rails pod:**

```bash
# First, bash into the pod
kubectl exec -n raycesv3 -it $(kubectl get pods -n raycesv3 | grep rails-rayces | grep Running | awk '{print $1}') -- bash

# Then run the test
cd /var/www/rails-api
bundle exec ruby spec/scripts/test_fresh_boot.rb

# Or with options
bundle exec ruby spec/scripts/test_fresh_boot.rb --verbose
bundle exec ruby spec/scripts/test_fresh_boot.rb --skip-drop
bundle exec ruby spec/scripts/test_fresh_boot.rb --help
```

**Expected output:**
- Drops and recreates databases
- Successfully runs db:create without crashes
- Runs all migrations
- Verifies Organization model loads correctly
- Tests acts_as_tenant configuration
- Confirms Rails server can boot
- Reports success or lists any failures

**Options:**
- `--skip-drop`: Skip dropping databases (useful if they don't exist)
- `--verbose`: Show detailed output from each command
- `--help`: Show usage information

### verify_multi_tenancy.rb
Verifies that acts_as_tenant properly isolates data between organizations for all PRP-35 models.

**What it tests:**
- CreditBalance isolation
- CreditTransaction isolation
- AvailabilityRule isolation
- TimeSlot isolation
- Error handling without tenant context
- Cross-tenant data visibility

**How to run:**

```bash
# From local machine
kubectl exec -n raycesv3 $(kubectl get pods -n raycesv3 | grep rails-rayces | grep Running | awk '{print $1}') -- bundle exec rails runner /var/www/rails-api/spec/scripts/verify_multi_tenancy.rb

# Or copy and run in two steps
POD=$(kubectl get pods -n raycesv3 | grep rails-rayces | grep Running | awk '{print $1}')
kubectl cp rails-api/spec/scripts/verify_multi_tenancy.rb raycesv3/$POD:/var/www/rails-api/spec/scripts/verify_multi_tenancy.rb
kubectl exec -n raycesv3 $POD -- bundle exec rails runner /var/www/rails-api/spec/scripts/verify_multi_tenancy.rb
```

**Expected output:**
- Creates test data in 2 organizations
- Verifies each organization only sees its own data
- Confirms ActsAsTenant::Errors::NoTenantSet without context
- Cleans up test data after verification

## Adding New Scripts

When adding new verification scripts:
1. Place them in this directory
2. Document what they test
3. Include kubectl commands for running
4. Clean up any test data created
5. Update this README