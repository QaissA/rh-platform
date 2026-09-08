# Two-step leave validation

Leave requests need manager approval first, then HR. The leave is confirmed only after HR accepts.

## Statuses

| Status | Meaning |
|--------|---------|
| `pending` | Waiting for the team manager |
| `pending_hr` | Manager accepted; waiting for HR |
| `approved` | HR accepted; leave is confirmed, balance debited, days count as holiday |
| `rejected` | Manager or HR refused; request is closed |

## Rules

- Manager (of the request’s team) or admin may accept/refuse a `pending` request.
- Manager accept moves the request to `pending_hr`. Balance is **not** debited.
- RH or admin may accept/refuse a `pending_hr` request.
- HR accept moves it to `approved` and debits the balance.
- Manager cannot skip HR. HR cannot skip the manager.
- Employee sees both `pending` and `pending_hr` as still waiting (not confirmed).
