import 'dart:async';
import 'dart:ui';
import 'dart:math';

import 'package:flutter_countdown_timer/flutter_countdown_timer.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:kira_auth/models/proposal.dart';
import 'package:kira_auth/utils/colors.dart';
import 'package:kira_auth/utils/export.dart';

import 'custom_button.dart';

class ProposalsTable extends StatefulWidget {
  final List<Proposal> proposals;
  final List<int> voteable;
  final String expandedId;
  final Function onTapRow;
  final Function onTapVote;
  final Function loadMore;
  final StreamController controller;
  final Function setPage;
  final int page;
  final int totalPages;
  final bool isFiltering;

  ProposalsTable({
    Key key,
    this.proposals,
    this.voteable,
    this.expandedId,
    this.onTapRow,
    this.onTapVote,
    this.controller,
    this.totalPages,
    this.isFiltering,
    this.loadMore,
    this.page,
    this.setPage,
  }) : super();

  @override
  _ProposalsTableState createState() => _ProposalsTableState();
}

class _ProposalsTableState extends State<ProposalsTable> {
  int voteOption;
  List<ExpandableController> controllers = List.filled(PAGE_COUNT, null);
  int startAt;
  int endAt;
  List<Proposal> currentProposals = <Proposal>[];
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
    if (!mounted) return;
    if (newPage > 0)
      widget.setPage(newPage);
    else if (newQuery != null && !first)
      widget.setPage(1);
    var page = newPage > 0 ? newPage : newQuery != null ? 1 : widget.page;
    this.setState(() {
      startAt = page * PAGE_COUNT - PAGE_COUNT;
      endAt = startAt + PAGE_COUNT;

      currentProposals = [];
      var proposals = query.isEmpty ? widget.proposals : widget.proposals.where((x) => x.proposalId == query ||
          x.content.getName().toLowerCase().contains(query) || x.getStatusString().toLowerCase().contains(query)).toList();
      if (proposals.length > startAt)
        currentProposals = proposals.sublist(startAt, min(endAt, proposals.length));
      if (currentProposals.length < PAGE_COUNT && (proposals.length / PAGE_COUNT).ceil() < widget.totalPages)
        widget.loadMore();
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
                      ...currentProposals
                          .map((proposal) =>
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
                                  header: addRowHeader(proposal),
                                  collapsed: Container(),
                                  expanded: addRowBody(proposal),
                                ),
                              ),
                            ),
                          )
                      ).toList(),
                    ])
            )));
  }

  Widget addNavigateControls() {
    var proposals = query.isEmpty ? widget.proposals : widget.proposals.where((x) => x.proposalId == query ||
        x.content.getName().toLowerCase().contains(query) || x.getStatusString().toLowerCase().contains(query)).toList();
    var totalPages = widget.isFiltering ? (proposals.length / PAGE_COUNT).ceil() : widget.totalPages;

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

  refreshExpandStatus({String newExpandId = ""}) {
    widget.onTapRow(newExpandId);
    this.setState(() {
      currentProposals.asMap().forEach((index, proposal) {
        controllers[index].expanded = proposal.proposalId == newExpandId;
      });
    });
  }

  Widget addRowHeader(Proposal proposal) {
    return Builder(
        builder: (context) {
          var controller = ExpandableController.of(context);
          controllers[currentProposals.indexOf(proposal)] = controller;

          return InkWell(
              onTap: () {
                var newExpandId = proposal.proposalId != widget.expandedId ? proposal.proposalId : "";
                refreshExpandStatus(newExpandId: newExpandId);
              },
              child: Container(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Text(proposal.proposalId,
                            textAlign: TextAlign.center, style: TextStyle(color: KiraColors.white.withOpacity(0.8), fontSize: 16)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(proposal.content.getName(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center, style: TextStyle(color: KiraColors.white.withOpacity(0.8), fontSize: 16)),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(proposal.getStatusString(),
                            textAlign: TextAlign.center, style: TextStyle(color: proposal.getStatusColor(), fontSize: 16)),
                      ),
                      Expanded(
                          flex: 1,
                          child: Center(
                            child: CountdownTimer(
                                endTime: proposal.getTimer,
                                endWidget: Center(
                                  child: Text(proposal.getEndTime, style: TextStyle(color: proposal.getTimeColor(), fontSize: 16)),
                                ),
                                textStyle: TextStyle(color: proposal.getTimeColor(), fontSize: 16)
                            ),
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
                  )
              )
          );
        }
    );
  }

  Widget addRowBody(Proposal proposal) {
    final fieldWidth = ResponsiveWidget.isSmallScreen(context) ? 80.0 : 150.0;
    final voteOptions = proposal.availableVoteOptions().map((e) => VoteOption.values.indexOf(e)).toList();
    var allColors = [KiraColors.kGrayColor, KiraColors.green3, KiraColors.orange1, KiraColors.danger, KiraColors.danger];
    var colorList = allColors.where((element) {
      final colorIndex = allColors.indexOf(element);
      return proposal.voteResults.keys.contains(Strings.voteTitles[colorIndex]);
    }).toList();
    final hasVotes = colorList.isNotEmpty;

    return Container(
        padding: EdgeInsets.all(10),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                flex: 2,
                child: Column(children: [
                  Row(
                    children: [
                      Container(
                          width: fieldWidth,
                          child: Text("Voters",
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  color: KiraColors.white.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.bold))),
                      SizedBox(width: 20),
                      Text("${proposal.voteability.count}",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: KiraColors.white.withOpacity(0.8), fontSize: 14)),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                          width: fieldWidth,
                          child: Text("Status",
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  color: KiraColors.white.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.bold))),
                      SizedBox(width: 20),
                      Text(proposal.getStatusString(),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: KiraColors.white.withOpacity(0.8), fontSize: 14)),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                          width: fieldWidth,
                          child: Text("Description",
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  color: KiraColors.white.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.bold))),
                      SizedBox(width: 20),
                      Flexible(
                          child: Text(proposal.description,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 3,
                              style: TextStyle(color: KiraColors.white.withOpacity(0.8), fontSize: 14))),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                          width: fieldWidth,
                          child: Text("Content",
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  color: KiraColors.white.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.bold))),
                      SizedBox(width: 20),
                      Flexible(
                          child: Text(proposal.getContent,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 4,
                              style: TextStyle(color: KiraColors.white.withOpacity(0.8), fontSize: 14))),
                    ],
                  ),
                ]),
              ),
              (!hasVotes || !ResponsiveWidget.isLargeScreen(context)) ? Container() :
              Container(
                padding: EdgeInsets.only(left: 20, right: 20),
                child: PieChart(
                  dataMap: proposal.voteResults,
                  animationDuration: Duration(milliseconds: 800),
                  chartLegendSpacing: 20,
                  chartRadius: 200,
                  colorList: colorList,
                  initialAngleInDegree: 0,
                  chartType: ChartType.disc,
                  legendOptions: LegendOptions(
                    showLegends: true,
                    showLegendsInRow: false,
                    legendShape: BoxShape.circle,
                    legendTextStyle: TextStyle(color: KiraColors.white),
                  ),
                  chartValuesOptions: ChartValuesOptions(
                      showChartValueBackground: false,
                      showChartValuesInPercentage: true,
                      decimalPlaces: 1,
                      chartValueStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)
                  ),
                ),
              ),
              !proposal.isVoteable ? Container() :
              Expanded(
                  flex: 1,
                  child: Column(
                      children: <Widget>[
                        Text(hasVotes ? Strings.voteUpdate : Strings.voteProposal,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: KiraColors.white, fontSize: 16)),
                        SizedBox(height: 20),
                        Container(
                            width: 200,
                            color: KiraColors.kPrimaryColor,
                            child: ButtonTheme(
                              alignedDropdown: true,
                              child: DropdownButton<int>(
                                  dropdownColor: KiraColors.kPurpleColor,
                                  value: voteOption,
                                  icon: Icon(Icons.arrow_drop_down, color: KiraColors.white),
                                  iconSize: 32,
                                  isExpanded: true,
                                  hint: Text(Strings.voteHint,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: KiraColors.white, fontSize: 15)),
                                  underline: SizedBox(),
                                  onChanged: (int option) {
                                    setState(() {
                                      voteOption = option;
                                    });
                                  },
                                  items: voteOptions.map<DropdownMenuItem<int>>((int option) {
                                    return DropdownMenuItem<int>(
                                      value: option,
                                      child: Container(
                                          height: 25,
                                          alignment: Alignment.topCenter,
                                          child: Text(Strings.voteTitles[option],
                                              textAlign: TextAlign.center,
                                              style: TextStyle(color: KiraColors.white, fontSize: 15))),
                                    );
                                  }).toList()),
                            )
                        ),
                        SizedBox(height: 20),
                        CustomButton(
                            text: hasVotes ? Strings.update : Strings.vote,
                            width: 100,
                            height: 40,
                            style: 1,
                            onPressed: () {
                              if (voteOption < 1) return;
                              widget.onTapVote(proposal.proposalId, voteOption);
                            }),
                      ])
              )
            ])
    );
  }
}
