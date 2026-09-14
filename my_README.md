## Hackathon Theme

### 演出テーマ
SF空間に投影された、不安定な人物ホログラム。

人物モデルを半透明化し、青～シアン系の発光、Fresnelによる輪郭発光、
縦方向に流れる走査線、明滅・ノイズ・グリッチを組み合わせて、
ゲーム内の通信映像や立体投影装置のような表現を目指す。

### 技術テーマ
World Space・視線方向・時間変化を利用した、
パラメータ調整可能なホログラムシェーダをHLSLで実装する。

主な要素:
- Transparent描画
- Fresnel / Rim Light
- World SpaceベースのScan Line
- 時間によるPulse
- Glitch / Noise
- Inspectorから各効果を調整可能にする

### 参考
https://atelier-aomi.hatenablog.com/entry/2025/05/18/180023#google_vignette
https://qiita.com/JunNishimura/items/24f509eded20af92aad7

## Development Plan

### Day 1 - Minimum Hologram
- SampleNPR.shaderの最初のPassを簡略化して使用する
- Transparent / Blend / ZWriteを理解して人物を半透明化
- Fresnel + Scan Line + Pulseを統合
- 人物モデルに適用して最低限のホログラムを完成させる

### Day 2 - Expression & Engineering
- Scan LineをUV依存からWorld Space依存へ変更
- Glitch / Noise表現を追加
- HDR ColorやBloomとの組み合わせを調整
- 各効果のStrength / Speed / FrequencyをProperty化
- 処理を関数化してShaderを整理する

### Day 3 - Polish
- パラメータ調整
- シーンへの配置・演出調整
- 不要な処理を削減
- Frame Debuggerで描画状態を確認
- README / 発表資料 / コメントを整理
- ビルド確認

## Priority

1. Transparent
2. Fresnel
3. Scan Line
4. Pulse
5. Glitch
6. Bloom / Scene演出