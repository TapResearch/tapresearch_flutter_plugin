import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:tapresearch_flutter_plugin/tapresearch_flutter_plugin.dart';

final _placementTagController = TextEditingController(text: 'earn-center');

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: HomeScreen());
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    implements TRSdkReadyCallback, TRErrorCallback, TRRewardCallback {
  final _plugin = TapresearchFlutterPlugin();
  bool _initializing = true;
  TRPlacementDetails? _placementDetails;
  bool? _isProfilerPlacement;

  @override
  void initState() {
    super.initState();
    _initializeSdk();
  }

  Future<void> _initializeSdk() async {
    await _plugin.initialize(
      apiToken: Platform.isAndroid ? 'fb28e5e0572876db0790ecaf6c588598' : '100e9133abc21471c8cd373587e07515',
      userIdentifier: Platform.isAndroid ? 'tr-sdk-test-user-46183135' : 'tr-sdk-test-ios-flutter-user',
      sdkReadyCallback: this,
      errorCallback: this,
      rewardCallback: this,
    );
  }

  // TRSdkReadyCallback
  @override
  void onTapResearchSdkReady() {
    debugPrint('TapResearch SDK is ready');
    if (mounted) {
      setState(() => _initializing = false);
    }
    _getPlacementDetails(showFeedback: false);
  }

  // TRErrorCallback
  @override
  void onTapResearchDidError(TRError trError) {
    debugPrint('TapResearch error ${trError.code}: ${trError.description}');
  }

  // TRRewardCallback
  @override
  void onTapResearchDidReceiveRewards(List<TRReward> rewards) {
    for (final reward in rewards) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'TapResearch reward: ${reward.rewardAmount} ${reward.currencyName}'),
        ),
      );
    }
  }

  Future<void> _showStandardWall() async {
    await _plugin.showContentForPlacement(
      tag: _placementTagController.text,
      errorCallback: this,
    );
  }

  Future<void> _getSurveys() async {
    final messenger = ScaffoldMessenger.of(context);
    final tag = _placementTagController.text;
    final surveys = await _plugin.getSurveysForPlacement(tag, this);
    if (surveys == null || surveys.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text('No surveys available for $tag')),
      );
      return;
    }
    final message = surveys
        .map((s) =>
            'Survey ${s.surveyId}: ${s.rewardAmount} ${s.currencyName}, ${s.lengthInMinutes} min')
        .join('\n');
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _getPlacementDetails({bool showFeedback = true}) async {
    final messenger = ScaffoldMessenger.of(context);
    final tag = _placementTagController.text;
    final details = await _plugin.getPlacementDetails(
      tag,
      errorListener: this,
    );
    final isProfilerPlacement = details?.contentType == 'profiler';

    if (!mounted) {
      return;
    }

    setState(() {
      _placementDetails = details;
      _isProfilerPlacement = details == null ? null : isProfilerPlacement;
    });

    if (details == null) {
      if (showFeedback) {
        messenger.showSnackBar(
          SnackBar(content: Text('No placement details returned for $tag')),
        );
      }
      return;
    }

    if (showFeedback) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'content_type: ${details.contentType ?? 'unknown'}'
            '${isProfilerPlacement ? ' (profiler)' : ' (not profiler)'}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TapResearch Example')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: _initializing
              ? const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Please wait while initializing...'),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: TextField(
                        controller: _placementTagController,
                        decoration: const InputDecoration(
                          labelText: 'Placement Tag',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _showStandardWall,
                      child: Text(
                        _isProfilerPlacement == true
                            ? 'Show Profiler'
                            : 'Show Survey Wall',
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _getSurveys,
                      child: const Text('Get Surveys'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _getPlacementDetails,
                      child: const Text('Get Placement Details'),
                    ),
                    const SizedBox(height: 16),
                    if (_placementDetails != null) ...[
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 340),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Placement Details',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text('Name: ${_placementDetails!.name ?? 'n/a'}'),
                                Text(
                                  'content_type: ${_placementDetails!.contentType ?? 'n/a'}',
                                ),
                                Text(
                                  'Is profiler: ${_isProfilerPlacement == true ? 'Yes' : 'No'}',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SurveyWallPreviewScreen()),
                      ),
                      child: const Text('Survey Wall Preview'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class SurveyWallPreviewScreen extends StatefulWidget {
  const SurveyWallPreviewScreen({super.key});

  @override
  State<SurveyWallPreviewScreen> createState() =>
      _SurveyWallPreviewScreenState();
}

class _SurveyWallPreviewScreenState extends State<SurveyWallPreviewScreen>
    implements TRErrorCallback, TRSurveysRefreshedListener {
  final _plugin = TapresearchFlutterPlugin();
  List<TRSurvey>? _surveys;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _plugin.setSurveysRefreshedListener(this);
    _loadSurveys();
  }

  @override
  void dispose() {
    _plugin.setSurveysRefreshedListener(null);
    super.dispose();
  }

  Future<void> _loadSurveys({String? placementTag}) async {
    final tag = placementTag ?? _placementTagController.text;
    final surveys = await _plugin.getSurveysForPlacement(tag, this);
    if (mounted) {
      setState(() {
        _surveys = surveys;
        _loading = false;
      });
    }
  }

  @override
  void onSurveysRefreshedForPlacement(String placementTag) {
    _loadSurveys(placementTag: placementTag);
  }

  @override
  void onTapResearchDidError(TRError trError) {
    if (mounted) {
      setState(() {
        _errorMessage = trError.description;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Survey Wall Preview'),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text('Error: $_errorMessage'));
    }
    final surveys = _surveys;
    if (surveys == null || surveys.isEmpty) {
      return const Center(child: Text('No surveys available.'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: surveys.length,
      itemBuilder: (context, index) => _SurveyTile(
            survey: surveys[index],
            onTap: () => _plugin.showSurveyForPlacement(
              placementTag: _placementTagController.text,
              surveyId: surveys[index].surveyId ?? '',
              errorCallback: this,
            ),
          ),
    );
  }
}

class _SurveyTile extends StatelessWidget {
  const _SurveyTile({required this.survey, required this.onTap});

  final TRSurvey survey;
  final VoidCallback onTap;

  static const _cardBg = Color(0xFFF3EEFF);
  static const _purple = Color(0xFF9747FF);
  static const _decoColor = Color(0xFFCBA8FF);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      color: _cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 13,
                          color: Colors.black87),
                      const SizedBox(width: 3),
                      Text(
                        survey.lengthInMinutes != null
                            ? '${survey.lengthInMinutes} min'
                            : '--',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black87),
                      ),
                    ],
                  ),
                  if (survey.isHotTile == true)
                    const Row(
                      children: [
                        Text('HOT!',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87)),
                        SizedBox(width: 3),
                        Icon(Icons.whatshot, size: 13, color: Colors.black87),
                      ],
                    ),
                ],
              ),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Positioned(
                        top: 2,
                        left: 2,
                        child: Icon(Icons.bolt, color: _decoColor, size: 20)),
                    const Positioned(
                        top: 2,
                        right: 2,
                        child: Icon(Icons.bolt, color: _decoColor, size: 14)),
                    const Positioned(
                        bottom: 2,
                        left: 2,
                        child: Icon(Icons.diamond_outlined,
                            color: _decoColor, size: 16)),
                    const Positioned(
                        bottom: 2,
                        right: 4,
                        child: Icon(Icons.star_outline,
                            color: _decoColor, size: 16)),
                    FractionallySizedBox(
                      widthFactor: 0.78,
                      heightFactor: 0.78,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: _purple,
                          shape: BoxShape.circle,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              survey.rewardAmount != null
                                  ? survey.rewardAmount!.toStringAsFixed(0)
                                  : '--',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              survey.currencyName ?? '',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
