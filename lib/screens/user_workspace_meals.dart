part of 'user_workspace_screen.dart';

class _MealsTab extends StatelessWidget {
  const _MealsTab({
    required this.meals,
    required this.selectedDate,
    required this.onSelectDate,
    required this.onAdd,
    required this.onDelete,
    required this.onEdit,
    required this.onDuplicate,
    required this.onShowDetails,
  });

  final List<MealRecord> meals;
  final DateTime selectedDate;
  final VoidCallback onSelectDate;
  final VoidCallback onAdd;
  final ValueChanged<MealRecord> onDelete;
  final ValueChanged<MealRecord> onEdit;
  final ValueChanged<MealRecord> onDuplicate;
  final ValueChanged<MealRecord> onShowDetails;

  @override
  Widget build(BuildContext context) {
    final calories = meals.fold<int>(0, (sum, meal) => sum + meal.calories);
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 26),
      children: [
        const _PageHeading(
          title: 'Food diary',
          subtitle: 'Search foods and record your meals',
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: _TodayPill(date: selectedDate, onTap: onSelectDate),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF123B66), Color(0xFF146C78)],
            ),
            borderRadius: BorderRadius.circular(19),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.local_fire_department_outlined,
                color: Color(0xFFB7EADA),
                size: 25,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TODAY’S INTAKE',
                      style: TextStyle(
                        color: Color(0xFFB8D9D9),
                        fontSize: 9,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '$calories kcal',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${meals.length} meals',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 17),
        Row(
          children: [
            const Expanded(child: _SectionHeading('Logged today')),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 17),
              label: const Text('Add meal'),
            ),
          ],
        ),
        if (meals.isEmpty)
          _EmptyActionCard(onTap: onAdd)
        else
          ...meals.map(
            (meal) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _MealCard(
                meal: meal,
                onDelete: () => onDelete(meal),
                onEdit: () => onEdit(meal),
                onDuplicate: () => onDuplicate(meal),
                onDetails: () => onShowDetails(meal),
              ),
            ),
          ),
        const _DemoNotice(
          text: 'Only food records published by an Admin in the shared catalog are available when adding a meal.',
        ),
      ],
    );
  }
}

class _AddMealSheet extends StatefulWidget {
  const _AddMealSheet({
    required this.date,
    required this.foodCatalog,
    required this.foodCategories,
    required this.onBarcodeLookup,
    this.initialMeal,
  });

  final DateTime date;
  final List<_FoodData> foodCatalog;
  final List<String> foodCategories;
  final Future<_FoodData?> Function(String) onBarcodeLookup;
  final MealRecord? initialMeal;

  @override
  State<_AddMealSheet> createState() => _AddMealSheetState();
}

class _AddMealSheetState extends State<_AddMealSheet> {
  final _formKey = GlobalKey<FormState>();
  final _search = TextEditingController();
  final _name = TextEditingController();
  final _calories = TextEditingController();
  final _protein = TextEditingController();
  final _carbs = TextEditingController();
  final _fat = TextEditingController();
  final _notes = TextEditingController();
  final List<MealRecord> _pendingItems = [];
  String _category = 'Breakfast';
  String _foodFilter = 'All';
  String _servingSize = '1 serving';
  bool _sortByCalories = false;
  int _servings = 1;
  _FoodData? _selectedFood;
  late DateTime _entryDate;

  List<_FoodData> get _visibleFoods {
    final query = _search.text.trim().toLowerCase();
    final foods = widget.foodCatalog
        .where(
          (food) =>
              food.name.toLowerCase().contains(query) &&
              (_foodFilter == 'All' || food.category == _foodFilter),
        )
        .toList();
    if (_sortByCalories) {
      foods.sort((first, second) => first.calories.compareTo(second.calories));
    } else {
      foods.sort((first, second) => first.name.compareTo(second.name));
    }
    return foods;
  }

  double get _servingMultiplier => switch (_servingSize) {
    '½ serving' => .5,
    '2 servings' => 2.0,
    _ => 1.0,
  };

  @override
  void initState() {
    super.initState();
    final meal = widget.initialMeal;
    _entryDate = DateUtils.dateOnly(meal?.createdAt ?? widget.date);
    if (meal == null) return;
    _name.text = meal.name;
    _category = meal.category;
    _calories.text = meal.calories.toString();
    _protein.text = meal.protein.toString();
    _carbs.text = meal.carbs.toString();
    _fat.text = meal.fat.toString();
    _notes.text = meal.notes;
  }

  @override
  void dispose() {
    _search.dispose();
    _name.dispose();
    _calories.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _selectFood(_FoodData food) {
    setState(() {
      _selectedFood = food;
      if (widget.foodCategories.contains(food.category)) {
        _category = food.category;
      }
      _servings = 1;
      _servingSize = '1 serving';
      _name.text = food.name;
      _calories.text = food.calories.toString();
      _protein.text = food.protein.toString();
      _carbs.text = food.carbs.toString();
      _fat.text = food.fat.toString();
    });
  }

  Future<void> _lookupFoodByBarcode() async {
    final controller = TextEditingController();
    final barcode = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Find food by barcode'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Barcode number'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(dialogContext, controller.text.trim());
              }
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (barcode == null) return;
    try {
      final food = await widget.onBarcodeLookup(barcode);
      if (!mounted) return;
      if (food == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No published food matched that barcode.'),
          ),
        );
        return;
      }
      _selectFood(food);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  void _updateServing() {
    final food = _selectedFood;
    if (food == null) return;
    final multiplier = _servings * _servingMultiplier;
    _calories.text = (food.calories * multiplier).round().toString();
    _protein.text = (food.protein * multiplier).round().toString();
    _carbs.text = (food.carbs * multiplier).round().toString();
    _fat.text = (food.fat * multiplier).round().toString();
  }

  Future<void> _showFoodDetails(_FoodData food) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(food.name),
        content: Text(
          '${food.calories} kcal · Protein ${food.protein} g · Carbs ${food.carbs} g · Fat ${food.fat} g\n\nServing: ${food.servingLabel}\nSource: ${food.source.isEmpty ? 'Not provided' : food.source}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Food data reports need a connected support service.',
                  ),
                ),
              );
            },
            child: const Text('Report incorrect data'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _selectFood(food);
            },
            child: const Text('Select food'),
          ),
        ],
      ),
    );
  }

  MealRecord _currentEntry() => MealRecord(
    name: _name.text.trim(),
    category: _category,
    calories: int.parse(_calories.text),
    protein: int.parse(_protein.text),
    carbs: int.parse(_carbs.text),
    fat: int.parse(_fat.text),
    foodId: _selectedFood?.id,
    servings: _servings * _servingMultiplier,
    notes: _notes.text.trim(),
    createdAt: _entryDate,
  );

  void _save({bool addAnother = false}) {
    if (!_formKey.currentState!.validate()) return;
    final entry = _currentEntry();
    if (addAnother) {
      setState(() {
        _pendingItems.add(entry);
        _selectedFood = null;
        _servings = 1;
        _servingSize = '1 serving';
        _name.clear();
        _calories.clear();
        _protein.clear();
        _carbs.clear();
        _fat.clear();
        _notes.clear();
      });
      return;
    }
    Navigator.pop(context, [..._pendingItems, entry]);
  }

  Future<void> _selectEntryDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _entryDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (selected != null) {
      setState(() => _entryDate = DateUtils.dateOnly(selected));
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * .92,
    ),
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 18,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDE4E8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 17),
              Text(
                widget.initialMeal == null ? 'Add a meal' : 'Edit meal',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              TextButton.icon(
                onPressed: _selectEntryDate,
                icon: const Icon(Icons.calendar_today_outlined, size: 16),
                label: Text(
                  'Change date · ${_entryDate.year}-${_entryDate.month.toString().padLeft(2, '0')}-${_entryDate.day.toString().padLeft(2, '0')}',
                ),
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search foods',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _search.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                onPressed: () {
                                  _search.clear();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.close),
                              ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: _sortByCalories
                        ? 'Sort by name'
                        : 'Sort by calories',
                    onPressed: () =>
                        setState(() => _sortByCalories = !_sortByCalories),
                    icon: Icon(
                      _sortByCalories ? Icons.sort_by_alpha : Icons.swap_vert,
                      color: const Color(0xFF1684E8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: ['All', ...widget.foodCategories].map((category) {
                    return Padding(
                      padding: EdgeInsets.only(right: 7),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: _foodFilter == category,
                        onSelected: (_) =>
                            setState(() => _foodFilter = category),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 108,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _visibleFoods.isEmpty
                      ? const [
                          Center(
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Text('No published foods available.'),
                            ),
                          ),
                        ]
                      : _visibleFoods
                            .map(
                              (food) => _FoodChoice(
                                food: food,
                                onTap: () => _selectFood(food),
                                onDetails: () => _showFoodDetails(food),
                              ),
                            )
                            .toList(),
                ),
              ),
              if (_selectedFood != null) ...[
                const SizedBox(height: 7),
                Text(
                  'Serving size · ${_selectedFood!.servingLabel}',
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        value: _servingSize,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(
                            value: '½ serving',
                            child: Text('½ serving'),
                          ),
                          DropdownMenuItem(
                            value: '1 serving',
                            child: Text('1 serving'),
                          ),
                          DropdownMenuItem(
                            value: '2 servings',
                            child: Text('2 servings'),
                          ),
                        ],
                        onChanged: (value) => setState(() {
                          _servingSize = value ?? '1 serving';
                          _updateServing();
                        }),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Decrease serving count',
                      onPressed: _servings <= 1
                          ? null
                          : () => setState(() {
                              _servings--;
                              _updateServing();
                            }),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text('$_servings'),
                    IconButton(
                      tooltip: 'Increase serving count',
                      onPressed: () => setState(() {
                        _servings++;
                        _updateServing();
                      }),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ],
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _lookupFoodByBarcode,
                    icon: const Icon(Icons.qr_code_scanner, size: 16),
                    label: const Text('Find by barcode'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Food name',
                  prefixIcon: Icon(Icons.restaurant_menu),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a food name'
                    : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Meal type'),
                items: const ['Breakfast', 'Lunch', 'Dinner', 'Snack']
                    .map(
                      (item) =>
                          DropdownMenuItem(value: item, child: Text(item)),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _category = value ?? 'Breakfast'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _numberInput(_calories, 'kcal')),
                  const SizedBox(width: 8),
                  Expanded(child: _numberInput(_protein, 'Protein g')),
                  const SizedBox(width: 8),
                  Expanded(child: _numberInput(_carbs, 'Carbs g')),
                  const SizedBox(width: 8),
                  Expanded(child: _numberInput(_fat, 'Fat g')),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _notes,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Meal notes (optional)',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              if (widget.initialMeal == null) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _save(addAnother: true),
                  icon: const Icon(Icons.add, size: 17),
                  label: const Text('Add another item'),
                ),
              ],
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: FilledButton(
                      onPressed: _save,
                      child: Text(
                        widget.initialMeal == null
                            ? 'Save to today’s diary'
                            : 'Save changes',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              const Center(
                child: Text(
                  'Saved to your NutriMate account. Values may be estimates.',
                  style: TextStyle(color: Color(0xFF8996A8), fontSize: 10),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _numberInput(TextEditingController controller, String label) =>
      TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
        validator: (value) {
          final number = int.tryParse(value ?? '');
          return number == null || number < 0 ? 'Required' : null;
        },
      );
}

class _FoodData {
  const _FoodData(
    this.id,
    this.name,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.category,
    this.servingLabel, {
    this.source = '',
  });
  final int id;
  final String name;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final String category;
  final String servingLabel;
  final String source;
}

class _FoodChoice extends StatelessWidget {
  const _FoodChoice({
    required this.food,
    required this.onTap,
    required this.onDetails,
  });
  final _FoodData food;
  final VoidCallback onTap;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      width: 116,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F8F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  food.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Food details',
                onPressed: onDetails,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 25,
                  height: 25,
                ),
                icon: const Icon(Icons.info_outline, size: 15),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${food.calories} kcal',
            style: const TextStyle(
              color: AppColors.teal,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Text(
            'Tap to select',
            style: TextStyle(color: Color(0xFF8391A2), fontSize: 8),
          ),
        ],
      ),
    ),
  );
}

class _MealCard extends StatelessWidget {
  const _MealCard({
    required this.meal,
    this.onDelete,
    this.onEdit,
    this.onDuplicate,
    this.onDetails,
  });
  final MealRecord meal;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onDetails;

  @override
  Widget build(BuildContext context) => _WhiteCard(
    padding: const EdgeInsets.all(13),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF6F2),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            _categoryIcon(meal.category),
            color: AppColors.teal,
            size: 21,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                meal.name,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${meal.category} · ${_formatTime(meal.createdAt)} · P ${meal.protein}g · C ${meal.carbs}g · F ${meal.fat}g',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF8290A2), fontSize: 9),
              ),
            ],
          ),
        ),
        const SizedBox(width: 7),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${meal.calories}',
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Text(
              'kcal',
              style: TextStyle(color: Color(0xFF8290A2), fontSize: 8),
            ),
          ],
        ),
        if (onDelete != null ||
            onEdit != null ||
            onDuplicate != null ||
            onDetails != null)
          PopupMenuButton<String>(
            tooltip: 'Meal actions',
            onSelected: (action) {
              switch (action) {
                case 'details':
                  onDetails?.call();
                case 'edit':
                  onEdit?.call();
                case 'duplicate':
                  onDuplicate?.call();
                case 'delete':
                  onDelete?.call();
              }
            },
            itemBuilder: (context) => [
              if (onDetails != null)
                const PopupMenuItem(
                  value: 'details',
                  child: Text('Meal details'),
                ),
              if (onEdit != null)
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
              if (onDuplicate != null)
                const PopupMenuItem(
                  value: 'duplicate',
                  child: Text('Duplicate'),
                ),
              if (onDelete != null)
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
      ],
    ),
  );
}
