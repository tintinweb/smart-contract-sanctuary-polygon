/**
 *Submitted for verification at polygonscan.com on 2023-01-03
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.12;


interface k0 {
    struct item {
       uint256 a;
       uint256 b;
   }
    function set(item memory _item) external;
}


contract K {
   uint256 public s;
   uint256 public t;
   struct item {
       uint256 a;
       uint256 b;
   }
   //address public k=0x5FD6eB55D12E759a21C09eF703fe0CBa1DC9d88D;

   function set(item memory _item) external {
      s = _item.a;
	  t = _item.b;
      //k.delegatecall(abi.encodeWithSelector(k0.set.selector,_item));
   }
}