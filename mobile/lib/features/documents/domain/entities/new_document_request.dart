class NewDocumentRequest {
  const NewDocumentRequest({
    required this.docType,
    this.note,
  });

  final String docType;
  final String? note;
}
