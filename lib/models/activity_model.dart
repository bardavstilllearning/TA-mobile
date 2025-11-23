class Riwayat {
  final String nama;
  final String pekerjaan;
  final String tanggal; // tanggal pemesanan atau jadwal kerja
  final String durasi; // jam kerja atau waktu booking
  final int harga;
  final String status; // "Selesai", "Dalam Proses", dll
  final String foto; // path foto pekerja
  final double rating; // rating pekerja

  Riwayat({
    required this.nama,
    required this.pekerjaan,
    required this.tanggal,
    required this.durasi,
    required this.harga,
    required this.status,
    required this.foto,
    required this.rating,
  });
}
