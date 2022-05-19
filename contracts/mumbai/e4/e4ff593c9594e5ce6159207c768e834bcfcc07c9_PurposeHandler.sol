/**
 *Submitted for verification at polygonscan.com on 2022-05-19
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0; // 合约版本号


// import "hardhat/console.sol";  
// 引入 console.sol 的作用在这里：https://hardhat.org/tutorial/debugging-with-hardhat-network.html，简单来说就是能在合约中 console.log 进行调试了
//import "@openzeppelin/contracts/access/Ownable.sol"; //https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

contract PurposeHandler { // 合约名称

  //event SetPurpose(address sender, string purpose);

  string public purpose = "Building Unstoppable Apps!!!"; // 设定一个变量 purpose，这个变量是直接存储在区块链中的，这也是和传统的编程语言不同的特性之一 —— 赋值即存储。

  constructor() {
    // what should we do on deploy?
  }

  function setPurpose(string memory newPurpose) public {
  		// 一个传参为 newPurpose 的函数
  		// memory/storage 这两种修饰符的使用看这里：
  		// https://learnblockchain.cn/2017/12/21/solidity_reftype_datalocation
      purpose = newPurpose; // 把 purpose 更新为传入的参数
      //console.log(msg.sender,"set purpose to",purpose);
      //emit SetPurpose(msg.sender, purpose);
  }
}