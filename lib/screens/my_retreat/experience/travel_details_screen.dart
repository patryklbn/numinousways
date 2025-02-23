import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart'; // For input formatters
import '../../../models/experience/travel_details.dart';
import '../../../services/retreat_service.dart';

class TravelDetailsScreen extends StatefulWidget {
  final String retreatId;
  final String userId; // The participant/user's ID

  const TravelDetailsScreen({
    Key? key,
    required this.retreatId,
    required this.userId,
  }) : super(key: key);

  @override
  State<TravelDetailsScreen> createState() => _TravelDetailsScreenState();
}

class _TravelDetailsScreenState extends State<TravelDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Controllers
  late TextEditingController _nameCtrl;
  late TextEditingController _surnameCtrl;
  late TextEditingController _mobileNumberCtrl;

  // Arrival
  String _arrivalMethod = 'PLANE'; // Default
  late TextEditingController _arrivalFlightCtrl;
  late TextEditingController _arrivalDateCtrl;
  late TextEditingController _arrivalTimeCtrl;

  // Departure
  String _departureMethod = 'PLANE'; // Default
  late TextEditingController _departureFlightCtrl;
  late TextEditingController _departureDateCtrl;
  late TextEditingController _departureTimeCtrl;

  // Passport / Personal
  late TextEditingController _passportNumberCtrl;
  late TextEditingController _passportIssueDateCtrl;
  late TextEditingController _passportPlaceOfIssueCtrl;
  late TextEditingController _birthPlaceCtrl;
  late TextEditingController _dobCtrl;
  late TextEditingController _nationalityCtrl;

  // Additional
  late TextEditingController _additionalCommentCtrl;

  // Define theme colors
  final Color _primaryColor = const Color(0xFF6A0DAD);
  final Color _accentColor = const Color(0xFF3700B3);
  final Color _backgroundColor = const Color(0xFFF8F9FA);
  final Color _cardColor = Colors.white;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    _nameCtrl = TextEditingController();
    _surnameCtrl = TextEditingController();
    _mobileNumberCtrl = TextEditingController();

    _arrivalFlightCtrl = TextEditingController();
    _arrivalDateCtrl = TextEditingController();
    _arrivalTimeCtrl = TextEditingController();

    _departureFlightCtrl = TextEditingController();
    _departureDateCtrl = TextEditingController();
    _departureTimeCtrl = TextEditingController();

    _passportNumberCtrl = TextEditingController();
    _passportIssueDateCtrl = TextEditingController();
    _passportPlaceOfIssueCtrl = TextEditingController();
    _birthPlaceCtrl = TextEditingController();
    _dobCtrl = TextEditingController();
    _nationalityCtrl = TextEditingController();

    _additionalCommentCtrl = TextEditingController();
  }

  @override
  void dispose() {
    // Dispose all controllers
    _nameCtrl.dispose();
    _surnameCtrl.dispose();
    _mobileNumberCtrl.dispose();
    _arrivalFlightCtrl.dispose();
    _arrivalDateCtrl.dispose();
    _arrivalTimeCtrl.dispose();
    _departureFlightCtrl.dispose();
    _departureDateCtrl.dispose();
    _departureTimeCtrl.dispose();
    _passportNumberCtrl.dispose();
    _passportIssueDateCtrl.dispose();
    _passportPlaceOfIssueCtrl.dispose();
    _birthPlaceCtrl.dispose();
    _dobCtrl.dispose();
    _nationalityCtrl.dispose();
    _additionalCommentCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        controller.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  Future<void> _selectTime(BuildContext context, TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        controller.text = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _submitTravelDetails() async {
    // Check form validation
    if (!_formKey.currentState!.validate()) {
      // If validation fails, show a custom dialog
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            "Missing Required Fields",
            style: TextStyle(
              color: _primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            "Some required fields are missing or invalid. "
                "Please fill them before submitting.",
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: TextButton.styleFrom(
                foregroundColor: _primaryColor,
              ),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // If validation passes, construct the TravelDetails model
    final details = TravelDetails(
      userId: widget.userId,
      name: _nameCtrl.text.trim(),
      surname: _surnameCtrl.text.trim(),
      mobileNumber: _mobileNumberCtrl.text.trim(),
      methodOfArrival: _arrivalMethod,
      arrivalFlightNumber: _arrivalFlightCtrl.text.trim(),
      arrivalDate: _arrivalDateCtrl.text.trim(),
      arrivalTime: _arrivalTimeCtrl.text.trim(),
      departureMethod: _departureMethod,
      departureFlightNumber: _departureFlightCtrl.text.trim(),
      departureDate: _departureDateCtrl.text.trim(),
      departureTime: _departureTimeCtrl.text.trim(),
      passportNumber: _passportNumberCtrl.text.trim(),
      passportIssuingDate: _passportIssueDateCtrl.text.trim(),
      passportPlaceOfIssue: _passportPlaceOfIssueCtrl.text.trim(),
      birthPlace: _birthPlaceCtrl.text.trim(),
      dob: _dobCtrl.text.trim(),
      nationality: _nationalityCtrl.text.trim(),
      additionalComment: _additionalCommentCtrl.text.trim(),
    );

    try {
      final retreatService = Provider.of<RetreatService>(context, listen: false);
      await retreatService.submitTravelDetails(widget.retreatId, details);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Travel Details Submitted Successfully."),
          backgroundColor: _primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Submission error: $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 16.0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: _primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool requiredField = false,
    TextInputType keyboardType = TextInputType.text,
    String? hintText,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    IconData? icon,
    VoidCallback? onTap,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        inputFormatters: inputFormatters,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          labelStyle: TextStyle(
            color: Colors.grey[700],
            fontSize: 14,
          ),
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
          fillColor: _cardColor,
          filled: true,
          prefixIcon: icon != null ? Icon(icon, color: _primaryColor) : null,
          suffixIcon: requiredField
              ? const Icon(Icons.star, color: Colors.red, size: 10)
              : null,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _primaryColor, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        style: const TextStyle(fontSize: 15),
        validator: requiredField
            ? (value) {
          if (value == null || value.trim().isEmpty) {
            return 'This field is required';
          }
          return null;
        }
            : null,
      ),
    );
  }

  Widget _buildDropDown({
    required String label,
    required String value,
    required Function(String?) onChanged,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey[700],
            fontSize: 14,
          ),
          fillColor: _cardColor,
          filled: true,
          prefixIcon: icon != null ? Icon(icon, color: _primaryColor) : null,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _primaryColor, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isDense: true,
            isExpanded: true,
            icon: Icon(Icons.arrow_drop_down, color: _primaryColor),
            items: const [
              DropdownMenuItem(value: 'PLANE', child: Text('Plane')),
              DropdownMenuItem(value: 'TRAIN', child: Text('Train')),
            ],
            onChanged: onChanged,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  title == 'Personal Information' ? Icons.person :
                  title == 'Arrival Details' ? Icons.flight_land :
                  title == 'Departure Details' ? Icons.flight_takeoff :
                  title == 'Passport Information' ? Icons.chrome_reader_mode :
                  Icons.comment,
                  color: _primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryColor, _accentColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          "Travel Details",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(
                    "Travel Information",
                    style: TextStyle(
                      color: _primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: const Text(
                    "To facilitate your transportation arrangements to and from the retreat center, we kindly ask you to provide accurate travel information. This is crucial for adhering to legal obligations for tourist accommodations.",
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: _primaryColor,
                      ),
                      child: const Text("OK"),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Intro card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[700], size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "To facilitate your transportation arrangements to and from the retreat center, we kindly ask you to provide us with your travel information.",
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.blue[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Personal Information Section
                _buildFormCard(
                  'Personal Information',
                  [
                    _buildTextField(
                      label: "First Name",
                      controller: _nameCtrl,
                      requiredField: true,
                      icon: Icons.person_outline,
                    ),
                    _buildTextField(
                      label: "Last Name",
                      controller: _surnameCtrl,
                      requiredField: true,
                      icon: Icons.person_outline,
                    ),
                    _buildTextField(
                      label: "Mobile Number",
                      controller: _mobileNumberCtrl,
                      keyboardType: TextInputType.phone,
                      requiredField: true,
                      icon: Icons.phone_android,
                    ),
                  ],
                ),

                // Arrival Details Section
                _buildFormCard(
                  'Arrival Details',
                  [
                    _buildDropDown(
                      label: "Method of Arrival",
                      value: _arrivalMethod,
                      icon: Icons.commute,
                      onChanged: (val) {
                        setState(() => _arrivalMethod = val ?? 'PLANE');
                      },
                    ),
                    _buildTextField(
                      label: "Flight/Train Number",
                      controller: _arrivalFlightCtrl,
                      hintText: "Leave blank if not applicable",
                      icon: _arrivalMethod == 'PLANE' ? Icons.flight : Icons.train,
                    ),
                    _buildTextField(
                      label: "Arrival Date",
                      controller: _arrivalDateCtrl,
                      requiredField: true,
                      icon: Icons.calendar_today,
                      readOnly: true,
                      onTap: () => _selectDate(context, _arrivalDateCtrl),
                    ),
                    _buildTextField(
                      label: "Arrival Time",
                      controller: _arrivalTimeCtrl,
                      requiredField: true,
                      icon: Icons.access_time,
                      readOnly: true,
                      onTap: () => _selectTime(context, _arrivalTimeCtrl),
                    ),
                  ],
                ),

                // Departure Details Section
                _buildFormCard(
                  'Departure Details',
                  [
                    _buildDropDown(
                      label: "Departure Method",
                      value: _departureMethod,
                      icon: Icons.commute,
                      onChanged: (val) {
                        setState(() => _departureMethod = val ?? 'PLANE');
                      },
                    ),
                    _buildTextField(
                      label: "Flight/Train Number",
                      controller: _departureFlightCtrl,
                      hintText: "Leave blank if not applicable",
                      icon: _departureMethod == 'PLANE' ? Icons.flight : Icons.train,
                    ),
                    _buildTextField(
                      label: "Departure Date",
                      controller: _departureDateCtrl,
                      requiredField: true,
                      icon: Icons.calendar_today,
                      readOnly: true,
                      onTap: () => _selectDate(context, _departureDateCtrl),
                    ),
                    _buildTextField(
                      label: "Departure Time",
                      controller: _departureTimeCtrl,
                      requiredField: true,
                      icon: Icons.access_time,
                      readOnly: true,
                      onTap: () => _selectTime(context, _departureTimeCtrl),
                    ),
                  ],
                ),

                // Passport Information Section
                _buildFormCard(
                  'Passport Information',
                  [
                    _buildTextField(
                      label: "Passport Number",
                      controller: _passportNumberCtrl,
                      requiredField: true,
                      icon: Icons.credit_card,
                    ),
                    _buildTextField(
                      label: "Passport Issuing Date",
                      controller: _passportIssueDateCtrl,
                      requiredField: true,
                      icon: Icons.calendar_today,
                      readOnly: true,
                      onTap: () => _selectDate(context, _passportIssueDateCtrl),
                    ),
                    _buildTextField(
                      label: "Place of Issue",
                      controller: _passportPlaceOfIssueCtrl,
                      requiredField: true,
                      icon: Icons.place,
                    ),
                    _buildTextField(
                      label: "Birth Place",
                      controller: _birthPlaceCtrl,
                      requiredField: true,
                      icon: Icons.home,
                    ),
                    _buildTextField(
                      label: "Date of Birth",
                      controller: _dobCtrl,
                      requiredField: true,
                      icon: Icons.cake,
                      readOnly: true,
                      onTap: () => _selectDate(context, _dobCtrl),
                    ),
                    _buildTextField(
                      label: "Nationality",
                      controller: _nationalityCtrl,
                      requiredField: true,
                      icon: Icons.flag,
                    ),
                  ],
                ),

                // Additional Information Section
                _buildFormCard(
                  'Additional Information',
                  [
                    _buildTextField(
                      label: "Additional Comments or Messages",
                      controller: _additionalCommentCtrl,
                      maxLines: 3,
                      icon: Icons.comment,
                      inputFormatters: [LengthLimitingTextInputFormatter(250)],
                      hintText: "Maximum 250 characters",
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "${_additionalCommentCtrl.text.length}/250",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Submit button
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: _primaryColor,
                        elevation: 5,
                        shadowColor: _primaryColor.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isSubmitting ? null : _submitTravelDetails,
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle),
                          SizedBox(width: 8),
                          Text(
                            "SUBMIT DETAILS",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}