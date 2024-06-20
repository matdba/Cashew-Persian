import 'package:budget/colors.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/pages/addTransactionPage.dart';
import 'package:budget/pages/homePage/homePageAllSpendingSummary.dart';
import 'package:budget/pages/homePage/homePageBudgets.dart';
import 'package:budget/pages/homePage/homePageCreditDebts.dart';
import 'package:budget/pages/homePage/homePageLineGraph.dart';
import 'package:budget/pages/homePage/homePageNetWorth.dart';
import 'package:budget/pages/homePage/homePageObjectives.dart';
import 'package:budget/pages/homePage/homePageUpcomingTransactions.dart';
import 'package:budget/pages/homePage/homePageWalletSwitcher.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/modified/reorderable_list.dart';
import 'package:budget/struct/navBarIconsData.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/editRowEntry.dart';
import 'package:budget/widgets/listItem.dart';
import 'package:budget/widgets/moreIcons.dart';
import 'package:budget/widgets/navigationFramework.dart';
import 'package:budget/widgets/navigationSidebar.dart';
import 'package:budget/widgets/openBottomSheet.dart';
import 'package:budget/widgets/outlinedButtonStacked.dart';
import 'package:budget/widgets/radioItems.dart';
import 'package:budget/widgets/settingsContainers.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:budget/widgets/util/showDatePicker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart' hide SliverReorderableList;
import 'package:flutter/material.dart' hide SliverReorderableList;
import 'package:flutter/services.dart';
import 'package:budget/widgets/framework/pageFramework.dart';
import 'package:budget/widgets/framework/popupFramework.dart';
import 'package:budget/functions.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:persian_number_utility/persian_number_utility.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:flutter/material.dart' as material;

// We need to refresh the home page when this route is popped

class EditHomePageItem {
  final IconData icon;
  final String name;
  bool isEnabled;
  final Function(bool value) onSwitched;
  final Function()? onTap;
  List<Widget>? extraWidgetsBelow;

  EditHomePageItem({
    required this.icon,
    required this.name,
    required this.isEnabled,
    required this.onSwitched,
    this.onTap,
    this.extraWidgetsBelow,
  });
}

class EditHomePage extends StatefulWidget {
  const EditHomePage({super.key});

  @override
  State<EditHomePage> createState() => _EditHomePageState();
}

class _EditHomePageState extends State<EditHomePage> {
  bool dragDownToDismissEnabled = true;
  int currentReorder = -1;

  Map<String, EditHomePageItem> editHomePageItems = {};
  List<dynamic> keyOrder = [];

  @override
  void initState() {
    Future.delayed(Duration.zero, () async {
      setState(() {
        editHomePageItems = {
          "wallets": EditHomePageItem(
            icon: appStateSettings["outlinedIcons"] ? Icons.account_balance_wallet_outlined : Icons.account_balance_wallet_rounded,
            name: "حساب ها",
            isEnabled: isHomeScreenSectionEnabled(context, "showWalletSwitcher"),
            onSwitched: (value) {
              switchHomeScreenSection(context, "showWalletSwitcher", value);
            },
            onTap: () {
              openBottomSheet(
                context,
                EditHomePagePinnedWalletsPopup(
                  homePageWidgetDisplay: HomePageWidgetDisplay.WalletSwitcher,
                  showCyclePicker: true,
                ),
                useCustomController: true,
              );
            },
          ),
          "walletsList": EditHomePageItem(
            icon: appStateSettings["outlinedIcons"] ? Icons.format_list_bulleted_outlined : Icons.format_list_bulleted_rounded,
            name: "لیست حساب ها",
            isEnabled: isHomeScreenSectionEnabled(context, "showWalletList"),
            onSwitched: (value) {
              switchHomeScreenSection(context, "showWalletList", value);
            },
            onTap: () {
              openBottomSheet(
                context,
                EditHomePagePinnedWalletsPopup(
                  homePageWidgetDisplay: HomePageWidgetDisplay.WalletList,
                  showCyclePicker: true,
                ),
                useCustomController: true,
              );
            },
          ),
          "budgets": EditHomePageItem(
            icon: appStateSettings["outlinedIcons"] ? Icons.donut_small_outlined : MoreIcons.chart_pie,
            name: "بودجه ها",
            isEnabled: isHomeScreenSectionEnabled(context, "showPinnedBudgets"),
            onSwitched: (value) {
              switchHomeScreenSection(context, "showPinnedBudgets", value);
            },
            onTap: () {
              openBottomSheet(
                context,
                EditHomePagePinnedBudgetsPopup(
                  showBudgetsTotalLabelSetting: true,
                ),
                useCustomController: true,
              );
            },
          ),
          "objectives": EditHomePageItem(
            icon: appStateSettings["outlinedIcons"] ? Icons.savings_outlined : Icons.savings_rounded,
            name: "اهداف",
            isEnabled: isHomeScreenSectionEnabled(context, "showObjectives"),
            onSwitched: (value) {
              switchHomeScreenSection(context, "showObjectives", value);
            },
            onTap: () async {
              openBottomSheet(
                context,
                EditHomePagePinnedGoalsPopup(showGoalsTotalLabelSetting: true, objectiveType: ObjectiveType.goal),
                useCustomController: true,
              );
            },
          ),
          "overdueUpcoming": EditHomePageItem(
            icon: getTransactionTypeIcon(TransactionSpecialType.subscription),
            name: "موعد رسیده و نرسیده",
            isEnabled: isHomeScreenSectionEnabled(context, "showOverdueUpcoming"),
            onSwitched: (value) {
              switchHomeScreenSection(context, "showOverdueUpcoming", value);
            },
            onTap: () async {
              openOverdueUpcomingSettings(context);
            },
          ),
          "creditDebts": EditHomePageItem(
            icon: getTransactionTypeIcon(TransactionSpecialType.credit),
            // name: "lent-and-borrowed".tr(),
            name: "وام ها",
            isEnabled: isHomeScreenSectionEnabled(context, "showCreditDebt"),
            onSwitched: (value) {
              switchHomeScreenSection(context, "showCreditDebt", value);
            },
            onTap: () async {
              openCreditDebtsSettings(context);
            },
          ),
          "objectiveLoans": EditHomePageItem(
            icon: appStateSettings["outlinedIcons"] ? Icons.av_timer_outlined : Icons.av_timer_rounded,
            name: "وام های طولانی مدت",
            isEnabled: isHomeScreenSectionEnabled(context, "showObjectiveLoans"),
            onSwitched: (value) {
              switchHomeScreenSection(context, "showObjectiveLoans", value);
            },
            onTap: () async {
              openBottomSheet(
                context,
                EditHomePagePinnedGoalsPopup(
                  showGoalsTotalLabelSetting: true,
                  objectiveType: ObjectiveType.loan,
                ),
                useCustomController: true,
              );
            },
          ),
          "allSpendingSummary": EditHomePageItem(
            icon: appStateSettings["outlinedIcons"] ? Icons.swap_vert_outlined : Icons.swap_vert_rounded,
            name: "هزینه ها و درآمدها",
            isEnabled: isHomeScreenSectionEnabled(context, "showAllSpendingSummary"),
            onSwitched: (value) {
              switchHomeScreenSection(context, "showAllSpendingSummary", value);
            },
            onTap: () async {
              await openAllSpendingSettings(context);
            },
          ),
          "netWorth": EditHomePageItem(
            icon: appStateSettings["outlinedIcons"] ? Icons.area_chart_outlined : Icons.area_chart_rounded,
            name: "دارایی کل",
            isEnabled: isHomeScreenSectionEnabled(context, "showNetWorth"),
            onSwitched: (value) {
              switchHomeScreenSection(context, "showNetWorth", value);
            },
            extraWidgetsBelow: [],
            onTap: () async {
              await openNetWorthSettings(context);
            },
          ),
          "spendingGraph": EditHomePageItem(
            icon: appStateSettings["outlinedIcons"] ? Icons.insights_outlined : Icons.insights_rounded,
            name: "نمودار هزینه",
            isEnabled: isHomeScreenSectionEnabled(context, "showSpendingGraph"),
            onSwitched: (value) {
              switchHomeScreenSection(context, "showSpendingGraph", value);
            },
            extraWidgetsBelow: [],
            onTap: () async {
              String defaultLabel = "پیشفرض (۳۰ روز گذشته)";
              String allTimeLabel = "همه زمان ها";
              String customLabel = "تاریخ شروع سفارشی";
              List<Budget> allBudgets = await database.getAllBudgets();
              openBottomSheet(
                context,
                Directionality(
                  textDirection: material.TextDirection.rtl,
                  child: PopupFramework(
                    title: "انتخاب نمودار",
                    child: RadioItems(
                      items: [
                        defaultLabel,
                        allTimeLabel,
                        customLabel,
                        ...[for (Budget budget in allBudgets) budget.budgetPk.toString()],
                      ],
                      colorFilter: (budgetPk) {
                        for (Budget budget in allBudgets)
                          if (budget.budgetPk.toString() == budgetPk.toString()) {
                            return dynamicPastel(
                              context,
                              lightenPastel(
                                HexColor(
                                  budget.colour,
                                  defaultColor: Theme.of(context).colorScheme.primary,
                                ),
                                amount: 0.2,
                              ),
                              amount: 0.1,
                            );
                          }
                        return null;
                      },
                      displayFilter: (budgetPk) {
                        for (Budget budget in allBudgets)
                          if (budget.budgetPk.toString() == budgetPk.toString()) {
                            return budget.name;
                          }
                        if (budgetPk == customLabel)
                          return ('${customLabel} (${getWordedDateShortMore(Jalali.fromDateTime(DateTime.parse(appStateSettings["lineGraphStartDate"])), includeYear: true)})');
                        return budgetPk;
                      },
                      initial: appStateSettings["lineGraphDisplayType"] == LineGraphDisplay.Default30Days.index
                          ? defaultLabel
                          : appStateSettings["lineGraphDisplayType"] == LineGraphDisplay.AllTime.index
                              ? allTimeLabel
                              : appStateSettings["lineGraphDisplayType"] == LineGraphDisplay.CustomStartDate.index
                                  ? customLabel
                                  : appStateSettings["lineGraphReferenceBudgetPk"].toString(),
                      onChanged: (value) async {
                        if (value == defaultLabel) {
                          updateSettings(
                            "lineGraphDisplayType",
                            LineGraphDisplay.Default30Days.index,
                            pagesNeedingRefresh: [],
                            updateGlobalState: false,
                          );
                        } else if (value == allTimeLabel) {
                          updateSettings(
                            "lineGraphDisplayType",
                            LineGraphDisplay.AllTime.index,
                            pagesNeedingRefresh: [],
                            updateGlobalState: false,
                          );
                        } else if (value == customLabel) {
                          DateTime? picked = await showCustomDatePicker(
                            context,
                            DateTime.parse(appStateSettings["lineGraphStartDate"]),
                          );
                          if (picked == null || picked.isAfter(DateTime.now())) {
                            if (DateTime.parse(appStateSettings["lineGraphStartDate"]).isAfter(DateTime.now())) {
                              picked = DateTime.now();
                            } else {
                              picked = DateTime.parse(appStateSettings["lineGraphStartDate"]);
                            }
                          }
                          updateSettings(
                            "lineGraphStartDate",
                            (picked ?? appStateSettings["lineGraphDisplayType"]).toString(),
                            pagesNeedingRefresh: [],
                            updateGlobalState: false,
                          );
                          updateSettings(
                            "lineGraphDisplayType",
                            LineGraphDisplay.CustomStartDate.index,
                            pagesNeedingRefresh: [],
                            updateGlobalState: false,
                          );
                        } else {
                          updateSettings(
                            "lineGraphReferenceBudgetPk",
                            value,
                            pagesNeedingRefresh: [],
                            updateGlobalState: false,
                          );
                          updateSettings(
                            "lineGraphDisplayType",
                            LineGraphDisplay.Budget.index,
                            pagesNeedingRefresh: [],
                            updateGlobalState: false,
                          );
                        }
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          "pieChart": EditHomePageItem(
            icon: appStateSettings["outlinedIcons"] ? Icons.pie_chart_outline : Icons.pie_chart_rounded,
            name: "نمودار دایره",
            isEnabled: isHomeScreenSectionEnabled(context, "showPieChart"),
            onSwitched: (value) {
              switchHomeScreenSection(context, "showPieChart", value);
            },
            extraWidgetsBelow: [],
            onTap: () {
              openPieChartHomePageBottomSheetSettings(context);
            },
          ),
          "heatMap": EditHomePageItem(
            icon: appStateSettings["outlinedIcons"] ? Icons.grid_on_outlined : Icons.grid_on_rounded,
            name: "نقشه حرارتی",
            isEnabled: isHomeScreenSectionEnabled(context, "showHeatMap"),
            onSwitched: (value) {
              switchHomeScreenSection(context, "showHeatMap", value);
            },
            extraWidgetsBelow: [],
          ),
          "transactionsList": EditHomePageItem(
            icon: navBarIconsData["transactions"]!.iconData,
            name: "لیست تراکنش ها",
            isEnabled: isHomeScreenSectionEnabled(context, "showTransactionsList"),
            onSwitched: (value) {
              switchHomeScreenSection(context, "showTransactionsList", value);
            },
            extraWidgetsBelow: [],
            onTap: () {
              openTransactionsListHomePageBottomSheetSettings(context);
            },
          ),
        };
        keyOrder = List<String>.from(appStateSettings[getHomePageOrderSettingsKey(context)].map((element) => element.toString()));
        print(keyOrder);
      });
    });
    super.initState();
  }

  toggleSwitch(String key) {
    editHomePageItems[key]?.onSwitched(!(editHomePageItems[key]?.isEnabled ?? false));
    setState(() {
      editHomePageItems[key]?.isEnabled = !(editHomePageItems[key]?.isEnabled ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // We need to refresh the home page when this route is popped
        homePageStateKey.currentState?.refreshState();
        return true;
      },
      child: Directionality(
        textDirection: material.TextDirection.rtl,
        child: PageFramework(
          horizontalPadding: getHorizontalPaddingConstrained(context),
          dragDownToDismiss: true,
          dragDownToDismissEnabled: dragDownToDismissEnabled,
          title: "ویرایش خانه",
          slivers: [
            if (enableDoubleColumn(context))
              SliverToBoxAdapter(
                child: PanelSectionSeparator(
                  orderKey: "ORDER:CENTER",
                ),
              ),
            SliverToBoxAdapter(
              child: HomePageEditRowEntryUsername(
                iconData: appStateSettings["outlinedIcons"] ? Icons.edit_outlined : Icons.edit_rounded,
                initialValue: isHomeScreenSectionEnabled(context, "showUsernameWelcomeBanner"),
                name: appStateSettings["username"] == null || appStateSettings["username"] == "" ? "بنر صفحه خانه" : "بنر نام کاربری",
                onChanged: (value) {
                  switchHomeScreenSection(context, "showUsernameWelcomeBanner", value);
                },
              ),
            ),
            SliverReorderableList(
              onReorderStart: (index) {
                HapticFeedback.heavyImpact();
                setState(() {
                  dragDownToDismissEnabled = false;
                  currentReorder = index;
                });
              },
              onReorderEnd: (_) {
                setState(() {
                  dragDownToDismissEnabled = true;
                  currentReorder = -1;
                });
              },
              itemBuilder: (context, index) {
                if (keyOrder.length <= index)
                  return Container(
                    key: ValueKey(index),
                  );
                String key = keyOrder[index];

                if (["ORDER:LEFT", "ORDER:RIGHT"].contains(key)) {
                  return PanelSectionSeparator(
                    orderKey: key,
                    key: ValueKey(key),
                  );
                }

                if (editHomePageItems[key] == null)
                  return Container(
                    key: ValueKey(index),
                  );

                return EditRowEntry(
                  canReorder: true,
                  key: ValueKey(key),
                  currentReorder: currentReorder != -1 && currentReorder != index,
                  padding: EdgeInsets.only(right: 18, left: 0, top: 16, bottom: 16),
                  extraWidget: Row(
                    children: [
                      getPlatform() == PlatformOS.isIOS
                          ? CupertinoSwitch(
                              activeColor: Theme.of(context).colorScheme.primary,
                              value: editHomePageItems[key]?.isEnabled ?? false,
                              onChanged: (value) {
                                toggleSwitch(key);
                              },
                            )
                          : Switch(
                              activeColor: Theme.of(context).colorScheme.primary,
                              value: editHomePageItems[key]?.isEnabled ?? false,
                              onChanged: (value) {
                                toggleSwitch(key);
                              },
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                    ],
                  ),
                  content: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        editHomePageItems[key]!.icon,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      SizedBox(width: 13),
                      Expanded(
                        child: TextFont(
                          text: editHomePageItems[key]!.name,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          maxLines: 5,
                        ),
                      ),
                    ],
                  ),
                  hasMoreOptionsIcon: editHomePageItems[key]?.onTap != null,
                  extraWidgetsBelow: editHomePageItems[key]?.extraWidgetsBelow,
                  canDelete: false,
                  index: index,
                  onTap: editHomePageItems[key]?.onTap ??
                      () {
                        toggleSwitch(key);
                      },
                  openPage: Container(),
                );
              },
              itemCount: keyOrder.length,
              onReorder: (oldIndex, newIndex) async {
                setState(() {
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }
                  final String item = keyOrder.removeAt(oldIndex);
                  keyOrder.insert(newIndex, item);
                });
                updateSettings(getHomePageOrderSettingsKey(context), keyOrder, pagesNeedingRefresh: [], updateGlobalState: false);
                return true;
              },
            ),
          ],
        ),
      ),
    );
  }
}

class PanelSectionSeparator extends StatelessWidget {
  const PanelSectionSeparator({required this.orderKey, super.key});
  final String orderKey;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15, top: 20, bottom: 10),
      child: Row(
        children: [
          if (orderKey == "ORDER:LEFT")
            TextFont(
              text: "left-panel".tr(),
              fontSize: 16,
              textAlign: TextAlign.left,
            ),
          Expanded(
              child: HorizontalBreak(
            padding: const EdgeInsets.all(15),
          )),
          if (orderKey == "ORDER:CENTER")
            TextFont(
              text: "top-center".tr(),
              fontSize: 16,
              textAlign: TextAlign.right,
            ),
          if (orderKey == "ORDER:CENTER")
            Expanded(
                child: HorizontalBreak(
              padding: const EdgeInsets.all(15),
            )),
          if (orderKey == "ORDER:RIGHT")
            TextFont(
              text: "right-panel".tr(),
              fontSize: 16,
              textAlign: TextAlign.right,
            ),
        ],
      ),
    );
  }
}

Future openTransactionsListHomePageBottomSheetSettings(BuildContext context) async {
  await openBottomSheet(
    context,
    TransactionsListHomePageBottomSheetSettings(),
  );
}

class TransactionsListHomePageBottomSheetSettings extends StatefulWidget {
  const TransactionsListHomePageBottomSheetSettings({super.key});

  @override
  State<TransactionsListHomePageBottomSheetSettings> createState() => _TransactionsListHomePageBottomSheetSettingsState();
}

class _TransactionsListHomePageBottomSheetSettingsState extends State<TransactionsListHomePageBottomSheetSettings> {
  int futureTransactionDaysHomePage = appStateSettings["futureTransactionDaysHomePage"];
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: material.TextDirection.rtl,
      child: PopupFramework(
        title: "لیست تراکنش ها",
        subtitle: "تراکنش های ۷ روز گذشته و تراکنش های آتی در" +
            " ${futureTransactionDaysHomePage.toString().toPersianDigit()} " +
            "روز آینده را لیست می کند",
        child: Column(
          children: [
            SettingsContainerDropdown(
              enableBorderRadius: true,
              items: ["0", "1", "4", "7", "14"],
              onChanged: (value) {
                updateSettings("futureTransactionDaysHomePage", int.parse(value), pagesNeedingRefresh: [], updateGlobalState: false);
                setState(() {
                  futureTransactionDaysHomePage = int.parse(value);
                });
              },
              initial: appStateSettings["futureTransactionDaysHomePage"].toString(),
              title: "تعداد روزهای تراکنش های آتی",
              description: "روزهای آتی برای لیست کردن تراکنش ها",
              icon: appStateSettings["outlinedIcons"] ? Symbols.event_upcoming_sharp : Symbols.event_upcoming_rounded,
            ),
            HorizontalBreakAbove(
              padding: EdgeInsets.symmetric(vertical: 15),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: TextFont(
                      text: "این تنظیمات هنگام تغییر تب لیست تراکنش ها در صفحه خانه اعمال می شود",
                      maxLines: 10,
                      fontSize: getPlatform() == PlatformOS.isIOS ? 14 : 16,
                      textAlign: getPlatform() == PlatformOS.isIOS ? TextAlign.center : TextAlign.right,
                    ),
                  ),
                  SizedBox(height: 15),
                  IncomeAndExpenseOnlyPicker(
                    initialValue: appStateSettings["homePageTransactionsListIncomeAndExpenseOnly"] == true,
                    onChanged: (value) {
                      updateSettings("homePageTransactionsListIncomeAndExpenseOnly", value, updateGlobalState: false);
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

Future openPieChartHomePageBottomSheetSettings(BuildContext context) async {
  await openBottomSheet(
    context,
    PopupFramework(
      title: "نمودار دایره ای",
      subtitle: "این تنظیمات در صفحه خانه اعمال می شود",
      child: Column(
        children: [
          WalletPickerPeriodCycle(
            allWalletsSettingKey: "pieChartAllWallets",
            cycleSettingsExtension: "PieChart",
            homePageWidgetDisplay: HomePageWidgetDisplay.PieChart,
          ),
          HorizontalBreakAbove(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: IncomeAndExpenseOnlyPicker(
              initialValue: appStateSettings["pieChartIncomeAndExpenseOnly"] == true,
              onChanged: (value) {
                updateSettings("pieChartIncomeAndExpenseOnly", value, updateGlobalState: false);
              },
            ),
          ),
          SizedBox(height: 10),
        ],
      ),
      // Column(
      //   children: [
      //     RadioItems(
      //       items: <String>[
      //         "outgoing",
      //         "incoming",
      //       ],
      //       displayFilter: (type) {
      //         return type.toString().tr();
      //       },
      //       initial: appStateSettings["pieChartTotal"],
      //       onChanged: (type) async {
      //         updateSettings("pieChartTotal", type, updateGlobalState: false);
      //         Navigator.of(context).pop();
      //       },
      //     ),
      //     Padding(
      //       padding: const EdgeInsets.only(top: 5),
      //       child: HorizontalBreakAbove(
      //         enabled: true,
      //         child: PeriodCyclePicker(
      //           cycleSettingsExtension: "PieChart",
      //         ),
      //       ),
      //     ),
      //   ],
      // ),
    ),
  );
}

class IncomeAndExpenseOnlyPicker extends StatefulWidget {
  const IncomeAndExpenseOnlyPicker({required this.initialValue, required this.onChanged, super.key});
  final bool initialValue;
  final Function(bool) onChanged;
  @override
  State<IncomeAndExpenseOnlyPicker> createState() => _IncomeAndExpenseOnlyPickerState();
}

class _IncomeAndExpenseOnlyPickerState extends State<IncomeAndExpenseOnlyPicker> {
  late bool pieChartIncomeAndExpenseOnly = widget.initialValue;
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: material.TextDirection.rtl,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AnimatedOpacity(
                  duration: Duration(milliseconds: 500),
                  opacity: pieChartIncomeAndExpenseOnly ? 1 : 0.5,
                  child: OutlinedButtonStacked(
                    filled: pieChartIncomeAndExpenseOnly,
                    alignLeft: true,
                    alignBeside: true,
                    afterWidget: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListItem(
                          "تمامی خرج و دخل را شامل نکن",
                        ),
                        ListItem(
                          "برای مثال: وام ها را شامل نکن",
                        ),
                      ],
                    ),
                    text: "تنها هزینه ها و درآمد ها",
                    padding: EdgeInsets.only(left: 20, right: 15, top: 15, bottom: 15),
                    iconData: null,
                    onTap: () {
                      widget.onChanged(!pieChartIncomeAndExpenseOnly);
                      setState(() {
                        pieChartIncomeAndExpenseOnly = !pieChartIncomeAndExpenseOnly;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AnimatedOpacity(
                  duration: Duration(milliseconds: 500),
                  opacity: !pieChartIncomeAndExpenseOnly ? 1 : 0.5,
                  child: OutlinedButtonStacked(
                    filled: !pieChartIncomeAndExpenseOnly,
                    alignLeft: true,
                    alignBeside: true,
                    afterWidget: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListItem(
                          "تمامی جریان نقدی مثبت و منفی را شامل کن",
                        ),
                        ListItem(
                          "برای مثال: شامل تراکنش های مربوط به وام",
                        ),
                      ],
                    ),
                    text: "همه دخل و خرج",
                    padding: EdgeInsets.only(left: 20, right: 15, top: 15, bottom: 15),
                    iconData: null,
                    onTap: () {
                      widget.onChanged(!pieChartIncomeAndExpenseOnly);
                      setState(() {
                        pieChartIncomeAndExpenseOnly = !pieChartIncomeAndExpenseOnly;
                      });
                    },
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}

class HomePageEditRowEntryUsername extends StatefulWidget {
  const HomePageEditRowEntryUsername(
      {required this.initialValue, required this.onChanged, required this.iconData, required this.name, super.key});

  final bool initialValue;
  final Function(bool value) onChanged;
  final IconData iconData;
  final String name;

  @override
  State<HomePageEditRowEntryUsername> createState() => _HomePageEditRowEntryUsernameState();
}

class _HomePageEditRowEntryUsernameState extends State<HomePageEditRowEntryUsername> {
  late bool value = widget.initialValue;
  @override
  Widget build(BuildContext context) {
    return EditRowEntry(
      canReorder: false,
      padding: EdgeInsets.only(left: 0, right: 18, top: 16, bottom: 16),
      extraWidget: Row(
        children: [
          getPlatform() == PlatformOS.isIOS
              ? CupertinoSwitch(
                  activeColor: Theme.of(context).colorScheme.primary,
                  value: value,
                  onChanged: (value) {
                    widget.onChanged(value);
                    setState(() {
                      this.value = value;
                    });
                  },
                )
              : Switch(
                  activeColor: Theme.of(context).colorScheme.primary,
                  value: value,
                  onChanged: (value) {
                    widget.onChanged(value);
                    setState(() {
                      this.value = value;
                    });
                  },
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
        ],
      ),
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            widget.iconData,
            color: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(width: 13),
          Expanded(
            child: TextFont(
              text: widget.name,
              fontWeight: FontWeight.bold,
              fontSize: 17,
              maxLines: 5,
            ),
          ),
        ],
      ),
      canDelete: false,
      index: 0,
      onTap: () {
        widget.onChanged(!value);
        setState(() {
          this.value = !value;
        });
      },
      openPage: Container(),
    );
  }
}

void switchHomeScreenSection(BuildContext context, String sectionSetting, bool value) {
  if (enableDoubleColumn(context)) {
    updateSettings(sectionSetting + "FullScreen", value, pagesNeedingRefresh: [], updateGlobalState: false);
  } else {
    updateSettings(sectionSetting, value, pagesNeedingRefresh: [], updateGlobalState: false);
  }
}

bool isHomeScreenSectionEnabled(BuildContext context, String sectionSetting) {
  if (enableDoubleColumn(context)) {
    if (appStateSettings[sectionSetting + "FullScreen"] != null) return appStateSettings[sectionSetting + "FullScreen"];
    return false;
  } else {
    if (appStateSettings[sectionSetting] != null) return appStateSettings[sectionSetting];
    return false;
  }
}

String getHomePageOrderSettingsKey(BuildContext context) {
  if (enableDoubleColumn(context)) {
    return "homePageOrderFullScreen";
  } else {
    return "homePageOrder";
  }
}

fixHomePageOrder(Map<String, dynamic> defaultPreferences, settingsKey) {
  List<String> defaultPrefPageOrder = List<String>.from(defaultPreferences[settingsKey].map((element) => element.toString()));
  List<String> currentPageOrder = List<String>.from(appStateSettings[settingsKey].map((element) => element.toString()));
  int index = 0;
  for (String key in [...currentPageOrder]) {
    if (!defaultPrefPageOrder.contains(key)) {
      currentPageOrder.removeWhere((item) => item == key);
      // print("Fixed homepage ordering: " + currentPageOrder.toString());
    }
    index++;
  }
  index = 0;
  String? keyBefore;
  for (String key in defaultPrefPageOrder) {
    if (!currentPageOrder.contains(key)) {
      int indexOfItem = keyBefore == null ? -1 : currentPageOrder.indexOf(keyBefore);
      // print("Fixed homepage ordering finding " + keyBefore.toString());
      if (indexOfItem != -1) {
        // print("Fixed homepage ordering inserted at" +
        //     (indexOfItem + 1).toString());
        currentPageOrder.insert(indexOfItem + 1, key);
      } else {
        currentPageOrder.insert(index, key);
      }
      // print("Fixed homepage ordering: " + currentPageOrder.toString());
    }
    keyBefore = key;
    index++;
  }
  appStateSettings[settingsKey] = currentPageOrder;
}
