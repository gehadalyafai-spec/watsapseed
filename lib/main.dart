import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
      title: 'واتساب سريع',
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
  Country(name: 'المغرب', flag: '🇲🇦', code: '212'),
  Country(name: 'الجزائر', flag: '🇩🇿', code: '213'),
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

    // V4 no longer stores or displays recently used phone numbers.
    await prefs.remove('phone_history');

    if (!mounted) return;

    setState(() {
      selectedTarget = savedTarget == 'business'
          ? WhatsAppTarget.business
          : WhatsAppTarget.personal;
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

  Future<void> pasteNumber() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;

    if (text == null || text.trim().isEmpty) {
      showMessage('لا يوجد رقم في الحافظة');
      return;
    }

    phoneController.text = text.trim();
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
        showMessage('${selectedTarget.title} غير مثبت على الجهاز أو تعذر فتحه');
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
          DropdownButtonFormField<Country>(
            initialValue: selectedCountry,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'الدولة',
              prefixIcon: Icon(LucideIcons.globe),
            ),
            items: countries.map((country) {
              return DropdownMenuItem(
                value: country,
                child: Text(
                  '${country.flag}  ${country.name}  +${country.code}',
                ),
              );
            }).toList(),
            onChanged: (country) {
              if (country == null) return;
              setState(() => selectedCountry = country);
            },
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
              label: Text(
                openingWhatsApp
                    ? 'جاري الفتح...'
                    : 'فتح في ${selectedTarget.shortTitle}',
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
        ].animate(interval: 55.ms)
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
            'واتساب سريع',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
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
                    'واتساب سريع',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'تطبيق سريع لفتح محادثة في واتساب العادي أو واتساب الأعمال دون الحاجة إلى حفظ الرقم في جهات الاتصال.',
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

  void _showPrivacyPlaceholder() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('سياسة الخصوصية'),
        content: const Text(
          'سيتم إضافة سياسة الخصوصية الكاملة هنا في إصدار لاحق.',
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
          children: [
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
                    subtitle: const Text('سنضيف التفاصيل لاحقًا'),
                    trailing: const Icon(LucideIcons.chevronLeft),
                    onTap: _showPrivacyPlaceholder,
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
