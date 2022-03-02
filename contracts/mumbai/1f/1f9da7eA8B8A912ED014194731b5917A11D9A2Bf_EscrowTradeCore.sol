// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IERC20.sol";
import "./EscrowDisputes.sol";

contract EscrowTradeCore is EscrowDisputes {

    constructor() {}

    function deposit(address seller, string memory tradeId) external payable{
        require(seller != address(0), 'Invalid Seller');
        require(msg.value > 0, 'Amount must be greater than zero');
        totalTrades += 1;
        escrows[totalTrades] = Escrow(totalTrades,payable(msg.sender),payable(seller),msg.value, false);
        emit Deposited(totalTrades, tradeId, msg.sender, seller, msg.value, address(0));
    }

    function depositToken(address seller, uint256 amount, address _tokenAddress, string memory tradeId) external onlyPermitToken(_tokenAddress) {
        require(seller != address(0), 'Invalid Seller');
        require(amount > 0, 'Amount must be greater than zero');
        totalTrades += 1;
        IERC20(_tokenAddress).transferFrom(msg.sender, address(this), amount);
        escrows[totalTrades] = Escrow(totalTrades,payable(msg.sender),payable(seller),amount,false);
        emit Deposited(totalTrades, tradeId, msg.sender, seller, amount, _tokenAddress);
    }

    function addDeposit(uint256 _id, uint256 amount) external {
        require(amount > 0, 'Amount must be greater than zero');
        require(escrowTokenAddresses[_id] != address(0), "Trade currency is not ERC20");
        IERC20(escrowTokenAddresses[_id]).transferFrom(msg.sender, address(this), amount);
        escrows[_id].amount += amount;
        emit ExtraDeposit(_id, amount);
    }

    function withdraw(uint256 _id) external {
        Escrow storage escrow = escrows[_id];
        require(!escrow.completed, "Escrow already completed");
        require(escrow.id == _id, "Escrow not matched");
        require(escrow.buyer == msg.sender || disputes[_id] == true, "You are not buyer");
        if(escrowTokenAddresses[_id] == address(0)){
             _withdrawNativeCoin(escrow.seller, escrow.amount);
        }else{
            _withdrawToken(escrow.seller, escrow.amount, escrowTokenAddresses[_id]);
        }

        escrow.completed = true;
        emit Completed(_id);
    }

    function dispute (uint256 _id) external {
        require(msg.sender == escrows[_id].buyer || msg.sender == escrows[_id].seller, "You are not buyer or seller");
        _dispute(_id);
    }

    function cancel(uint256 _id) external {
        Escrow storage escrow = escrows[_id];
        require(!escrow.completed, "Escrow already completed");
        require(escrow.id == _id, "Escrow not matched");
        require(escrow.seller == msg.sender || (disputes[_id] == true && msg.sender == owner()), "You are not seller or admin");
        // transfer amount back to seller ;
        if(escrowTokenAddresses[_id] == address(0)){
             _cancelNativeCoin(escrow.buyer, escrow.amount);
        }else{
            _cancelToken(escrow.buyer, escrow.amount, escrowTokenAddresses[_id]);
        }
        escrow.completed = true;
        emit Cancelled(_id);
    }
    

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


interface IERC20 {
    function transferFrom( address sender, address recipient, uint256 amount ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract EscrowTradeBase is Ownable{
    using SafeMath for uint256;

    /// @notice Fee of any native coin trade
    uint256 public fee;

    /// @notice Number of trades
    uint256 public totalTrades;

    struct Escrow {
        uint id;
        address payable buyer;
        address payable seller;
        uint amount;
        bool completed;
    }

    struct Token {
        bool allowed;
        uint256 fee;
    }

    /// @notice Map of all escrows
    mapping(uint => Escrow) public escrows;

    event Deposited(
        uint256 indexed id,
        string tradeId,
        address buyer,
        address seller,
        uint amount,
        address tokenAddress
    );
    event ExtraDeposit(
        uint256 indexed id,
        uint amount
    );
    event Completed(uint256 indexed id);
    event Cancelled(uint256 indexed id);
    event FeeDeducted(
        uint escrowId, 
        uint amount, 
        uint tokenAddress
    );
    
    //// @notice Transfer the coin to the seller
    /// @dev It calculate the estimate fee then transfer the coin (after deducing fee) to the seller
    /// @param to a parameter of type address that represents the address of the seller
    /// @param amount a parameter of type uint that represents the amount of the coin
    function _withdrawNativeCoin(
        address payable to, 
        uint256 amount
    ) internal {
        uint256 estimateFee = amount.mul(fee).div(10000);
        to.transfer(amount.sub(estimateFee));
    }

    /// @notice Transfer back the coin to the buyer
    /// @param to a parameter of type address that represents the address of the buyer
    /// @param amount a parameter of type uint that represents the amount of the coin
    function _cancelNativeCoin(
        address payable to, 
        uint256 amount
    ) internal {
        to.transfer(amount);
    }


    /// @notice Change the fee of native coin
    /// @dev This function is callable only from the owner of the contract.
    /// @param _fee a parameter of type uint that represents the new fee
    function changeFee(uint256 _fee) external onlyOwner() {
        fee = _fee;
    }


    // Getters

    function getEscrowFee(uint256 amount) internal view returns(uint256) {
        return amount.mul(fee).div(100);
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./EscrowTradeBase.sol";
import "./IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract EscrowErc20 is EscrowTradeBase {
    using SafeMath for uint256;

    mapping(uint => address) public escrowTokenAddresses;
    mapping(address => Token) public allowedToken;


    // Modifiers
    modifier onlyPermitToken (address _tokenAddress) {
        require(isAllowedToken(_tokenAddress), 'Token is not allowed');
        _;
    }

    function addToken(address _tokenAddress, uint _fee) external onlyOwner() {
        allowedToken[_tokenAddress] = Token(true, _fee);
    }

    function removeToken(address _tokenAddress) external onlyOwner() {
        delete allowedToken[_tokenAddress];
    }

    function changeTokenFee(uint256 _fee, address _tokenAddress) external onlyOwner() {
        allowedToken[_tokenAddress].fee = _fee;
    }

    function getEscrowTokenFee(uint256 amount, address _tokenAddress) internal view returns(uint256) {
        return amount.mul(allowedToken[_tokenAddress].fee).div(100);
    }

    function _cancelToken(
        address to, 
        uint256 amount, 
        address _tokenAddress
    ) internal {
        require(allowedToken[_tokenAddress].allowed, "Token is not allowed in this platform");
        // Transfer ERC20 Token
        IERC20(_tokenAddress).transferFrom(address(this), to, amount);
    }

    function _withdrawToken(
        address to, 
        uint256 amount, 
        address _tokenAddress
    ) internal {
        require(
            allowedToken[_tokenAddress].allowed,
            "Token is not allowed in this platform"
        );

        // Fee estimation
        uint256 estimateFee = amount.mul(allowedToken[_tokenAddress].fee).div(10000);

        // Transfer ERC20 Token
        IERC20(_tokenAddress).transferFrom(address(this), to, amount.sub(estimateFee));
    }

    function isAllowedToken(address _tokenAddress) internal view returns(bool){
        return allowedToken[_tokenAddress].allowed;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./EscrowErc20.sol";

contract EscrowDisputes is EscrowErc20 {
    
    event Disputed(uint256 indexed id, address disputeBy);
    mapping(uint => bool) public disputes;

    function _dispute(uint _id) internal {
        disputes[_id] = true;
        emit Disputed(_id, msg.sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

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
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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