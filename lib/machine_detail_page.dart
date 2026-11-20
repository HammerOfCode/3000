import 'package:flutter/material.dart';

import 'equipment_page.dart';
import 'machine_viewer_360.dart';
import 'repdb_image.dart';

class MachineDetailPage extends StatelessWidget {
  const MachineDetailPage({super.key, required this.equipment});

  final Equipment equipment;

  @override
  Widget build(BuildContext context) {
    final photo = equipment.photo;
    final media = equipment.media;
    final poster = equipment.posterUrl;
    final repDbPoster = (poster?.startsWith('assets/repdb/') ?? false)
        ? poster
        : null;
    return Scaffold(
      appBar: AppBar(title: Text(equipment.label)),
      body: SafeArea(
        top: false,
        child: RepDbImageChoice(
          asset: repDbPoster,
          builder: (context, bundledPoster) => LayoutBuilder(
            builder: (context, size) => Column(
              children: [
                SizedBox(
                  height: size.maxHeight * .49,
                  width: double.infinity,
                  child: MachineViewer360(
                    modelSrc: media.model3dUrl,
                    posterImage: repDbPoster == null ? poster : bundledPoster,
                    fallbackPosterImage: photo?.assetPath,
                    spinFrames: media.spinFrames ?? const [],
                    hotspots: media.hotspots ?? const [],
                    iosModelSrc: media.iosModelUrl,
                    enableAr: const bool.fromEnvironment('ENABLE_MACHINE_AR'),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      if (equipment == Equipment.legPress)
                        const Text(
                          '3D preview uses a demonstration model. Equipment varies by gym.',
                        ),
                      if (bundledPoster != null)
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: RepDbCredit(),
                        )
                      else if (photo != null)
                        SelectableText(photo.credit),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
