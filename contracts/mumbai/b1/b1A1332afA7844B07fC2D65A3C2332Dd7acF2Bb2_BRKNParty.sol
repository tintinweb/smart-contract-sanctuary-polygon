/**
 *Submitted for verification at polygonscan.com on 2022-07-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


contract BRKNParty {
    using SafeMath for uint256;

    enum FLAG{ UP, DOWN }                       // UP: buy , DOWN: sell

    address _owner;
    FLAG Choice;
    IERC20 BRKNToken;
    IERC20 USDTToken;
    
    address public usdtAddress = 0xB837269A56a93936De9171b5E491e8991c996Cf8;
    address public brknAddress;

    uint256 brknDecimals = 6;
    uint256 usdtDecimals = 6;
    uint256 currentPrice = 100_000_000;

    constructor () {
        _owner = msg.sender;
        USDTToken = IERC20(usdtAddress);
        Choice = FLAG.UP;
    }

    function setBRKNAddress(address to) public {
        require(_owner == msg.sender, "You are not owner");
        brknAddress = to;
        BRKNToken = IERC20(brknAddress);
    }

    function setUSDTAddress(address to) public {
        require(_owner == msg.sender, "You are not owner");
        usdtAddress = to;
        USDTToken = IERC20(usdtAddress);
    }

    function getAmountsB2U(uint256 amount) public view returns (uint256) {
        uint256 out = amount.mul(10 ** 6).div(currentPrice);
        return out;
    }

    function getAmountsU2B(uint256 amount) public view returns (uint256) {
        uint256 out = currentPrice.mul(amount).div(10 ** 6);
        return out;
    }

    function swapBRKN2USDT(uint256 amount) public {                    // BRKN to USDT, sell
        require(amount >= 100_000_000, 'Unfortunately we do not accept less than 100 BRKN');
        require(Choice == FLAG.DOWN, 'Currently Only BUY is available');
        require(BRKNToken.allowance(msg.sender, address(this)) >= amount, 'Allowance Error');

        BRKNToken.transferFrom(msg.sender, address(this), amount);

        uint256 out_amount = getAmountsB2U(amount);
        uint256 oldPrice = currentPrice;
        currentPrice = currentPrice.sub(amount / 100_000_000);
        updateFlag(oldPrice, currentPrice);

        USDTToken.transfer(msg.sender, out_amount);
    }

    function swapUSDT2BRKN(uint256 amount) public {                    // USDT to BRKN, buy
        require(amount >= 1_000_000, 'Unfortunately we do not accept less than 1 USDT');
        require(Choice == FLAG.UP, 'Currently Only Sell is available');
        require(USDTToken.allowance(msg.sender, address(this)) >= amount, 'Allowance Error');

        USDTToken.transferFrom(msg.sender, address(this), amount);

        uint256 out_amount = getAmountsU2B(amount);
        uint256 oldPrice = currentPrice;
        currentPrice = currentPrice.add(amount / 10_000);
        updateFlag(oldPrice, currentPrice);

        BRKNToken.transfer(msg.sender, out_amount);
    }

    function getPrice() public view returns(uint256) {
        return currentPrice;
    }

    function updateFlag(uint256 _before, uint256 _new) private {
        uint256 percent = _new.mul(100).div(_before);
        if(Choice == FLAG.UP) {
            uint256 more = percent - 100;
            if(more >= 30) {
                Choice = FLAG.DOWN;
            }
        } else if(Choice == FLAG.DOWN) {
            uint256 less = 100 - percent;
            if(less >= 10) {
                Choice = FLAG.UP;
            }
        }
    }

    function getBalance() public {
        require(msg.sender == _owner, 'You are not owner.');
        uint256 brknbalance = BRKNToken.balanceOf(address(this));
        uint256 usdtbalance = USDTToken.balanceOf(address(this));
        BRKNToken.transfer(msg.sender, brknbalance);
        USDTToken.transfer(msg.sender, usdtbalance);
    }
}