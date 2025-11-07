import 'package:flutter/material.dart';

class OutfitCard extends StatelessWidget {
  final String title;
  final List<String> images;
  const OutfitCard({super.key, required this.title, required this.images});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            for (var i = 0; i < images.length && i < 3; i++)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Image.network(
                  images[i],
                  height: 60,
                  width: 60,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
      ),
    );
  }
}
