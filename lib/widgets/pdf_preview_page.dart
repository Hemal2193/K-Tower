import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:k_tower/services/pdf_service.dart';

class PdfPreviewPage extends StatefulWidget {
  final File pdfFile;
  final String title;
  final String shareSubject;

  const PdfPreviewPage({
    super.key,
    required this.pdfFile,
    required this.title,
    required this.shareSubject,
  });

  @override
  State<PdfPreviewPage> createState() => _PdfPreviewPageState();
}

class _PdfPreviewPageState extends State<PdfPreviewPage> {
  final PdfService _pdfService = PdfService();
  bool _isLoading = true;
  PDFViewController? _pdfViewController;
  int _pageCount = 0;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    // We don't need to load the PDF here since PDFView handles it
    _isLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurpleAccent,
        foregroundColor: Colors.white,
        actions: [
          // Share button in app bar
          IconButton(
            onPressed: () {
              _pdfService.sharePdf(widget.pdfFile, widget.shareSubject);
            },
            icon: const Icon(Icons.share, color: Colors.white),
            tooltip: 'Share PDF',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // PDF View
          PDFView(
            filePath: widget.pdfFile.path,
            enableAntialiasing: true,
            enableRenderDuringScale: true,
            autoSpacing: true,
            enableSwipe: true,
            pageSnap: true,
            swipeHorizontal: true,
            nightMode: false,
            fitPolicy: FitPolicy.BOTH, // Fit both width and height
            defaultPage: 0,
            preventLinkNavigation: false, // Allow links if any
            pageFling: true, // Enable page fling animation
            fitEachPage: true, // Fit each page to screen
            onError: (error) {
              setState(() {
                _isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error loading PDF: $error')),
              );
            },
            onPageError: (page, error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error loading page $page: $error')),
              );
            },
            onViewCreated: (PDFViewController pdfViewController) {
              setState(() {
                _pdfViewController = pdfViewController;
                _isLoading = false;
              });
            },
            onRender: (pages) {
              if (!mounted) {
                return;
              }

              setState(() {
                _pageCount = pages ?? 0;
                _isLoading = false;
              });
            },
            onPageChanged: (page, total) {
              if (!mounted) {
                return;
              }

              setState(() {
                _currentPage = page ?? 0;
                _pageCount = total ?? _pageCount;
              });
            },
          ),

          // Loading indicator
          if (_isLoading) const Center(child: CircularProgressIndicator()),

          if (_pageCount > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 18,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Swipe left or right',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pageCount, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 18 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.deepPurpleAccent
                              : Colors.white70,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pdfViewController?.dispose();
    super.dispose();
  }
}
