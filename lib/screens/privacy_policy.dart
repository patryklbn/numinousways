import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Define theme colors to match travel details screen
    final Color primaryColor = const Color(0xFF6A0DAD);
    final Color accentColor = const Color(0xFF3700B3);
    final Color backgroundColor = const Color(0xFFF8F9FA);
    final Color cardColor = Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, accentColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          "Privacy Policy",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
                        "This policy explains how we collect, use, and protect your personal information. We are committed to ensuring the security and privacy of your data.",
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

              const SizedBox(height: 24),

              // Policy Sections
              _buildPolicySection(
                title: 'Data We Collect',
                icon: Icons.data_usage,
                content: [
                  "• Personal Information: Name, email, and profile data to create and manage your account.",
                  "• Travel Details: Including passport information, arrival and departure details required for retreat arrangements.",
                  "• Retreat Participation: Information about your retreat experiences and preferences.",
                  "• Mushroom/Truffle Orders: Information related to any mushroom/truffle orders you place through our system.",
                  "• Assessment Forms: Responses to the Psychedelic Preparedness Scale (PPS) and Mystical Experience Questionnaire (MEQ-30).",
                  "• Feedback: Responses to our post-retreat feedback forms."
                ],
                cardColor: cardColor,
                primaryColor: primaryColor,
              ),

              _buildPolicySection(
                title: 'Travel Details & Passport Information',
                icon: Icons.flight,
                content: [
                  "In order to arrange your transportation to and from the retreat center, we collect your travel details. This information is essential to comply with the legal requirements set by the Portuguese administration regarding tourists and their accommodation.",
                  "",
                  "• We store this data securely in our Firebase database with access restricted to administrators only.",
                  "• This data is automatically deleted 90 days after the retreat has concluded.",
                  "• Upon request, we can immediately delete this information after the retreat.",

                ],
                cardColor: cardColor,
                primaryColor: primaryColor,
              ),

              _buildPolicySection(
                title: 'Mushroom/Truffle Orders',
                icon: Icons.spa,
                content: [
                  "We've set up a system that allows you to place orders for mushrooms/truffles via a designated form. A third-party partner will manage your order, ensuring it arrives at the center before you do. This setup complies with legal requirements.",
                  "",
                  "• You may use a pseudonym rather than your full name for these orders.",
                  "• Email is collected only for order confirmation purposes.",
                  "• Your order declaration confirms you are 18+ and will consume these products according to legal guidelines.",
                  "• Order information is deleted 90 days after the retreat concludes.",
                  "• Your declaration data is stored securely and is only accessible to administrators.",
                  "• Numinous Ways does not supply these mushrooms."
                ],
                cardColor: cardColor,
                primaryColor: primaryColor,
              ),

              _buildPolicySection(
                title: 'Assessment Forms (PPS & MEQ-30)',
                icon: Icons.assignment,
                content: [
                  "As part of the retreat experience, we collect assessment data through two standardized questionnaires:",
                  "",
                  "• Psychedelic Preparedness Scale (PPS): Collected before the preparation course and after completion to assess readiness.",
                  "• Mystical Experience Questionnaire (MEQ-30): Gathered after the retreat to capture your experience.",
                  "",
                  "This data helps us improve our programs and understand your experience. All responses are:",
                  "• Stored securely in our database",
                  "• Accessible only to retreat administrators",
                  "• May be used in anonymized, aggregated form for research purposes",
                  "• Deleted upon request"
                ],
                cardColor: cardColor,
                primaryColor: primaryColor,
              ),

              _buildPolicySection(
                title: 'Feedback Data',
                icon: Icons.feedback,
                content: [
                  "After the retreat, we collect feedback about your experience. This includes ratings and comments on:",
                  "",
                  "• Overall experience",
                  "• Feeling of security and support",
                  "• Small group experiences",
                  "• Facilitation team performance",
                  "• Balance of activities",
                  "• Accommodations and facilities",
                  "• Suggestions for improvement",
                  "",
                  "This feedback is used to improve future retreats and is:",
                  "• Stored securely with access limited to administrators",
                  "• May be used in anonymized form for promotional purposes",
                  "• Deleted upon request"
                ],
                cardColor: cardColor,
                primaryColor: primaryColor,
              ),

              _buildPolicySection(
                title: 'How We Use Your Data',
                icon: Icons.assignment,
                content: [
                  "• To facilitate your participation in retreats",
                  "• To comply with legal requirements for tourist accommodations",
                  "• To arrange transportation and logistics",
                  "• To process your mushroom/truffle orders through third-party partners",
                  "• To assess and improve our preparation and integration programs",
                  "• To enhance future retreats based on participant feedback",
                  "• To improve our services and your experience"
                ],
                cardColor: cardColor,
                primaryColor: primaryColor,
              ),

              _buildPolicySection(
                title: 'Data Security',
                icon: Icons.security,
                content: [
                  "• All data is stored securely in Firebase with strict access controls",
                  "• Only authorized administrators can access sensitive information",
                  "• We regularly review and update our security practices"
                ],
                cardColor: cardColor,
                primaryColor: primaryColor,
              ),

              _buildPolicySection(
                title: 'Data Retention & Deletion',
                icon: Icons.delete_outline,
                content: [
                  "• All sensitive information (travel details, passport data, psychedelic orders) is automatically deleted 90 days after the retreat ends",
                  "• You can request immediate deletion of your data at any time by contacting our administrators",
                  "• When you request account deletion, all your personal data will be removed from our systems",

                ],
                cardColor: cardColor,
                primaryColor: primaryColor,
              ),

              _buildPolicySection(
                title: 'Account Deletion',
                icon: Icons.person_remove,
                content: [
                  "You can delete your account directly from the Edit Profile section.",
                  "When you delete your account, all your associated data will be permanently removed from our system. This includes:",
                  "• Your personal information",
                  "• Travel details",
                  "• Passport data",
                  "• Psychedelic orders",
                  "• AI-generated images",
                  "",
                  "Please note that this action is irreversible."
                ],
                cardColor: cardColor,
                primaryColor: primaryColor,
              ),


              _buildPolicySection(
                title: 'Your Rights',
                icon: Icons.gavel,
                content: [
                  "You have the right to:",
                  "• Access your personal data",
                  "• Correct inaccurate data",
                  "• Request deletion of your data",
                  "• Withdraw consent for data processing",
                  "• Request a copy of your data",

                ],
                cardColor: cardColor,
                primaryColor: primaryColor,
              ),

              _buildPolicySection(
                title: 'Contact Us',
                icon: Icons.contact_mail,
                content: [
                  "If you have any questions about this Privacy Policy or would like to exercise your rights regarding your personal data, please contact us at:",
                  "",
                  "info@numinousways.com"
                ],
                cardColor: cardColor,
                primaryColor: primaryColor,
              ),

              const SizedBox(height: 24),

              // Last updated
              Center(
                child: Text(
                  "Last Updated: February 2025",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPolicySection({
    required String title,
    required IconData icon,
    required List<String> content,
    required Color cardColor,
    required Color primaryColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cardColor,
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
              color: primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: content.map((text) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}