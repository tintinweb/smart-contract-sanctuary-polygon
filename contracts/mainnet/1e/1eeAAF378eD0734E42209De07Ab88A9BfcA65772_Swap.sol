/**
 *Submitted for verification at polygonscan.com on 2022-04-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}


abstract contract ERC20 {
    uint256 public totalSupply;
    function balanceOf(address _owner) view public virtual returns (uint256 balance);
    function transfer(address _to, uint256 _value) public virtual returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool success);
    function approve(address _spender, uint256 _value) public virtual returns (bool success);
    function allowance(address _owner, address _spender) view public virtual returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Swap is Ownable{
    using SafeMath for uint256;

    ERC20 public reward = ERC20(address(0xcf74Ae52ae2c848387e6cD0048e1eC5a93ee2c66));

    ERC20 public usdt = ERC20(address(0xc2132D05D31c914a87C6611C10748AEb04B58e8F));

    uint256 public minDeposit = 100000000000000000;
    
    uint256 public priceToken = 1000000000000000000;

    address payable public vault = 0x89d4c05848811155ce16a447c762421eaC93d927;
    
    function setTokenReward(address _tokenAddr) public onlyOwner{
        reward = ERC20(_tokenAddr);
    }

     function setTokenUSDT(address _usdt) public onlyOwner{
        usdt = ERC20(_usdt);
    }
    
    function setVault(address payable _value) public onlyOwner{
        vault = _value;
    }
    
    function setMinDeposit(uint256 _value) public onlyOwner{
        minDeposit = _value;
    }
    
    function setPriceToken(uint256 _value) public onlyOwner{
        priceToken = _value;
    }

    function withdraw() public onlyOwner{
        vault.transfer(address(this).balance);
    }

    function withdrawToken() public onlyOwner{
        reward.transfer(msg.sender, reward.balanceOf(address(this)));
    }

    function swapUSDT(uint256 _usdt) public payable{
        require(_usdt >= minDeposit);

        usdt.transferFrom(msg.sender, vault, _usdt);
        
        uint256 valueTOKEN = _usdt.div(priceToken).mul(1000000000000000000);
        
        reward.transfer(msg.sender, valueTOKEN);
    }
    
}