## Hackathon Theme

### 演出テーマ
SF空間に投影された、不安定な人物ホログラム。
人物モデルを半透明化し、青～シアン系の発光、Fresnelによる輪郭発光、縦方向に流れる走査線、明滅・ノイズ・グリッチを組み合わせて、ゲーム内の通信映像や立体投影装置のような表現を目指す。

### 技術テーマ
World Space・視線方向・時間変化を利用した、パラメータ調整可能なホログラムシェーダをHLSLで実装する。
シェーダ未経験のため、シェーダの処理の流れや文法などを理解して、自分の力にすることを意識して取り組む。


## 作業記録（9/14~16）
ー基本的なイメージは（https://qiita.com/Cova8bitdot/items/d741426096c8be3ec50a）にあるようなポケモンZAのホログラム
1. 半透明にする（https://atelier-aomi.hatenablog.com/entry/2025/05/18/180023#google_vignette）
2. スキャンラインが走るようにする（https://qiita.com/JunNishimura/items/24f509eded20af92aad7）
3. フレネル効果の実装（SampleNPRを主に参考にして実装）
<-2までで最低限それっぽくなったが立体感がなくのっぺりしていたためAIやwebを使ってアプローチ方法を調査&Slackで相談、<-「フレネル効果」の実装を試してみるのが良さそうという結論になった
->ある程度の形になってきた
4. 頂点グリッチの実装（（https://zenn.dev/kento_o/articles/ab2b547e6f8f78）やTreeDeformを参考に一部詰まったところをAIに相談しながら作成）
<-3までに加えて、frag部分だけでなくvertにもノイズを入れる表現を試したかったため、AIやwebを使ってアプローチ方法を調査して実装
5. 人物にホログラムを適用
->動きはそれっぽいが、パーツが透けてごちゃつく
->AIに相談して修正を適用、ただし描画順によって後ろのホログラムが透けたり透けなかったりするバグが存在（内部パーツを見えないようにしたい関係で、後ろのホログラムも常に透ける実装はシェーダーだけではおそらく不可能）
->Slackで相談して「2パスにしてDepthOnlyパスを追加する」方法を教えてもらい、web（https://docs.unity3d.com/ja/6000.0/Manual/urp/writing-shaders-urp-depth-only.html）（https://zenn.dev/kento_o/articles/e178dfde7632da）やAIを参考にしながら実装（別途Unity側でRender Objectsの設定をする必要がある->AIに相談しつつ設定した）
->「Woman内部ではパーツが透けない」&「Womanと球は半透明合成される」を実現するにはグループ単位で描くカスタムRendererFeatureを作る必要があるとのこと（※AIに相談）（未実装）
->髪や服の区別がつくように、materialを明暗の2種類作ってwomanモデルの各パーツに適用した
6. スキャンラインを速度や幅を変えて重ねがけする+帯の幅やその比率を変更可能にすることで、さらなるホログラム感を演出
7. ポストエフェクトの微調整（CustumPostEffect）
->部屋が明るすぎるため、水色っぽい色を画面全体にかけて全体の雰囲気を冷たい無機質な感じに揃えた
->気持ち程度にビネットを実装して追加
8. 全体の明滅を実装
->おまけとして単純に実装したかったため、sinと_Timeを用いて周期的に小さな値を乗算
->思ったより見た目に良い結果となった



## メモ
・公開の際は自分の書いた.shaderとREADME+動画などとして公開する
・シェーダー内のPassは、書かれた順に無条件ですべて実行されるわけではない。LightModeタグは、URPに対してPassの用途を伝える分類。
・Render Objectsの編集によるレンダリングの流れは以下
    通常の不透明描画
    部屋
    家具
    壁
        ↓
    Render Objects
    Hologramレイヤーを探す
        ↓
    LightMode="DepthOnly"を呼ぶ
        ↓
    Woman全パーツのDepth
    球のDepth
        ↓
    通常の透明描画
    LightMode="UniversalForward"を呼ぶ
        ↓
    ZTest Equal
    最前面と一致するColorだけ描画