import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:geo_monitor/library/hive_util.dart';

import 'package:lat_lng_to_timezone/lat_lng_to_timezone.dart';

import '../../api/data_api.dart';
import '../../api/prefs_og.dart';
import '../../bloc/organization_bloc.dart';
import '../../data/project_position.dart';
import '../../data/user.dart';
import '../../data/weather/daily_forecast.dart';
import '../../emojis.dart';
import '../../functions.dart';
import '../../generic_functions.dart';

class DailyForecastPage extends StatefulWidget {
  const DailyForecastPage({Key? key}) : super(key: key);

  @override
  DailyForecastPageState createState() => DailyForecastPageState();
}

class DailyForecastPageState extends State<DailyForecastPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final mm =
      '${E.nice}${E.nice}${E.nice}${E.nice}${E.nice} DailyForecastPage: ';

  DailyForecast? dailyForecast;
  var forecastBags = <ForecastBag>[];
  var positions = <ProjectPosition>[];
  bool busy = false;
  User? user;

  var currentForecasts = <DailyForecast>[];

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _getDailyForecasts();
  }

  void _getDailyForecasts() async {
    setState(() {
      busy = true;
    });
    try {
      pp('$mm  get project positions and get forecast for each ....');
      user = await prefsOGx.getUser();
      positions = await organizationBloc.getProjectPositions(
          organizationId: user!.organizationId!, forceRefresh: false);
      for (var pos in positions) {
        String tz = latLngToTimezoneString(
            pos.position!.coordinates[1], pos.position!.coordinates[0]);
        final forecasts = await DataAPI.getDailyForecast(
            latitude: pos.position!.coordinates[1],
            longitude: pos.position!.coordinates[0],
            timeZone: tz,
            projectId: pos.projectId!,
            projectName: pos.projectName!,
            projectPositionId: pos.projectPositionId!);

        pp('$mm daily forecast received: 🍎🍎🍎🍎 ${forecasts.length} 🍎🍎🍎🍎');
        //
        if (forecasts.isNotEmpty) {
          pp('$mm 🔵🔵🔵 First Daily Forecast: 🔵🔵🔵 '
              '${prettyPrint(forecasts[0].toJson(), 'Daily Forecast')} 🔵');
        }
        forecastBags
            .add(ForecastBag(projectPosition: pos, forecasts: forecasts));
      }
      pp('\n\n$mm 🔵🔵🔵 All Daily Forecasts per ProjectPosition: 🔵🔵🔵 ${forecastBags.length}');

      await _setCurrentForecasts();
    } catch (e) {
      pp(e);
      if (mounted) {
        showToast(message: '$e', context: context);
      }
    }

    setState(() {
      busy = false;
    });
  }

  Future<void> _setCurrentForecasts() async {
    for (var bag in forecastBags) {
      currentForecasts.add(bag.forecasts.first);
    }
    if (currentForecasts.length == 1) {
      //todo 1 project position - so show all 7 days
      currentForecasts = forecastBags.first.forecasts;
    } else {
      var distinctProjectMap = HashMap<String, String>();
      for (var bag in forecastBags) {
        if (distinctProjectMap.containsKey(bag.projectPosition.projectId!)) {
          //ignore
        } else {
          distinctProjectMap[bag.projectPosition.projectId!] = "Don't matte";
        }
      }

      if (distinctProjectMap.length == 1) {
        //todo this project could have just 1 position OR has multiple project positions
        var id = distinctProjectMap.keys.toList().first;
        var positions = await cacheManager.getProjectPositions(id);
        if (positions.length == 1) {
          currentForecasts = forecastBags.first.forecasts;
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: const Text('Daily Weather Forecast'),
      ),
      body: Stack(
        children: [
          busy
              ? const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 4,
                        backgroundColor: Colors.pink),
                  ),
                )
              : OneDayProjectPositionForecastsPage(forecasts: currentForecasts),
        ],
      ),
    ));
  }
}

class ForecastBag {
  late ProjectPosition projectPosition;
  late List<DailyForecast> forecasts;

  ForecastBag({required this.projectPosition, required this.forecasts});
}

class DayForecastCard extends StatefulWidget {
  const DayForecastCard({Key? key, required this.forecast}) : super(key: key);

  final DailyForecast forecast;
  @override
  State<DayForecastCard> createState() => _DayForecastCardState();
}

class _DayForecastCardState extends State<DayForecastCard> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 360,
          child: Card(
            elevation: 4,
            shape: getRoundedBorder(radius: 16),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  const SizedBox(
                    height: 12,
                  ),
                  Text(
                    getFormattedDateLong(widget.forecast.date!, context),
                    style: myTextStyleSmall(context),
                  ),
                  const SizedBox(
                    height: 12,
                  ),

                  Text(widget.forecast.projectName!,
                    style: myTextStyleMedium(context),
                  ),
                  const SizedBox(
                    height: 36,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 12,),
                      Text(
                        '${widget.forecast.apparentMaxTemp}',
                        style: myNumberStyleLargest(context),
                      ),
                      const SizedBox(width: 4,),
                       Text(' \u2103 ', style: myTextStyleMedium(context),),
                      const SizedBox(width: 24,),
                      const Image(
                        width: 48, height: 48,
                        image: AssetImage('assets/weather/cloudy.png', ),
                      ),
                      const SizedBox(width: 24,),
                    ],
                  ),
                  const SizedBox(height: 12,),
                  SunriseSunset(sunrise: getFormattedDateHour(widget.forecast.sunrise!),
                      sunset: getFormattedDateHour( widget.forecast.sunset!)),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }
}
class SunriseSunset extends StatelessWidget {
  const SunriseSunset({Key? key, required this.sunrise, required this.sunset}) : super(key: key);
  final String sunrise, sunset;
  @override
  Widget build(BuildContext context) {
    return  SizedBox(height: 60, width: 300,
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Sunrise', style: myTextStyleTiny(context),),
              const SizedBox(width: 8,),
              Text(sunrise, style: myTextStyleSmall(context),),
            ],
          ),
          const SizedBox(height: 12,),
          Row(mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Sunset', style: myTextStyleTiny(context)),
              const SizedBox(width: 8,),
              Text(sunset, style: myTextStyleSmall(context)),
            ],
          ),
        ],
      ),
    );
  }
}

///one day forecast for each project position OR if org has just one project
class OneDayProjectPositionForecastsPage extends StatefulWidget {
  const OneDayProjectPositionForecastsPage({Key? key, required this.forecasts})
      : super(key: key);
  final List<DailyForecast> forecasts;
  @override
  State<OneDayProjectPositionForecastsPage> createState() =>
      _OneDayProjectPositionForecastsPageState();
}

class _OneDayProjectPositionForecastsPageState
    extends State<OneDayProjectPositionForecastsPage> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
             const SizedBox(
              height: 48,
            ),
             Padding(
              padding: const EdgeInsets.all(28.0),
              child: Text('This is the weather forecast at all your project locations. '
                  'Swipe right to see the rest of the show! ', style: myTextStyleSmall(context),),
            ),
            const SizedBox(height: 24,),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: ListView.builder(
                    itemCount: widget.forecasts.length,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (_, index) {
                      var fc = widget.forecasts.elementAt(index);
                      return DayForecastCard(forecast: fc);
                    }),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
