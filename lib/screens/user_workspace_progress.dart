part of 'user_workspace_screen.dart';

class _ProgressTab extends StatefulWidget {
  const _ProgressTab({
    required this.api,
    required this.meals,
    required this.allMeals,
    required this.waterMl,
    required this.goals,
    required this.selectedDate,
    required this.waterEntries,
    required this.onSelectDate,
    required this.onAddWater,
    required this.onEditWater,
    required this.onDeleteWater,
  });

  final NutriMateApi api;
  final List<MealRecord> meals;
  final List<MealRecord> allMeals;
  final int waterMl;
  final NutritionGoals goals;
  final DateTime selectedDate;
  final List<_WaterLogEntry> waterEntries;
  final VoidCallback onSelectDate;
  final ValueChanged<int> onAddWater;
  final void Function(_WaterLogEntry, int) onEditWater;
  final ValueChanged<_WaterLogEntry> onDeleteWater;

  @override
  State<_ProgressTab> createState() => _ProgressTabState();
}

class _ProgressTabState extends State<_ProgressTab> {
  String _period = 'Daily';
  DateTimeRange? _range;
  late Future<List<Map<String, dynamic>>> _measurements;

  @override
  void initState() {
    super.initState();
    _reloadMeasurements();
  }

  void _reloadMeasurements() {
    _measurements = widget.api.measurements();
  }

  List<MealRecord> get _periodMeals {
    bool isInSelectedPeriod(MealRecord meal) {
      final date = DateUtils.dateOnly(meal.createdAt);
      if (_range != null) {
        return !date.isBefore(DateUtils.dateOnly(_range!.start)) &&
            !date.isAfter(DateUtils.dateOnly(_range!.end));
      }
      if (_period == 'Daily') {
        return DateUtils.isSameDay(date, widget.selectedDate);
      }
      if (_period == 'Weekly') {
        final start = DateUtils.dateOnly(widget.selectedDate)
            .subtract(Duration(days: widget.selectedDate.weekday - 1));
        final end = start.add(const Duration(days: 7));
        return !date.isBefore(start) && date.isBefore(end);
      }
      return date.year == widget.selectedDate.year &&
          date.month == widget.selectedDate.month;
    }

    return widget.allMeals.where(isInSelectedPeriod).toList();
  }

  List<_TrendPoint> _trendPoints() {
    final meals = _periodMeals;
    if (_range == null && _period == 'Daily') {
      const categories = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
      return categories
          .map(
            (category) => _TrendPoint(
              category.substring(0, 1),
              meals
                  .where((meal) => meal.category == category)
                  .fold<int>(0, (sum, meal) => sum + meal.calories),
            ),
          )
          .toList();
    }
    if (_range == null && _period == 'Weekly') {
      final start = DateUtils.dateOnly(widget.selectedDate)
          .subtract(Duration(days: widget.selectedDate.weekday - 1));
      const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
      return List<_TrendPoint>.generate(7, (index) {
        final date = start.add(Duration(days: index));
        return _TrendPoint(
          labels[index],
          meals
              .where((meal) => DateUtils.isSameDay(meal.createdAt, date))
              .fold<int>(0, (sum, meal) => sum + meal.calories),
        );
      });
    }
    final start =
        _range?.start ??
        DateTime(widget.selectedDate.year, widget.selectedDate.month);
    final end =
        _range?.end ??
        DateTime(widget.selectedDate.year, widget.selectedDate.month + 1, 0);
    final dayCount = end.difference(start).inDays + 1;
    final bucketSize = (dayCount / 7).ceil().clamp(1, 31);
    final points = <_TrendPoint>[];
    for (var index = 0; index < dayCount; index += bucketSize) {
      final bucketStart = DateUtils.dateOnly(start.add(Duration(days: index)));
      final bucketEnd = bucketStart.add(Duration(days: bucketSize));
      final bucketMeals = meals.where((meal) {
        final date = DateUtils.dateOnly(meal.createdAt);
        return !date.isBefore(bucketStart) && date.isBefore(bucketEnd);
      });
      points.add(
        _TrendPoint(
          '${bucketStart.month}/${bucketStart.day}',
          bucketMeals.fold<int>(0, (sum, meal) => sum + meal.calories),
        ),
      );
    }
    return points;
  }

  Future<void> _selectRange() async {
    final now = DateUtils.dateOnly(DateTime.now());
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now,
      initialDateRange: _range,
    );
    if (selected != null) setState(() => _range = selected);
  }

  Future<void> _editWater(_WaterLogEntry entry) async {
    final controller = TextEditingController(text: entry.amount.toString());
    final amount = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit water entry'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Amount in ml'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null && value > 0) Navigator.pop(context, value);
            },
            child: const Text('Save changes'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (amount != null) widget.onEditWater(entry, amount);
  }

  Future<void> _exportReport() async {
    final format = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart_outlined),
              title: const Text('Copy CSV report'),
              onTap: () => Navigator.pop(context, 'CSV'),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('Share PDF report'),
              onTap: () => Navigator.pop(context, 'PDF'),
            ),
          ],
        ),
      ),
    );
    if (format == null || !mounted) return;
    if (format == 'PDF') {
      final document = pw.Document();
      document.addPage(
        pw.MultiPage(
          build: (context) => [
            pw.Text(
              'NutriMate nutrition report',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Period: $_period'),
            pw.Text('Selected date: ${widget.selectedDate.toIso8601String()}'),
            pw.SizedBox(height: 14),
            pw.Text('Meal entries', style: pw.TextStyle(fontSize: 16)),
            pw.SizedBox(height: 6),
            ..._periodMeals.map(
              (meal) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Text(
                  '${meal.category}: ${meal.name} · ${meal.calories} kcal · P ${meal.protein} g · C ${meal.carbs} g · F ${meal.fat} g',
                ),
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              'Total: ${_periodMeals.fold<int>(0, (sum, meal) => sum + meal.calories)} kcal',
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Nutrition figures are estimates from your server-saved entries; they are not medical advice.',
              style: pw.TextStyle(fontSize: 9),
            ),
          ],
        ),
      );
      await Printing.sharePdf(
        bytes: await document.save(),
        filename: 'nutrimate-report.pdf',
      );
      return;
    }
    String csvCell(Object value) =>
        '"${value.toString().replaceAll('"', '""')}"';
    final csv = [
      'date,meal,category,calories,protein_g,carbs_g,fat_g',
      ..._periodMeals.map(
        (meal) => [
          meal.createdAt.toIso8601String(),
          meal.name,
          meal.category,
          meal.calories,
          meal.protein,
          meal.carbs,
          meal.fat,
        ].map(csvCell).join(','),
      ),
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: csv));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CSV report copied to clipboard.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final periodMeals = _periodMeals;
    final calories = periodMeals.fold<int>(
      0,
      (sum, meal) => sum + meal.calories,
    );
    final protein = periodMeals.fold<int>(0, (sum, meal) => sum + meal.protein);
    final carbs = periodMeals.fold<int>(0, (sum, meal) => sum + meal.carbs);
    final fat = periodMeals.fold<int>(0, (sum, meal) => sum + meal.fat);
    final recentEntries = widget.waterEntries.take(10).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 26),
      children: [
        Row(
          children: [
            const Expanded(
              child: _PageHeading(
                title: 'Progress & insights',
                subtitle:
                    'Review nutrition records and trends saved by the API',
              ),
            ),
            IconButton(
              tooltip: 'View chart details',
              onPressed: () => showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Selected period details'),
                  content: Text(
                    'Period: $_period\nCalories: $calories / ${widget.goals.calories} kcal\nRemaining: ${(widget.goals.calories - calories).clamp(0, widget.goals.calories)} kcal\nProtein: $protein / ${widget.goals.protein} g\nCarbohydrates: $carbs / ${widget.goals.carbs} g\nFat: $fat / ${widget.goals.fat} g\nWater total: ${widget.waterMl} ml',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
              icon: const Icon(Icons.info_outline),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Daily', label: Text('Daily')),
                ButtonSegment(value: 'Weekly', label: Text('Weekly')),
                ButtonSegment(value: 'Monthly', label: Text('Monthly')),
              ],
              selected: {_period},
              onSelectionChanged: (selection) =>
                  setState(() => _period = selection.first),
            ),
            OutlinedButton.icon(
              onPressed: _selectRange,
              icon: const Icon(Icons.date_range, size: 17),
              label: Text(
                _range == null
                    ? 'Date range'
                    : '${_range!.start.month}/${_range!.start.day}–${_range!.end.month}/${_range!.end.day}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Align(
          alignment: Alignment.centerLeft,
          child: _TodayPill(
            date: widget.selectedDate,
            onTap: widget.onSelectDate,
          ),
        ),
        const SizedBox(height: 16),
        _ProgressHero(
          calories: calories,
          mealCount: periodMeals.length,
          calorieGoal: widget.goals.calories,
        ),
        const SizedBox(height: 12),
        _ProgressTrendChart(
          title: '$_period calorie history',
          points: _trendPoints(),
        ),
        const SizedBox(height: 12),
        _MacroSummaryCard(
          protein: protein,
          carbs: carbs,
          fat: fat,
          goals: widget.goals,
        ),
        const SizedBox(height: 12),
        _SimpleInfoCard(
          icon: Icons.water_drop_outlined,
          title: 'Water today',
          value: '${widget.waterMl} ml',
          color: AppColors.blue,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => widget.onAddWater(250),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add water'),
            ),
            OutlinedButton.icon(
              onPressed: _exportReport,
              icon: const Icon(Icons.file_download_outlined, size: 16),
              label: const Text('Reports & export'),
            ),
            OutlinedButton.icon(
              onPressed: _showMeasurements,
              icon: const Icon(Icons.monitor_weight_outlined, size: 16),
              label: const Text('Measurements'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [const Expanded(child: _SectionHeading('Water history'))],
        ),
        if (recentEntries.isEmpty)
          _WhiteCard(
            child: Text(
              widget.waterMl == 0
                  ? 'No water entries recorded yet.'
                  : 'Saved total: ${widget.waterMl} ml. Previous item-level records were not stored.',
              style: const TextStyle(color: Color(0xFF78869A), fontSize: 11),
            ),
          )
        else
          ...recentEntries.map(
            (entry) => ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 6),
              leading: const Icon(
                Icons.water_drop_outlined,
                color: AppColors.blue,
              ),
              title: Text('${entry.amount} ml'),
              subtitle: Text(_formatTime(entry.recordedAt)),
              trailing: PopupMenuButton<String>(
                onSelected: (action) {
                  if (action == 'edit') _editWater(entry);
                  if (action == 'delete') widget.onDeleteWater(entry);
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit entry')),
                  PopupMenuItem(value: 'delete', child: Text('Delete entry')),
                ],
              ),
            ),
          ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Expanded(child: _SectionHeading('Body measurements')),
            TextButton.icon(
              onPressed: _addMeasurement,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add measurement'),
            ),
          ],
        ),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _measurements,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _WhiteCard(
                child: Text(
                  snapshot.error.toString(),
                  style: const TextStyle(
                    color: Color(0xFFB74B4B),
                    fontSize: 11,
                  ),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(14),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.data!.isEmpty) {
              return const _WhiteCard(
                child: Text(
                  'No body measurements recorded.',
                  style: TextStyle(color: Color(0xFF78869A), fontSize: 11),
                ),
              );
            }
            return Column(
              children: snapshot.data!
                  .take(3)
                  .map(
                    (record) => ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                      leading: const Icon(
                        Icons.monitor_weight_outlined,
                        color: AppColors.teal,
                      ),
                      title: Text('${record['weight_kg']} kg'),
                      subtitle: Text(
                        '${record['height_cm'] ?? 'Height not recorded'} cm · ${record['measured_at']}',
                      ),
                      onTap: () => _addMeasurement(record),
                    ),
                  )
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 12),
        const _DemoNotice(
          text: 'Meal logs, water entries, and body measurements are saved by the NutriMate API. Nutrition figures are estimates, not medical advice.',
        ),
      ],
    );
  }

  Future<void> _showMeasurements() async {
    try {
      final records = await widget.api.measurements();
      if (!mounted) return;
      final result = await showDialog<Map<String, dynamic>?>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Measurements'),
          content: SizedBox(
            width: 420,
            child: records.isEmpty
                ? const Text('No measurements recorded yet.')
                : ListView(
                    shrinkWrap: true,
                    children: records
                        .map(
                          (record) => ListTile(
                            title: Text('${record['weight_kg']} kg'),
                            subtitle: Text(
                              '${record['height_cm'] ?? 'Height not recorded'} cm · ${record['measured_at']}',
                            ),
                            onTap: () => Navigator.pop(dialogContext, record),
                            trailing: IconButton(
                              tooltip: 'Delete measurement',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => Navigator.pop(dialogContext, {
                                'delete_id': record['id'],
                              }),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      if (result == null) return;
      final deleteId = result['delete_id'];
      if (deleteId is int) {
        await widget.api.deleteMeasurement(deleteId);
        if (mounted) {
          setState(_reloadMeasurements);
          _showMessage('Measurement deleted.');
        }
      } else {
        await _addMeasurement(result);
      }
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    }
  }

  Future<void> _addMeasurement([Map<String, dynamic>? existing]) async {
    final values = await showDialog<(double, double?)>(
      context: context,
      builder: (_) => _MeasurementDialog(measurement: existing),
    );
    if (values == null) return;
    try {
      if (existing == null) {
        await widget.api.createMeasurement(
          weightKg: values.$1,
          heightCm: values.$2,
        );
        if (mounted) {
          setState(_reloadMeasurements);
          _showMessage('Measurement saved to your account.');
        }
      } else {
        await widget.api.updateMeasurement(
          existing['id'] as int,
          weightKg: values.$1,
          heightCm: values.$2,
        );
        if (mounted) {
          setState(_reloadMeasurements);
          _showMessage('Measurement updated.');
        }
      }
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _MeasurementDialog extends StatefulWidget {
  const _MeasurementDialog({this.measurement});

  final Map<String, dynamic>? measurement;

  @override
  State<_MeasurementDialog> createState() => _MeasurementDialogState();
}

class _MeasurementDialogState extends State<_MeasurementDialog> {
  late final _weight = TextEditingController(
    text: '${widget.measurement?['weight_kg'] ?? ''}',
  );
  late final _height = TextEditingController(
    text: '${widget.measurement?['height_cm'] ?? ''}',
  );
  String? _error;

  @override
  void dispose() {
    _weight.dispose();
    _height.dispose();
    super.dispose();
  }

  void _save() {
    final weight = double.tryParse(_weight.text.trim());
    final heightText = _height.text.trim();
    final height = heightText.isEmpty ? null : double.tryParse(heightText);
    if (weight == null ||
        weight <= 0 ||
        (heightText.isNotEmpty && (height == null || height <= 0))) {
      setState(() => _error = 'Enter a valid weight and optional height.');
      return;
    }
    Navigator.pop(context, (weight, height));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.measurement == null ? 'Add measurement' : 'Edit measurement',
    ),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _weight,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Weight (kg)'),
        ),
        const SizedBox(height: 9),
        TextField(
          controller: _height,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Height (cm, optional)'),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: const TextStyle(color: Color(0xFFB74B4B), fontSize: 11),
          ),
        ],
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _save, child: const Text('Save')),
    ],
  );
}

class _TrendPoint {
  const _TrendPoint(this.label, this.value);

  final String label;
  final int value;
}

class _ProgressTrendChart extends StatelessWidget {
  const _ProgressTrendChart({required this.title, required this.points});

  final String title;
  final List<_TrendPoint> points;

  @override
  Widget build(BuildContext context) {
    final maximum = points.fold<int>(
      1,
      (current, point) => point.value > current ? point.value : current,
    );
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 13),
          SizedBox(
            height: 112,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: points
                  .map(
                    (point) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              point.value == 0 ? '' : '${point.value}',
                              style: const TextStyle(
                                color: Color(0xFF708198),
                                fontSize: 8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              constraints: const BoxConstraints(minHeight: 3),
                              height: point.value == 0
                                  ? 3
                                  : 12 + 52 * point.value / maximum,
                              decoration: BoxDecoration(
                                color: point.value == 0
                                    ? const Color(0xFFE5EDF7)
                                    : const Color(0xFF1684E8),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              point.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF8290A2),
                                fontSize: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressHero extends StatelessWidget {
  const _ProgressHero({
    required this.calories,
    required this.mealCount,
    required this.calorieGoal,
  });
  final int calories;
  final int mealCount;
  final int calorieGoal;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(19),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF123B66), Color(0xFF146C78)],
      ),
      borderRadius: BorderRadius.circular(21),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 88,
          height: 88,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 82,
                height: 82,
                child: CircularProgressIndicator(
                  value: (calories / calorieGoal).clamp(0.0, 1.0),
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withValues(alpha: .18),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF91E1C2)),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(calories / calorieGoal * 100).round()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'daily target',
                    style: TextStyle(color: Color(0xFFD3E4ED), fontSize: 8),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 17),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Today’s intake',
                style: TextStyle(color: Color(0xFFD3E4ED), fontSize: 11),
              ),
              Text(
                '$calories kcal',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '$mealCount meals recorded',
                style: const TextStyle(color: Color(0xFFB8D9D9), fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _MacroSummaryCard extends StatelessWidget {
  const _MacroSummaryCard({
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.goals,
  });
  final int protein;
  final int carbs;
  final int fat;
  final NutritionGoals goals;

  @override
  Widget build(BuildContext context) => _WhiteCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading('Macro breakdown'),
        const SizedBox(height: 13),
        _MacroLine(
          label: 'Protein',
          value: protein,
          goal: goals.protein,
          color: AppColors.teal,
        ),
        const SizedBox(height: 12),
        _MacroLine(
          label: 'Carbohydrates',
          value: carbs,
          goal: goals.carbs,
          color: AppColors.blue,
        ),
        const SizedBox(height: 12),
        _MacroLine(
          label: 'Fat',
          value: fat,
          goal: goals.fat,
          color: const Color(0xFFE6A13A),
        ),
      ],
    ),
  );
}

class _MacroLine extends StatelessWidget {
  const _MacroLine({
    required this.label,
    required this.value,
    required this.goal,
    required this.color,
  });
  final String label;
  final int value;
  final int goal;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '$value g',
            style: const TextStyle(
              color: Color(0xFF78869A),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: LinearProgressIndicator(
          value: (value / goal).clamp(0.0, 1.0),
          minHeight: 7,
          backgroundColor: const Color(0xFFEDF1F4),
          color: color,
        ),
      ),
    ],
  );
}
