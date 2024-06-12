import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:presensi_app/model/presensi.dart';
import 'package:presensi_app/screen/attandance_recap_screen.dart';
import 'package:presensi_app/utils/mix.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String nik = "",
      token = "",
      name = "",
      dept = "",
      imgUrl = "";
  bool isMasuk = true;

  Future<void> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    nik = prefs.getString('nik') ?? "";
    token = prefs.getString('jwt') ?? "";
    name = prefs.getString('name') ?? "";
    dept = prefs.getString('dept') ?? "";
    imgUrl = prefs.getString('imgProfil') ?? "not found";
    setState(() {});
  }

  Future<Presensi> fetchPresensi(String nik, String tanggal) async {
    final response = await http.get(
      Uri.parse(
          'https://presensi.spilme.id/presence?nik=$nik&tanggal=$tanggal'),
      headers: {
        'Authorization': 'Bearer $token'
      },
    );

    if (response.statusCode == 200) {
      return Presensi.fromJson(jsonDecode(response.body));
    } else {
      return Presensi(
        id: 0,
        nik: nik,
        tanggal: getTodayDate(),
        jamMasuk: "--:--",
        jamKeluar: '--:--',
        lokasiMasuk: '-',
        lokasiKeluar: '-',
        status: '-',
      );
    }
  }

  Future<void> saveStatusMasuk() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isMasuk', isMasuk);
  }

  Future<void> loadStatusMasuk() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isMasuk = prefs.getBool('isMasuk') ?? true;
    });
  }

  Future<void> recordAttendance() async {
    final endpoint = isMasuk
        ? 'https://presensi.spilme.id/entry'
        : 'https://presensi.spilme.id/exit';
    final requestBody = isMasuk
        ? {
      'nik': nik,
      'tanggal': getTodayDate(),
      'jam_masuk': getTime(),
      'lokasi_masuk': 'polbeng',
    }
        : {
      'nik': nik,
      'tanggal': getTodayDate(),
      'jam_keluar': getTime(),
      'lokasi_keluar': 'polbeng',
    };

    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(responseBody['message'])),
      );
      setState(() {
        isMasuk = !isMasuk;
        saveStatusMasuk();
      });
      fetchPresensi(nik, getTodayDate());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to record attendance')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              // Greetings
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Image.network(
                          imgUrl,
                          height: 84,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.manrope(
                              fontSize: 20,
                              color: const Color(0xFF263238),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            dept,
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              color: const Color(0xFF263238),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Stack(
                    children: [
                      IconButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text('Notification'),
                                content: Text(
                                    'This is a notification message.'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text('OK'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        icon: const Icon(Icons.notifications_none),
                        iconSize: 32,
                        color: Colors.black,
                      ),
                      Positioned(
                        right: 10,
                        top: 8,
                        child: Container(
                          height: 15,
                          width: 15,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF6497),
                            borderRadius: BorderRadius.circular(15 / 2),
                          ),
                          child: Center(
                            child: Text(
                              "2",
                              style: GoogleFonts.mPlus1p(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kehadiran hari ini',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      color: const Color(0xFF101317),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AttandanceRecapScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Rekap Absensi',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        color: const Color(0xFF12A3DA),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              FutureBuilder<Presensi>(
                future: fetchPresensi(nik, getTodayDate()),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (snapshot.hasData) {
                    final data = snapshot.data;
                    return Row(
                      children: [
                        Expanded(
                          child: Card(
                            shape: RoundedRectangleBorder(
                              side: const BorderSide(
                                  color: Color.fromARGB(255, 219, 226, 228),
                                  width: 1.0),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color.fromARGB(
                                              35, 48, 134, 254),
                                          borderRadius: BorderRadius.circular(
                                              10),
                                        ),
                                        child: SvgPicture.asset(
                                            'assets/svgs/login_outlined.svg'),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Masuk',
                                        style: GoogleFonts.lexend(
                                          fontSize: 16,
                                          color: const Color(0xFF101317),
                                        ),
                                        textAlign: TextAlign.left,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    data?.jamMasuk ?? '--:--',
                                    style: GoogleFonts.lexend(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF101317),
                                    ),
                                  ),
                                  Text(
                                    getPresenceEntryStatus(
                                        data?.jamMasuk ?? '-'),
                                    style: GoogleFonts.lexend(
                                      fontSize: 16,
                                      color: const Color(0xFF101317),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Card(
                            shape: RoundedRectangleBorder(
                              side: const BorderSide(
                                  color: Color.fromARGB(255, 219, 226, 228),
                                  width: 1.0),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color.fromARGB(
                                              35, 48, 134, 254),
                                          borderRadius: BorderRadius.circular(
                                              10),
                                        ),
                                        child: SvgPicture.asset(
                                            'assets/svgs/logout_outlined.svg'),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Keluar',
                                        style: GoogleFonts.lexend(
                                          fontSize: 16,
                                          color: const Color(0xFF101317),
                                        ),
                                        textAlign: TextAlign.left,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    data?.jamKeluar ?? '--:--',
                                    style: GoogleFonts.lexend(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF101317),
                                    ),
                                  ),
                                  Text(
                                    getPresenceExitStatus(
                                        data?.jamKeluar ?? '-'),
                                    style: GoogleFonts.lexend(
                                      fontSize: 16,
                                      color: const Color(0xFF101317),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return const Center(child: Text('No data available'));
                  }
                },
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) {
                      return attandanceScreen();
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: const Color(0xFF12A3DA),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.circle_outlined,
                      color: Colors.white,
                      size: 24.0,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tekan untuk presensi ${isMasuk ? 'masuk' : 'pulang'}',
                      style: GoogleFonts.lexend(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/images/bg_izin.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Izin Absen',
                                style: GoogleFonts.manrope(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Isi form untuk mengajukan izin absensi',
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xff313638),
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  'Ajukan izin',
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/images/bg_cuti.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Izin Cuti',
                                style: GoogleFonts.manrope(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Isi form untuk mengajukan cuti',
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 40),
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xff9B59B6),
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  'Ajukan Cuti',
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget attandanceScreen() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Presensi ${isMasuk ? 'Masuk' : 'Pulang'}',
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_month,
                    color: Color(0xffE74C3C),
                    size: 32,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tanggal ${isMasuk ? 'Masuk' : 'Pulang'}',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xff111111),
                        ),
                      ),
                      Text(
                        getToday(),
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          color: const Color(0xff707070),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.av_timer_outlined,
                    color: Color(0xffE74C3C),
                    size: 32,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jam ${isMasuk ? 'Masuk' : 'Pulang'}',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xff111111),
                        ),
                      ),
                      Text(
                        getTime(),
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          color: const Color(0xff707070),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Text(
                'Foto selfie di area kantor',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  color: const Color(0xff707070),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Container(
                  height: 200,
                  alignment: Alignment.center,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Ambil Gambar'),
                    onPressed: () {
                      // Implement your image picking logic
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: recordAttendance,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  'Simpan',
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}