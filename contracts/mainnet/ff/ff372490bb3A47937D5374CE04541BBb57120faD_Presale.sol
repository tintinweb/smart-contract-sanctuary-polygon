/**
 *Submitted for verification at polygonscan.com on 2023-07-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

// Sources flattened with hardhat v2.12.6 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File @openzeppelin/contracts/token/ERC20/[email protected]

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File @openzeppelin/contracts/utils/math/[email protected]

// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
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
    function trySub(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
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

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

contract Presale is Ownable {
    using SafeMath for uint256;

    //Struct for Buyers
    struct tokenBuyer{
        uint256 tokensBought;
    }

    //Mapping for Buyers
    mapping (address => tokenBuyer) public Customer;

    // The token being sold
    IERC20 public immutable token;

    //USDT token address
    IERC20 public immutable usdt = IERC20(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);

    //tokens that can be claimed
    uint256 private claimableTokens;

    // Address where funds are collected
    address public wallet = payable(0x31b5B830a8B02D79b1933ce7aBDe74230BA3908e);

    // How many token units a buyer gets per BNB & USDT
    uint256 private bnbRate = 10000;
    uint256 private usdtRate = 10;

    // Amount of wei raised
    uint256 private weiRaised;
    uint256 private usdtRaised;

    //Amount of tokens sold
    uint256 private tokensSold;

    //Presale status
    bool private hasPresaleStarted;
    uint256 private presalePeriod;

    constructor(address _token) {
        token = IERC20(_token);
    }

    receive() external payable {
        buyTokens();
    }
    
    //START PRESALE & SET PRESALE PERIOD
    function StartPresale() public onlyOwner{
        hasPresaleStarted = true;
        presalePeriod = block.timestamp + 200;
    }

    // BUY TOKENS WITH BNB
    function buyTokens() public payable {
        require(hasPresaleStarted,"Presale not started");
        require(presalePeriod >= block.timestamp, "Presale has ended");
        require(msg.value >= 0.01 ether, "cant buy less with than 0.01 BNB");
        require(10 ether >= msg.value, "cannot buy with more than 10 BNB");
        uint256 weiAmount = msg.value;
        uint256 tokens = weiAmount * bnbRate;
        uint256 alreadyBought = Customer[msg.sender].tokensBought;
        require(
            token.balanceOf(address(this)) >= tokens + alreadyBought,
            "Insufficient tokens in contract"
        );
        require(claimableTokens >= tokens, "Not enought tokens availible");

        weiRaised += weiAmount;

        Customer[msg.sender].tokensBought += tokens;
        tokensSold += tokens;
        claimableTokens -= tokens;

        (bool callSuccess, ) = payable(wallet).call{value: msg.value}("");
        require(callSuccess, "Call failed");
    }

    //BUY TOKENS WITH USDT
    function buyTokensWithUSDT(uint256 amount) public {
        require(hasPresaleStarted,"Presale not started");
        require(presalePeriod >= block.timestamp, "Presale has ended");
        require(amount >= 1 * 10 ** 18, "cant buy less with than 1 USDT");
        require(5000 * 10 ** 18 >= amount, "cannot buy with more than 5000 USDT");
        uint256 weiAmount = amount;
        uint256 tokens = weiAmount * usdtRate;
        uint256 alreadyBought = Customer[msg.sender].tokensBought;
        require(
            token.balanceOf(address(this)) >= tokens + alreadyBought,
            "Insufficient tokens in contract"
        );
        require(claimableTokens >= tokens, "Not enought tokens availible");

        usdtRaised += weiAmount;

        Customer[msg.sender].tokensBought += tokens;
        tokensSold += tokens;
        claimableTokens -= tokens;

        usdt.transferFrom(msg.sender, wallet, amount);
    }

    //DEPOSIT TOKENS FOR PRESALE
    function deposit(uint amount) external onlyOwner {
        require(amount > 0, "Deposit value must be greater than 0");
        token.transferFrom(msg.sender, address(this), amount);
        claimableTokens += amount;
    }

    //WITHDRAW UNSOLD TOKENS IF NEEDED
    function withdraw(uint amount) external onlyOwner {
        require(
            token.balanceOf(address(this)) > 0,
            "There are not enough tokens in contract"
        );
        token.transfer(msg.sender, amount);
        claimableTokens -= amount;
    }

    // CLAIM FUNCTION
    function claimTokens() public {
        require(block.timestamp >= presalePeriod,"Presale has not ended");
        require(Customer[msg.sender].tokensBought > 0, "No tokens to be claimed");

        uint256 amount = Customer[msg.sender].tokensBought;

        token.transfer(msg.sender, amount);

        Customer[msg.sender].tokensBought = 0;
    }

    //TO CHANGE COLLECTION WALLET
    function changeWallet(address payable _wallet) external onlyOwner {
        wallet = _wallet;
    }

    //TO UPDATE RATES
    function changeRate(uint256 _bnbRate, uint256 _usdtRate) public onlyOwner {
        require(_usdtRate > 0, "Rate cannot be 0");
        require(_bnbRate > 0, "Rate cannot be 0");
        bnbRate = _bnbRate;
        usdtRate = _usdtRate;
    }

    // ALL GETTER FUNCTIONS TO RETRIEVE DATA

    function checkbalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function getBnbRate() public view returns (uint256) {
        return bnbRate;
    }

    function getUsdtRate() public view returns (uint256) {
        return usdtRate;
    }

    function progressBNB() public view returns (uint256) {
        return weiRaised;
    }

    function progressUSDT() public view returns (uint256) {
        return usdtRaised;
    }

    function soldTokens() public view returns (uint256) {
        return tokensSold;
    }

    function checkPresaleStatus() public view returns (bool) {
        return hasPresaleStarted;
    }

    function getPresalePeriod() public view returns (uint256) {
        return presalePeriod;
    }

    function getClaimableTokens() public view returns (uint256) {
        return claimableTokens;
    }

}