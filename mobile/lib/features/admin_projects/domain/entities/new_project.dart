class NewProject {
  const NewProject({
    required this.name,
    required this.businessUnitId,
    this.leadId,
  });

  final String name;
  final int businessUnitId;
  final int? leadId;
}
