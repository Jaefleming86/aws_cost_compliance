# Demo Script (5–7 minutes)

1) **Required Tags Enforcement**
   - Create a test S3 bucket *without* required tags.
   - Wait ~1–2 minutes: AWS Config flags non-compliant.
   - Auto-remediation Lambda adds missing tags; check CloudWatch Logs for evidence.
   - Show the resource now compliant in the Config console.

2) **Budget per Tag**
   - In Billing > Budgets, show the generated budget for `App=demo-app`.
   - (Optionally) raise a test spend (start a small instance) and trigger alarms (or simulate via threshold change).

3) **NAT Cost Reduction**
   - Show VPC **Gateway Endpoints** for S3/DynamoDB created in the selected VPC.
   - Explain path: instances in private subnets access S3/DynamoDB without NAT egress charges.

4) **Security Hub**
   - Show Security Hub is enabled and CIS standard subscribed.

5) **CUR in Athena**
   - Open `sql/top_services_month.sql` in Athena. Show Top 10 services spend this month.
