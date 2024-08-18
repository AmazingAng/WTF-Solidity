# WTF Solidity 超シンプル入門: 10. Control Flow（制御フロー）

最近、Solidity の学習を再開し、詳細を確認しながら「Solidity 超シンプル入門」を作っています。これは初心者向けのガイドで、プログラミングの達人向けの教材ではありません。毎週 1〜3 レッスンのペースで更新していきます。

僕のツイッター：[@0xAA_Science](https://twitter.com/0xAA_Science)｜[@WTFAcademy\_](https://twitter.com/WTFAcademy_)

コミュニティ：[Discord](https://discord.gg/5akcruXrsk)｜[Wechat](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform?usp=sf_link)｜[公式サイト wtf.academy](https://wtf.academy)

すべてのソースコードやレッスンは github にて公開: [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

この章では、Solidityにおける制御フローを紹介して、簡単そうに見えてバグの多いプログラムである挿入ソート（`InsertionSort`）を書きます。

## Control Flow （制御フロー）

Solidityの制御フローは他のプログラミング言語に似て、主に次の構成要素を含んでいます:

1. `if-else`

```solidity
function ifElseTest(uint256 _number) public pure returns(bool){
    if(_number == 0){
	return(true);
    }else{
	return(false);
    }
}
```

2. `for loop`

```solidity
function forLoopTest() public pure returns(uint256){
    uint sum = 0;
    for(uint i = 0; i < 10; i++){
	sum += i;
    }
    return(sum);
}
```

3. `while loop`

```solidity
function whileTest() public pure returns(uint256){
    uint sum = 0;
    uint i = 0;
    while(i < 10){
	sum += i;
	i++;
    }
    return(sum);
}
```

4. `do-while loop`

```solidity
function doWhileTest() public pure returns(uint256){
    uint sum = 0;
    uint i = 0;
    do{
	sum += i;
	i++;
    }while(i < 10);
    return(sum);
}
```

5. Conditional (`ternary`) operator （条件(`ternary`:三項)演算子）

`ternary`（三項）演算子はSolidityで３つの項（オペランド）を受け入れる唯一の演算子です: 条件の後にクエスチョンマーク(`?`)が付けられており、そしてもし条件がtrueならば実行される式`x`の後にコロン(`:`)が付けられており、そして最後に条件がfalseならば実行される式`y`があります: `condition ? x : y`。

この演算子は`if-else`文の代替として頻繁に使用されます。

```solidity
// ternary/conditional operator（三項演算子/条件演算子）
function ternaryTest(uint256 x, uint256 y) public pure returns(uint256){
    // return the max of x and y（xとyの最大値を返す）
    return x >= y ? x: y; 
}
```

加えて、使用可能な`continue`（直ちに次のループに入る）と`break`（現在のループから抜ける）キーワードもある。

## `Solidity` Implementation of Insertion Sort（`Solidity`で挿入ソートを実装する）

**Note（注記）**: Solidityで挿入ソートアルゴリズムを書く90%を超える人々ははじめての試みで間違えることでしょう。

### Insertion Sort（挿入ソート）

ソートアルゴリズムは整列されていない数字を小さい数字から大きい数字に並び替える問題を解きます。例えば、`[2, 5, 3, 1]`から`[1, 2, 3, 5]`とするように。
挿入ソート(`InsertionSort`)はコンピューターサイエンスの授業でほとんどの開発者が最初に習う最も簡潔で最初のソートアルゴリズムです。`InsertionSort`のロジックは次の通りです:

1. 配列`x`の先頭から末尾まで、要素`x[i]`をその前にある要素である`x[i-1]`と比べてみましょう; もし、`x[i]`がより小さい数字であれば、その位置を入れ替えて、要素`x[i-2]`とそれを比較して、このプロセスを続けます。

挿入ソートの概略図:

![InsertionSort](https://i.pinimg.com/originals/92/b0/34/92b034385c440e08bc8551c97df0a2e3.gif)

### Python Implementation（Pythonでの実装）

それでは、挿入ソートのPythonでの実装を見てみましょう:

```python
# Python program for implementation of Insertion Sort（挿入ソートを実装するPythonのプログラミング）
def insertionSort(arr):
	for i in range(1, len(arr)):
		key = arr[i]
		j = i-1
		while j >=0 and key < arr[j] :
				arr[j+1] = arr[j]
				j -= 1
		arr[j+1] = key
    return arr
```

### Solidity Implementation (with Bug)（Solidityでの実装(バグが発生する)）

Python版の挿入ソートは9行を要します。`function`や`variables`、そして`loops`を、適宜Solidityの構文で置き換えてSolidityに書き換えてみましょう。
たったの９行のコードで出来ます:

``` solidity
    // Insertion Sort (Wrong version）（挿入ソート(間違いバージョン)）
    function insertionSortWrong(uint[] memory a) public pure returns(uint[] memory) {
        for (uint i = 1;i < a.length;i++){
            uint temp = a[i];
            uint j=i-1;
            while( (j >= 0) && (temp < a[j])){
                a[j+1] = a[j];
                j--;
            }
            a[j+1] = temp;
        }
        return(a);
    }
```

しかし、編集されたバージョンをコンパイルして`[2, 5, 3, 1]`をソートしようとした際に、*ドーンッ！*バグが発生するではありませんか！３時間ものデバッグの後で、どこにバグがあるのか、私には見当もつきませんでした。そこで、"Solidity insertion sort"をググってみたところ、Solidityで書かれた全ての挿入ソートアルゴリズムが全く間違っていることが分かったのでした。例えば、次の記事のように。[Sorting in Solidity without Comparison](https://medium.com/coinmonks/sorting-in-solidity-without-comparison-4eb47e04ff0d)

`Remix decoded output`でエラーは起こりました:

![10-1](./img/10-1.jpg)

### Solidity Implementation (Correct)（Solidityでの実装(正確な)）

`Dapp-Learning`コミュニティからの友人の助けにより、問題が漸く分かりました。Solidityで最もよく使われている変数型は`uint`です。そしてそれは非負の整数型を表しています。もし、負の値を取った時、`underflow`のエラーに直面してしまうのです。上記のソースコードで、変数`j`は`-1`を得るのですが、これがバグを引き起こしているのでした。

ですので、`j`が決して負の値を取ることが無いように、我々は`j`に`1`を加える必要があるのです。正確な挿入ソートのsolidityのコードは次のようになります:

```solidity
    // Insertion Sort（Correct Version）（挿入ソート(正確なバージョン)）
    function insertionSort(uint[] memory a) public pure returns(uint[] memory) {
        // note that uint can not take negative value（uint型は負の数を取れないことに注意すること）
        for (uint i = 1;i < a.length;i++){
            uint temp = a[i];
            uint j=i;
            while( (j >= 1) && (temp < a[j-1])){
                a[j] = a[j-1];
                j--;
            }
            a[j] = temp;
        }
        return(a);
    }
```

Result:

   !["Input [2,5,3,1] Output[1,2,3,5]"](https://images.mirror-media.xyz/publication-images/S-i6rwCMeXoi8eNJ0fRdB.png?height=300&width=554)

## まとめ

このレクチャーでは、Solidityにおける制御フローを紹介し、シンプルでありながらバグが発生しやすいソートアルゴリズムを書きました。Solidityはシンプルに見えますが、沢山の罠を抱えています。毎月、スマートコントラクトにある小さなバグが故に、プロジェクトはハッキングされて、何百万ドルもの損失を生んでしまいます。安全なコントラクトを書く為には、Solidityの基礎をマスターし、訓練し続ける必要があるのです。
