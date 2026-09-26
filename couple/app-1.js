const cfg = window.APP_CONFIG || {};
const configured = cfg.SUPABASE_URL && cfg.SUPABASE_PUBLISHABLE_KEY && !cfg.SUPABASE_URL.includes('YOUR_PROJECT_ID') && !cfg.SUPABASE_PUBLISHABLE_KEY.includes('YOUR_');
const sb = configured ? window.supabase.createClient(cfg.SUPABASE_URL, cfg.SUPABASE_PUBLISHABLE_KEY) : null;

const categoryNames={date:'デート',food:'グルメ',trip:'旅行',home:'おうち',other:'その他'};
const categoryEmoji={date:'🌷',food:'🍰',trip:'🧳',home:'🕯️',other:'✨'};
const recommendations=[
 {title:'朝からカフェでモーニング',category:'food',place:'近くのカフェ',emoji:'☕',months:[1,2,3,4,5,9,10,11,12],tags:['カフェ','朝'],desc:'いつもより少し早起きして、ゆっくり朝デート。'},
 {title:'夜景を見に行く',category:'date',place:'展望台・夜景スポット',emoji:'🌙',months:[1,2,3,10,11,12],tags:['夜景'],desc:'帰り道まで特別になる定番デート。'},
 {title:'季節の花畑へ行く',category:'date',place:'花畑・庭園',emoji:'🌸',months:[3,4,5,6,7,8,9,10],tags:['花','自然'],desc:'季節ごとの写真をふたりで残そう。'},
 {title:'温泉で1泊する',category:'trip',place:'温泉地',emoji:'♨️',months:[1,2,3,10,11,12],tags:['温泉','旅行'],desc:'何もしない時間を一緒に楽しむ小旅行。'},
 {title:'水族館でゆっくりデート',category:'date',place:'水族館',emoji:'🪼',months:[1,2,6,7,8,9,12],tags:['水族館'],desc:'雨の日や暑い日にも行きやすい。'},
 {title:'ふたりで陶芸体験',category:'date',place:'陶芸教室',emoji:'🏺',months:[1,2,3,4,5,6,9,10,11,12],tags:['体験','ものづくり'],desc:'お揃いの器を作って思い出を形に。'},
 {title:'お互いに料理を1品ずつ作る',category:'home',place:'おうち',emoji:'🍳',months:[1,2,3,4,5,6,7,8,9,10,11,12],tags:['料理','おうち'],desc:'小さなコース料理みたいにして楽しむ。'},
 {title:'一緒にお菓子作り',category:'home',place:'おうち',emoji:'🧁',months:[1,2,3,4,5,9,10,11,12],tags:['お菓子','おうち'],desc:'失敗しても写真に残せばいい思い出。'},
 {title:'ピクニックをする',category:'date',place:'大きな公園',emoji:'🧺',months:[3,4,5,9,10,11],tags:['公園','ピクニック'],desc:'好きなものを持ち寄ってのんびり。'},
 {title:'夕日を見に行く',category:'date',place:'海・展望スポット',emoji:'🌇',months:[3,4,5,6,7,8,9,10],tags:['夕日','海'],desc:'予定を詰めず、夕方だけのショートデート。'},
 {title:'食べ歩きデート',category:'food',place:'商店街・観光地',emoji:'🍡',months:[1,2,3,4,5,9,10,11,12],tags:['食べ歩き'],desc:'1人1品ずつ気になるものを選ぶ。'},
 {title:'ホテルのアフタヌーンティー',category:'food',place:'ホテルラウンジ',emoji:'🫖',months:[1,2,3,4,5,6,9,10,11,12],tags:['スイーツ'],desc:'少しおしゃれして特別な午後に。'},
 {title:'ドライブで知らない街へ',category:'trip',place:'近郊エリア',emoji:'🚗',months:[3,4,5,6,9,10,11],tags:['ドライブ','散策'],desc:'目的地を1つだけ決めて寄り道を楽しむ。'},
 {title:'一緒に写真を撮りに行く',category:'date',place:'街・公園',emoji:'📷',months:[1,2,3,4,5,6,7,8,9,10,11,12],tags:['写真'],desc:'お互いを撮り合う日を作ってみる。'},
 {title:'ふたりで映画館のレイトショー',category:'date',place:'映画館',emoji:'🎬',months:[1,2,6,7,8,12],tags:['映画'],desc:'終わったあと感想を話しながら帰る。'},
 {title:'イルミネーションを見に行く',category:'date',place:'イルミネーション会場',emoji:'✨',months:[11,12,1,2],tags:['イルミネーション'],desc:'冬だけの景色を写真に残そう。'},
 {title:'紅葉を見に行く',category:'trip',place:'紅葉スポット',emoji:'🍁',months:[10,11,12],tags:['紅葉','自然'],desc:'散歩とカフェをセットにして秋デート。'},
 {title:'花火大会へ行く',category:'date',place:'花火大会',emoji:'🎆',months:[7,8,9],tags:['花火','夏'],desc:'浴衣でも普段着でも、夏の定番思い出。'},
 {title:'海辺を散歩する',category:'date',place:'海・海岸',emoji:'🌊',months:[4,5,6,7,8,9,10],tags:['海'],desc:'夕方の涼しい時間にのんびり歩く。'},
 {title:'一緒にボードゲームをする',category:'home',place:'おうち・ボードゲームカフェ',emoji:'🎲',months:[1,2,3,4,5,6,7,8,9,10,11,12],tags:['ゲーム'],desc:'勝った人が次のデートを決めるルールも。'},
 {title:'ふたりのプレイリストを作る',category:'home',place:'おうち',emoji:'🎧',months:[1,2,3,4,5,6,7,8,9,10,11,12],tags:['音楽'],desc:'お互いに5曲ずつ追加して共有。'},
 {title:'お揃いのものを探しに行く',category:'date',place:'ショッピングエリア',emoji:'🛍️',months:[1,2,3,4,5,6,7,8,9,10,11,12],tags:['買い物'],desc:'小物なら気軽に思い出として残せる。'},
 {title:'牧場や動物園へ行く',category:'date',place:'動物園・牧場',emoji:'🐑',months:[3,4,5,9,10,11],tags:['動物'],desc:'写真がたくさん増えやすい休日デート。'},
 {title:'星を見に行く',category:'trip',place:'星空スポット',emoji:'⭐',months:[1,2,3,8,9,10,11,12],tags:['星','夜'],desc:'少し遠出して静かな夜を過ごす。'},
 {title:'ふたりで朝市へ行く',category:'food',place:'朝市・市場',emoji:'🥐',months:[3,4,5,6,9,10,11],tags:['朝','グルメ'],desc:'朝ごはんを現地で探す小さな旅。'},
 {title:'体験型ミュージアムへ行く',category:'date',place:'美術館・ミュージアム',emoji:'🎨',months:[1,2,3,6,7,8,9,12],tags:['美術館','体験'],desc:'見るだけじゃない展示なら会話も増える。'},
 {title:'お互いに手紙を書く',category:'home',place:'おうち',emoji:'💌',months:[1,2,3,4,5,6,7,8,9,10,11,12],tags:['手紙','記念日'],desc:'記念日じゃない日に渡すのもおすすめ。'},
 {title:'日帰りで知らない駅に降りる',category:'trip',place:'行ったことのない駅',emoji:'🚃',months:[3,4,5,9,10,11],tags:['電車','散策'],desc:'その場でカフェとごはんを探す即興デート。'},
 {title:'一緒にスパ・岩盤浴へ行く',category:'date',place:'スパ・温浴施設',emoji:'🫧',months:[1,2,3,6,7,8,11,12],tags:['スパ'],desc:'天気を気にせず一日ゆっくりできる。'},
 {title:'クリスマスマーケットへ行く',category:'date',place:'クリスマスマーケット',emoji:'🎄',months:[11,12],tags:['クリスマス'],desc:'冬の限定フードや雑貨を一緒に楽しむ。'}
];
