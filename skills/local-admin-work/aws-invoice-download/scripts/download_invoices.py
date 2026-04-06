#!/usr/bin/env python3
"""Download AWS invoices across all org accounts, deduplicated by invoice ID."""

import argparse
import json
import os
import subprocess
import urllib.request
from datetime import datetime, timedelta

PROFILE = os.environ.get("AWS_PROFILE", "default")
REGION = os.environ.get("AWS_REGION", "us-east-1")


def aws(*args):
    result = subprocess.run(
        ["aws", "--profile", PROFILE, "--region", REGION, "--output", "json", "--no-cli-pager", *args],
        capture_output=True, text=True,
    )
    if result.returncode != 0:
        print(f"  ERROR: {result.stderr.strip()}")
        return None
    return json.loads(result.stdout) if result.stdout.strip() else None


def get_mgmt_account_id():
    data = aws("organizations", "describe-organization", "--query", "Organization.MasterAccountId")
    if not data:
        raise SystemExit("Failed to get management account ID")
    return data


def get_accounts(mgmt_id):
    data = aws("organizations", "list-accounts", "--query", "Accounts[].[Id,Name]")
    if not data:
        raise SystemExit("Failed to list accounts")
    return sorted(data, key=lambda a: (a[0] == mgmt_id, a[1]))


def billing_periods(months):
    now = datetime.now().replace(day=1)
    periods = []
    dt = now
    for _ in range(months):
        periods.append((dt.month, dt.year))
        dt = (dt - timedelta(days=1)).replace(day=1)
    return sorted(periods)


def list_invoices(account_id, month, year):
    data = aws(
        "invoicing", "list-invoice-summaries",
        "--selector", f"ResourceType=ACCOUNT_ID,Value={account_id}",
        "--filter", json.dumps({"BillingPeriod": {"Month": month, "Year": year}}),
    )
    return data.get("InvoiceSummaries", []) if data else []


def download_invoice(invoice_id, dest_path):
    data = aws("invoicing", "get-invoice-pdf", "--invoice-id", invoice_id)
    if not data:
        return False
    url = data.get("InvoicePDF", {}).get("DocumentUrl")
    if not url:
        return False
    urllib.request.urlretrieve(url, dest_path)
    return True


def main():
    parser = argparse.ArgumentParser(description="Download AWS org invoices")
    parser.add_argument("--months", type=int, required=True)
    parser.add_argument("--output-dir", default="/output")
    args = parser.parse_args()

    mgmt_id = get_mgmt_account_id()
    accounts = get_accounts(mgmt_id)
    periods = billing_periods(args.months)
    seen_ids = set()
    total = 0

    print(f"Accounts: {len(accounts)} | Periods: {[f'{m:02d}-{y}' for m, y in periods]}")

    for month, year in periods:
        folder = f"{month:02d}-{year}"
        folder_path = os.path.join(args.output_dir, folder)
        os.makedirs(folder_path, exist_ok=True)
        print(f"\n=== {folder} ===")

        for account_id, account_name in accounts:
            for inv in list_invoices(account_id, month, year):
                inv_id = inv["InvoiceId"]
                if inv_id in seen_ids:
                    continue
                seen_ids.add(inv_id)

                amount = inv.get("BaseCurrencyAmount", {}).get("TotalAmount", "?")
                currency = inv.get("BaseCurrencyAmount", {}).get("CurrencyCode", "")
                safe = lambda s: s.replace(" ", "_").replace("/", "_")
                dest = os.path.join(folder_path, f"{safe(account_name)}_{safe(inv_id)}.pdf")

                if download_invoice(inv_id, dest):
                    print(f"  ✓ {safe(account_name)}_{safe(inv_id)}.pdf ({amount} {currency})")
                    total += 1
                else:
                    print(f"  ✗ Failed: {inv_id}")

    print(f"\nDone — {total} invoices downloaded")


if __name__ == "__main__":
    main()
