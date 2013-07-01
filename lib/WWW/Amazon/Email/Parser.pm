package WWW::Amazon::Email::Parser;

use utf8;
use strict;
use warnings;
use POSIX qw(floor);
use List::Util qw(reduce);
use Carp;

sub new {
	my ($class, %args) = @_;
	bless { %args }, $class;
}

sub parse {
	my ($self, $mail) = @_;

	if ($mail =~ m{発送の詳細：}) {
		return $self->parse_co_jp($mail);
	}

	...;
}


sub parse_co_jp ($) {
	my ($self, $mail) = @_;

	($mail) = ($mail =~ m{^====================================================================([\s\S]+)====================================================================}m);
	$mail or croak "Unknown format for parse_co_jp";

	my ($main, $etc) = split /--------------------------------------------------------------------/, $mail;
	$main && $etc or croak "Unknown format for parse_co_jp...";

	# TODO コンビニ決済
	my ($credit)   = ($etc =~ m{クレジットカード.*?でのお支払い額：\s*￥\s*([\d,]+)});
	my ($giftcard) = ($etc =~ m{Amazonギフト券・Amazonショッピングカードでのお支払い額：\s*￥\s*([\d,]+)});
	my ($fee)      = ($etc =~ m{配送料および手数料：\s*￥\s*([\d,]+)});
	my ($tax)      = ($etc =~ m{消費税：\s*￥\s*([\d,]+)});

	$credit ||= 0;
	$giftcard ||= 0;
	$fee ||= 0;
	$tax ||= 0;

	$credit =~ s/,//g;
	$giftcard =~ s/,//g;
	$fee =~ s/,//g;
	$tax =~ s/,//g;

	my $pay = $credit + $giftcard;

	my $items = [];
	my $total = 0;
	while ($main =~ m{^ +(?<name>.+?)\s*￥\s*(?<amount>[\d,]+)}gm) {
		my $name   = $+{name};
		my $amount = $+{amount} =~ s/,//gr;
		$total += $amount;
		push @$items, {
			name   => $name,
			amount => $amount,
		};
	}

	if ($fee) {
		push @$items, {
			name   => '配送料および手数料',
			amount => $fee,
		};
		$total += $fee;
	}

	my $extra = $pay - $total;

	# 特殊な例だがプロモーションなどで別途減算されることがある。その分は元の金額から減額する
	if ($extra < 0) {
		my $extra_ratio = $extra / $pay;
		for my $item (@$items) {
			my $e = floor($item->{amount} * $extra_ratio);
			$item->{amount} += $e;
			$extra -= $e;
		}
		$items->[0]->{amount} += $extra;
		$extra = 0;
	}


	# アマゾンは決済手段でギフトカードという手段を使えるため「決済手段を混ぜてつかえる」という状態になる
	# なので支払い全体からギフトカード支払い率を求め、各商品に対して「ギフトカードでの支払い額」「その他の方法での支払い額」を求める
	if ($pay) {
		my $gift_ratio = $giftcard / $pay;
		$_->{amount_giftcard} = floor($_->{amount} * $gift_ratio) for @$items;
		$items->[0]->{amount_giftcard} += $giftcard - reduce { $a + $b->{amount_giftcard} } 0, @$items;
		$_->{amount_etc} = $_->{amount} - $_->{amount_giftcard} for @$items;
	}

	# 細かいものをたくさん買うと、小計 + 消費税と、各商品のところの税込金額の合計があわなくなる
	# なので各商品分はそれぞれ表示されている税込分を計上し、最終的な請求額とあわない部分は別途消費税として余りを計上する
	# 各商品に分散して加算するという方法もあるが、明細と数値を一致させたほうが気持ちいいので別にしてある
	if ($extra > 0) {
		push @$items, {
			name   => '消費税',
			amount => $extra,
		};
	}

	{
		credit   => $credit,
		giftcard => $giftcard,
		items    => $items,
	};
}


1;
__END__
