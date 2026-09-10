import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../features/customer/domain/entities/warranty_entity.dart';

class WarrantyCardPdfService {
  static const PdfColor primaryBlue = PdfColor.fromInt(0xFF2F5597);
  static const PdfColor darkTitleBlue = PdfColor.fromInt(0xFF1F497D);
  static const PdfColor borderColor = PdfColor.fromInt(0xFFD0D7DE);
  static const PdfColor textColor = PdfColor.fromInt(0xFF222222);
  static const PdfColor subtextColor = PdfColor.fromInt(0xFF555555);

  /// Determine if product is LF Inverter
  static bool _isLFInverter(WarrantyEntity warranty) {
    final name = (warranty.product?.name ?? '').toLowerCase();
    final cat = (warranty.product?.category ?? '').toLowerCase();
    return name.contains('lf') || (cat.contains('inverter') && !name.contains('pulse'));
  }

  /// Determine if product is Pulse Battery
  static bool _isPulseBattery(WarrantyEntity warranty) {
    final name = (warranty.product?.name ?? '').toLowerCase();
    final cat = (warranty.product?.category ?? '').toLowerCase();
    return name.contains('pulse') || cat.contains('battery');
  }

  /// Get Validity Period text according to exact specifications
  static String getValidityPeriodText(WarrantyEntity warranty) {
    if (_isPulseBattery(warranty)) {
      return 'Warranty is applicable for 5 years on the LFP battery cells and electrical components';
    }
    if (_isLFInverter(warranty)) {
      return 'Warranty is applicable for 2 years on Inverter internal components and 5 years on the LFP battery';
    }
    // Generic fallback based on product warranty months
    final months = warranty.product?.warrantyMonths ?? 24;
    return 'Warranty is applicable for $months months from the date of registration under standard operating conditions.';
  }

  /// Get Total Warranty Period display string
  static String getTotalWarrantyPeriodText(WarrantyEntity warranty) {
    if (_isPulseBattery(warranty)) {
      return '5 Years (LFP Battery Cells & Electrical Components)';
    }
    if (_isLFInverter(warranty)) {
      return '2 Years (Inverter) / 5 Years (LFP Battery)';
    }
    final months = warranty.product?.warrantyMonths ?? 24;
    final years = (months / 12).round();
    return '$years Years ($months Months)';
  }

  /// Generate raw PDF bytes matching the official Index template
  static Future<Uint8List> generateWarrantyCardPdf({
    required WarrantyEntity warranty,
    String? customerName,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');

    // Load authentic assets
    pw.MemoryImage? logoImage;
    pw.MemoryImage? signatureImage;

    try {
      final logoBytes = await rootBundle.load('assets/images/warranty_logo.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (e) {
      debugPrint('Error loading logo asset: $e');
    }

    try {
      final sigBytes = await rootBundle.load('assets/images/warranty_signature.png');
      signatureImage = pw.MemoryImage(sigBytes.buffer.asUint8List());
    } catch (e) {
      debugPrint('Error loading signature asset: $e');
    }

    // Resolve details
    final resolvedCustomerName = customerName?.trim().isNotEmpty == true
        ? customerName!.trim()
        : (warranty.customerName?.trim().isNotEmpty == true
            ? warranty.customerName!.trim()
            : 'Valued Customer');

    final productName = warranty.product?.name ??
        warranty.serialNumber?.productName ??
        (_isLFInverter(warranty) ? 'Index Solar Inverter LF Series' : 'Index Solar Product');

    final serialNumber = warranty.serialNumber?.serialNumber ?? 'N/A';

    final startDate = dateFormat.format(warranty.purchaseDate ?? warranty.registrationDate);

    // Calculate end date
    DateTime endDate;
    if (warranty.batteryWarrantyExpiry != null && warranty.boardWarrantyExpiry != null) {
      endDate = warranty.batteryWarrantyExpiry!.isAfter(warranty.boardWarrantyExpiry!)
          ? warranty.batteryWarrantyExpiry!
          : warranty.boardWarrantyExpiry!;
    } else if (warranty.batteryWarrantyExpiry != null) {
      endDate = warranty.batteryWarrantyExpiry!;
    } else if (warranty.boardWarrantyExpiry != null) {
      endDate = warranty.boardWarrantyExpiry!;
    } else {
      final months = warranty.product?.warrantyMonths ?? (_isLFInverter(warranty) ? 60 : 24);
      final start = warranty.purchaseDate ?? warranty.registrationDate;
      endDate = DateTime(start.year + (months ~/ 12), start.month + (months % 12), start.day);
    }
    final formattedEndDate = dateFormat.format(endDate);

    final totalWarrantyPeriod = getTotalWarrantyPeriodText(warranty);
    final validityPeriodText = getValidityPeriodText(warranty);
    final creationDate = dateFormat.format(DateTime.now());

    pw.Font? ttfRegular;
    pw.Font? ttfBold;
    try {
      ttfRegular = await PdfGoogleFonts.robotoRegular();
      ttfBold = await PdfGoogleFonts.robotoBold();
    } catch (_) {
      // Fallback to default Helvetica if offline or in headless test
    }

    final theme = ttfRegular != null && ttfBold != null
        ? pw.ThemeData.withFont(base: ttfRegular, bold: ttfBold)
        : pw.ThemeData.base();

    pdf.addPage(
      pw.Page(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 22),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // 1. HEADER SECTION
              pw.Center(
                child: pw.Column(
                  children: [
                    if (logoImage != null)
                      pw.Container(
                        height: 48,
                        child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                      )
                    else
                      pw.Text(
                        'INDEX INFORMATICS (S) PVT. LTD.',
                        style: const pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: darkTitleBlue,
                        ),
                      ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'PRODUCT WARRANTY CARD',
                      style: const pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: darkTitleBlue,
                        letterSpacing: 0.8,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'Official Warranty Document · Retain this card for future service or warranty claims',
                      style: const pw.TextStyle(
                        fontSize: 8.5,
                        color: subtextColor,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 12),

              // 2. PRODUCT & WARRANTY DETAILS BANNER
              _buildSectionBanner('PRODUCT & WARRANTY DETAILS'),

              // Details 2x3 Grid Table
              pw.Table(
                border: pw.TableBorder.all(color: borderColor, width: 0.7),
                columnWidths: const {
                  0: pw.FlexColumnWidth(1.2),
                  1: pw.FlexColumnWidth(1.8),
                  2: pw.FlexColumnWidth(1.2),
                  3: pw.FlexColumnWidth(1.8),
                },
                children: [
                  pw.TableRow(
                    children: [
                      _buildTableCell('Product Name', isHeader: true),
                      _buildTableCell(productName),
                      _buildTableCell('Serial Number', isHeader: true),
                      _buildTableCell(serialNumber, isBold: true),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _buildTableCell('Warranty Start Date', isHeader: true),
                      _buildTableCell(startDate),
                      _buildTableCell('Warranty End Date', isHeader: true),
                      _buildTableCell(formattedEndDate, isBold: true),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _buildTableCell('Customer Name', isHeader: true),
                      _buildTableCell(resolvedCustomerName),
                      _buildTableCell('Total Warranty Period', isHeader: true),
                      _buildTableCell(totalWarrantyPeriod, isBold: true),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 10),

              // 3. WARRANTY TERMS BANNER
              _buildSectionBanner('1. WARRANTY TERMS'),

              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: borderColor, width: 0.7),
                ),
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildClauseParagraph(
                      title: 'Manufacturing Guarantee: ',
                      text:
                          'Index Informatics Systems Pvt. Ltd. warrants its products to be free from manufacturing defects and improper workmanship under normal operating conditions.',
                    ),
                    pw.SizedBox(height: 5),
                    _buildClauseParagraph(
                      title: 'Validity Period: ',
                      text: validityPeriodText,
                      highlightText: true,
                    ),
                    pw.SizedBox(height: 5),
                    _buildClauseParagraph(
                      title: 'Authorized Sourcing: ',
                      text:
                          'The warranty is valid only for brand-new Goods purchased directly from the Company or through an authorized Company Distributor. It is strictly non-transferable.',
                    ),
                    pw.SizedBox(height: 5),
                    _buildClauseParagraph(
                      title: 'Discretion & Ownership: ',
                      text:
                          'The right to determine whether a defective unit requires repair or replacement lies wholly at the discretion of the Company. Defective components or parts replaced under warranty become the sole property of the Company.',
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 10),

              // 4. WARRANTY LIMITATIONS & EXCLUSIONS BANNER
              _buildSectionBanner('2. WARRANTY LIMITATIONS & EXCLUSIONS'),

              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: borderColor, width: 0.7),
                ),
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildClauseParagraph(
                      title: 'Tampering & Voiding: ',
                      text:
                          'Warranty is strictly NULL AND VOID if the factory seal of the equipment is broken, damaged, or tampered with by unauthorized personnel.',
                    ),
                    pw.SizedBox(height: 5),
                    _buildClauseParagraph(
                      title: 'Misuse & External Damage: ',
                      text:
                          'Warranty does not cover damages caused by improper installation, improper wiring or external connections, misuse, negligence, or exposure to environmental hazards/calamities (fire, water ingress, lightning strikes, overvoltage surge, etc.).',
                    ),
                    pw.SizedBox(height: 5),
                    _buildClauseParagraph(
                      title: 'Product Identification: ',
                      text:
                          "Warranty is invalid if the product's original identification markings (model number, serial number, or rating labels) have been defaced, altered, or removed.",
                    ),
                    pw.SizedBox(height: 5),
                    _buildClauseParagraph(
                      title: 'Excluded Expenses & Equipment: ',
                      text:
                          'Warranty does not cover transportation, freight, or site access costs incurred during service. The company is not responsible for any issues arising from external output connections or third-party connected equipment.',
                    ),
                    pw.SizedBox(height: 5),
                    _buildClauseParagraph(
                      title: 'Payment Default: ',
                      text:
                          'The warranty will automatically become null and void in the event of non-payment or outstanding dues for the equipment.',
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 10),

              // 5. AUTHORIZATION & VALIDATION BANNER
              _buildSectionBanner('AUTHORIZATION & VALIDATION'),

              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: borderColor, width: 0.7),
                ),
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    // Date of Creation
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'DATE OF CREATION',
                          style: const pw.TextStyle(
                            fontSize: 8.5,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryBlue,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          creationDate,
                          style: const pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        pw.SizedBox(height: 6),
                      ],
                    ),

                    // Authorized Signatory Box
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        if (signatureImage != null)
                          pw.Container(
                            height: 48,
                            width: 140,
                            child: pw.Image(signatureImage, fit: pw.BoxFit.contain),
                          )
                        else
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 8),
                            child: pw.Text(
                              'For INDEX INFORMATICS (S) PVT LTD',
                              style: const pw.TextStyle(
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        pw.Container(
                          width: 150,
                          height: 0.8,
                          color: PdfColors.grey700,
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'AUTHORISED SIGNATORY',
                          style: const pw.TextStyle(
                            fontSize: 7.5,
                            fontWeight: pw.FontWeight.bold,
                            color: subtextColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // 6. FOOTER BAR
              pw.Container(
                color: primaryBlue,
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'INDEX INFORMATICS SYSTEMS PVT. LTD.',
                          style: const pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'HIG-25, Panampilly Nagar, Cochin - 682 036',
                          style: const pw.TextStyle(
                            fontSize: 7,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.Text(
                          'Ph: 9846033330 · 9349299199 · 8086688188',
                          style: const pw.TextStyle(
                            fontSize: 7,
                            color: PdfColors.white,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'info.indexinformatics@gmail.com',
                          style: const pw.TextStyle(
                            fontSize: 7,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'www.indexinformatics.com',
                          style: const pw.TextStyle(
                            fontSize: 7,
                            color: PdfColors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 3),
              pw.Text(
                'This is a systems generated Warranty card',
                style: const pw.TextStyle(
                  fontSize: 6.5,
                  color: subtextColor,
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Builds a dark blue section banner
  static pw.Widget _buildSectionBanner(String title) {
    return pw.Container(
      color: primaryBlue,
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      child: pw.Text(
        title,
        style: const pw.TextStyle(
          fontSize: 8.5,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  /// Builds a table cell with optional header styling
  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    bool isBold = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4.5),
      color: isHeader ? const PdfColor(0.96, 0.97, 0.98) : PdfColors.white,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 7.8,
          fontWeight: (isHeader || isBold) ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? primaryBlue : textColor,
        ),
      ),
    );
  }

  /// Builds a bold title + normal text paragraph
  static pw.Widget _buildClauseParagraph({
    required String title,
    required String text,
    bool highlightText = false,
  }) {
    return pw.RichText(
      textAlign: pw.TextAlign.justify,
      text: pw.TextSpan(
        children: [
          pw.TextSpan(
            text: title,
            style: const pw.TextStyle(
              fontSize: 7.3,
              fontWeight: pw.FontWeight.bold,
              color: textColor,
            ),
          ),
          pw.TextSpan(
            text: text,
            style: pw.TextStyle(
              fontSize: 7.2,
              fontWeight: highlightText ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: highlightText ? primaryBlue : textColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Trigger preview & download dialog via Printing library
  static Future<void> downloadOrPreview(
    BuildContext context, {
    required WarrantyEntity warranty,
    String? customerName,
  }) async {
    try {
      final serial = warranty.serialNumber?.serialNumber ?? 'Product';
      final fileName = 'Warranty_Card_$serial.pdf';

      await Printing.layoutPdf(
        name: fileName,
        onLayout: (PdfPageFormat format) async {
          return generateWarrantyCardPdf(
            warranty: warranty,
            customerName: customerName,
          );
        },
      );
    } on MissingPluginException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'PDF plugin requires a full app restart. Please stop and re-run the app.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate warranty card: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Direct Share / Save PDF file
  static Future<void> directSharePdf(
    BuildContext context, {
    required WarrantyEntity warranty,
    String? customerName,
  }) async {
    try {
      final serial = warranty.serialNumber?.serialNumber ?? 'Product';
      final fileName = 'Warranty_Card_$serial.pdf';

      final bytes = await generateWarrantyCardPdf(
        warranty: warranty,
        customerName: customerName,
      );

      await Printing.sharePdf(
        bytes: bytes,
        filename: fileName,
      );
    } on MissingPluginException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'PDF plugin requires a full app restart. Please stop and re-run the app.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download warranty card: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
