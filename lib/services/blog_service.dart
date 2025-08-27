import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/blog_post.dart';

class BlogService {
  static const String _blogPostsKey = 'blog_posts';

  // Blog yazılarını getir
  Future<List<BlogPost>> getBlogPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final blogPostsData = prefs.getStringList(_blogPostsKey) ?? [];

    if (blogPostsData.isEmpty) {
      // İlk çalıştırmada demo verilerini yükle
      await _loadDemoData();
      return getBlogPosts();
    }

    return blogPostsData
        .map((data) => BlogPost.fromJson(json.decode(data)))
        .toList()
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
  }

  // Kategoriye göre blog yazılarını getir
  Future<List<BlogPost>> getBlogPostsByCategory(String category) async {
    final allPosts = await getBlogPosts();
    return allPosts.where((post) => post.category == category).toList();
  }

  // Öne çıkan yazıları getir
  Future<List<BlogPost>> getFeaturedPosts() async {
    final allPosts = await getBlogPosts();
    return allPosts.where((post) => post.isFeatured).toList();
  }

  // En popüler yazıları getir
  Future<List<BlogPost>> getPopularPosts({int limit = 5}) async {
    final allPosts = await getBlogPosts();
    allPosts.sort((a, b) => b.views.compareTo(a.views));
    return allPosts.take(limit).toList();
  }

  // Blog yazısını ID ile getir
  Future<BlogPost?> getBlogPostById(String id) async {
    final allPosts = await getBlogPosts();
    try {
      return allPosts.firstWhere((post) => post.id == id);
    } catch (e) {
      return null;
    }
  }

  // Blog yazısının görüntülenme sayısını artır
  Future<void> incrementViews(String postId) async {
    final allPosts = await getBlogPosts();
    final postIndex = allPosts.indexWhere((post) => post.id == postId);

    if (postIndex != -1) {
      allPosts[postIndex] = allPosts[postIndex].copyWith(
        views: allPosts[postIndex].views + 1,
      );
      await _saveBlogPosts(allPosts);
    }
  }

  // Blog yazısını beğen
  Future<void> likeBlogPost(String postId) async {
    final allPosts = await getBlogPosts();
    final postIndex = allPosts.indexWhere((post) => post.id == postId);

    if (postIndex != -1) {
      allPosts[postIndex] = allPosts[postIndex].copyWith(
        likes: allPosts[postIndex].likes + 1,
      );
      await _saveBlogPosts(allPosts);
    }
  }

  // Arama fonksiyonu
  Future<List<BlogPost>> searchBlogPosts(String query) async {
    final allPosts = await getBlogPosts();
    final lowercaseQuery = query.toLowerCase();

    return allPosts.where((post) {
      return post.title.toLowerCase().contains(lowercaseQuery) ||
          post.excerpt.toLowerCase().contains(lowercaseQuery) ||
          post.content.toLowerCase().contains(lowercaseQuery) ||
          post.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  // Kategorileri getir
  List<String> getCategories() {
    return BlogCategory.values.map((category) => category.displayName).toList();
  }

  // Blog yazılarını kaydet
  Future<void> _saveBlogPosts(List<BlogPost> posts) async {
    final prefs = await SharedPreferences.getInstance();
    final blogPostsData = posts
        .map((post) => json.encode(post.toJson()))
        .toList();
    await prefs.setStringList(_blogPostsKey, blogPostsData);
  }

  // Demo verileri yükle
  Future<void> _loadDemoData() async {
    final demoPosts = [
      BlogPost(
        id: '1',
        title: 'Günlük Diş Bakımı: Doğru Fırçalama Teknikleri',
        excerpt:
            'Diş sağlığınızı korumak için doğru fırçalama tekniklerini öğrenin. Uzmanlarımızdan adım adım rehber.',
        content: '''# Günlük Diş Bakımı: Doğru Fırçalama Teknikleri

Diş sağlığınızı korumak için en önemli alışkanlık düzenli ve doğru diş fırçalamadır. Bu yazımızda doğru fırçalama tekniklerini detaylı olarak ele alacağız.

## Doğru Fırçalama Tekniği

1. **Diş Fırçası Seçimi**: Orta sertlikte kılları olan bir diş fırçası seçin
2. **Diş Macunu**: Florür içeren diş macunu kullanın
3. **Süre**: En az 2 dakika fırçalayın
4. **Teknik**: Dairesel hareketlerle nazikçe fırçalayın

## Fırçalama Sıklığı

- Günde en az 2 kez (sabah ve akşam)
- Yemeklerden 30-60 dakika sonra
- Özellikle şekerli yiyeceklerden sonra

## Dikkat Edilmesi Gerekenler

- Çok sert fırçalamayın, diş eti hasarına yol açabilir
- Diş fırçanızı 3-4 ayda bir değiştirin
- Fırçalama sonrası ağız gargarasını ihmal etmeyin

Düzenli diş fırçalama ile çürük, diş eti hastalıkları ve ağız kokusunu önleyebilirsiniz.''',
        category: BlogCategory.preventive.displayName,
        tags: ['diş fırçalama', 'ağız bakımı', 'günlük bakım', 'diş sağlığı'],
        imageUrl:
            'https://images.unsplash.com/photo-1606811841689-23dfddce3e95?w=800',
        authorName: 'Dr. Ayşe Kaya',
        publishedAt: DateTime.now().subtract(const Duration(days: 2)),
        readTimeMinutes: 5,
        isFeatured: true,
        views: 245,
        likes: 18,
      ),

      BlogPost(
        id: '2',
        title: 'Çocuklarda Diş Çürüğü: Önleme ve Tedavi',
        excerpt:
            'Çocukların diş sağlığını korumak için alınması gereken önlemler ve erken dönem müdahale yöntemleri.',
        content: '''# Çocuklarda Diş Çürüğü: Önleme ve Tedavi

Çocukların diş sağlığı, gelecekteki ağız sağlığının temelini oluşturur. Bu yazımızda çocuklarda diş çürüğü önleme yöntemlerini ele alacağız.

## Çürük Oluşum Sebepleri

1. **Şekerli Gıdalar**: Özellikle şeker, çikolata ve gazlı içecekler
2. **Yetersiz Diş Bakımı**: Düzensiz fırçalama
3. **Genetik Faktörler**: Ailesel yatkınlık
4. **Biberon Çürüğü**: Geceleri süt şişesi ile uyumak

## Önleme Yöntemleri

### Beslenme
- Şekerli atıştırmalıkları sınırlandırın
- Su tüketimini artırın
- Kalsiyum açısından zengin gıdalar verin

### Diş Bakımı
- 2 yaşından itibaren florürlü diş macunu kullanın
- Günde 2 kez diş fırçalayın
- 6 ayda bir diş hekimi kontrolü

## Erken Belirtiler

- Dişlerde beyaz lekeler
- Sıcak/soğuk hassasiyeti
- Diş ağrısı
- Dişlerde renk değişimi

Erken teşhis ve tedavi ile çocuğunuzun diş sağlığını koruyabilirsiniz.''',
        category: BlogCategory.children.displayName,
        tags: ['çocuk diş hekimliği', 'diş çürüğü', 'önleme', 'çocuk sağlığı'],
        imageUrl:
            'https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=800',
        authorName: 'Dr. Mehmet Özkan',
        publishedAt: DateTime.now().subtract(const Duration(days: 5)),
        readTimeMinutes: 7,
        isFeatured: true,
        views: 189,
        likes: 24,
      ),

      BlogPost(
        id: '3',
        title: 'Diş Eti Hastalıkları: Gingivit ve Periodontit',
        excerpt:
            'Diş eti hastalıklarının belirtileri, nedenleri ve tedavi yöntemleri hakkında kapsamlı bilgiler.',
        content: '''# Diş Eti Hastalıkları: Gingivit ve Periodontit

Diş eti hastalıkları, diş kaybının en önemli nedenlerinden biridir. Bu yazımızda gingivit ve periodontit hakkında bilgi vereceğiz.

## Gingivit Nedir?

Gingivit, diş etlerinin iltihabıdır ve erken tedavi ile tamamen iyileştirilebilir.

### Belirtileri:
- Diş etlerinde kızarıklık
- Şişlik ve hassasiyet
- Fırçalama sırasında kanama
- Ağız kokusu

## Periodontit Nedir?

Tedavi edilmeyen gingivitin ilerlemesi ile oluşan ciddi diş eti hastalığıdır.

### Belirtileri:
- Diş etlerinde çekilme
- Diş sallantısı
- Diş aralarında açılma
- Ağız tadında bozukluk

## Tedavi Yöntemleri

### Gingivit Tedavisi:
1. Profesyonel diş temizliği
2. Günlük ağız bakımının iyileştirilmesi
3. Antibakteriyel gargara kullanımı

### Periodontit Tedavisi:
1. Kök yüzeyi düzeltmesi
2. Cerrahi müdahale (gerekirse)
3. Düzenli kontroller

## Önleme

- Günlük diş ipi kullanımı
- Düzenli diş fırçalama
- 6 ayda bir diş hekimi kontrolü
- Sigara kullanımından kaçınma

Erken teşhis ile diş eti hastalıkları başarıyla tedavi edilebilir.''',
        category: BlogCategory.treatment.displayName,
        tags: ['diş eti hastalığı', 'gingivit', 'periodontit', 'tedavi'],
        imageUrl:
            'https://images.unsplash.com/photo-1588776814546-1ffcf47267a5?w=800',
        authorName: 'Dr. Fatma Demir',
        publishedAt: DateTime.now().subtract(const Duration(days: 8)),
        readTimeMinutes: 6,
        isFeatured: false,
        views: 156,
        likes: 12,
      ),

      BlogPost(
        id: '4',
        title: 'Acil Diş Ağrısında Ne Yapmalı?',
        excerpt:
            'Gece yarısı başlayan diş ağrısı için evde uygulayabileceğiniz ilk yardım yöntemleri ve ağrı kesici öneriler.',
        content: '''# Acil Diş Ağrısında Ne Yapmalı?

Diş ağrısı genellikle en beklenmedik zamanlarda ortaya çıkar. Bu yazımızda acil diş ağrısında yapılabilecekleri ele alacağız.

## İlk Yardım Yöntemleri

### Anında Yapılabilecekler:
1. **Soğuk Kompres**: Şişlik varsa dışarıdan soğuk uygulayın
2. **Ağrı Kesici**: Doktor önerisi doğrultusunda ağrı kesici alın
3. **Tuzlu Su Gargarası**: 1 çay kaşığı tuzu 1 bardak ılık suda eritin
4. **Diş İpi**: Dişler arasındaki yemek artıklarını temizleyin

### Kaçınılması Gerekenler:
- Ağrıyan dişe aspirin koymak
- Çok sıcak veya soğuk yiyecekler
- Sert yiyecekler çiğnemek
- Alkol kullanımı

## Ne Zaman Acil Servise Gidilmeli?

- Yüzde şişlik varsa
- Ateş eşlik ediyorsa
- Yutkunmada zorluk varsa
- Ağrı kesiciler etkisizse

## Diş Ağrısının Nedenleri

1. **Diş Çürüğü**: En yaygın neden
2. **Diş Kırığı**: Travma sonucu
3. **Diş Eti İltihabı**: Bakım eksikliği
4. **Diş Çıkarımı**: Özellikle 20 yaş dişleri

## Önleme

- Düzenli diş hekimi kontrolü
- Günlük ağız bakımı
- Sert yiyeceklerden kaçınma
- Gece dişlerinizi sıkıyorsanız koruyucu kullanın

Remember: Diş ağrısı her zaman ciddi bir problemi işaret eder, en kısa sürede diş hekimine başvurun.''',
        category: BlogCategory.emergency.displayName,
        tags: ['acil durum', 'diş ağrısı', 'ilk yardım', 'ağrı kesici'],
        imageUrl:
            'https://images.unsplash.com/photo-1559757175-0eb30cd8c063?w=800',
        authorName: 'Dr. Can Yılmaz',
        publishedAt: DateTime.now().subtract(const Duration(days: 12)),
        readTimeMinutes: 4,
        isFeatured: false,
        views: 312,
        likes: 28,
      ),

      BlogPost(
        id: '5',
        title: 'Diş Beyazlatma: Yöntemler ve Öneriler',
        excerpt:
            'Evde ve klinikte uygulanan diş beyazlatma yöntemleri, avantajları ve dikkat edilmesi gereken noktalar.',
        content: '''# Diş Beyazlatma: Yöntemler ve Öneriler

Güzel bir gülümseme için beyaz dişler önemlidir. Bu yazımızda diş beyazlatma yöntemlerini detaylı olarak inceleyeceğiz.

## Diş Beyazlatma Yöntemleri

### Klinikte Yapılan Beyazlatma:
1. **Profesyonel Beyazlatma**: En etkili yöntem
2. **Laser Beyazlatma**: Hızlı sonuç
3. **Özel Plak ile Beyazlatma**: Evde devam eden tedavi

### Evde Yapılan Yöntemler:
1. **Beyazlatıcı Diş Macunu**: Günlük kullanım
2. **Beyazlatıcı Şeritler**: Kolay uygulama
3. **Beyazlatıcı Jel**: Etkili sonuç

## Doğal Yöntemler

### Etkili Doğal Yollar:
- **Karbonat**: Haftada 1-2 kez
- **Çilek**: Doğal asit içeriği
- **Hindistan Cevizi Yağı**: Oil pulling yöntemi
- **Elma Sirkesi**: Seyreltilmiş olarak gargara

### Dikkat Edilecek Noktalar:
- Doğal yöntemler sınırlı etkilidir
- Aşırı kullanım diş minesine zarar verebilir
- Hassasiyet oluşabilir

## Beyazlatma Sonrası Bakım

### İlk 48 Saat:
- Çay, kahve, kırmızı şaraptan kaçının
- Sigara içmeyin
- Renkli yiyeceklerden uzak durun

### Uzun Vadeli Bakım:
- Düzenli diş fırçalama
- Pipet kullanarak içecek tüketin
- 6 ayda bir diş temizliği

## Kimler Beyazlatma Yaptıramaz?

- Hamile ve emziren kadınlar
- 16 yaş altı gençler
- Ciddi diş eti hastalığı olanlar
- Aşırı hassas dişleri olanlar

Profesyonel beyazlatma en güvenli ve etkili yöntemdir.''',
        category: BlogCategory.cosmetic.displayName,
        tags: ['diş beyazlatma', 'estetik', 'gülümseme', 'beyaz diş'],
        imageUrl:
            'https://images.unsplash.com/photo-1609840114035-3c981960af0e?w=800',
        authorName: 'Dr. Elif Şahin',
        publishedAt: DateTime.now().subtract(const Duration(days: 15)),
        readTimeMinutes: 8,
        isFeatured: false,
        views: 278,
        likes: 31,
      ),
    ];

    await _saveBlogPosts(demoPosts);
  }
}
