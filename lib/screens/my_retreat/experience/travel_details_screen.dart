import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/experience/travel_details.dart';
import '../../../services/retreat_service.dart';
import 'package:flutter/services.dart'; // For input formatters

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

  // Define gradient colors
  final Color _gradientColor1 = const Color(0xFF6A0DAD);
  final Color _gradientColor2 = const Color(0xFF3700B3);

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
    super.dispose();
  }

  Future<void> _submitTravelDetails() async {
    // Check form validation
    if (!_formKey.currentState!.validate()) {
      // If validation fails, show a custom dialog
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Missing Required Fields"),
          content: const Text(
            "Some required fields are missing or invalid. "
                "Please fill them before submitting.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

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
        const SnackBar(content: Text("Travel Details Submitted Successfully.")),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Submission error: $e")),
      );
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool requiredField = false,
    TextInputType keyboardType = TextInputType.text,
    String? hintText,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          fillColor: Colors.white,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: _gradientColor1),
          ),
        ),
        validator: requiredField
            ? (value) {
          if (value == null || value.trim().isEmpty) {
            return '$label is required';
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
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          fillColor: Colors.white,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: _gradientColor1),
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isDense: true,
            items: const [
              DropdownMenuItem(value: 'PLANE', child: Text('PLANE')),
              DropdownMenuItem(value: 'TRAIN', child: Text('TRAIN')),
            ],
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_gradientColor1, _gradientColor2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          "Your Travel Details Form",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Intro text
                const Text(
                  "To facilitate your transportation arrangements to and from the retreat center, we kindly ask you to provide us with your travel information. Sharing these details is crucial for adhering to the legal obligations imposed by the authorities on tourist accommodations.",
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Name / Surname / Mobile
                _buildTextField(
                  label: "NAME",
                  controller: _nameCtrl,
                  requiredField: true,
                ),
                _buildTextField(
                  label: "SURNAME",
                  controller: _surnameCtrl,
                  requiredField: true,
                ),
                _buildTextField(
                  label: "MOBILE NUMBER",
                  controller: _mobileNumberCtrl,
                  keyboardType: TextInputType.phone,
                  requiredField: true,
                ),

                // ARRIVAL
                _buildDropDown(
                  label: "Method of Arrival",
                  value: _arrivalMethod,
                  onChanged: (val) {
                    setState(() => _arrivalMethod = val ?? 'PLANE');
                  },
                ),
                _buildTextField(
                  label: "ARRIVAL FLIGHT NUMBER",
                  controller: _arrivalFlightCtrl,
                  hintText: "Leave blank if not applicable",
                ),
                _buildTextField(
                  label: "ARRIVAL DATE AT AIRPORT OR RAILWAY STATION",
                  controller: _arrivalDateCtrl,
                  requiredField: true,
                ),
                _buildTextField(
                  label: "ARRIVAL TIME AT AIRPORT OR RAILWAY STATION",
                  controller: _arrivalTimeCtrl,
                  requiredField: true,
                ),

                // DEPARTURE
                _buildDropDown(
                  label: "Departure Method",
                  value: _departureMethod,
                  onChanged: (val) {
                    setState(() => _departureMethod = val ?? 'PLANE');
                  },
                ),
                _buildTextField(
                  label: "DEPARTURE FLIGHT NUMBER",
                  controller: _departureFlightCtrl,
                  hintText: "Leave blank if not applicable",
                ),
                _buildTextField(
                  label: "DEPARTURE DATE FROM AIRPORT OR RAILWAY STATION",
                  controller: _departureDateCtrl,
                  requiredField: true,
                ),
                _buildTextField(
                  label: "DEPARTURE TIME FROM AIRPORT OR RAILWAY STATION",
                  controller: _departureTimeCtrl,
                  requiredField: true,
                ),

                // PASSPORT
                _buildTextField(
                  label: "PASSPORT NUMBER",
                  controller: _passportNumberCtrl,
                  requiredField: true,
                ),
                _buildTextField(
                  label: "PASSPORT - ISSUING DATE",
                  controller: _passportIssueDateCtrl,
                  requiredField: true,
                ),
                _buildTextField(
                  label: "PASSPORT - PLACE OF ISSUE",
                  controller: _passportPlaceOfIssueCtrl,
                  requiredField: true,
                ),
                _buildTextField(
                  label: "BIRTH PLACE",
                  controller: _birthPlaceCtrl,
                  requiredField: true,
                ),
                _buildTextField(
                  label: "DOB",
                  controller: _dobCtrl,
                  requiredField: true,
                ),
                _buildTextField(
                  label: "NATIONALITY",
                  controller: _nationalityCtrl,
                  requiredField: true,
                ),

                // Additional Comment with max length 250 characters
                _buildTextField(
                  label: "ADDITIONAL COMMENT OR MESSAGE",
                  controller: _additionalCommentCtrl,
                  maxLines: 3,
                  inputFormatters: [LengthLimitingTextInputFormatter(250)],
                ),

                const SizedBox(height: 20),

                // Submit button with gradient background
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_gradientColor1, _gradientColor2],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _submitTravelDetails,
                      child: const Text(
                        "SUBMIT",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
