import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class TentangAplikasiPage extends StatelessWidget {
  const TentangAplikasiPage({Key? key}) : super(key: key);

  Future<String> _getAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version} (Build ${info.buildNumber})';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF152349),
        automaticallyImplyLeading: true,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 32,
              width: 32,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Semar Nari',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    fontFamily: 'Montserrat',
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Sanggar Tari Kota Semarang',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ],
            ),
          ],
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(
              Icons.info_outline,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
      body: FutureBuilder<String>(
        future: _getAppVersion(),
        builder: (context, snapshot) {
          final version = snapshot.data ?? '-';

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 80),
              Center(
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withOpacity(0.15),
                            theme.colorScheme.primary.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.info_outline,
                          size: 40,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Tentang Semar Nari',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Aplikasi Sanggar Seni Tari Semarang',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                elevation: 4,
                color: Colors.white,
                shadowColor: theme.colorScheme.primary.withOpacity(0.08),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AboutItem(
                        text:
                            'Aplikasi Semar Nari adalah platform digital resmi milik Sanggar Semar Nari, Kota Semarang. Diluncurkan tahun 2025 sebagai inovasi pengelolaan kegiatan belajar dan latihan seni tari secara modern dan terstruktur.',
                      ),
                      const SizedBox(height: 26),
                      _AboutItem(
                        text:
                            'Mendukung kegiatan internal sanggar: pencatatan kehadiran digital, pemantauan perkembangan siswa oleh orang tua, serta informasi jadwal latihan, pentas, dan pengumuman.',
                      ),
                      const SizedBox(height: 26),
                      _AboutItem(
                        text:
                            'Siswa dapat melihat riwayat kehadiran real-time, orang tua mengakses laporan perkembangan anak secara langsung, meningkatkan komunikasi efektif dan transparan.',
                      ),
                      const SizedBox(height: 26),
                      _AboutItem(
                        text:
                            'Menggabungkan seni dan teknologi, Semar Nari menjadi solusi inovatif untuk pelestarian budaya dan mempermudah manajemen belajar-mengajar seni tari tradisional.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 0,
                color: theme.colorScheme.primary.withOpacity(0.07),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 22, color: theme.colorScheme.primary),
                      const SizedBox(width: 10),
                      Text(
                        'Versi Aplikasi: $version',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AboutItem extends StatelessWidget {
  final String text;
  const _AboutItem({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontSize: 14.5,
          height: 1.7,
          color: theme.colorScheme.onSurface.withOpacity(0.92),
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}
