# Backup & Recovery Guide - Librio

**Version**: 1.0  
**Last Updated**: August 23, 2026  
**Status**: Phase 5 - Database Migrations & Deployment

---

## Table of Contents

1. [Overview](#overview)
2. [Backup Strategy](#backup-strategy)
3. [Backup Procedures](#backup-procedures)
4. [Recovery Procedures](#recovery-procedures)
5. [Disaster Recovery](#disaster-recovery)
6. [Testing & Verification](#testing--verification)
7. [Monitoring & Alerts](#monitoring--alerts)

---

## Overview

Librio implements a comprehensive backup and recovery strategy to ensure data protection and business continuity.

### Backup Tiers

| Tier | Type | Frequency | Retention | Purpose |
|------|------|-----------|-----------|---------|
| 1 | Continuous Replication | Real-time | 24 hours | Failover |
| 2 | Daily Snapshots | Daily | 30 days | Point-in-time recovery |
| 3 | Weekly Archives | Weekly | 90 days | Long-term retention |
| 4 | Monthly Archives | Monthly | 1 year | Compliance |

---

## Backup Strategy

### Database Backups

**PostgreSQL Backup Methods**:

#### 1. Continuous Replication (Tier 1)
```bash
# Primary → Standby replication
# Real-time synchronous replication
# Recovery Point Objective (RPO): 0 seconds
# Recovery Time Objective (RTO): < 1 minute
```

**Configuration**:
```yaml
# postgresql.conf
wal_level = replica
max_wal_senders = 10
max_replication_slots = 10
hot_standby = on
```

#### 2. Daily Snapshots (Tier 2)
```bash
# pg_dump with compression
# Scheduled daily at 2 AM UTC
# RPO: 24 hours
# RTO: 30 minutes
```

**Script**:
```bash
#!/bin/bash
BACKUP_DIR="/backups/postgresql"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DB_NAME="librio_production"

pg_dump \
  --host=$DB_HOST \
  --username=$DB_USER \
  --format=custom \
  --compress=9 \
  --file="$BACKUP_DIR/backup_$TIMESTAMP.dump" \
  $DB_NAME

# Verify backup
pg_restore --list "$BACKUP_DIR/backup_$TIMESTAMP.dump" > /dev/null
```

#### 3. Weekly Archives (Tier 3)
```bash
# Full backup + WAL archives
# Scheduled weekly on Sunday
# RPO: 7 days
# RTO: 1-2 hours
```

#### 4. Monthly Archives (Tier 4)
```bash
# Offline backup for compliance
# Scheduled monthly on 1st
# RPO: 30 days
# RTO: 4-8 hours
```

### Application Data Backups

**User Data**:
- Flashcard decks
- Review history
- User statistics
- Sync queue

**Backup Locations**:
- Primary: PostgreSQL database
- Secondary: S3 (encrypted)
- Tertiary: Tape archive (compliance)

### File Backups

**Application Files**:
```bash
# Docker images
# Configuration files
# SSL certificates
# API keys (encrypted)
```

**Backup Locations**:
- Docker registry (ECR/Docker Hub)
- Git repository (source code)
- Secrets manager (encrypted)

---

## Backup Procedures

### Daily Backup Procedure

**Time**: 2:00 AM UTC  
**Duration**: ~15 minutes  
**Verification**: Automated

```bash
#!/bin/bash
set -e

BACKUP_DIR="/backups/postgresql"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DB_NAME="librio_production"
RETENTION_DAYS=30

# Create backup
echo "Starting backup at $(date)"
pg_dump \
  --host=$DB_HOST \
  --username=$DB_USER \
  --format=custom \
  --compress=9 \
  --file="$BACKUP_DIR/backup_$TIMESTAMP.dump" \
  $DB_NAME

# Verify backup
echo "Verifying backup..."
pg_restore --list "$BACKUP_DIR/backup_$TIMESTAMP.dump" > /dev/null

# Upload to S3
echo "Uploading to S3..."
aws s3 cp "$BACKUP_DIR/backup_$TIMESTAMP.dump" \
  "s3://librio-backups/postgresql/backup_$TIMESTAMP.dump" \
  --sse AES256

# Clean old backups (local)
echo "Cleaning old backups..."
find "$BACKUP_DIR" -name "backup_*.dump" -mtime +$RETENTION_DAYS -delete

# Log backup
echo "Backup completed at $(date)" >> /var/log/backups.log
```

### Weekly Archive Procedure

**Time**: Sunday 3:00 AM UTC  
**Duration**: ~30 minutes  
**Verification**: Manual review

```bash
#!/bin/bash
set -e

ARCHIVE_DIR="/backups/archives"
TIMESTAMP=$(date +%Y%m%d)
DB_NAME="librio_production"

# Full backup
pg_dump \
  --host=$DB_HOST \
  --username=$DB_USER \
  --format=tar \
  --compress=9 \
  --file="$ARCHIVE_DIR/archive_$TIMESTAMP.tar.gz" \
  $DB_NAME

# WAL archive
tar czf "$ARCHIVE_DIR/wal_$TIMESTAMP.tar.gz" /var/lib/postgresql/wal_archive/

# Verify
pg_restore --list "$ARCHIVE_DIR/archive_$TIMESTAMP.tar.gz" > /dev/null

# Upload to S3 Glacier
aws s3 cp "$ARCHIVE_DIR/archive_$TIMESTAMP.tar.gz" \
  "s3://librio-archives/postgresql/archive_$TIMESTAMP.tar.gz" \
  --storage-class GLACIER

# Encrypt and upload to tape
# (handled by separate tape backup system)
```

### Monthly Compliance Backup

**Time**: 1st of month, 4:00 AM UTC  
**Duration**: ~1 hour  
**Verification**: Manual + Compliance team

```bash
#!/bin/bash
set -e

COMPLIANCE_DIR="/backups/compliance"
TIMESTAMP=$(date +%Y%m)
DB_NAME="librio_production"

# Full backup
pg_dump \
  --host=$DB_HOST \
  --username=$DB_USER \
  --format=tar \
  --file="$COMPLIANCE_DIR/compliance_$TIMESTAMP.tar" \
  $DB_NAME

# Encrypt with GPG
gpg --encrypt \
  --recipient compliance@librio.com \
  "$COMPLIANCE_DIR/compliance_$TIMESTAMP.tar"

# Verify encryption
gpg --list-only "$COMPLIANCE_DIR/compliance_$TIMESTAMP.tar.gpg"

# Upload to secure archive
aws s3 cp "$COMPLIANCE_DIR/compliance_$TIMESTAMP.tar.gpg" \
  "s3://librio-compliance-archive/backup_$TIMESTAMP.tar.gpg" \
  --sse aws:kms \
  --sse-kms-key-id $KMS_KEY_ID

# Send notification
aws sns publish \
  --topic-arn $SNS_TOPIC \
  --message "Compliance backup completed: $TIMESTAMP"
```

---

## Recovery Procedures

### Point-in-Time Recovery (PITR)

**Scenario**: Accidental data deletion  
**Recovery Time**: 30-60 minutes  
**Data Loss**: 0-24 hours

```bash
#!/bin/bash
set -e

BACKUP_FILE="/backups/postgresql/backup_20260823_020000.dump"
RECOVERY_TIME="2026-08-23 15:30:00"
RECOVERY_DB="librio_recovery"

# Create recovery database
createdb -h $DB_HOST -U $DB_USER $RECOVERY_DB

# Restore from backup
pg_restore \
  --host=$DB_HOST \
  --username=$DB_USER \
  --dbname=$RECOVERY_DB \
  --format=custom \
  "$BACKUP_FILE"

# Apply WAL recovery to specific point in time
psql -h $DB_HOST -U $DB_USER -d $RECOVERY_DB << EOF
SELECT pg_wal_replay_pause();
-- Verify data at recovery point
SELECT * FROM user_profiles LIMIT 5;
EOF

# If recovery is successful, promote recovery database
# psql -h $DB_HOST -U $DB_USER -d postgres << EOF
# ALTER DATABASE librio_production RENAME TO librio_production_old;
# ALTER DATABASE librio_recovery RENAME TO librio_production;
# EOF
```

### Full Database Recovery

**Scenario**: Disk failure, complete data loss  
**Recovery Time**: 1-2 hours  
**Data Loss**: 0-24 hours

```bash
#!/bin/bash
set -e

BACKUP_FILE="s3://librio-backups/postgresql/backup_20260823_020000.dump"
RECOVERY_DB="librio_production"

# Download backup from S3
aws s3 cp "$BACKUP_FILE" ./backup.dump

# Verify backup integrity
pg_restore --list ./backup.dump > /dev/null

# Drop old database (if exists)
psql -h $DB_HOST -U $DB_USER -d postgres << EOF
DROP DATABASE IF EXISTS $RECOVERY_DB;
CREATE DATABASE $RECOVERY_DB;
EOF

# Restore database
pg_restore \
  --host=$DB_HOST \
  --username=$DB_USER \
  --dbname=$RECOVERY_DB \
  --format=custom \
  ./backup.dump

# Verify recovery
psql -h $DB_HOST -U $DB_USER -d $RECOVERY_DB << EOF
SELECT COUNT(*) as user_count FROM user_profiles;
SELECT COUNT(*) as deck_count FROM flashcard_decks;
SELECT COUNT(*) as card_count FROM flashcards;
EOF

# Clean up
rm ./backup.dump
```

### Replica Failover

**Scenario**: Primary database failure  
**Recovery Time**: < 1 minute  
**Data Loss**: 0 seconds

```bash
#!/bin/bash
set -e

STANDBY_HOST="db-standby.internal"
STANDBY_USER="postgres"

# Promote standby to primary
ssh $STANDBY_USER@$STANDBY_HOST << EOF
pg_ctl promote -D /var/lib/postgresql/data
EOF

# Update application connection string
# Update DNS to point to new primary
aws route53 change-resource-record-sets \
  --hosted-zone-id $ZONE_ID \
  --change-batch file://dns-update.json

# Verify new primary
psql -h $STANDBY_HOST -U $STANDBY_USER -d librio_production << EOF
SELECT pg_is_in_recovery();
EOF
```

---

## Disaster Recovery

### RTO/RPO Targets

| Scenario | RTO | RPO | Strategy |
|----------|-----|-----|----------|
| Single server failure | < 1 min | 0 sec | Replica failover |
| Data corruption | 30 min | 24 hrs | PITR from backup |
| Disk failure | 1-2 hrs | 24 hrs | Full restore |
| Regional outage | 4 hrs | 24 hrs | Cross-region restore |
| Complete loss | 8 hrs | 30 days | Archive restore |

### Disaster Recovery Plan

**Phase 1: Detection (0-5 minutes)**
- Monitoring alerts
- Health check failures
- Manual verification

**Phase 2: Assessment (5-15 minutes)**
- Determine scope of failure
- Identify recovery strategy
- Notify stakeholders

**Phase 3: Recovery (15-60 minutes)**
- Execute recovery procedure
- Verify data integrity
- Validate application

**Phase 4: Validation (60-120 minutes)**
- Run smoke tests
- Verify user access
- Monitor metrics

**Phase 5: Communication (ongoing)**
- Update status page
- Notify users
- Post-incident review

---

## Testing & Verification

### Backup Verification

**Daily Verification**:
```bash
# Verify backup file integrity
pg_restore --list $BACKUP_FILE > /dev/null

# Check backup size
ls -lh $BACKUP_FILE

# Verify S3 upload
aws s3 ls s3://librio-backups/postgresql/ --recursive
```

**Weekly Verification**:
```bash
# Test restore to temporary database
createdb test_restore
pg_restore --dbname=test_restore $BACKUP_FILE
psql -d test_restore -c "SELECT COUNT(*) FROM user_profiles;"
dropdb test_restore
```

**Monthly Verification**:
```bash
# Full recovery test
# Restore to separate environment
# Run full test suite
# Verify all data
# Document results
```

### Recovery Testing

**Quarterly Disaster Recovery Drill**:
1. Simulate primary failure
2. Execute failover procedure
3. Verify application functionality
4. Measure RTO and RPO
5. Document lessons learned
6. Update procedures

**Annual Full Recovery Test**:
1. Restore from oldest archive
2. Verify data completeness
3. Test application with recovered data
4. Measure recovery time
5. Validate compliance

---

## Monitoring & Alerts

### Backup Monitoring

**Metrics**:
- Backup duration
- Backup size
- Backup success/failure
- S3 upload status
- Backup age

**Alerts**:
```yaml
- name: BackupFailure
  condition: backup_success == 0
  severity: critical
  action: page_on_call

- name: BackupTooOld
  condition: backup_age_hours > 25
  severity: high
  action: notify_team

- name: BackupSizeAnomaly
  condition: backup_size > baseline * 1.5
  severity: medium
  action: investigate
```

### Health Checks

**Backup Health**:
```bash
#!/bin/bash

# Check last backup
LAST_BACKUP=$(ls -t /backups/postgresql/backup_*.dump | head -1)
BACKUP_AGE=$(($(date +%s) - $(stat -f%m "$LAST_BACKUP")))

if [ $BACKUP_AGE -gt 86400 ]; then
  echo "CRITICAL: Backup is older than 24 hours"
  exit 2
fi

# Check backup size
BACKUP_SIZE=$(du -h "$LAST_BACKUP" | cut -f1)
echo "OK: Last backup: $LAST_BACKUP ($BACKUP_SIZE)"
exit 0
```

---

## Backup Checklist

- [ ] Daily backups configured
- [ ] Weekly archives configured
- [ ] Monthly compliance backups configured
- [ ] Replication configured
- [ ] S3 encryption enabled
- [ ] Backup verification automated
- [ ] Recovery procedures documented
- [ ] Disaster recovery plan created
- [ ] RTO/RPO targets defined
- [ ] Monitoring configured
- [ ] Alerts configured
- [ ] Recovery testing scheduled
- [ ] Team trained
- [ ] Documentation updated

---

## Resources

### Commands

```bash
# List backups
ls -lh /backups/postgresql/

# Verify backup
pg_restore --list backup.dump

# Restore database
pg_restore --dbname=librio_production backup.dump

# Check replication status
psql -c "SELECT * FROM pg_stat_replication;"

# Promote standby
pg_ctl promote -D /var/lib/postgresql/data
```

### Files

- `.backup-config.yaml` - Backup configuration
- `backup.sh` - Daily backup script
- `archive.sh` - Weekly archive script
- `recovery.sh` - Recovery procedures
- `disaster-recovery-plan.md` - DR plan

---

*Generated: August 23, 2026*  
*Status: Phase 5 - Backup & Recovery*  
*Next: Deployment Automation*
