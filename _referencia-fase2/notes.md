# 1. senha postgres
[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("postgres"))
cG9zdGdyZXM=

# 2. master key
[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("admin-secreto-123"))
YWRtaW4tc2VjcmV0by0xMjM=

# 3. DATABASE_URL auth
[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("postgres://postgres:postgres@auth-postgres.togglemaster.svc.cluster.local:5432/auth_db"))
cG9zdGdyZXM6Ly9wb3N0Z3Jlczpwb3N0Z3Jlc0BhdXRoLXBvc3RncmVzLnRvZ2dsZW1hc3Rlci5zdmMuY2x1c3Rlci5sb2NhbDo1NDMyL2F1dGhfZGI=

# 4. DATABASE_URL flag
[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("postgres://postgres:postgres@flag-postgres.togglemaster.svc.cluster.local:5432/flag_db"))
cG9zdGdyZXM6Ly9wb3N0Z3Jlczpwb3N0Z3Jlc0BmbGFnLXBvc3RncmVzLnRvZ2dsZW1hc3Rlci5zdmMuY2x1c3Rlci5sb2NhbDo1NDMyL2ZsYWdfZGI=

# 5. DATABASE_URL targeting
[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("postgres://postgres:postgres@targeting-postgres.togglemaster.svc.cluster.local:5432/targeting_db"))
cG9zdGdyZXM6Ly9wb3N0Z3Jlczpwb3N0Z3Jlc0B0YXJnZXRpbmctcG9zdGdyZXMudG9nZ2xlbWFzdGVyLnN2Yy5jbHVzdGVyLmxvY2FsOjU0MzIvdGFyZ2V0aW5nX2Ri

# 6. REDIS_URL (substitua pelo endpoint real do ElastiCache)
[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("rediss://SEU_ENDPOINT:6379"))

# 7. SQS URL (substitua pelo valor real)
[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("https://sqs.us-east-1.amazonaws.com/697683755104/togglemaster-events"))
aHR0cHM6Ly9zcXMudXMtZWFzdC0xLmFtYXpvbmF3cy5jb20vNjk3NjgzNzU1MTA0L3RvZ2dsZW1hc3Rlci1ldmVudHM=

# 8. AWS Region
[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("us-east-1"))
dXMtZWFzdC0x

# 9. DynamoDB table name
[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("ToggleMasterAnalytics"))
VG9nZ2xlTWFzdGVyQW5hbHl0aWNz

# 10. endpoint Redis
[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("rediss://master.togglemaster-redis-cache.hreaey.use1.cache.amazonaws.com:6379"))
cmVkaXNzOi8vbWFzdGVyLnRvZ2dsZW1hc3Rlci1yZWRpcy1jYWNoZS5ocmVhZXkudXNlMS5jYWNoZS5hbWF6b25hd3MuY29tOjYzNzk=

