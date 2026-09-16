## 公開にあたっての注意事項

> 本作品は、シリコンスタジオ株式会社のオンラインハッカソン（9/14〜9/16）内で制作したものです。使用している3DCGモデルの製作元は、シリコンスタジオ株式会社です。

ハッカソンで配布された3DCGモデルやコードは公開できないため、自作したシェーダ、マテリアル、READMEのみ公開します。

## テーマ

### 演出テーマ

SF調の不安定な人物ホログラムの作成。
人物モデルを半透明化し、青～シアン系の発光、Fresnelによる輪郭発光、縦方向に流れる走査線、明滅・ノイズ・グリッチを組み合わせて、ゲーム内の通信映像や立体投影装置のような表現を目指した。

### 技術テーマ

World Space・視線方向・時間変化を利用した、パラメータ調整可能なホログラムシェーダをHLSLで実装すること。
ハッカソン開始時点でシェーダ未経験であったため、シェーダの処理の流れや文法などを理解して、自分の力にすることを意識して取り組んだ。

## 完成したシェーダ

**動画URL：** https://youtu.be/fkl-N8qOtZc

- シェーダー：
  - [Hologram.shader](Assets/_Matsu/Shaders/Hologram.shader)
- マテリアル：
  - [M_Hologram.mat](Assets/_Matsu/Materials/M_Hologram.mat)
  - [M_Hologram_Woman.mat](Assets/_Matsu/Materials/M_Hologram_Woman.mat)
  - [M_Hologram_Woman_dark.mat](Assets/_Matsu/Materials/M_Hologram_Woman_dark.mat)

人物モデルをSF風のホログラムとして表示する、Unity URP向けのシェーダ。
半透明表示をベースに、以下の表現を組み合わせた。

- Fresnel効果による輪郭発光
- 速度や幅の異なる複数のスキャンライン
- 一定間隔で流れる強いスキャンビーム
- 頂点グリッチによる形状の乱れ
- 周期的な明滅
- 疑似乱数による不規則なRGBの色変化
- `DepthOnly`パスによる内部パーツの透過抑制

色や透明度、スキャンラインの速度・幅、Fresnel効果、明滅、色変化、グリッチなどの強さや頻度は、マテリアルから調整可能。

## 作業記録

基本イメージは、[こちらの記事](https://qiita.com/Cova8bitdot/items/d741426096c8be3ec50a)にあるような『Pokémon LEGENDS Z-A』のホログラム。

1. [半透明表現](https://atelier-aomi.hatenablog.com/entry/2025/05/18/180023#google_vignette)を実装
2. [スキャンライン](https://qiita.com/JunNishimura/items/24f509eded20af92aad7)が走る表現を実装
3. フレネル効果の実装（SampleNPRを主に参考にして実装）

   ← 手順2までで最低限それらしくなったが、立体感がなくのっぺりしていたため、AIやWebを使ってアプローチ方法を調査し、Slackでも相談<br>
   ← 調査・相談の結果、「フレネル効果」の実装を試すのが良さそうだという結論になった<br>
   → ある程度の形になってきた

4. 頂点グリッチを実装（[参考記事](https://zenn.dev/kento_o/articles/ab2b547e6f8f78)やTreeDeformを参考にし、詰まった箇所はAIに相談しながら作成）

   ← 手順3までの表現に加え、`frag`部分だけでなく`vert`にもノイズを入れたかったため、AIやWebを使ってアプローチ方法を調査して実装

5. 人物にホログラムを適用

   → 動きはそれらしくなったが、パーツが透けてごちゃつく<br>
   → AIに相談して修正を適用。ただし、描画順によって後ろのホログラムが透けたり透けなかったりする問題が残った<br>
  　補足：内部パーツを見えないようにしつつ、後ろのホログラムを常に透過させる実装は、シェーダーだけではおそらく不可能（グループ単位で描くカスタム`RendererFeature`が必要？）<br>
   → Slackで相談し、「2パスにして`DepthOnly`パスを追加する」方法を教えてもらった<br>
   → [Unity公式ドキュメント](https://docs.unity3d.com/ja/6000.0/Manual/urp/writing-shaders-urp-depth-only.html)、[参考記事](https://zenn.dev/kento_o/articles/e178dfde7632da)、AIを参考にしながら実装<br>
  　補足：別途Unity側で`Render Objects`を設定する必要があったため、AIに相談しながら設定<br>
   → 髪や服を区別できるように、明暗2種類のマテリアルを作り、Womanモデルの各パーツに適用

6. 速度や幅が異なるスキャンラインを重ね、帯の幅と比率も調整可能にすることで、さらなるホログラム感を演出。強い明るさのスキャンビームも別途重ねた。

7. 全体の明滅を実装

   → シンプルに実装したかったため、`sin`と`_Time`を用いて周期的に小さな値を乗算<br>
   → 想像以上に見た目の良い結果となった

8. 不規則な色変化を実装

   → 時間を一定間隔で区切り、疑似乱数を用いてRGB各チャンネルの変化を個別に判定

9. ポストエフェクトの微調整（CustumPostEffect）（おまけ）

   → 部屋が明るすぎるため、画面全体に水色系の色をかけ、冷たく無機質な雰囲気に統一<br>
   → 控えめなビネット（画面の端を暗くする手法らしい）を実装して追加

## メモ

- シェーダー内の`Pass`は、記述順に無条件ですべて実行されるわけではない。`LightMode`タグは、URPに対して`Pass`の用途を伝える分類
- `Render Objects`によるレンダリングの流れ：

```text
通常の不透明描画
├─ 部屋
├─ 家具
└─ 壁
    ↓
Render ObjectsがHologramレイヤーを検出
    ↓
LightMode = "DepthOnly"を呼び出す
├─ Woman全パーツのDepth
└─ 球のDepth
    ↓
通常の透明描画でLightMode = "UniversalForward"を呼び出す
    ↓
ZTest Equal
    ↓
最前面と一致するColorだけを描画
```
