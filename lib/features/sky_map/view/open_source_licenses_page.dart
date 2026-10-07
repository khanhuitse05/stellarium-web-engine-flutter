import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mlastro_skymap/sky_map_assets.dart';
import 'package:url_launcher/url_launcher.dart';

const String _kFlutterPackageGitHubUrl =
    'https://github.com/khanhuitse05/stellarium-web-engine-flutter';
const String _kUpstreamGitHubUrl =
    'https://github.com/Stellarium/stellarium-web-engine';
const String _kGnuAgplUrl = 'https://www.gnu.org/licenses/agpl-3.0.html';
const String _kStellariumLabsUrl = 'https://stellarium-labs.com/';

Future<void> _launchUrlString(BuildContext context, String urlString) async {
  final uri = Uri.tryParse(urlString);
  if (uri == null) return;
  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open $urlString')));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to open link: $e')));
    }
  }
}

/// Open source licenses and third-party software acknowledgements.
class OpenSourceLicensesPage extends StatelessWidget {
  const OpenSourceLicensesPage({super.key, this.applicationName = 'MLAstro'});

  final String? applicationName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Licenses & Attributions')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // 1. Hero Card: Stellarium Web Engine & primary actions
          const _HeroCard(),
          const SizedBox(height: 16),

          // 3. Bundled NOTICE file & AGPL note
          const _ClickableNoticeSection(),
          const SizedBox(height: 16),

          // 4. Flutter & other third-party dependencies licenses
          _AllLicensesCard(applicationName: applicationName),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Hero card for Stellarium Web Engine with badges and primary action buttons.
class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stellarium Web Engine',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Offline Sky Map & Planetarium Engine',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Badges
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _Badge(
                  icon: Icons.gavel_rounded,
                  label: 'GNU AGPL-3.0',
                  color: theme.colorScheme.primary,
                ),
                _Badge(
                  icon: Icons.copyright_rounded,
                  label: '© Stellarium Labs SRL',
                  color: theme.colorScheme.secondary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Powers MLAstro\'s offline interactive sky chart, celestial coordinates, constellation lines, and telescope pointing visualization.',
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.45,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 14),
            // Action buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const _AgplLicensePage(),
                    ),
                  ),
                  icon: const Icon(Icons.description_outlined, size: 16),
                  label: const Text('AGPL v3 text'),
                ),
                FilledButton.icon(
                  onPressed: () =>
                      _launchUrlString(context, _kFlutterPackageGitHubUrl),
                  icon: const Icon(Icons.code_rounded, size: 16),
                  label: const Text('Source Code'),
                ),
                OutlinedButton.icon(
                  onPressed: () =>
                      _launchUrlString(context, _kUpstreamGitHubUrl),
                  icon: const Icon(Icons.open_in_new_rounded, size: 14),
                  label: const Text('Upstream Engine'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _launchUrlString(context, _kGnuAgplUrl),
                  icon: const Icon(Icons.open_in_new_rounded, size: 14),
                  label: const Text('GNU.org'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Small informational tag / badge
class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Notice section displaying the bundled NOTICE file with clickable URLs and copy action.
class _ClickableNoticeSection extends StatelessWidget {
  const _ClickableNoticeSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<String>(
      future: rootBundle.loadString(SkyMapAssets.notice),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snap.hasError) {
          return Text('Could not load notice: ${snap.error}');
        }
        final noticeText = snap.data ?? '';
        return Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.article_outlined,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Third-Party Notice',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      tooltip: 'Copy notice',
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: noticeText),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Notice copied to clipboard'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
                const Divider(height: 12),
                const SizedBox(height: 4),
                _ClickableUrlText(
                  text: noticeText,
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _launchUrlString(context, _kStellariumLabsUrl),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Commercial licensing via Stellarium Labs ',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Icon(
                            Icons.open_in_new_rounded,
                            size: 13,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Renders text with automatic regex detection for clickable URLs.
class _ClickableUrlText extends StatefulWidget {
  const _ClickableUrlText({required this.text, this.style});

  final String text;
  final TextStyle? style;

  @override
  State<_ClickableUrlText> createState() => _ClickableUrlTextState();
}

class _ClickableUrlTextState extends State<_ClickableUrlText> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();

    final theme = Theme.of(context);
    final linkColor = theme.colorScheme.primary;
    final defaultStyle = widget.style ?? theme.textTheme.bodySmall;
    final linkStyle = (defaultStyle ?? const TextStyle()).copyWith(
      color: linkColor,
      decoration: TextDecoration.underline,
      decorationColor: linkColor.withValues(alpha: 0.6),
      fontWeight: FontWeight.w500,
    );

    final urlRegex = RegExp(r'https?://[^\s)\]]+');
    final spans = <InlineSpan>[];
    int start = 0;

    for (final match in urlRegex.allMatches(widget.text)) {
      if (match.start > start) {
        spans.add(
          TextSpan(
            text: widget.text.substring(start, match.start),
            style: defaultStyle,
          ),
        );
      }
      final url = match.group(0)!;
      final recognizer = TapGestureRecognizer()
        ..onTap = () => _launchUrlString(context, url);
      _recognizers.add(recognizer);

      spans.add(TextSpan(text: url, style: linkStyle, recognizer: recognizer));
      start = match.end;
    }

    if (start < widget.text.length) {
      spans.add(
        TextSpan(text: widget.text.substring(start), style: defaultStyle),
      );
    }

    return SelectableText.rich(TextSpan(children: spans));
  }
}

/// Card providing access to Flutter and other bundled third-party package licenses.
class _AllLicensesCard extends StatelessWidget {
  const _AllLicensesCard({this.applicationName});

  final String? applicationName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.library_books_outlined,
            color: theme.colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          'All Open Source Licenses',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'View licenses for Flutter and other bundled packages',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => showLicensePage(
          context: context,
          applicationName: applicationName,
        ),
      ),
    );
  }
}

/// Dedicated page rendering the full GNU AGPL v3 license with monospace formatting,
/// quick action links (GitHub, GNU.org), and copy-to-clipboard functionality.
class _AgplLicensePage extends StatelessWidget {
  const _AgplLicensePage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('GNU AGPL v3'),
        actions: [
          IconButton(
            tooltip: 'Open on GNU.org',
            icon: const Icon(Icons.open_in_new_rounded),
            onPressed: () => _launchUrlString(context, _kGnuAgplUrl),
          ),
        ],
      ),
      body: FutureBuilder<String>(
        future: rootBundle.loadString(SkyMapAssets.agplLicense),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Could not load license: ${snap.error}'));
          }
          final text = snap.data ?? '';
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                height: 1.45,
              ),
            ),
          );
        },
      ),
    );
  }
}
