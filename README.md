# Self-hosted Infracost

## What
Run Infracost server and postgres backend for one-off estimation.

You should likely be using a long-living database to rate-limit scraping.

## How

With docker and make installed, run `make`

## Example Output

```
Project: /terraform

Name                                                 Monthly Qty  Unit   Monthly Cost

aws_instance.app_server
├─ Instance usage (Linux/UNIX, on-demand, t2.micro)          730  hours         $8.47
└─ root_block_device
   └─ Storage (general purpose SSD, gp2)                       8  GB            $0.80

 OVERALL TOTAL                                                                  $9.27
──────────────────────────────────
1 cloud resource was detected:
∙ 1 was estimated, it includes usage-based costs, see https://infracost.io/usage-file
```
