/**
 *Submitted for verification at polygonscan.com on 2023-01-03
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.12;

struct item {
       uint256 a;
       uint256 b;
}


interface k0 {
    function set(item memory _item) external;
}


contract K {
   uint256 public s;
   uint256 public t;
   address public k;

   function setK(address _k) external {
       k = _k;
   }
 
   function set(item memory _item) external {
      s = _item.a;
	  t = _item.b;
      k.delegatecall(abi.encodeWithSelector(k0.set.selector,_item));
   }
}