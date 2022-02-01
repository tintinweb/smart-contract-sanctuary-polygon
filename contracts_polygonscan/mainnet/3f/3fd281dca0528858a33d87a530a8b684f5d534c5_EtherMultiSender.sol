/**
 *Submitted for verification at polygonscan.com on 2022-02-01
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


abstract contract ERC20Basic {
    function totalSupply() virtual public view returns (uint256);
    function balanceOf(address who) virtual public view returns (uint256);
    function transfer(address to, uint256 value) virtual public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

abstract contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) virtual public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) virtual public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract EtherMultiSender {
    using SafeMath for uint256;
    function multisend(address payable[] memory _recipients, uint256[] memory _balances)
        public
        payable
    {
        //test
        uint256 total = msg.value;
        uint256 i = 0;
        for (i; i < _recipients.length; i++) {
            require(total >= _balances[i]);
            total = total.sub(_balances[i]);
            _recipients[i].transfer(_balances[i]);
        }
    }

    function multisendErc20(address token, address payable[] memory _recipients, uint256[] memory _balances) public payable {
        require(_recipients.length <= 200);

        uint256 i = 0;
        ERC20 erc20 = ERC20(token);

        for(i; i < _recipients.length; i++) {
            erc20.transferFrom(msg.sender, _recipients[i], _balances[i]);
        }
    }
}