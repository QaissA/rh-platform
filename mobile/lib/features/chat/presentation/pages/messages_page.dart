import 'dart:typed_data';

import 'package:alize_mobile/core/l10n/i18n_provider.dart';
import 'package:alize_mobile/core/theme/alize_colors.dart';
import 'package:alize_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:alize_mobile/features/chat/domain/entities/chat_attachment.dart';
import 'package:alize_mobile/features/chat/domain/entities/chat_message.dart';
import 'package:alize_mobile/features/chat/domain/entities/chat_upload.dart';
import 'package:alize_mobile/features/chat/domain/entities/conversation.dart';
import 'package:alize_mobile/features/chat/presentation/providers/chat_providers.dart';
import 'package:alize_mobile/features/team/domain/entities/team_member.dart';
import 'package:alize_mobile/features/team/domain/person_format.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

const _avatarColors = [
  Color(0xFF460CAD),
  Color(0xFF6D28D9),
  Color(0xFF7C3AED),
  Color(0xFF9333EA),
  Color(0xFF5B21B6),
  Color(0xFF7E22CE),
  Color(0xFF4338CA),
];

const _maxBytes = 5 * 1024 * 1024;

AlizePalette _paletteOf(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? AlizeColors.dark
      : AlizeColors.light;
}

class MessagesPage extends ConsumerWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.watch(i18nProvider);
    return Directionality(
      textDirection:
          i18n.dir == 'rtl' ? TextDirection.rtl : TextDirection.ltr,
      child: const _MessagesView(),
    );
  }
}

class _MessagesView extends ConsumerStatefulWidget {
  const _MessagesView();

  @override
  ConsumerState<_MessagesView> createState() => _MessagesViewState();
}

class _MessagesViewState extends ConsumerState<_MessagesView> {
  final _listQuery = TextEditingController();
  final _peopleQuery = TextEditingController();
  final _threadQuery = TextEditingController();
  final _composer = TextEditingController();
  ChatUpload? _pendingFile;

  @override
  void dispose() {
    _listQuery.dispose();
    _peopleQuery.dispose();
    _threadQuery.dispose();
    _composer.dispose();
    super.dispose();
  }

  int? get _meId {
    final auth = ref.read(authProvider);
    if (auth is AuthSignedIn) return auth.session.user.id;
    return null;
  }

  Future<void> _toast(String message) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickFile() async {
    final i18n = ref.read(i18nProvider);
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg', 'webp'],
      withData: true,
    );
    final file = result?.files.single;
    if (file == null) return;
    final bytes = file.bytes;
    if (bytes == null) {
      await _toast(i18n.t('chat.sendFail'));
      return;
    }
    if (bytes.length > _maxBytes) {
      await _toast(i18n.t('chat.tooBig'));
      return;
    }
    final mime = _mimeFor(file.extension, file.name);
    if (mime == null) {
      await _toast(i18n.t('chat.badType'));
      return;
    }
    setState(() {
      _pendingFile = ChatUpload(
        filename: file.name,
        contentType: mime,
        bytes: bytes,
      );
    });
  }

  Future<void> _send() async {
    final i18n = ref.read(i18nProvider);
    final body = _composer.text.trim();
    final file = _pendingFile;
    if (body.isEmpty && file == null) return;
    final result = await ref.read(chatControllerProvider.notifier).send(
          body: body,
          file: file,
        );
    if (!mounted) return;
    if (result.isOk) {
      _composer.clear();
      setState(() => _pendingFile = null);
    } else {
      await _toast(i18n.t('chat.sendFail'));
    }
  }

  Future<void> _openWith(int userId) async {
    final i18n = ref.read(i18nProvider);
    final result =
        await ref.read(chatControllerProvider.notifier).openWith(userId);
    if (!result.isOk) {
      await _toast(i18n.t('chat.openFail'));
    }
  }

  Future<void> _startPick() async {
    _peopleQuery.clear();
    final result = await ref.read(chatControllerProvider.notifier).startPick();
    if (!result.isOk) {
      await _toast(ref.read(i18nProvider).t('chat.directoryFail'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.watch(i18nProvider);
    final colors = _paletteOf(context);
    final state = ref.watch(chatControllerProvider);
    final controller = ref.read(chatControllerProvider.notifier);

    return Scaffold(
      backgroundColor: colors.paper,
      body: state.picking
          ? _DirectoryPane(
              colors: colors,
              i18n: i18n,
              query: _peopleQuery,
              people: _filterPeople(state.directory, _peopleQuery.text),
              onCancel: controller.cancelPick,
              onOpen: _openWith,
              onQuery: () => setState(() {}),
            )
          : state.active != null
              ? _ThreadPane(
                  colors: colors,
                  i18n: i18n,
                  conversation: state.active!,
                  messages: _filterThread(state.messages, _threadQuery.text),
                  imageBytes: state.imageBytes,
                  meId: _meId,
                  sending: state.sending,
                  threadError: state.threadError,
                  composer: _composer,
                  threadQuery: _threadQuery,
                  pendingFile: _pendingFile,
                  onBack: () {
                    _composer.clear();
                    _threadQuery.clear();
                    setState(() => _pendingFile = null);
                    controller.closeThread();
                  },
                  onQuery: () => setState(() {}),
                  onAttach: _pickFile,
                  onClearFile: () => setState(() => _pendingFile = null),
                  onSend: _send,
                )
              : _ConversationListPane(
                  colors: colors,
                  i18n: i18n,
                  query: _listQuery,
                  conversations: _filterConversations(
                    state.conversations,
                    _listQuery.text,
                  ),
                  hasQuery: _listQuery.text.trim().isNotEmpty,
                  onQuery: () => setState(() {}),
                  onNew: _startPick,
                  onOpen: controller.select,
                ),
    );
  }
}

List<Conversation> _filterConversations(
  List<Conversation> list,
  String raw,
) {
  final q = raw.trim().toLowerCase();
  if (q.isEmpty) return list;
  return list.where((c) {
    final name = fullName(c.other).toLowerCase();
    final snip = (c.lastMessage?.body ??
            c.lastMessage?.attachment?.filename ??
            '')
        .toLowerCase();
    return name.contains(q) || snip.contains(q);
  }).toList();
}

List<TeamMember> _filterPeople(List<TeamMember> list, String raw) {
  final q = raw.trim().toLowerCase();
  if (q.isEmpty) return list;
  return list
      .where(
        (p) =>
            fullName(p).toLowerCase().contains(q) ||
            p.email.toLowerCase().contains(q),
      )
      .toList();
}

List<ChatMessage> _filterThread(List<ChatMessage> list, String raw) {
  final q = raw.trim().toLowerCase();
  if (q.isEmpty) return list;
  return list.where((m) {
    final body = (m.body ?? '').toLowerCase();
    final file = (m.attachment?.filename ?? '').toLowerCase();
    return body.contains(q) || file.contains(q);
  }).toList();
}

String? _mimeFor(String? extension, String filename) {
  final ext = (extension ?? filename.split('.').last).toLowerCase();
  return switch (ext) {
    'pdf' => 'application/pdf',
    'png' => 'image/png',
    'jpg' || 'jpeg' => 'image/jpeg',
    'webp' => 'image/webp',
    _ => null,
  };
}

class _ConversationListPane extends StatelessWidget {
  const _ConversationListPane({
    required this.colors,
    required this.i18n,
    required this.query,
    required this.conversations,
    required this.hasQuery,
    required this.onQuery,
    required this.onNew,
    required this.onOpen,
  });

  final AlizePalette colors;
  final I18nController i18n;
  final TextEditingController query;
  final List<Conversation> conversations;
  final bool hasQuery;
  final VoidCallback onQuery;
  final VoidCallback onNew;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  i18n.t('chat.conversations'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.ink,
                  ),
                ),
              ),
              TextButton(onPressed: onNew, child: Text(i18n.t('chat.new'))),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: query,
            onChanged: (_) => onQuery(),
            decoration: _searchDecoration(
              colors,
              i18n.t('chat.searchThread'),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: conversations.isEmpty
              ? _EmptyHint(
                  colors: colors,
                  text: hasQuery
                      ? i18n.t('chat.noResults')
                      : i18n.t('chat.noConversations'),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: conversations.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final conv = conversations[index];
                    return _PersonRow(
                      colors: colors,
                      member: conv.other,
                      subtitle: _snippet(conv, i18n),
                      badge: conv.unreadCount,
                      onTap: () => onOpen(conv.id),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _DirectoryPane extends StatelessWidget {
  const _DirectoryPane({
    required this.colors,
    required this.i18n,
    required this.query,
    required this.people,
    required this.onCancel,
    required this.onOpen,
    required this.onQuery,
  });

  final AlizePalette colors;
  final I18nController i18n;
  final TextEditingController query;
  final List<TeamMember> people;
  final VoidCallback onCancel;
  final ValueChanged<int> onOpen;
  final VoidCallback onQuery;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  i18n.t('chat.new'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.ink,
                  ),
                ),
              ),
              TextButton(
                onPressed: onCancel,
                child: Text(i18n.t('common.cancel')),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: query,
            onChanged: (_) => onQuery(),
            decoration: _searchDecoration(
              colors,
              i18n.t('chat.searchPerson'),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: people.isEmpty
              ? _EmptyHint(colors: colors, text: i18n.t('chat.noPeople'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: people.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final person = people[index];
                    return _PersonRow(
                      colors: colors,
                      member: person,
                      subtitle: i18n.t('status.role.${person.role}'),
                      onTap: () => onOpen(person.id),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ThreadPane extends StatelessWidget {
  const _ThreadPane({
    required this.colors,
    required this.i18n,
    required this.conversation,
    required this.messages,
    required this.imageBytes,
    required this.meId,
    required this.sending,
    required this.threadError,
    required this.composer,
    required this.threadQuery,
    required this.pendingFile,
    required this.onBack,
    required this.onQuery,
    required this.onAttach,
    required this.onClearFile,
    required this.onSend,
  });

  final AlizePalette colors;
  final I18nController i18n;
  final Conversation conversation;
  final List<ChatMessage> messages;
  final Map<int, Uint8List> imageBytes;
  final int? meId;
  final bool sending;
  final bool threadError;
  final TextEditingController composer;
  final TextEditingController threadQuery;
  final ChatUpload? pendingFile;
  final VoidCallback onBack;
  final VoidCallback onQuery;
  final VoidCallback onAttach;
  final VoidCallback onClearFile;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final canSend =
        (composer.text.trim().isNotEmpty || pendingFile != null) && !sending;
    return Column(
      children: [
        Material(
          color: colors.surface,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 16, 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back),
                ),
                _Avatar(member: conversation.other),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName(conversation.other),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: colors.ink,
                        ),
                      ),
                      Text(
                        i18n.t('status.role.${conversation.other.role}'),
                        style: TextStyle(fontSize: 12, color: colors.ink2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: threadQuery,
            onChanged: (_) => onQuery(),
            decoration: _searchDecoration(
              colors,
              i18n.t('chat.searchInThread'),
            ),
          ),
        ),
        Expanded(
          child: messages.isEmpty
              ? _EmptyHint(
                  colors: colors,
                  text: threadQuery.text.trim().isNotEmpty
                      ? i18n.t('chat.noMatch')
                      : threadError
                          ? i18n.t('chat.openFail')
                          : i18n.t('chat.firstMessage'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final showDay = index == 0 ||
                        _dayKey(messages[index - 1].createdAt) !=
                            _dayKey(msg.createdAt);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showDay)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Center(
                              child: Text(
                                _dayLabel(msg.createdAt, i18n),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.ink3,
                                ),
                              ),
                            ),
                          ),
                        _Bubble(
                          colors: colors,
                          i18n: i18n,
                          message: msg,
                          mine: msg.senderId == meId,
                          preview: imageBytes[msg.id],
                        ),
                      ],
                    );
                  },
                ),
        ),
        if (pendingFile != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.brandTint,
                borderRadius: BorderRadius.circular(AlizeColors.radiusSm),
              ),
              child: ListTile(
                dense: true,
                title: Text(
                  '${pendingFile!.filename} · ${_fileSize(pendingFile!.bytes.length)}',
                  style: TextStyle(color: colors.ink, fontSize: 13),
                ),
                trailing: IconButton(
                  tooltip: i18n.t('chat.removeFile'),
                  onPressed: onClearFile,
                  icon: const Icon(Icons.close),
                ),
              ),
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(top: BorderSide(color: colors.line)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: i18n.t('chat.attach'),
                  onPressed: onAttach,
                  icon: const Icon(Icons.attach_file),
                ),
                Expanded(
                  child: TextField(
                    controller: composer,
                    minLines: 1,
                    maxLines: 4,
                    onChanged: (_) => onQuery(),
                    onSubmitted: (_) {
                      if (canSend) onSend();
                    },
                    decoration: InputDecoration(
                      hintText: i18n.t('chat.placeholder'),
                      filled: true,
                      fillColor: colors.surface2,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AlizeColors.radiusSm),
                        borderSide: BorderSide(color: colors.line),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AlizeColors.radiusSm),
                        borderSide: BorderSide(color: colors.line),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                FilledButton(
                  onPressed: canSend ? onSend : null,
                  child: Text(i18n.t('common.send')),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.colors,
    required this.i18n,
    required this.message,
    required this.mine,
    required this.preview,
  });

  final AlizePalette colors;
  final I18nController i18n;
  final ChatMessage message;
  final bool mine;
  final Uint8List? preview;

  @override
  Widget build(BuildContext context) {
    final attachment = message.attachment;
    final align = mine ? Alignment.centerRight : Alignment.centerLeft;
    return Align(
      alignment: align,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: mine ? colors.brandTint : colors.surface,
            borderRadius: BorderRadius.circular(AlizeColors.radius),
            border: Border.all(color: mine ? colors.brandTint2 : colors.line),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (attachment != null)
                  _AttachmentBlock(
                    colors: colors,
                    attachment: attachment,
                    preview: preview,
                  ),
                if (message.body != null && message.body!.trim().isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: attachment == null ? 0 : 6),
                    child: Text(
                      message.body!,
                      style: TextStyle(color: colors.ink, height: 1.35),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  _when(message.createdAt, i18n),
                  style: TextStyle(fontSize: 11, color: colors.ink3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AttachmentBlock extends StatelessWidget {
  const _AttachmentBlock({
    required this.colors,
    required this.attachment,
    required this.preview,
  });

  final AlizePalette colors;
  final ChatAttachment attachment;
  final Uint8List? preview;

  @override
  Widget build(BuildContext context) {
    final bytes = preview;
    if (attachment.contentType.startsWith('image/') && bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image(
          image: MemoryImage(bytes),
          fit: BoxFit.cover,
        ),
      );
    }
    return Row(
      children: [
        Icon(Icons.insert_drive_file_outlined, color: colors.brand, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                attachment.filename,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colors.ink,
                ),
              ),
              Text(
                _fileSize(attachment.byteSize),
                style: TextStyle(fontSize: 11, color: colors.ink3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({
    required this.colors,
    required this.member,
    required this.subtitle,
    required this.onTap,
    this.badge = 0,
  });

  final AlizePalette colors;
  final TeamMember member;
  final String subtitle;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final job = jobTitleOf(member);
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AlizeColors.radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AlizeColors.radius),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              _Avatar(member: member),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              text: fullName(member),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: colors.ink,
                              ),
                              children: [
                                if (job != null)
                                  TextSpan(
                                    text: '  $job',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 12,
                                      color: colors.ink3,
                                    ),
                                  ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (badge > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.brand,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '$badge',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: colors.ink2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.member});

  final TeamMember member;

  @override
  Widget build(BuildContext context) {
    final color = _avatarColors[avatarIndex(member.id)];
    return CircleAvatar(
      radius: 18,
      backgroundColor: color,
      child: Text(
        initialsOf(member),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.colors, required this.text});

  final AlizePalette colors;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.ink2),
        ),
      ),
    );
  }
}

InputDecoration _searchDecoration(AlizePalette colors, String hint) {
  return InputDecoration(
    hintText: hint,
    prefixIcon: const Icon(Icons.search, size: 20),
    filled: true,
    fillColor: colors.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AlizeColors.radiusSm),
      borderSide: BorderSide(color: colors.line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AlizeColors.radiusSm),
      borderSide: BorderSide(color: colors.line),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  );
}

String _snippet(Conversation conversation, I18nController i18n) {
  final last = conversation.lastMessage;
  if (last == null) return i18n.t('chat.noMessage');
  final body = last.body?.trim();
  if (body != null && body.isNotEmpty) return body;
  if (last.attachment != null) return i18n.t('chat.attachment');
  return i18n.t('chat.noMessage');
}

String _fileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

DateTime? _parseTime(String iso) => DateTime.tryParse(iso);

String _dayKey(String iso) {
  final date = _parseTime(iso)?.toLocal();
  if (date == null) return iso;
  return '${date.year}-${date.month}-${date.day}';
}

String _dayLabel(String iso, I18nController i18n) {
  final date = _parseTime(iso)?.toLocal();
  if (date == null) return iso;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  if (day == today) return i18n.t('chat.today');
  if (day == today.subtract(const Duration(days: 1))) {
    return i18n.t('chat.yesterday');
  }
  return DateFormat.yMMMEd(i18n.locale).format(date);
}

String _when(String iso, I18nController i18n) {
  final date = _parseTime(iso)?.toLocal();
  if (date == null) return iso;
  return DateFormat.Hm(i18n.locale).format(date);
}
