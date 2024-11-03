import 'package:flutter/material.dart';
import '../models/onboarding_page_model.dart';

class OnboardingPagePresenter extends StatefulWidget {
  final List<OnboardingPageModel> pages;
  final VoidCallback? onSkip;
  final VoidCallback? onFinish;

  const OnboardingPagePresenter({
    Key? key,
    required this.pages,
    this.onSkip,
    this.onFinish,
  }) : super(key: key);

  @override
  State<OnboardingPagePresenter> createState() => _OnboardingPagePresenterState();
}

class _OnboardingPagePresenterState extends State<OnboardingPagePresenter> {
  int _currentPage = 0;
  final PageController _pageController = PageController(initialPage: 0);

  @override
  Widget build(BuildContext context) {
    // Determine button and indicator color based on the current page index
    Color buttonColor = _currentPage == 0 ? Colors.black : Colors.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      color: widget.pages[_currentPage].bgColor,
      child: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.pages.length,
              onPageChanged: (idx) {
                setState(() {
                  _currentPage = idx;
                });
              },
              itemBuilder: (context, idx) {
                final item = widget.pages[idx];
                return Column(
                  children: [
                    // Image that expands to full width but maintains original aspect ratio
                    item.imageAsset != null
                        ? Image.asset(
                      item.imageAsset!,
                      fit: BoxFit.fitWidth,
                      width: double.infinity, // Expands to full width
                    )
                        : Image.network(
                      item.imageUrl!,
                      fit: BoxFit.fitWidth,
                      width: double.infinity, // Expands to full width
                    ),
                    // Remaining content
                    Expanded(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              item.title,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: item.textColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Container(
                            constraints: const BoxConstraints(maxWidth: 280),
                            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                            child: Text(
                              item.description,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: item.textColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            // Page indicator
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: widget.pages
                    .asMap()
                    .map((i, _) => MapEntry(
                  i,
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: _currentPage == i ? 30 : 8,
                    height: 8,
                    margin: const EdgeInsets.all(2.0),
                    decoration: BoxDecoration(
                      color: buttonColor, // Dynamic color based on page index
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ))
                    .values
                    .toList(),
              ),
            ),
            // Navigation buttons
            Positioned(
              bottom: 10,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Skip button
                  TextButton(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.comfortable,
                      foregroundColor: buttonColor, // Dynamic color based on page index
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      if (widget.onSkip != null) {
                        widget.onSkip!();
                      } else {
                        _pageController.jumpToPage(widget.pages.length - 1);
                      }
                    },
                    child: const Text("Skip"),
                  ),
                  // Next/Finish button
                  TextButton(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.comfortable,
                      foregroundColor: buttonColor, // Dynamic color based on page index
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      if (_currentPage == widget.pages.length - 1) {
                        widget.onFinish?.call();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOutCubic,
                        );
                      }
                    },
                    child: Row(
                      children: [
                        Text(
                          _currentPage == widget.pages.length - 1 ? "Finish" : "Next",
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _currentPage == widget.pages.length - 1 ? Icons.done : Icons.arrow_forward,
                          color: buttonColor, // Dynamic icon color
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
