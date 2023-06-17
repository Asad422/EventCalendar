import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:intl/intl.dart';
import 'package:native_notify/native_notify.dart';
import 'package:project/splash_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:velocity_x/velocity_x.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
 
  await initializeDateFormatting('ru',null);
    WidgetsFlutterBinding.ensureInitialized();
     NativeNotify.initialize(3068, 'CU6FgIDICOw6xEmXiGxptd');
   runApp(const MyApp());
}

class Event {
  final String title;
  final String? description;
  final DateTime date;
  final String id;
  final String time;
  Event({
    required this.title,
    this.description,
    required this.date,
    required this.time,
    required this.id,
  });

  factory Event.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot,
      [SnapshotOptions? options]) {
    final data = snapshot.data()!;
    return Event(
      time: data['time'],
      date: data['date'].toDate(),
      title: data['title'],
      description: data['description'],
      id: snapshot.id,
    );
  }

  Map<String, Object?> toFirestore() {
    return {
      "date": Timestamp.fromDate(date),
      "title": title,
      "description": description,
      'time' : time,
    };
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      home: SplashScreen()
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late DateTime _focusedDay;
  late DateTime _firstDay;
  late DateTime _lastDay;
  var password_controller = TextEditingController();
  late DateTime _selectedDay;
  late CalendarFormat _calendarFormat;
  late Map<DateTime, List<Event>> _events;

  int getHashCode(DateTime key) {
    return key.day * 1000000 + key.month * 10000 + key.year;
  }

  @override
  void initState() {
    super.initState();
    _events = LinkedHashMap(
      equals: isSameDay,
      hashCode: getHashCode,
    );
    _focusedDay = DateTime.now();
    _firstDay = DateTime.now().subtract(const Duration(days: 1000));
    _lastDay = DateTime.now().add(const Duration(days: 1000));
    _selectedDay = DateTime.now();
    _calendarFormat = CalendarFormat.month;
    _loadFirestoreEvents();
  }

  _loadFirestoreEvents() async {
    final firstDay = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    _events = {};

    final snap = await FirebaseFirestore.instance
        .collection('event')
        .where('date', isGreaterThanOrEqualTo: firstDay)
        .where('date', isLessThanOrEqualTo: lastDay)
        .withConverter(
            fromFirestore: Event.fromFirestore,
            toFirestore: (event, options) => event.toFirestore())
        .get();
    for (var doc in snap.docs) {
      final event = doc.data();
      final day =
          DateTime.utc(event.date.year, event.date.month, event.date.day);
      if (_events[day] == null) {
        _events[day] = [];
      }
      _events[day]!.add(event);
    }
    setState(() {});
  }

  List<Event> _getEventsForTheDay(DateTime day) {
    return _events[day] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(30,0,179,1),
        title: const Text('Календарь'),
        actions: [
          IconButton(onPressed: (){
            
              showDialog<String>(
                
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Введите пароль'),
          
          actions: <Widget>[
            TextField(
              controller: password_controller,
              decoration: InputDecoration(
                hintText: "Пароль"
              ),
            ),
            TextButton(
              onPressed: () {
                if(password_controller.value.text == '8742174'){
                  Get.to(()=>Admin());
                }
              },
              child: const Text('Ок'),
            ),
          ],
        ),
           );
          }, icon: Icon(Icons.admin_panel_settings))
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(child: 
             StreamBuilder(
                    stream: Stream.periodic(const Duration(seconds: 1)),
                    builder: (context, snapshot) {
                      return Text(
                        
                        DateFormat('MM/dd/yyyy hh:mm:ss').format(DateTime.now()),
                        style: TextStyle(color: Colors.black,fontSize: 25),);
                    },
                  ),),
          ),
        
           TableCalendar(
            headerStyle: HeaderStyle(
              titleCentered: true,
              titleTextFormatter: (date, locale) => DateFormat.yMMMd(locale).format(date),
            
             
            ),
            startingDayOfWeek: StartingDayOfWeek.monday,
            availableCalendarFormats: {
              CalendarFormat.month : 'Месяц',
              CalendarFormat.twoWeeks :'Две недели',
              CalendarFormat.week : 'Неделя'
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            eventLoader: _getEventsForTheDay,
          shouldFillViewport: false,
          locale: 'ru_RU',
         focusedDay: _focusedDay,
            firstDay: _firstDay,
            calendarFormat: _calendarFormat,
            lastDay: _lastDay,
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
              _loadFirestoreEvents();
            },
             selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            onDaySelected: (selectedDay, focusedDay) {
             
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
               
              });},
              
              calendarStyle: const CalendarStyle(
              weekendTextStyle: TextStyle(
                color: Colors.red,
              ),
              selectedDecoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red,
              ),
            ),
            
            
        ),
         ..._getEventsForTheDay(_selectedDay).map(
            (event) => ListTile(
              title: Text(
                event.title,
              ),
              subtitle: Text(
                 DateFormat('dd-MM-yyyy').format(event.date) +  " " + event.time
              ),
            ),
          )
        ],
      )
      
      
    );
  }
}

class AddEvent extends StatefulWidget {
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? selectedDate;
  const AddEvent(
      {Key? key,
      required this.firstDate,
      required this.lastDate,
      this.selectedDate})
      : super(key: key);

  @override
  State<AddEvent> createState() => _AddEventState();
}

class _AddEventState extends State<AddEvent> {
  late DateTime _selectedDate;
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _timeController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Добавить событие")),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          InputDatePickerFormField(
            fieldLabelText: 'Дата',
            firstDate: widget.firstDate,
            lastDate: widget.lastDate,
            initialDate: _selectedDate,
            onDateSubmitted: (date) {
              setState(() {
                _selectedDate = date;
              });
            },
          ),
          TextField(
      
            keyboardType: TextInputType.datetime,
            controller: _timeController,
            maxLines: 1,
            decoration: const InputDecoration(labelText: 'Время'),
          ),
          TextField(
            controller: _titleController,
            maxLines: 1,
            decoration: const InputDecoration(labelText: 'Название'),
          ),
          TextField(
            controller: _descController,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Описание'),
          ),
          ElevatedButton(
            onPressed: () {
              _addEvent();
            },
            child: const Text("Сохранить"),
          ),
        ],
      ),
    );
  }

  void _addEvent() async {
    final title = _titleController.text;
    final description = _descController.text;
    final time = _timeController.text;
    if (title.isEmpty) {
      return;
    }
    await FirebaseFirestore.instance.collection('event').doc(title).set({
      "title": title,
      "time" :time , 
      "description": description,
      "date": Timestamp.fromDate(_selectedDate),
    });
    if (mounted) {
      Navigator.pop<bool>(context, true);
    }
  }
}

class Admin extends StatefulWidget {
  const Admin({super.key});

  @override
  State<Admin> createState() => _AdminState();
}

class _AdminState extends State<Admin> {
 
  late DateTime _focusedDay;
  late DateTime _firstDay;
  late DateTime _lastDay;
  var password_controller = TextEditingController();
  late DateTime _selectedDay;
  late CalendarFormat _calendarFormat;
  late Map<DateTime, List<Event>> _events;

  int getHashCode(DateTime key) {
    return key.day * 1000000 + key.month * 10000 + key.year;
  }

  @override
  void initState() {
    super.initState();
    _events = LinkedHashMap(
      equals: isSameDay,
      hashCode: getHashCode,
    );
    _focusedDay = DateTime.now();
    _firstDay = DateTime.now().subtract(const Duration(days: 1000));
    _lastDay = DateTime.now().add(const Duration(days: 1000));
    _selectedDay = DateTime.now();
    _calendarFormat = CalendarFormat.month;
    _loadFirestoreEvents();
  }

  _loadFirestoreEvents() async {
    final firstDay = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    _events = {};

    final snap = await FirebaseFirestore.instance
        .collection('event')
        .where('date', isGreaterThanOrEqualTo: firstDay)
        .where('date', isLessThanOrEqualTo: lastDay)
        .withConverter(
            fromFirestore: Event.fromFirestore,
            toFirestore: (event, options) => event.toFirestore())
        .get();
    for (var doc in snap.docs) {
      final event = doc.data();
      final day =
          DateTime.utc(event.date.year, event.date.month, event.date.day);
      if (_events[day] == null) {
        _events[day] = [];
      }
      _events[day]!.add(event);
    }
    setState(() {});
  }

  List<Event> _getEventsForTheDay(DateTime day) {
    return _events[day] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(30,0,179,1),
        title: const Text('Админ-панель'),
        
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: StreamBuilder(
                  stream: Stream.periodic(const Duration(seconds: 1)),
                  builder: (context, snapshot) {
                    return Text(
                      
                      DateFormat('MM/dd/yyyy hh:mm:ss').format(DateTime.now()),
                      style: TextStyle(color: Colors.black,fontSize: 25),);
                  },
                ),
            ),
          ),
          TableCalendar(
            headerStyle: HeaderStyle(
              titleCentered: true,
              titleTextFormatter: (date, locale) => DateFormat.yMMMd(locale).format(date),
            
             
            ),
            startingDayOfWeek: StartingDayOfWeek.monday,
            availableCalendarFormats: {
              CalendarFormat.month : 'Месяц',
              CalendarFormat.twoWeeks :'Две недели',
              CalendarFormat.week : 'Неделя'
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            eventLoader: _getEventsForTheDay,
          shouldFillViewport: false,
          locale: 'ru_RU',
         focusedDay: _focusedDay,
            firstDay: _firstDay,
            calendarFormat: _calendarFormat,
            lastDay: _lastDay,
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
              _loadFirestoreEvents();
            },
             selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            onDaySelected: (selectedDay, focusedDay) {
             
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
               
              });},
              
              calendarStyle: const CalendarStyle(
              weekendTextStyle: TextStyle(
                color: Colors.red,
              ),
              selectedDecoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red,
              ),
            ),
            
            
        ), ..._getEventsForTheDay(_selectedDay).map
          (
            
        
            (event ) => 
          
            Slidable(
               endActionPane:  ActionPane(
                motion: ScrollMotion(),
                children: [
                  SlidableAction(
                    onPressed:(BuildContext context){
                        FirebaseFirestore.instance.collection("event").doc(event.title  ).delete();
                         _loadFirestoreEvents();
                    },
                   backgroundColor: Color(0xFFFE4A49),
                    foregroundColor: Colors.white,
                    icon: Icons.delete,
                    label: 'Удалить',
                  )]),
              child: event.id != null ? 
            ListTile(
              title: Text(
                event.title,
              ),
              subtitle: Text(
                 DateFormat('dd-MM-yyyy').format(event.date) +  " " + event.time
              ),
            ): Text('Нет событий')
          ))
        ],
      ),
       floatingActionButton: FloatingActionButton(
        backgroundColor:  Color.fromRGBO(30,0,179,1),
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => AddEvent(
                firstDate: _firstDay,
                lastDate: _lastDay,
                selectedDate: _selectedDay,
              ),
            ),
          );
          if (result ?? false) {
            _loadFirestoreEvents();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}



