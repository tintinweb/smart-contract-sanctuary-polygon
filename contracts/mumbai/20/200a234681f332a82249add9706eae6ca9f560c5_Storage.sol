/**
 *Submitted for verification at polygonscan.com on 2023-05-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract Ownable 
{    
  // Variable that maintains 
  // owner address
  address private _owner;
  
  // Sets the original owner of 
  // contract when it is deployed
  constructor()
  {
    _owner = msg.sender;
  }
  
  // Publicly exposes who is the
  // owner of this contract
  function owner() public view returns(address) 
  {
    return _owner;
  }
  
  // onlyOwner modifier that validates only 
  // if caller of function is contract owner, 
  // otherwise not
  modifier onlyOwner() 
  {
    require(isOwner(),
    "Function accessible only by the owner !!");
    _;
  }
  
  // function for owners to verify their ownership. 
  // Returns true for owners otherwise false
  function isOwner() public view returns(bool) 
  {
    return msg.sender == _owner;
  }
}

interface Calculator {
   function getResult() external view returns(uint);
}

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Storage is Ownable {
    Calculator calculator;
    
    constructor(address _test){
        calculator =  Calculator(_test);
    }

    uint256 number;

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public onlyOwner{
        number = num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }
}