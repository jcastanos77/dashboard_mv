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
  bool _loadingServices = false;
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

    // Cargar primero los datos del evento para conocer su fecha real.
    if (widget.isEditing) {
      _loadInitialData();
    }

    _loadAvailability();
  }

  /// -------------------------------------------------
  /// LOAD AVAILABILITY CARD
  /// -------------------------------------------------

  Future<void> _loadAvailability() async {
    if (!mounted) return;

    setState(() => _loadingAvailability = true);

    try {
      final db = FirebaseFirestore.instance;
      final businessRef = db.collection('businesses').doc(widget.businessId);

      final businessSnap = await businessRef.get();
      final resources = Map<String, dynamic>.from(
        businessSnap.data()?['resources'] ?? {},
      );

      final selectedDateId =
      DateFormat('yyyy-MM-dd').format(_selectedDate);

      final availabilitySnap = await businessRef
          .collection('availability')
          .doc(selectedDateId)
          .get();

      final used = Map<String, dynamic>.from(
        availabilitySnap.data() ?? {},
      );

      // Al editar, devolver temporalmente los recursos que ya ocupa
      // este mismo evento, pero solo si seguimos en su fecha original.
      if (widget.isEditing && widget.eventId != null) {
        final eventSnap = await businessRef
            .collection('events')
            .doc(widget.eventId)
            .get();

        final eventData = eventSnap.data();
        final rawDate = eventData?['date'];
        DateTime? oldDate;

        if (rawDate is Timestamp) {
          oldDate = rawDate.toDate();
        } else if (rawDate is DateTime) {
          oldDate = rawDate;
        } else {
          final initialDate = widget.initialData?['date'];
          if (initialDate is Timestamp) {
            oldDate = initialDate.toDate();
          } else if (initialDate is DateTime) {
            oldDate = initialDate;
          }
        }

        if (oldDate != null &&
            DateFormat('yyyy-MM-dd').format(oldDate) == selectedDateId) {
          final oldServices = List<Map<String, dynamic>>.from(
            eventData?['services'] ?? widget.initialData?['services'] ?? [],
          );

          for (final service in oldServices) {
            final resourceType =
            (service['resourceType'] as String? ?? '').trim();

            if (resourceType.isEmpty) continue;

            final count = (used[resourceType] as num?)?.toInt() ?? 0;
            used[resourceType] = (count - 1).clamp(0, 999999);
          }
        }
      }

      final result = <String, int>{};

      for (final entry in resources.entries) {
        final resourceType = entry.key.trim();
        if (resourceType.isEmpty) continue;

        final total = (entry.value as num?)?.toInt() ?? 0;
        final usedCount = (used[resourceType] as num?)?.toInt() ?? 0;

        result[resourceType] = total - usedCount;
      }

      if (!mounted) return;

      setState(() {
        _availableResources = result;
        _loadingAvailability = false;
      });
    } catch (e, stack) {
      debugPrint('Error al cargar disponibilidad: $e');
      debugPrintStack(stackTrace: stack);

      if (!mounted) return;

      setState(() {
        _loadingAvailability = false;
      });

      await _showError('No se pudo cargar la disponibilidad.\n\n$e');
    }
  }

  /// -------------------------------------------------
  /// ADD SERVICE
  /// -------------------------------------------------


  Future<void> _addService() async {
    if (_loadingServices) return;

    setState(() => _loadingServices = true);

    try {
      final snap = await FirebaseFirestore.instance
          .collection('businesses')
          .doc(widget.businessId)
          .collection('services')
          .where('isActive', isEqualTo: true)
          .get();

      if (!mounted) return;

      if (snap.docs.isEmpty) {
        await _showError('No hay servicios activos configurados.');
        return;
      }

      final selected = await showCupertinoModalPopup<
          QueryDocumentSnapshot<Map<String, dynamic>>>(
        context: context,
        builder: (modalContext) {
          return Container(
            height: 350,
            color: CupertinoColors.systemBackground.resolveFrom(modalContext),
            child: SafeArea(
              top: false,
              child: ListView(
                children: snap.docs.map((doc) {
                  final data = doc.data();

                  return CupertinoButton(
                    child: Text(data['name'] ?? 'Sin nombre'),
                    onPressed: () => Navigator.of(modalContext).pop(doc),
                  );
                }).toList(),
              ),
            ),
          );
        },
      );

      if (!mounted || selected == null) return;

      final data = selected.data();
      final resourceType =
      (data['resourceType'] as String? ?? '').trim();

      if (resourceType.isEmpty) {
        await _showError(
          'El servicio "${data['name'] ?? 'Sin nombre'}" no tiene '
              'configurado el campo resourceType en Firestore.',
        );
        return;
      }

      setState(() {
        _services.add(
          SelectedService(
            serviceId: selected.id,
            serviceName: data['name'] ?? '',
            resourceType: resourceType,
          ),
        );
      });
    } catch (e, stack) {
      debugPrint('Error al cargar barras: $e');
      debugPrintStack(stackTrace: stack);

      if (mounted) {
        await _showError(
          'No se pudieron cargar las barras. Intenta nuevamente.\n\n$e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loadingServices = false);
      }
    }
  }

  Future<void> _showError(String message) async {
    await showCupertinoDialog(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text("OK"),
            onPressed: () =>
                Navigator.of(dialogContext).pop(),
          ),
        ],
      ),
    );
  }

  /// -------------------------------------------------
  /// SAVE EVENT
  /// -------------------------------------------------

  Future<void> _save() async {
    if (_clientController.text.trim().isEmpty || _services.isEmpty) {
      await _showError(
        'Todos los eventos deben tener cliente y al menos un servicio seleccionado.',
      );
      return;
    }

    for (final service in _services) {
      if (service.packageId == null) {
        await _showError(
          'Todos los servicios deben tener paquete seleccionado.',
        );
        return;
      }

      if (service.resourceType.trim().isEmpty) {
        await _showError(
          'El servicio "${service.serviceName}" no tiene configurado '
              'su tipo de recurso en Firestore.',
        );
        return;
      }
    }

    try {
      final db = FirebaseFirestore.instance;
      final businessRef = db.collection('businesses').doc(widget.businessId);
      final eventRef = widget.isEditing
          ? businessRef.collection('events').doc(widget.eventId)
          : businessRef.collection('events').doc();

      final newDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
      final newDateId = DateFormat('yyyy-MM-dd').format(newDate);
      final newAvailabilityRef =
      businessRef.collection('availability').doc(newDateId);

      await db.runTransaction((tx) async {
        // Leer primero el evento anterior para conocer la fecha original.
        DocumentSnapshot<Map<String, dynamic>>? oldEventSnap;
        Map<String, dynamic>? oldEventData;

        if (widget.isEditing) {
          oldEventSnap = await tx.get(eventRef);
          oldEventData = oldEventSnap.data();

          if (!oldEventSnap.exists || oldEventData == null) {
            throw Exception('No se encontró el evento que intentas editar.');
          }
        }

        DateTime? oldDate;
        if (oldEventData != null) {
          final rawDate = oldEventData['date'];

          if (rawDate is Timestamp) {
            oldDate = rawDate.toDate();
          } else if (rawDate is DateTime) {
            oldDate = rawDate;
          }
        }

        // Compatibilidad por si el documento antiguo no tiene fecha.
        oldDate ??= newDate;

        final oldDateOnly = DateTime(
          oldDate.year,
          oldDate.month,
          oldDate.day,
        );
        final oldDateId = DateFormat('yyyy-MM-dd').format(oldDateOnly);
        final sameDate = oldDateId == newDateId;

        final oldAvailabilityRef =
        businessRef.collection('availability').doc(oldDateId);

        // Leer todas las disponibilidades antes de escribir.
        final newAvailabilitySnap = await tx.get(newAvailabilityRef);

        DocumentSnapshot<Map<String, dynamic>>? oldAvailabilitySnap;
        if (widget.isEditing && !sameDate) {
          oldAvailabilitySnap = await tx.get(oldAvailabilityRef);
        }

        final newCurrent = <String, dynamic>{
          ...?newAvailabilitySnap.data(),
        };

        final oldCurrent = sameDate
            ? newCurrent
            : <String, dynamic>{...?oldAvailabilitySnap?.data()};

        // Contar recursos usados por los servicios del evento anterior.
        final oldRequired = <String, int>{};
        if (widget.isEditing && oldEventData != null) {
          final oldServices = List<Map<String, dynamic>>.from(
            oldEventData['services'] ?? [],
          );

          for (final service in oldServices) {
            final resourceType =
            (service['resourceType'] as String? ?? '').trim();
            if (resourceType.isEmpty) continue;

            oldRequired[resourceType] =
                (oldRequired[resourceType] ?? 0) + 1;
          }
        }

        // Contar los recursos de los servicios que se guardarán.
        final required = <String, int>{};
        for (final service in _services) {
          final resourceType = service.resourceType.trim();

          if (resourceType.isEmpty) {
            throw Exception(
              'El servicio "${service.serviceName}" no tiene resourceType.',
            );
          }

          required[resourceType] = (required[resourceType] ?? 0) + 1;
        }

        if (widget.isEditing) {
          if (sameDate) {
            // Misma fecha: primero liberar la reserva anterior y después
            // reservar los servicios nuevos, para no descontar doble.
            for (final entry in oldRequired.entries) {
              final used =
                  (newCurrent[entry.key] as num?)?.toInt() ?? 0;
              newCurrent[entry.key] =
                  (used - entry.value).clamp(0, 999999);
            }
          } else {
            // Fecha distinta: liberar los recursos de la fecha anterior.
            for (final entry in oldRequired.entries) {
              final used =
                  (oldCurrent[entry.key] as num?)?.toInt() ?? 0;
              oldCurrent[entry.key] =
                  (used - entry.value).clamp(0, 999999);
            }
          }
        }

        // Reservar los recursos en la fecha seleccionada.
        for (final entry in required.entries) {
          final used = (newCurrent[entry.key] as num?)?.toInt() ?? 0;
          newCurrent[entry.key] = used + entry.value;
        }

        final eventData = <String, dynamic>{
          'clientName': _clientController.text.trim(),
          'phone': _phoneController.text.trim(),
          'locationName': _locationController.text.trim(),
          'date': newDate,
          'totalPrice': totalPrice,
          'totalPaid': oldEventData?['totalPaid'] ?? 0,
          'services': _services.map((service) => service.toMap()).toList(),
          'createdAt': oldEventData?['createdAt'] ??
              FieldValue.serverTimestamp(),
        };

        // Evitar que una clave vacía heredada provoque error en Firestore.
        newCurrent.remove('');
        oldCurrent.remove('');

        tx.set(eventRef, eventData);

        tx.set(
          newAvailabilityRef,
          newCurrent,
          SetOptions(merge: true),
        );

        if (widget.isEditing && !sameDate) {
          tx.set(
            oldAvailabilityRef,
            oldCurrent,
            SetOptions(merge: true),
          );
        }
      });

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e, stack) {
      debugPrint('🔥 ERROR SAVE CREATE EVENT: $e');
      debugPrintStack(stackTrace: stack);

      if (!mounted) return;
      await _showError('No se pudo guardar el evento: $e');
    }
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

  void _loadInitialData() {

    final data = widget.initialData;
    if (data == null) return;

    _clientController.text = data['clientName'] ?? '';
    _phoneController.text = data['phone'] ?? '';
    _locationController.text = data['locationName'] ?? '';

    final rawDate = data['date'];
    final DateTime date;
    if (rawDate is Timestamp) {
      date = rawDate.toDate();
    } else if (rawDate is DateTime) {
      date = rawDate;
    } else {
      date = DateTime.now();
    }

    _selectedDate = DateTime(date.year, date.month, date.day);

    final services = (data['services'] ?? []) as List;

    _services = services.map((s) {

      final service = SelectedService(
        serviceId: s['serviceId'],
        serviceName: s['serviceName'] ?? '',
        resourceType: s['resourceType'] ?? '',
      );

      service.packageId = s['packageId'];
      service.packageName = s['packageName'];
      service.basePrice =
          (s['basePrice'] as num?)?.toDouble() ?? 0;

      service.options =
      List<Map<String, dynamic>>.from(
          s['options'] ?? []);

      return service;

    }).toList();
  }

  @override
  void dispose() {
    _clientController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
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
              onPressed: _loadingServices ? null : _addService,
              child: _loadingServices
                  ? const CupertinoActivityIndicator()
                  : const Text('+ Agregar barra'),
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
              child: Text(widget.isEditing
                  ? "Actualizar Evento"
                  : "Crear Evento"),
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
