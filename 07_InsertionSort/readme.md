# Solidity极简入门: 7. 控制流，用solidity实现插入排序

我最近在重新学solidity，巩固一下细节，也写一个“Solidity极简入门”，供小白们使用（编程大佬可以另找教程），每周更新1-3讲。

欢迎关注我的推特：[@0xAA_Science](https://twitter.com/0xAA_Science)

所有代码开源在github(64个star开微信交流群，已开[填表加入](https://docs.google.com/forms/d/e/1FAIpQLSe4KGT8Sh6sJ7hedQRuIYirOoZK_85miz3dw7vA1-YjodgJ-A/viewform)；128个star录教学视频): [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----
这一讲，我们将介绍`solidity`中的控制流，然后讲如何用`solidity`实现插入排序（`InsertionSort`），一个看起来简单，但实际上很容易写出`bug`的程序。

控制流
`Solidity`的控制流与其他语言类似，主要包含以下几种：

1. `if-else`

        // if else
        function IfElseTest(uint256 _number) public returns(uint256){
        if(条件){
            ...;
        }else{
            ...;
        }
    }
2. `for循环`

        for(uint256 i = 0; i < n; i++){
            ...;
        }
3. `while循环`

        while(i < n){
            ...;
        }
4. `do-while循环`

        do{
            ...;

        }while(i < n);
另外还有`continue`（立即进入下一个循环）和break（跳出当前循环）关键字可以使用。

## 用`solidity`实现插入排序
### 写在前面：90%以上的人用`solidity`写插入算法都会出错。

### 插入排序
排序算法解决的问题是将无序的一组数字，例如`[2, 5, 3, 1]`，从小到大一次排列好。插入排序（`InsertionSort`）是最简单的一种排序算法，也是很多人学习的第一个算法。它的思路很简答，从前往后，依次将每一个数和排在他前面的数字比大小，如果比前面的数字小，就互换位置。示意图：

![插入排序](https://i.pinimg.com/originals/92/b0/34/92b034385c440e08bc8551c97df0a2e3.gif)

### `python`代码
我们可以先看一下插入排序的python代码：
```
# Python program for implementation of Insertion Sort
def insertionSort(arr):
	for i in range(1, len(arr)):
		key = arr[i]
		j = i-1
		while j >=0 and key < arr[j] :
				arr[j+1] = arr[j]
				j -= 1
		arr[j+1] = key
```
### 改写成`solidity`后有`BUG`！
一共8行`python`代码就可以完成插入排序，非常简单。那么我们将它改写成`solidity`代码，将函数，变量，循环等等都做了相应的转换，只需要9行代码：

    // 插入排序 错误版
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
那我们把改好的放到`remix`上去跑，输入`[2, 5, 3, 1]`。BOOM！有`bug`！改了半天，没找到`bug`在哪。我又去`google`搜”solidity insertion sort”，然后发现网上用`solidity`写的插入算法教程都是错的，比如：[Sorting in Solidity without Comparison](https://medium.com/coinmonks/sorting-in-solidity-without-comparison-4eb47e04ff0d)

### 正确的solidity插入排序
花了几个小时，在`Dapp-Learning`社群一个朋友的帮助下，终于找到了`bug`所在。`solidity`中最常用的变量类型是`uint`，也就是正整数，取到负值的话，会报`underflow`错误。而在插入算法中，变量`j`有可能会取到`-1`，引起报错。

这里，我们需要把`j`加1，让它无法取到负值。正确代码：

    // 插入排序 正确版
    function insertionSort(uint[] memory a) public pure returns(uint[] memory) {
        // note that uint can not take negative value
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
运行后的结果：

!["输入[2,5,3,1] 输出[1,2,3,5]
"](https://images.mirror-media.xyz/publication-images/S-i6rwCMeXoi8eNJ0fRdB.png?height=300&width=554)

## 总结
这一讲，我们介绍了`solidity`中控制流，并且用`solidity`写了插入排序。看起来很简单，但实际很难。这就是`solidity`，坑很多，每个月都有项目因为这些小`bug`损失几千万甚至上亿美元。掌握好基础，不断练习，才能写出更好的`solidity`代码。

