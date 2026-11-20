import 'package:flutter/material.dart';

import 'repdb_image.dart';

enum CommonsLicense {
  shareAlike40(
    'CC BY-SA 4.0',
    'https://creativecommons.org/licenses/by-sa/4.0/',
  ),
  shareAlike30(
    'CC BY-SA 3.0',
    'https://creativecommons.org/licenses/by-sa/3.0/',
  ),
  attribution20('CC BY 2.0', 'https://creativecommons.org/licenses/by/2.0/'),
  cc0('CC0 1.0', 'https://creativecommons.org/publicdomain/zero/1.0/'),
  publicDomain('Public domain (U.S. government)');

  const CommonsLicense(this.label, [this.url]);
  final String label;
  final String? url;
}

enum CommonsPhoto {
  dumbbells(
    'Colorful dumbbells of various sizes.jpg',
    'Ser Amantio di Nicolao',
    CommonsLicense.shareAlike40,
  ),
  bench(
    'Two weight training benches.jpg',
    'Wolfgang1018',
    CommonsLicense.shareAlike30,
  ),
  band(
    'Trenirovachni lastici set.JPG',
    'Velislav Panchev',
    CommonsLicense.shareAlike40,
  ),
  cableStation(
    'Functional Trainer Exercise Machine at Gym.jpg',
    'KeepActive Australia',
    CommonsLicense.shareAlike40,
    authorUrl: 'https://keepactive.com.au/',
  ),
  latPulldown(
    'Lat Pull down Machine.jpg',
    'SAgbley',
    CommonsLicense.shareAlike40,
  ),
  chestPress(
    'Muscle Strengthening at the Gym - Chest Press.webm',
    'Centers for Disease Control and Prevention',
    CommonsLicense.publicDomain,
    stillFrame: true,
  ),
  cableRow(
    'Woman using a seated cable row machine at the gym.jpg',
    'Miguel Angel Omaña Rojas',
    CommonsLicense.cc0,
  ),
  legPressMachine(
    'Leg press machine.jpg',
    'Teemeah',
    CommonsLicense.shareAlike40,
  ),
  legPress(
    'Young man using a leg press machine at the gym.jpg',
    'Nenad Stojkovic',
    CommonsLicense.attribution20,
  ),
  hackSquat(
    'David Jobson & Ziggy Chima; machine hack squat.jpg',
    'brett jordan',
    CommonsLicense.attribution20,
  ),
  legExtension(
    'LegExtensionMachineExercise.JPG',
    'GeorgeStepanek',
    CommonsLicense.shareAlike30,
  ),
  lyingLegCurl(
    'LyingLegCurlMachineExercise.JPG',
    'GeorgeStepanek',
    CommonsLicense.shareAlike30,
  ),
  shoulderPress(
    'ShoulderPressMachineExercise.JPG',
    'GeorgeStepanek',
    CommonsLicense.shareAlike30,
  ),
  pecDeck('Chest Fly Machine.jpg', 'SAgbley', CommonsLicense.shareAlike40),
  pullUpBar('Pull up bar stand.jpg', 'SAgbley', CommonsLicense.shareAlike40),
  bodyweightSquat(
    'Bodyweight Squats.gif',
    'Danielflefil',
    CommonsLicense.shareAlike40,
    stillFrame: true,
  );

  const CommonsPhoto(
    this.file,
    this.author,
    this.license, {
    this.authorUrl,
    this.stillFrame = false,
  });

  final String file;
  final String author;
  final CommonsLicense license;
  final String? authorUrl;
  final bool stillFrame;

  String get assetPath => 'assets/commons/$name.jpg';

  Uri get source => Uri.https(
    'commons.wikimedia.org',
    '/wiki/File:${file.replaceAll(' ', '_')}',
  );

  String get credit => [
    '$author · Wikimedia Commons · ${license.label}',
    if (stillFrame) 'Still frame',
    source.toString(),
    ?license.url,
    ?authorUrl,
  ].join('\n');
}

class CommonsThumbnail extends StatelessWidget {
  const CommonsThumbnail(this.photo, {super.key, required this.size});

  final CommonsPhoto photo;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        photo.assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).ceil(),
        excludeFromSemantics: true,
      ),
    );
  }
}

class PhotoCreditsPage extends StatelessWidget {
  const PhotoCreditsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Photo credits')),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: CommonsPhoto.values.length + 1,
        separatorBuilder: (context, index) => const Divider(height: 24),
        itemBuilder: (context, index) {
          if (index == 0) {
            return const Align(
              alignment: Alignment.centerLeft,
              child: RepDbCredit(),
            );
          }
          final photo = CommonsPhoto.values[index - 1];
          return SelectableText('${photo.file}\n${photo.credit}');
        },
      ),
    );
  }
}
