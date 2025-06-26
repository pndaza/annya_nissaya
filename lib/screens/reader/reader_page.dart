import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_pdf_viewer/just_pdf_viewer.dart';

import 'reader_appbar.dart';
import 'reader_view_controller.dart';

class ReaderPage extends ConsumerWidget {
  final String id;
  final String? name;
  final int pageNumber;

  const ReaderPage({super.key, required this.id, this.name, this.pageNumber = 1});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdfController = PdfController(initialPage: pageNumber);

    return ColoredBox(
      color: Theme.of(context).brightness == Brightness.light
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.surface,
      child: SafeArea(
        bottom: false,
        child: Scaffold(
          appBar: ReaderAppBar(
            bookID: id,
            bookName: name,
          ),
          body: GestureDetector(
            onTap: () {
              ref.read(readerViewController).toggleFullScreenMode();
            },
            child: Consumer(
              builder: (context, watch, child) {
                final scrollDirection = ref.watch(scrollDirectionProvider);
                final colorMode = ref.watch(pdfColorModeProvider);
                return JustPdfViewer(
                  onPageChanged: (pageIndex) {
                    EasyDebounce.debounce(
                        'page_changed', const Duration(milliseconds: 500), () {
                      ref
                          .read(readerViewController)
                          .onPageChanged(nsyBookId: id, pageIndex: pageIndex);
                    });
                  },
                  assetPath: 'assets/books/pdf/$id.pdf',
                  scrollDirection: scrollDirection,
                  pdfController: pdfController,
                  colorMode: colorMode,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
