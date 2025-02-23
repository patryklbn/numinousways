import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/retreat_service.dart';
import '../../../models/experience/psychedelic_order.dart';

class PsychedelicOrderScreen extends StatefulWidget {
  final String retreatId;
  final String userId;        // Who is placing the order
  final bool isMushroomOrder; // True = mushrooms, false = truffles

  const PsychedelicOrderScreen({
    Key? key,
    required this.retreatId,
    required this.userId,
    required this.isMushroomOrder,
  }) : super(key: key);

  @override
  State<PsychedelicOrderScreen> createState() => _PsychedelicOrderScreenState();
}

class _PsychedelicOrderScreenState extends State<PsychedelicOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  late TextEditingController _namePseudonymCtrl;
  late TextEditingController _emailCtrl;

  String _quantity = '3'; // "3" or "4"
  bool _donationOrPaymentSelected = false;
  bool _declarationConfirmed = false;

  // Theme colors
  final Color _primaryColor = const Color(0xFF6A0DAD);
  final Color _accentColor = const Color(0xFF3700B3);
  final Color _backgroundColor = const Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    _namePseudonymCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _namePseudonymCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    // 1) Check form validation
    final isValid = _formKey.currentState!.validate();

    // If the form is invalid, see if the name field is empty
    if (!isValid) {
      if (_namePseudonymCtrl.text.trim().isEmpty) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              "Name/Pseudonym Required",
              style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
            ),
            content: const Text(
              "We need a name or pseudonym to identify your order. "
                  "Please fill this field before submitting.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                style: TextButton.styleFrom(foregroundColor: _primaryColor),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
      return;
    }

    // 2) Check if user has confirmed the declaration
    if (!_declarationConfirmed) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Declaration Required",
            style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "You must confirm you are at least 18 years old and accept the declaration.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(foregroundColor: _primaryColor),
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

    // 3) Build the order model
    final newOrder = PsychedelicOrder(
      userId: widget.userId,
      isMushroomOrder: widget.isMushroomOrder,
      namePseudonym: _namePseudonymCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      quantity: _quantity,
      donationOrPaymentSelected: _donationOrPaymentSelected,
      declarationConfirmed: _declarationConfirmed,
    );

    try {
      // 4) Submit to Firestore
      final retreatService = Provider.of<RetreatService>(context, listen: false);
      await retreatService.submitPsychedelicOrder(widget.retreatId, newOrder);

      // 5) Show success message and pop
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Your order has been submitted successfully."),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          backgroundColor: Colors.green[700],
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Order submission failed: $e"),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          backgroundColor: Colors.red[700],
        ),
      );
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  InputDecoration _buildInputDecoration(String label, String hint, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.grey[50],
      prefixIcon: icon != null ? Icon(icon, color: _primaryColor) : null,
      labelStyle: TextStyle(
        color: Colors.grey[700],
        fontSize: 14,
      ),
      hintStyle: TextStyle(
        color: Colors.grey[400],
        fontSize: 14,
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: _primaryColor, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildSectionHeader(String title, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 12.0),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: _primaryColor, size: 20),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String text, {Color? backgroundColor, Color? borderColor}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor ?? Colors.blue[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF444444),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMushroom = widget.isMushroomOrder;

    // Title & text details
    final screenTitle = isMushroom ? "Order Mushrooms" : "Order Truffles";
    final productType = isMushroom ? "mushrooms" : "truffles";
    final location = isMushroom ? "Portugal" : "Netherlands";

    final introText =
    """We've set up a system that allows you to place orders for these $productType via a designated form. A third-party partner will then manage your order, ${isMushroom ? "guaranteeing" : "ensuring"} that it arrives at the center before you do. This setup ensures we comply with $location's legal requirements, providing a secure and lawful experience for everyone involved.""";

    final quantityLabel = isMushroom
        ? "I would like to request Psilocybin Mushrooms:"
        : "I would like to order High Hawaiians psilocybin truffles:";

    final option3 = isMushroom ? "3 PORTIONS (3x3g)" : "3 BOXES (3x22g)";
    final option4 = isMushroom ? "4 PORTIONS (4x3g)" : "4 BOXES (4x22g)";

    final item = isMushroom ? "portions" : "boxes";
    final itemType = isMushroom ? "Golden Teacher mushrooms" : "High Hawaiians truffles";

    final dosageInfo =
    """We suggest $item of $itemType, as this amount usually provides a medium dose for the first ceremony and a high dose for the second ceremony, which is adequate for most participants. However, if you're an experienced psychonaut and know that you usually require a larger amount, ordering 4 $item might be a better choice. This variation in quantity is due to the fact that some individuals have brain receptors that are less responsive to psilocybin, thus requiring more to achieve the desired effect.""";

    final donationOrPaymentHeading = isMushroom ? "Donation" : "Payment";
    final donationOrPaymentExplanation = "We suggest €25 per ${isMushroom ? "portion" : "box"}, or its equivalent, in cash.";

    final consentText = isMushroom
        ? "I WOULD LIKE TO MAKE A DONATION AT THE RETREAT CENTER."
        : "I agree to pay at the retreat center.";

    final declarationText = isMushroom
        ? """I CONFIRM THAT I AM 18 YEARS OR OLDER AND I WILL CONSUME THESE PSILOCYBIN MUSHROOMS ON MY OWN ACCORD. THEY ARE EXCLUSIVELY FOR MY PERSONAL USE. I WILL PREPARE AND CONSUME THEM IN ACCORDANCE WITH LEGAL GUIDELINES. I AM AWARE THAT NUMINOUS WAYS DOES NOT SUPPLY THESE MUSHROOMS."""
        : """I CONFIRM THAT I AM 18 YEARS OR OLDER AND AM PURCHASING THESE PSILOCYBIN TRUFFLES ON MY OWN ACCORD, EXCLUSIVELY FOR MY PERSONAL USE. I WILL PREPARE AND CONSUME THEM IN ACCORDANCE WITH LEGAL GUIDELINES. I AM AWARE THAT NUMINOUS WAYS DOES NOT SUPPLY THESE TRUFFLES.""";

    final submitButtonText = "PLACE YOUR ORDER";

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
        title: Text(
          screenTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Introduction card
                _buildInfoCard(introText),

                // Personal details section
                _buildSectionHeader("Personal Details", icon: Icons.person_outline),

                // NAME/PSEUDONYM
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: TextFormField(
                    controller: _namePseudonymCtrl,
                    decoration: _buildInputDecoration(
                      "Name/Pseudonym *",
                      "No need for your full name",
                      icon: Icons.badge_outlined,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Name/Pseudonym is required';
                      }
                      return null;
                    },
                  ),
                ),

                // EMAIL (OPTIONAL)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _buildInputDecoration(
                      "Email (Optional)",
                      "For order confirmation",
                      icon: Icons.email_outlined,
                    ),
                  ),
                ),

                // QUANTITY SELECTION
                _buildSectionHeader("Order Details", icon: Icons.shopping_bag_outlined),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quantityLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Option 3
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _quantity == '3' ? _primaryColor : Colors.grey[300]!,
                            width: _quantity == '3' ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: _quantity == '3' ? _primaryColor.withOpacity(0.05) : Colors.white,
                        ),
                        child: RadioListTile<String>(
                          title: Text(
                            option3,
                            style: TextStyle(
                              fontWeight: _quantity == '3' ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          value: '3',
                          groupValue: _quantity,
                          onChanged: (val) {
                            setState(() => _quantity = val ?? '3');
                          },
                          activeColor: _primaryColor,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Option 4
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _quantity == '4' ? _primaryColor : Colors.grey[300]!,
                            width: _quantity == '4' ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: _quantity == '4' ? _primaryColor.withOpacity(0.05) : Colors.white,
                        ),
                        child: RadioListTile<String>(
                          title: Text(
                            option4,
                            style: TextStyle(
                              fontWeight: _quantity == '4' ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          value: '4',
                          groupValue: _quantity,
                          onChanged: (val) {
                            setState(() => _quantity = val ?? '3');
                          },
                          activeColor: _primaryColor,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Dosage info
                      Text(
                        dosageInfo,
                        style: const TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF444444)),
                      ),
                    ],
                  ),
                ),

                // DONATION OR PAYMENT
                _buildSectionHeader(donationOrPaymentHeading, icon: Icons.payments_outlined),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        donationOrPaymentExplanation,
                        style: const TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF444444)),
                      ),
                      const SizedBox(height: 16),

                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _donationOrPaymentSelected
                                ? _primaryColor
                                : Colors.grey[300]!,
                            width: _donationOrPaymentSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: _donationOrPaymentSelected
                              ? _primaryColor.withOpacity(0.05)
                              : Colors.white,
                        ),
                        child: CheckboxListTile(
                          title: Text(
                            consentText,
                            style: TextStyle(
                              fontWeight: _donationOrPaymentSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                          activeColor: _primaryColor,
                          value: _donationOrPaymentSelected,
                          onChanged: (val) {
                            setState(() => _donationOrPaymentSelected = val ?? false);
                          },
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // DECLARATION
                _buildSectionHeader("Legal Declaration", icon: Icons.gavel),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          declarationText,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: Color(0xFF444444),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _declarationConfirmed
                                ? _primaryColor
                                : Colors.grey[300]!,
                            width: _declarationConfirmed ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: _declarationConfirmed
                              ? _primaryColor.withOpacity(0.05)
                              : Colors.white,
                        ),
                        child: CheckboxListTile(
                          title: Text(
                            "I confirm the declaration above",
                            style: TextStyle(
                              fontWeight: _declarationConfirmed
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                          activeColor: _primaryColor,
                          value: _declarationConfirmed,
                          onChanged: (val) {
                            setState(() => _declarationConfirmed = val ?? false);
                          },
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // SUBMIT BUTTON
                SizedBox(
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
                    onPressed: _isSubmitting ? null : _submitOrder,
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shopping_cart),
                        const SizedBox(width: 8),
                        Text(
                          submitButtonText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
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