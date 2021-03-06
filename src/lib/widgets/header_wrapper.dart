import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:kira_auth/widgets/export.dart';
import 'package:kira_auth/services/export.dart';
import 'package:kira_auth/utils/export.dart';
import 'package:kira_auth/service_manager.dart';

class HeaderWrapper extends StatefulWidget {
  final Widget childWidget;
  final bool isNetworkHealthy;
  const HeaderWrapper({Key key, this.childWidget, this.isNetworkHealthy}) : super(key: key);

  @override
  _HeaderWrapperState createState() => _HeaderWrapperState();
}

class _HeaderWrapperState extends State<HeaderWrapper> {
  final _storageService = getIt<StorageService>();
  ScrollController _scrollController = ScrollController();
  double _scrollPosition = 0;
  double _opacity = 0;
  bool _loggedIn = false;

  bool display = false;

  _scrollListener() {
    setState(() {
      _scrollPosition = _scrollController.position.pixels;
    });
  }

  Future<bool> isUserLoggedIn() async {
    bool isLoggedIn = await _storageService.getLoginStatus();

    return isLoggedIn;
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);

    _storageService.getTopBarStatus().then((displayResult) {
      setState(() {
        display = displayResult;
      });
    });

    isUserLoggedIn().then((isLoggedIn) {
      if (isLoggedIn) {
        _storageService.checkPasswordExists().then((success) {
          setState(() {
            _loggedIn = success;
          });
        });
      } else {
        setState(() {
          _loggedIn = false;
        });
      }
    });
  }

  Widget topBarSmall(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    var imageSize = 30 + screenSize.width * 0.05;
    imageSize = imageSize > 60 ? 60 : imageSize;

    return AppBar(
      toolbarHeight: 120,
      backgroundColor: KiraColors.kBackgroundColor.withOpacity(0),
      elevation: 0,
      centerTitle: true,
      title: Row(
        children: [
          InkWell(
              onTap: () => Navigator.pushReplacementNamed(context, '/'),
              child: Image(image: AssetImage(Strings.logoImage), width: imageSize, height: imageSize)),
          SizedBox(width: 5),
          Text(
            Strings.kiraNetwork,
            style: TextStyle(
              color: KiraColors.white,
              fontSize: 18,
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget topBarBig(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;

    return PreferredSize(
      preferredSize: Size(screenSize.width, 1000),
      child: TopBarContents(_opacity, _loggedIn, widget.isNetworkHealthy, display),
    );
  }

  Widget bottomBarSmall(BuildContext context) {
    return Container(
        width: MediaQuery.of(context).size.width,
        margin: EdgeInsets.only(top: 50, bottom: 50, left: 30),
        color: Color(0xffffff),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            InkWell(
                child: Image(
              image: AssetImage(Strings.grayLogoImage),
              width: 140,
              height: 70,
            )),
            Text(
              Strings.copyRight,
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontFamily: 'Mulish', color: Colors.white.withOpacity(0.4), fontSize: 13, letterSpacing: 1),
            ),
          ],
        ));
  }

  Widget bottomBarBig() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 30),
      margin: EdgeInsets.symmetric(horizontal: 50),
      color: Color(0x00000000),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          InkWell(
              child: Image(
            image: AssetImage(Strings.grayLogoImage),
            width: 140,
            height: 140,
          )),
          Flexible(
            child: SizedBox(
              width: 0,
            ),
            flex: 2,
          ),
          Text(
            Strings.copyRight,
            textAlign: TextAlign.center,
            style:
                TextStyle(fontFamily: 'Mulish', color: Colors.white.withOpacity(0.4), fontSize: 13, letterSpacing: 1),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;

    _opacity = _scrollPosition < screenSize.height * 0.35 ? _scrollPosition / (screenSize.height * 0.40) : 0.9;
    _opacity = _opacity > 0.9 ? 0.9 : _opacity;
    _opacity = _loggedIn == true ? _opacity : 0.9;

    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      drawer: HamburgerDrawer(),
      body: WebScrollbar(
        color: KiraColors.kYellowColor,
        backgroundColor: Colors.purple.withOpacity(0.3),
        width: 12,
        heightFraction: 0.3,
        controller: _scrollController,
        isAlwaysShown: false,
        child: Container(
            width: screenSize.width,
            height: screenSize.height,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(Strings.backgroundImage),
                fit: BoxFit.fill,
              ),
            ),
            child: Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: ClampingScrollPhysics(),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ResponsiveWidget.isMediumScreen(context) ? topBarSmall(context) : topBarBig(context),
                        SizedBox(height: 20),
                        widget.childWidget != null ? widget.childWidget : SizedBox(height: 300),
                        ResponsiveWidget.isSmallScreen(context) ? bottomBarSmall(context) : bottomBarBig()
                      ],
                    )))),
      ),
    );
  }
}
