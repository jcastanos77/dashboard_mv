import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/business_helper.dart';
import '../../services/event_service.dart';

class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key});

  @override
  State<CreateEventPage> createState() =>
      _CreateEventPageState();
}

class _CreateEventPageState
    extends State<CreateEventPage> {

  final _formKey = GlobalKey<FormState>();

  final _clientController =
  TextEditingController();
  final _phoneController =
  TextEditingController();
  final _locationController =
  TextEditingController();
  final _anticipoController =
  TextEditingController();

  final EventService _eventService =
  EventService();

  String? _businessId;
  bool _initialLoading = true;

  DateTime _selectedDate =
  DateTime.now();

  String? _selectedServiceId;
  String? _selectedServiceName;

  String? _selectedPackageId;
  String? _selectedPackageName;
  double _total = 0;

  bool _isFull = false;
  bool _checkingCapacity = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final id = await getBusinessId();
    setState(() {
      _businessId = id;
      _initialLoading = false;
    });
  }

  Future<void> _checkCapacity() async {

    if (_selectedServiceId == null ||
        _businessId == null) return;

    setState(() => _checkingCapacity = true);

    final db = FirebaseFirestore.instance;

    final dateId =
    DateFormat('yyyy-MM-dd')
        .format(_selectedDate);

    final availabilityDoc = await db
        .collection('businesses')
        .doc(_businessId)
        .collection('availability')
        .doc(dateId)
        .get();

    final serviceDoc = await db
        .collection('businesses')
        .doc(_businessId)
        .collection('services')
        .doc(_selectedServiceId)
        .get();

    final capacity =
    serviceDoc['dailyCapacity'];

    final used =
        availabilityDoc.data()?[_selectedServiceId] ?? 0;

    setState(() {
      _isFull = used >= capacity;
      _checkingCapacity = false;
    });
  }

  Future<void> _save() async {

    if (_businessId == null) return;

    if (_clientController.text.trim().isEmpty ||
        _locationController.text.trim().isEmpty ||
        _selectedServiceId == null ||
        _selectedPackageId == null) {
      return;
    }

    final anticipo =
        double.tryParse(
            _anticipoController.text) ??
            0;

    if (anticipo < 500) return;

    setState(() => _loading = true);

    try {

      await _eventService
          .createEventWithPayment(
        businessId: _businessId!,
        date: _selectedDate,
        serviceId: _selectedServiceId!,
        totalPrice: _total,
        firstPayment: anticipo,
        eventData: {
          'clientName':
          _clientController.text.trim(),
          'phone':
          _phoneController.text.trim(),
          'locationName':
          _locationController.text.trim(),
          'packageId':
          _selectedPackageId,
          'packageName':
          _selectedPackageName,
        },
      );

      Navigator.pop(context);

    } catch (e) {
      showCupertinoDialog(
        context: context,
        builder: (_) =>
            CupertinoAlertDialog(
              title:
              const Text("Sin disponibilidad"),
              content: const Text(
                  "Ese servicio está lleno ese día."),
              actions: [
                CupertinoDialogAction(
                  child: const Text("OK"),
                  onPressed: () =>
                      Navigator.pop(context),
                )
              ],
            ),
      );
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {

    if (_initialLoading) {
      return const CupertinoPageScaffold(
        child: Center(
          child:
          CupertinoActivityIndicator(),
        ),
      );
    }

    final bg =
    CupertinoColors.systemGroupedBackground
        .resolveFrom(context);

    final cardColor =
    CupertinoColors.secondarySystemGroupedBackground
        .resolveFrom(context);

    final secondaryText =
    CupertinoColors.secondaryLabel
        .resolveFrom(context);

    return CupertinoPageScaffold(
      backgroundColor: bg,
      navigationBar:
      const CupertinoNavigationBar(
        middle:
        Text("Nuevo Evento"),
      ),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding:
            const EdgeInsets.fromLTRB(
                16, 16, 16, 120),
            children: [

              _section("Cliente", secondaryText),

              _input(cardColor,
                  CupertinoTextField(
                    controller:
                    _clientController,
                    placeholder:
                    "Nombre",
                  )),

              _input(cardColor,
                  CupertinoTextField(
                    controller:
                    _phoneController,
                    placeholder:
                    "Teléfono",
                    keyboardType:
                    TextInputType.phone,
                  )),

              _input(cardColor,
                  CupertinoTextField(
                    controller:
                    _locationController,
                    placeholder:
                    "Lugar del evento",
                  )),

              const SizedBox(height: 16),

              _section("Evento", secondaryText),

              _row(cardColor,
                  "Fecha",
                  DateFormat(
                      'dd MMM yyyy')
                      .format(
                      _selectedDate),
                  _openDatePicker),

              _row(cardColor,
                  "Servicio",
                  _selectedServiceName ??
                      "Seleccionar",
                  _showServiceSheet),

              if (_selectedServiceId !=
                  null)
                Padding(
                  padding:
                  const EdgeInsets.only(
                      top: 6),
                  child:
                  _checkingCapacity
                      ? const CupertinoActivityIndicator()
                      : Text(
                    _isFull
                        ? "Sin disponibilidad"
                        : "Disponible",
                    style:
                    TextStyle(
                      fontSize:
                      13,
                      fontWeight:
                      FontWeight
                          .w600,
                      color:
                      _isFull
                          ? CupertinoColors
                          .systemRed
                          : CupertinoColors
                          .systemGreen,
                    ),
                  ),
                ),

              _row(cardColor,
                  "Paquete",
                  _selectedPackageName ??
                      "Seleccionar",
                  _showPackageSheet),

              const SizedBox(height: 16),

              _section("Pago", secondaryText),

              _input(cardColor,
                  CupertinoTextField(
                    controller:
                    _anticipoController,
                    placeholder:
                    "Anticipo",
                    keyboardType:
                    TextInputType.number,
                  )),

              const SizedBox(height: 8),

              Text(
                "Total \$${_total.toStringAsFixed(0)}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              CupertinoButton(
                borderRadius:
                BorderRadius
                    .circular(14),
                color:
                CupertinoColors
                    .systemBlue,
                onPressed:
                (_loading ||
                    _isFull ||
                    _checkingCapacity)
                    ? null
                    : _save,
                child: _loading
                    ? const CupertinoActivityIndicator(
                  color:
                  CupertinoColors
                      .white,
                )
                    : const Text(
                  "Guardar evento",
                  style:
                  TextStyle(
                    color: Colors.white,
                    fontWeight:
                    FontWeight
                        .w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDatePicker() {
    Navigator.push(
      context,
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (_) =>
            _FullScreenDatePicker(
              initialDate:
              _selectedDate,
              onDateSelected:
                  (date) async {
                setState(() {
                  _selectedDate = date;
                  _selectedPackageId =
                  null;
                  _selectedPackageName =
                  null;
                });

                await _checkCapacity();
              },
            ),
      ),
    );
  }

  void _showServiceSheet() async {

    final snap =
    await FirebaseFirestore
        .instance
        .collection(
        'businesses')
        .doc(_businessId)
        .collection(
        'services')
        .where(
        'isActive',
        isEqualTo: true)
        .get();

    showCupertinoModalPopup(
      context: context,
      builder: (_) =>
          CupertinoActionSheet(
            title:
            const Text(
                "Seleccionar servicio"),
            actions: snap.docs
                .map((doc) {
              final data =
              doc.data();
              return CupertinoActionSheetAction(
                child:
                Text(data['name']),
                onPressed:
                    () async {
                  setState(() {
                    _selectedServiceId =
                        doc.id;
                    _selectedServiceName =
                    data['name'];
                    _selectedPackageId =
                    null;
                    _selectedPackageName =
                    null;
                  });

                  Navigator.pop(
                      context);

                  await _checkCapacity();
                },
              );
            }).toList(),
            cancelButton:
            CupertinoActionSheetAction(
              isDefaultAction:
              true,
              child:
              const Text(
                  "Cancelar"),
              onPressed: () =>
                  Navigator.pop(
                      context),
            ),
          ),
    );
  }

  void _showPackageSheet() async {

    if (_selectedServiceId ==
        null) return;

    final snap =
    await FirebaseFirestore
        .instance
        .collection(
        'businesses')
        .doc(_businessId)
        .collection(
        'services')
        .doc(
        _selectedServiceId)
        .collection(
        'packages')
        .where(
        'isActive',
        isEqualTo: true)
        .get();

    showCupertinoModalPopup(
      context: context,
      builder: (_) =>
          CupertinoActionSheet(
            title:
            const Text(
                "Seleccionar paquete"),
            actions: snap.docs
                .map((doc) {
              final data =
              doc.data();
              return CupertinoActionSheetAction(
                child: Text(
                    "${data['name']} - \$${data['price']}"),
                onPressed:
                    () {
                  setState(() {
                    _selectedPackageId =
                        doc.id;
                    _selectedPackageName =
                    data['name'];
                    _total =
                        (data['price']
                        as num)
                            .toDouble();
                  });

                  Navigator.pop(
                      context);
                },
              );
            }).toList(),
            cancelButton:
            CupertinoActionSheetAction(
              isDefaultAction:
              true,
              child:
              const Text(
                  "Cancelar"),
              onPressed: () =>
                  Navigator.pop(
                      context),
            ),
          ),
    );
  }

  Widget _section(
      String text,
      Color secondaryText) {
    return Padding(
      padding:
      const EdgeInsets.only(
          bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight:
          FontWeight.w600,
          color:
          secondaryText,
        ),
      ),
    );
  }

  Widget _input(
      Color cardColor,
      Widget child) {
    return Container(
      margin:
      const EdgeInsets.only(
          bottom: 10),
      padding:
      const EdgeInsets
          .symmetric(
          horizontal: 14,
          vertical: 10),
      decoration:
      BoxDecoration(
        color: cardColor,
        borderRadius:
        BorderRadius.circular(
            14),
      ),
      child: child,
    );
  }

  Widget _row(
      Color cardColor,
      String label,
      String value,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin:
        const EdgeInsets.only(
            bottom: 10),
        padding:
        const EdgeInsets
            .symmetric(
            horizontal: 14,
            vertical: 12),
        decoration:
        BoxDecoration(
          color: cardColor,
          borderRadius:
          BorderRadius.circular(
              14),
        ),
        child: Row(
          mainAxisAlignment:
          MainAxisAlignment
              .spaceBetween,
          children: [
            Text(label),
            Text(
              value,
              style:
              const TextStyle(
                color:
                CupertinoColors
                    .systemBlue,
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullScreenDatePicker
    extends StatefulWidget {

  final DateTime initialDate;
  final Function(DateTime)
  onDateSelected;

  const _FullScreenDatePicker({
    required this.initialDate,
    required this.onDateSelected,
  });

  @override
  State<_FullScreenDatePicker>
  createState() =>
      _FullScreenDatePickerState();
}

class _FullScreenDatePickerState
    extends State<
        _FullScreenDatePicker> {

  late DateTime _tempDate;

  @override
  void initState() {
    super.initState();
    _tempDate =
        widget.initialDate;
  }

  @override
  Widget build(
      BuildContext context) {

    return CupertinoPageScaffold(
      navigationBar:
      CupertinoNavigationBar(
        middle:
        const Text(
            "Seleccionar fecha"),
        trailing:
        CupertinoButton(
          padding:
          EdgeInsets.zero,
          child:
          const Text(
              "Listo"),
          onPressed: () {
            widget
                .onDateSelected(
                _tempDate);
            Navigator.pop(
                context);
          },
        ),
      ),
      child: SafeArea(
        child: Center(
          child:
          CupertinoDatePicker(
            mode:
            CupertinoDatePickerMode
                .date,
            initialDateTime:
            _tempDate,
            minimumYear:
            2023,
            maximumYear:
            2035,
            onDateTimeChanged:
                (date) {
              _tempDate =
                  date;
            },
          ),
        ),
      ),
    );
  }
}
