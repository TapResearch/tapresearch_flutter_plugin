import 'package:flutter/material.dart';
import 'package:tapresearch_flutter_plugin/tapresearch_flutter_plugin.dart';

class PagedProfilerScreen extends StatefulWidget {
  const PagedProfilerScreen({
    super.key,
    required this.apiToken,
    required this.userIdentifier,
  });

  final String apiToken;
  final String userIdentifier;

  @override
  State<PagedProfilerScreen> createState() => _PagedProfilerScreenState();
}

class _PagedProfilerScreenState extends State<PagedProfilerScreen>
    implements TRQualificationsResponseListener {
  final _plugin = TapresearchFlutterPlugin();
  TRQualificationsResponse? _response;
  bool _loading = true;
  bool _isSubmitting = false;
  String _submitButtonLabel = 'Submit Answer';
  final Map<int, List<String>> _answers = {};
  final Map<int, TextEditingController> _textControllers = {};

  @override
  void initState() {
    super.initState();
    _fetchQualifications();
  }

  @override
  void dispose() {
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _fetchQualifications() {
    setState(() {
      _loading = true;
    });
    _plugin.getProfilingQualifications(
      apiToken: widget.apiToken,
      userIdentifier: widget.userIdentifier,
      countryCode: 'US',
      listener: this,
    );
  }

  void _submitSingleAnswer(TRQualification currentQualification) {
    final qId = currentQualification.questionId;
    if (qId == null) return;

    if (['date', 'zip_code', 'text', 'integer']
        .contains(currentQualification.answerType)) {
      final controller = _textControllers[qId];
      if (controller != null) {
        final val = controller.text.trim();
        if (val.isNotEmpty) {
          _answers[qId] = [val];
        } else {
          _answers.remove(qId);
        }
      }
    }

    final stateValues = _answers[qId] ?? [];
    if (stateValues.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    final submissions = [
      {
        'question_id': qId,
        'actual_user_answer': stateValues,
      }
    ];

    _plugin.sendProfilingQualifications(
      apiToken: widget.apiToken,
      userIdentifier: widget.userIdentifier,
      countryCode: 'US',
      answers: submissions,
      listener: this,
    );
  }

  @override
  void onReceivedQualificationsResponse(TRQualificationsResponse response) {
    if (mounted) {
      setState(() {
        _response = response;
        _loading = false;
        _isSubmitting = false;
        final remainingCount = response.qualifications?.length ?? 0;
        _submitButtonLabel = 'Submit Answer ($remainingCount remaining)';

        if (response.qualifications != null) {
          for (final qual in response.qualifications!) {
            if (qual.questionId != null &&
                ['date', 'zip_code', 'text', 'integer']
                    .contains(qual.answerType)) {
              _textControllers.putIfAbsent(
                qual.questionId!,
                () => TextEditingController(
                  text: _answers[qual.questionId!]?.firstOrNull ?? '',
                ),
              );
            }
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentQualification = _response?.qualifications?.firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paged Native Profiler'),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: _buildBody(),
      bottomNavigationBar: (currentQualification != null &&
              !_loading &&
              !_isSubmitting)
          ? Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: ElevatedButton(
                onPressed: () => _submitSingleAnswer(currentQualification),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: Text(_submitButtonLabel),
              ),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_loading || _isSubmitting) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(_isSubmitting ? 'Submitting Answer...' : 'Loading Profiler...'),
          ],
        ),
      );
    }

    final response = _response;
    if (response == null) {
      return const Center(child: Text('No response received.'));
    }

    final currentQualification = response.qualifications?.firstOrNull;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Paged Native Profiler',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'API Token: ${widget.apiToken}',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
        ),
        Text(
          'User ID: ${widget.userIdentifier}',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
        ),
        const SizedBox(height: 12),
        if (response.error != null)
          Text(
            response.error?.description ?? 'Unknown error',
            style: const TextStyle(color: Colors.red, fontSize: 16),
          )
        else ...[
          Text('Country: ${response.countryCode}, Locale: ${response.locale}'),
          Text('Is Profiled: ${response.isProfiled}'),
          const Divider(height: 24),
          if (response.qualificationsResult != null) ...[
            const Text(
              'Qualifications Submission Summary:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (response.qualificationsResult?.acceptedCount != null)
              Text(
                  'Accepted Count: ${response.qualificationsResult?.acceptedCount}'),
            if (response.qualificationsResult?.invalidCount != null)
              Text(
                  'Invalid Count: ${response.qualificationsResult?.invalidCount}'),
            const Divider(height: 24),
          ],
          if (response.isProfiled == true)
            const Text(
              'No further qualification questions required. Go back and change the user identifier.',
              style: TextStyle(fontWeight: FontWeight.w500),
            )
          else if (currentQualification != null) ...[
            const Text(
              'Answer the following question:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            _buildQualificationItem(currentQualification),
          ] else
            const Text(
              'No more questions for now.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
        ],
      ],
    );
  }

  Widget _buildQualificationItem(TRQualification qual) {
    final qId = qual.questionId;
    if (qId == null) return const SizedBox.shrink();

    final selectedValues = _answers[qId] ?? [];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              qual.questionText ?? '',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (qual.previousError != null) ...[
              const SizedBox(height: 4),
              Text(
                qual.previousError!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              'Type: ${qual.answerType}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 8),
            _buildAnswerWidget(qual, qId, selectedValues),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerWidget(
      TRQualification qual, int qId, List<String> selectedValues) {
    switch (qual.answerType) {
      case 'single_select':
        return Column(
          children: (qual.qualificationAnswers ?? []).map((ans) {
            final code = ans.preCode ?? '';
            return RadioListTile<String>(
              title: Text(ans.optionText ?? ''),
              value: code,
              groupValue: selectedValues.firstOrNull,
              onChanged: (val) {
                setState(() {
                  if (val != null) {
                    _answers[qId] = [val];
                  }
                });
              },
            );
          }).toList(),
        );

      case 'multi_select':
        return Column(
          children: (qual.qualificationAnswers ?? []).map((ans) {
            final code = ans.preCode ?? '';
            final isChecked = selectedValues.contains(code);
            return CheckboxListTile(
              title: Text(ans.optionText ?? ''),
              value: isChecked,
              onChanged: (bool? checked) {
                setState(() {
                  final list = _answers[qId] ?? [];
                  if (checked == true) {
                    if (!list.contains(code)) list.add(code);
                  } else {
                    list.remove(code);
                  }
                  if (list.isEmpty) {
                    _answers.remove(qId);
                  } else {
                    _answers[qId] = list;
                  }
                });
              },
            );
          }).toList(),
        );

      case 'date':
      case 'zip_code':
      case 'text':
      case 'integer':
        final controller = _textControllers.putIfAbsent(
          qId,
          () => TextEditingController(text: selectedValues.firstOrNull ?? ''),
        );
        final keyboardType =
            (qual.answerType == 'date' || qual.answerType == 'integer')
                ? TextInputType.number
                : TextInputType.text;

        return TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            labelText: 'Enter ${qual.answerType}',
            border: const OutlineInputBorder(),
          ),
          onChanged: (val) {
            setState(() {
              if (val.trim().isEmpty) {
                _answers.remove(qId);
              } else {
                _answers[qId] = [val.trim()];
              }
            });
          },
        );

      default:
        return const Text(
          'Unsupported answer type',
          style: TextStyle(color: Colors.red),
        );
    }
  }
}
