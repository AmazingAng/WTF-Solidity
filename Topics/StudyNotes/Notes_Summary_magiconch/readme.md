# Solidity如何在数组中删除指定元素

Solidity中的数组相对于其他语言来说，功能很少，仅有push/pop两种功能。但是我们在实际开发中，可能会遇到删除指定元素的场景，那么这个功能改如何实现呢？



## 简单的方案(?)

在solidity中存在一个关键词叫做`delete`那么直接使用这个关键词，删除指定元素是否能解决问题呢？

```solidity
pragma solidity ^0.8.9;
contract itemRemoval{
  uint[] public arrs = [1,2,3,4,5];
  function removeItem(uint i) public {
    delete arrs[i];
  }
  function getLength() public view returns(uint){
    return arrs.length;
  }
}
```

对于以上这段代码，我们尝试删除第一个元素，执行`removeItem(0)`，`arrs`将会变成这样：`[0,2,3,4,5]`，

接下来运行`getLength()`，我们将会得到结果为`5`，这是怎么回事？

> ```markdown
> ## delete
> `a` assigns the initial value for the type to `a`. I.e. for integers it is equivalent to `a = 0`
> ```

通过查阅文档，我们可以知道，在solidity语意下的删除是指将该变量恢复为默认值。这里就存在了潜在的风险，数组的长度无限增长，有可能导致gas费的持续上涨。如果代码运行下去，可能会导致gas fee直至超过上限。

如果你还觉得这样没有问题，让我们把问题扩充一下：

```solidity
pragma solidity ^0.8.9;
contract itemRemoval{
  uint[] public arrs = [0,1,2,3,4];
  function deleteZeroItem() public {
  	for (uint i = 0; i < arrs.length; i++) {
  		if (arrs[i] == 0) {
  			delete arrs[i];
  		}
  	}
  }
  function getLength() public view returns(uint){
    return arrs.length;
  }
}
```

我想实现一个可以删除元素值为0的函数，通过上面的代码，你会发现完全没有办法删除这个元素。



我们可以看到，虽然使用`delete`删除数组元素简单又节省gas，但是这样做带来的风险是不可估量的。



## 交换末尾元素

```solidity
pragma solidity ^0.8.9;
contract itemRemoval{
  uint[] public arrs = [1,2,3,4,5];
  function removeItem(uint i) public {
    arrs[i] = arrs[arrs.length - 1];
    arrs.pop();
  }
  function getLength() public view returns(uint){
    return arrs.length;
  }
}
```

通过将目标元素和栈尾元素交换，再将队尾元素出栈，这样做的gas花费相比较上一种会高很多，但是通过这种方式，可以将数组长度控制在指定范围，不会出现随着时间推移，数组的长度无法控制的情况。

但是这样子也不是完美无缺的，通过这样删除元素会改变数组的元素顺序，对于需要维护数组元素顺序的要求，我们应该使用以下写法：

```solidity
pragma solidity ^0.8.9;
contract itemRemoval{
  uint[] public arrs = [1,2,3,4,5];
  function removeItem(uint i) public {
    for (;i < arrs.length - 1; i++) {
        arrs[i] = arrs[i + 1];
      }
    arrs.pop();
  }
  function getLength() public view returns(uint){
    return arrs.length;
  }
}
```

但是这样做的gas开销会非常大，因为更改一个状态的gas花费是远大于运算的，不在必要情况下，不推荐使用这种写法。





