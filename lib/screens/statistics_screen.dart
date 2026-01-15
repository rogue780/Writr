import 'package:flutter/material.dart';
import '../models/scrivener_project.dart';
import '../services/statistics_service.dart';

/// Screen displaying writing statistics for the project
class StatisticsScreen extends StatefulWidget {
  final ScrivenerProject project;
  final StatisticsService statisticsService;

  const StatisticsScreen({
    super.key,
    required this.project,
    required this.statisticsService,
  });

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Writing Statistics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Project', icon: Icon(Icons.folder)),
            Tab(text: 'History', icon: Icon(Icons.history)),
            Tab(text: 'Goals', icon: Icon(Icons.flag)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProjectTab(),
          _buildHistoryTab(),
          _buildGoalsTab(),
        ],
      ),
    );
  }

  Widget _buildProjectTab() {
    final stats = widget.statisticsService.calculateProjectStatistics(widget.project);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Words',
                  _formatNumber(stats.totalWords),
                  Icons.text_fields,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Documents',
                  stats.documentCount.toString(),
                  Icons.description,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Characters',
                  _formatNumber(stats.totalCharacters),
                  Icons.abc,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Avg Words/Doc',
                  stats.averageWordsPerDocument.toString(),
                  Icons.analytics,
                  Colors.purple,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Writing streak
          _buildStreakCard(),

          const SizedBox(height: 24),

          // Words by document
          const Text(
            'Words by Document',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildDocumentWordsList(stats),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    final wordsPerDay = widget.statisticsService.getWordsPerDay(30);
    final sessions = widget.statisticsService.allSessions;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart header
          const Text(
            'Words Written (Last 30 Days)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Simple bar chart
          _buildWordChart(wordsPerDay),

          const SizedBox(height: 24),

          // Summary stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Last 7 Days',
                  _formatNumber(widget.statisticsService.getTotalWordsInRange(
                    DateTime.now().subtract(const Duration(days: 7)),
                    DateTime.now(),
                  )),
                  Icons.calendar_today,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Last 30 Days',
                  _formatNumber(widget.statisticsService.getTotalWordsInRange(
                    DateTime.now().subtract(const Duration(days: 30)),
                    DateTime.now(),
                  )),
                  Icons.date_range,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Daily Average',
                  widget.statisticsService.getAverageWordsPerDay(30).toStringAsFixed(0),
                  Icons.trending_up,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Writing Streak',
                  '${widget.statisticsService.getWritingStreak()} days',
                  Icons.local_fire_department,
                  Colors.red,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Recent sessions
          const Text(
            'Recent Sessions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          if (sessions.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No writing sessions recorded yet.\nStart writing to track your progress!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...sessions.take(10).map((session) => _buildSessionTile(session)),
        ],
      ),
    );
  }

  Widget _buildGoalsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Daily goal
          _buildGoalCard(
            title: 'Daily Goal',
            current: widget.statisticsService.getWordsPerDay(1).values.firstOrNull ?? 0,
            target: 1000,
            icon: Icons.today,
            color: Colors.blue,
          ),

          const SizedBox(height: 16),

          // Weekly goal
          _buildGoalCard(
            title: 'Weekly Goal',
            current: widget.statisticsService.getTotalWordsInRange(
              DateTime.now().subtract(const Duration(days: 7)),
              DateTime.now(),
            ),
            target: 5000,
            icon: Icons.view_week,
            color: Colors.green,
          ),

          const SizedBox(height: 16),

          // Monthly goal
          _buildGoalCard(
            title: 'Monthly Goal',
            current: widget.statisticsService.getTotalWordsInRange(
              DateTime.now().subtract(const Duration(days: 30)),
              DateTime.now(),
            ),
            target: 20000,
            icon: Icons.calendar_month,
            color: Colors.purple,
          ),

          const SizedBox(height: 24),

          // Project goals
          const Text(
            'Project Goals',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          _buildGoalCard(
            title: 'Project Word Count',
            current: widget.statisticsService
                .calculateProjectStatistics(widget.project)
                .totalWords,
            target: 50000,
            icon: Icons.book,
            color: Colors.orange,
            subtitle: 'Target: Novel (~50,000 words)',
          ),

          const SizedBox(height: 24),

          // Motivational tips
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.amber[700]),
                      const SizedBox(width: 8),
                      const Text(
                        'Writing Tips',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getMotivationalTip(),
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard() {
    final streak = widget.statisticsService.getWritingStreak();

    return Card(
      color: streak > 0 ? Colors.orange[50] : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: streak > 0 ? Colors.orange : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_fire_department,
                color: streak > 0 ? Colors.white : Colors.grey[600],
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streak Day${streak != 1 ? 's' : ''} Streak',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  streak > 0
                      ? 'Keep it up! Write today to continue your streak.'
                      : 'Start writing today to begin your streak!',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentWordsList(ProjectStatistics stats) {
    // Get document titles and sort by word count
    final sortedDocs = <MapEntry<BinderItem, int>>[];

    void collectDocs(List<BinderItem> items) {
      for (final item in items) {
        if (!item.isFolder && stats.wordsByDocument.containsKey(item.id)) {
          sortedDocs.add(MapEntry(item, stats.wordsByDocument[item.id]!));
        }
        if (item.children.isNotEmpty) {
          collectDocs(item.children);
        }
      }
    }

    collectDocs(widget.project.binderItems);
    sortedDocs.sort((a, b) => b.value.compareTo(a.value));

    if (sortedDocs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No documents with content yet.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children: sortedDocs.take(10).map((entry) {
        final percentage = stats.totalWords > 0
            ? (entry.value / stats.totalWords * 100)
            : 0.0;

        return ListTile(
          leading: const Icon(Icons.description),
          title: Text(entry.key.title),
          subtitle: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[200],
          ),
          trailing: Text(
            '${_formatNumber(entry.value)} (${percentage.toStringAsFixed(1)}%)',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWordChart(Map<String, int> wordsPerDay) {
    // Reverse to show oldest first
    final entries = wordsPerDay.entries.toList().reversed.toList();
    final maxWords = entries.map((e) => e.value).fold(0, (a, b) => a > b ? a : b);

    return SizedBox(
      height: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: entries.map((entry) {
          final height = maxWords > 0 ? (entry.value / maxWords * 120) : 0.0;
          final isToday = entry.key == _getDateKey(DateTime.now());

          return Expanded(
            child: Tooltip(
              message: '${entry.key}: ${entry.value} words',
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                height: height.toDouble(),
                decoration: BoxDecoration(
                  color: isToday ? Colors.blue : Colors.blue[200],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSessionTile(WritingSession session) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: session.wordsWritten > 0 ? Colors.green[100] : Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: Icon(
          session.wordsWritten > 0 ? Icons.check : Icons.remove,
          color: session.wordsWritten > 0 ? Colors.green : Colors.grey,
          size: 20,
        ),
      ),
      title: Text(_formatDate(session.date)),
      subtitle: Text(
        session.duration.inMinutes > 0
            ? '${session.duration.inMinutes} minutes'
            : 'No duration recorded',
      ),
      trailing: Text(
        '${session.wordsWritten >= 0 ? '+' : ''}${session.wordsWritten} words',
        style: TextStyle(
          color: session.wordsWritten >= 0 ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildGoalCard({
    required String title,
    required int current,
    required int target,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    final progress = (current / target).clamp(0.0, 1.0);
    final isComplete = progress >= 1.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (isComplete)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Complete!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatNumber(current),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '/ ${_formatNumber(target)}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation(
                  isComplete ? Colors.green : color,
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(progress * 100).toInt()}% complete',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';

    return '${date.month}/${date.day}/${date.year}';
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _getMotivationalTip() {
    final tips = [
      'Write every day, even if it\'s just a few sentences. Consistency builds habits.',
      'Don\'t edit while you write. Let the words flow first, then refine later.',
      'Set a specific writing time each day. Your brain will learn to be creative on schedule.',
      'Read widely in your genre. Great writers are always great readers.',
      'Take breaks! A walk can do wonders for writer\'s block.',
      'Keep a notebook handy. Ideas come at unexpected times.',
      'Your first draft doesn\'t have to be perfect. It just has to exist.',
      'Write the scenes you\'re excited about first. Momentum matters.',
      'Track your progress. Seeing growth motivates continued effort.',
      'Join a writing community. Feedback and support help you improve.',
    ];

    return tips[DateTime.now().day % tips.length];
  }
}
