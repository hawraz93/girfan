/// Kurdish (Sorani) UI strings. Kept in one place so wording stays consistent.
class S {
  static const appName = 'گیرفان';
  static const home = 'سەرەکی';
  static const analytics = 'شیکاری';
  static const recurring = 'جێگیرەکان';
  static const settings = 'ڕێکخستن';

  static const balance = 'ماوە';
  static const income = 'داهات';
  static const expense = 'خەرجی';
  static const remainingOf = 'ماوەی';
  static const dueThisMonth = 'ماوە بدرێت';
  static const transactions = 'مامەڵەکان';
  static const noTx = 'هێشتا هیچ مامەڵەیەک نییە';
  static const noTxHint = 'دوگمەی + دابگرە بۆ تۆمارکردنی یەکەم خەرجی';
  static const avgPerDay = 'تێکڕای ڕۆژانە';
  static const ofIncome = 'لە داهات';

  static const add = 'زیادکردن';
  static const save = 'پاشەکەوتکردن';
  static const cancel = 'پاشگەزبوونەوە';
  static const delete = 'سڕینەوە';
  static const edit = 'دەستکاری';
  static const yes = 'بەڵێ';
  static const confirmDelete = 'دڵنیایت لە سڕینەوە؟';
  static const required = 'پێویستە';

  static const amount = 'بڕ';
  static const category = 'پۆل';
  static const source = 'سەرچاوە';
  static const date = 'بەروار';
  static const note = 'تێبینی';
  static const noteHint = 'تێبینی (ئارەزوومەندانە)';
  static const today = 'ئەمڕۆ';
  static const yesterday = 'دوێنێ';
  static const pickDate = 'بەروارێکی تر';
  static const newExpense = 'خەرجی نوێ';
  static const newIncome = 'داهاتی نوێ';
  static const editTx = 'دەستکاری مامەڵە';
  static const record = 'تۆمار بکە';
  static const paid = 'دراوە';
  static const due = 'ماوە';

  static const name = 'ناو';
  static const dayOfMonth = 'ڕۆژی مانگ';
  static const startMonth = 'مانگی سەرەتا';
  static const endMonth = 'مانگی کۆتایی';
  static const hasEnd = 'کۆتایی هەیە (سلفە / قیست)';
  static const ongoing = 'بەردەوام';
  static const installment = 'قیست';
  static const remaining = 'ماوە';
  static const month = 'مانگ';
  static const newRecurring = 'جێگیری نوێ';
  static const editRecurring = 'دەستکاری جێگیر';
  static const noRecurring = 'هیچ خەرجی جێگیرێک نییە';
  static const noRecurringHint = 'کرێی خانوو، سلفە، ئینتەرنێت، موچە... لێرە زیاد بکە';
  static const recurringHelp = 'هەر مانگ لە سەرەکی وەک «ماوە بدرێت» دەردەکەوێت تا تۆماری بکەیت.';

  static const categories = 'پۆلەکانی خەرجی';
  static const incomeSources = 'سەرچاوەکانی داهات';
  static const newCategory = 'پۆلی نوێ';
  static const editCategory = 'دەستکاری پۆل';
  static const icon = 'ئایکۆن';
  static const color = 'ڕەنگ';
  static const budget = 'سنووری مانگانە';
  static const budgetHint = 'بەتاڵ = بێ سنوور';
  static const categoryHidden = 'ئەم پۆلە مامەڵەی لەسەرە، بۆیە شاردرایەوە.';

  static const currency = 'دراو';
  static const baseCurrency = 'دراوی سەرەکی';
  static const usdRate = 'نرخی ١ دۆلار بە دینار';
  static const security = 'پاراستن';
  static const pinLock = 'کۆدی داخستن (PIN)';
  static const setPin = 'کۆدی ٤ ژمارەیی دابنێ';
  static const confirmPin = 'دووبارە کۆدەکە بنووسە';
  static const enterPin = 'کۆدەکەت بنووسە';
  static const wrongPin = 'کۆد هەڵەیە، دووبارە هەوڵ بدە';
  static const appearance = 'ڕووکار';
  static const themeSystem = 'سیستەم';
  static const themeLight = 'ڕووناک';
  static const themeDark = 'تاریک';
  static const data = 'داتا';
  static const exportCsv = 'هەناردەکردنی مامەڵەکان (CSV)';
  static const exportHint = 'بۆ Excel یان پاشەکەوتکردن';
  static const profile = 'پڕۆفایل';
  static const yourName = 'ناوت';
  static const greeting = 'سڵاو';

  static const last6 = '٦ مانگی ڕابردوو';
  static const byCategory = 'بەپێی پۆل';
  static const nothingHere = 'هیچ داتایەک نییە بۆ ئەم مانگە';
  static const total = 'کۆی گشتی';
  static const net = 'پاشماوە';
  static const ofBudget = 'لە سنووری';
  static const overBudget = 'سنوور تێپەڕی';

  // Plans tab
  static const plans = 'پلان';
  static const repeat = 'دووبارەبوونەوە';
  static const everyMonth = 'مانگانە';
  static String everyNMonths(int n) => switch (n) {
        1 => everyMonth,
        12 => 'ساڵانە',
        _ => 'هەر $n مانگ جارێک',
      };
  static const nextDue = 'دواتر';

  // Debts
  static const debts = 'قەرز';
  static const iOwe = 'قەرزی سەرم';
  static const owedToMe = 'قەرزم لای خەڵک';
  static const iOweShort = 'من قەرزدارم';
  static const lentShort = 'قەرزم داوە';
  static const person = 'کەس';
  static const personHint = 'ناوی کەسەکە یان شوێنەکە';
  static const newDebt = 'قەرزی نوێ';
  static const editDebt = 'دەستکاری قەرز';
  static const dueDate = 'وادەی دانەوە';
  static const noDueDate = 'بێ وادە';
  static const noDebts = 'هیچ قەرزێک تۆمار نەکراوە';
  static const noDebtsHint = 'قەرزی سەر خۆت و ئەوەی لای خەڵکە لێرە بنووسە';
  static const payBack = 'پارەدانەوە';
  static const receivePayment = 'وەرگرتنەوە';
  static const payments = 'پارەدانەوەکان';
  static const settled = 'تەواو بوو';
  static const overdue = 'وادەی تێپەڕی';
  static const debtsSeparate =
      'قەرز لە باڵانسی مانگانە جیایە. ئەگەر پارەدانەوەکە وەک خەرجیش دەتەوێت، لە سەرەکی تۆماری بکە.';

  // Goals
  static const goals = 'ئامانج';
  static const goalsTitle = 'پلانی کڕین';
  static const newGoal = 'ئامانجی نوێ';
  static const editGoal = 'دەستکاری ئامانج';
  static const goalNameHint = 'بۆ نموونە: مۆبایلی نوێ';
  static const target = 'نرخ / ئامانج';
  static const deadline = 'دەمەوێت تا ئەم مانگە بیکڕم';
  static const noDeadline = 'بێ کات';
  static const noGoals = 'هیچ پلانێکی کڕینت نییە';
  static const noGoalsHint = 'ئامێرێک یان شتێک کە دەتەوێت بیکڕیت، پارەی بۆ کۆ بکەرەوە';
  static const deposit = 'دانان';
  static const withdraw = 'دەرهێنان';
  static const savedSoFar = 'کۆکراوەتەوە';
  static const perMonth = 'مانگانە پێویستە';
  static const reached = 'گەیشتیت! 🎉';
  static const history = 'مێژوو';
  static const saved = 'پاشەکەوت';
  static const goalsAffectBalance = 'ئەو پارەیەی دایدەنێیت لە باڵانسی ئەو مانگە کەم دەبێتەوە.';
}
