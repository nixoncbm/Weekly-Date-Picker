library weekly_date_picker;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:week_of_year/week_of_year.dart';
import "package:weekly_date_picker/datetime_apis.dart";

class WeeklyDatePicker extends StatefulWidget {
  WeeklyDatePicker({
    Key? key,
    required this.selectedDay,
    required this.changeDay,
    this.weekdayText = 'Week',
    this.weekdays = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    this.backgroundColor = const Color(0xFFFAFAFA),
    this.selectedDigitBackgroundColor = const Color(0xFF2A2859),
    this.selectedDigitBorderColor =
        const Color(0x00000000), // Transparent color
    this.selectedDigitColor = const Color(0xFFFFFFFF),
    this.digitsColor = const Color(0xFF000000),
    this.weekdayTextColor = const Color(0xFF303030),
    this.enableWeeknumberText = true,
    this.weeknumberColor = const Color(0xFFB2F5FE),
    this.weeknumberTextColor = const Color(0xFF000000),
    this.daysInWeek = 7,
    this.changeWeek,
    this.showLabelMonth = false,
    this.formatMonth = 'yyyy-MM-dd'
  })  : assert(weekdays.length == daysInWeek,
            "weekdays must be of length $daysInWeek"),
        super(key: key);

  /// The current selected day
  final DateTime selectedDay;

  /// Callback function with the new selected date
  final Function(DateTime) changeDay;

  /// Callback function with the new week date
  final Function(List<DateTime>)? changeWeek;

  /// Specifies the weekday text: default is 'Week'
  final String weekdayText;

  /// Specifies the weekday strings ['Mon', 'Tue'...]
  final List<String> weekdays;

  /// Background color
  final Color backgroundColor;

  /// Color of the selected day circle
  final Color selectedDigitBackgroundColor;

  /// Color of the border of the selected day circle
  final Color selectedDigitBorderColor;

  /// Color of the selected digit text
  final Color selectedDigitColor;

  /// Color of the unselected digits text
  final Color digitsColor;

  /// Is the color of the weekdays 'Mon', 'Tue'...
  final Color weekdayTextColor;

  /// Set to false to hide the weeknumber textfield to the left of the slider
  final bool enableWeeknumberText;

  /// Color of the weekday container
  final Color weeknumberColor;

  /// Color of the weekday text
  final Color weeknumberTextColor;

  /// Specifies the number of weekdays to render, default is 7, so Monday to Sunday
  final int daysInWeek;

  final bool showLabelMonth;

  final String formatMonth;

  @override
  _WeeklyDatePickerState createState() => _WeeklyDatePickerState();
}

class _WeeklyDatePickerState extends State<WeeklyDatePicker> {
  final DateTime _todaysDateTime = DateTime.now();

  // About 100 years back in time should be sufficient for most users, 52 weeks * 100
  final int _weekIndexOffset = 5200;

  late final PageController _controller;
  late final DateTime _initialSelectedDay;
  late int _weeknumberInSwipe;
  late List<DateTime> _weekDays;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: _weekIndexOffset);
    _initialSelectedDay = widget.selectedDay;
    _weeknumberInSwipe = widget.selectedDay.weekOfYear;
    _weekDays = _week(0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {


    return Column(
      children: [
        if(widget.showLabelMonth)...[
          Text("${DateFormat(widget.formatMonth).format(_weekDays.first)} - ${DateFormat(widget.formatMonth).format(_weekDays.last)}")
        ],
        Container(
          height: 64,
          color: widget.backgroundColor,
          child: Row(
            children: <Widget>[
              widget.enableWeeknumberText
                  ? Container(
                      padding: EdgeInsets.all(8.0),
                      color: widget.weeknumberColor,
                      child: Text(
                        '${widget.weekdayText} $_weeknumberInSwipe',
                        style: TextStyle(color: widget.weeknumberTextColor),
                      ),
                    )
                  : Container(),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (int index) {
                    setState(() {
                      _weeknumberInSwipe = _initialSelectedDay
                          .addDays(7 * (index - _weekIndexOffset))
                          .weekOfYear;
                      _weekDays = _week(index - _weekIndexOffset);
                    });
                    widget.changeWeek?.call(_weekDays);
                  },
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (_, weekIndex) => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: _weekdays(weekIndex - _weekIndexOffset),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Get a 5 day list of week
  List<DateTime> _week(int weekIndex) {
    List<DateTime> weekdays = [];

    for (int i = 0; i < widget.daysInWeek; i++) {
      final int offset = i + 1 - _initialSelectedDay.weekday;
      final int daysToAdd = weekIndex * 7 + offset;
      final DateTime dateTime = _initialSelectedDay.addDays(daysToAdd);
      weekdays.add(dateTime);
    }
    return weekdays;
  }

  // Builds a 5 day list of DateButtons
  List<Widget> _weekdays(int weekIndex) {
    List<Widget> weekdays = [];

    for (int i = 0; i < widget.daysInWeek; i++) {
      final int offset = i + 1 - _initialSelectedDay.weekday;
      final int daysToAdd = weekIndex * 7 + offset;
      final DateTime dateTime = _initialSelectedDay.addDays(daysToAdd);
      weekdays.add(_dateButton(dateTime));
    }
    return weekdays;
  }

  Widget _dateButton(DateTime dateTime) {
    final String weekday = widget.weekdays[dateTime.weekday - 1];
    final bool isSelected = dateTime.isSameDateAs(widget.selectedDay);
    final bool isTodaysDate = dateTime.isSameDateAs(_todaysDateTime);

    return Expanded(
      child: GestureDetector(
        onTap: () => widget.changeDay(dateTime),
        child: Container(
          // Bugfix, the transparent container makes the GestureDetector fill the Expanded
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Text(
                  '$weekday',
                  style:
                      TextStyle(fontSize: 12.0, color: widget.weekdayTextColor),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(1.0),
                decoration: BoxDecoration(
                    // Border around today's date
                    color: isTodaysDate
                        ? widget.selectedDigitBorderColor
                        : Colors.transparent,
                    shape: BoxShape.circle),
                child: CircleAvatar(
                  backgroundColor: isSelected
                      ? widget.selectedDigitBackgroundColor
                      : widget.backgroundColor,
                  radius: 14.0,
                  child: Text(
                    '${dateTime.day}',
                    style: TextStyle(
                        fontSize: 16.0,
                        color: isSelected
                            ? widget.selectedDigitColor
                            : widget.digitsColor),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
