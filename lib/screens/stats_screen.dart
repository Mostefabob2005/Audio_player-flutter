class StatsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.firebaseUser;
    return FutureBuilder<DocumentSnapshot>(
      future: FirestoreService().getUserProfile(user!.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();
        final data = snapshot.data!.data() as Map<String, dynamic>;
        final fullName = '${data['firstName']} ${data['lastName']}';
        return Scaffold(
          appBar: AppBar(title: Text('Statistics')),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome, ', style: TextStyle(fontSize: 20)),
                Text(fullName,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 20),
                Consumer<StatsProvider>(
                  builder: (context, stats, child) {
                    final hours = stats.totalMinutesThisMonth ~/ 60;
                    final minutes = stats.totalMinutesThisMonth % 60;
                    return Column(
                      children: [
                        Text('Total listening this month: $hours h $minutes min'),
                        SizedBox(height: 10),
                        // Histogram (fl_chart)
                        SizedBox(
                          height: 200,
                          child: BarChartWidget(dailyMinutes: stats._dailyMinutes),
                        ),
                        SizedBox(height: 20),
                        // Progress bar and goal dropdown
                        Row(
                          children: [
                            Expanded(
                              child: LinearProgressIndicator(
                                value: stats.progressValue,
                                minHeight: 10,
                              ),
                            ),
                            SizedBox(width: 10),
                            DropdownButton<double>(
                              value: stats.monthlyGoalHours,
                              items: [10, 20, 30, 40, 50].map((h) {
                                return DropdownMenuItem(
                                  value: h.toDouble(),
                                  child: Text('${h}h'),
                                );
                              }).toList(),
                              onChanged: (val) => stats.setMonthlyGoal(val!),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Text('Top Tracks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ...stats.topTracks.map((e) => ListTile(
                              title: Text(e.key),
                              trailing: Text('${e.value} plays'),
                            )),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}