import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/service_model.dart';
import '../../models/package_model.dart';
import '../../models/option_model.dart';

class EventFormPage extends StatefulWidget {
  final String businessId;

  const EventFormPage({
    super.key,
    required this.businessId
  });

  @override
  State<EventFormPage> createState() =>
      _EventFormPageState();
}

class _EventFormPageState
    extends State<EventFormPage> {

  final _formKey = GlobalKey<FormState>();

  DateTime _selectedDate = DateTime.now();

  ServiceModel? _selectedService;
  PackageModel? _selectedPackage;
  List<OptionModel> _selectedOptions = [];

  final _clientController = TextEditingController();
  final _phoneController = TextEditingController();
  final _anticipoController =
  TextEditingController();

  double _total = 0;

  int _availableSpots = -1;
  bool _isCheckingAvailability = false;


  @override
  void initState() {
    super.initState();
  }

  void _calculateTotal() {
    double total = 0;

    if (_selectedPackage != null) {
      total += _selectedPackage!.price;
    }

    for (var option in _selectedOptions) {
      total += option.extraCost;
    }

    setState(() {
      _total = total;
    });
  }

  Future<void> _saveEvent(String businessId) async {

    if (!_formKey.currentState!.validate()) return;

    if (_selectedService == null || _selectedPackage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Selecciona servicio y paquete"),
        ),
      );
      return;
    }

    final anticipo =
    double.parse(_anticipoController.text);

    if (anticipo < 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Mínimo 500 para apartar"),
        ),
      );
      return;
    }

    final db = FirebaseFirestore.instance;

    final dateId =
    DateFormat('yyyy-MM-dd').format(_selectedDate);

    final businessRef =
    db.collection('businesses').doc(businessId);

    final availabilityRef =
    businessRef.collection('availability')
        .doc(dateId);

    final serviceRef =
    businessRef.collection('services')
        .doc(_selectedService!.id);

    await db.runTransaction((tx) async {

      final serviceSnap =
      await tx.get(serviceRef);

      final capacity =
      serviceSnap['dailyCapacity'];

      final availabilitySnap =
      await tx.get(availabilityRef);

      int currentCount = 0;

      if (availabilitySnap.exists) {
        currentCount =
            availabilitySnap.data()?[
            _selectedService!.id] ??
                0;
      }

      if (currentCount >= capacity) {
        throw Exception(
            "No hay disponibilidad ese día");
      }

      /// Crear evento
      final eventRef =
      businessRef.collection('events').doc();

      tx.set(eventRef, {

        'date': DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day),

        'clientName':
        _clientController.text.trim(),

        'phone':
        _phoneController.text.trim(),

        'serviceId':
        _selectedService!.id,

        'serviceName':  // 👈 NUEVO
        _selectedService!.name,

        'packageId':
        _selectedPackage!.id,

        'packageName':  // 👈 NUEVO
        _selectedPackage!.name,

        'selectedOptions':
        _selectedOptions
            .map((e) => e.id)
            .toList(),

        'totalPrice': _total,

        'totalPaid': anticipo,

        'status': 'confirmed',

        'createdAt':
        FieldValue.serverTimestamp(),
      });

      /// Crear pago inicial
      tx.set(
        eventRef.collection('payments').doc(),
        {
          'amount': anticipo,
          'date': FieldValue.serverTimestamp(),
          'method': 'anticipo',
        },
      );

      /// Actualizar disponibilidad
      tx.set(
        availabilityRef,
        {
          _selectedService!.id:
          currentCount + 1
        },
        SetOptions(merge: true),
      );
    });

    Navigator.pop(context);
  }

  Future<void> _checkAvailability(String businessId) async {

    if (_selectedService == null) return;

    setState(() {
      _isCheckingAvailability = true;
    });

    final db = FirebaseFirestore.instance;

    final dateId =
    DateFormat('yyyy-MM-dd').format(_selectedDate);

    final availabilityDoc = await db
        .collection('businesses')
        .doc(businessId)
        .collection('availability')
        .doc(dateId)
        .get();

    final serviceDoc = await db
        .collection('businesses')
        .doc(businessId)
        .collection('services')
        .doc(_selectedService!.id)
        .get();

    final capacity =
    serviceDoc['dailyCapacity'];

    final used =
        availabilityDoc.data()?[
        _selectedService!.id] ??
            0;

    setState(() {
      _availableSpots = capacity - used;
      _isCheckingAvailability = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    final businessId = widget.businessId;

    return Scaffold(
          appBar: AppBar(
            title: const Text("Nuevo Evento"),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [

                  /// Fecha
                  ListTile(
                    title: const Text("Fecha"),
                    subtitle: Text(
                      DateFormat('dd MMM yyyy')
                          .format(_selectedDate),
                    ),
                    trailing:
                    const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked =
                      await showDatePicker(
                        context: context,
                        initialDate:
                        _selectedDate,
                        firstDate:
                        DateTime(2023),
                        lastDate:
                        DateTime(2035),
                      );

                      if (picked != null) {
                        setState(() {
                          _selectedDate =
                              picked;
                        });

                        await _checkAvailability(businessId);
                      }
                    },
                  ),

                  const SizedBox(height: 12),

                  /// Cliente
                  TextFormField(
                    controller:
                    _clientController,
                    decoration:
                    const InputDecoration(
                        labelText:
                        "Nombre cliente"),
                    validator: (v) =>
                    v == null || v.isEmpty
                        ? "Requerido"
                        : null,
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _phoneController,
                    decoration:
                    const InputDecoration(
                        labelText: "Teléfono"),
                    validator: (v) =>
                    v == null || v.isEmpty
                        ? "Requerido"
                        : null,
                  ),

                  const SizedBox(height: 20),

                  /// Servicios
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore
                        .instance
                        .collection(
                        'businesses')
                        .doc(businessId)
                        .collection(
                        'services')
                        .where('isActive',
                        isEqualTo: true)
                        .snapshots(),
                    builder: (context, snap) {

                      if (!snap.hasData)
                        return const SizedBox();

                      final services =
                      snap.data!.docs
                          .map((d) =>
                          ServiceModel
                              .fromMap(
                              d.data()
                              as Map<String,
                                  dynamic>,
                              d.id))
                          .toList();

                      return DropdownButtonFormField<
                          ServiceModel>(
                        value: _selectedService,
                        hint: const Text(
                            "Seleccionar servicio"),
                        items: services
                            .map((s) =>
                            DropdownMenuItem(
                              value: s,
                              child:
                              Text(s.name),
                            ))
                            .toList(),
                        onChanged: (val) async{
                          setState(() {
                            _selectedService =
                                val;
                            _selectedPackage =
                            null;
                            _selectedOptions
                                .clear();
                            _calculateTotal();
                          });

                          await _checkAvailability(businessId);

                        },
                        validator: (v) =>
                        v == null
                            ? "Selecciona servicio"
                            : null,
                      );
                    },
                  ),

                  if (_selectedService != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: _isCheckingAvailability
                          ? const CircularProgressIndicator()
                          : Text(
                        _availableSpots > 0
                            ? "$_availableSpots disponibles"
                            : "FULL ese día",
                        style: TextStyle(
                          color: _availableSpots > 0
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),


                  const SizedBox(height: 12),

                  /// Paquetes
                  if (_selectedService != null)
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore
                          .instance
                          .collection(
                          'businesses')
                          .doc(businessId)
                          .collection(
                          'services')
                          .doc(_selectedService!
                          .id)
                          .collection(
                          'packages')
                          .where('isActive',
                          isEqualTo: true)
                          .snapshots(),
                      builder:
                          (context, snap) {

                        if (!snap.hasData)
                          return const SizedBox();

                        final packages =
                        snap.data!.docs
                            .map((d) =>
                            PackageModel
                                .fromMap(
                                d.data()
                                as Map<String,
                                    dynamic>,
                                d.id))
                            .toList();

                        return DropdownButtonFormField<
                            PackageModel>(
                          value: _selectedPackage,
                          hint: const Text(
                              "Seleccionar paquete"),
                          items: packages
                              .map((p) =>
                              DropdownMenuItem(
                                value: p,
                                child: Text(
                                    "${p.name} - \$${p.price}"),
                              ))
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedPackage =
                                  val;
                              _calculateTotal();
                            });
                          },
                          validator: (v) =>
                          v == null
                              ? "Selecciona paquete"
                              : null,
                        );
                      },
                    ),

                  const SizedBox(height: 12),

                  /// Opciones
                  if (_selectedService != null)
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore
                          .instance
                          .collection(
                          'businesses')
                          .doc(businessId)
                          .collection(
                          'services')
                          .doc(_selectedService!
                          .id)
                          .collection(
                          'options')
                          .where('isActive',
                          isEqualTo: true)
                          .snapshots(),
                      builder:
                          (context, snap) {

                        if (!snap.hasData)
                          return const SizedBox();

                        final options =
                        snap.data!.docs
                            .map((d) =>
                            OptionModel
                                .fromMap(
                                d.data()
                                as Map<String,
                                    dynamic>,
                                d.id))
                            .toList();

                        return Wrap(
                          spacing: 8,
                          children: options
                              .map((option) {
                            final selected =
                            _selectedOptions
                                .contains(
                                option);

                            return FilterChip(
                              label: Text(
                                  "${option.name} +\$${option.extraCost}"),
                              selected: selected,
                              onSelected:
                                  (val) {
                                setState(() {
                                  if (selected) {
                                    _selectedOptions
                                        .remove(
                                        option);
                                  } else {
                                    _selectedOptions
                                        .add(
                                        option);
                                  }
                                  _calculateTotal();
                                });
                              },
                            );
                          }).toList(),
                        );
                      },
                    ),

                  const SizedBox(height: 20),

                  /// Total
                  Text(
                    "Total: \$${_total.toStringAsFixed(2)}",
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight:
                        FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller:
                    _anticipoController,
                    keyboardType:
                    TextInputType.number,
                    decoration:
                    const InputDecoration(
                        labelText:
                        "Anticipo"),
                    validator: (v) =>
                    v == null ||
                        double.tryParse(v) ==
                            null
                        ? "Número inválido"
                        : null,
                  ),

                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: (_availableSpots == 0 ||
                        _isCheckingAvailability)
                        ? null
                        : () => _saveEvent(businessId),
                    child: const Text("Guardar"),
                  ),

                ],
              ),
            ),
          ),
        );
      }
}
