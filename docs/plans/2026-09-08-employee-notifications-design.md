# In-app + logged email notifications

Employees are notified when:

- a document is marked ready by RH
- a manager accepts their leave (still waiting for RH)
- RH confirms their leave

The inbox lives in auth-service. Leave-service and admin-doc-service POST internally. The top-bar bell lists alerts; emails are written to the Rails log / `tmp/mails` in development (no SMTP).
