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

  double get totalPrice {
    double sum = 0;
    for (var s in _services) {
      sum += s.totalServicePrice;
    }
    return sum;
  }

  /// -------------------------------
  /// AGREGAR SERVICIO
  /// -------------------------------

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
          ),
        );
      });
    }
  }

  /// -------------------------------
  /// GUARDAR EVENTO
  /// -------------------------------

  Future<void> _save() async {

    if (_clientController.text.isEmpty || _services.isEmpty) return;

    final db = FirebaseFirestore.instance;

    final eventData = {
      'clientName': _clientController.text.trim(),
      'phone': _phoneController.text.trim(),
      'locationName': _locationController.text.trim(),
      'date': DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day),
      'totalPrice': totalPrice,
      'totalPaid': 0,
      'services': _services.map((s) {
        return {
          'serviceId': s.serviceId,
          'serviceName': s.serviceName,
          'packageId': s.packageId,
          'packageName': s.packageName,
          'basePrice': s.basePrice,
          'options': s.options,
          'totalServicePrice': s.totalServicePrice,
        };
      }).toList(),
    };

    final eventRef = await db
        .collection('businesses')
        .doc(widget.businessId)
        .collection('events')
        .add(eventData);

    /// ACTUALIZAR DISPONIBILIDAD
    final dateId = DateFormat('yyyy-MM-dd').format(_selectedDate);

    for (var s in _services) {

      final availabilityRef = db
          .collection('businesses')
          .doc(widget.businessId)
          .collection('availability')
          .doc(dateId);

      await db.runTransaction((tx) async {

        final snap = await tx.get(availabilityRef);

        int count = 0;

        if (snap.exists) {
          count = snap.data()?[s.serviceId] ?? 0;
        }

        tx.set(
          availabilityRef,
          {s.serviceId: count + 1},
          SetOptions(merge: true),
        );
      });
    }

    Navigator.pop(context);
  }

  Future<void> _updateEvent() async {
    final db = FirebaseFirestore.instance;

    final eventRef = db
        .collection('businesses')
        .doc(widget.businessId)
        .collection('events')
        .doc(widget.eventId);

    await eventRef.update({
      'clientName': _clientController.text.trim(),
      'phone': _phoneController.text.trim(),
      'locationName': _locationController.text.trim(),
      'date': DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      ),
      'services': _services.map((s) {
        return {
          'serviceId': s.serviceId,
          'serviceName': s.serviceName,
          'packageId': s.packageId,
          'packageName': s.packageName,
          'basePrice': s.basePrice,
          'options': s.options,
          'totalServicePrice': s.totalServicePrice,
        };
      }).toList(),
      'totalPrice': totalPrice,
    });

    Navigator.pop(context);
  }

  @override
  void initState() {
    super.initState();

    if (widget.isEditing && widget.initialData != null) {
      final data = widget.initialData!;

      _clientController.text = data['clientName'] ?? '';
      _phoneController.text = data['phone'] ?? '';
      _locationController.text = data['locationName'] ?? '';

      _selectedDate = (data['date'] as Timestamp).toDate();

      final services = List<Map<String, dynamic>>.from(
        data['services'] ?? [],
      );

      _services = services.map((s) {
        final service = SelectedService(
          serviceId: s['serviceId'],
          serviceName: s['serviceName'],
        );

        service.packageId = s['packageId'];
        service.packageName = s['packageName'];
        service.basePrice =
            (s['basePrice'] as num?)?.toDouble() ?? 0;

        service.options =
        List<Map<String, dynamic>>.from(s['options'] ?? []);

        return service;
      }).toList();
    }
  }

  /// -------------------------------
  /// UI
  /// -------------------------------

  @override
  Widget build(BuildContext context) {

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.isEditing ? "Editar Evento" : "Nuevo Evento"),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [

            /// CLIENTE
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

            const SizedBox(height: 20),

            CupertinoTextField(
              controller: _locationController,
              placeholder: "Lugar del evento (salón, casa, expo...)",
            ),

            const SizedBox(height: 20),

            /// FECHA
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () async {
                final picked = await showCupertinoModalPopup<DateTime>(
                  context: context,
                  builder: (_) {
                    DateTime tempDate = _selectedDate;
                    return Container(
                      height: 250,
                      color: CupertinoColors.systemBackground.resolveFrom(context),
                      child: Column(
                        children: [
                          Expanded(
                            child: CupertinoDatePicker(
                              mode: CupertinoDatePickerMode.date,
                              initialDateTime: _selectedDate,
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
                    _selectedDate = picked;
                  });
                }
              },
              child: Text(
                DateFormat('dd MMM yyyy').format(_selectedDate),
              ),
            ),

            const SizedBox(height: 30),

            /// SERVICIOS
            const Text(
              "Servicios",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 10),

            ..._services.map((s) {

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        s.serviceName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
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

                  const SizedBox(height: 8),

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

                  if (s.options.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: s.options.map((o) {
                        return Text(
                            "• ${o['name']} (+\$${o['extraCost']})");
                      }).toList(),
                    ),

                  const SizedBox(height: 8),

                  Text(
                    "Total servicio: \$${s.totalServicePrice.toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            }),

            const SizedBox(height: 10),

            CupertinoButton(
              onPressed: _addService,
              child: const Text("+ Agregar barra"),
            ),

            const SizedBox(height: 30),

            /// TOTAL GENERAL
            Text(
              "Total general: \$${totalPrice.toStringAsFixed(0)}",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 20),


            CupertinoButton.filled(
              onPressed: widget.isEditing ? _updateEvent : _save,
              child: Text(widget.isEditing ? "Guardar Cambios" : "Crear Evento"),
            ),
          ],
        ),
      ),
    );
  }

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
          height: 400,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: ListView(
            children: snap.docs.map((doc) {

              final data = doc.data() as Map<String, dynamic>;

              return CupertinoButton(
                child: Text(
                  "${data['name']} • +\$${data['extraCost']}",
                ),
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
        service.basePrice = (data['price'] as num).toDouble();
      });
    }
  }

}

class SelectedService {
  String serviceId;
  String serviceName;

  String? packageId;
  String? packageName;
  double basePrice = 0;

  List<Map<String, dynamic>> options = [];

  SelectedService({
    required this.serviceId,
    required this.serviceName,
  });

  double get totalServicePrice {
    double optionsTotal = 0;
    for (var o in options) {
      optionsTotal += (o['extraCost'] ?? 0);
    }
    return basePrice + optionsTotal;
  }
}
