# Test Scripts

This directory contains utility scripts for testing and verifying system functionality.

## Available Scripts

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