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
  });

  final String id;
  final String title;
  final String subtitle;
  final List<String> previewImages;
  final String editorial;
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
    ),
  ];
}
