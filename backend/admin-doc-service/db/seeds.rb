# Demo data for the admin-doc-service. Run with: bin/rails db:seed
# Ids mirror auth-service seed order: admin=1, manager=2, Emma Employee=3.
EMMA = 3

[
  { doc_type: "work_certificate",  status: "pending",    note: "Pour une demande de prêt bancaire" },
  { doc_type: "salary_certificate", status: "ready",      note: "Bulletin de juin 2026",
    fields: {
      "employee_name" => "Emma Employee",
      "job_title" => "Employée",
      "period" => "juin 2026",
      "net_salary" => "2 450 €",
      "company" => "Alizé",
      "issued_date" => "2026-07-01",
      "signer" => "Service RH",
    } },
  { doc_type: "leave_attestation", status: "processing", note: "Attestation de congés d'été" },
].each do |d|
  dr = DocumentRequest.find_or_create_by!(user_id: EMMA, doc_type: d[:doc_type], note: d[:note]) do |row|
    row.status = d[:status]
    row.fields = d[:fields] || {}
  end
  dr.update!(status: d[:status], fields: d[:fields] || dr.fields)
end

puts "Seeded #{DocumentRequest.count} document request(s)."
