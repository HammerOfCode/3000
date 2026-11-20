import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'repdb_assets.dart';

final _repDbManifests = Expando<Future<AssetManifest>>();

/// The public checkout can be built before the optional licensed art is fetched.
class RepDbImageChoice extends StatelessWidget {
  const RepDbImageChoice({
    super.key,
    required this.asset,
    required this.builder,
  });

  final String? asset;
  final Widget Function(BuildContext context, String? bundledAsset) builder;

  @override
  Widget build(BuildContext context) {
    final image = asset;
    if (image == null) return builder(context, null);
    final bundle = DefaultAssetBundle.of(context);
    return FutureBuilder<AssetManifest>(
      future: _repDbManifests[bundle] ??= AssetManifest.loadFromAssetBundle(
        bundle,
      ),
      builder: (context, snapshot) {
        final bundled = snapshot.data?.getAssetVariants(image) != null;
        return builder(context, bundled ? image : null);
      },
    );
  }
}

class RepDbCredit extends StatelessWidget {
  const RepDbCredit({super.key});

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () async {
      final opened = await launchUrl(
        Uri.https('repdb.co'),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Visit repdb.co')));
      }
    },
    child: const Text(repDbCredit),
  );
}
