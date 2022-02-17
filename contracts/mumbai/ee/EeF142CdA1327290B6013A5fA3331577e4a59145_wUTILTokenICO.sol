/**
 *Submitted for verification at polygonscan.com on 2022-02-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function decimals() external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
 
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


/*
tokenPrice: 1 / 0.04  // 0.04 is amount of USDT per wUTILToken
*/

contract wUTILTokenICO is Ownable {
    using SafeMath for uint256;

    // address of admin
    IERC20 public wUTILtoken;
    // token price variable (amount of wUTILtoken per 1 native coin)
    uint256 public tokenPrice;
    // count of tokens sold
    uint256 public tokensSold; 
    uint256 public minInvestment; // minimum amount of tokens that an investor can buy

    event Sell(address sender,uint256 totalvalue);
    event SetTokenPrice(uint256 tokenPrice);
    event SetTokenAddress(address tokenaddress);
    event SetMinInvestment(uint256 _minInvestment);

    // constructor 
    constructor(address _tokenAddress, uint256 _tokenPrice, uint256 _minInvestment) {
        wUTILtoken  = IERC20(_tokenAddress);
        tokenPrice = _tokenPrice;
        minInvestment = _minInvestment;
    }

    function setTokenAddress(address _tokenaddress) external onlyOwner {
        wUTILtoken  = IERC20(_tokenaddress);
        emit SetTokenAddress(_tokenaddress);
    }

    function setTokenPrice(uint256 _tokenvalue) external onlyOwner {
        tokenPrice = _tokenvalue;
        emit SetTokenPrice(tokenPrice);
    }

    function getTokenPrice() external view returns (uint256){
        return tokenPrice;
    }

    function setMinInvestment(uint256 _minInvestment) external onlyOwner {
        minInvestment = _minInvestment;
        emit SetMinInvestment(_minInvestment);
    }

    function getTokensSold() external view returns (uint256){
        return tokensSold;
    }

    // buyTokens function
    function buyTokens(address usdtToken, uint256 usdtAmount) external {
        address buyer = msg.sender;
        uint256 wUTILAmount = usdtAmount.mul(tokenPrice).div(10**wUTILtoken.decimals());

	// check if usdtAmount is equal to or greater than minInvestment.
        require(usdtAmount >= minInvestment, "check if usdtAmount is equal to or greater than minInvestment");

	// check if allowance is enough.
        uint256 allowance = IERC20(usdtToken).allowance(msg.sender, address(this));
        require(allowance >= usdtAmount, "Check the wUTILtoken allowance");
        IERC20(usdtToken).transferFrom(buyer, address(this), usdtAmount);

        // check if the contract has the tokens or not
        require(wUTILtoken.balanceOf(address(this)) >= wUTILAmount,"the smart contract dont hold the enough tokens");
        // transfer the wUTILtoken to the user
        wUTILtoken.transfer(buyer, wUTILAmount);
        // increase the wUTILtoken sold
	    tokensSold = tokensSold.add(wUTILAmount);
        // emit sell event for ui
        emit Sell(buyer, wUTILAmount);
    }

    function transfer2wallet(address receiveaddr, uint256 amount) external onlyOwner {
        wUTILtoken.transfer(receiveaddr, amount);
    }

    // end sale
    function endsale() public onlyOwner {
        // transfer all the remaining tokens to admin
        require(wUTILtoken.transfer(msg.sender, wUTILtoken.balanceOf(address(this))));
        // transfer all the etherum to admin and self selfdestruct the contract
        selfdestruct(payable(msg.sender));
    }
}