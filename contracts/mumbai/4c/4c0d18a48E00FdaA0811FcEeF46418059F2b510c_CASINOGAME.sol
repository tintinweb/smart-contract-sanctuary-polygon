/**
 *Submitted for verification at polygonscan.com on 2023-07-13
*/

/**
 *Submitted for verification at BscScan.com on 2023-07-12
*/

/**
 *Submitted for verification at BscScan.com on 2022-11-19
*/

/**
 *Submitted for verification at BscScan.com on 2022-11-10
*/

/**
 *Submitted for verification at BscScan.com on 2022-10-20
*/

/**
 *Submitted for verification at BscScan.com on 2022-10-20
*/

/**
 *Submitted for verification at polygonscan.com on 2022-10-19
*/

/**
 *Submitted for verification at polygonscan.com on 2022-10-10
*/

/**
 *Submitted for verification at polygonscan.com on 2022-10-01
*/

/**
 *Submitted for verification at polygonscan.com on 2022-09-02
*/

/**
 *Submitted for verification at BscScan.com on 2022-07-02
*/

/**
 *Submitted for verification at BscScan.com on 2022-06-30
*/

pragma solidity ^ 0.8.0;

// SPDX-License-Identifier: UNLICENSED

interface IBEP20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function burn(uint256 value) external returns (bool);
  event Transfer(address indexed from,address indexed to,uint256 value);
  event Approval(address indexed owner,address indexed spender,uint256 value);
}

library SafeMath {
  
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }


    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

   
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

   
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

   
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

  
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

 
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

  
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

   
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

   
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

contract CASINOGAME {
    using SafeMath for uint256;
    event deposite(address indexed user,uint256 amountBuy);

    IBEP20 private SEEDx; 
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(address ownerAddress,IBEP20 _SEEDx) {
        owner = ownerAddress; 
        SEEDx = _SEEDx;    
    }
    
    function add_fund_deposite(uint256 _amount) external {
        require(_amount==45,"invalid package");
    	uint256 tot_amt = (_amount*1e18);   
        require(SEEDx.balanceOf(msg.sender) >= tot_amt,"Low SEEDx Balance");
        require(SEEDx.allowance(msg.sender,address(this)) >= tot_amt,"Invalid allowance ");
        SEEDx.transferFrom(msg.sender, owner, tot_amt);
        emit deposite(msg.sender,_amount);
	}
    
    function withdrawToken(IBEP20 _token ,uint256 _amount) external onlyOwner {
        _token.transfer(owner,_amount);
    }

    function withdraw(uint256 _amount) external onlyOwner {
        payable(owner).transfer(_amount);
    }
	
}