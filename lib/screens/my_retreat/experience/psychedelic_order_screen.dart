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

  late TextEditingController _namePseudonymCtrl;
  late TextEditingController _emailCtrl;

  String _quantity = '3'; // "3" or "4"
  bool _donationOrPaymentSelected = false;
  bool _declarationConfirmed = false;

  // Define gradient colors
  final Color _gradientColor1 = const Color(0xFF6A0DAD);
  final Color _gradientColor2 = const Color(0xFF3700B3);

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
            title: const Text("Name/Pseudonym Required"),
            content: const Text(
              "We need a name or pseudonym to identify your order. "
                  "Please fill this field before submitting.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
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
          title: const Text("Declaration Required"),
          content: const Text(
            "You must confirm you are at least 18 years old and accept the declaration.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Your order has been submitted successfully."),
      ));
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Order submission failed: $e")),
      );
    }
  }

  InputDecoration _buildInputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.grey[50],
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: _gradientColor1),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: _gradientColor2),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMushroom = widget.isMushroomOrder;

    // Title & text details
    final screenTitle = isMushroom ? "Order Mushrooms" : "Order Truffles";

    final introText = isMushroom
        ? """We’ve set up a system that allows you to place orders for these mushrooms via a designated form. A third-party partner will then manage your order, guaranteeing that it arrives at the center before you do. This setup ensures we comply with Portugal’s legal requirements, providing a secure and lawful experience for everyone involved."""
        : """We’ve set up a system that allows you to place orders for these truffles via a designated form. A third-party partner will then manage your order, ensuring it arrives at the center before you do. This setup ensures we comply with Netherlands legal requirements, providing a secure and lawful experience for everyone involved.""";

    final quantityLabel = isMushroom
        ? "I would like to request Psilocybin Mushrooms:"
        : "I would like to order High Hawaiians psilocybin truffles:";

    final option3 = isMushroom ? "3 PORTIONS (3x3g)" : "3 BOXES (3x22g)";
    final option4 = isMushroom ? "4 PORTIONS (4x3g)" : "4 BOXES (4x22g)";

    final dosageInfo = isMushroom
        ? """We suggest 3 portions of Golden Teacher mushrooms, as this amount usually provides a medium dose for the first ceremony and a high dose for the second ceremony, which is adequate for most participants. However, if you're an experienced psychonaut and know that you usually require a larger amount, ordering 4 portions might be a better choice. This variation in quantity is due to the fact that some individuals have brain receptors that are less responsive to psilocybin, thus requiring more to achieve the desired effect."""
        : """We suggest buying 3 boxes of High Hawaiians truffles, as this amount usually provides a medium dose for the first ceremony and a high dose for the second ceremony, which is adequate for most participants. However, if you're an experienced psychonaut and know that you usually require a larger amount, ordering 4 boxes might be a better choice. This variation in quantity is due to the fact that some individuals have brain receptors that are less responsive to psilocybin, thus requiring more to achieve the desired effect.""";

    final donationOrPaymentHeading = isMushroom ? "Donation" : "Payment";
    final donationOrPaymentExplanation = isMushroom
        ? "We suggest €25 per portion, or its equivalent, in cash."
        : "We suggest €25 per box, or its equivalent, in cash.";

    final declarationText = isMushroom
        ? """I CONFIRM THAT I AM 18 YEARS OR OLDER AND I WILL CONSUME THESE PSILOCYBIN MUSHROOMS ON MY OWN ACCORD. THEY ARE EXCLUSIVELY FOR MY PERSONAL USE. I WILL PREPARE AND CONSUME THEM IN ACCORDANCE WITH LEGAL GUIDELINES. I AM AWARE THAT NUMINOUS WAYS DOES NOT SUPPLY THESE MUSHROOMS."""
        : """I CONFIRM THAT I AM 18 YEARS OR OLDER AND AM PURCHASING THESE PSILOCYBIN TRUFFLES ON MY OWN ACCORD, EXCLUSIVELY FOR MY PERSONAL USE. I WILL PREPARE AND CONSUME THEM IN ACCORDANCE WITH LEGAL GUIDELINES. I AM AWARE THAT NUMINOUS WAYS DOES NOT SUPPLY THESE TRUFFLES.""";

    final submitButtonText = "PLACE YOUR ORDER";

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
        title: Text(
          screenTitle,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Form(
            key: _formKey,
            child: Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Intro text
                    Text(
                      introText,
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                    const SizedBox(height: 20),

                    // NAME/PSEUDONYM
                    TextFormField(
                      controller: _namePseudonymCtrl,
                      decoration: _buildInputDecoration(
                        "Name/Pseudonym *",
                        "No need for your full name. We'll use this to identify your order.",
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Name/Pseudonym is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // EMAIL (OPTIONAL)
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: _buildInputDecoration(
                        "Email",
                        "If you'd like to receive a confirmation, please provide your email.",
                      ),
                    ),
                    const SizedBox(height: 24),

                    // QUANTITY SELECTION
                    Text(
                      quantityLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    RadioListTile<String>(
                      title: Text(option3),
                      value: '3',
                      groupValue: _quantity,
                      onChanged: (val) {
                        setState(() => _quantity = val ?? '3');
                      },
                      activeColor: _gradientColor1,
                    ),
                    RadioListTile<String>(
                      title: Text(option4),
                      value: '4',
                      groupValue: _quantity,
                      onChanged: (val) {
                        setState(() => _quantity = val ?? '3');
                      },
                      activeColor: _gradientColor1,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      dosageInfo,
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                    const SizedBox(height: 24),

                    // DONATION OR PAYMENT
                    Text(
                      donationOrPaymentHeading,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      donationOrPaymentExplanation,
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      title: Text(
                        isMushroom
                            ? "I WOULD LIKE TO MAKE A DONATION AT THE RETREAT CENTER."
                            : "I agree to pay at the retreat center.",
                      ),
                      activeColor: _gradientColor1,
                      value: _donationOrPaymentSelected,
                      onChanged: (val) {
                        setState(() => _donationOrPaymentSelected = val ?? false);
                      },
                    ),
                    const SizedBox(height: 24),

                    // DECLARATION
                    const Text(
                      "Your declaration *",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      declarationText,
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      title: const Text("I confirm the declaration above."),
                      activeColor: _gradientColor1,
                      value: _declarationConfirmed,
                      onChanged: (val) {
                        setState(() => _declarationConfirmed = val ?? false);
                      },
                    ),
                    const SizedBox(height: 24),

                    // SUBMIT BUTTON WITH GRADIENT
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
                          onPressed: _submitOrder,
                          child: Text(
                            submitButtonText,
                            style: const TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
