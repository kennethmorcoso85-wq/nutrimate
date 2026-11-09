part of 'admin_workspace_screen.dart';

enum _AdminResource { articles, recommendations, announcements }

class _AdminResourceTab extends StatefulWidget {
  const _AdminResourceTab({required this.api, required this.resource});

  final NutriMateApi api;
  final _AdminResource resource;

  @override
  State<_AdminResourceTab> createState() => _AdminResourceTabState();
}

class _AdminResourceTabState extends State<_AdminResourceTab> {
  late Future<List<Map<String, dynamic>>> _records;

  String get _title => switch (widget.resource) {
    _AdminResource.articles => 'Nutrition content',
    _AdminResource.recommendations => 'Recommendation rules',
    _AdminResource.announcements => 'Announcements',
  };

  String get _endpoint => switch (widget.resource) {
    _AdminResource.articles => 'content',
    _AdminResource.recommendations => 'recommendations',
    _AdminResource.announcements => 'announcements',
  };

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _records = switch (widget.resource) {
      _AdminResource.articles => widget.api.articles(),
      _AdminResource.recommendations => widget.api.recommendations(),
      _AdminResource.announcements => widget.api.announcements(),
    };
  }

  @override
  Widget build(
    BuildContext context,
  ) => FutureBuilder<List<Map<String, dynamic>>>(
    future: _records,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return _AdminLoadError(
          message: snapshot.error.toString(),
          onRetry: () => setState(_reload),
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final records = snapshot.data!;
      return ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 26),
        children: [
          Row(
            children: [
              Expanded(
                child: _AdminPageHeading(
                  title: _title,
                  subtitle: switch (widget.resource) {
                    _AdminResource.articles =>
                      'Publish articles shown to users in Education & guidance',
                    _AdminResource.recommendations =>
                      'Manage advice displayed in the user notifications feed',
                    _AdminResource.announcements =>
                      'Publish announcements in the user notifications feed',
                  },
                ),
              ),
              IconButton(
                tooltip: 'Add $_title',
                onPressed: _editRecord,
                icon: const Icon(Icons.add_circle_outline),
              ),
              IconButton(
                tooltip: 'Refresh $_title',
                onPressed: () => setState(_reload),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 13),
          _AdminSectionTitle('${records.length} records'),
          const SizedBox(height: 8),
          if (records.isEmpty)
            _AdminEmptyState(
              title: 'No ${_title.toLowerCase()} yet',
              message: 'Add a record to make it available to the app.',
            )
          else
            ...records.map(
              (record) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _AdminResourceCard(
                  record: record,
                  resource: widget.resource,
                  onEdit: () => _editRecord(record),
                  onDelete: () => _deleteRecord(record),
                ),
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            height: 46,
            child: OutlinedButton.icon(
              onPressed: _editRecord,
              icon: const Icon(Icons.add),
              label: Text('Add ${_title.toLowerCase()}'),
            ),
          ),
        ],
      );
    },
  );

  Future<void> _editRecord([Map<String, dynamic>? record]) async {
    final values = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) =>
          _AdminResourceEditorDialog(resource: widget.resource, record: record),
    );
    if (values == null) return;
    try {
      await widget.api.saveAdminResource(
        _endpoint,
        values,
        id: record?['id'] as int?,
      );
      if (!mounted) return;
      setState(_reload);
      _message(record == null ? 'Record created.' : 'Record updated.');
    } on ApiException catch (error) {
      if (mounted) _message(error.message);
    }
  }

  Future<void> _deleteRecord(Map<String, dynamic> record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete record?'),
        content: Text('Delete "${record['title']}" permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.api.deleteAdminResource(_endpoint, record['id'] as int);
      if (!mounted) return;
      setState(_reload);
      _message('Record deleted.');
    } on ApiException catch (error) {
      if (mounted) _message(error.message);
    }
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }
}

class _AdminResourceCard extends StatelessWidget {
  const _AdminResourceCard({
    required this.record,
    required this.resource,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> record;
  final _AdminResource resource;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final published = switch (resource) {
      _AdminResource.articles => record['is_published'] == true,
      _AdminResource.recommendations ||
      _AdminResource.announcements => record['is_active'] == true,
    };
    final subtitle = switch (resource) {
      _AdminResource.articles => '${record['category']} · ${record['summary']}',
      _AdminResource.recommendations =>
        '${record['trigger']} · ${record['message']}',
      _AdminResource.announcements =>
        'Publishes ${record['publish_at']} · ${record['body']}',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE6EDF1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record['title'] as String,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF78869A),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  published ? 'Active / published' : 'Draft / inactive',
                  style: TextStyle(
                    color: published ? AppColors.teal : const Color(0xFF78869A),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit record',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete record',
            onPressed: onDelete,
            color: const Color(0xFFB74B4B),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}

class _AdminResourceEditorDialog extends StatefulWidget {
  const _AdminResourceEditorDialog({required this.resource, this.record});

  final _AdminResource resource;
  final Map<String, dynamic>? record;

  @override
  State<_AdminResourceEditorDialog> createState() =>
      _AdminResourceEditorDialogState();
}

class _AdminResourceEditorDialogState
    extends State<_AdminResourceEditorDialog> {
  String? _validationError;
  late final _title = TextEditingController(
    text: widget.record?['title'] as String? ?? '',
  );
  late final _summary = TextEditingController(
    text: widget.record?['summary'] as String? ?? '',
  );
  late final _category = TextEditingController(
    text: widget.record?['category'] as String? ?? 'Nutrition',
  );
  late final _description = TextEditingController(
    text: widget.record?['description'] as String? ?? '',
  );
  late final _message = TextEditingController(
    text: widget.record?['message'] as String? ?? '',
  );
  late final _trigger = TextEditingController(
    text: widget.record?['trigger'] as String? ?? 'manual',
  );
  late final _body = TextEditingController(
    text: widget.record?['body'] as String? ?? '',
  );
  late final _publishAt = TextEditingController(
    text:
        widget.record?['publish_at'] as String? ??
        DateTime.now().toUtc().toIso8601String(),
  );
  late bool _isActive =
      widget.record == null && widget.resource == _AdminResource.announcements
      ? true
      : switch (widget.resource) {
          _AdminResource.articles => widget.record?['is_published'] == true,
          _AdminResource.recommendations ||
          _AdminResource.announcements => widget.record?['is_active'] == true,
        };

  @override
  void dispose() {
    _title.dispose();
    _summary.dispose();
    _category.dispose();
    _description.dispose();
    _message.dispose();
    _trigger.dispose();
    _body.dispose();
    _publishAt.dispose();
    super.dispose();
  }

  Map<String, dynamic>? _values() {
    if (_title.text.trim().isEmpty) return null;
    return switch (widget.resource) {
      _AdminResource.articles
          when _summary.text.trim().isNotEmpty &&
              _category.text.trim().isNotEmpty &&
              _body.text.trim().isNotEmpty =>
        {
          'title': _title.text.trim(),
          'summary': _summary.text.trim(),
          'category': _category.text.trim(),
          'body': _body.text.trim(),
          'is_published': _isActive,
        },
      _AdminResource.recommendations
          when _description.text.trim().isNotEmpty &&
              _message.text.trim().isNotEmpty =>
        {
          'title': _title.text.trim(),
          'description': _description.text.trim(),
          'message': _message.text.trim(),
          'trigger': _trigger.text.trim(),
          'is_active': _isActive,
        },
      _AdminResource.announcements
          when _body.text.trim().isNotEmpty &&
              DateTime.tryParse(_publishAt.text.trim()) != null =>
        {
          'title': _title.text.trim(),
          'body': _body.text.trim(),
          'publish_at': DateTime.parse(_publishAt.text.trim())
              .toUtc()
              .toIso8601String(),
          'is_active': _isActive,
        },
      _ => null,
    };
  }

  String _validationMessage() {
    if (_title.text.trim().isEmpty) return 'Enter a title.';
    return switch (widget.resource) {
      _AdminResource.articles =>
        _summary.text.trim().isEmpty
            ? 'Enter a summary.'
            : _category.text.trim().isEmpty
            ? 'Enter a category.'
            : _body.text.trim().isEmpty
            ? 'Enter the article body.'
            : 'Check the article details.',
      _AdminResource.recommendations =>
        _description.text.trim().isEmpty
            ? 'Enter a description.'
            : _message.text.trim().isEmpty
            ? 'Enter a message for users.'
            : 'Check the recommendation details.',
      _AdminResource.announcements =>
        _body.text.trim().isEmpty
            ? 'Enter an announcement message.'
            : DateTime.tryParse(_publishAt.text.trim()) == null
            ? 'Enter a valid ISO 8601 publish date and time.'
            : 'Check the announcement details.',
    };
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      '${widget.record == null ? 'Add' : 'Edit'} ${switch (widget.resource) {
        _AdminResource.articles => 'article',
        _AdminResource.recommendations => 'recommendation rule',
        _AdminResource.announcements => 'announcement',
      }}',
    ),
    content: SizedBox(
      width: 460,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(_title, 'Title'),
            if (widget.resource == _AdminResource.articles) ...[
              _field(_summary, 'Summary'),
              _field(_category, 'Category'),
              _field(_body, 'Article body', maxLines: 5),
            ],
            if (widget.resource == _AdminResource.recommendations) ...[
              _field(_description, 'Description', maxLines: 3),
              _field(_message, 'Message for users', maxLines: 3),
              _field(_trigger, 'Trigger label'),
            ],
            if (widget.resource == _AdminResource.announcements) ...[
              _field(_body, 'Announcement message', maxLines: 4),
              _field(
                _publishAt,
                'Publish date and time (ISO 8601)',
                hint: '2026-11-09T12:00:00+08:00',
              ),
            ],
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                widget.resource == _AdminResource.articles
                    ? 'Published'
                    : 'Active',
              ),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),
            if (_validationError != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _validationError!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          final values = _values();
          if (values == null) {
            setState(() => _validationError = _validationMessage());
            return;
          }
          Navigator.pop(context, values);
        },
        child: const Text('Save'),
      ),
    ],
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    String? hint,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label, hintText: hint),
    ),
  );
}

class _AdminAuditTab extends StatefulWidget {
  const _AdminAuditTab({required this.api});

  final NutriMateApi api;

  @override
  State<_AdminAuditTab> createState() => _AdminAuditTabState();
}

class _AdminAuditTabState extends State<_AdminAuditTab> {
  late Future<List<Map<String, dynamic>>> _events;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _events = widget.api.adminAuditEvents();
  }

  @override
  Widget build(
    BuildContext context,
  ) => FutureBuilder<List<Map<String, dynamic>>>(
    future: _events,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return _AdminLoadError(
          message: snapshot.error.toString(),
          onRetry: () => setState(_reload),
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final events = snapshot.data!;
      return ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 26),
        children: [
          Row(
            children: [
              const Expanded(
                child: _AdminPageHeading(
                  title: 'Audit logs',
                  subtitle: 'Administrative changes recorded by the API',
                ),
              ),
              IconButton(
                tooltip: 'Refresh audit logs',
                onPressed: () => setState(_reload),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _AdminSectionTitle('${events.length} recent events'),
          const SizedBox(height: 8),
          if (events.isEmpty)
            const _AdminEmptyState(
              title: 'No audit events',
              message: 'Admin changes will appear here.',
            )
          else
            ...events.map(
              (event) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: const Color(0xFFE6EDF1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (event['action'] as String).replaceAll('.', ' '),
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${event['target']} · ${event['actor_name'] ?? 'Deleted account'}',
                      style: const TextStyle(
                        color: Color(0xFF53647A),
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event['created_at'] as String,
                      style: const TextStyle(
                        color: Color(0xFF8290A2),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );
}
