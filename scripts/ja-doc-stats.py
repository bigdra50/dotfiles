#!/usr/bin/env python3
"""文書全体を集計して初めて分かる日本語の癖を検査する。

1 文ずつ見ても違反にならず、文書を通して数えると見える 3 点を扱う。

    ending-run  同一語形の文末が続く
    style-mix   敬体と常体の混在
    metaphor    同一段落での比喩の重ね

textlint のルールは 1 文または 1 ノードを単位に評価するため、文書全体の分布を
必要とするこの 3 点は textlint 側では書けない。scripts/sembr-check.sh と同じく
scripts/md-lint.sh から呼ばれる補助チェッカーとして独立させている。

3 項目の選定は「AI の書く日本語の癖を Hooks で検査する」という記事の仕様からの
推定実装であり、元記事のコードを移植したものではない。しきい値も元記事の値では
なく、このリポジトリ (55 ファイル) と手元の技術ノート (95 ファイル) へ当てた
実測から決めている。実測値は各定数のコメントに残す。

判定対象は地の文のみ。frontmatter・コードフェンス・見出し・箇条書き・表・引用は
scripts/sembr-check.sh と同じ理由で除外し、インラインコードも落とす。

Usage:
    scripts/ja-doc-stats.py <file.md>...
    scripts/ja-doc-stats.py --mode text < input.md

終了コード: 違反ありで 1、なしで 0
"""

from __future__ import annotations

import argparse
import re
import sys
from collections import Counter
from collections.abc import Callable, Iterable, Iterator, Sequence
from dataclasses import dataclass
from pathlib import Path

POLITE = "敬体"
PLAIN = "常体"
OTHER = "その他"

# 文末の正規化キーは語形そのもの。ます / ました / ません は別扱いにする。
# 単調に聞こえるのは表層の同じ文末が続くときで、時制や否定の切り替えはむしろ
# 変化に当たる。「実行します。完了しました。動きません。」を 3 連続と数えると、
# 正常な時制の変化まで指摘してしまう。
_ENDING_RULES: tuple[tuple[str, str, str], ...] = (
    ("ませんでした", POLITE, r"ませんでした$"),
    ("ましょう", POLITE, r"まし[ょよ]う$"),
    ("ました", POLITE, r"ました$"),
    ("ません", POLITE, r"ません$"),
    ("ます", POLITE, r"ます$"),
    ("でしょう", POLITE, r"でし[ょよ]う$"),
    ("でした", POLITE, r"でした$"),
    ("です", POLITE, r"です$"),
    ("ください", POLITE, r"(?:ください|下さい)$"),
    ("である", PLAIN, r"である$"),
    ("であった", PLAIN, r"であった$"),
    ("だった", PLAIN, r"だった$"),
    ("だろう", PLAIN, r"だろう$"),
    ("なかった", PLAIN, r"なかった$"),
    ("ない", PLAIN, r"ない$"),
    ("たい", PLAIN, r"たい$"),
)

ENDING_RULES: tuple[tuple[str, str, re.Pattern[str]], ...] = tuple(
    (key, style, re.compile(pattern)) for key, style, pattern in _ENDING_RULES
)

# 規則に載らない文末は末尾 2 文字をキーにする。終止形の語尾がこの集合なら常体、
# それ以外は体言止めとして文体判定から外す。実測（150 ファイル・約 3000 文）では
# この集合に入る文末 356 件のうち体言止めは「2 つ。」の 8 件だけで、残りは動詞・
# 形容詞の終止形だった。名詞は「確認。」「済み。」「参照。」のように、この集合に
# 入らない仮名か漢字・カタカナで終わる。
PLAIN_TAIL = frozenset("うくぐすつぬぶむるいただ")
# 「2 つ。」のような助数詞の体言止め。唯一まとまった数がある取りこぼしなので除く。
COUNTER_TAIL = re.compile(r"[0-9０-９][ 　]*つ$")
# 日本語を含まない文は対象外。英語で書かれた節が「文末が連続する」等で
# 引っ掛かっても直しようがない。
JAPANESE = re.compile(r"[ぁ-んァ-ヴー一-龠]")

FINAL_PARTICLE = re.compile(r"[かねよ]$")

TERMINATORS = "。．！？!?"
CLOSERS = "」』）)】〉》"
# 引用符の内側は引用元の文体で書かれる。常体の文書がツイートや UI 文言を
# 「〜です。〜ください」と丸ごと引くのは正しい書き方であって文体の混在ではない。
# 句点の直後が閉じ括弧のときだけ弾く規則では、引用の途中にある句点
# (「〜です。危険と判断した場合は〜」) で文が切れて敬体の文が 1 つ生まれる。
# 引用の深さを数えて、閉じるまで文を切らないようにする。
QUOTE_OPEN = "「『"
QUOTE_CLOSE = "」』"

FRONTMATTER_OPEN = re.compile(r"^---[ \t]*$")
FRONTMATTER_CLOSE = re.compile(r"^(?:---|\.\.\.)[ \t]*$")
FENCE = re.compile(r"^[ \t]*(?:```|~~~)")
# 見出し・箇条書き・順序付きリスト・表・引用。地の文ではないので除外する。
BLOCK = re.compile(r"^[ \t]*(?:#|[-*+][ \t]|[0-9]+\.[ \t]|\||>)")
BLANK = re.compile(r"^[ \t]*$")
INLINE_CODE = re.compile(r"`[^`]*`")
# リンクはラベルだけ残す。URL 中の `?` を文の区切りと誤認しないため。
MD_LINK = re.compile(r"\[([^\]]*)\]\([^)]*\)")
AUTOLINK = re.compile(r"<https?://[^>]*>")
BARE_URL = re.compile(r"https?://\S+")
# 強調記号は文末判定の邪魔になるだけなので落とす。
EMPHASIS = re.compile(r"[*_~`]")

METAPHOR = re.compile(r"まるで|あたかも|かのよう[にな]|のよう[にな]")
# 「以下のように」「次のような」は指示表現であって比喩ではない。
DEICTIC = re.compile(
    r"(?:この|その|あの|どの|これ|それ|あれ|どれ|以下|以上|上記|下記|前述|後述"
    r"|次|同|同様|同じ|別|従来|旧来|本来|今|昔|通常|理想|想定)$"
)

CHECK_IDS: tuple[str, ...] = ("ending-run", "style-mix", "metaphor")

# 既定で有効にする検査。metaphor は既定 off。実測 150 ファイルで地の文に現れた
# 「〜のよう[にな]」は 8 件、うち指示表現を除いた 3 件は「SO-101 のような小型
# アーム」のような例示であって比喩ではなかった。比喩と例示を正規表現で分けられず、
# 発火したときの精度が見込めない。--checks all で明示的に有効化する。
DEFAULT_CHECKS: tuple[str, ...] = ("ending-run", "style-mix")

# 検査ごとの重大度。textlint と同じく error だけが終了コードを 1 にする。
# ending-run を warning にしたのは実測による。技術ノート 1070 ファイルで 20 件出て、
# うち複数がコードフェンスへ入れ忘れた擬似コード（「H が受理したら D は拒否する。」等）
# だった。手順やアルゴリズムの記述では「〜する。」が自然に続くため、地の文かどうかを
# 行単位では判別できない。指摘は出しつつ CI と Stop は止めない。
SEVERITY: dict[str, str] = {
    "ending-run": "warning",
    "style-mix": "error",
    "metaphor": "warning",
}

# しきい値の既定値。実測の内訳は各引数の help に書く。
DEFAULT_MAX_ENDING_RUN = 3
DEFAULT_MIX_RATIO = 0.2
DEFAULT_MIN_SENTENCES = 20
DEFAULT_METAPHOR_MAX = 1

# 少数派の文をすべて並べても直す手掛かりにならないので先頭だけ出す。
MAX_REPORTED_MIX = 5
SNIPPET_LEN = 36


@dataclass(frozen=True)
class Sentence:
    """地の文から切り出した 1 文。"""

    line: int
    # 地の文以外が挟まるまでのかたまり。空行では切れない。
    block: int
    # 空行でも切れる段落。
    paragraph: int
    text: str
    ending: str
    style: str


@dataclass(frozen=True)
class Violation:
    line: int
    check: str
    message: str


def strip_noise(line: str) -> str:
    """行から文末判定の妨げになる記法を落とす。"""
    text = INLINE_CODE.sub("", line)
    text = MD_LINK.sub(r"\1", text)
    text = AUTOLINK.sub("", text)
    text = BARE_URL.sub("", text)
    return EMPHASIS.sub("", text).strip()


def iter_prose(lines: Sequence[str]) -> Iterator[tuple[int, int, int, str]]:
    """地の文の行を (行番号, ブロック番号, 段落番号, 本文) で返す。

    段落は空行でも見出し・箇条書き・コードでも切れる。ブロックは空行では切れず、
    地の文以外が挟まったときだけ切れる。この書き方の規範は一文一行なので、
    段落は 1〜2 文しか含まないことが多く、文末の連続を段落単位で数えると
    ほぼ何も見つからない（実測: 段落あたりの文数は 1〜2 が 8 割）。
    """
    block = 0
    paragraph = 0
    in_block = False
    in_paragraph = False
    in_fence = False
    in_frontmatter = False

    for number, raw in enumerate(lines, start=1):
        if number == 1 and FRONTMATTER_OPEN.match(raw):
            in_frontmatter = True
            continue
        if in_frontmatter:
            if FRONTMATTER_CLOSE.match(raw):
                in_frontmatter = False
            continue
        if FENCE.match(raw):
            in_fence = not in_fence
            in_paragraph = False
            in_block = False
            continue
        if in_fence:
            continue
        if BLANK.match(raw):
            in_paragraph = False
            continue
        if BLOCK.match(raw):
            in_paragraph = False
            in_block = False
            continue
        if not in_paragraph:
            paragraph += 1
            in_paragraph = True
        if not in_block:
            block += 1
            in_block = True
        yield number, block, paragraph, raw


def classify(body: str) -> tuple[str, str]:
    """文末を正規化キーと文体に振り分ける。"""
    tail = body.rstrip(TERMINATORS + CLOSERS + " 　")
    # 終助詞は語形の判別を邪魔するだけなので落とす。「〜でしょうか。」を
    # 「か」で終わる文として扱うと敬体を取りこぼす。
    tail = FINAL_PARTICLE.sub("", tail)
    if not tail:
        return "", OTHER
    for key, style, pattern in ENDING_RULES:
        if pattern.search(tail):
            return key, style
    if len(tail) >= 2 and tail[-1] in PLAIN_TAIL and not COUNTER_TAIL.search(tail):
        return tail[-2:], PLAIN
    return tail[-2:], OTHER


def is_wholly_quoted(body: str) -> bool:
    """文の全体が 1 つの引用かどうか。

    「〜です。〜ください」。のように地の文を伴わない行は、文末が引用元の文体で
    決まる。書き手の文体として数えると、常体の文書が敬体の引用を 1 つ引いただけで
    文体混在として報告される。地の文を伴う「〜です」と述べた。は対象外。
    """
    trimmed = body.strip().rstrip(TERMINATORS).strip()
    if len(trimmed) < 2 or trimmed[0] not in QUOTE_OPEN:
        return False
    depth = 0
    for index, char in enumerate(trimmed):
        if char in QUOTE_OPEN:
            depth += 1
        elif char in QUOTE_CLOSE:
            depth -= 1
            # 最初の引用が閉じた位置が末尾なら、行全体がその引用。
            if depth == 0:
                return index == len(trimmed) - 1
    return False


def split_sentences(lines: Sequence[str]) -> list[Sentence]:
    """地の文を 1 文ずつに切る。段落をまたぐ文は作らない。"""
    sentences: list[Sentence] = []
    buffer = ""
    current_paragraph = 0
    # 引用の深さ。閉じ忘れの影響を段落内に閉じ込めるため段落ごとに戻す。
    quote_depth = 0

    def flush(line: int, block: int, paragraph: int) -> None:
        """句点で終わった 1 文を確定する。"""
        nonlocal buffer
        body = buffer.strip()
        buffer = ""
        # 日本語を含まない文は数えない。英文の段落まで文末統計に入ると、
        # 直しようのない指摘が出る。
        if not body or not JAPANESE.search(body):
            return
        # 引用だけの行は書き手の文体ではないので統計に入れない。
        if is_wholly_quoted(body):
            return
        ending, style = classify(body)
        if not ending:
            return
        sentences.append(Sentence(line, block, paragraph, body, ending, style))

    for number, block, paragraph, raw in iter_prose(lines):
        if paragraph != current_paragraph:
            # 段落をまたいで文を継続しない。書きかけの断片はここで捨てる。
            buffer = ""
            quote_depth = 0
            current_paragraph = paragraph
        text = strip_noise(raw)
        for index, char in enumerate(text):
            buffer += char
            if char in QUOTE_OPEN:
                quote_depth += 1
                continue
            if char in QUOTE_CLOSE:
                # 閉じ括弧が余っていても負にはしない。開き括弧を書き落とした
                # 一行のせいで、以降の段落全部が 1 文に潰れるのを避ける。
                quote_depth = max(0, quote_depth - 1)
                continue
            if char not in TERMINATORS:
                continue
            # 引用の内側の句点では文を切らない。引用元の文体を書き手の文体として
            # 数えないため。
            if quote_depth > 0:
                continue
            # 句点の直後が閉じ括弧なら引用中の文末。文はそこで終わっていない。
            following = text[index + 1 : index + 2]
            if following and following in CLOSERS:
                continue
            flush(number, block, paragraph)
    # 最後に flush しない。句点で終わらない断片（コードブロックへの導入行
    # 「以下の設定を書く:」など）は文ではないので統計に入れない。
    return sentences


def snippet(text: str) -> str:
    if len(text) <= SNIPPET_LEN:
        return text
    return text[:SNIPPET_LEN] + "…"


def _runs(
    sentences: Sequence[Sentence], scope: Callable[[Sentence], int]
) -> Iterator[list[Sentence]]:
    """同じ語形の文末が同じ範囲で続くかたまりを返す。"""
    run: list[Sentence] = []
    for sentence in sentences:
        if (
            run
            and run[-1].ending == sentence.ending
            and scope(run[-1]) == scope(sentence)
        ):
            run.append(sentence)
            continue
        if run:
            yield run
        run = [sentence]
    if run:
        yield run


def check_ending_run(sentences: Sequence[Sentence], limit: int) -> list[Violation]:
    """同じ語形の文末が続いたら指摘する。

    段落の中では limit 文、段落をまたぐ場合は limit + 1 文から数える。段落が
    変われば読み手が受ける単調さは弱まるうえ、この書き方の規範では段落が 1〜2 文
    しかないため、同じ本数で数えると段落境界をまたぐ連続ばかりが並ぶ。
    """
    longest: dict[int, list[Sentence]] = {}
    for scope, threshold in (
        (lambda s: s.paragraph, limit),
        (lambda s: s.block, limit + 1),
    ):
        for run in _runs(sentences, scope):
            if len(run) < threshold:
                continue
            line = run[-1].line
            if len(run) > len(longest.get(line, [])):
                longest[line] = run

    violations: list[Violation] = []
    for line, run in sorted(longest.items()):
        last = run[-1]
        violations.append(
            Violation(
                line,
                "ending-run",
                f"文末「{last.ending}」が {len(run)} 文続く: {snippet(last.text)}",
            )
        )
    return violations


def check_style_mix(
    sentences: Sequence[Sentence], ratio: float, min_sentences: int
) -> list[Violation]:
    """敬体と常体の分布を見て、少数派が ratio 以下なら混在として指摘する。"""
    counts = Counter(s.style for s in sentences if s.style in (POLITE, PLAIN))
    total = counts[POLITE] + counts[PLAIN]
    if total < min_sentences or not counts[POLITE] or not counts[PLAIN]:
        return []
    minority = POLITE if counts[POLITE] <= counts[PLAIN] else PLAIN
    majority = PLAIN if minority == POLITE else POLITE
    share = counts[minority] / total
    # 半々に近い文書は章ごとに文体が違う等の構成上の理由がある。少数派が
    # 十分小さいときだけ「書き漏らし」と見なす。
    if share > ratio:
        return []
    violations: list[Violation] = []
    targets = [s for s in sentences if s.style == minority]
    for sentence in targets[:MAX_REPORTED_MIX]:
        violations.append(
            Violation(
                sentence.line,
                "style-mix",
                f"文体混在: {majority} {counts[majority]} 文に対し {minority} "
                f"{counts[minority]} 文（{share:.0%}）。{minority}の文: "
                f"{snippet(sentence.text)}",
            )
        )
    return violations


def count_metaphors(text: str) -> list[str]:
    """比喩表現を数える。指示表現の「以下のように」等は除く。"""
    found: list[str] = []
    for match in METAPHOR.finditer(text):
        if match.group(0).startswith("のよう") and DEICTIC.search(
            text[: match.start()]
        ):
            continue
        found.append(match.group(0))
    return found


def check_metaphor(sentences: Sequence[Sentence], limit: int) -> list[Violation]:
    """同一段落で比喩が limit を超えて重なったら指摘する。"""
    violations: list[Violation] = []
    paragraphs: dict[int, list[tuple[Sentence, str]]] = {}
    for sentence in sentences:
        for expression in count_metaphors(sentence.text):
            paragraphs.setdefault(sentence.paragraph, []).append((sentence, expression))
    for hits in paragraphs.values():
        if len(hits) <= limit:
            continue
        sentence, _ = hits[-1]
        expressions = "」「".join(expression for _, expression in hits)
        violations.append(
            Violation(
                sentence.line,
                "metaphor",
                f"同一段落に比喩表現が {len(hits)} 件（「{expressions}」）",
            )
        )
    return violations


def inspect(
    lines: Sequence[str], checks: Sequence[str], args: argparse.Namespace
) -> list[Violation]:
    sentences = split_sentences(lines)
    violations: list[Violation] = []
    if "ending-run" in checks:
        violations += check_ending_run(sentences, args.max_ending_run)
    if "style-mix" in checks:
        violations += check_style_mix(sentences, args.mix_ratio, args.min_sentences)
    if "metaphor" in checks:
        violations += check_metaphor(sentences, args.metaphor_max)
    return sorted(violations, key=lambda v: (v.line, v.check))


def report(label: str, violations: Iterable[Violation]) -> int:
    """全件を表示し、error の件数だけを返す。warning は終了コードに影響しない。"""
    errors = 0
    for violation in violations:
        level = SEVERITY.get(violation.check, "error")
        print(
            f"{label}:{violation.line}: {level}: {violation.check}: {violation.message}"
        )
        if level == "error":
            errors += 1
    return errors


def parse_checks(value: str) -> tuple[str, ...]:
    if value == "all":
        return CHECK_IDS
    selected = tuple(name.strip() for name in value.split(",") if name.strip())
    unknown = [name for name in selected if name not in CHECK_IDS]
    if unknown:
        raise argparse.ArgumentTypeError(
            f"unknown check: {', '.join(unknown)} (available: {', '.join(CHECK_IDS)})"
        )
    return selected


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="文書全体を集計して分かる日本語の癖を検査する",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("paths", nargs="*", help="検査する Markdown ファイル")
    parser.add_argument(
        "--mode",
        choices=("files", "text"),
        default="files",
        help="text は標準入力を 1 文書として検査する",
    )
    parser.add_argument(
        "--checks",
        type=parse_checks,
        default=DEFAULT_CHECKS,
        help=f"検査する項目のカンマ区切り、または all（既定: {','.join(DEFAULT_CHECKS)}）",
    )
    parser.add_argument(
        "--max-ending-run",
        type=int,
        default=DEFAULT_MAX_ENDING_RUN,
        metavar="N",
        help="同一語形の文末が N 文続いたら指摘する（段落をまたぐ連続は N+1 文から）。"
        "既定 3 での実測は dotfiles 55 ファイル 0 件、技術ノート 95 ファイル 2 件で、"
        "2 件はどちらも「〜する。」の実在する 3 連続",
    )
    parser.add_argument(
        "--mix-ratio",
        type=float,
        default=DEFAULT_MIX_RATIO,
        metavar="R",
        help="少数派の文体がこの割合以下なら混在とみなす（既定 0.2）。実測では"
        "0.5 まで緩めても既存 150 ファイルに 1 件も出ない（文体の混在自体が無い）",
    )
    parser.add_argument(
        "--min-sentences",
        type=int,
        default=DEFAULT_MIN_SENTENCES,
        metavar="N",
        help="文体混在を判定する最小文数。短い文書は分布が偶然に左右される",
    )
    parser.add_argument(
        "--metaphor-max",
        type=int,
        default=DEFAULT_METAPHOR_MAX,
        metavar="N",
        help="同一段落で許す比喩表現の数（既定 1）。既定では metaphor 自体が off",
    )
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    checks: tuple[str, ...] = tuple(args.checks)
    found = 0  # error の件数。warning は数えない

    if args.mode == "text":
        lines = sys.stdin.read().splitlines()
        found += report("<stdin>", inspect(lines, checks, args))
        return 1 if found else 0

    for path in args.paths:
        target = Path(path)
        if not target.is_file():
            continue
        lines = target.read_text(encoding="utf-8", errors="replace").splitlines()
        found += report(path, inspect(lines, checks, args))
    return 1 if found else 0


if __name__ == "__main__":
    sys.exit(main())
