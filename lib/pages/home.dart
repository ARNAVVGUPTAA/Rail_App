import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:adaptive_theme/adaptive_theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Color getRandomColor() {
    final Random random = Random();
    return Color.fromARGB(
      255,
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color getColour() {
      return AdaptiveTheme.of(context).mode.isDark
          ? Colors.white
          : Colors.black;
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    final double baseFontSize = screenWidth * 0.05;
    final List<Widget> carouselItems = [
      Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/alohomora.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
            child: Text('ALOHOMORA',
                style: TextStyle(fontSize: baseFontSize, color: Colors.white))),
      ),
      Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            colorFilter: ColorFilter.mode(
                Colors.black.withAlpha(120), BlendMode.colorDodge),
            image: AssetImage('assets/images/REChase.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
            child: Text('REChase',
                style: TextStyle(fontSize: baseFontSize, color: Colors.white))),
      ),
      Container(
        decoration: BoxDecoration(
          image: DecorationImage(
              image: AssetImage('assets/images/vivek.jpeg'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                  Colors.black.withAlpha(120), BlendMode.colorDodge)),
        ),
        child: Center(
            child: Text('INTERNSHIP AND PLACEMENT TALKS',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: baseFontSize, color: Colors.white))),
      ),
      Container(
        decoration: BoxDecoration(
          image: DecorationImage(
              image: AssetImage('assets/images/session.jpeg'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                  Colors.black.withAlpha(120), BlendMode.colorDodge)),
        ),
        child: Center(
            child: Text('SESSION WITH FACULTY ADVISOR',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: baseFontSize, color: Colors.white))),
      ),
      Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            colorFilter: ColorFilter.mode(
                Colors.black.withAlpha(120), BlendMode.colorDodge),
            image: AssetImage('assets/images/RECode.jpeg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
            child: Text('RECODE',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: baseFontSize, color: Colors.white))),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/icons/logoInverted.svg',
              color: getColour(),
              height: 30,
              width: 30,
            ),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'REC',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: baseFontSize,
                      color: getColour(),
                    ),
                  ),
                  TextSpan(
                    text: 'ursion',
                    style: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: baseFontSize,
                      color: getColour(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.dark_mode),
            onPressed: () {
              AdaptiveTheme.of(context).mode.isDark
                  ? AdaptiveTheme.of(context).setLight()
                  : AdaptiveTheme.of(context).setDark();
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              child: Text(''),
            ),
            ListTile(
              title: Text('About Us'),
              onTap: () {},
            ),
            ListTile(
              title: Text('Contact Us'),
              onTap: () {},
            ),
          ],
        ),
      ),
      body: ListView(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'REC',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: baseFontSize * 13,
                            color: getColour(),
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.only(
                            top: 0.0, left: 20, right: 10, bottom: 0),
                        child: Text(
                          "We are the programming community of NIT Durgapur, with focus on improving coding culture institute wide by conducting regular lectures from beginner to advance topics of programming. Our goal is to increase student's participation in inter-collegiate contest like ACM-ICPC and help them get better.",
                          style: TextStyle(
                              color: getColour(), fontSize: baseFontSize * 0.8),
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                ),
                RotatedBox(
                  quarterTurns: 1,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'URSION',
                      style: TextStyle(
                        fontSize: baseFontSize * 4,
                        color: getColour(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 40,
          ),
          Container(
            height: 200,
            child: CarouselSlider(
              options: CarouselOptions(
                height: 200.0,
                autoPlay: true,
                enlargeCenterPage: true,
                aspectRatio: 16 / 9,
                autoPlayCurve: Curves.fastOutSlowIn,
                enableInfiniteScroll: true,
                autoPlayAnimationDuration: Duration(milliseconds: 800),
                viewportFraction: 0.8,
              ),
              items: carouselItems
                  .map((item) => Container(
                        child: Center(
                          child: item,
                        ),
                      ))
                  .toList(),
            ),
          ),
          Divider(
            height: 40,
          ),
          Container(
            padding: EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TweenAnimationBuilder<int>(
                  curve: Curves.easeOut,
                  tween: IntTween(begin: 0, end: 600),
                  duration: Duration(seconds: 5),
                  builder: (context, value, child) {
                    return Text(
                      '$value+ hours of teaching',
                      style: TextStyle(
                        fontSize: baseFontSize,
                        fontWeight: FontWeight.bold,
                        color: getColour(),
                      ),
                      textAlign: TextAlign.left,
                    );
                  },
                ),
                TweenAnimationBuilder<int>(
                  curve: Curves.easeOut,
                  tween: IntTween(begin: 0, end: 10),
                  duration: Duration(seconds: 5),
                  builder: (context, value, child) {
                    return Text(
                      '$value+ years of teaching',
                      style: TextStyle(
                        fontSize: baseFontSize,
                        fontWeight: FontWeight.bold,
                        color: getColour(),
                      ),
                      textAlign: TextAlign.left,
                    );
                  },
                ),
                TweenAnimationBuilder<int>(
                  curve: Curves.easeOut,
                  tween: IntTween(begin: 0, end: 69),
                  duration: Duration(seconds: 5),
                  builder: (context, value, child) {
                    return Text(
                      '$value+ Offline/Online Contests',
                      style: TextStyle(
                        fontSize: baseFontSize,
                        fontWeight: FontWeight.bold,
                        color: getColour(),
                      ),
                      textAlign: TextAlign.left,
                    );
                  },
                ),
                TweenAnimationBuilder<int>(
                  curve: Curves.easeOut,
                  tween: IntTween(begin: 0, end: 2000),
                  duration: Duration(seconds: 5),
                  builder: (context, value, child) {
                    return Text(
                      '$value+ hours of teaching',
                      style: TextStyle(
                        fontSize: baseFontSize,
                        fontWeight: FontWeight.bold,
                        color: getColour(),
                      ),
                      textAlign: TextAlign.left,
                    );
                  },
                ),
              ],
            ),
          ),
          Divider(
            height: 40,
          ),
          Column(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                child: Text(
                  'Made with ❤️ by RECursion',
                  style: TextStyle(
                    fontSize: baseFontSize * 0.75, // Adjusted font size
                    color: getColour(),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(10),
                child: TextField(
                  maxLength: 200,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'We would love your feedback!',
                    labelStyle: TextStyle(
                        fontSize: baseFontSize * 0.75), // Adjusted font size
                  ),
                  style: TextStyle(
                      fontSize: baseFontSize * 0.75), // Adjusted font size
                ),
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contact Us',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: baseFontSize * 0.75,
                    fontWeight: FontWeight.bold,
                    color: getColour(),
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.location_on, color: getColour()),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'NIT Durgapur, West Bengal, India',
                        style: TextStyle(
                            fontSize: baseFontSize * 0.6, color: getColour()),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.phone, color: getColour()),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '+91 84209 98766',
                        style: TextStyle(
                            fontSize: baseFontSize * 0.6, color: getColour()),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.email, color: getColour()),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'recursion.nit@gmail.com',
                        style: TextStyle(
                            fontSize: baseFontSize * 0.6, color: getColour()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        destinations: [
          NavigationDestination(
            icon: Badge(child: Icon(Icons.home_outlined)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: 'Event',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            label: 'Team',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => {},
        label: Text('askREC'),
        icon: Icon(Icons.chat_bubble_outline),
      ),
    );
  }
}
