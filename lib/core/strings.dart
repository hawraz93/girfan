/// UI strings in Kurdish (Sorani), Arabic and English.
///
/// Every string is a getter that reads [appLang], so the whole app follows the
/// language chosen in Settings. The app tree is rebuilt when it changes.
enum AppLang { ku, ar, en }

AppLang appLang = AppLang.ku;

bool get isRtl => appLang != AppLang.en;

String _t(String ku, String ar, String en) => switch (appLang) {
      AppLang.ku => ku,
      AppLang.ar => ar,
      AppLang.en => en,
    };

class S {
  static String get appName => _t('گیرفان', 'گيرفان', 'Girfan');
  static String get home => _t('سەرەکی', 'الرئيسية', 'Home');
  static String get analytics => _t('شیکاری', 'التحليل', 'Analytics');
  static String get recurring => _t('جێگیرەکان', 'الثابتة', 'Fixed');
  static String get settings => _t('ڕێکخستن', 'الإعدادات', 'Settings');

  static String get balance => _t('ماوە', 'المتبقي', 'Left');
  static String get income => _t('داهات', 'الدخل', 'Income');
  static String get expense => _t('خەرجی', 'المصروف', 'Expense');
  static String get remainingOf => _t('ماوەی', 'المتبقي من', 'Left in');
  static String get dueThisMonth => _t('ماوە بدرێت', 'مستحق الدفع', 'Due');
  static String get transactions => _t('مامەڵەکان', 'المعاملات', 'Transactions');
  static String get noTx => _t('هێشتا هیچ مامەڵەیەک نییە', 'لا توجد معاملات بعد', 'No transactions yet');
  static String get noTxHint => _t('دوگمەی + دابگرە بۆ تۆمارکردنی یەکەم خەرجی',
      'اضغط + لتسجيل أول مصروف', 'Tap + to record your first expense');
  static String get avgPerDay => _t('تێکڕای ڕۆژانە', 'المعدل اليومي', 'Daily average');
  static String get ofIncome => _t('لە داهات', 'من الدخل', 'of income');
  static String spentOfIncome(int pct) => _t('$pct٪ لە داهات خەرج کراوە',
      'تم صرف $pct٪ من الدخل', '$pct% of income spent');

  static String get add => _t('زیادکردن', 'إضافة', 'Add');
  static String get save => _t('پاشەکەوتکردن', 'حفظ', 'Save');
  static String get cancel => _t('پاشگەزبوونەوە', 'إلغاء', 'Cancel');
  static String get delete => _t('سڕینەوە', 'حذف', 'Delete');
  static String get edit => _t('دەستکاری', 'تعديل', 'Edit');
  static String get yes => _t('بەڵێ', 'نعم', 'Yes');
  static String get confirmDelete => _t('دڵنیایت لە سڕینەوە؟', 'هل أنت متأكد من الحذف؟', 'Delete this?');
  static String get required => _t('پێویستە', 'مطلوب', 'is required');

  static String get amount => _t('بڕ', 'المبلغ', 'Amount');
  static String get category => _t('پۆل', 'الفئة', 'Category');
  static String get source => _t('سەرچاوە', 'المصدر', 'Source');
  static String get catsAndSources => _t('پۆل و سەرچاوە', 'الفئات والمصادر', 'Categories & sources');
  static String get date => _t('بەروار', 'التاريخ', 'Date');
  static String get note => _t('تێبینی', 'ملاحظة', 'Note');
  static String get noteHint => _t('تێبینی (ئارەزوومەندانە)', 'ملاحظة (اختياري)', 'Note (optional)');
  static String get today => _t('ئەمڕۆ', 'اليوم', 'Today');
  static String get yesterday => _t('دوێنێ', 'أمس', 'Yesterday');
  static String get pickDate => _t('بەروارێکی تر', 'تاريخ آخر', 'Other date');
  static String get newExpense => _t('خەرجی نوێ', 'مصروف جديد', 'New expense');
  static String get newIncome => _t('داهاتی نوێ', 'دخل جديد', 'New income');
  static String get editTx => _t('دەستکاری مامەڵە', 'تعديل المعاملة', 'Edit transaction');
  static String get record => _t('تۆمار بکە', 'سجّل', 'Record');
  static String get paid => _t('دراوە', 'مدفوع', 'Paid');
  static String get due => _t('ماوە', 'مستحق', 'Due');

  static String get name => _t('ناو', 'الاسم', 'Name');
  static String get dayOfMonth => _t('ڕۆژی مانگ', 'يوم الشهر', 'Day of month');
  static String get startMonth => _t('مانگی سەرەتا', 'شهر البداية', 'Start month');
  static String get endMonth => _t('مانگی کۆتایی', 'شهر النهاية', 'End month');
  static String get endBeforeStart => _t('مانگی کۆتایی پێش مانگی سەرەتا نابێت',
      'لا يمكن أن يسبق شهر النهاية شهر البداية', 'End month cannot be before start month');
  static String get firstPayment => _t('یەکەم پارەدان', 'أول دفعة', 'first payment');
  static String get hasEnd =>
      _t('کۆتایی هەیە (سلفە / قیست)', 'له نهاية (قرض / قسط)', 'Has an end (loan / installment)');
  static String get ongoing => _t('بەردەوام', 'مستمر', 'Ongoing');
  static String get installment => _t('قیست', 'قسط', 'installments');
  static String get remaining => _t('ماوە', 'المتبقي', 'Left');
  static String get month => _t('مانگ', 'شهر', 'month');
  static String get newRecurring => _t('جێگیری نوێ', 'بند ثابت جديد', 'New fixed item');
  static String get editRecurring => _t('دەستکاری جێگیر', 'تعديل البند الثابت', 'Edit fixed item');
  static String get noRecurring => _t('هیچ خەرجی جێگیرێک نییە', 'لا توجد مصاريف ثابتة', 'No fixed items');
  static String get noRecurringHint => _t('کرێی خانوو، سلفە، ئینتەرنێت، موچە... لێرە زیاد بکە',
      'الإيجار، القرض، الإنترنت، الراتب... أضفها هنا', 'Rent, loans, internet, salary... add them here');
  static String get recurringHelp => _t(
      'هەر مانگ لە سەرەکی وەک «ماوە بدرێت» دەردەکەوێت تا تۆماری بکەیت.',
      'تظهر كل شهر في الرئيسية كـ«مستحق الدفع» حتى تسجّلها.',
      'Each month it shows on Home as “Due” until you record it.');
  static String get recurringNameHintExp =>
      _t('بۆ نموونە: کرێی خانوو', 'مثال: إيجار البيت', 'e.g. House rent');
  static String get recurringNameHintInc => _t('بۆ نموونە: موچە', 'مثال: الراتب', 'e.g. Salary');
  static String get fixedExpenseMonth =>
      _t('خەرجی جێگیر · مانگ', 'مصاريف ثابتة · شهرياً', 'Fixed expenses · month');
  static String get fixedIncomeMonth =>
      _t('داهاتی جێگیر · مانگ', 'دخل ثابت · شهرياً', 'Fixed income · month');
  static String fromTo(String a, String b) => _t('$a  تا  $b', '$a  إلى  $b', '$a  to  $b');
  static String since(String a) => _t('لە $a', 'منذ $a', 'since $a');
  static String until(String a) => _t('تا $a', 'حتى $a', 'by $a');

  // Installments
  static String get prePaid =>
      _t('پێشتر چەند قیستت داوە؟', 'كم قسطاً دفعت سابقاً؟', 'Installments already paid');
  static String get prePaidHint => _t('ئەو قیستانەی پێش تۆمارکردن لە گیرفان دراون',
      'الأقساط المدفوعة قبل تسجيلها في التطبيق', 'Paid before you started using the app');
  static String get prePaidAllPast =>
      _t('هەموو مانگە ڕابردووەکان', 'كل الأشهر الماضية', 'All past months');
  static String get nextInstallment => _t('قیستی داهاتوو', 'القسط القادم', 'Next');
  static String installmentsLeft(int n) => _t('$n قیست ماوە', 'بقي $n قسط', '$n left');
  static String unrecordedPast(int n) => _t('$n قیستی ڕابردوو تۆمار نەکراوە، دەستکاری بکە',
      '$n أقساط سابقة غير مسجلة، عدّل البند', '$n past installments not recorded, tap to edit');

  static String get categories => _t('پۆلەکانی خەرجی', 'فئات المصاريف', 'Expense categories');
  static String get incomeSources => _t('سەرچاوەکانی داهات', 'مصادر الدخل', 'Income sources');
  static String get newCategory => _t('پۆلی نوێ', 'فئة جديدة', 'New category');
  static String get editCategory => _t('دەستکاری پۆل', 'تعديل الفئة', 'Edit category');
  static String get icon => _t('ئایکۆن', 'الأيقونة', 'Icon');
  static String get color => _t('ڕەنگ', 'اللون', 'Color');
  static String get budget => _t('سنووری مانگانە', 'الحد الشهري', 'Monthly budget');
  static String get budgetHint => _t('بەتاڵ = بێ سنوور', 'فارغ = بلا حد', 'Empty = no limit');
  static String get categoryHidden => _t('ئەم پۆلە مامەڵەی لەسەرە، بۆیە شاردرایەوە.',
      'هذه الفئة عليها معاملات، لذا تم إخفاؤها.', 'This category has transactions, so it was hidden.');
  static String get categoriesHelp => _t('دابگرە بۆ دەستکاری · درێژ دابگرە بۆ سڕینەوە',
      'اضغط للتعديل · اضغط مطولاً للحذف', 'Tap to edit · long-press to delete');

  static String get currency => _t('دراو', 'العملة', 'Currency');
  static String get baseCurrency => _t('دراوی سەرەکی', 'العملة الأساسية', 'Main currency');
  static String get dinar => _t('دینار', 'دينار', 'Dinar');
  static String get dollar => _t('دۆلار', 'دولار', 'Dollar');
  static String get usdRate => _t('نرخی ١ دۆلار بە دینار', 'سعر ١ دولار بالدينار', 'Rate: 1 USD in IQD');
  static String get security => _t('پاراستن', 'الحماية', 'Security');
  static String get pinLock => _t('کۆدی داخستن (PIN)', 'رمز القفل (PIN)', 'PIN lock');
  static String get setPin => _t('کۆدی ٤ ژمارەیی دابنێ', 'أدخل رمزاً من ٤ أرقام', 'Set a 4-digit PIN');
  static String get confirmPin => _t('دووبارە کۆدەکە بنووسە', 'أعد إدخال الرمز', 'Enter the PIN again');
  static String get enterPin => _t('کۆدەکەت بنووسە', 'أدخل الرمز', 'Enter your PIN');
  static String get wrongPin =>
      _t('کۆد هەڵەیە، دووبارە هەوڵ بدە', 'رمز خاطئ، حاول مرة أخرى', 'Wrong PIN, try again');
  static String get appearance => _t('ڕووکار', 'المظهر', 'Appearance');
  static String get themeSystem => _t('سیستەم', 'النظام', 'System');
  static String get themeLight => _t('ڕووناک', 'فاتح', 'Light');
  static String get themeDark => _t('تاریک', 'داكن', 'Dark');
  static String get language => _t('زمان', 'اللغة', 'Language');
  static String get data => _t('داتا', 'البيانات', 'Data');
  static String get exportCsv =>
      _t('هەناردەکردنی مامەڵەکان (CSV)', 'تصدير المعاملات (CSV)', 'Export transactions (CSV)');
  static String get exportHint => _t('بۆ Excel یان پاشەکەوتکردن', 'لـ Excel أو للحفظ', 'For Excel or safekeeping');
  static String get profile => _t('پڕۆفایل', 'الملف الشخصي', 'Profile');
  static String get yourName => _t('ناوت', 'اسمك', 'Your name');
  static String get greeting => _t('سڵاو', 'مرحباً', 'Hi');
  static String greetingName(String n) => _t('سڵاو، $n', 'مرحباً، $n', 'Hi, $n');

  static String get last6 => _t('٦ مانگی ڕابردوو', 'آخر ٦ أشهر', 'Last 6 months');
  static String get byCategory => _t('بەپێی پۆل', 'حسب الفئة', 'By category');
  static String get nothingHere => _t('هیچ داتایەک نییە بۆ ئەم مانگە', 'لا توجد بيانات لهذا الشهر', 'No data for this month');
  static String get total => _t('کۆی گشتی', 'المجموع', 'Total');
  static String get net => _t('پاشماوە', 'الصافي', 'Net');
  static String get ofBudget => _t('لە سنووری', 'من الحد', 'of');
  static String get overBudget => _t('سنوور تێپەڕی', 'تجاوز الحد', 'Over budget');
  static String get more => _t('زیاتر', 'المزيد', 'More');
  static String get showLess => _t('کەمتر', 'أقل', 'Less');
  static String moreCount(int n) => _t('$n ی تر', '$n أخرى', '$n more');

  // Plans tab
  static String get plans => _t('پلان', 'الخطط', 'Plans');
  static String get repeat => _t('دووبارەبوونەوە', 'التكرار', 'Repeats');
  static String get everyMonth => _t('مانگانە', 'شهرياً', 'Monthly');
  static String everyNMonths(int n) => switch (n) {
        1 => everyMonth,
        12 => _t('ساڵانە', 'سنوياً', 'Yearly'),
        _ => _t('هەر $n مانگ جارێک', 'كل $n أشهر', 'Every $n months'),
      };
  static String get nextDue => _t('دواتر', 'التالي', 'Next');

  // Debts
  static String get debts => _t('قەرز', 'الديون', 'Debts');
  static String get iOwe => _t('قەرزی سەرم', 'ديون عليّ', 'I owe');
  static String get owedToMe => _t('قەرزم لای خەڵک', 'ديوني عند الناس', 'Owed to me');
  static String get iOweShort => _t('من قەرزدارم', 'أنا مدين', 'I borrowed');
  static String get lentShort => _t('قەرزم داوە', 'أقرضت', 'I lent');
  static String get person => _t('کەس', 'الشخص', 'Person');
  static String get personHint => _t('ناوی کەسەکە یان شوێنەکە', 'اسم الشخص أو الجهة', 'Person or place');
  static String get newDebt => _t('قەرزی نوێ', 'دين جديد', 'New debt');
  static String get editDebt => _t('دەستکاری قەرز', 'تعديل الدين', 'Edit debt');
  static String get dueDate => _t('وادەی دانەوە', 'موعد السداد', 'Due date');
  static String get noDueDate => _t('بێ وادە', 'بلا موعد', 'No due date');
  static String get noDebts => _t('هیچ قەرزێک تۆمار نەکراوە', 'لا توجد ديون مسجلة', 'No debts recorded');
  static String get noDebtsHint => _t('قەرزی سەر خۆت و ئەوەی لای خەڵکە لێرە بنووسە',
      'سجّل ديونك وما لك عند الآخرين هنا', 'Record what you owe and what others owe you');
  static String get payBack => _t('پارەدانەوە', 'سداد', 'Pay back');
  static String get receivePayment => _t('وەرگرتنەوە', 'استلام', 'Receive');
  static String get payments => _t('پارەدانەوەکان', 'الدفعات', 'Payments');
  static String get settled => _t('تەواو بوو', 'مُسدَّد', 'Settled');
  static String get overdue => _t('وادەی تێپەڕی', 'متأخر', 'Overdue');
  static String get debtsSeparate => _t(
      'قەرز لە باڵانسی مانگانە جیایە. ئەگەر پارەدانەوەکە وەک خەرجیش دەتەوێت، لە سەرەکی تۆماری بکە.',
      'الديون منفصلة عن الرصيد الشهري. إذا أردت احتساب السداد كمصروف، سجّله في الرئيسية.',
      'Debts are kept apart from the monthly balance. To count a repayment as an expense, record it on Home too.');

  // Goals
  static String get goals => _t('ئامانج', 'الأهداف', 'Goals');
  static String get goalsTitle => _t('پلانی کڕین', 'خطة الشراء', 'Saving goals');
  static String get newGoal => _t('ئامانجی نوێ', 'هدف جديد', 'New goal');
  static String get editGoal => _t('دەستکاری ئامانج', 'تعديل الهدف', 'Edit goal');
  static String get goalNameHint => _t('بۆ نموونە: مۆبایلی نوێ', 'مثال: هاتف جديد', 'e.g. New phone');
  static String get target => _t('نرخ / ئامانج', 'السعر / الهدف', 'Target');
  static String get deadline => _t('دەمەوێت تا ئەم مانگە بیکڕم', 'أريد شراءه بحلول', 'Buy by');
  static String get noDeadline => _t('بێ کات', 'بلا موعد', 'No date');
  static String get noGoals => _t('هیچ پلانێکی کڕینت نییە', 'لا توجد خطط شراء', 'No saving goals');
  static String get noGoalsHint => _t('ئامێرێک یان شتێک کە دەتەوێت بیکڕیت، پارەی بۆ کۆ بکەرەوە',
      'ادّخر لجهاز أو شيء تريد شراءه', 'Save up for a device or anything you want to buy');
  static String get deposit => _t('دانان', 'إيداع', 'Add money');
  static String get withdraw => _t('دەرهێنان', 'سحب', 'Take out');
  static String get savedSoFar => _t('کۆکراوەتەوە', 'المدّخر', 'Saved');
  static String get perMonth => _t('مانگانە پێویستە', 'المطلوب شهرياً', 'Needed monthly');
  static String get reached => _t('گەیشتیت! 🎉', 'وصلت! 🎉', 'Reached! 🎉');
  static String get history => _t('مێژوو', 'السجل', 'History');
  static String get saved => _t('پاشەکەوت', 'مدّخر', 'Saved');
  static String get goalsAffectBalance => _t('ئەو پارەیەی دایدەنێیت لە باڵانسی ئەو مانگە کەم دەبێتەوە.',
      'المبلغ الذي تدّخره يُخصم من رصيد ذلك الشهر.', 'Money you put aside is taken off that month’s balance.');

  // Updates
  static String get updTitle => _t('وەشانی نوێی گیرفان هەیە', 'يتوفر إصدار جديد', 'A new version is available');
  static String get updBuild => _t('وەشان', 'الإصدار', 'Version');
  static String get updKeepsData => _t('هەموو داتاکانت دەمێننەوە.', 'ستبقى جميع بياناتك.', 'All your data is kept.');
  static String get updNow => _t('نوێکردنەوە', 'تحديث', 'Update');
  static String get updLater => _t('دواتر', 'لاحقاً', 'Later');
  static String get updRetry => _t('دووبارە هەوڵ بدە', 'أعد المحاولة', 'Try again');
  static String get updDownloading => _t('داگرتن...', 'جارٍ التنزيل...', 'Downloading...');
  static String get updInstalling =>
      _t('لە پەنجەرەی ئەندرۆید «Update» دابگرە', 'اضغط «تحديث» في نافذة أندرويد', 'Tap “Update” in the Android window');
  static String get updFailed => _t('نوێکردنەوە سەرکەوتوو نەبوو', 'فشل التحديث', 'Update failed');
  static String get updPermission => _t('ڕێگە بە گیرفان بدە ئەپ دابمەزرێنێت، پاشان دووبارە هەوڵ بدە',
      'اسمح للتطبيق بتثبيت التطبيقات ثم أعد المحاولة', 'Allow the app to install apps, then try again');
  static String get updCheck => _t('پشکنینی نوێکردنەوە', 'التحقق من التحديثات', 'Check for updates');
  static String get updLatest => _t('نوێترین وەشانت هەیە', 'لديك أحدث إصدار', 'You have the latest version');
  static String get version => _t('وەشان', 'الإصدار', 'Version');

  // Month style & date picker
  static String get monthStyle => _t('شێوازی مانگ', 'أسماء الأشهر', 'Month names');
  static String get msNumber => _t('ژمارە', 'أرقام', 'Numbers');
  static String get msKurdish => _t('کوردی', 'كردي', 'Kurdish');
  static String get msArabic => _t('عەرەبی', 'عربي', 'Arabic');
  static String get example => _t('نموونە', 'مثال', 'Example');
  static String get pickDay => _t('بەروار هەڵبژێرە', 'اختر التاريخ', 'Pick a date');

  // Quick buttons
  static String get quick => _t('خێرا', 'سريع', 'Quick');
  static String get quickHint => _t('کرتە = تۆمار · ڕاگرتن = دەستکاری', 'اضغط = تسجيل · مطولاً = تعديل', 'Tap = record · hold = edit');
  static String get quickFirst => _t('دوگمەی خێرا', 'زر سريع', 'Quick button');
  static String get newQuick => _t('دوگمەی خێرای نوێ', 'زر سريع جديد', 'New quick button');
  static String get editQuick => _t('دەستکاری دوگمەی خێرا', 'تعديل الزر السريع', 'Edit quick button');
  static String get quickNameHint => _t('بۆ نموونە: نان، بەنزین، چای', 'مثال: خبز، بنزين، شاي', 'e.g. Bread, fuel, tea');
  static String get saveAsQuick => _t('پاشەکەوت وەک دوگمەی خێرا', 'حفظ كزر سريع', 'Save as quick button');
  static String get quickSaved => _t('وەک دوگمەی خێرا پاشەکەوت کرا', 'تم الحفظ كزر سريع', 'saved as a quick button');
  static String get recorded => _t('تۆمار کرا', 'تم التسجيل', 'recorded');
  static String get undo => _t('گەڕانەوە', 'تراجع', 'Undo');

  // Rate per transaction
  static String get rateThisTx => _t('نرخی دۆلار بۆ ئەم مامەڵەیە', 'سعر الدولار لهذه المعاملة', 'Dollar rate for this entry');
  static String get rateNote => _t('مامەڵە کۆنەکان بە نرخی کاتی خۆیان دەمێننەوە',
      'المعاملات القديمة تبقى بسعرها وقت التسجيل', 'Older entries keep the rate they were recorded with');

  // Backup
  static String get backup => _t('باکئەپ', 'النسخ الاحتياطي', 'Backup');
  static String get backupNow => _t('باکئەپکردن', 'نسخ احتياطي', 'Back up');
  static String get backupHint => _t('فایلەکە بنێرە بۆ Google Drive یان WhatsAppـی خۆت',
      'أرسل الملف إلى Google Drive أو WhatsApp الخاص بك', 'Send the file to your Google Drive or WhatsApp');
  static String get restore => _t('گەڕاندنەوە لە باکئەپ', 'استعادة من نسخة احتياطية', 'Restore from backup');
  static String get restoreHint => _t('فایلێکی باکئەپی گیرفان هەڵبژێرە', 'اختر ملف نسخة احتياطية', 'Pick a Girfan backup file');
  static String get never => _t('هەرگیز', 'أبداً', 'never');
  static String lastBackupLabel(int? days) => days == null
      ? _t('دوایین باکئەپ: هەرگیز', 'آخر نسخة: لا يوجد', 'Last backup: never')
      : days == 0
          ? _t('دوایین باکئەپ: ئەمڕۆ', 'آخر نسخة: اليوم', 'Last backup: today')
          : _t('دوایین باکئەپ: $days ڕۆژ لەمەوبەر', 'آخر نسخة: قبل $days يوم', 'Last backup: $days days ago');
  static String get backupDone => _t('باکئەپ کرا ✓', 'تم النسخ الاحتياطي ✓', 'Backed up ✓');
  static String get backupDue => _t('باکئەپت نەکردووە', 'لم تقم بنسخ احتياطي', 'Not backed up');
  static String get restoreConfirm => _t(
      'هەموو داتای ئێستا دەسڕێتەوە و داتای باکئەپەکە دادەنرێت. بەردەوام دەبیت؟',
      'سيتم حذف جميع البيانات الحالية واستبدالها بالنسخة الاحتياطية. هل تتابع؟',
      'All current data will be replaced by the backup. Continue?');
  static String get restoreDone => _t('داتاکان گەڕێنرانەوە ✓', 'تمت الاستعادة ✓', 'Data restored ✓');
  static String get restoreBad => _t('ئەم فایلە باکئەپی گیرفان نییە', 'هذا الملف ليس نسخة احتياطية صالحة', 'This is not a Girfan backup');
  static String get txs => _t('مامەڵە', 'معاملة', 'transactions');

  // Currencies kept apart / merged
  static String get mergeCurrencies => _t('دینار و دۆلار تێکەڵ بکە', 'دمج الدينار والدولار', 'Merge dinar and dollar');
  static String get mergeOff => _t('جیان: دینار و دۆلار هەریەکە حیسابی خۆی هەیە',
      'منفصلان: لكل من الدينار والدولار حسابه', 'Separate: dinar and dollar are counted apart');
  static String get mergeOn => _t('تێکەڵن: دۆلار بە نرخی هەر مامەڵەیەک دەگۆڕدرێت بۆ دراوی سەرەکی',
      'مدمجان: يُحوَّل الدولار بسعر كل معاملة إلى العملة الأساسية',
      'Merged: dollars are converted at each entry’s rate');

  // Categories
  static String get newCategoryShort => _t('نوێ', 'جديد', 'New');

  // Debts by person
  static String get theyOweMe => _t('قەرزم لایەتی', 'لي عنده', 'Owes me');
  static String get iOweThem => _t('قەرزداریم', 'أنا مدين', 'I owe');
  static String get even => _t('یەکسانە', 'متعادل', 'Even');
  static String get moreLoan => _t('قەرزی زیاتر', 'دين إضافي', 'Another loan');
  static String get borrowAgain => _t('دیسان قەرزم لێکرد', 'اقترضت مجدداً', 'Borrowed again');
  static String get lendAgain => _t('دیسان قەرزم دایە', 'أقرضته مجدداً', 'Lent again');
  static String loansCount(int n) => _t('$n قەرز', '$n دين', '$n loans');
}

/// Default categories are stored by their Kurdish name. Show them in the
/// current language unless the user renamed them.
const Map<String, List<String>> _defaultCategoryNames = {
  'خواردن': ['طعام', 'Food'],
  'بازاڕ': ['تسوّق', 'Groceries'],
  'مناڵ': ['الأطفال', 'Kids'],
  'سەیارە': ['السيارة', 'Car'],
  'خانوو': ['البيت', 'Home'],
  'تەندروستی': ['الصحة', 'Health'],
  'جل و بەرگ': ['الملابس', 'Clothes'],
  'کات بەسەربردن': ['ترفيه', 'Fun'],
  'مۆبایل و ئینتەرنێت': ['الهاتف والإنترنت', 'Phone & internet'],
  'پەروەردە': ['التعليم', 'Education'],
  'هیتر': ['أخرى', 'Other'],
  'قیست و سلفە': ['أقساط وقروض', 'Loans & installments'],
  'موچە': ['الراتب', 'Salary'],
  'کاری سەربەخۆ': ['عمل حر', 'Freelance'],
  'دیاری': ['هدية', 'Gift'],
};

String localizeCategory(String raw) {
  if (appLang == AppLang.ku) return raw;
  final t = _defaultCategoryNames[raw];
  if (t == null) return raw;
  return appLang == AppLang.ar ? t[0] : t[1];
}
