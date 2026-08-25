// LICENSE : MIT
"use strict";

// Markdown の Strong（** … ** / __ … __）を全面禁止するルール。
// AI が書く文章は太字強調を多用しがちで、乱用すると本当に重要な箇所が
// 埋もれる。強調したい語があれば、文の構造や語順で示す方針に統一する。
module.exports = function (context) {
  const { Syntax, RuleError, report } = context;
  return {
    [Syntax.Strong](node) {
      report(
        node,
        new RuleError(
          "** による強調（Markdown の Strong）は使わない。強調したい内容があるなら、語順や文の構造、見出し・箇条書きの分割で表す。"
        )
      );
    },
  };
};
