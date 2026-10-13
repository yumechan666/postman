import 'dart:math' as math;

class FriendData {
  const FriendData({
    required this.id,
    required this.name,
    required this.species,
    required this.personality,
    required this.item,
    required this.sheet,
    required this.color,
  });

  final String id;
  final String name;
  final String species;
  final String personality;
  final String item;
  final String sheet;
  final int color;
}

const friends = <FriendData>[
  FriendData(
    id: 'luna',
    name: 'Luna',
    species: 'Rabbit',
    personality: 'Restless gardener',
    item: 'carrot',
    sheet: 'npc_luna_finn_sheet-transparent.webp',
    color: 0xffd982a7,
  ),
  FriendData(
    id: 'finn',
    name: 'Finn',
    species: 'Fox',
    personality: 'Clever tinkerer',
    item: 'brass_gear',
    sheet: 'npc_luna_finn_sheet-transparent.webp',
    color: 0xffd87742,
  ),
  FriendData(
    id: 'bruno',
    name: 'Bruno',
    species: 'Bear',
    personality: 'Gentle baker',
    item: 'cookie',
    sheet: 'npc_bruno_nia_sheet-transparent.webp',
    color: 0xff9a694d,
  ),
  FriendData(
    id: 'nia',
    name: 'Nia',
    species: 'Squirrel',
    personality: 'Fast, organized collector',
    item: 'acorn',
    sheet: 'npc_bruno_nia_sheet-transparent.webp',
    color: 0xffc85a48,
  ),
  FriendData(
    id: 'oliver',
    name: 'Oliver',
    species: 'Owl',
    personality: 'Thoughtful night reader',
    item: 'star',
    sheet: 'npc_oliver_elia_sheet-transparent.webp',
    color: 0xff64628e,
  ),
  FriendData(
    id: 'elia',
    name: 'Elia',
    species: 'Deer',
    personality: 'Quiet artist and florist',
    item: 'wildflower',
    sheet: 'npc_oliver_elia_sheet-transparent.webp',
    color: 0xffb98572,
  ),
  FriendData(
    id: 'momo',
    name: 'Momo',
    species: 'Frog',
    personality: 'Cheerful musician',
    item: 'lily_pad',
    sheet: 'npc_momo_mimi_sheet-transparent.webp',
    color: 0xff5c9b70,
  ),
  FriendData(
    id: 'mimi',
    name: 'Mimi',
    species: 'Cat',
    personality: 'Curious traveler',
    item: 'shell',
    sheet: 'npc_momo_mimi_sheet-transparent.webp',
    color: 0xffa56b8d,
  ),
];

class PuzzleData {
  const PuzzleData({
    required this.prompt,
    required this.answer,
    required this.options,
    required this.hint,
    required this.item,
    required this.visualCount,
    required this.visualGroups,
  });

  final String prompt;
  final String answer;
  final List<String> options;
  final String hint;
  final String item;
  final int visualCount;
  final int visualGroups;
}

class DeliveryData {
  const DeliveryData({
    required this.friendId,
    required this.senderId,
    required this.title,
    required this.greeting,
    required this.story,
    required this.letter,
    required this.reward,
    required this.puzzle,
  });

  final String friendId;
  final String senderId;
  final String title;
  final String greeting;
  final String story;
  final String letter;
  final int reward;
  final PuzzleData puzzle;
}

class LandmarkData {
  const LandmarkData(this.frame, this.x, this.scale);
  final String frame;
  final double x;
  final double scale;
}

class PropData {
  const PropData(this.frame, this.x, this.clue);
  final String frame;
  final double x;
  final String clue;
}

class WorldData {
  const WorldData({
    required this.id,
    required this.name,
    required this.palette,
    required this.backdrop,
    required this.weather,
    required this.ambience,
    required this.landmarks,
    required this.props,
    required this.npcPositions,
    required this.deliveries,
  });

  final int id;
  final String name;
  final List<int> palette;
  final String backdrop;
  final String weather;
  final String ambience;
  final List<LandmarkData> landmarks;
  final List<PropData> props;
  final Map<String, double> npcPositions;
  final List<DeliveryData> deliveries;

  DeliveryData deliveryFor(String friendId) =>
      deliveries.firstWhere((delivery) => delivery.friendId == friendId);
}

class _WorldSpec {
  const _WorldSpec(
    this.name,
    this.palette,
    this.backdrop,
    this.weather,
    this.landmarks,
    this.ambience,
  );
  final String name;
  final List<String> palette;
  final String backdrop;
  final String weather;
  final List<String> landmarks;
  final String ambience;
}

const _specs = <_WorldSpec>[
  _WorldSpec(
    'Little Forest',
    ['bfe2dc', 'f2e4b7', '7d9b58', 'eabf69', '584332'],
    'bg_spring_forest.webp',
    'pollen',
    ['thatched_cottage', 'wood_bridge', 'pond'],
    'Tiny paths remember every pair of boots.',
  ),
  _WorldSpec(
    'Flower Meadow',
    ['bfe8e0', 'f4d7df', '72a963', 'e48ca8', '5b4639'],
    'bg_spring_forest.webp',
    'petal',
    ['flower_arch', 'windmill', 'pond'],
    'Blue flowers lean toward the next delivery.',
  ),
  _WorldSpec(
    'Mushroom Woods',
    ['7ca59a', 'd9c08f', '466c59', 'e8798f', '4c3a36'],
    'bg_spring_forest.webp',
    'spore',
    ['mushroom_cafe', 'treehouse', 'wood_bridge'],
    'The tallest red cap marks the middle path.',
  ),
  _WorldSpec(
    'Rainy Forest',
    ['718f98', 'd3cba8', '3f695b', 'f1c662', '334544'],
    'bg_rain_night.webp',
    'rain',
    ['thatched_cottage', 'wood_bridge', 'pond'],
    'Yellow umbrellas point away from deep puddles.',
  ),
  _WorldSpec(
    'Autumn Forest',
    ['d7af72', 'f0d09d', '9a5f3f', 'c95045', '513b31'],
    'bg_rain_night.webp',
    'leaf',
    ['workshop', 'flower_arch', 'treehouse'],
    'Red leaves gather beside the old oak.',
  ),
  _WorldSpec(
    'Night Forest',
    ['293b63', '8da8a2', '344e45', 'd9ce78', 'ede0bd'],
    'bg_rain_night.webp',
    'firefly',
    ['observatory', 'pond', 'treehouse'],
    'Fireflies make a dotted path after moonrise.',
  ),
  _WorldSpec(
    'Forest Village',
    ['a9c8b0', 'efd1a2', '7c8e5a', 'c66b4d', '523d35'],
    'bg_spring_forest.webp',
    'steam',
    ['fountain', 'workshop', 'thatched_cottage'],
    'The clock tower can be seen from every lane.',
  ),
  _WorldSpec(
    'Sunflower Field',
    ['9ed7df', 'f8e7a0', '7f9b4c', 'e2ad37', '5a482f'],
    'bg_spring_forest.webp',
    'pollen',
    ['windmill', 'flower_arch', 'thatched_cottage'],
    'The sunflowers face the hill mailbox.',
  ),
  _WorldSpec(
    'Riverside',
    ['91d1d0', 'dce4b6', '5c9274', 'd5a56e', '435047'],
    'bg_spring_forest.webp',
    'bubble',
    ['boathouse', 'wood_bridge', 'pond'],
    'Dragonflies circle the quiet ferry bend.',
  ),
  _WorldSpec(
    'Old Cottage',
    ['c6b6aa', 'eed5c5', '7b8b62', 'c48a79', '513f38'],
    'bg_spring_forest.webp',
    'steam',
    ['thatched_cottage', 'workshop', 'flower_arch'],
    'The greenhouse window catches the afternoon light.',
  ),
  _WorldSpec(
    'Old Station',
    ['9db2a8', 'd9c8a0', '667858', 'ad5746', '473c36'],
    'bg_rain_night.webp',
    'steam',
    ['old_station', 'workshop', 'wood_bridge'],
    'Listen for the clock that ticks a little late.',
  ),
  _WorldSpec(
    'Seaside',
    ['8fd5d3', 'f4d4c3', 'd8bd7a', 'e88383', '46545a'],
    'bg_coast_snow.webp',
    'bubble',
    ['lighthouse', 'boathouse', 'wood_bridge'],
    'Shells become smaller toward the lighthouse.',
  ),
  _WorldSpec(
    'Mountain Path',
    ['9bbac0', 'dfc79f', '667563', 'd77d4e', '414746'],
    'bg_coast_snow.webp',
    'cloud_mote',
    ['wood_bridge', 'ruin_arch', 'observatory'],
    'The brass bell hangs below the last switchback.',
  ),
  _WorldSpec(
    'Snow Forest',
    ['b9dbe1', 'eff0dc', '587766', 'c85858', '46535b'],
    'bg_coast_snow.webp',
    'snow',
    ['thatched_cottage', 'treehouse', 'wood_bridge'],
    'Berry-red scarves show against the pines.',
  ),
  _WorldSpec(
    'Frozen Lake',
    ['b7e0e4', 'd9d7ee', '8fa9a6', 'e0a55c', '4b5068'],
    'bg_coast_snow.webp',
    'snow',
    ['boathouse', 'pond', 'fountain'],
    'Lanterns mark the safe arc across the ice.',
  ),
  _WorldSpec(
    'Starry Hill',
    ['382c63', '8c74a0', '4f526a', 'e9ce74', 'f2e8ce'],
    'bg_rain_night.webp',
    'starfall',
    ['observatory', 'treehouse', 'flower_arch'],
    'Three bright stones point toward the telescope.',
  ),
  _WorldSpec(
    'Cloud Valley',
    ['b6dff0', 'f0dfd5', 'a8c5aa', 'e9aa87', '4f5965'],
    'bg_magic_castle.webp',
    'cloud_mote',
    ['windmill', 'wood_bridge', 'observatory'],
    'Wind bells ring near the floating garden.',
  ),
  _WorldSpec(
    'Rainbow Valley',
    ['a6ded7', 'ecd9ef', '83a967', 'd87baa', '50455c'],
    'bg_magic_castle.webp',
    'postal_sparkle',
    ['fountain', 'flower_arch', 'ruin_arch'],
    'Prism drops make the creek flash seven colors.',
  ),
  _WorldSpec(
    'Rose Garden',
    ['c5ddd0', 'f3dadc', '527557', 'c95f7d', '513b42'],
    'bg_magic_castle.webp',
    'petal',
    ['flower_arch', 'fountain', 'library_door'],
    'The moon-rose bed opens beside the quiet arbor.',
  ),
  _WorldSpec(
    'Magical Library',
    ['273457', 'dccaa2', '4d5771', '9b73c1', 'efe4c8'],
    'bg_magic_castle.webp',
    'rune',
    ['library_door', 'observatory', 'fountain'],
    'A loose page always floats toward the map room.',
  ),
  _WorldSpec(
    'Ancient Ruins',
    ['b7c3ac', 'd9c79f', '777858', '55a39a', '4c4539'],
    'bg_magic_castle.webp',
    'rune',
    ['ruin_arch', 'fountain', 'wood_bridge'],
    'The sundial shadow touches the vine stair.',
  ),
  _WorldSpec(
    'Golden Meadow',
    ['dbcb91', 'f4d8a2', 'a98a4b', 'dc7a55', '5a4532'],
    'bg_spring_forest.webp',
    'leaf',
    ['windmill', 'flower_arch', 'treehouse'],
    'Warm wind carries chaff toward the golden oak.',
  ),
  _WorldSpec(
    'Moon Village',
    ['273253', '8e8da9', '555879', 'e6c56d', 'efe6cf'],
    'bg_magic_castle.webp',
    'firefly',
    ['observatory', 'thatched_cottage', 'fountain'],
    'Moon moths gather along the lantern canal.',
  ),
  _WorldSpec(
    'Dream Forest',
    ['b7a7d3', 'cce1ce', '8a9a7e', 'e5a6a4', '4d4861'],
    'bg_magic_castle.webp',
    'starfall',
    ['mushroom_cafe', 'pond', 'library_door'],
    'The reflection path is truer than the floating one.',
  ),
  _WorldSpec(
    "Postmaster's Castle",
    ['e6c99c', 'f1e4ca', '8e9b70', 'b64b49', '503b35'],
    'bg_magic_castle.webp',
    'postal_sparkle',
    ['castle_gate', 'library_door', 'fountain'],
    'Eight glowing stamps lead from the gate to dawn.',
  ),
];

const _specIdNames = <String>[
  'Hutan Kecil',
  'Padang Bunga',
  'Hutan Jamur',
  'Hutan Hujan',
  'Hutan Gugur',
  'Hutan Malam',
  'Desa Hutan',
  'Ladang Bunga Matahari',
  'Tepi Sungai',
  'Gubuk Tua',
  'Stasiun Tua',
  'Tepi Pantai',
  'Jalan Gunung',
  'Hutan Salju',
  'Danau Beku',
  'Bukit Berbintang',
  'Lembah Awan',
  'Lembah Pelangi',
  'Taman Mawar',
  'Perpustakaan Ajaib',
  'Reruntuhan Kuno',
  'Padang Emas',
  'Desa Bulan',
  'Hutan Mimpi',
  'Kastil Pemimpin Pos',
];

const _specIdAmbience = <String>[
  'Jalan-jalan kecil mengingat setiap pasang sepatu bot.',
  'Bunga biru condong ke arah kiriman berikutnya.',
  'Topi merah tertinggi menandai jalan tengah.',
  'Payung kuning menunjuk menjauhi genangan dalam.',
  'Daun merah berkumpul di samping pohon oak tua.',
  'Kunang-kunang membuat jalan bertitik setelah bulan terbit.',
  'Menara jam terlihat dari setiap lorong.',
  'Bunga matahari menghadap kotak surat di bukit.',
  'Capung berputar di tikungan feri yang tenang.',
  'Jendela rumah kaca menangkap cahaya sore.',
  'Dengarkan jam yang berdetak agak terlambat.',
  'Cangkang semakin kecil mendekati mercusuar.',
  'Lonceng kuningan tergantung di bawah tikungan terakhir.',
  'Syal merah ceri mencolok di antara pohon pinus.',
  'Lentera menandai lengkungan aman melintasi es.',
  'Tiga batu terang menunjuk ke arah teleskop.',
  'Lonceng angin berdentang dekat taman terapung.',
  'Tetesan prisma membuat aliran sungai berkilau tujuh warna.',
  'Beds of moon-roses mekar di samping pergola yang tenang.',
  'Sehelai halaman lepas selalu melayang ke ruang peta.',
  'Bayangan jam matahari menyentuh tangga tanaman merambat.',
  'Angin hangat membawa sekam ke arah oak emas.',
  'Ngengat bulan berkumpul di sepanjang kanal lentera.',
  'Jalan pantulan lebih nyata daripada yang melayang.',
  'Delapan perangko bercahaya memimpin dari gerbang ke fajar.',
];

const _npcX = <double>[690, 1080, 1510, 2010, 2560, 3150, 3780, 4440];
const _landmarkX = <double>[420, 1120, 1970, 2870, 3820];
const _propFrames = <String>[
  'signpost',
  'bench',
  'lamp',
  'mailbox',
  'basket',
  'crate',
  'clock',
  'book_stack',
  'mushroom_cluster',
  'flower_patch',
  'rock_stack',
  'telescope',
  'snow_pine',
  'sunflower',
  'rose_bush',
  'parcel_cart',
];

int _color(String value) => 0xff000000 | int.parse(value, radix: 16);

List<T> _rotate<T>(List<T> values, int amount) => List<T>.generate(
  values.length,
  (index) => values[(index + amount) % values.length],
);

final Map<String, List<List<String>>> storyStages = {
  'luna': [
    [
      'Luna is turning one borrowed flowerbed into a garden for everyone.',
      'She is learning that rare seeds grow better when Elia helps choose their place.',
      'A storm scatters her labels, and the friends identify every sprout together.',
      'Her traveling seed exchange now leaves a little color in every world.',
      'The castle flowers are ready—grown from seeds each friend carried along the route.',
    ],
  ],
  'finn': [
    [
      'Finn repairs things before anyone asks, even when they were not broken.',
      "A stubborn clock teaches him that Nia's lists and Oliver's old diagrams are useful.",
      'He restores the station signal and finally signs all three helpers’ names.',
      'His little route markers make difficult paths feel welcoming instead of clever.',
      'Finn’s final marker points home in every direction, which is exactly the idea.',
    ],
  ],
  'bruno': [
    [
      'Bruno is testing a honey biscuit sturdy enough to survive a postal satchel.',
      'Weather keeps changing his recipes, so he begins collecting advice instead of ingredients.',
      'His traveling tea cart becomes the place where missed connections meet again.',
      'He saves one recipe from every stop for a cake no oven could make alone.',
      'The celebration cake tastes faintly of all twenty-five worlds—and somehow it works.',
    ],
  ],
  'nia': [
    [
      'Nia has a basket, a label, and a backup label for almost everything.',
      'One old acorn refuses to fit her perfect catalog because it is a memory, not a specimen.',
      "She starts recording the stories attached to objects, including Finn's repaired clock.",
      'Her portable archive becomes less tidy and much more worth opening.',
      'Nia arranges the delivered letters as a journey, leaving one empty page for what comes next.',
    ],
  ],
  'oliver': [
    [
      'Oliver discovers that a page is missing from the oldest forest postal atlas.',
      'Clues in station clocks and shoreline stars suggest the page was used as a route map.',
      'The library and ruins reveal a path that only appears when eight stories overlap.',
      'He stops searching alone and lets every friend’s memory fill one missing piece.',
      'The recovered route leads to the castle, but Oliver says the real map is the company.',
    ],
  ],
  'elia': [
    [
      'Elia paints the forest in small studies, never quite ready to call one finished.',
      'Luna trades her a seed for a sketch, and both decide the imperfect exchange is better.',
      'Changing light teaches her to keep the marks that show where a picture began.',
      "She gathers colors from Mimi's travels and sounds from Momo's songs.",
      "Her castle mural leaves a clear patch where tomorrow's weather can add itself.",
    ],
  ],
  'momo': [
    [
      'Momo is collecting the sound of each place, beginning with one excellent pond plop.',
      'Far from water, he worries his music has lost its voice until Mimi hums along.',
      'Their unlikely duet grows from rain, train steam, shells, bells, and quiet pauses.',
      'Momo learns that silence is not an empty measure; it is room for a friend.',
      'The forest finale begins with one pond plop and ends with everyone joining in.',
    ],
  ],
  'mimi': [
    [
      'Mimi writes fearless travel notes and quietly keeps every reply in her cape pocket.',
      'A seaside letter admits that exciting places can still feel lonely after sunset.',
      'She and Momo turn homesickness into a tune they can carry anywhere.',
      'Mimi realizes home is not the place she stopped traveling—it is who expects her letters.',
      'Her final invitation gathers every friend at the castle before dawn.',
    ],
  ],
};

const _itemNamesId = <String, String>{
  'carrot': 'wortel',
  'brass_gear': 'gir kuningan',
  'cookie': 'kue',
  'acorn': 'biji ek',
  'star': 'bintang',
  'wildflower': 'bunga liar',
  'lily_pad': 'daun teratai',
  'shell': 'cangkang',
};

const _landmarkNamesId = <String, String>{
  'thatched_cottage': 'gubuk beratap alang-alang',
  'wood_bridge': 'jembatan kayu',
  'pond': 'kolam',
  'flower_arch': 'lengkungan bunga',
  'windmill': 'kincir angin',
  'mushroom_cafe': 'kafe jamur',
  'treehouse': 'rumah pohon',
  'workshop': 'bengkel',
  'observatory': 'balai pengamatan',
  'fountain': 'air mancur',
  'boathouse': 'rumah perahu',
  'old_station': 'stasiun tua',
  'lighthouse': 'mercusuar',
  'ruin_arch': 'lengkungan reruntuhan',
  'library_door': 'pintu perpustakaan',
  'castle_gate': 'gerbang istana',
};

const _propNamesId = <String, String>{
  'signpost': 'tanda penunjuk',
  'bench': 'bangku',
  'lamp': 'lentera',
  'mailbox': 'kotak surat',
  'basket': 'keranjang',
  'crate': 'peti',
  'clock': 'jam',
  'book_stack': 'tumpukan buku',
  'mushroom_cluster': 'kelompok jamur',
  'flower_patch': 'rumpun bunga',
  'rock_stack': 'tumpukan batu',
  'telescope': 'teropong',
  'snow_pine': 'pinus salju',
  'sunflower': 'bunga matahari',
  'rose_bush': 'semak mawar',
  'parcel_cart': 'kereta paket',
};

const _friendSpeciesId = <String, String>{
  'luna': 'Kelinci',
  'finn': 'Rubah',
  'bruno': 'Beruang',
  'nia': 'Tupai',
  'oliver': 'Burung Hantu',
  'elia': 'Rusa',
  'momo': 'Katak',
  'mimi': 'Kucing',
};

const _friendPersonalityId = <String, String>{
  'luna': 'Pecinta kebun yang gelisah',
  'finn': 'Tukang reparasi yang cerdik',
  'bruno': 'Pembuat roti yang lembut',
  'nia': 'Kolektor cepat dan teratur',
  'oliver': 'Pembaca malam yang bijaksana',
  'elia': 'Seniman dan florist yang tenang',
  'momo': 'Musisi ceria',
  'mimi': 'Petualang penasaran',
};

const Map<String, List<List<String>>> storyStagesId = <String, List<List<String>>>{
  'luna': [
    [
      'Luna mengubah satu bedeng bunga pinjaman menjadi kebun untuk semua orang.',
      'Ia belajar bahwa benih langka tumbuh lebih baik saat Elia membantu memilih tempatnya.',
      'Badai menerbangkan label-labelnya, dan teman-teman membedakan setiap tunas bersama-sama.',
      'Pertukaran benih kelilingnya kini meninggalkan sedikit warna di setiap dunia.',
      'Bunga istana sudah siap—ditumbuhkan dari benih yang dibawa setiap teman sepanjang rute.',
    ],
  ],
  'finn': [
    [
      'Finn memperbaiki barang sebelum diminta, bahkan yang tidak rusak.',
      'Sebuah jam keras kepala mengajarinya bahwa daftar Nia dan diagram lama Oliver sangat berguna.',
      'Ia memulihkan sinyal stasiun dan akhirnya menulis nama ketiga penolong.',
      'Penanda rute kecilnya membuat jalan sulit terasa ramah, bukan sekadar pintar.',
      'Penanda terakhir Finn menunjuk ke rumah ke segala arah, dan itulah maksudnya.',
    ],
  ],
  'bruno': [
    [
      'Bruno menguji biskuit madu yang cukup kuat bertahan di dalam pelana pos.',
      'Cuaca terus mengubah resepnya, maka ia mulai mengumpulkan saran daripada bahan.',
      'Kereta teh kelilingnya menjadi tempat pertemuan kembali bagi yang terlewat.',
      'Ia menyimpan satu resep dari setiap persinggahan untuk kue yang tak bisa dibuat oven sendiri.',
      'Kue perayaannya terasa sedikit seperti ke-25 dunia—dan entah bagaimana berhasil.',
    ],
  ],
  'nia': [
    [
      'Nia punya keranjang, label, dan label cadangan untuk hampir segalanya.',
      'Satu biji ek tua tak mau masuk katalognya yang sempurna karena itu kenangan, bukan spesimen.',
      'Ia mulai mencatat kisah yang melekat pada benda, termasuk jam reparasi Finn.',
      'Arsip portabelnya jadi kurang rapi tapi jauh lebih layak dibuka.',
      'Nia menyusun surat yang terkirim sebagai perjalanan, menyisakan satu halaman kosong untuk lanjutan.',
    ],
  ],
  'oliver': [
    [
      'Oliver menemukan satu halaman hilang dari atlas pos hutan tertua.',
      'Petunjuk pada jam stasiun dan bintang pesisir menunjukkan halaman itu dipakai sebagai peta rute.',
      'Perpustakaan dan reruntuhan memperlihatkan jalan yang muncul saat delapan kisah berimpit.',
      'Ia berhenti mencari sendirian dan membiarkan kenangan tiap teman mengisi kepingan yang hilang.',
      'Rute yang ditemukan mengarah ke istana, tapi Oliver bilang peta sejatinya adalah kebersamaan.',
    ],
  ],
  'elia': [
    [
      'Elia melukis hutan dalam sketsa kecil, tak pernah benar-benar siap menyebut satu karya selesai.',
      'Luna menukar benih dengan sketsanya, dan keduanya sepakat tukar-menukar yang tak sempurna lebih baik.',
      'Cahaya yang berubah mengajarinya menyimpan tanda di mana sebuah lukisan bermula.',
      'Ia mengumpulkan warna dari perjalanan Mimi dan suara dari lagu Momo.',
      'Mural istananya menyisakan bagian kosong tempat cuaca esok bisa menambahkan diri.',
    ],
  ],
  'momo': [
    [
      'Momo mengumpulkan suara tiap tempat, bermula dari satu plup kolam yang sempurna.',
      'Jauh dari air, ia khawatir musiknya kehilangan suara hingga Mimi ikut bersenandung.',
      'Duet tak terduga mereka tumbuh dari hujan, uap kereta, cangkang, lonceng, dan jeda hening.',
      'Momo belajar bahwa diam bukan birama kosong; itu ruang untuk seorang teman.',
      'Finale hutan bermula dari satu plup kolam dan berakhir dengan semua ikut bernyanyi.',
    ],
  ],
  'mimi': [
    [
      'Mimi menulis catatan perjalanan tanpa takut dan diam-diam menyimpan setiap balasan di saku jubahnya.',
      'Sebuah surat pesisir mengakui tempat seru tetap terasa sepi setelah matahari terbenam.',
      'Ia dan Momo mengubah rindu kampung hutan jadi lagu yang bisa dibawa ke mana saja.',
      'Mimi sadar rumah bukan tempat ia berhenti bepergian—melainkan siapa yang menanti suratnya.',
      'Undangan terakhirnya mengumpulkan semua teman di istana sebelum fajar.',
    ],
  ],
};

String _itemName(String item, String lang) =>
    lang == 'id' ? _itemNamesId[item] ?? item.replaceAll('_', ' ') : item.replaceAll('_', ' ');

String propName(String frame, String lang) =>
    lang == 'id' ? _propNamesId[frame] ?? frame.replaceAll('_', ' ') : frame.replaceAll('_', ' ');

String friendSpecies(FriendData friend, String lang) =>
    lang == 'id' ? _friendSpeciesId[friend.id]! : friend.species;

String friendPersonality(FriendData friend, String lang) =>
    lang == 'id' ? _friendPersonalityId[friend.id]! : friend.personality;

int _hash(int seed) => ((seed * 9301 + 49297) % 233280).abs();

List<String> _shuffled(List<String> values, int seed) {
  final result = [...values];
  int stableHash(String value) =>
      value.codeUnits.fold(0, (sum, unit) => sum * 31 + unit);
  result.sort(
    (a, b) => _hash(
      seed + stableHash(a) * 11,
    ).compareTo(_hash(seed + stableHash(b) * 11)),
  );
  return result;
}

List<String> _numericOptions(int answer, int seed) {
  final delta = 2 + seed % 4;
  final values = <int>{
    answer,
    answer + 1,
    math.max(0, answer - 1),
    answer + delta,
  };
  while (values.length < 4) {
    values.add(answer + values.length + delta);
  }
  return _shuffled(values.map((value) => '$value').toList(), seed);
}

PuzzleData makePuzzle(
  int level,
  int friendIndex,
  String item,
  String lang, [
  int variant = 0,
]) {
  final id = lang == 'id';
  final v = variant;
  final seed = level * 31 + friendIndex * 7 + v * 911;
  final a = 2 + ((level + friendIndex * 2 + v * 3) % 8);
  final b = 1 + ((level * 2 + friendIndex + v * 5) % 7);
  var answer = 0;
  var promptEn = '';
  var promptId = '';
  var hintEn = '';
  var hintId = '';
  var options = <String>[];
  var visualCount = math.min(a, 8);
  var visualGroups = 1;
  final itemLabel = _itemName(item, lang);

  if (level <= 2) {
    final plus = (level + friendIndex + v).isEven;
    answer = plus ? a + b : (a > b ? a - b : b - a);
    promptEn = plus
        ? '$a ${itemLabel}s arrive, then $b more. How many?'
        : '${math.max(a, b)} ${itemLabel}s are ready. ${math.min(a, b)} are used. How many remain?';
    promptId = plus
        ? '$a $itemLabel datang, lalu $b lagi. Berapa jumlahnya?'
        : '${math.max(a, b)} $itemLabel sudah siap. ${math.min(a, b)} dipakai. Berapa yang tersisa?';
    hintEn = plus ? 'Count on $b steps from $a.' : 'Take away ${math.min(a, b)} from ${math.max(a, b)}.';
    hintId = plus ? 'Hitung $b langkah dari $a.' : 'Kurangi ${math.max(a, b)} sebanyak ${math.min(a, b)}.';
  } else if (level <= 4) {
    final groups = 2 + (friendIndex + v) % 4;
    final each = 2 + ((level + friendIndex + v) % 4);
    if ((friendIndex + v).isEven) {
      answer = groups * each;
      promptEn = '$groups little baskets hold $each ${itemLabel}s each. How many altogether?';
      promptId = '$groups keranjang kecil berisi $each $itemLabel masing-masing. Berapa seluruhnya?';
      hintEn = 'Add $each, $groups times.';
      hintId = 'Jumlahkan $each, sebanyak $groups kali.';
    } else {
      answer = each;
      promptEn = '${groups * each} ${itemLabel}s are shared equally between $groups baskets. How many in each?';
      promptId = '${groups * each} $itemLabel dibagi rata ke $groups keranjang. Berapa di tiap keranjang?';
      hintEn = 'Split ${groups * each} into $groups equal groups.';
      hintId = 'Bagi ${groups * each} menjadi $groups kelompok sama.';
    }
    visualCount = each;
    visualGroups = groups;
  } else if (level <= 6) {
    answer = (a + b) * 2;
    promptEn = 'Two parcels each need $a large and $b small ${itemLabel}s. How many pieces?';
    promptId = 'Dua paket masing-masing butuh $a $itemLabel besar dan $b $itemLabel kecil. Berapa banyak benda?';
    hintEn = 'First find $a + $b, then double it.';
    hintId = 'Cari dulu $a + $b, lalu kalikan dua.';
  } else if (level <= 8) {
    answer = a + b;
    promptEn = 'The label says □ − $b = $a. Which number belongs in the empty stamp?';
    promptId = 'Labelnya berbunyi □ − $b = $a. Angka apa yang mengisi perangko kosong?';
    hintEn = 'Undo subtraction by adding $a and $b.';
    hintId = 'Batalkan pengurangan dengan menjumlahkan $a dan $b.';
  } else if (level <= 10) {
    final packed = 3 + (friendIndex + v) % 5;
    final extra = 2 + (level + v) % 4;
    answer = packed * 2 + extra;
    promptEn = '${friends[friendIndex].name} packed two rows of $packed ${itemLabel}s and found $extra more by the path. How many now?';
    promptId = '${friends[friendIndex].name} menyusun dua baris berisi $packed $itemLabel dan menemukan $extra lagi di jalan. Berapa sekarang?';
    hintEn = 'Two equal rows make ${packed * 2}; then add $extra.';
    hintId = 'Dua baris sama berisi ${packed * 2}; lalu tambah $extra.';
  } else if (level == 11) {
    final step = 2 + (friendIndex + v) % 4;
    answer = a + step * 3;
    promptEn = 'Continue the route marks: $a, ${a + step}, ${a + step * 2}, □';
    promptId = 'Lanjutkan tanda rute: $a, ${a + step}, ${a + step * 2}, □';
    hintEn = 'Each mark grows by $step.';
    hintId = 'Setiap tanda bertambah $step.';
  } else if (level == 12) {
    final left = a * b;
    final right = left + ((friendIndex % 3) - 1) * 2;
    final relation = left == right ? '=' : (left > right ? '>' : '<');
    promptEn = 'Compare the two tide baskets: $left □ $right';
    promptId = 'Bandingkan dua keranjang pasang: $left □ $right';
    hintEn = 'The open side points toward the larger amount.';
    hintId = 'Sisi terbuka menunjuk ke jumlah yang lebih besar.';
    options = _shuffled(['>', '<', '='], seed);
    return PuzzleData(
      prompt: id ? promptId : promptEn,
      answer: relation,
      options: options,
      hint: id ? hintId : hintEn,
      item: item,
      visualCount: visualCount,
      visualGroups: visualGroups,
    );
  } else if (level <= 14) {
    final groups = 6 + (level - 13) * 2 + (friendIndex + v) % 4;
    final each = 4 + (friendIndex + v) % 5;
    if ((friendIndex + v).isEven) {
      answer = groups * each;
      promptEn = '$groups trail bundles each carry $each ${itemLabel}s. Find the full load.';
      promptId = '$groups ikatan jejak masing-masing membawa $each $itemLabel. Berapa muatan penuh?';
      hintEn = 'Multiply $groups by $each; split $groups into ten and the rest if helpful.';
      hintId = 'Kalikan $groups dengan $each; bagi $groups jadi sepuluh dan sisanya bila perlu.';
    } else if (level == 14) {
      final remainder = 1 + (friendIndex + v) % 3;
      final textAnswer = '$each r $remainder';
      promptEn = '${groups * each + remainder} ${itemLabel}s are shared among $groups snow baskets. How many per basket, and how many remain?';
      promptId = '${groups * each + remainder} $itemLabel dibagi ke $groups keranjang salju. Berapa per keranjang, dan berapa sisa?';
      hintEn = '$groups × $each uses ${groups * each}; compare that with the full amount.';
      hintId = '$groups × $each memakai ${groups * each}; bandingkan dengan jumlah penuh.';
      options = _shuffled([
        textAnswer,
        '${each + 1} r 0',
        '$each r ${remainder + 1}',
        '${each - 1} r $remainder',
      ], seed);
      return PuzzleData(
        prompt: id ? promptId : promptEn,
        answer: textAnswer,
        options: options,
        hint: id ? hintId : hintEn,
        item: item,
        visualCount: each,
        visualGroups: groups,
      );
    } else {
      answer = each;
      promptEn = '${groups * each} trail marks are split evenly across $groups signposts. How many marks on each?';
      promptId = '${groups * each} tanda jejak dibagi rata ke $groups tiang penunjuk. Berapa tanda di tiap tiang?';
      hintEn = 'Use division: ${groups * each} ÷ $groups.';
      hintId = 'Pakai pembagian: ${groups * each} ÷ $groups.';
    }
  } else if (level == 15) {
    answer = ((a * b + 12) / 2).ceil();
    promptEn = 'Pack $a groups of $b, add 12 lantern tags, then share the total as evenly as possible between 2 sleds. How many on the fuller sled?';
    promptId = 'Kemas $a kelompok berisi $b, tambah 12 gantungan lentera, lalu bagi total sedekat mungkin ke 2 kereta luncur. Berapa di kereta yang lebih penuh?';
    hintEn = 'Multiply, add 12, then divide by 2. If one remains, the fuller sled gets it.';
    hintId = 'Kalikan, tambah 12, lalu bagi dua. Bila sisa satu, kereta lebih penuh yang mendapatnya.';
  } else if (level == 16) {
    const fractions = [
      ['1/2', '2/4'],
      ['1/3', '2/6'],
      ['3/4', '6/8'],
      ['2/5', '4/10'],
    ];
    final pair = fractions[(friendIndex + v) % fractions.length];
    final textAnswer = pair[1];
    promptEn = 'Which fraction covers the same part of the star map as ${pair[0]}?';
    promptId = 'Pecahan mana yang menutupi bagian peta bintang yang sama dengan ${pair[0]}?';
    hintEn = 'Multiply the top and bottom by the same number.';
    hintId = 'Kalikan pembilang dan penyebut dengan angka yang sama.';
    options = _shuffled([textAnswer, '1/4', '3/5', '2/3'], seed);
    return PuzzleData(
      prompt: id ? promptId : promptEn,
      answer: textAnswer,
      options: options,
      hint: id ? hintId : hintEn,
      item: item,
      visualCount: visualCount,
      visualGroups: visualGroups,
    );
  } else if (level == 17) {
    const percents = [25, 50, 75, 20];
    final percent = percents[(friendIndex + v) % percents.length];
    final total = percent == 20 ? 15 : 12;
    answer = total * percent ~/ 100;
    final partEn = percent == 25
        ? 'one quarter'
        : percent == 50
        ? 'one half'
        : percent == 75
        ? 'three quarters'
        : 'one fifth';
    final partId = percent == 25
        ? 'seperempat'
        : percent == 50
        ? 'setengah'
        : percent == 75
        ? 'tiga perempat'
        : 'seperlima';
    promptEn = '$percent% of $total cloud ribbons are peach. How many peach ribbons?';
    promptId = '$percent% dari $total pita awan berwarna persik. Berapa pita persik?';
    hintEn = '$percent% is $partEn of the set.';
    hintId = '$percent% adalah $partId dari kumpulan.';
  } else if (level == 18) {
    final scale = 2 + (friendIndex + v) % 3;
    answer = 3 * scale;
    promptEn = 'The color mix uses 2 blue drops for every 3 gold drops. With ${2 * scale} blue drops, how many gold drops?';
    promptId = 'Campuran warna memakai 2 tetes biru untuk tiap 3 tetes emas. Dengan ${2 * scale} tetes biru, berapa tetes emas?';
    hintEn = 'The blue amount grew by ×$scale, so grow the gold amount the same way.';
    hintId = 'Jumlah biru bertambah ×$scale, maka tambah jumlah emas dengan cara sama.';
  } else if (level == 19) {
    answer = a + b + 2;
    promptEn = 'A rose row must be longer than ${a + b}, even, and less than ${a + b + 5}. Which length fits?';
    promptId = 'Satu baris mawar harus lebih panjang dari ${a + b}, genap, dan kurang dari ${a + b + 5}. Panjang mana yang cocok?';
    if (answer.isOdd) answer++;
    hintEn = 'Check the range first, then keep only the even number.';
    hintId = 'Periksa rentangnya dulu, lalu ambil hanya angka genap.';
  } else if (level <= 22) {
    final shelves = 3 + (friendIndex + v) % 4;
    final each = 5 + (level + v) % 5;
    final borrowed = 2 + (friendIndex + v) % 3;
    answer = shelves * each - borrowed + 4;
    promptEn = '$shelves shelves hold $each route tokens each. $borrowed are borrowed and 4 new ones arrive. How many are there after both changes?';
    promptId = '$shelves rak menyimpan $each token rute masing-masing. $borrowed dipinjam dan 4 yang baru tiba. Berapa jumlahnya setelah kedua perubahan?';
    hintEn = 'Multiply shelves × tokens, subtract $borrowed, then add 4.';
    hintId = 'Kalikan rak × token, kurangi $borrowed, lalu tambah 4.';
  } else if (level == 23) {
    answer = a * 3 + b * 2;
    promptEn = 'The moon clues show $a lanterns worth 3 marks each and $b bells worth 2. What is the combined route number?';
    promptId = 'Petunjuk bulan menunjukkan $a lentera bernilai 3 tanda masing-masing dan $b lonceng bernilai 2. Berapa angka rute gabungannya?';
    hintEn = 'Find both clue values separately, then add them.';
    hintId = 'Cari kedua nilai petunjuk secara terpisah, lalu jumlahkan.';
  } else if (level == 24) {
    final total = 16 + (friendIndex + v) * 2;
    answer = total ~/ 2 + 3;
    promptEn = 'Half of $total dream stamps wake up, then 3 more float from the mirror grove. How many glow?';
    promptId = 'Setengah dari $total perangko mimpi terbangun, lalu 3 lagi melayang dari hutan cermin. Berapa yang bersinar?';
    hintEn = 'Find one half first; only then add 3.';
    hintId = 'Cari setengahnya dulu; baru tambah 3.';
  } else {
    switch (friendIndex % 4) {
      case 0:
        answer = (a + b) * 4;
        promptEn = 'Four castle wings each need $a red and $b gold stamps. How many stamps open the great mailbox?';
        promptId = 'Empat sayap istana masing-masing butuh $a perangko merah dan $b perangko emas. Berapa perangko membuka kotak surat besar?';
        hintEn = "Add one wing's stamps, then multiply by 4.";
        hintId = 'Jumlahkan perangko satu sayap, lalu kalikan 4.';
      case 1:
        final textAnswer = '${3 + friendIndex + v}/8';
        promptEn = 'Eight friends raise their lanterns. ${3 + friendIndex + v} glow gold. What fraction glow gold?';
        promptId = 'Delapan teman mengangkat lentera. ${3 + friendIndex + v} bersinar emas. Pecahan apa yang bersinar emas?';
        hintEn = 'The part is glowing lanterns; the whole is all 8 lanterns.';
        hintId = 'Bagiannya adalah lentera yang bersinar; keseluruhannya adalah 8 lentera.';
        options = _shuffled([
          textAnswer,
          '${2 + friendIndex + v}/8',
          '${3 + friendIndex + v}/7',
          '1/2',
        ], seed);
        return PuzzleData(
          prompt: id ? promptId : promptEn,
          answer: textAnswer,
          options: options,
          hint: id ? hintId : hintEn,
          item: item,
          visualCount: visualCount,
          visualGroups: visualGroups,
        );
      case 2:
        answer = a * b - 5;
        promptEn = 'The final route has $a arches with $b marks each, but 5 marks are already lit. How many remain?';
        promptId = 'Rute terakhir memiliki $a lengkungan dengan $b tanda masing-masing, tapi 5 tanda sudah menyala. Berapa yang tersisa?';
        hintEn = 'Multiply first, then subtract the 5 lit marks.';
        hintId = 'Kalikan dulu, lalu kurangi 5 tanda yang menyala.';
      default:
        answer = 24;
        promptEn = 'The Postmaster needs a number divisible by 3 and 4, greater than 20, but less than 28. Which seal works?';
        promptId = 'Pemimpin Pos butuh angka yang habis dibagi 3 dan 4, lebih dari 20, tapi kurang dari 28. Meterai mana yang cocok?';
        hintEn = 'Test the numbers between 20 and 28 against both 3 and 4.';
        hintId = 'Uji angka antara 20 dan 28 terhadap 3 dan 4.';
        options = _shuffled(['18', '21', '24', '28'], seed);
    }
  }

  options = _numericOptions(answer, seed);
  return PuzzleData(
    prompt: id ? promptId : promptEn,
    answer: '$answer',
    options: options,
    hint: id ? hintId : hintEn,
    item: item,
    visualCount: visualCount,
    visualGroups: visualGroups,
  );
}

WorldData worldFor(int worldId, String lang) {
  final id = lang == 'id';
  final level = worldId.clamp(1, 25);
  final spec = _specs[level - 1];
  final order = _rotate(
    friends.map((friend) => friend.id).toList(),
    (level - 1) * 3 % friends.length,
  );
  final xOrder = level == 1
      ? _npcX
      : _rotate(_npcX, (level - 1) % _npcX.length);
  final npcPositions = <String, double>{};
  for (var i = 0; i < order.length; i++) {
    npcPositions[order[i]] = xOrder[i];
  }
  final landmarks = List<LandmarkData>.generate(
    5,
    (i) => LandmarkData(
      spec.landmarks[i % spec.landmarks.length],
      _landmarkX[i],
      i.isOdd ? .42 : .5,
    ),
  );
  final props = List<PropData>.generate(10, (i) {
    final frame = _propFrames[(i + (level - 1) * 2) % _propFrames.length];
    final friendId = order[i % friends.length];
    final friend = friends.firstWhere((entry) => entry.id == friendId);
    final landmarkFrame = spec.landmarks[i % spec.landmarks.length];
    final landmarkLocal = _landmarkNamesId[landmarkFrame] ?? landmarkFrame.replaceAll('_', ' ');
    final side = npcPositions[friendId]! < 2400
        ? (id ? 'ke arah matahari terbit' : 'toward the sunrise side')
        : (id ? 'ke arah matahari terbenam' : 'toward the sunset side');
    final clue = i < 8
        ? '${friend.name} is $side, near $landmarkLocal.'
        : (id ? _specIdAmbience[level - 1] : spec.ambience);
    return PropData(frame, 360 + i * 470 + ((level * 73 + i * 31) % 120), clue);
  });
  final stage = math.min(4, (level - 1) ~/ 5);
  final deliveries = friends.asMap().entries.map((entry) {
    final index = entry.key;
    final friend = entry.value;
    final sender = friends[(index + level + 2) % friends.length];
    final landmarkFrame = spec.landmarks[index % spec.landmarks.length];
    final landmarkEn = landmarkFrame.replaceAll('_', ' ');
    final landmarkLocal = _landmarkNamesId[landmarkFrame] ?? landmarkEn;
    final finalLineEn = level == 25
        ? '${friend.name} adds one last piece to the gathering before sunrise.'
        : '${friend.name} found a new detail near the $landmarkEn worth remembering.';
    final finalLineId = level == 25
        ? '${friend.name} menambahkan satu keping terakhir untuk kumpul sebelum matahari terbit.'
        : '${friend.name} menemukan detail baru dekat $landmarkLocal yang layak diingat.';
    final finalLine = id ? finalLineId : finalLineEn;
    final stages = id ? storyStagesId[friend.id]!.first : storyStages[friend.id]!.first;
    final greetingEn = level == 1
        ? 'Oh! A letter for me? The mailbox only opens when its little number story is complete.'
        : 'You found me near the $landmarkEn. I was hoping that satchel held something familiar.';
    final greetingId = level == 1
        ? 'Oh! Surat untukku? Kotak surat hanya terbuka bila cerita angka kecilnya lengkap.'
        : 'Kau menemukanku dekat $landmarkLocal. Kukira pelana itu membawa sesuatu yang kukenal.';
    final greeting = id ? greetingId : greetingEn;
    final letterEn =
        'Dear ${friend.name}, I noticed the ${spec.name.toLowerCase()} changing around us. Keep this note until our paths cross again. — ${sender.name}';
    final letterId =
        'Hai ${friend.name}, kuperhatikan ${_specIdNames[level - 1].toLowerCase()} berubah di sekitar kita. Simpan catatan ini hingga jalan kita bertemu lagi. — ${sender.name}';
    final letter = id ? letterId : letterEn;
    final titleEn = "${sender.name}'s note from ${spec.name}";
    final titleId = 'Catatan ${sender.name} dari ${_specIdNames[level - 1]}';
    return DeliveryData(
      friendId: friend.id,
      senderId: sender.id,
      title: id ? titleId : titleEn,
      greeting: greeting,
      story: '${stages[stage]} $finalLine',
      letter: letter,
      reward: 7 + level ~/ 3,
      puzzle: makePuzzle(level, index, friend.item, lang),
    );
  }).toList();

  return WorldData(
    id: level,
    name: id ? _specIdNames[level - 1] : spec.name,
    palette: spec.palette.map(_color).toList(),
    backdrop: spec.backdrop,
    weather: spec.weather,
    ambience: id ? _specIdAmbience[level - 1] : spec.ambience,
    landmarks: landmarks,
    props: props,
    npcPositions: npcPositions,
    deliveries: deliveries,
  );
}

const playerSkins = <(String, String, String)>[
  ('forest', 'Forest Ranger', 'Green coat and leaf badge'),
  ('wizard', 'Letter Wizard', 'Violet robe and star hat'),
  ('pirate', 'Tide Pirate', 'Tricorn and treasure satchel'),
  ('royal', 'Royal Messenger', 'Crimson, ivory, and gold'),
  ('winter', 'Snow Courier', 'Warm coat and berry scarf'),
  ('autumn', 'Maple Post', 'Amber coat and leaf pin'),
  ('sakura', 'Sakura Route', 'Pink ribbon and blossoms'),
  ('moon', 'Moon Route', 'Navy coat and silver stars'),
  ('rainbow', 'Rainbow Post', 'Sky blue and bright trim'),
  ('halloween', 'Pumpkin Post', 'Cozy charcoal and orange'),
  ('robot', 'Retro Robot', 'Teal metal postal helper'),
  ('galaxy', 'Galaxy Courier', 'Cosmic indigo and cyan'),
];

const Map<String, int> skinCosts = {
  'forest': 0,
  'wizard': 15,
  'pirate': 20,
  'royal': 25,
  'winter': 15,
  'autumn': 20,
  'sakura': 25,
  'moon': 25,
  'rainbow': 30,
  'halloween': 20,
  'robot': 30,
  'galaxy': 35,
};
