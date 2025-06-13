import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'home.dart';
import 'detail_student.dart';
import 'history_student.dart';

class StudentListPage extends StatefulWidget {
  @override
  _StudentListPageState createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  List<dynamic> branches = [];
  List<dynamic> students = [];
  List<dynamic> filteredStudents = [];
  String? selectedBranch;
  bool isLoading = false;
  String searchQuery = '';
  final Map<int, bool> _flipped = {}; // flip state per card

  @override
  void initState() {
    super.initState();
    fetchBranches();
  }

  // Fetch all branches from the API
  Future<void> fetchBranches() async {
    final response = await http.get(Uri.parse('https://semarnari.sportballnesia.com/api/master/data/get_all_branch'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        branches = data['data'];
      });
    } else {
      // Handle error if necessary
    }
  }

  // Fetch students based on the selected branch
  Future<void> fetchStudents() async {
    if (selectedBranch == null) return;

    setState(() {
      students = [];
      filteredStudents = [];
      isLoading = true;
      searchQuery = '';
    });

    final response = await http.post(
      Uri.parse('https://semarnari.sportballnesia.com/api/master/user/get_all_student'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({'branch': selectedBranch}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<dynamic> fetchedStudents = data['data'];
      // Urutkan abjad
      fetchedStudents.sort((a, b) =>
          (a['fullname'] ?? '').toString().toLowerCase().compareTo((b['fullname'] ?? '').toString().toLowerCase()));
      setState(() {
        students = fetchedStudents;
        filteredStudents = students;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  void filterStudents(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredStudents = students;
      } else {
        filteredStudents = students.where((student) {
          final name = (student['fullname'] ?? '').toString().toLowerCase();
          return name.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF152349),
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 30,
                  width: 30,
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Semar Nari',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Sanggar Tari Kota Semarang',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            IconButton(
              icon: const Icon(
                Icons.home,
                size: 30.0,
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pilih Cabang dengan desain lebih baik
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pilih Cabang',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF31416A))),
                    const SizedBox(height: 10),
                    DropdownButtonFormField2<String>(
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(0xFF31416A), width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(0xFF31416A), width: 1),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF6F8FB),
                      ),
                      hint: const Text(
                        'Pilih Cabang',
                        style: TextStyle(fontSize: 14, color: Color(0xFF31416A)),
                      ),
                      items: branches.map<DropdownMenuItem<String>>((branch) {
                        return DropdownMenuItem<String>(
                          value: branch['id'].toString(),
                          child: Text(branch['name'], style: const TextStyle(fontSize: 16)),
                        );
                      }).toList(),
                      value: selectedBranch,
                      onChanged: (value) {
                        setState(() {
                          selectedBranch = value.toString();
                          fetchStudents();
                        });
                      },
                      buttonStyleData: const ButtonStyleData(
                        padding: EdgeInsets.only(right: 8),
                      ),
                      iconStyleData: const IconStyleData(
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: Color(0xFF31416A),
                        ),
                        iconSize: 24,
                      ),
                      dropdownStyleData: DropdownStyleData(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Jumlah siswa dan filter/search
            if (selectedBranch != null && !isLoading)
              Row(
                children: [
                  Expanded(
                    child: Card(
                      elevation: 0,
                      color: const Color(0xFF31416A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        child: Row(
                          children: [
                            const Icon(Icons.people, color: Colors.white, size: 22),
                            const SizedBox(width: 10),
                            Text(
                              '${students.length}',
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Cari nama siswa...',
                            prefixIcon: const Icon(Icons.search, color: Color(0xFF31416A)),
                            border: InputBorder.none,
                          ),
                          onChanged: filterStudents,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

            // Skeleton loading
            if (isLoading)
              Expanded(
                child: ListView.builder(
                  itemCount: 6,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: _SkeletonCard(),
                  ),
                ),
              ),

            // Student List
            if (!isLoading && filteredStudents.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: filteredStudents.length,
                  itemBuilder: (context, index) {
                    final student = filteredStudents[index];
                    return StatefulBuilder(
                      builder: (context, setLocalState) {
                        final isFlipped = _flipped[index] ?? false;
                        const double cardHeight = 170;
                        // Tambahkan animasi muncul (fade + slide)
                        return TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: 1),
                          duration: Duration(milliseconds: 400 + index * 60),
                          curve: Curves.easeOutCubic,
                          builder: (context, animValue, child) {
                            return Opacity(
                              opacity: animValue,
                              child: Transform.translate(
                                offset: Offset(0, (1 - animValue) * 30),
                                child: SizedBox(
                                  height: cardHeight,
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween<double>(begin: isFlipped ? 1 : 0, end: isFlipped ? 1 : 0),
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeInOut,
                                    builder: (context, value, child) {
                                      final angle = value * 3.1416;
                                      final isBack = angle > 3.1416 / 2;
                                      return AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                        height: cardHeight,
                                        child: Transform(
                                          alignment: Alignment.center,
                                          transform: Matrix4.identity()
                                            ..setEntry(3, 2, 0.001)
                                            ..rotateY(angle),
                                          child: isBack
                                              ? GestureDetector(
                                                  onTap: () {
                                                    setLocalState(() {
                                                      _flipped[index] = false;
                                                    });
                                                    setState(() {});
                                                  },
                                                  child: Transform(
                                                    alignment: Alignment.center,
                                                    transform: Matrix4.identity()..rotateY(3.1416),
                                                    child: _buildStudentCardBackWithDelete(
                                                      student,
                                                      index,
                                                      cardHeight,
                                                      setLocalState,
                                                      onDelete: () async {
                                                        final confirm = await showDialog<bool>(
                                                          context: context,
                                                          builder: (ctx) => AlertDialog(
                                                            title: const Text('Konfirmasi Hapus'),
                                                            content: const Text('Yakin ingin menghapus siswa ini?'),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () => Navigator.pop(ctx, false),
                                                                child: const Text('Batal'),
                                                              ),
                                                              TextButton(
                                                                onPressed: () => Navigator.pop(ctx, true),
                                                                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                        if (confirm == true) {
                                                          final resp = await http.post(
                                                            Uri.parse('https://semarnari.sportballnesia.com/api/master/user/delete'),
                                                            headers: {'Content-Type': 'application/json'},
                                                            body: json.encode({'username': student['username']}),
                                                          );
                                                          if (resp.statusCode == 200) {
                                                            setState(() {
                                                              students.removeWhere((s) => s['id'] == student['id']);
                                                              filteredStudents = students.where((stu) {
                                                                final name = (stu['fullname'] ?? '').toString().toLowerCase();
                                                                return searchQuery.isEmpty || name.contains(searchQuery.toLowerCase());
                                                              }).toList();
                                                            });
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              const SnackBar(content: Text('Siswa berhasil dihapus')),
                                                            );
                                                          } else {
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              const SnackBar(content: Text('Gagal menghapus siswa')),
                                                            );
                                                          }
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                )
                                              : GestureDetector(
                                                  onTap: () {
                                                    setLocalState(() {
                                                      _flipped[index] = true;
                                                    });
                                                    setState(() {});
                                                  },
                                                  child: _buildStudentCardFront(student, index, cardHeight),
                                                ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            // No Data Found
            if (!isLoading && filteredStudents.isEmpty)
              Center(child: Text('Tidak ada data siswa ditemukan.', style: TextStyle(fontSize: 16))),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCardFront(Map<String, dynamic> student, int index, double cardHeight) {
    return Container(
      key: const ValueKey(false),
      height: cardHeight,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF31416A), Color(0xFF5B6BAA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Nomor urut di pojok kiri atas
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          // Isi utama card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 18.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Foto siswa
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.10),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: (() {
                    final photo = student['photo']?.toString() ?? '';
                    if (photo.isNotEmpty) {
                      if (photo.startsWith('data:image/')) {
                        try {
                          final base64Str = photo.split(',').last;
                          return ClipOval(
                            child: Image.memory(
                              base64Decode(base64Str),
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                            ),
                          );
                        } catch (_) {
                          return Icon(Icons.account_circle, size: 44, color: Colors.grey.shade300);
                        }
                      } else {
                        return ClipOval(
                          child: Image.network(
                            photo,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.account_circle,
                              size: 44,
                              color: Colors.grey.shade300,
                            ),
                          ),
                        );
                      }
                    } else {
                      return Icon(Icons.account_circle, size: 65, color: Colors.grey.shade300);
                    }
                  })(),
                ),
                const SizedBox(width: 6),
                // Nama, email, username, status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        (student['fullname']?.toString().split(' ').take(2).join(' ') ?? 'Nama Tidak Diketahui').toUpperCase(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.person, color: Colors.white70, size: 15),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Username: ${student['username'] ?? 'Tidak Tersedia'}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.grade, color: Colors.white70, size: 15),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Kelas: ${(student['grade'] == '0' || student['grade'] == 0) ? 'TK' : student['grade'].toString()}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Status badge
                      Row(
                        children: [
                          Icon(
                            student['active'] == '1' ? Icons.check_circle : Icons.cancel,
                            color: student['active'] == '1' ? Colors.greenAccent : Colors.redAccent,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            student['active'] == '1' ? 'Aktif' : 'Tidak Aktif',
                            style: TextStyle(
                              color: student['active'] == '1' ? Colors.greenAccent : Colors.redAccent,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Action icons
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HistoryStudentPage(
                              studentId: student['id'].toString(),
                              studentName: student['fullname'] ?? 'Siswa',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.calendar_today,
                        color: Colors.greenAccent,
                        size: 22,
                      ),
                      tooltip: 'Lihat Presensi',
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailStudentPage(
                              studentId: student['id'].toString(),
                              fullname: student['fullname'] ?? 'Nama Tidak Diketahui',
                              username: student['username'] ?? 'Tidak Tersedia',
                              email: student['email'] ?? 'Email Tidak Diketahui',
                              branchName: student['branch_name'] ?? 'Cabang Tidak Diketahui',
                              phone: student['child_phone_number'] ?? 'Nomor Telepon Tidak Tersedia',
                              class_name: student['class_name'] ?? 'Kelas Tidak Tersedia',
                              active: student['active'] ?? '0',
                              grade: student['grade'] ?? '0',
                            ),
                          ),
                        ).then((_) {
                          fetchStudents();
                        });
                      },
                      icon: const Icon(
                        Icons.visibility,
                        color: Colors.amberAccent,
                        size: 22,
                      ),
                      tooltip: 'Lihat Detail',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCardBack(Map<String, dynamic> student, int index, double cardHeight) {
    return Container(
      key: const ValueKey(true),
      height: cardHeight,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF5B6BAA), Color(0xFF31416A)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'DETAIL SISWA',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.email, 'Email', student['email'] ?? 'Email Tidak Diketahui'),
              _buildDetailRow(Icons.school, 'Ruangan', student['class_name'] ?? 'Kelas Tidak Tersedia'),
              _buildDetailRow(Icons.phone, 'Phone', student['parent_phone_number'] ?? 'Nomor Telepon Tidak Tersedia'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentCardBackWithDelete(
    Map<String, dynamic> student,
    int index,
    double cardHeight,
    void Function(void Function()) setLocalState, {
    required VoidCallback onDelete,
  }) {
    return Container(
      key: const ValueKey(true),
      height: cardHeight,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF5B6BAA), Color(0xFF31416A)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'DETAIL SISWA',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent, size: 24),
                    tooltip: 'Hapus',
                    onPressed: onDelete,
                  ),
                ],
              ),
              _buildDetailRow(Icons.email, 'Email', student['email'] ?? 'Email Tidak Diketahui'),
              _buildDetailRow(Icons.school, 'Ruangan', student['class_name'] ?? 'Kelas Tidak Tersedia'),
              _buildDetailRow(Icons.phone, 'Phone', student['parent_phone_number'] ?? 'Nomor Telepon Tidak Tersedia'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {Color iconColor = Colors.white70}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w400,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// Skeleton loader widget
class _SkeletonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const SizedBox(width: 22),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 18, width: 120, color: Colors.grey[300]),
                  const SizedBox(height: 8),
                  Container(height: 12, width: 180, color: Colors.grey[200]),
                  const SizedBox(height: 8),
                  Container(height: 12, width: 100, color: Colors.grey[200]),
                  const SizedBox(height: 8),
                  Container(height: 12, width: 80, color: Colors.grey[200]),
                ],
              ),
            ),
          ),
          const SizedBox(width: 22),
        ],
      ),
    );
  }
}
