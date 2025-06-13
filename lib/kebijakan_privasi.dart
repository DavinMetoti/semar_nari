import 'package:flutter/material.dart';

class KebijakanPrivasiPage extends StatelessWidget {
  const KebijakanPrivasiPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final kebijakanList = const [
      {
        'title': '1. Informasi yang Dikumpulkan',
        'items': [
          'Nama lengkap siswa dan/atau orang tua/wali',
          'Nomor telepon dan alamat email',
          'Informasi kehadiran dan aktivitas dalam aplikasi',
          'Data perangkat (device ID, sistem operasi, dan versi aplikasi)',
        ],
      },
      {
        'title': '2. Penggunaan Informasi',
        'items': [
          'Memfasilitasi pencatatan kehadiran siswa',
          'Memberikan laporan perkembangan siswa kepada orang tua/wali',
          'Mengirimkan notifikasi atau informasi terkait jadwal kegiatan',
          'Meningkatkan kualitas layanan dan performa aplikasi',
        ],
      },
      {
        'title': '3. Penyimpanan dan Keamanan Data',
        'items': [
          'Kami menyimpan data pengguna dengan sistem keamanan yang memadai dan membatasi akses hanya kepada pihak yang berwenang. Data tidak akan dibagikan kepada pihak ketiga tanpa izin pengguna, kecuali diwajibkan oleh hukum.',
        ],
      },
      {
        'title': '4. Hak Pengguna',
        'items': [
          'Mengakses dan memperbarui informasi pribadi mereka',
          'Meminta penghapusan akun dan data terkait',
          'Menolak penggunaan data untuk keperluan tertentu',
        ],
      },
      {
        'title': '5. Perubahan Kebijakan Privasi',
        'items': [
          'Kami dapat memperbarui kebijakan privasi ini dari waktu ke waktu. Setiap perubahan akan diumumkan melalui aplikasi atau saluran resmi sanggar.',
        ],
      },
    ];

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
              Icons.privacy_tip,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
      body: ListView(
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
                      Icons.privacy_tip,
                      size: 40,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Kebijakan Privasi',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Aplikasi Semar Nari',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _KebijakanCard(
            title: 'Kebijakan Privasi Aplikasi Semar Nari',
            description:
                'Aplikasi Semar Nari dibangun dan dikelola oleh Sanggar Semar Nari Kota Semarang. Kami berkomitmen untuk melindungi dan menghormati privasi pengguna kami. Kebijakan privasi ini menjelaskan bagaimana kami mengumpulkan, menggunakan, menyimpan, dan melindungi informasi pribadi yang Anda berikan saat menggunakan aplikasi kami.',
            kebijakanList: kebijakanList,
          ),
          const SizedBox(height: 24),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            elevation: 0,
            color: theme.colorScheme.primary.withOpacity(0.07),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: Text(
                'Dengan menggunakan aplikasi Semar Nari, Anda dianggap telah membaca dan menyetujui seluruh isi dari kebijakan privasi ini.',
                style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KebijakanCard extends StatelessWidget {
  final String title;
  final String description;
  final List<Map<String, dynamic>> kebijakanList;
  const _KebijakanCard({
    required this.title,
    required this.description,
    required this.kebijakanList,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 2,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14.5,
                height: 1.7,
                color: theme.colorScheme.onSurface.withOpacity(0.92),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 18),
            ...kebijakanList.map((section) => Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: _KebijakanSection(
                    title: section['title'] as String,
                    items: (section['items'] as List).cast<String>(),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _KebijakanSection extends StatelessWidget {
  final String title;
  final List<String> items;
  const _KebijakanSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
            fontSize: 15.5,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14.5,
                      height: 1.6,
                      color: theme.colorScheme.onSurface.withOpacity(0.92),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
