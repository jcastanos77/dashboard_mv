import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CreateEventPage extends StatefulWidget {
  final String businessId;
  final String? eventId;
  final Map<String, dynamic>? initialData;

  const CreateEventPage({
    super.key,
    required this.businessId,
    this.eventId,
    this.initialData,
  });

  bool get isEditing => eventId != null;

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {

  final _clientController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();

  DateTime _selectedDate = DateTime.now();

  List<SelectedService> _services = [];

  Map<String, int> _availableResources = {};
  bool _loadingAvailability = false;
  Map<String, int> _availabilityByResource = {};

  double get totalPrice {
    double sum = 0;
    for (var s in _services) {
      sum += s.totalServicePrice;
    }
    return sum;
  }

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  /// -------------------------------------------------
  /// LOAD AVAILABILITY CARD
  /// -------------------------------------------------

  Future<void> _loadAvailability() async {

    setState(() => _loadingAvailability = true);

    final db = FirebaseFirestore.instance;

    final businessDoc = await db
        .collection('businesses')
        .doc(widget.businessId)
        .get();

    final resources =
    Map<String, dynamic>.from(businessDoc.data()?['resources'] ?? {});

    final dateId =
    DateFormat('yyyy-MM-dd').format(_selectedDate);

    final availabilitySnap = await db
        .collection('businesses')
        .doc(widget.businessId)
        .collection('availability')
        .doc(dateId)
        .get();

    final used =
    Map<String, dynamic>.from(availabilitySnap.data() ?? {});

    Map<String, int> result = {};

    for (var entry in resources.entries) {

      final total = (entry.value as num?)?.toInt() ?? 0;
      final usedCount = (used[entry.key] as num?)?.toInt() ?? 0;

      result[entry.key] = total - usedCount;
    }


    setState(() {
      _availableResources = result;
      _loadingAvailability = false;
    });
  }

  /// -------------------------------------------------
  /// ADD SERVICE
  /// -------------------------------------------------

  Future<void> _addService() async {

    final snap = await FirebaseFirestore.instance
        .collection('businesses')
        .doc(widget.businessId)
        .collection('services')
        .where('isActive', isEqualTo: true)
        .get();

    if (snap.docs.isEmpty) return;

    final selected = await showCupertinoModalPopup<DocumentSnapshot>(
      context: context,
      builder: (_) {
        return Container(
          height: 350,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: ListView(
            children: snap.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return CupertinoButton(
                child: Text(data['name']),
                onPressed: () {
                  Navigator.pop(context, doc);
                },
              );
            }).toList(),
          ),
        );
      },
    );

    if (selected != null) {
      final data = selected.data() as Map<String, dynamic>;

      setState(() {
        _services.add(
          SelectedService(
            serviceId: selected.id,
            serviceName: data['name'],
            resourceType: data['resourceType'],
          ),
        );
      });
    }
  }

  /// -------------------------------------------------
  /// VALIDATE RESOURCES
  /// -------------------------------------------------

  Future<void> _validateResources() async {

    final db = FirebaseFirestore.instance;

    final businessDoc = await db
        .collection('businesses')
        .doc(widget.businessId)
        .get();

    final resources =
    Map<String, dynamic>.from(businessDoc.data()?['resources'] ?? {});

    final dateId =
    DateFormat('yyyy-MM-dd').format(_selectedDate);

    final availabilitySnap = await db
        .collection('businesses')
        .doc(widget.businessId)
        .collection('availability')
        .doc(dateId)
        .get();

    final used =
    Map<String, dynamic>.from(availabilitySnap.data() ?? {});

    Map<String, int> required = {};

    for (var s in _services) {
      required[s.resourceType] =
          (required[s.resourceType] ?? 0) + 1;
    }

    for (var entry in required.entries) {

      final total = (resources[entry.key] as num?)?.toInt() ?? 0;
      final usedCount = (used[entry.key] as num?)?.toInt() ?? 0;

      if (usedCount + entry.value > total) {
        throw Exception(
            "No hay suficientes barras para ${entry.key}");
      }
    }
  }

  /// -------------------------------------------------
  /// SAVE EVENT
  /// -------------------------------------------------

  Future<void> _save() async {

    if (_clientController.text.isEmpty || _services.isEmpty) return;

    try {
      await _validateResources();
    } catch (e) {
      showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text("Sin disponibilidad"),
          content: Text(e.toString()),
          actions: [
            CupertinoDialogAction(
              child: const Text("OK"),
              onPressed: () => Navigator.pop(context),
            )
          ],
        ),
      );
      return;
    }

    final db = FirebaseFirestore.instance;
    final dateId =
    DateFormat('yyyy-MM-dd').format(_selectedDate);

    final businessRef =
    db.collection('businesses').doc(widget.businessId);

    await db.runTransaction((tx) async {

      final eventRef =
      businessRef.collection('events').doc();

      tx.set(eventRef, {
        'clientName': _clientController.text.trim(),
        'phone': _phoneController.text.trim(),
        'locationName': _locationController.text.trim(),
        'date': DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
        ),
        'totalPrice': totalPrice,
        'totalPaid': 0,
        'services': _services.map((s) => s.toMap()).toList(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      final availabilityRef =
      businessRef.collection('availability').doc(dateId);

      final availabilitySnap =
      await tx.get(availabilityRef);

      Map<String, dynamic> current =
          availabilitySnap.data() ?? {};

      Map<String, int> required = {};

      for (var s in _services) {
        required[s.resourceType] =
            (required[s.resourceType] ?? 0) + 1;
      }

      for (var entry in required.entries) {
        final used = current[entry.key] ?? 0;
        current[entry.key] = used + entry.value;
      }

      tx.set(availabilityRef, current, SetOptions(merge: true));
    });

    Navigator.pop(context);
  }

  /// -------------------------------------------------
  /// SELECT PACKAGE
  /// -------------------------------------------------

  Future<void> _selectPackage(SelectedService service) async {

    final snap = await FirebaseFirestore.instance
        .collection('businesses')
        .doc(widget.businessId)
        .collection('services')
        .doc(service.serviceId)
        .collection('packages')
        .where('isActive', isEqualTo: true)
        .get();

    if (snap.docs.isEmpty) return;

    final selected = await showCupertinoModalPopup<DocumentSnapshot>(
      context: context,
      builder: (_) {
        return Container(
          height: 350,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: ListView(
            children: snap.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return CupertinoButton(
                child: Text(
                    "${data['name']} • \$${data['price']}"),
                onPressed: () {
                  Navigator.pop(context, doc);
                },
              );
            }).toList(),
          ),
        );
      },
    );

    if (selected != null) {
      final data = selected.data() as Map<String, dynamic>;
      setState(() {
        service.packageId = selected.id;
        service.packageName = data['name'];
        service.basePrice =
            (data['price'] as num).toDouble();
      });
    }
  }

  /// -------------------------------------------------
  /// SELECT OPTIONS
  /// -------------------------------------------------

  Future<void> _selectOptions(SelectedService service) async {

    final snap = await FirebaseFirestore.instance
        .collection('businesses')
        .doc(widget.businessId)
        .collection('services')
        .doc(service.serviceId)
        .collection('options')
        .where('isActive', isEqualTo: true)
        .get();

    if (snap.docs.isEmpty) return;

    await showCupertinoModalPopup(
      context: context,
      builder: (_) {
        return Container(
          height: 350,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: ListView(
            children: snap.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return CupertinoButton(
                child: Text(
                    "${data['name']} • +\$${data['extraCost']}"),
                onPressed: () {
                  setState(() {
                    service.options.add({
                      'optionId': doc.id,
                      'name': data['name'],
                      'extraCost': data['extraCost'],
                    });
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Future<void> _pickDate() async {

    final now = DateTime.now();

    // 🔹 Normalizamos a solo fecha
    final today = DateTime(now.year, now.month, now.day);

    DateTime tempDate = _selectedDate.isBefore(today)
        ? today
        : _selectedDate;

    final picked = await showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (_) {
        return Container(
          height: 300,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [

              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: tempDate,
                  minimumDate: today, // 👈 SOLO FECHA
                  onDateTimeChanged: (val) {
                    tempDate = val;
                  },
                ),
              ),

              CupertinoButton(
                child: const Text("Seleccionar"),
                onPressed: () {
                  Navigator.pop(context, tempDate);
                },
              )
            ],
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
        );
      });

      await _loadAvailability();
    }
  }

  /// -------------------------------------------------
  /// UI
  /// -------------------------------------------------

  @override
  Widget build(BuildContext context) {

      final bg = CupertinoColors.systemGroupedBackground.resolveFrom(context);
      final cardBg = CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context);
      final label = CupertinoColors.label.resolveFrom(context);
      final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);

      return CupertinoPageScaffold(
        backgroundColor: bg,
        navigationBar: CupertinoNavigationBar(
          middle: Text(widget.isEditing ? "Editar Evento" : "Nuevo Evento"),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            children: [

              /// =============================
              /// FECHA + DISPONIBILIDAD
              /// =============================

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      "Fecha del evento",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: secondary,
                      ),
                    ),

                    const SizedBox(height: 6),

                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _pickDate,
                      child: Text(
                        DateFormat('dd MMM yyyy').format(_selectedDate),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: label,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    if (!_loadingAvailability)
                      Column(
                        children: _availableResources.entries.map((e) {

                          final available = e.value;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [

                                Text(
                                  e.key.replaceAll('_', ' ').toUpperCase(),
                                  style: TextStyle(color: label),
                                ),

                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: available <= 0
                                        ? CupertinoColors.systemRed.withOpacity(.15)
                                        : CupertinoColors.systemGreen.withOpacity(.15),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    available <= 0
                                        ? "FULL"
                                        : "$available disponibles",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: available <= 0
                                          ? CupertinoColors.systemRed
                                          : CupertinoColors.systemGreen,
                                    ),
                                  ),
                                )
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              /// =============================
              /// DATOS DEL CLIENTE
              /// =============================

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [

                    CupertinoTextField(
                      controller: _clientController,
                      placeholder: "Nombre del cliente",
                    ),

                    const SizedBox(height: 12),

                    CupertinoTextField(
                      controller: _phoneController,
                      placeholder: "Teléfono",
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: 12),

                    CupertinoTextField(
                      controller: _locationController,
                      placeholder: "Lugar del evento",
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              /// =============================
              /// SERVICIOS
              /// =============================

              ..._services.map((s) => Container(
                margin: const EdgeInsets.only(bottom: 18),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          s.serviceName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: const Icon(CupertinoIcons.delete),
                          onPressed: () {
                            setState(() {
                              _services.remove(s);
                            });
                          },
                        )
                      ],
                    ),

                    const SizedBox(height: 10),

                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => _selectPackage(s),
                      child: Text(
                        s.packageName == null
                            ? "Seleccionar paquete"
                            : "Paquete: ${s.packageName}",
                      ),
                    ),

                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => _selectOptions(s),
                      child: const Text("Agregar opción extra"),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "Total servicio: \$${s.totalServicePrice.toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )),

              CupertinoButton(
                onPressed: _addService,
                child: const Text("+ Agregar barra"),
              ),

              const SizedBox(height: 30),

              /// =============================
              /// TOTAL
              /// =============================

              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Total",
                      style: TextStyle(
                        fontSize: 16,
                        color: secondary,
                      ),
                    ),
                    Text(
                      "\$${totalPrice.toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              CupertinoButton.filled(
                borderRadius: BorderRadius.circular(20),
                onPressed: _save,
                child: const Text("Crear Evento"),
              ),
            ],
          ),
        ),
      );
    }
  }


class SelectedService {

  String serviceId;
  String serviceName;
  String resourceType;

  String? packageId;
  String? packageName;
  double basePrice = 0;

  List<Map<String, dynamic>> options = [];

  SelectedService({
    required this.serviceId,
    required this.serviceName,
    required this.resourceType,
  });

  double get totalServicePrice {
    double optionsTotal = 0;
    for (var o in options) {
      optionsTotal += (o['extraCost'] ?? 0);
    }
    return basePrice + optionsTotal;
  }

  Map<String, dynamic> toMap() {
    return {
      'serviceId': serviceId,
      'serviceName': serviceName,
      'resourceType': resourceType,
      'packageId': packageId,
      'packageName': packageName,
      'basePrice': basePrice,
      'options': options,
      'totalServicePrice': totalServicePrice,
    };
  }
}
