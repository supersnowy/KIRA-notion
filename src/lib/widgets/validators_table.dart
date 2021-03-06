import 'dart:async';
import 'dart:ui';
import 'dart:math';

import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:kira_auth/models/validator.dart';
import 'package:kira_auth/utils/export.dart';

class ValidatorsTable extends StatefulWidget {
  final List<Validator> validators;
  final int expandedTop;
  final Function onChangeLikes;
  final Function onTapRow;
  final StreamController controller;
  final int page;
  final Function setPage;
  final bool isLoggedIn;

  ValidatorsTable({
    Key key,
    this.isLoggedIn,
    this.validators,
    this.expandedTop,
    this.onChangeLikes,
    this.onTapRow,
    this.controller,
    this.page,
    this.setPage,
  }) : super();

  @override
  _ValidatorsTableState createState() => _ValidatorsTableState();
}

class _ValidatorsTableState extends State<ValidatorsTable> {
  List<ExpandableController> controllers = List.filled(PAGE_COUNT, null);
  int startAt = 0;
  int endAt;
  List<Validator> currentValidators = <Validator>[];
  String query;

  @override
  void initState() {
    super.initState();

    setPage("", first: true);
    widget.controller.stream.listen((newQuery) => setPage(newQuery));
  }

  setPage(String newQuery, {int newPage = 0, bool first = false}) {
    if (newQuery != null)
      query = newQuery;
    if (newPage > 0)
      widget.setPage(newPage);
    else if (newQuery != null && !first)
      widget.setPage(1);
    var page = newPage > 0 ? newPage : newQuery != null ? 1 : widget.page;
    this.setState(() {
      startAt = page * PAGE_COUNT - PAGE_COUNT;
      endAt = startAt + PAGE_COUNT;

      currentValidators = [];
      var validators = query.isEmpty ? widget.validators : widget.validators.where((x) =>
        x.moniker.toLowerCase().contains(query) || x.address.toLowerCase().contains(query)).toList();
      if (validators.length > startAt)
        currentValidators = validators.sublist(startAt, min(endAt, validators.length));
    });
    if (newPage > 0)
      refreshExpandStatus();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: Container(
            child: ExpandableTheme(
                data: ExpandableThemeData(
                  iconColor: KiraColors.white,
                  useInkWell: true,
                ),
                child: Column(
                  children: <Widget>[
                    addNavigateControls(),
                    ...currentValidators
                      .map((validator) =>
                      ExpandableNotifier(
                        child: ScrollOnExpand(
                          scrollOnExpand: true,
                          scrollOnCollapse: false,
                          child: Card(
                            clipBehavior: Clip.antiAlias,
                            color: KiraColors.kBackgroundColor.withOpacity(0.2),
                            child: ExpandablePanel(
                              theme: ExpandableThemeData(
                                headerAlignment: ExpandablePanelHeaderAlignment.center,
                                tapHeaderToExpand: false,
                                hasIcon: false,
                              ),
                              header: addRowHeader(validator),
                              collapsed: Container(),
                              expanded: addRowBody(validator),
                            ),
                          ),
                        ),
                      )
                  ).toList(),
              ])
            )));
  }

  Widget addNavigateControls() {
    var validators = query.isEmpty ? widget.validators : widget.validators.where((x) =>
      x.moniker.toLowerCase().contains(query) || x.address.toLowerCase().contains(query)).toList();
    var totalPages = (validators.length / PAGE_COUNT).ceil();

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        IconButton(
          onPressed: widget.page > 1 ? () => setPage(null, newPage: widget.page - 1) : null,
          icon: Icon(
            Icons.arrow_back_ios,
            size: 20,
            color: widget.page > 1 ? KiraColors.white : KiraColors.kGrayColor.withOpacity(0.2),
          ),
        ),
        Text("${min(widget.page, totalPages)} / $totalPages", style: TextStyle(fontSize: 16, color: KiraColors.white, fontWeight: FontWeight.bold)),
        IconButton(
          onPressed: widget.page < totalPages ? () => setPage(null, newPage: widget.page + 1) : null,
          icon: Icon(
              Icons.arrow_forward_ios,
              size: 20,
              color: widget.page < totalPages ? KiraColors.white : KiraColors.kGrayColor.withOpacity(0.2)
          ),
        ),
      ],
    );
  }

  refreshExpandStatus({int newExpandTop = -1}) {
    widget.onTapRow(newExpandTop);
    this.setState(() {
      currentValidators.asMap().forEach((index, validator) {
        controllers[index].expanded = validator.top == newExpandTop;
      });
    });
  }

  Widget addRowHeader(Validator validator) {
    return Builder(
        builder: (context) {
          var controller = ExpandableController.of(context);
          controllers[currentValidators.indexOf(validator)] = controller;

          return InkWell(
              onTap: () {
                var newExpandTop = validator.top != widget.expandedTop ? validator.top : -1;
                refreshExpandStatus(newExpandTop: newExpandTop);
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                        flex: 2,
                        child: Container(
                            decoration: new BoxDecoration(
                              shape: BoxShape.circle,
                              border: new Border.all(color: validator.getStatusColor().withOpacity(0.5), width: 2),
                            ),
                            child: InkWell(
                              child: Padding(
                                padding: EdgeInsets.all(2.0),
                                child: Icon(Icons.circle, size: 12.0,
                                    color: validator.getStatusColor()),
                              ),
                            ))
                    ),
                    Expanded(
                        flex: ResponsiveWidget.isSmallScreen(context) ? 3 : 2,
                        child: Text(
                          "${validator.top}.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: KiraColors.white.withOpacity(0.8),
                              fontSize: 16),
                        )
                    ),
                    Expanded(
                        flex: ResponsiveWidget.isSmallScreen(context) ? 6 : 3,
                        child: Align(
                            child: InkWell(
                              onTap: () {
                                copyText(validator.moniker.isEmpty ? validator.address : validator.moniker);
                                showToast(Strings.validatorMonikerCopied);
                              },
                              child: Text(
                                  validator.moniker.isEmpty ? validator.address : validator.moniker,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: KiraColors.white
                                      .withOpacity(0.8), fontSize: 16)
                              ),
                            )
                        )
                    ),
                    ResponsiveWidget.isSmallScreen(context) ? Container() :
                    Expanded(
                        flex: 9,
                        child: Align(
                            child: InkWell(
                                onTap: () {
                                  copyText(validator.address);
                                  showToast(Strings.validatorAddressCopied);
                                },
                                child: Text(
                                  validator.getReducedAddress,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: KiraColors.white
                                      .withOpacity(0.8), fontSize: 16),
                                )
                            )
                        )
                    ),
                    !widget.isLoggedIn ? Container() : Expanded(
                        flex: 2,
                        child: IconButton(
                            icon: Icon(
                                validator.isFavorite ? Icons.favorite : Icons
                                    .favorite_border, color: KiraColors.blue1),
                            color: validator.isFavorite ? KiraColors
                                .kYellowColor2 : KiraColors.white,
                            onPressed: () => widget.onChangeLikes(validator.top)
                        )
                    ),
                    ExpandableIcon(
                      theme: const ExpandableThemeData(
                        expandIcon: Icons.arrow_right,
                        collapseIcon: Icons.arrow_drop_down,
                        iconColor: Colors.white,
                        iconSize: 28,
                        iconRotationAngle: pi / 2,
                        iconPadding: EdgeInsets.only(right: 5),
                        hasIcon: false,
                      ),
                    ),
                  ],
                ),
              )
          );
        }
    );
  }

  Widget addRowBody(Validator validator) {
    final fieldWidth = ResponsiveWidget.isSmallScreen(context) ? 80.0 : 150.0;

    return Container(
        padding: EdgeInsets.all(10),
        child: Column(children: [
          Row(
            children: [
              Container(
                  width: fieldWidth,
                  child: Text(
                      "Validator Key",
                      textAlign: TextAlign.right,
                      style: TextStyle(color: KiraColors.white.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.bold)
                  )
              ),
              SizedBox(width: 20),
              Flexible(child:
                InkWell(
                  onTap: () {
                    copyText(validator.valkey);
                    showToast(Strings.validatorAddressCopied);
                  },
                  child: Text(
                    validator.valkey,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: KiraColors.white.withOpacity(0.8), fontSize: 14))
                )),
              SizedBox(width: 10),
              InkWell(
                onTap: () {
                  copyText(validator.valkey);
                  showToast(Strings.validatorAddressCopied);
                },
                child: Icon(Icons.copy, size: 20, color: KiraColors.white),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Container(
                  width: fieldWidth,
                  child: Text(
                      "Public Key",
                      textAlign: TextAlign.right,
                      style: TextStyle(color: KiraColors.white.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.bold)
                  )
              ),
              SizedBox(width: 20),
              Flexible(child:
                InkWell(
                  onTap: () {
                    copyText(validator.pubkey);
                    showToast(Strings.publicAddressCopied);
                  },
                  child: Text(
                    validator.pubkey,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: KiraColors.white.withOpacity(0.8), fontSize: 14))
                )),
              SizedBox(width: 10),
              InkWell(
                onTap: () {
                  copyText(validator.pubkey);
                  showToast(Strings.publicAddressCopied);
                },
                child: Icon(Icons.copy, size: 20, color: KiraColors.white),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Container(
                  width: fieldWidth,
                  child: Text(
                      "Website",
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(color: KiraColors.white.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.bold)
                  )
              ),
              SizedBox(width: 20),
              Text(validator.checkUnknownWith("website"), overflow: TextOverflow.ellipsis, style: TextStyle(color: KiraColors.white.withOpacity(0.8), fontSize: 14)),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Container(
                  width: fieldWidth,
                  child: Text(
                      "Social",
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(color: KiraColors.white.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.bold)
                  )
              ),
              SizedBox(width: 20),
              Flexible(child: Text(validator.checkUnknownWith("social"),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: KiraColors.white.withOpacity(0.8), fontSize: 14))
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Container(
                  width: fieldWidth,
                  child: Text(
                      "Identity",
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(color: KiraColors.white.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.bold)
                  )
              ),
              SizedBox(width: 20),
              Text(validator.checkUnknownWith("identity"), overflow: TextOverflow.ellipsis, style: TextStyle(color: KiraColors.white.withOpacity(0.8), fontSize: 14)),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Container(
                  width: fieldWidth,
                  child: Text(
                      "Streak",
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(color: KiraColors.white.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.bold)
                  )
              ),
              SizedBox(width: 20),
              Text("${validator.streak}", overflow: TextOverflow.ellipsis, style: TextStyle(color: KiraColors.white.withOpacity(0.8), fontSize: 14)),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Container(
                  width: fieldWidth,
                  child: Text(
                      "Mischance",
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: KiraColors.white.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.bold)
                  )
              ),
              SizedBox(width: 20),
              Text("${validator.mischance}", overflow: TextOverflow.ellipsis, style: TextStyle(color: KiraColors.white.withOpacity(0.8), fontSize: 14)),
            ],
          ),
          SizedBox(height: 10),
        ]));
  }
}
