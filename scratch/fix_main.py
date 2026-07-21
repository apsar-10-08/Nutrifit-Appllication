import re
import json

def fix_main_dart():
    with open(r'c:\project\NutriFit_Flutter_Supabase\lib\main.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Add notification service import
    if 'import \'notification_service.dart\';' not in content:
        content = content.replace("import 'package:supabase_flutter/supabase_flutter.dart';", "import 'package:supabase_flutter/supabase_flutter.dart';\nimport 'notification_service.dart';")

    # 2. Add AppController variables
    if 'List<String> aiHistory = [];' not in content:
        app_ctrl_vars = """
  List<String> aiHistory = [];
  String get latestAIAdvice => aiHistory.isNotEmpty ? aiHistory.last : 'Tap refresh to get your first personalized advice!';
  final Map<String, bool> reminders = {'Breakfast': false, 'Lunch': false, 'Dinner': false, 'Workout': false};
"""
        content = content.replace("final completedWorkouts=<String>{};", f"final completedWorkouts=<String>{{}};\n{app_ctrl_vars}")

    # 3. Add AppController methods
    if 'void addAIAdvice(String advice)' not in content:
        methods = """
  void addAIAdvice(String advice) {
    aiHistory.add(advice);
    persist();
    notifyListeners();
  }

  void toggleReminder(String key, String timeStr, bool value) {
    reminders[key] = value;
    persist();
    notifyListeners();
    if (value) {
      final parts = timeStr.split(' ');
      final timeParts = parts[0].split(':');
      int h = int.parse(timeParts[0]);
      int m = int.parse(timeParts[1]);
      if (parts[1] == 'PM' && h != 12) h += 12;
      if (parts[1] == 'AM' && h == 12) h = 0;
      NotificationService().scheduleDailyNotification(id: reminders.keys.toList().indexOf(key), title: 'NutriFit Reminder', body: 'Time for your $key!', hour: h, minute: m);
    } else {
      NotificationService().cancelNotification(reminders.keys.toList().indexOf(key));
    }
  }
"""
        content = content.replace("Future<void> persist() async {", f"{methods}\n  Future<void> persist() async {{")

    # 4. AppController init & persist
    if "aiHistory.addAll(p.getStringList('aiHistory')" not in content:
        content = content.replace("wishlist.addAll(p.getStringList('wishlist') ?? []);", "wishlist.addAll(p.getStringList('wishlist') ?? []);\n    aiHistory.addAll(p.getStringList('aiHistory') ?? []);\n    final rawRem = p.getString('reminders'); if (rawRem != null) reminders.addAll((jsonDecode(rawRem) as Map<String,dynamic>).map((k,v)=>MapEntry(k, v as bool)));")
        content = content.replace("await p.setStringList('wishlist', wishlist.toList());", "await p.setStringList('wishlist', wishlist.toList());\n    await p.setStringList('aiHistory', aiHistory);\n    await p.setString('reminders', jsonEncode(reminders));")
        # Ensure dart:convert is imported
        if "import 'dart:convert';" not in content:
            content = "import 'dart:convert';\n" + content

    # 5. MaterialApp route
    if "'/ai_trainer': (_) => const AITrainerScreen()" not in content:
        content = content.replace("'/cart': (_) => const CartScreen()", "'/cart': (_) => const CartScreen(),\n        '/ai_trainer': (_) => const AITrainerScreen()")

    # 6. HomeTab AI InfoBox & Reminder
    content = content.replace("infoBox(Icons.smart_toy,aiAdvice(g,f,l))", "InkWell(onTap: () => Navigator.pushNamed(context, '/ai_trainer'), child: infoBox(Icons.smart_toy, c.latestAIAdvice))")
    
    content = content.replace("Widget reminder(String t,String time,IconData icon)=>Card(child:ListTile(leading:CircleAvatar(backgroundColor:lightGreen,child:Icon(icon,color:green)),title:Text(t),subtitle:Text(time),trailing:Switch(value:true,onChanged:(_){ })));",
                              "Widget reminder(BuildContext context, String t,String time,IconData icon){ final c = Scope.of(context); return Card(child:ListTile(leading:CircleAvatar(backgroundColor:lightGreen,child:Icon(icon,color:green)),title:Text(t),subtitle:Text(time),trailing:Switch(value:c.reminders[t] ?? false,onChanged:(v)=>c.toggleReminder(t, time, v))));}")
    
    content = content.replace("reminder('Breakfast','7:30 AM',Icons.breakfast_dining),reminder('Lunch','1:00 PM',Icons.lunch_dining),reminder('Workout','6:00 PM',Icons.fitness_center)",
                              "reminder(context, 'Breakfast','7:30 AM',Icons.breakfast_dining),reminder(context, 'Lunch','1:00 PM',Icons.lunch_dining),reminder(context, 'Dinner','8:00 PM',Icons.dinner_dining),reminder(context, 'Workout','6:00 PM',Icons.fitness_center)")

    # 7. TrackersTab refactor
    trackers_code = """class TrackersTab extends StatefulWidget{ const TrackersTab({super.key}); @override State<TrackersTab> createState()=>_TrackersTabState(); }
class _TrackersTabState extends State<TrackersTab>{ 
  Timer? timer; int sec=0; 
  TimeOfDay? sleepTime; TimeOfDay? wakeTime;
  double? customMet;

  @override void dispose(){timer?.cancel();super.dispose();}

  String _getSleepAdvice(double hours) {
    if (hours >= 7 && hours <= 9) return 'Excellent! You are getting well-rested sleep. Keep it up.';
    if (hours >= 5 && hours < 7) return 'Warning: Try to get a bit more sleep. Aim for 7-9 hours for better recovery.';
    return 'Poor sleep! You need more rest. Tips: Sleep by 10-11 PM, avoid screens 1 hour before bed, keep room cool, avoid caffeine after 2 PM, meditate before sleeping.';
  }

  @override Widget build(BuildContext context){
    final c=Scope.of(context);
    final p=c.profile;
    
    final bool complete = p != null && p.age != null && p.height != null && p.weight != null && p.gender.isNotEmpty && p.goal.isNotEmpty;

    double bmi = 0; double bmr = 0; double tdee = 0; double tdeeAdj = 0;
    int protein = 0; int carbs = 0; int fats = 0; int fiber = 30; int waterReq = 3000;
    
    if (complete) {
      double w = p.weight!; double h = p.height!; int a = p.age!;
      bmi = w / ((h/100)*(h/100));
      bmr = p.gender == 'Male' ? (10*w + 6.25*h - 5*a + 5) : (10*w + 6.25*h - 5*a - 161);
      
      double met = customMet ?? 1.55;
      if (customMet == null) {
        if (p.location == 'Home Workout') met = 1.375;
        if (p.goal == 'Improve Stamina' || p.goal == 'Weight Loss') met = 1.55;
      }
      
      tdee = bmr * met;
      tdeeAdj = tdee;
      if (p.goal == 'Weight Loss') tdeeAdj -= 500;
      if (p.goal == 'Weight Gain') tdeeAdj += 500;
      
      protein = (w * 2.0).round();
      fats = ((tdeeAdj * 0.25) / 9).round();
      carbs = ((tdeeAdj - (protein * 4) - (fats * 9)) / 4).round();
      waterReq = (w * 35).round();
    }

    return ListView(padding:const EdgeInsets.all(20),children:[
      Text(c.t('trackers'),style:Theme.of(context).textTheme.headlineMedium),
      section(c.t('water')),
      track(Icons.water_drop,'${c.water} ml / ${complete ? waterReq : 3000} ml',Row(children:[Expanded(child:ElevatedButton(onPressed:()=>c.waterAdd(250),child:const Text('+250 ml'))),const SizedBox(width:10),Expanded(child:OutlinedButton(onPressed:()=>c.waterAdd(-c.water),child:const Text('Reset')))])),
      section(c.t('sleep')),
      track(Icons.bedtime,'${c.sleep.toStringAsFixed(1)} hours',Column(children:[
        Row(children:[
          Expanded(child:OutlinedButton.icon(icon:const Icon(Icons.nights_stay),label:Text(sleepTime?.format(context) ?? 'Sleep Time'),onPressed:()async{final t=await showTimePicker(context:context,initialTime:const TimeOfDay(hour:22,minute:0));if(t!=null)setState(()=>sleepTime=t);})),
          const SizedBox(width:10),
          Expanded(child:OutlinedButton.icon(icon:const Icon(Icons.wb_sunny),label:Text(wakeTime?.format(context) ?? 'Wake Time'),onPressed:()async{final t=await showTimePicker(context:context,initialTime:const TimeOfDay(hour:6,minute:0));if(t!=null)setState(()=>wakeTime=t);})),
        ]),
        const SizedBox(height:10),
        ElevatedButton(onPressed:(){
          if(sleepTime!=null && wakeTime!=null){
            double sH=sleepTime!.hour+sleepTime!.minute/60.0;
            double wH=wakeTime!.hour+wakeTime!.minute/60.0;
            double diff=wH-sH;
            if(diff<0)diff+=24;
            c.sleepSet(diff);
          }
        },child:const Text('Calculate Sleep')),
        if(c.sleep>0) ...[
          const SizedBox(height:14),
          Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:lightGreen,borderRadius:BorderRadius.circular(12)),child:Text(_getSleepAdvice(c.sleep),style:const TextStyle(color:textDark))),
        ]
      ])),
      section(c.t('steps')),
      track(Icons.directions_walk,'${c.steps} steps',Row(children:[Expanded(child:ElevatedButton(onPressed:()=>c.stepsAdd(500),child:const Text('+500'))),const SizedBox(width:10),Expanded(child:OutlinedButton(onPressed:()=>c.stepsAdd(-c.steps),child:const Text('Reset')))])),
      section(c.t('calorie')),
      if (!complete) ...[
        track(Icons.local_fire_department,'Complete Profile',Column(children:[
          const Text('Please complete your profile first to calculate your precise calories.'),
          const SizedBox(height:10),
          ElevatedButton(onPressed:()=>Navigator.pushNamed(context,'/goal'),child:const Text('Edit Profile Metrics'))
        ]))
      ] else ...[
        track(Icons.local_fire_department,'${tdeeAdj.round()} kcal / day',Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text('BMI: ${bmi.toStringAsFixed(1)}',style:const TextStyle(fontWeight:FontWeight.bold)),Text('BMR: ${bmr.round()} kcal',style:const TextStyle(fontWeight:FontWeight.bold))]),
          const SizedBox(height:10),
          Row(children:[
            Expanded(child:Container(padding:const EdgeInsets.all(10),color:Colors.blue.shade50,child:Column(children:[const Text('Protein'),Text('${protein}g',style:const TextStyle(fontWeight:FontWeight.bold))]))),
            Expanded(child:Container(padding:const EdgeInsets.all(10),color:Colors.green.shade50,child:Column(children:[const Text('Carbs'),Text('${carbs}g',style:const TextStyle(fontWeight:FontWeight.bold))]))),
            Expanded(child:Container(padding:const EdgeInsets.all(10),color:Colors.orange.shade50,child:Column(children:[const Text('Fats'),Text('${fats}g',style:const TextStyle(fontWeight:FontWeight.bold))]))),
          ]),
          const SizedBox(height:14),
          DropdownButtonFormField<double>(value:customMet ?? (p.location=='Home Workout'?1.375:1.55),decoration:const InputDecoration(labelText:'Activity Level (Optional)'),items:const [DropdownMenuItem(value:1.2,child:Text('Sedentary')),DropdownMenuItem(value:1.375,child:Text('Lightly Active')),DropdownMenuItem(value:1.55,child:Text('Moderately Active')),DropdownMenuItem(value:1.725,child:Text('Very Active'))],onChanged:(v)=>setState(()=>customMet=v)),
          const SizedBox(height:10),
          Align(alignment:Alignment.centerRight,child:TextButton.icon(icon:const Icon(Icons.edit),label:const Text('Edit Profile Metrics'),onPressed:()=>Navigator.pushNamed(context,'/goal')))
        ]))
      ],
      section('Workout Timer & Rest Timer'),
      track(Icons.timer,_fmt(sec),Row(children:[Expanded(child:ElevatedButton(onPressed:(){if(timer==null){timer=Timer.periodic(const Duration(seconds:1),(_)=>setState(()=>sec++));}else{timer?.cancel();timer=null;}setState((){});},child:Text(timer==null?'Start':'Pause'))),const SizedBox(width:10),Expanded(child:OutlinedButton(onPressed:()=>setState(()=>sec=0),child:const Text('Reset')))])),
      section(c.t('habits')),
      for(final h in habits) CheckboxListTile(value:c.habits[h]??false,onChanged:(_)=>c.toggleHabit(h),title:Text(h),activeColor:green,tileColor:Colors.white,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(18)))
    ]);}
  String _fmt(int s)=>'${(s~/60).toString().padLeft(2,'0')}:${(s%60).toString().padLeft(2,'0')}';
}"""

    start_idx = content.find('class TrackersTab extends StatefulWidget')
    end_idx = content.find('Widget track(', start_idx)
    
    if start_idx != -1 and end_idx != -1:
        content = content[:start_idx] + trackers_code + '\n' + content[end_idx:]

    # 8. Add AITrainerScreen
    ai_trainer_code = """
class AITrainerScreen extends StatelessWidget {
  const AITrainerScreen({super.key});
  @override Widget build(BuildContext context) {
    final c = Scope.of(context);
    final p = c.profile;
    return Scaffold(
      appBar: AppBar(title: const Text('AI Trainer'), backgroundColor: Colors.white, elevation: 0, foregroundColor: textDark),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: lightGreen, borderRadius: BorderRadius.circular(24)),
            child: Column(
              children: [
                const CircleAvatar(radius: 32, backgroundColor: Colors.white, child: Icon(Icons.smart_toy, color: green, size: 36)),
                const SizedBox(height: 16),
                Text(c.latestAIAdvice, style: const TextStyle(fontSize: 18, color: textDark, height: 1.5), textAlign: TextAlign.center),
              ],
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh Advice'),
            onPressed: () {
              if (p != null) {
                final g = p.goal.isNotEmpty ? p.goal : 'General Fitness';
                final f = p.food.isNotEmpty ? p.food : 'Eggetarian';
                final l = p.location.isNotEmpty ? p.location : 'Home Workout';
                c.addAIAdvice(aiAdvice(g, f, l));
              }
            },
          ),
          if (c.aiHistory.length > 1) ...[
            const SizedBox(height: 40),
            const Text('Past Advice', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 16),
            ...c.aiHistory.reversed.skip(1).take(5).map((h) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE7EEE9))),
              child: Row(children: [const Icon(Icons.history, color: Colors.grey), const SizedBox(width: 12), Expanded(child: Text(h, style: const TextStyle(color: Colors.black87)))]),
            )),
          ]
        ],
      ),
    );
  }
}
"""
    if 'class AITrainerScreen' not in content:
        content += ai_trainer_code

    with open(r'c:\project\NutriFit_Flutter_Supabase\lib\main.dart', 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    fix_main_dart()
    print('Done patching main.dart correctly')
