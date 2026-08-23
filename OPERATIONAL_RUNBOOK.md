# Operational Runbook - Librio

**Version**: 1.0  
**Last Updated**: August 23, 2026  
**Status**: Phase 5 - Database Migrations & Deployment

---

## Table of Contents

1. [Overview](#overview)
2. [On-Call Procedures](#on-call-procedures)
3. [Common Issues & Solutions](#common-issues--solutions)
4. [Incident Response](#incident-response)
5. [Maintenance Procedures](#maintenance-procedures)
6. [Escalation Paths](#escalation-paths)

---

## Overview

This runbook provides operational procedures for managing Librio in production.

### Key Contacts

| Role | Name | Email | Phone |
|------|------|-------|-------|
| Engineering Lead | - | eng@librio.com | - |
| On-Call Engineer | - | oncall@librio.com | - |
| Database Admin | - | dba@librio.com | - |
| Security Team | - | security@librio.com | - |

### Critical Systems

| System | Purpose | SLA | Contact |
|--------|---------|-----|---------|
| API Server | Backend API | 99.9% | eng@librio.com |
| Database | Data storage | 99.95% | dba@librio.com |
| Auth Service | User authentication | 99.9% | eng@librio.com |
| Analytics | Event tracking | 99.0% | analytics@librio.com |

---

## On-Call Procedures

### Daily Standup

**Time**: 9:00 AM UTC  
**Duration**: 15 minutes  
**Attendees**: Engineering team

**Agenda**:
1. System status overview
2. Recent deployments
3. Known issues
4. Planned maintenance
5. Action items

### Weekly Review

**Time**: Friday 4:00 PM UTC  
**Duration**: 1 hour  
**Attendees**: Engineering + Product

**Agenda**:
1. Performance metrics review
2. Error rate analysis
3. User feedback summary
4. Upcoming changes
5. Lessons learned

### On-Call Shift

**Duration**: 1 week  
**Responsibilities**:
- Monitor alerts
- Respond to incidents
- Perform emergency fixes
- Document issues
- Hand off to next on-call

**Escalation**:
- P1 (Critical): Immediate response
- P2 (High): Within 15 minutes
- P3 (Medium): Within 1 hour
- P4 (Low): Within 24 hours

---

## Common Issues & Solutions

### Issue: High Error Rate

**Symptoms**:
- Error rate > 5%
- Sentry alerts triggered
- User complaints

**Diagnosis**:
```bash
# Check error logs
kubectl logs -f deployment/librio-api --tail=100

# Check error metrics
curl http://api.librio.app/metrics | grep http_requests_total

# Check Sentry
# https://sentry.io/organizations/librio/issues/
```

**Solutions**:

**1. Database Connection Issues**
```bash
# Check database connectivity
psql -h $DB_HOST -U $DB_USER -d librio_production -c "SELECT 1;"

# Check connection pool
psql -c "SELECT count(*) FROM pg_stat_activity;"

# Restart connection pool
kubectl rollout restart deployment/librio-api
```

**2. Memory Leak**
```bash
# Check memory usage
kubectl top pods -l app=librio-api

# Check for memory leaks
# Review recent code changes
# Restart pods
kubectl rollout restart deployment/librio-api
```

**3. Slow Queries**
```bash
# Check slow query log
psql -c "SELECT query, calls, mean_time FROM pg_stat_statements ORDER BY mean_time DESC LIMIT 10;"

# Kill long-running queries
psql -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE duration > interval '5 minutes';"

# Analyze query plan
EXPLAIN ANALYZE SELECT ...;
```

**Escalation**:
- If error rate persists > 15 minutes: Page on-call
- If error rate > 20%: Initiate rollback
- If database down: Activate DR plan

### Issue: Slow Response Times

**Symptoms**:
- P95 response time > 2 seconds
- User complaints about slowness
- Timeout errors

**Diagnosis**:
```bash
# Check response time metrics
curl http://api.librio.app/metrics | grep http_request_duration

# Check database performance
psql -c "SELECT query, calls, mean_time FROM pg_stat_statements ORDER BY mean_time DESC LIMIT 10;"

# Check server resources
kubectl top nodes
kubectl top pods -l app=librio-api
```

**Solutions**:

**1. Database Optimization**
```bash
# Analyze tables
ANALYZE;

# Reindex
REINDEX DATABASE librio_production;

# Vacuum
VACUUM ANALYZE;
```

**2. Cache Issues**
```bash
# Clear cache
redis-cli FLUSHALL

# Check cache hit rate
redis-cli INFO stats
```

**3. Scale Up**
```bash
# Increase replicas
kubectl scale deployment librio-api --replicas=5

# Check HPA status
kubectl get hpa
```

### Issue: Database Disk Full

**Symptoms**:
- Write errors
- Deployment failures
- Backup failures

**Diagnosis**:
```bash
# Check disk usage
df -h

# Check database size
psql -c "SELECT pg_size_pretty(pg_database_size('librio_production'));"

# Check table sizes
psql -c "SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) FROM pg_tables ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC LIMIT 10;"
```

**Solutions**:

**1. Clean Old Data**
```bash
-- Delete old sync queue entries
DELETE FROM sync_queue WHERE synced = true AND created_at < NOW() - INTERVAL '30 days';

-- Delete old audit logs
DELETE FROM audit_logs WHERE created_at < NOW() - INTERVAL '90 days';

-- Vacuum
VACUUM ANALYZE;
```

**2. Archive Data**
```bash
-- Archive old review data
INSERT INTO review_archive SELECT * FROM review_sessions WHERE completed_at < NOW() - INTERVAL '1 year';
DELETE FROM review_sessions WHERE completed_at < NOW() - INTERVAL '1 year';
```

**3. Expand Storage**
```bash
# Expand EBS volume
aws ec2 modify-volume --volume-id vol-xxx --size 500

# Extend filesystem
sudo resize2fs /dev/nvme0n1p1
```

### Issue: Authentication Failures

**Symptoms**:
- Login errors
- Token verification failures
- User lockouts

**Diagnosis**:
```bash
# Check auth service logs
kubectl logs -f deployment/librio-api | grep -i auth

# Check JWT secret
echo $JWT_SECRET

# Test token generation
curl -X POST http://api.librio.app/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test"}'
```

**Solutions**:

**1. JWT Secret Mismatch**
```bash
# Verify secret is set correctly
kubectl get secret librio-secrets -o jsonpath='{.data.jwt-secret}' | base64 -d

# Update if needed
kubectl set env deployment/librio-api JWT_SECRET=$NEW_SECRET
```

**2. Token Expiration**
```bash
# Check token expiration settings
grep -r "expiresIn" src/services/auth.service.ts

# Adjust if needed
# Redeploy
```

**3. Database Issues**
```bash
# Check user table
psql -c "SELECT COUNT(*) FROM user_profiles;"

# Check for locked users
psql -c "SELECT * FROM user_profiles WHERE deleted_at IS NOT NULL;"
```

---

## Incident Response

### Incident Classification

| Severity | Impact | Response Time | Example |
|----------|--------|----------------|---------|
| P1 | Complete outage | Immediate | API down |
| P2 | Major degradation | 15 minutes | 50% error rate |
| P3 | Minor degradation | 1 hour | Slow queries |
| P4 | No user impact | 24 hours | Log errors |

### Incident Response Procedure

**Phase 1: Detection (0-5 min)**
```
1. Alert triggered
2. On-call notified
3. Acknowledge alert
4. Begin investigation
```

**Phase 2: Triage (5-15 min)**
```
1. Assess severity
2. Identify scope
3. Determine impact
4. Notify stakeholders
```

**Phase 3: Mitigation (15-60 min)**
```
1. Implement fix or workaround
2. Deploy fix or rollback
3. Verify resolution
4. Monitor metrics
```

**Phase 4: Recovery (60-120 min)**
```
1. Restore normal operations
2. Verify all systems
3. Update status page
4. Notify users
```

**Phase 5: Post-Incident (24-48 hours)**
```
1. Root cause analysis
2. Document lessons learned
3. Create action items
4. Update runbook
```

### Incident Communication

**Initial Notification** (within 5 minutes):
```
🚨 INCIDENT: API Error Rate High
Severity: P2
Status: Investigating
Impact: 10% of users affected
```

**Status Updates** (every 15 minutes):
```
🔄 UPDATE: Identified slow database queries
Action: Optimizing queries
ETA: 15 minutes
```

**Resolution** (when fixed):
```
✅ RESOLVED: Error rate normalized
Root Cause: Slow query on user_profiles table
Fix: Added index on email column
```

---

## Maintenance Procedures

### Daily Maintenance

**Morning (9:00 AM UTC)**:
- [ ] Check system status
- [ ] Review error logs
- [ ] Verify backups completed
- [ ] Check disk usage
- [ ] Review metrics

**Evening (6:00 PM UTC)**:
- [ ] Verify no critical alerts
- [ ] Check deployment status
- [ ] Review user feedback
- [ ] Prepare for next day

### Weekly Maintenance

**Monday**:
- [ ] Review performance metrics
- [ ] Analyze error trends
- [ ] Check security logs
- [ ] Plan week ahead

**Wednesday**:
- [ ] Test disaster recovery
- [ ] Review backup status
- [ ] Update documentation
- [ ] Team sync

**Friday**:
- [ ] Weekly review meeting
- [ ] Plan next week
- [ ] Prepare release notes
- [ ] Celebrate wins

### Monthly Maintenance

**First Week**:
- [ ] Full backup verification
- [ ] Database optimization
- [ ] Security audit
- [ ] Capacity planning

**Third Week**:
- [ ] Performance review
- [ ] Dependency updates
- [ ] Documentation review
- [ ] Team training

### Quarterly Maintenance

- [ ] Disaster recovery drill
- [ ] Security penetration test
- [ ] Performance benchmarking
- [ ] Architecture review
- [ ] Capacity planning

---

## Escalation Paths

### Technical Escalation

```
Level 1: On-Call Engineer
├─ Diagnose issue
├─ Apply quick fix
└─ If unresolved → Level 2

Level 2: Engineering Lead
├─ Review diagnosis
├─ Authorize major changes
├─ Coordinate team
└─ If unresolved → Level 3

Level 3: CTO
├─ Strategic decision
├─ Resource allocation
├─ Executive communication
└─ If unresolved → External support
```

### Business Escalation

```
Level 1: Support Team
├─ Acknowledge issue
├─ Provide status updates
└─ If SLA at risk → Level 2

Level 2: Product Manager
├─ Assess business impact
├─ Communicate with customers
├─ Prioritize fix
└─ If major impact → Level 3

Level 3: Executive Team
├─ Customer communication
├─ Media response
├─ Compensation decisions
└─ Post-incident review
```

---

## Quick Reference

### Critical Commands

```bash
# Check system status
kubectl get all -n production

# View logs
kubectl logs -f deployment/librio-api

# Scale deployment
kubectl scale deployment librio-api --replicas=5

# Restart deployment
kubectl rollout restart deployment/librio-api

# Rollback deployment
kubectl rollout undo deployment/librio-api

# Check database
psql -h $DB_HOST -U $DB_USER -d librio_production

# View metrics
curl http://api.librio.app/metrics

# Health check
curl http://api.librio.app/health
```

### Important URLs

- **API**: https://api.librio.app
- **Staging**: https://staging.librio.app
- **Sentry**: https://sentry.io/organizations/librio/
- **Grafana**: https://grafana.librio.internal/
- **Kubernetes**: https://k8s.librio.internal/
- **Status Page**: https://status.librio.app

### Important Files

- `.env.production` - Production configuration
- `k8s/` - Kubernetes manifests
- `scripts/deploy.sh` - Deployment script
- `scripts/rollback.sh` - Rollback script
- `MONITORING_GUIDE.md` - Monitoring setup
- `BACKUP_AND_RECOVERY_GUIDE.md` - Backup procedures

---

*Generated: August 23, 2026*  
*Status: Phase 5 - Operational Runbook*  
*Next: Production Launch*
