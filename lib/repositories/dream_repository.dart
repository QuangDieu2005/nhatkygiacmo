import '../models/dream_model.dart';

abstract interface class DreamDataRepository {
  Future<List<DreamModel>> getAllDreams();
  Future<DreamModel?> getDreamById(String id);
  Future<void> addDream(DreamModel dream);
  Future<void> updateDream(DreamModel dream);
  Future<void> deleteDream(String id);
}

class DreamRepository implements DreamDataRepository {
  DreamRepository._();
  static final DreamRepository instance = DreamRepository._();

  // Dữ liệu mẫu ban đầu (Mock Data)
  final List<DreamModel> _dreams = [
    DreamModel(
      id: 'dream_01',
      userId: 'user_01',
      title: 'Bay lượn trên thành phố sao đêm',
      content: 'Tôi thấy mình mọc một đôi cánh phát sáng màu tím, có thể lướt êm ái qua những tòa nhà chọc trời dưới bầu trời đêm ngập tràn ánh sao lấp lánh. Không khí trong lành và nhẹ bẫng.',
      emotion: EmotionType.excited,
      tags: ['Bay', 'Thành phố', 'Sao đêm', 'Tự do'],
      clarityScore: 5,
      isLucid: true,
      dreamDate: DateTime.now().subtract(const Duration(hours: 14)),
      createdAt: DateTime.now().subtract(const Duration(hours: 14)),
    ),
    DreamModel(
      id: 'dream_02',
      userId: 'user_01',
      title: 'Khu vườn hoa pha lê phát sáng',
      content: 'Một khu vườn kỳ bí nơi tất cả các loài hoa đều làm bằng pha lê trong suốt, phát ra tiếng chuông gió du dương mỗi khi có làn gió thoảng qua. Cảm giác vô cùng thư thái và tĩnh lặng.',
      emotion: EmotionType.peaceful,
      tags: ['Khu vườn', 'Pha lê', 'Bình yên'],
      clarityScore: 4,
      isLucid: false,
      dreamDate: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    ),
    DreamModel(
      id: 'dream_03',
      userId: 'user_01',
      title: 'Bữa tiệc trà với những người bạn cũ',
      content: 'Chúng tôi ngồi trên một chiếc thảm bay giữa đám mây ngũ sắc, cùng uống trà thảo mộc và kể lại những kỷ niệm ngày còn bé. Ai nấy đều cười rạng rỡ và hạnh phúc.',
      emotion: EmotionType.happy,
      tags: ['Bạn bè', 'Trà', 'Kỷ niệm', 'Mây'],
      clarityScore: 4,
      isLucid: false,
      dreamDate: DateTime.now().subtract(const Duration(days: 2, hours: 5)),
      createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 5)),
    ),
    DreamModel(
      id: 'dream_04',
      userId: 'user_01',
      title: 'Lạc lối trong mê cung gương vô tận',
      content: 'Mỗi khúc quanh đều phản chiếu một phiên bản khác nhau của bản thân trong các trang phục từ nhiều thời đại. Tôi cố gắng tìm lối ra nhưng các cánh cửa liên tục đổi vị trí.',
      emotion: EmotionType.confused,
      tags: ['Mê cung', 'Gương', 'Bí ẩn'],
      clarityScore: 3,
      isLucid: false,
      dreamDate: DateTime.now().subtract(const Duration(days: 3, hours: 8)),
      createdAt: DateTime.now().subtract(const Duration(days: 3, hours: 8)),
    ),
    DreamModel(
      id: 'dream_05',
      userId: 'user_01',
      title: 'Cơn sóng thần màu tím dâng cao',
      content: 'Đứng trên bờ biển nhìn thấy ngọn sóng khổng lồ màu tím thẫm từ xa tiến lại gần. Tôi cố chạy trốn nhưng đôi chân dường như dính chặt xuống cát lún. Rất may đã tỉnh dậy kịp lúc.',
      emotion: EmotionType.scared,
      tags: ['Biển', 'Sóng thần', 'Cơn ác mộng'],
      clarityScore: 4,
      isLucid: false,
      dreamDate: DateTime.now().subtract(const Duration(days: 4, hours: 6)),
      createdAt: DateTime.now().subtract(const Duration(days: 4, hours: 6)),
    ),
    DreamModel(
      id: 'dream_06',
      userId: 'user_01',
      title: 'Chuyến tàu hơi nước xuyên thời gian',
      content: 'Tàu chạy trên một đường ray lơ lửng giữa dải ngân hà. Đi qua từng ga là những thế kỷ khác nhau, từ thời khủng long đến các trạm vũ trụ hiện đại trong tương lai.',
      emotion: EmotionType.excited,
      tags: ['Tàu hỏa', 'Vũ trụ', 'Thời gian'],
      clarityScore: 5,
      isLucid: true,
      dreamDate: DateTime.now().subtract(const Duration(days: 5, hours: 3)),
      createdAt: DateTime.now().subtract(const Duration(days: 5, hours: 3)),
    ),
    DreamModel(
      id: 'dream_07',
      userId: 'user_01',
      title: 'Bức thư bị nhòe dưới cơn mưa chiều',
      content: 'Tôi nhận được một phong thư không đề tên người gửi. Khi mở ra dưới mưa, mực bị nhòe đi chỉ còn đọng lại vài chữ thể hiện nỗi nhớ da diết. Tỉnh dậy với cảm giác man mác buồn.',
      emotion: EmotionType.sad,
      tags: ['Mưa', 'Bức thư', 'Hoài niệm'],
      clarityScore: 3,
      isLucid: false,
      dreamDate: DateTime.now().subtract(const Duration(days: 6, hours: 4)),
      createdAt: DateTime.now().subtract(const Duration(days: 6, hours: 4)),
    ),
    DreamModel(
      id: 'dream_08',
      userId: 'user_01',
      title: 'Ngồi thiền bên bờ hồ sương mù',
      content: 'Hồ nước phẳng lặng như gương, không gợn một tiếng động. Mặt nước phản chiếu ánh trăng bạc dịu nhẹ, tâm trí hoàn toàn thanh tịnh.',
      emotion: EmotionType.peaceful,
      tags: ['Hồ nước', 'Trăng', 'Tĩnh lặng'],
      clarityScore: 4,
      isLucid: false,
      dreamDate: DateTime.now().subtract(const Duration(days: 7, hours: 7)),
      createdAt: DateTime.now().subtract(const Duration(days: 7, hours: 7)),
    ),
    DreamModel(
      id: 'dream_09',
      userId: 'user_01',
      title: 'Đi dạo trên một con phố bình thường',
      content: 'Giấc mơ đơn giản là đi bộ qua con ngõ quen thuộc, ghé tiệm tạp hóa mua một món đồ nhỏ rồi về nhà.',
      emotion: EmotionType.neutral,
      tags: ['Đường phố', 'Bình thường'],
      clarityScore: 2,
      isLucid: false,
      dreamDate: DateTime.now().subtract(const Duration(days: 8, hours: 10)),
      createdAt: DateTime.now().subtract(const Duration(days: 8, hours: 10)),
    ),
    DreamModel(
      id: 'dream_10',
      userId: 'user_01',
      title: 'Khám phá thư viện cổ dưới lòng đại dương',
      content: 'Một thư viện rộng lớn với hàng vạn cuốn sách phát sáng được bọc trong bong bóng khí dưới đáy biển. Những chú cá heo bơi xung quanh nhìn tôi đọc sách.',
      emotion: EmotionType.excited,
      tags: ['Đại dương', 'Thư viện', 'Sách'],
      clarityScore: 5,
      isLucid: true,
      dreamDate: DateTime.now().subtract(const Duration(days: 9, hours: 6)),
      createdAt: DateTime.now().subtract(const Duration(days: 9, hours: 6)),
    ),
  ];

  // TODO: Sau này kết nối Node.js backend & Supabase Database:
  // - Gọi ApiService.instance.fetchDreams()
  // - Hoặc Supabase.instance.client.from('dreams').select()

  @override
  Future<List<DreamModel>> getAllDreams() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.unmodifiable(_dreams);
  }

  @override
  Future<DreamModel?> getDreamById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _dreams.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> addDream(DreamModel dream) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _dreams.insert(0, dream);
  }

  @override
  Future<void> updateDream(DreamModel dream) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _dreams.indexWhere((d) => d.id == dream.id);
    if (index != -1) {
      _dreams[index] = dream;
    }
  }

  @override
  Future<void> deleteDream(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _dreams.removeWhere((d) => d.id == id);
  }
}
