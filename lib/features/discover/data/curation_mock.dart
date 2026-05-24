/// 検索タブ (= 発見・キュレーション) の静的モックデータ。
/// 本実装では `assets/curations/*.json` に置き換える想定。
class CurationHero {
  const CurationHero({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
  });

  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
}

class CurationSection {
  const CurationSection({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.previewImages,
    required this.editorial,
    required this.spots,
  });

  final String id;
  final String title;
  final String subtitle;
  final List<String> previewImages;
  final String editorial;
  final List<CurationSpot> spots;
}

/// キュレーション配下のスポット 1 件。実装段階では Places API の Place ID と
/// 1:1 に対応させて、保存時に DB に flush する。モック期はダミー Place ID で
/// editorial データだけを持つ。
class CurationSpot {
  const CurationSpot({
    required this.placeId,
    required this.name,
    required this.lat,
    required this.lng,
    required this.editorialNote,
    this.address,
    this.rating,
    this.photoUrls = const [],
  });

  final String placeId;
  final String name;
  final double lat;
  final double lng;
  final String editorialNote;
  final String? address;
  final double? rating;
  final List<String> photoUrls;
}

class CurationMock {
  CurationMock._();

  static const heroes = <CurationHero>[
    CurationHero(
      id: 'spring',
      title: '春の桜スポット',
      subtitle: '今が見頃',
      imageUrl: 'https://picsum.photos/seed/sakura-hero/1200/1200',
    ),
    CurationHero(
      id: 'rainy',
      title: '雨の日でも楽しめる',
      subtitle: '室内派の集まる場所',
      imageUrl: 'https://picsum.photos/seed/rainy-hero/1200/1200',
    ),
    CurationHero(
      id: 'night',
      title: '東京の夜景スポット',
      subtitle: '夜にしか見えない景色',
      imageUrl: 'https://picsum.photos/seed/night-hero/1200/1200',
    ),
  ];

  static const sections = <CurationSection>[
    CurationSection(
      id: 'spring',
      title: '桜の見頃に行きたい 10 選',
      subtitle: '春のおすすめ',
      previewImages: [
        'https://picsum.photos/seed/spring1/600/600',
        'https://picsum.photos/seed/spring2/600/600',
        'https://picsum.photos/seed/spring3/600/600',
        'https://picsum.photos/seed/spring4/600/600',
      ],
      editorial: '今年の桜は例年より早く咲きそう。週末は名所が混むので、平日の朝に行ける場所をまとめました。',
      spots: [
        CurationSpot(
          placeId: 'cur_spring_ueno',
          name: '上野恩賜公園',
          address: '東京都台東区上野公園 5-20',
          lat: 35.7148,
          lng: 139.7741,
          rating: 4.5,
          photoUrls: ['https://picsum.photos/seed/ueno/800/600'],
          editorialNote: '都内最大級の桜並木。朝 8 時前なら静かに花見散歩を独占できる。',
        ),
        CurationSpot(
          placeId: 'cur_spring_chidori',
          name: '千鳥ヶ淵',
          address: '東京都千代田区九段南 2',
          lat: 35.6912,
          lng: 139.7460,
          rating: 4.6,
          photoUrls: ['https://picsum.photos/seed/chidorigafuchi/800/600'],
          editorialNote: 'お堀沿いの桜と武道館の屋根が一緒に見られる、唯一無二の構図。',
        ),
        CurationSpot(
          placeId: 'cur_spring_meguro',
          name: '目黒川',
          address: '東京都目黒区中目黒',
          lat: 35.6444,
          lng: 139.6991,
          rating: 4.5,
          photoUrls: ['https://picsum.photos/seed/meguroriver/800/600'],
          editorialNote: '約 4 km 続く桜のトンネル。中目黒駅から池尻大橋方向が空いている。',
        ),
        CurationSpot(
          placeId: 'cur_spring_sumida',
          name: '隅田公園',
          address: '東京都台東区花川戸 1',
          lat: 35.7140,
          lng: 139.8024,
          rating: 4.4,
          photoUrls: ['https://picsum.photos/seed/sumidapark/800/600'],
          editorialNote: '桜と東京スカイツリーが一枚の写真に収まる名所。',
        ),
      ],
    ),
    CurationSection(
      id: 'rainy',
      title: '雨の日でも楽しい屋内スポット',
      subtitle: '雨の日 OK',
      previewImages: [
        'https://picsum.photos/seed/rainy1/600/600',
        'https://picsum.photos/seed/rainy2/600/600',
        'https://picsum.photos/seed/rainy3/600/600',
        'https://picsum.photos/seed/rainy4/600/600',
      ],
      editorial: '美術館・水族館・大型ショッピングモールなど、傘要らずで一日過ごせる場所。',
      spots: [
        CurationSpot(
          placeId: 'cur_rainy_kahaku',
          name: '国立科学博物館',
          address: '東京都台東区上野公園 7-20',
          lat: 35.7164,
          lng: 139.7763,
          rating: 4.6,
          photoUrls: ['https://picsum.photos/seed/kahaku/800/600'],
          editorialNote: '常設展だけで半日。地下 3 階の地球館は雨を忘れる空間。',
        ),
        CurationSpot(
          placeId: 'cur_rainy_sunshine',
          name: 'サンシャイン水族館',
          address: '東京都豊島区東池袋 3-1',
          lat: 35.7297,
          lng: 139.7193,
          rating: 4.2,
          photoUrls: ['https://picsum.photos/seed/sunshineaqua/800/600'],
          editorialNote: '都心とは思えない屋上水景。空飛ぶペンギンが必見。',
        ),
        CurationSpot(
          placeId: 'cur_rainy_morimuseum',
          name: '森美術館',
          address: '東京都港区六本木 6-10-1 53F',
          lat: 35.6604,
          lng: 139.7292,
          rating: 4.4,
          photoUrls: ['https://picsum.photos/seed/morimuseum/800/600'],
          editorialNote: '六本木ヒルズ最上階、現代美術と東京の景観が同時に楽しめる。',
        ),
      ],
    ),
    CurationSection(
      id: 'night',
      title: '東京 夜景の名所 8 選',
      subtitle: '夜景',
      previewImages: [
        'https://picsum.photos/seed/night1/600/600',
        'https://picsum.photos/seed/night2/600/600',
        'https://picsum.photos/seed/night3/600/600',
        'https://picsum.photos/seed/night4/600/600',
      ],
      editorial: 'デート向けの定番から、知る人ぞ知る穴場まで。日没 30 分前に到着するのがコツ。',
      spots: [
        CurationSpot(
          placeId: 'cur_night_tokyotower',
          name: '東京タワー',
          address: '東京都港区芝公園 4-2-8',
          lat: 35.6586,
          lng: 139.7454,
          rating: 4.5,
          photoUrls: ['https://picsum.photos/seed/tokyotower/800/600'],
          editorialNote: 'メインデッキ (150m) からの夜景は王道。ライトアップも美しい。',
        ),
        CurationSpot(
          placeId: 'cur_night_shibuyasky',
          name: 'SHIBUYA SKY',
          address: '東京都渋谷区渋谷 2-24-12',
          lat: 35.6586,
          lng: 139.7022,
          rating: 4.5,
          photoUrls: ['https://picsum.photos/seed/shibuyaskynight/800/600'],
          editorialNote: '渋谷スクランブル交差点の真上から見下ろす夜の街。',
        ),
        CurationSpot(
          placeId: 'cur_night_kasai',
          name: '葛西臨海公園',
          address: '東京都江戸川区臨海町 6',
          lat: 35.6395,
          lng: 139.8553,
          rating: 4.3,
          photoUrls: ['https://picsum.photos/seed/kasairinkai/800/600'],
          editorialNote: '海と都心の夜景が同時に見える穴場。観覧車も無料エリアから映える。',
        ),
      ],
    ),
    CurationSection(
      id: 'cafe',
      title: '朝のカフェ巡り',
      subtitle: 'モーニング',
      previewImages: [
        'https://picsum.photos/seed/cafe1/600/600',
        'https://picsum.photos/seed/cafe2/600/600',
        'https://picsum.photos/seed/cafe3/600/600',
        'https://picsum.photos/seed/cafe4/600/600',
      ],
      editorial: '8 時前に開く、コーヒーの香りで一日を始められるカフェ。',
      spots: [
        CurationSpot(
          placeId: 'cur_cafe_bluebottle',
          name: 'ブルーボトルコーヒー 渋谷カフェ',
          address: '東京都渋谷区道玄坂 1-2-3',
          lat: 35.6595,
          lng: 139.7004,
          rating: 4.4,
          photoUrls: ['https://picsum.photos/seed/cafebb/800/600'],
          editorialNote: '朝 8 時オープン。窓際の席で渋谷を眺めながらシングルオリジン。',
        ),
        CurationSpot(
          placeId: 'cur_cafe_fuglen',
          name: 'フグレントウキョウ',
          address: '東京都渋谷区富ヶ谷 1-16-11',
          lat: 35.6661,
          lng: 139.6883,
          rating: 4.5,
          photoUrls: ['https://picsum.photos/seed/cafefuglen/800/600'],
          editorialNote: '北欧の朝の空気感。コーヒー一杯で長居しても怒られない。',
        ),
        CurationSpot(
          placeId: 'cur_cafe_glitch',
          name: 'Glitch Coffee & Roasters',
          address: '東京都千代田区神田錦町 3-16',
          lat: 35.6938,
          lng: 139.7634,
          rating: 4.5,
          photoUrls: ['https://picsum.photos/seed/cafeglitch/800/600'],
          editorialNote: '神田の隠れ家。8:30 オープン、平日の朝は静か。',
        ),
      ],
    ),
    CurationSection(
      id: 'date',
      title: 'デートで行きたい 15 選',
      subtitle: 'デート',
      previewImages: [
        'https://picsum.photos/seed/date1/600/600',
        'https://picsum.photos/seed/date2/600/600',
        'https://picsum.photos/seed/date3/600/600',
        'https://picsum.photos/seed/date4/600/600',
      ],
      editorial: '初デートでも安心の落ち着いた雰囲気の場所を中心にセレクト。',
      spots: [
        CurationSpot(
          placeId: 'cur_date_redbrick',
          name: '横浜赤レンガ倉庫',
          address: '神奈川県横浜市中区新港 1-1',
          lat: 35.4527,
          lng: 139.6440,
          rating: 4.4,
          photoUrls: ['https://picsum.photos/seed/redbrick/800/600'],
          editorialNote: '夜は海風と建物のライトアップ。ベタだけど初デートで外さない。',
        ),
        CurationSpot(
          placeId: 'cur_date_omotesando',
          name: '表参道ヒルズ',
          address: '東京都渋谷区神宮前 4-12-10',
          lat: 35.6655,
          lng: 139.7100,
          rating: 4.2,
          photoUrls: ['https://picsum.photos/seed/omotehills/800/600'],
          editorialNote: 'ショッピングとカフェが両立。話題が途切れにくい。',
        ),
        CurationSpot(
          placeId: 'cur_date_odaiba',
          name: 'お台場海浜公園',
          address: '東京都港区台場 1-4',
          lat: 35.6304,
          lng: 139.7740,
          rating: 4.3,
          photoUrls: ['https://picsum.photos/seed/odaibapark/800/600'],
          editorialNote: 'レインボーブリッジを背景に砂浜を散歩。映え写真確実。',
        ),
      ],
    ),
  ];

  static CurationSection? sectionById(String id) {
    for (final s in sections) {
      if (s.id == id) return s;
    }
    return null;
  }
}
