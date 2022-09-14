/**
 *Submitted for verification at polygonscan.com on 2022-09-14
*/

// SPDX-License-Identifier: MIT
/**
 *Submitted for verification at BscScan.com on 2022-09-12
*/

// File: contracts/microTokens/manager.sol


pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from,address to,uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
    function mint_mx(uint amount, address receiver) external;
    function burn_mx(address sender, uint amount) external;
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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


contract manager {
    using SafeMath for uint;
    address public admin;
    address public xToken;
    address public mXToken;
    IERC20 immutable mXTokenContract;

    constructor(address _mXToken) {
        admin = msg.sender;
        mXToken = _mXToken;
        mXTokenContract = IERC20(mXToken);
    }

    modifier onlyOwner(){
        require(msg.sender == admin, "Not Authorized");
        _;
    }

    function setTokenXaddress(address _xToken) onlyOwner public {
        xToken = _xToken;
    }

    function sendXToken(uint amount) public {
        IERC20 xTokenFns = IERC20(xToken);
        require(xTokenFns.balanceOf(msg.sender) >= amount, "MANAGER: INSUFFICIENT BALANCE");
        xTokenFns.transferFrom(msg.sender, address(this), amount); // sends X token amount to MANAGER contract
        uint mxDecimals = mXTokenContract.decimals();
        uint xDecimals = xTokenFns.decimals();
        uint factor = mxDecimals.sub(xDecimals);
        mXTokenContract.mint_mx(amount.mul(1000).mul(10**factor), msg.sender);
    }

    function sendMXToken(uint mXAmount) public {
        require(mXTokenContract.balanceOf(msg.sender) >= mXAmount, "MANAGER: INSUFFICIENT MX AMOUNT");
        IERC20 xTokenFns = IERC20(xToken);
        uint xAmount = mXAmount.div(10**mXTokenContract.decimals()).mul(10**xTokenFns.decimals()).div(1000);
        if(xTokenFns.balanceOf(address(this)) >= xAmount) {
            xTokenFns.transfer(msg.sender, xAmount);
            mXTokenContract.burn_mx(msg.sender, mXAmount);
        }
        else{
            require(false, "MANAGER: INSUFFICIENT X TOKEN AMOUNT");
        }
    }
}