import 'package:flutter/material.dart';
import '/../models/content_report.dart';
import '/../services/reporting_service.dart';
import 'package:provider/provider.dart';
import '/../services/login_provider.dart';

class ReportContentDialog extends StatefulWidget {
  final String contentId;
  final String contentType; // 'post' or 'comment'
  final String reportedUserId;

  const ReportContentDialog({
    Key? key,
    required this.contentId,
    required this.contentType,
    required this.reportedUserId,
  }) : super(key: key);

  @override
  _ReportContentDialogState createState() => _ReportContentDialogState();
}

class _ReportContentDialogState extends State<ReportContentDialog> {
  final ReportingService _reportingService = ReportingService();
  ReportReason _selectedReason = ReportReason.inappropriate;
  final TextEditingController _commentsController = TextEditingController();
  bool _isSubmitting = false;
  bool _hasAlreadyReported = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyReported();
  }

  Future<void> _checkIfAlreadyReported() async {
    final loginProvider = Provider.of<LoginProvider>(context, listen: false);
    final currentUserId = loginProvider.userId;

    if (currentUserId != null) {
      try {
        final hasReported = await _reportingService.hasUserReportedContent(
          currentUserId,
          widget.contentId,
          widget.contentType,
        );

        if (mounted) {
          setState(() {
            _hasAlreadyReported = hasReported;
          });
        }
      } catch (e) {
        // Handle error silently
        print('Error checking report status: $e');
      }
    }
  }

  Future<void> _submitReport() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final loginProvider = Provider.of<LoginProvider>(context, listen: false);
    final currentUserId = loginProvider.userId;

    if (currentUserId == null) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'You must be logged in to report content.';
      });
      return;
    }

    try {
      await _reportingService.submitReport(
        contentId: widget.contentId,
        contentType: widget.contentType,
        reportedBy: currentUserId,
        reportedUserId: widget.reportedUserId,
        reason: _selectedReason,
        additionalComments: _commentsController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop(true); // Success
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Failed to submit report. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: _buildDialogContent(context),
    );
  }

  Widget _buildDialogContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10.0,
            offset: Offset(0.0, 10.0),
          ),
        ],
      ),
      child: _hasAlreadyReported
          ? _buildAlreadyReportedContent()
          : _buildReportForm(),
    );
  }

  Widget _buildAlreadyReportedContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 60,
        ),
        const SizedBox(height: 16),
        const Text(
          'You\'ve already reported this content',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Our moderation team will review this content as soon as possible.',
          style: TextStyle(fontSize: 14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Close',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6A0DAD),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReportForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.flag,
              color: Color(0xFF6A0DAD),
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Report Content',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Why are you reporting this content?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildReasonDropdown(),
        const SizedBox(height: 16),
        const Text(
          'Additional comments (optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildCommentsField(),
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 14,
            ),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _isSubmitting
                  ? null
                  : () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A0DAD),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Text(
                'Submit Report',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReasonDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ReportReason>(
          isExpanded: true,
          value: _selectedReason,
          onChanged: (ReportReason? value) {
            if (value != null) {
              setState(() {
                _selectedReason = value;
              });
            }
          },
          items: ReportReason.values.map((ReportReason reason) {
            return DropdownMenuItem<ReportReason>(
              value: reason,
              child: Text(reason.displayName),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCommentsField() {
    return TextField(
      controller: _commentsController,
      maxLines: 3,
      maxLength: 500,
      decoration: InputDecoration(
        hintText: 'Provide any additional details...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF6A0DAD)),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }
}