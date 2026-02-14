import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GikiMapScreen extends StatelessWidget {
  const GikiMapScreen({super.key});

  static const LatLng _gikiCampusCenter = LatLng(34.0695, 72.6438);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1E3A),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0B3D91),
                  Color(0xFF0A2E66),
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                child: Row(
                  children: [
                    const Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Hello Muhammad Umar Farooq',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
              child: GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: _gikiCampusCenter,
                  zoom: 16.8,
                ),
                mapType: MapType.normal,
                zoomControlsEnabled: true,
                myLocationButtonEnabled: false,
                compassEnabled: true,
                mapToolbarEnabled: false,
                markers: {
                  const Marker(
                    markerId: MarkerId('giki-main'),
                    position: _gikiCampusCenter,
                    infoWindow: InfoWindow(
                      title: 'GIKI Campus',
                      snippet: 'Topi, KP, Pakistan',
                    ),
                  ),
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
