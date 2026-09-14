class ChatAttachment {
  const ChatAttachment({
    required this.filename,
    required this.contentType,
    required this.byteSize,
    required this.url,
  });

  final String filename;
  final String contentType;
  final int byteSize;
  final String url;
}
