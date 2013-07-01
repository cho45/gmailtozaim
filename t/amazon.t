use utf8;
use strict;
use warnings;

use Test::Base -Base;
use Test::More;
use Data::Dumper;

use WWW::Amazon::Email::Parser;

delimiters('!!!', '***');

plan tests => 1 * blocks;

my $parser = WWW::Amazon::Email::Parser->new;

run {
	my $block = shift;
	my $result = $parser->parse($block->input);
	is_deeply $result, $block->expected or note Dumper $result;
	# credit --> all
	# giftcard --> credit
};

done_testing;
__END__
!!! test
*** input

Amazon.co.jp　ご注文の発送
注文番号 999-9999999-9999999
http://www.amazon.co.jp/ref=pe_302852_34649732_tex_g

--------------------------------------------------------------------

ゆの 様

Amazon.co.jp をご利用いただき、ありがとうございます。
ご注文いただいた商品を本日、Amazon.co.jp が発送し、ご注文の処理が完了しましたので、お知らせいたします。

お届け予定日： 日曜日, 2013/06/02
配送状況は下記ページからご確認ください。
http://www.amazon.co.jp/gp/css/your-orders-access?ie=UTF8&ref=pe_302852_34649732_tex_typ
お届け先：
   ゆの
   100-0000
   ひだまり荘 201号室
   (平日の7:00-18:00は不在)

お客様の商品はヤマト宅急便でお届けいたします。お問い合わせ伝票番号は999999999999です。なお、伝票番号で配送状況を確認できるようになるまで、お時間がかかる場合があります。

====================================================================

発送の詳細：

Amazon.com Int'l Sales, Inc.の商品:

   クロレッツXPオリジナルMB 150g　 5点
   ￥ 3,280

--------------------------------------------------------------------
   小計： ￥ 3,130
   配送料および手数料： ￥ 0
   合計（税抜き）： ￥ 3,130
   消費税： ￥ 155

   合計： ￥ 3,285

   クレジットカード（Visa）でのお支払い額： ￥ 3,285

====================================================================

ご注文の詳細は、下記URLからアカウントサービスでご確認いただけます。
http://www.amazon.co.jp/gp/css/your-account-access/ref=pe_999999_99999999_tex_ho

領収書が必要な場合は、PCサイトの「アカウントサービス」内にある注文履歴画面から領収書データを表示することができますので、印刷してご利用ください（代金引換、コンビニ・ATM・ネットバンキング・電子マネー払いでお支払いの場合を除く）。領収書について詳しくは、ヘルプページをご確認ください。
http://www.amazon.co.jp/gp/help/customer/display.html?nodeId=999999&ref=pe_999999_99999999_tex_rct

返品・交換は、下記URLから返品受付センターでお手続きください。
http://www.amazon.co.jp/henpin?ref=pe_999999_99999999_tex_r

ご不明な点は、下記URLのヘルプページからカスタマーサービスまでご連絡ください。
http://www.amazon.co.jp/gp/help/customer/display.html?ie=UTF9&ref=pe_999999_99999999_tex_cs

Amazon.co.jp のまたのご利用をお待ちしております。
Amazon.co.jp
www.amazon.co.jp

--------------------------------------------------------------------

このEメールアドレスは配信専用です。このメッセージに返信しないようお願いいたします。

*** expected eval
{
	credit => 3285,
	giftcard => 0,
	items => [
		{
			name => 'クロレッツXPオリジナルMB 150g　 5点',
			amount => 3280,
			amount_giftcard => 0,
			amount_etc => 3280,
		},
		{
			name => '消費税',
			amount => 5,
		},
	],
}

!!! test
*** input
====================================================================

発送の詳細：

Amazon.com Int'l Sales, Inc.の商品:

   つづきはまた明日 (4) (バーズコミックス ガールズコレクション)    ￥ 650


Amazon.com Int'l Sales, Inc.の商品:

   伊勢神宮 (楽学ブックス)    ￥ 1,575


Amazon.com Int'l Sales, Inc.の商品:

   出雲大社 (楽学ブックス)    ￥ 1,575


Amazon.com Int'l Sales, Inc.の商品:

   関東の聖地と神社 (楽学ブックス)    ￥ 1,575


Amazon.com Int'l Sales, Inc.の商品:

   伊勢神宮と出雲大社 もっと知りたい! ニッポン最高峰の神社 (日経ホームマガジン 日経おとなのOFF)    ￥ 880

--------------------------------------------------------------------
   小計： ￥ 5,957
   配送料および手数料： ￥ 0
   合計（税抜き）： ￥ 5,957
   消費税： ￥ 298

   合計： ￥ 6,255

   クレジットカード（Visa）でのお支払い額： ￥ 2,346
   Amazonギフト券・Amazonショッピングカードでのお支払い額： ￥ 3,909
====================================================================
*** expected eval
{
  'credit' => 2346,
  'giftcard' => 3909,
  'items' => [
               {
                 'amount' => 650,
                 'amount_etc' => 242,
                 'amount_giftcard' => 408,
                 'name' => "つづきはまた明日 (4) (バーズコミックス ガールズコレクション)"
               },
               {
                 'amount' => 1575,
                 'amount_etc' => 591,
                 'amount_giftcard' => 984,
                 'name' => "伊勢神宮 (楽学ブックス)"
               },
               {
                 'amount' => 1575,
                 'amount_etc' => 591,
                 'amount_giftcard' => 984,
                 'name' => "出雲大社 (楽学ブックス)"
               },
               {
                 'amount' => 1575,
                 'amount_etc' => 591,
                 'amount_giftcard' => 984,
                 'name' => "関東の聖地と神社 (楽学ブックス)"
               },
               {
                 'amount' => 880,
                 'name' => "伊勢神宮と出雲大社 もっと知りたい! ニッポン最高峰の神社 (日経ホームマガジン 日経おとなのOFF)",
                 'amount_etc' => 331,
                 'amount_giftcard' => 549,
               }
             ]
};

!!! test
*** input
====================================================================

発送の詳細：

Amazon.com Int'l Sales, Inc.の商品:

   ひだまりスケッチ (7) (まんがタイムKRコミックス)    ￥ 860

--------------------------------------------------------------------
   小計： ￥ 819
   配送料および手数料： ￥ 0
    プロモーション: -￥ 0
   合計（税抜き）： ￥ 819
   消費税： ￥ 41

   合計： ￥ 860

   クレジットカード（Visa）でのお支払い額： ￥ 860

====================================================================
*** expected eval
{
    'credit' => 860,
    'giftcard' => 0,
    'items' => [
                 {
                   'amount' => 860,
                   'name' => "ひだまりスケッチ (7) (まんがタイムKRコミックス)",
                   'amount_etc' => 860,
                   'amount_giftcard' => 0,
                 }
               ]
  };

!!! test
*** input
====================================================================

発送の詳細：

Amazon.com Int'l Sales, Inc.の商品:

   ベッセル ビットベルト BW-15    ￥ 1,653


Amazon.com Int'l Sales, Inc.の商品:

   クロレッツXPオリジナルMB 150g　 3点
   ￥ 1,794


Amazon.com Int'l Sales, Inc.の商品:

   ＴＲＵＳＣＯ　マジックバンド結束テープ　両面　黒　１０ｍｍ×１．５ｍ    ￥ 331

--------------------------------------------------------------------
   小計： ￥ 3,599
   配送料および手数料： ￥ 0
   合計（税抜き）： ￥ 3,599
   消費税： ￥ 179

   合計： ￥ 3,778

   クレジットカード（Visa）でのお支払い額： ￥ 3,778
====================================================================
*** expected eval
{
  'credit' => 3778,
  'giftcard' => 0,
  'items' => [
               {
                 'amount' => 1653,
                 'name' => "ベッセル ビットベルト BW-15",
                 'amount_giftcard' => 0,
                 'amount_etc' => 1653
               },
               {
                 'amount' => 1794,
                 'name' => "クロレッツXPオリジナルMB 150g　 3点",
                 'amount_giftcard' => 0,
                 'amount_etc' => 1794
               },
               {
                 'amount' => 331,
                 'name' => "ＴＲＵＳＣＯ　マジックバンド結束テープ　両面　黒　１０ｍｍ×１．５ｍ",
                 'amount_giftcard' => 0,
                 'amount_etc' => 331
               }
             ]
};

!!! test
*** input
====================================================================

発送の詳細：

WIN LIFEの商品:

   SANYO NEW eneloop 単4形4本 HR-4UTGB-4    ￥ 920
   コンディション： new

--------------------------------------------------------------------
   小計： ￥ 920
   配送料および手数料： ￥ 100

   合計： ￥ 1,020

   クレジットカード（Visa）でのお支払い額： ￥ 1,020
====================================================================
*** expected eval
{
  'credit' => 1020,
  'giftcard' => 0,
  'items' => [
               {
                 'amount' => 920,
                 'name' => "SANYO NEW eneloop 単4形4本 HR-4UTGB-4",
                 'amount_giftcard' => 0,
                 'amount_etc' => 920
               },
               {
                 'amount' => '100',
                 'amount_giftcard' => 0,
                 'amount_etc' => 100,
                 'name' => "配送料および手数料"
               }
             ]
};

!!! test
*** input

====================================================================

発送の詳細：

ビックカメラの商品:

   東芝 20形スタータ形 色評価用蛍光ランプ 昼白色 FL20SNEDL    ￥ 630
   コンディション： new

--------------------------------------------------------------------
   小計： ￥ 630
   配送料および手数料： ￥ 525
    プロモーション: -￥ 0

   合計： ￥ 1,155

   クレジットカード（Visa）でのお支払い額： ￥ 1,155

====================================================================

*** expected eval
{
  'credit' => 1155,
  'giftcard' => 0,
  'items' => [
               {
                 'amount' => 630,
                 'amount_etc' => 630,
                 'amount_giftcard' => 0,
                 'name' => "東芝 20形スタータ形 色評価用蛍光ランプ 昼白色 FL20SNEDL"
               },
               {
                 'amount' => 525,
                 'amount_etc' => 525,
                 'amount_giftcard' => 0,
                 'name' => "配送料および手数料"
               }
             ]
};

!!! test
*** input

====================================================================

発送の詳細：

Amazon.com Int'l Sales, Inc.の商品:

   iBUFFALO 【iPadmini,iPad(Retinaディスプレイ),iPhone5,iPhone4S動作確認済】 USB充電器2A...    ￥ 1,164

   PLANEX Xperia 充電&データ転送 MicroUSBケーブル ブラック (ACアダプタ/パソコン接続切替スイッチ付)BN-XPERIASB    ￥ 820

   Lexar microSDHCカード Class10 32GB [フラストレーションフリーパッケージ (FFP)] LSDMI32GBJ    ￥ 1,980

   Lexar SDHCカード Class10 UHS-1 32GB [フラストレーションフリーパッケージ (FFP)] LSD32GBJ200    ￥ 1,820

--------------------------------------------------------------------
   小計： ￥ 5,509
   配送料および手数料： ￥ 0
   プロモーション: -￥ 41
   合計（税抜き）： ￥ 5,468
   消費税： ￥ 275

   合計： ￥ 5,743

   クレジットカード（Visa）でのお支払い額： ￥ 5,743

====================================================================

*** expected eval
{
  'credit' => 5743,
  'giftcard' => 0,
  'items' => [
               {
                 'amount' => 1157,
                 'amount_etc' => 1157,
                 'amount_giftcard' => 0,
                 'name' => "iBUFFALO \x{3010}iPadmini,iPad(Retina\x{30c7}\x{30a3}\x{30b9}\x{30d7}\x{30ec}\x{30a4}),iPhone5,iPhone4S\x{52d5}\x{4f5c}\x{78ba}\x{8a8d}\x{6e08}\x{3011} USB\x{5145}\x{96fb}\x{5668}2A..."
               },
               {
                 'amount' => 814,
                 'amount_etc' => 814,
                 'amount_giftcard' => 0,
                 'name' => "PLANEX Xperia \x{5145}\x{96fb}&\x{30c7}\x{30fc}\x{30bf}\x{8ee2}\x{9001} MicroUSB\x{30b1}\x{30fc}\x{30d6}\x{30eb} \x{30d6}\x{30e9}\x{30c3}\x{30af} (AC\x{30a2}\x{30c0}\x{30d7}\x{30bf}/\x{30d1}\x{30bd}\x{30b3}\x{30f3}\x{63a5}\x{7d9a}\x{5207}\x{66ff}\x{30b9}\x{30a4}\x{30c3}\x{30c1}\x{4ed8})BN-XPERIASB"
               },
               {
                 'amount' => 1965,
                 'amount_etc' => 1965,
                 'amount_giftcard' => 0,
                 'name' => "Lexar microSDHC\x{30ab}\x{30fc}\x{30c9} Class10 32GB [\x{30d5}\x{30e9}\x{30b9}\x{30c8}\x{30ec}\x{30fc}\x{30b7}\x{30e7}\x{30f3}\x{30d5}\x{30ea}\x{30fc}\x{30d1}\x{30c3}\x{30b1}\x{30fc}\x{30b8} (FFP)] LSDMI32GBJ"
               },
               {
                 'amount' => 1807,
                 'amount_etc' => 1807,
                 'amount_giftcard' => 0,
                 'name' => "Lexar SDHC\x{30ab}\x{30fc}\x{30c9} Class10 UHS-1 32GB [\x{30d5}\x{30e9}\x{30b9}\x{30c8}\x{30ec}\x{30fc}\x{30b7}\x{30e7}\x{30f3}\x{30d5}\x{30ea}\x{30fc}\x{30d1}\x{30c3}\x{30b1}\x{30fc}\x{30b8} (FFP)] LSD32GBJ200"
               },
             ]
};

!!! test
*** input

====================================================================

発送の詳細：

Amazon.com Int'l Sales, Inc.の商品:

   ロゼット ゴマージュ 増量120g                           ￥ 364

--------------------------------------------------------------------
   小計： ￥ 347
   配送料および手数料： ￥ 0
   Promotion Applied: -￥ 36
   合計（税抜き）： ￥ 311
   消費税： ￥ 17

   合計： ￥ 328

   クレジットカード（Visa）でのお支払い額： ￥ 328

====================================================================

*** expected eval
{
  'credit' => 328,
  'giftcard' => 0,
  'items' => [
               {
                 'amount' => 328,
                 'amount_etc' => 328,
                 'amount_giftcard' => 0,
                 'name' => "ロゼット ゴマージュ 増量120g"
               }
             ]
};
