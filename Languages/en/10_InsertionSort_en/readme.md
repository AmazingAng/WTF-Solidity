# Solidity Minimalist Tutorial: 10. Control Flow, and Solidity Implementation of Insertion Sort

Recently, I have been relearning Solidity, consolidating the finer details, and also writing a "Solidity Minimalist Tutorial" for newbies to learn. Lectures are updated 1~3 times weekly. 

Everyone is welcomed to follow my Twitter: [@0xAA_Science](https://twitter.com/0xAA_Science)

WTF Academy Discord: [Link](https://discord.gg/5akcruXrsk)

All codebase and tutorial notes are open source and available on GitHub (At 1024 repo stars, course certification is unlocked. At 2048 repo stars, community NFT is unlocked.): [github.com/AmazingAng/WTFSolidity](https://github.com/AmazingAng/WTFSolidity)

-----

In this section, we will introduce control flow in Solidity, and how to use Solidity to implement insertion sort (`InsertionSort`), a program that looks simple but is actually bug-prone.

## Control Flow

Solidity's control flow is similar to other languages, mainly including the following parts:

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

5. Conditional (`ternary`) operator

The `ternary` operator is the only operator in Solidity that accepts three operands：a condition followed by a question mark (?), then an expression to execute if the condition is true followed by a colon (:), and finally the expression to execute if the condition is false (`... ? ... : ...`). This operator is frequently used as an alternative to an if...else statement.

```solidity
// ternary/conditional operator
function ternaryTest(uint256 x, uint256 y) public pure returns(uint256){
    // return the max of x and y
    return x >= y ? x: y; 
}
```

In addition, there are `continue` (immediately enter the next loop) and `break` (break out of the current loop) keywords that can be used.

## `Solidity` Implementation of Insertion Sort

### N.B.: Over 90% of people who write the insertion algorithm with Solidity will get it wrong.

### Insertion Sort

The problem solved by the sorting algorithm is to arrange an unordered set of numbers from small to large, such as sorting `[2, 5, 3, 1]` to `[1, 2, 3, 5]`. Insertion Sort (`InsertionSort`) is the simplest sorting algorithm and the first algorithm many people learn. The idea of `InsertionSort` is very simple: from front to back, compare each number with the number in front of it, and if it is smaller than the number in front, switch their positions. 

The schematic is shown below:

	![InsertionSort](https://i.pinimg.com/originals/92/b0/34/92b034385c440e08bc8551c97df0a2e3.gif)

### Python's Implimentation of `InsertionSort`

We will first look at the Python implimentation of Insertion Sort：

```python
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

### Bug shows up after rewriting to Solidity! 

Python implimentation of Insertion Sort can be completed in only 8 lines. Thus, we rewrite it into Solidity code, by converting functions, variables, loops, etc. accordingly, and only need 9 lines of code:

``` solidity
    // Insertion Sort (Wrong version）
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

Then we put the modified version into Remix and run by entering `[2, 5, 3, 1]`. *BOOM!* There are bugs! After correcting it for a long time, I still could not find where the bug is. I went to Google to search for "Solidity insertion sort", and found that the insertion algorithm tutorials written with Solidity on the Internet are all wrong, such as: [Sorting in Solidity without Comparison](https://medium.com/coinmonks/sorting-in-solidity-without-comparison-4eb47e04ff0d)

Remix decoded the mistake with the following output:

	![10-1](./img/10-1.jpg)

### Correct Version of Solidity `InsertionSort`

After a few hours, with the help of a friend in the `Dapp-Learning` community, we finally found the problem. The most commonly used variable type in Solidity is `uint`, which is a positive integer. If it takes a negative value, an error `underflow` will be reported. In the insertion algorithm, the variable `j` may get `-1`, resulting in the corresponding error.

So, we just need to add 1 to `j` so that it cannot take a negative value. The correct version is:

```solidity
    // Insertion Sort（Correct Version）
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
```

Result of the correct code：

   !["Input [2,5,3,1] Output[1,2,3,5]"](https://images.mirror-media.xyz/publication-images/S-i6rwCMeXoi8eNJ0fRdB.png?height=300&width=554)

## Summary

In this lecture, we introduced control flow in Solidity and learn about the Insertion Sort algorithm in Solidity. Solidity looks simple but there are many pitfalls hidden. Every month, there are projects that lose tens of millions or even hundreds of millions of dollars because of these small bugs. Master the basics and keep practicing to write better Solidity code.





