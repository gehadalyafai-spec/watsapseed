import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

enum AppFontStyle { tajawal, cairo, system }

extension AppFontStyleInfo on AppFontStyle {
  String get key => switch (this) {
    AppFontStyle.tajawal => 'tajawal',
    AppFontStyle.cairo => 'cairo',
    AppFontStyle.system => 'system',
  };

  String get title => switch (this) {
    AppFontStyle.tajawal => 'Tajawal (افتراضي)',
    AppFontStyle.cairo => 'Cairo',
    AppFontStyle.system => 'الخط العادي',
  };

  String get sample => switch (this) {
    AppFontStyle.tajawal => 'الخط الافتراضي للتطبيق',
    AppFontStyle.cairo => 'خط عربي واضح ومريح',
    AppFontStyle.system => 'خط النظام الافتراضي',
  };

  TextTheme applyTo(TextTheme base) => switch (this) {
    AppFontStyle.tajawal => GoogleFonts.tajawalTextTheme(base),
    AppFontStyle.cairo => GoogleFonts.cairoTextTheme(base),
    AppFontStyle.system => base,
  };

  TextStyle get sampleStyle => switch (this) {
    AppFontStyle.tajawal => GoogleFonts.tajawal(),
    AppFontStyle.cairo => GoogleFonts.cairo(),
    AppFontStyle.system => const TextStyle(),
  };

  static AppFontStyle fromKey(String? value) {
    return AppFontStyle.values.firstWhere(
      (style) => style.key == value,
      orElse: () => AppFontStyle.tajawal,
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('dark_mode') ?? false;
  final fontStyle = AppFontStyleInfo.fromKey(prefs.getString('font_style'));

  runApp(
    QuickWhatsAppApp(initialDarkMode: isDark, initialFontStyle: fontStyle),
  );
}

class QuickWhatsAppApp extends StatefulWidget {
  final bool initialDarkMode;
  final AppFontStyle initialFontStyle;

  const QuickWhatsAppApp({
    super.key,
    required this.initialDarkMode,
    required this.initialFontStyle,
  });

  @override
  State<QuickWhatsAppApp> createState() => _QuickWhatsAppAppState();
}

class _QuickWhatsAppAppState extends State<QuickWhatsAppApp> {
  late bool isDarkMode;
  late AppFontStyle fontStyle;
  Timer? _startupSplashTimer;
  bool _showStartupSplash = true;

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.initialDarkMode;
    fontStyle = widget.initialFontStyle;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startupSplashTimer = Timer(
        const Duration(seconds: 2),
        () {
          if (!mounted) return;
          setState(() => _showStartupSplash = false);
        },
      );
    });
  }

  @override
  void dispose() {
    _startupSplashTimer?.cancel();
    super.dispose();
  }

  Future<void> changeTheme(bool value) async {
    setState(() => isDarkMode = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
  }

  Future<void> changeFont(AppFontStyle value) async {
    setState(() => fontStyle = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('font_style', value.key);
  }

  ThemeData _buildTheme(Brightness brightness) {
    const brandBlue = Color(0xFF087BAA);
    final isDark = brightness == Brightness.dark;

    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brandBlue,
        brightness: brightness,
      ),
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF111714)
          : const Color(0xFFF7F9F8),
      iconTheme: const IconThemeData(size: 21),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isDark
            ? const Color(0xFF111714)
            : const Color(0xFFF7F9F8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1A211E) : Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: brandBlue, width: 1.8),
        ),
      ),
    );

    return baseTheme.copyWith(
      textTheme: fontStyle.applyTo(baseTheme.textTheme),
      primaryTextTheme: fontStyle.applyTo(baseTheme.primaryTextTheme),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'رقم مباشر',
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: HomePage(
        isDarkMode: isDarkMode,
        selectedFontStyle: fontStyle,
        onThemeChanged: changeTheme,
        onFontChanged: changeFont,
      ),
      builder: (context, child) {
        final screenWidth = MediaQuery.sizeOf(context).width;
        final logoSize =
            (screenWidth * 0.50).clamp(170.0, 220.0).toDouble();

        return Stack(
          fit: StackFit.expand,
          children: [
            child ?? const SizedBox.shrink(),
            IgnorePointer(
              ignoring: !_showStartupSplash,
              child: AnimatedOpacity(
                opacity: _showStartupSplash ? 1 : 0,
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                child: ColoredBox(
                  color: Colors.white,
                  child: Center(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: 0.94,
                        end: 1,
                      ),
                      duration: const Duration(milliseconds: 650),
                      curve: Curves.easeOutCubic,
                      builder: (context, scale, logo) {
                        return Transform.scale(
                          scale: scale,
                          child: logo,
                        );
                      },
                      child: _StartupLogo(size: logoSize),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StartupLogo extends StatelessWidget {
  final double size;

  const _StartupLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Image.asset(
        'assets/icons/app_icon.png',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

class Country {
  final String name;
  final String flag;
  final String code;

  const Country({required this.name, required this.flag, required this.code});
}

const countries = <Country>[
  Country(name: 'السعودية', flag: '🇸🇦', code: '966'),
  Country(name: 'اليمن', flag: '🇾🇪', code: '967'),
  Country(name: 'الإمارات', flag: '🇦🇪', code: '971'),
  Country(name: 'الكويت', flag: '🇰🇼', code: '965'),
  Country(name: 'قطر', flag: '🇶🇦', code: '974'),
  Country(name: 'البحرين', flag: '🇧🇭', code: '973'),
  Country(name: 'عُمان', flag: '🇴🇲', code: '968'),
  Country(name: 'مصر', flag: '🇪🇬', code: '20'),
  Country(name: 'الأردن', flag: '🇯🇴', code: '962'),
  Country(name: 'العراق', flag: '🇮🇶', code: '964'),
  Country(name: 'فلسطين', flag: '🇵🇸', code: '970'),
  Country(name: 'سوريا', flag: '🇸🇾', code: '963'),
  Country(name: 'لبنان', flag: '🇱🇧', code: '961'),
  Country(name: 'ليبيا', flag: '🇱🇾', code: '218'),
  Country(name: 'السودان', flag: '🇸🇩', code: '249'),
  Country(name: 'الصومال', flag: '🇸🇴', code: '252'),
  Country(name: 'جيبوتي', flag: '🇩🇯', code: '253'),
  Country(name: 'موريتانيا', flag: '🇲🇷', code: '222'),
  Country(name: 'تونس', flag: '🇹🇳', code: '216'),
  Country(name: 'المغرب', flag: '🇲🇦', code: '212'),
  Country(name: 'الجزائر', flag: '🇩🇿', code: '213'),
  Country(name: 'تركيا', flag: '🇹🇷', code: '90'),
  Country(name: 'باكستان', flag: '🇵🇰', code: '92'),
  Country(name: 'الهند', flag: '🇮🇳', code: '91'),
  Country(name: 'بنغلاديش', flag: '🇧🇩', code: '880'),
  Country(name: 'إندونيسيا', flag: '🇮🇩', code: '62'),
  Country(name: 'ماليزيا', flag: '🇲🇾', code: '60'),
  Country(name: 'الفلبين', flag: '🇵🇭', code: '63'),
  Country(name: 'الولايات المتحدة', flag: '🇺🇸', code: '1'),
  Country(name: 'كندا', flag: '🇨🇦', code: '1'),
  Country(name: 'المملكة المتحدة', flag: '🇬🇧', code: '44'),
  Country(name: 'فرنسا', flag: '🇫🇷', code: '33'),
  Country(name: 'ألمانيا', flag: '🇩🇪', code: '49'),
  Country(name: 'إيطاليا', flag: '🇮🇹', code: '39'),
  Country(name: 'إسبانيا', flag: '🇪🇸', code: '34'),
  Country(name: 'هولندا', flag: '🇳🇱', code: '31'),
  Country(name: 'بلجيكا', flag: '🇧🇪', code: '32'),
  Country(name: 'السويد', flag: '🇸🇪', code: '46'),
  Country(name: 'النرويج', flag: '🇳🇴', code: '47'),
  Country(name: 'أستراليا', flag: '🇦🇺', code: '61'),
];

enum WhatsAppTarget { personal, business }

extension WhatsAppTargetInfo on WhatsAppTarget {
  String get title =>
      this == WhatsAppTarget.personal ? 'واتساب العادي' : 'واتساب الأعمال';

  String get shortTitle =>
      this == WhatsAppTarget.personal ? 'واتساب' : 'واتساب الأعمال';

  String get androidPackage =>
      this == WhatsAppTarget.personal ? 'com.whatsapp' : 'com.whatsapp.w4b';
}

enum QuickTool {
  phone,
  sms,
  copyNumber,
  copyLink,
  shareLink,
  qr,
  templates,
  favorites,
}

extension QuickToolInfo on QuickTool {
  String get title => switch (this) {
    QuickTool.phone => 'اتصال مباشر',
    QuickTool.sms => 'رسالة SMS',
    QuickTool.copyNumber => 'نسخ الرقم الدولي',
    QuickTool.copyLink => 'نسخ رابط المحادثة',
    QuickTool.shareLink => 'مشاركة رابط المحادثة',
    QuickTool.qr => 'إنشاء QR',
    QuickTool.templates => 'الرسائل الجاهزة',
    QuickTool.favorites => 'المفضلة',
  };

  IconData get icon => switch (this) {
    QuickTool.phone => Icons.phone_rounded,
    QuickTool.sms => Icons.sms_rounded,
    QuickTool.copyNumber => Icons.copy_all_rounded,
    QuickTool.copyLink => Icons.content_copy_rounded,
    QuickTool.shareLink => Icons.share_rounded,
    QuickTool.qr => Icons.qr_code_2_rounded,
    QuickTool.templates => Icons.quickreply_rounded,
    QuickTool.favorites => Icons.star_rounded,
  };
}

class HomePage extends StatefulWidget {
  final bool isDarkMode;
  final AppFontStyle selectedFontStyle;
  final ValueChanged<bool> onThemeChanged;
  final ValueChanged<AppFontStyle> onFontChanged;

  const HomePage({
    super.key,
    required this.isDarkMode,
    required this.selectedFontStyle,
    required this.onThemeChanged,
    required this.onFontChanged,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const MethodChannel _whatsAppChannel = MethodChannel(
    'watsapseed/whatsapp',
  );

  final phoneController = TextEditingController();
  final messageController = TextEditingController();

  Country selectedCountry = countries.first;
  WhatsAppTarget selectedTarget = WhatsAppTarget.personal;
  bool openingWhatsApp = false;
  bool loadingSavedData = true;

  static const brandBlue = Color(0xFF087BAA);

  @override
  void initState() {
    super.initState();
    loadSavedData();
  }

  Future<void> loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTarget = prefs.getString('whatsapp_target');
    final savedCountryCode = prefs.getString('country_code');
    final savedCountryName = prefs.getString('country_name');

    // V4 no longer stores or displays recently used phone numbers.
    await prefs.remove('phone_history');

    if (!mounted) return;

    setState(() {
      selectedTarget = savedTarget == 'business'
          ? WhatsAppTarget.business
          : WhatsAppTarget.personal;
      selectedCountry = countries.firstWhere(
        (country) =>
            country.code == savedCountryCode &&
            (savedCountryName == null || country.name == savedCountryName),
        orElse: () => countries.firstWhere(
          (country) => country.code == savedCountryCode,
          orElse: () => countries.first,
        ),
      );
      loadingSavedData = false;
    });
  }

  Future<void> changeWhatsAppTarget(WhatsAppTarget target) async {
    setState(() => selectedTarget = target);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'whatsapp_target',
      target == WhatsAppTarget.business ? 'business' : 'personal',
    );
  }

  Future<void> changeCountry(Country country) async {
    setState(() => selectedCountry = country);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('country_code', country.code);
    await prefs.setString('country_name', country.name);
  }

  Future<void> _selectCountry() async {
    final country = await showDialog<Country>(
      context: context,
      builder: (_) => CountrySearchDialog(selectedCountry: selectedCountry),
    );

    if (country != null && mounted) {
      await changeCountry(country);
    }
  }

  Future<void> _detectCountryFromInternationalNumber(String value) async {
    final trimmed = value.trim();
    if (!trimmed.startsWith('+') && !trimmed.startsWith('00')) return;

    var digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (trimmed.startsWith('00') && digits.startsWith('00')) {
      digits = digits.substring(2);
    }

    final matching = countries
        .where((country) => digits.startsWith(country.code))
        .toList()
      ..sort((a, b) => b.code.length.compareTo(a.code.length));

    if (matching.isEmpty) return;

    Country detected = matching.first;
    final sameCodeAsCurrent = matching.any(
      (country) =>
          country.code == selectedCountry.code &&
          country.name == selectedCountry.name,
    );
    if (sameCodeAsCurrent) {
      detected = selectedCountry;
    }

    if (detected.name != selectedCountry.name ||
        detected.code != selectedCountry.code) {
      await changeCountry(detected);
    }
  }

  Future<void> pasteNumber() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;

    if (text == null || text.trim().isEmpty) {
      showMessage('لا يوجد رقم في الحافظة');
      return;
    }

    final matches = RegExp(r'\+?\d[\d\s\-()]{5,}\d').allMatches(text);
    String value = text.trim();

    if (matches.isNotEmpty) {
      final candidates = matches
          .map((match) => match.group(0)!.trim())
          .toList()
        ..sort((a, b) {
          final aDigits = a.replaceAll(RegExp(r'[^0-9]'), '').length;
          final bDigits = b.replaceAll(RegExp(r'[^0-9]'), '').length;
          return bDigits.compareTo(aDigits);
        });
      value = candidates.first;
    }

    phoneController.text = value;
    phoneController.selection = TextSelection.collapsed(
      offset: phoneController.text.length,
    );
    await _detectCountryFromInternationalNumber(value);
  }

  String preparePhoneNumber(String input) {
    final raw = input.trim();
    final hadPlus = raw.startsWith('+');
    var number = raw.replaceAll(RegExp(r'[^0-9]'), '');

    if (number.startsWith('00')) {
      return number.substring(2);
    }

    if (hadPlus) return number;

    if (number.startsWith(selectedCountry.code)) {
      return number;
    }

    while (number.startsWith('0')) {
      number = number.substring(1);
    }

    return '${selectedCountry.code}$number';
  }

  bool isPhoneValid(String number) {
    return number.length >= 7 && number.length <= 15;
  }

  Future<bool> _openSelectedWhatsAppOnAndroid(
    String number,
    String message,
  ) async {
    final opened = await _whatsAppChannel.invokeMethod<bool>('openWhatsApp', {
      'phone': number,
      'message': message,
      'packageName': selectedTarget.androidPackage,
    });

    return opened ?? false;
  }

  Future<bool> _openWhatsAppFallback(String number, String message) async {
    final Uri url = message.isEmpty
        ? Uri.https('wa.me', '/$number')
        : Uri.https('wa.me', '/$number', {'text': message});

    return launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _offerBrowserFallback(String number, String message) async {
    if (!mounted) return;

    final openBrowser = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${selectedTarget.title} غير متاح'),
        content: const Text(
          'لم يتم العثور على التطبيق المحدد. هل تريد فتح رابط المحادثة عبر المتصفح؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('فتح عبر المتصفح'),
          ),
        ],
      ),
    );

    if (openBrowser == true) {
      final opened = await _openWhatsAppFallback(number, message);
      if (!opened && mounted) {
        showMessage('تعذر فتح رابط المحادثة');
      }
    }
  }

  Future<void> openWhatsApp() async {
    FocusScope.of(context).unfocus();

    final input = phoneController.text.trim();

    if (input.isEmpty) {
      showMessage('اكتب رقم الجوال أولاً');
      return;
    }

    final number = preparePhoneNumber(input);

    if (!isPhoneValid(number)) {
      showMessage('تأكد من كتابة رقم جوال صحيح');
      return;
    }

    setState(() => openingWhatsApp = true);

    try {
      final message = messageController.text.trim();
      bool opened;

      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        opened = await _openSelectedWhatsAppOnAndroid(number, message);
      } else {
        opened = await _openWhatsAppFallback(number, message);
      }

      if (!opened && mounted) {
        await _offerBrowserFallback(number, message);
      }
    } on PlatformException {
      if (mounted) {
        showMessage('تعذر فتح ${selectedTarget.title}');
      }
    } catch (_) {
      if (mounted) {
        showMessage('حدث خطأ أثناء فتح ${selectedTarget.title}');
      }
    } finally {
      if (mounted) setState(() => openingWhatsApp = false);
    }
  }

  void clearInputs() {
    phoneController.clear();
    messageController.clear();
    FocusScope.of(context).unfocus();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String? _currentNumber() {
    final input = phoneController.text.trim();
    if (input.isEmpty) {
      showMessage('اكتب رقم الجوال أولاً');
      return null;
    }

    final number = preparePhoneNumber(input);
    if (!isPhoneValid(number)) {
      showMessage('تأكد من كتابة رقم جوال صحيح');
      return null;
    }
    return number;
  }

  Uri _currentChatUri(String number) {
    final message = messageController.text.trim();
    return message.isEmpty
        ? Uri.https('wa.me', '/$number')
        : Uri.https('wa.me', '/$number', {'text': message});
  }

  Future<void> _handleQuickTool(QuickTool tool) async {
    switch (tool) {
      case QuickTool.phone:
        await _openPhoneCall();
        break;
      case QuickTool.sms:
        await _openSms();
        break;
      case QuickTool.copyNumber:
        await _copyInternationalNumber();
        break;
      case QuickTool.copyLink:
        await _copyChatLink();
        break;
      case QuickTool.shareLink:
        await _shareChatLink();
        break;
      case QuickTool.qr:
        await _showQrCode();
        break;
      case QuickTool.templates:
        await _openMessageTemplates();
        break;
      case QuickTool.favorites:
        await _openFavorites();
        break;
    }
  }

  Future<void> _openPhoneCall() async {
    final number = _currentNumber();
    if (number == null) return;

    final opened = await launchUrl(
      Uri(scheme: 'tel', path: '+$number'),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) showMessage('تعذر فتح تطبيق الاتصال');
  }

  Future<void> _openSms() async {
    final number = _currentNumber();
    if (number == null) return;

    final message = messageController.text.trim();
    final uri = Uri(
      scheme: 'sms',
      path: '+$number',
      queryParameters: message.isEmpty ? null : {'body': message},
    );

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) showMessage('تعذر فتح تطبيق الرسائل');
  }

  Future<void> _copyInternationalNumber() async {
    final number = _currentNumber();
    if (number == null) return;

    await Clipboard.setData(ClipboardData(text: '+$number'));
    if (mounted) showMessage('تم نسخ الرقم الدولي');
  }

  Future<void> _copyChatLink() async {
    final number = _currentNumber();
    if (number == null) return;

    await Clipboard.setData(
      ClipboardData(text: _currentChatUri(number).toString()),
    );
    if (mounted) showMessage('تم نسخ رابط المحادثة');
  }

  Future<void> _shareChatLink() async {
    final number = _currentNumber();
    if (number == null) return;

    final text = _currentChatUri(number).toString();
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await _whatsAppChannel.invokeMethod<bool>('shareText', {'text': text});
      } else {
        await Clipboard.setData(ClipboardData(text: text));
        if (mounted) {
          showMessage('تم نسخ الرابط للمشاركة');
        }
      }
    } on PlatformException {
      if (mounted) showMessage('تعذرت مشاركة الرابط');
    }
  }

  Future<Uint8List?> _captureQrPng(GlobalKey qrKey) async {
    final renderObject = qrKey.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) return null;

    final image = await renderObject.toImage(pixelRatio: 4);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<void> _shareQrImage(GlobalKey qrKey, String link) async {
    try {
      final bytes = await _captureQrPng(qrKey);
      if (bytes == null || bytes.isEmpty) {
        showMessage('تعذر تجهيز صورة QR');
        return;
      }

      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await _whatsAppChannel.invokeMethod<bool>('shareImage', {
          'bytes': bytes,
          'fileName': 'raqm-mubasher-qr.png',
          'text': link,
        });
      } else {
        await Clipboard.setData(ClipboardData(text: link));
        if (mounted) showMessage('تم نسخ الرابط للمشاركة');
      }
    } on PlatformException {
      if (mounted) showMessage('تعذرت مشاركة صورة QR');
    } catch (_) {
      if (mounted) showMessage('تعذرت مشاركة صورة QR');
    }
  }

  Future<void> _saveQrImage(GlobalKey qrKey) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      showMessage('حفظ الصورة متاح حاليًا على Android');
      return;
    }

    try {
      final bytes = await _captureQrPng(qrKey);
      if (bytes == null || bytes.isEmpty) {
        showMessage('تعذر تجهيز صورة QR');
        return;
      }

      final savedAt = await _whatsAppChannel.invokeMethod<String>('saveImage', {
        'bytes': bytes,
        'fileName': 'raqm-mubasher-qr.png',
      });

      if (mounted) {
        showMessage(
          savedAt == null || savedAt.isEmpty
              ? 'تم حفظ صورة QR'
              : 'تم حفظ صورة QR بنجاح',
        );
      }
    } on PlatformException {
      if (mounted) showMessage('تعذر حفظ صورة QR');
    } catch (_) {
      if (mounted) showMessage('تعذر حفظ صورة QR');
    }
  }

  Future<void> _showQrCode() async {
    final number = _currentNumber();
    if (number == null || !mounted) return;

    final link = _currentChatUri(number).toString();
    final qrKey = GlobalKey();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final colors = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          title: const Text('رمز QR للمحادثة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RepaintBoundary(
                key: qrKey,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  color: Colors.white,
                  child: QrImageView(
                    data: link,
                    version: QrVersions.auto,
                    size: 220,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'امسح الرمز لفتح المحادثة مباشرة',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: () => _saveQrImage(qrKey),
              icon: const Icon(Icons.download_rounded),
              label: const Text('حفظ الصورة'),
            ),
            TextButton.icon(
              onPressed: () => _shareQrImage(qrKey, link),
              icon: const Icon(Icons.share_rounded),
              label: const Text('مشاركة الصورة'),
            ),
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: link));
                if (mounted) showMessage('تم نسخ رابط المحادثة');
              },
              child: const Text('نسخ الرابط'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('إغلاق'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openMessageTemplates() async {
    final message = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => const MessageTemplatesPage(),
      ),
    );

    if (message != null && mounted) {
      messageController.text = message;
      messageController.selection = TextSelection.collapsed(
        offset: messageController.text.length,
      );
    }
  }

  Future<void> _openFavorites() async {
    final number = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => FavoritesPage(
          initialNumber: phoneController.text.trim(),
          defaultCountry: selectedCountry,
        ),
      ),
    );

    if (number != null && mounted) {
      phoneController.text = number;
      phoneController.selection = TextSelection.collapsed(
        offset: phoneController.text.length,
      );
      await _detectCountryFromInternationalNumber(number);
    }
  }

  Future<void> openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsPage(
          initialDarkMode: widget.isDarkMode,
          initialFontStyle: widget.selectedFontStyle,
          onThemeChanged: widget.onThemeChanged,
          onFontChanged: widget.onFontChanged,
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF222B27) : const Color(0xFFE7ECEA);
    final highlightColor = isDark ? const Color(0xFF34403B) : const Color(0xFFF7F9F8);
    final compact = constraints.maxHeight < 650;
    final horizontalPadding = compact ? 14.0 : 18.0;

    Widget bar(double height, {double? width, double radius = 16}) {
      return Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        compact ? 10 : 16,
        horizontalPadding,
        12,
      ),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: bar(compact ? 48 : 58, width: compact ? 48 : 58)),
            const SizedBox(height: 10),
            Center(child: bar(16, width: 190, radius: 8)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: bar(compact ? 46 : 50)),
                const SizedBox(width: 8),
                Expanded(child: bar(compact ? 46 : 50)),
              ],
            ),
            const SizedBox(height: 12),
            bar(56),
            const SizedBox(height: 12),
            bar(56),
            const SizedBox(height: 12),
            bar(compact ? 62 : 70),
            const SizedBox(height: 14),
            bar(compact ? 48 : 52),
          ],
        ),
      ),
    );
  }

  Widget _buildWhatsAppSelector(bool compact) {
    final colors = Theme.of(context).colorScheme;

    Widget buildOption({
      required WhatsAppTarget target,
      required IconData icon,
      required String label,
    }) {
      final selected = selectedTarget == target;

      return Expanded(
        child: Material(
          color: selected
              ? brandBlue.withValues(alpha: 0.16)
              : colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: selected
                  ? brandBlue
                  : colors.outline.withValues(alpha: 0.55),
              width: selected ? 1.6 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => changeWhatsAppTarget(target),
            child: SizedBox(
              height: compact ? 46 : 50,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 8 : 10,
                  vertical: 7,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        selected ? LucideIcons.check : icon,
                        size: compact ? 20 : 22,
                      ),
                      SizedBox(width: compact ? 6 : 8),
                      Text(
                        label,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.visible,
                        style: TextStyle(
                          fontSize: compact ? 15 : 16,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        buildOption(
          target: WhatsAppTarget.personal,
          icon: LucideIcons.messageCircle,
          label: 'العادي',
        ),
        const SizedBox(width: 8),
        buildOption(
          target: WhatsAppTarget.business,
          icon: LucideIcons.briefcase,
          label: 'الأعمال',
        ),
      ],
    );
  }

  Widget _buildMainContent(BuildContext context, BoxConstraints constraints) {
    final colors = Theme.of(context).colorScheme;
    final compact = constraints.maxHeight < 650;
    final horizontalPadding = compact ? 14.0 : 18.0;
    final gap = compact ? 8.0 : 11.0;
    final logoSize = compact ? 48.0 : 58.0;

    final content = SizedBox(
      width: constraints.maxWidth - (horizontalPadding * 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: logoSize,
            height: logoSize,
            decoration: BoxDecoration(
              color: brandBlue,
              borderRadius: BorderRadius.circular(compact ? 15 : 18),
            ),
            child: Icon(
              LucideIcons.messageCircle,
              size: compact ? 27 : 32,
              color: Colors.white,
            ),
          ),
          SizedBox(height: compact ? 6 : 8),
          Text(
            'افتح محادثة بدون حفظ الرقم',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: compact ? 15 : 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: compact ? 8 : 12),
          _buildWhatsAppSelector(compact),
          SizedBox(height: gap),
          InkWell(
            onTap: _selectCountry,
            borderRadius: BorderRadius.circular(16),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'الدولة',
                prefixIcon: Icon(LucideIcons.globe),
              ),
              child: Row(
                children: [
                  Text(selectedCountry.flag),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      selectedCountry.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      '+${selectedCountry.code}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(LucideIcons.chevronDown, size: 18),
                ],
              ),
            ),
          ),
          SizedBox(height: gap),
          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            textDirection: TextDirection.ltr,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]')),
            ],
            style: TextStyle(
              fontSize: compact ? 17 : 18,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              labelText: 'رقم الجوال',
              hintText: '05xxxxxxxx',
              prefixIcon: const Icon(LucideIcons.smartphone),
              suffixIcon: IconButton(
                tooltip: 'لصق',
                onPressed: pasteNumber,
                icon: const Icon(LucideIcons.clipboardPaste),
              ),
            ),
          ),
          SizedBox(height: gap),
          SizedBox(
            height: compact ? 62 : 70,
            child: TextField(
              controller: messageController,
              expands: true,
              minLines: null,
              maxLines: null,
              textInputAction: TextInputAction.newline,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                labelText: 'الرسالة - اختياري',
                hintText: 'اكتب رسالة مسبقة',
                alignLabelWithHint: true,
                prefixIcon: Icon(LucideIcons.messageSquare),
              ),
            ),
          ),
          SizedBox(height: compact ? 10 : 13),
          SizedBox(
            width: double.infinity,
            height: compact ? 48 : 52,
            child: FilledButton.icon(
              onPressed: openingWhatsApp ? null : openWhatsApp,
              style: FilledButton.styleFrom(
                backgroundColor: brandBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: openingWhatsApp
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.3,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      selectedTarget == WhatsAppTarget.personal
                          ? LucideIcons.messageCircle
                          : LucideIcons.briefcase,
                      size: 22,
                    ),
              label: openingWhatsApp
                  ? Shimmer.fromColors(
                      baseColor: Colors.white70,
                      highlightColor: Colors.white,
                      child: Text(
                        'جاري الفتح...',
                        style: TextStyle(
                          fontSize: compact ? 16 : 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : Text(
                      'فتح في ${selectedTarget.shortTitle}',
                      style: TextStyle(
                        fontSize: compact ? 16 : 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          SizedBox(height: compact ? 2 : 4),
          TextButton.icon(
            onPressed: clearInputs,
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            icon: const Icon(LucideIcons.refreshCw, size: 19),
            label: const Text('رقم جديد'),
          ),
          Text(
            'لا يتم حفظ الرقم في جهات الاتصال أو في سجل داخل التطبيق.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: compact ? 10 : 11,
              color: colors.onSurfaceVariant,
            ),
          ),
        ].animate(delay: 1950.ms, interval: 55.ms)
            .fadeIn(duration: 420.ms, curve: Curves.easeOutCubic)
            .slideY(begin: 0.045, end: 0, duration: 480.ms, curve: Curves.easeOutCubic),
      ),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        compact ? 6 : 10,
        horizontalPadding,
        compact ? 6 : 10,
      ),
      child: SizedBox(
        width: constraints.maxWidth,
        height: constraints.maxHeight - (compact ? 12 : 20),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topCenter,
          child: content,
        ),
      ),
    );
  }

  @override
  void dispose() {
    phoneController.dispose();
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'رقم مباشر',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            PopupMenuButton<QuickTool>(
              tooltip: 'الأدوات',
              icon: const Icon(Icons.grid_view_rounded),
              onSelected: _handleQuickTool,
              itemBuilder: (context) => [
                for (final tool in QuickTool.values)
                  PopupMenuItem<QuickTool>(
                    value: tool,
                    child: Row(
                      children: [
                        Icon(tool.icon, size: 20),
                        const SizedBox(width: 10),
                        Text(tool.title),
                      ],
                    ),
                  ),
              ],
            ),
            IconButton(
              tooltip: 'الإعدادات',
              onPressed: openSettings,
              icon: const Icon(LucideIcons.settings),
            ),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => loadingSavedData
                ? _buildLoadingSkeleton(context, constraints)
                : _buildMainContent(context, constraints),
          ),
        ),
      ),
    );
  }
}

class CountrySearchDialog extends StatefulWidget {
  final Country selectedCountry;

  const CountrySearchDialog({super.key, required this.selectedCountry});

  @override
  State<CountrySearchDialog> createState() => _CountrySearchDialogState();
}

class _CountrySearchDialogState extends State<CountrySearchDialog> {
  final searchController = TextEditingController();
  String query = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<Country> get filteredCountries {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return countries;

    return countries.where((country) {
      return country.name.toLowerCase().contains(normalized) ||
          country.code.contains(normalized) ||
          '+${country.code}'.contains(normalized);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final results = filteredCountries;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('اختيار الدولة'),
        contentPadding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
        content: SizedBox(
          width: 420,
          height: 460,
          child: Column(
            children: [
              TextField(
                controller: searchController,
                autofocus: true,
                onChanged: (value) => setState(() => query = value),
                decoration: InputDecoration(
                  hintText: 'ابحث بالاسم أو مفتاح الدولة',
                  prefixIcon: const Icon(LucideIcons.search),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'مسح البحث',
                          onPressed: () {
                            searchController.clear();
                            setState(() => query = '');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: results.isEmpty
                    ? const Center(child: Text('لا توجد نتائج'))
                    : ListView.separated(
                        itemCount: results.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final country = results[index];
                          final selected =
                              country.code == widget.selectedCountry.code &&
                              country.name == widget.selectedCountry.name;
                          return ListTile(
                            dense: true,
                            leading: Text(
                              country.flag,
                              style: const TextStyle(fontSize: 24),
                            ),
                            title: Text(country.name),
                            subtitle: Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text(
                                '+${country.code}',
                                textAlign: TextAlign.right,
                              ),
                            ),
                            trailing: selected
                                ? const Icon(LucideIcons.check)
                                : null,
                            onTap: () => Navigator.of(context).pop(country),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }
}

enum SavedListSort { newest, oldest, alphabetical }

class MessageTemplatesPage extends StatefulWidget {
  const MessageTemplatesPage({super.key});

  @override
  State<MessageTemplatesPage> createState() => _MessageTemplatesPageState();
}

class _MessageTemplatesPageState extends State<MessageTemplatesPage> {
  static const _storageKey = 'message_templates';
  final _controller = TextEditingController();
  final _searchController = TextEditingController();
  List<String> templates = [];
  String query = '';
  SavedListSort sort = SavedListSort.newest;

  @override
  void initState() {
    super.initState();
    _load();
  }

  List<MapEntry<int, String>> get visibleTemplates {
    final normalized = query.trim().toLowerCase();
    final items = templates.asMap().entries.where((entry) {
      return normalized.isEmpty ||
          entry.value.toLowerCase().contains(normalized);
    }).toList();

    switch (sort) {
      case SavedListSort.newest:
        items.sort((a, b) => a.key.compareTo(b.key));
        break;
      case SavedListSort.oldest:
        items.sort((a, b) => b.key.compareTo(a.key));
        break;
      case SavedListSort.alphabetical:
        items.sort((a, b) => a.value.compareTo(b.value));
        break;
    }
    return items;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => templates = prefs.getStringList(_storageKey) ?? []);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, templates);
  }

  void _showDuplicateMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'هذه الرسالة محفوظة بالفعل',
          textAlign: TextAlign.center,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _editTemplate({int? index}) async {
    _controller.text = index == null ? '' : templates[index];
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(index == null ? 'رسالة جديدة' : 'تعديل الرسالة'),
        content: TextField(
          controller: _controller,
          autofocus: true,
          minLines: 3,
          maxLines: 7,
          decoration: const InputDecoration(
            hintText: 'اكتب الرسالة الجاهزة',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    final value = _controller.text.trim();
    if (saved != true || value.isEmpty || !mounted) return;

    final duplicate = templates.asMap().entries.any(
      (entry) =>
          entry.key != index &&
          entry.value.trim().toLowerCase() == value.toLowerCase(),
    );
    if (duplicate) {
      _showDuplicateMessage();
      return;
    }

    setState(() {
      if (index == null) {
        templates.insert(0, value);
      } else {
        templates[index] = value;
      }
    });
    await _save();
  }

  Future<void> _deleteTemplate(int index) async {
    setState(() => templates.removeAt(index));
    await _save();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible = visibleTemplates;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            templates.isEmpty
                ? 'الرسائل الجاهزة'
                : 'الرسائل الجاهزة (${templates.length})',
          ),
          actions: [
            if (templates.length > 1)
              PopupMenuButton<SavedListSort>(
                tooltip: 'الترتيب',
                icon: const Icon(Icons.sort_rounded),
                initialValue: sort,
                onSelected: (value) => setState(() => sort = value),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: SavedListSort.newest,
                    child: Text('الأحدث أولاً'),
                  ),
                  PopupMenuItem(
                    value: SavedListSort.oldest,
                    child: Text('الأقدم أولاً'),
                  ),
                  PopupMenuItem(
                    value: SavedListSort.alphabetical,
                    child: Text('ترتيب أبجدي'),
                  ),
                ],
              ),
            IconButton(
              tooltip: 'إضافة رسالة',
              onPressed: () => _editTemplate(),
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
        body: templates.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.quickreply_rounded, size: 54),
                      const SizedBox(height: 12),
                      const Text(
                        'لا توجد رسائل جاهزة بعد',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'احفظ الرسائل التي تستخدمها كثيرًا ثم اخترها بضغطة واحدة.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => _editTemplate(),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('إضافة رسالة'),
                      ),
                    ],
                  ),
                ),
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => query = value),
                      decoration: InputDecoration(
                        hintText: 'ابحث في الرسائل',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'مسح البحث',
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => query = '');
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: visible.isEmpty
                        ? const Center(child: Text('لا توجد نتائج'))
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                            itemCount: visible.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, listIndex) {
                              final item = visible[listIndex];
                              final sourceIndex = item.key;
                              final text = item.value;
                              return Card(
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    child: Icon(Icons.quickreply_rounded),
                                  ),
                                  title: Text(
                                    text,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: const Text(
                                    'اضغط لاستخدام الرسالة',
                                  ),
                                  onTap: () =>
                                      Navigator.of(context).pop(text),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _editTemplate(index: sourceIndex);
                                      }
                                      if (value == 'delete') {
                                        _deleteTemplate(sourceIndex);
                                      }
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Text('تعديل'),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text('حذف'),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}

class FavoritesPage extends StatefulWidget {
  final String initialNumber;
  final Country defaultCountry;

  const FavoritesPage({
    super.key,
    required this.initialNumber,
    required this.defaultCountry,
  });

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  static const _storageKey = 'favorite_numbers';
  final _searchController = TextEditingController();
  List<String> favorites = [];
  String query = '';
  SavedListSort sort = SavedListSort.newest;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _nameOf(String entry) {
    final separator = entry.indexOf('\t');
    return separator == -1 ? entry : entry.substring(0, separator);
  }

  String _numberOf(String entry) {
    final separator = entry.indexOf('\t');
    return separator == -1 ? '' : entry.substring(separator + 1);
  }

  String _normalizedNumber(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  String _internationalForStorage(String value) {
    final trimmed = value.trim();
    var digits = _normalizedNumber(trimmed);

    if (digits.isEmpty) return trimmed;

    if (trimmed.startsWith('+')) {
      return '+$digits';
    }

    if (trimmed.startsWith('00')) {
      if (digits.startsWith('00')) {
        digits = digits.substring(2);
      }
      return '+$digits';
    }

    if (digits.startsWith(widget.defaultCountry.code)) {
      return '+$digits';
    }

    while (digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    return '+${widget.defaultCountry.code}$digits';
  }

  List<MapEntry<int, String>> get visibleFavorites {
    final normalized = query.trim().toLowerCase();
    final items = favorites.asMap().entries.where((entry) {
      final name = _nameOf(entry.value).toLowerCase();
      final number = _numberOf(entry.value).toLowerCase();
      return normalized.isEmpty ||
          name.contains(normalized) ||
          number.contains(normalized);
    }).toList();

    switch (sort) {
      case SavedListSort.newest:
        items.sort((a, b) => a.key.compareTo(b.key));
        break;
      case SavedListSort.oldest:
        items.sort((a, b) => b.key.compareTo(a.key));
        break;
      case SavedListSort.alphabetical:
        items.sort(
          (a, b) => _nameOf(a.value).compareTo(_nameOf(b.value)),
        );
        break;
    }
    return items;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => favorites = prefs.getStringList(_storageKey) ?? []);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, favorites);
  }

  Future<void> _editFavorite({int? index}) async {
    final nameController = TextEditingController(
      text: index == null ? '' : _nameOf(favorites[index]),
    );
    final numberController = TextEditingController(
      text: index == null ? widget.initialNumber : _numberOf(favorites[index]),
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(index == null ? 'إضافة للمفضلة' : 'تعديل المفضلة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'الاسم'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: numberController,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: 'رقم الجوال',
                hintText: 'مثال: 05xxxxxxxx أو +966...',
                helperText: 'يُحفظ بصيغة دولية حسب ${widget.defaultCountry.name}',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    final name = nameController.text.trim();
    final enteredNumber = numberController.text.trim();
    nameController.dispose();
    numberController.dispose();

    if (saved != true || name.isEmpty || enteredNumber.isEmpty || !mounted) {
      return;
    }

    final number = _internationalForStorage(enteredNumber);
    final normalized = _normalizedNumber(number);
    if (normalized.length < 7) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تأكد من كتابة رقم صحيح',
            textAlign: TextAlign.center,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final duplicate = favorites.asMap().entries.any(
      (entry) =>
          entry.key != index &&
          _normalizedNumber(_numberOf(entry.value)) == normalized,
    );
    if (duplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'هذا الرقم موجود في المفضلة بالفعل',
            textAlign: TextAlign.center,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final entry = '$name\t$number';
    setState(() {
      if (index == null) {
        favorites.insert(0, entry);
      } else {
        favorites[index] = entry;
      }
    });
    await _save();
  }

  Future<void> _deleteFavorite(int index) async {
    setState(() => favorites.removeAt(index));
    await _save();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible = visibleFavorites;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            favorites.isEmpty ? 'المفضلة' : 'المفضلة (${favorites.length})',
          ),
          actions: [
            if (favorites.length > 1)
              PopupMenuButton<SavedListSort>(
                tooltip: 'الترتيب',
                icon: const Icon(Icons.sort_rounded),
                initialValue: sort,
                onSelected: (value) => setState(() => sort = value),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: SavedListSort.newest,
                    child: Text('الأحدث أولاً'),
                  ),
                  PopupMenuItem(
                    value: SavedListSort.oldest,
                    child: Text('الأقدم أولاً'),
                  ),
                  PopupMenuItem(
                    value: SavedListSort.alphabetical,
                    child: Text('ترتيب بالاسم'),
                  ),
                ],
              ),
            IconButton(
              tooltip: 'إضافة رقم',
              onPressed: () => _editFavorite(),
              icon: const Icon(Icons.person_add_alt_1_rounded),
            ),
          ],
        ),
        body: favorites.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_outline_rounded, size: 56),
                      const SizedBox(height: 12),
                      const Text(
                        'لا توجد أرقام مفضلة',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'احفظ الأرقام التي تحتاجها كثيرًا بعيدًا عن الشاشة الرئيسية.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => _editFavorite(),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('إضافة رقم'),
                      ),
                    ],
                  ),
                ),
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => query = value),
                      decoration: InputDecoration(
                        hintText: 'ابحث بالاسم أو الرقم',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'مسح البحث',
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => query = '');
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: visible.isEmpty
                        ? const Center(child: Text('لا توجد نتائج'))
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                            itemCount: visible.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, listIndex) {
                              final item = visible[listIndex];
                              final sourceIndex = item.key;
                              final name = _nameOf(item.value);
                              final number = _numberOf(item.value);
                              return Card(
                                child: ListTile(
                                  leading: CircleAvatar(
                                    child: Text(
                                      name.isEmpty ? '★' : name.substring(0, 1),
                                    ),
                                  ),
                                  title: Text(name),
                                  subtitle: Directionality(
                                    textDirection: TextDirection.ltr,
                                    child: Text(
                                      number,
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  onTap: () =>
                                      Navigator.of(context).pop(number),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _editFavorite(index: sourceIndex);
                                      }
                                      if (value == 'delete') {
                                        _deleteFavorite(sourceIndex);
                                      }
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Text('تعديل'),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text('حذف'),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  final bool initialDarkMode;
  final AppFontStyle initialFontStyle;
  final ValueChanged<bool> onThemeChanged;
  final ValueChanged<AppFontStyle> onFontChanged;

  const SettingsPage({
    super.key,
    required this.initialDarkMode,
    required this.initialFontStyle,
    required this.onThemeChanged,
    required this.onFontChanged,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late bool isDarkMode;
  late AppFontStyle selectedFontStyle;

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.initialDarkMode;
    selectedFontStyle = widget.initialFontStyle;
  }

  Future<void> _changeDarkMode(bool value) async {
    setState(() => isDarkMode = value);
    widget.onThemeChanged(value);
  }

  Future<void> _changeFont(AppFontStyle value) async {
    setState(() => selectedFontStyle = value);
    widget.onFontChanged(value);
  }

  void _showAbout() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('عن التطبيق'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF087BAA),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    LucideIcons.messageCircle,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'رقم مباشر',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'أداة تواصل سريعة لفتح واتساب وواتساب الأعمال، والاتصال وSMS، وإنشاء روابط وQR، مع رسائل جاهزة ومفضلة دون الحاجة إلى حفظ الرقم في جهات الاتصال.',
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 6),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: Icon(LucideIcons.user),
              title: Text('تطوير'),
              trailing: Text(
                'alyafai',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: Icon(LucideIcons.info),
              title: Text('نسخة التطبيق'),
              trailing: Text(
                '1.1.0',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('حسنًا'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('سياسة الخصوصية'),
        content: const SingleChildScrollView(
          child: Text(
            'يعمل تطبيق رقم مباشر محليًا على جهازك قدر الإمكان. '
            'لا يتطلب إنشاء حساب، ولا نقوم برفع أرقام الجوال أو الرسائل التي تكتبها إلى خوادم خاصة بنا، '
            'ولا نبيع بيانات المستخدمين.\n\n'
            'الرسائل الجاهزة والأرقام المفضلة التي تختار حفظها يتم تخزينها محليًا على جهازك فقط. '
            'عند استخدام واتساب أو واتساب الأعمال أو الاتصال أو SMS أو المشاركة، '
            'يتم تمرير الرقم أو النص الذي اخترته إلى التطبيق الخارجي أو نظام التشغيل لتنفيذ الإجراء. '
            'وتنطبق عند ذلك سياسات الخصوصية الخاصة بتلك الخدمات.\n\n'
            'لا يحتوي هذا الإصدار على إعلانات أو أدوات تحليل سلوكي. '
            'التطبيق مستقل وغير تابع لشركة WhatsApp أو Meta أو معتمد منهما.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('حسنًا'),
          ),
        ],
      ),
    );
  }

  Future<void> _copyLocalBackup() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = <String, Object>{
      'format': 'raqm-mubasher-backup',
      'version': 1,
      'message_templates': prefs.getStringList('message_templates') ?? <String>[],
      'favorite_numbers': prefs.getStringList('favorite_numbers') ?? <String>[],
    };

    await Clipboard.setData(
      ClipboardData(text: jsonEncode(payload)),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تم نسخ النسخة الاحتياطية إلى الحافظة',
          textAlign: TextAlign.center,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _restoreLocalBackup() async {
    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    final raw = clipboard?.text?.trim();

    if (raw == null || raw.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'لا توجد نسخة احتياطية في الحافظة',
            textAlign: TextAlign.center,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    List<String>? templates;
    List<String>? favorites;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map ||
          decoded['format'] != 'raqm-mubasher-backup' ||
          decoded['version'] != 1) {
        throw const FormatException('Invalid backup');
      }

      final templatesRaw = decoded['message_templates'];
      final favoritesRaw = decoded['favorite_numbers'];

      if (templatesRaw is! List || favoritesRaw is! List) {
        throw const FormatException('Invalid backup lists');
      }

      templates = templatesRaw.whereType<String>().toList();
      favorites = favoritesRaw.whereType<String>().toList();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'النص الموجود في الحافظة ليس نسخة احتياطية صالحة',
            textAlign: TextAlign.center,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('استعادة النسخة الاحتياطية'),
        content: Text(
          'سيتم استبدال الرسائل الجاهزة والمفضلة الحالية بما في النسخة الاحتياطية.\n\n'
          'الرسائل: ${templates!.length}\n'
          'المفضلة: ${favorites!.length}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('استعادة'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('message_templates', templates!);
    await prefs.setStringList('favorite_numbers', favorites!);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تمت استعادة النسخة الاحتياطية بنجاح',
          textAlign: TextAlign.center,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _clearSavedContent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('مسح البيانات المحلية'),
        content: const Text(
          'سيتم حذف جميع الرسائل الجاهزة والأرقام المفضلة المحفوظة على هذا الجهاز. '
          'لن تتغير إعدادات المظهر والخط.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('مسح'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('message_templates');
    await prefs.remove('favorite_numbers');

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تم مسح الرسائل الجاهزة والمفضلة',
          textAlign: TextAlign.center,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'الإعدادات',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: <Widget>[
            Text(
              'المظهر',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              clipBehavior: Clip.antiAlias,
              child: SwitchListTile(
                value: isDarkMode,
                onChanged: _changeDarkMode,
                secondary: Icon(
                  isDarkMode
                      ? LucideIcons.moon
                      : LucideIcons.sun,
                ),
                title: const Text('الوضع الداكن'),
                subtitle: Text(isDarkMode ? 'مفعّل' : 'غير مفعّل'),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'نوع الخط',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              clipBehavior: Clip.antiAlias,
              child: RadioGroup<AppFontStyle>(
                groupValue: selectedFontStyle,
                onChanged: (value) {
                  if (value != null) _changeFont(value);
                },
                child: Column(
                  children: [
                    for (final style in AppFontStyle.values)
                      RadioListTile<AppFontStyle>(
                        value: style,
                        title: Text(style.title),
                        subtitle: Text(
                          style.sample,
                          style: style.sampleStyle,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'البيانات المحلية',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.backup_rounded),
                    title: const Text('نسخ نسخة احتياطية'),
                    subtitle: const Text('نسخ الرسائل والمفضلة إلى الحافظة'),
                    trailing: const Icon(LucideIcons.chevronLeft),
                    onTap: _copyLocalBackup,
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.restore_rounded),
                    title: const Text('استعادة نسخة احتياطية'),
                    subtitle: const Text('استعادة نسخة موجودة في الحافظة'),
                    trailing: const Icon(LucideIcons.chevronLeft),
                    onTap: _restoreLocalBackup,
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.delete_outline_rounded),
                    title: const Text('مسح الرسائل والمفضلة'),
                    subtitle: const Text('حذف المحتوى المحفوظ محليًا على الجهاز'),
                    trailing: const Icon(LucideIcons.chevronLeft),
                    onTap: _clearSavedContent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'معلومات',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(LucideIcons.info),
                    title: const Text('عن التطبيق'),
                    trailing: const Icon(LucideIcons.chevronLeft),
                    onTap: _showAbout,
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(LucideIcons.shieldCheck),
                    title: const Text('سياسة الخصوصية'),
                    subtitle: const Text('كيف يتعامل التطبيق مع بياناتك'),
                    trailing: const Icon(LucideIcons.chevronLeft),
                    onTap: _showPrivacyPolicy,
                  ),
                ],
              ),
            ),
          ].animate(interval: 60.ms)
              .fadeIn(duration: 360.ms, curve: Curves.easeOutCubic)
              .slideY(begin: 0.035, end: 0, duration: 420.ms, curve: Curves.easeOutCubic),
        ),
      ),
    );
  }
}
