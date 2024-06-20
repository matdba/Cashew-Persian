import 'package:budget/colors.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/pages/addBudgetPage.dart';
import 'package:budget/pages/addTransactionPage.dart';
import 'package:budget/pages/upcomingOverdueTransactionsPage.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/initializeNotifications.dart';
import 'package:budget/struct/upcomingTransactionsFunctions.dart';
import 'package:budget/widgets/animatedExpanded.dart';
import 'package:budget/widgets/dropdownSelect.dart';
import 'package:budget/widgets/framework/popupFramework.dart';
import 'package:budget/widgets/navigationSidebar.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/widgets/selectedTransactionsAppBar.dart';
import 'package:budget/widgets/button.dart';
import 'package:budget/widgets/fab.dart';
import 'package:budget/widgets/fadeIn.dart';
import 'package:budget/widgets/noResults.dart';
import 'package:budget/widgets/openBottomSheet.dart';
import 'package:budget/widgets/framework/pageFramework.dart';
import 'package:budget/widgets/settingsContainers.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:budget/widgets/transactionEntry/incomeAmountArrow.dart';
import 'package:budget/widgets/transactionEntry/transactionEntry.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../functions.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/countNumber.dart';

class SubscriptionsPage extends StatefulWidget {
  const SubscriptionsPage({Key? key}) : super(key: key);

  @override
  State<SubscriptionsPage> createState() => SubscriptionsPageState();
}

enum SelectedSubscriptionsType {
  monthly,
  yearly,
  total,
}

class SubscriptionsPageState extends State<SubscriptionsPage> {
  SelectedSubscriptionsType selectedType = SelectedSubscriptionsType.values[appStateSettings["selectedSubscriptionType"]];
  GlobalKey<PageFrameworkState> pageState = GlobalKey();

  void scrollToTop() {
    pageState.currentState?.scrollToTop();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if ((globalSelectedID.value["Subscriptions"] ?? []).length > 0) {
          globalSelectedID.value["Subscriptions"] = [];
          globalSelectedID.notifyListeners();
          return false;
        } else {
          return true;
        }
      },
      child: Stack(
        children: [
          PageFramework(
            key: pageState,
            listID: "Subscriptions",
            floatingActionButton: AnimateFABDelayed(
              fab: AddFAB(
                tooltip: "add-subscription".tr(),
                openPage: AddTransactionPage(
                  selectedType: TransactionSpecialType.subscription,
                  routesToPopAfterDelete: RoutesToPopAfterDelete.None,
                ),
              ),
            ),
            dragDownToDismiss: true,
            title: "subscriptions".tr(),
            actions: [
              CustomPopupMenuButton(
                showButtons: enableDoubleColumn(context),
                keepOutFirst: true,
                items: [
                  DropdownItemMenu(
                    id: "settings",
                    label: "settings".tr(),
                    icon: appStateSettings["outlinedIcons"] ? Icons.settings_outlined : Icons.settings_rounded,
                    action: () {
                      openBottomSheet(
                        context,
                        PopupFramework(
                          hasPadding: false,
                          child: SubscriptionSettings(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
            slivers: [
              SliverToBoxAdapter(
                child: TotalUpcomingHeaderPeriodSwitcher(
                  transactionListStream: database.getAllSubscriptions().$1,
                  selectedType: selectedType,
                  setSelectedType: (chosenType) {
                    setState(() {
                      selectedType = chosenType;
                    });
                  },
                  selectedSubtitleTranslation: (selectedType) {
                    return selectedType == SelectedSubscriptionsType.yearly
                        ? "yearly-subscriptions".tr()
                        : selectedType == SelectedSubscriptionsType.monthly
                            ? "monthly-subscriptions".tr()
                            : "total-subscriptions".tr();
                  },
                ),
              ),
              StreamBuilder<List<Transaction>>(
                stream: database.getAllSubscriptions().$1,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    if (snapshot.data!.length <= 0) {
                      return SliverToBoxAdapter(
                          child: NoResults(
                              padding: const EdgeInsets.only(
                                top: 15,
                                right: 30,
                                left: 30,
                              ),
                              message: "no-subscription-transactions".tr()));
                    }
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (BuildContext context, int index) {
                          Transaction transaction = snapshot.data![index];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              HorizontalBreak(padding: EdgeInsets.only(top: 4, bottom: 6)),
                              TransactionEntry(
                                aboveWidget: UpcomingTransactionDateHeader(
                                  selectedType: selectedType,
                                  transaction: transaction,
                                ),
                                openPage: AddTransactionPage(
                                  transaction: transaction,
                                  routesToPopAfterDelete: RoutesToPopAfterDelete.One,
                                ),
                                transaction: transaction,
                                listID: "Subscriptions",
                              ),
                            ],
                          );
                        },
                        childCount: snapshot.data?.length,
                      ),
                    );
                  } else {
                    return SliverToBoxAdapter();
                  }
                },
              ),
              SliverToBoxAdapter(child: SizedBox(height: 55)),
            ],
          ),
          SelectedTransactionsAppBar(
            pageID: "Subscriptions",
          ),
        ],
      ),
    );
  }
}

class UpcomingTransactionDateHeader extends StatelessWidget {
  const UpcomingTransactionDateHeader({
    Key? key,
    required this.transaction,
    required this.selectedType,
    this.useHorizontalPaddingConstrained = true,
  }) : super(key: key);

  final Transaction transaction;
  final SelectedSubscriptionsType? selectedType;
  final bool useHorizontalPaddingConstrained;

  @override
  Widget build(BuildContext context) {
    int daysDifference =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).difference(transaction.dateCreated).inDays;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 3, right: 5),
            child: Row(
              children: [
                TextFont(
                  text: getWordedDateShortMore(
                    Jalali.fromDateTime(transaction.dateCreated),
                  ),
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
                daysDifference != 0
                    ? Flexible(
                        child: TextFont(
                          fontSize: 17,
                          textColor: daysDifference > 0 ? getColor(context, "unPaidOverdue") : getColor(context, "textLight"),
                          text: " • " +
                              daysDifference.abs().toString() +
                              " " +
                              (daysDifference.abs() == 1 ? "day".tr() : "days".tr()) +
                              (daysDifference > 0 ? " " + "overdue".tr().toLowerCase() : ""),
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : SizedBox(),
              ],
            ),
          ),
        ),
        transaction.type == TransactionSpecialType.repetitive || transaction.type == TransactionSpecialType.subscription
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Icon(
                        appStateSettings["outlinedIcons"] ? Icons.loop_outlined : Icons.loop_rounded,
                        color: dynamicPastel(context, Theme.of(context).colorScheme.primary, amount: 0.4),
                        size: 14,
                      ),
                      SizedBox(width: 3),
                      TextFont(
                        text: transaction.periodLength.toString() +
                            " " +
                            (transaction.periodLength == 1
                                ? nameRecurrence[transaction.reoccurrence].toString().toLowerCase().tr().toLowerCase()
                                : namesRecurrence[transaction.reoccurrence].toString().toLowerCase().tr().toLowerCase()),
                        fontSize: 14,
                        textColor: dynamicPastel(context, Theme.of(context).colorScheme.primary, amount: 0.4),
                      ),
                    ],
                  ),
                  if (selectedType != null)
                    AnimatedSizeSwitcher(
                      child: selectedType == SelectedSubscriptionsType.total
                          ? Container(
                              key: ValueKey(selectedType.toString()),
                            )
                          : TextFont(
                              key: ValueKey(selectedType.toString()),
                              text: convertToMoney(
                                    Provider.of<AllWallets>(context),
                                    getTotalSubscriptions(Provider.of<AllWallets>(context),
                                        selectedType ?? SelectedSubscriptionsType.monthly, [transaction]),
                                  ) +
                                  " / " +
                                  (selectedType == SelectedSubscriptionsType.monthly
                                          ? "month".tr()
                                          : selectedType == SelectedSubscriptionsType.yearly
                                              ? "year".tr()
                                              : "")
                                      .toLowerCase(),
                              fontSize: 14,
                              textColor: dynamicPastel(context, Theme.of(context).colorScheme.primary, amount: 0.4),
                            ),
                    ),
                ],
              )
            : SizedBox(),
      ],
    );
  }
}

class SubscriptionSettings extends StatelessWidget {
  const SubscriptionSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AutoPaySubscriptionsSetting(),
        AutoPaySettingDescription(),
      ],
    );
  }
}

class AutoPaySubscriptionsSetting extends StatelessWidget {
  const AutoPaySubscriptionsSetting({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsContainerSwitch(
      title: "pay-subscriptions".tr(),
      description: "pay-subscriptions-description".tr(),
      onSwitched: (value) async {
        // Need to change setting first, otherwise the function would not run!
        await updateSettings("automaticallyPaySubscriptions", value, updateGlobalState: false);
        await markSubscriptionsAsPaid(context);
        await setUpcomingNotifications(context);
      },
      initialValue: appStateSettings["automaticallyPaySubscriptions"],
      icon: getTransactionTypeIcon(TransactionSpecialType.subscription),
    );
  }
}

class TotalUpcomingHeaderPeriodSwitcher extends StatelessWidget {
  const TotalUpcomingHeaderPeriodSwitcher({
    required this.selectedType,
    required this.setSelectedType,
    required this.transactionListStream,
    required this.selectedSubtitleTranslation,
    super.key,
  });
  final SelectedSubscriptionsType selectedType;
  final Function(SelectedSubscriptionsType) setSelectedType;
  final Stream<List<Transaction>>? transactionListStream;
  final String Function(SelectedSubscriptionsType) selectedSubtitleTranslation;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 30, left: 20, right: 20, bottom: 35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          StreamBuilder<List<Transaction>>(
            stream: transactionListStream,
            builder: (context, snapshot) {
              double total = getTotalSubscriptions(Provider.of<AllWallets>(context), selectedType, snapshot.data);
              return AmountWithColorAndArrow(
                showIncomeArrow: true,
                totalSpent: total,
                fontSize: 30,
                iconSize: 30,
                iconWidth: 20,
                textColor: getColor(context, "black"),
              );
            },
          ),
          Padding(
            padding: EdgeInsets.only(top: 5),
            child: AnimatedSizeSwitcher(
              child: TextFont(
                key: ValueKey(selectedType.toString()),
                text: selectedSubtitleTranslation(selectedType),
                fontSize: 16,
                maxLines: 2,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 18.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: Duration(milliseconds: 250),
                  child: Button(
                    key: ValueKey(selectedType != SelectedSubscriptionsType.monthly),
                    color: selectedType != SelectedSubscriptionsType.monthly
                        ? dynamicPastel(context, Theme.of(context).colorScheme.secondaryContainer,
                            amount: appStateSettings["materialYou"] ? 0.2 : 0.7)
                        : null,
                    textColor: selectedType != SelectedSubscriptionsType.monthly
                        ? getColor(context, "black").withOpacity(0.5)
                        : getColor(context, "black"),
                    label: "monthly".tr(),
                    onTap: () {
                      setSelectedType(SelectedSubscriptionsType.monthly);
                      updateSettings("selectedSubscriptionType", SelectedSubscriptionsType.monthly.index,
                          pagesNeedingRefresh: [], updateGlobalState: false);
                    },
                    fontSize: 12,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  ),
                ),
                SizedBox(width: 7),
                AnimatedSwitcher(
                  duration: Duration(milliseconds: 250),
                  child: Button(
                    key: ValueKey(selectedType != SelectedSubscriptionsType.yearly),
                    color: selectedType != SelectedSubscriptionsType.yearly
                        ? dynamicPastel(context, Theme.of(context).colorScheme.secondaryContainer,
                            amount: appStateSettings["materialYou"] ? 0.2 : 0.7)
                        : null,
                    textColor: selectedType != SelectedSubscriptionsType.yearly
                        ? getColor(context, "black").withOpacity(0.5)
                        : getColor(context, "black"),
                    label: "yearly".tr(),
                    onTap: () {
                      setSelectedType(SelectedSubscriptionsType.yearly);
                      updateSettings("selectedSubscriptionType", SelectedSubscriptionsType.yearly.index,
                          pagesNeedingRefresh: [], updateGlobalState: false);
                    },
                    fontSize: 12,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  ),
                ),
                SizedBox(width: 7),
                AnimatedSwitcher(
                  duration: Duration(milliseconds: 250),
                  child: Button(
                    key: ValueKey(selectedType != SelectedSubscriptionsType.total),
                    color: selectedType != SelectedSubscriptionsType.total
                        ? dynamicPastel(context, Theme.of(context).colorScheme.secondaryContainer,
                            amount: appStateSettings["materialYou"] ? 0.2 : 0.7)
                        : null,
                    textColor: selectedType != SelectedSubscriptionsType.total
                        ? getColor(context, "black").withOpacity(0.5)
                        : getColor(context, "black"),
                    label: "total".tr(),
                    onTap: () {
                      setSelectedType(SelectedSubscriptionsType.total);
                      updateSettings("selectedSubscriptionType", SelectedSubscriptionsType.total.index,
                          pagesNeedingRefresh: [], updateGlobalState: false);
                    },
                    fontSize: 12,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
