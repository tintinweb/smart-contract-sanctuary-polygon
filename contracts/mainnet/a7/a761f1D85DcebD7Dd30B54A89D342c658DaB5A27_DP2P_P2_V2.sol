// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.18;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Counters.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

contract DP2P_P2_V2 is ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private adCount;

    struct Ad {
        address buyer;
        address seller;
        uint256 sellerAmount;
        uint256 amount;
        uint256 commissionAmount;
        address tokenAddr;
        AdStatus status;
        uint256 remainAmount;
        bool isProcessing;
    }

    struct AssignedAmount {
        uint256 adId;
        uint256 adminAmount;
    }

    enum AdStatus { Open, Cancelled, Completed }

    mapping(string => address) public tokenAddresses;
    mapping(uint256 => Ad) public ads;
    mapping(address => mapping(address => AssignedAmount)) public assignedAmount;

    address public admin;
    uint256 public minAmount = 0.01 ether;
    uint256 public maxAmount = 200 ether;
    uint256 public commissionRate = 2;

    event AdPosted(address indexed buyer, uint256 amount, uint256 adId);
    event PaymentReceived(address indexed buyer, uint256 amount);
    event AdCancelled(address indexed buyer, uint256 adId);

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    function isTokenContract(address _address) internal view returns (bool) {
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(_address)
        }
        if (codeSize > 0) {
            try IERC20(_address).totalSupply() returns (uint256) {
                return true;
            } catch {}
        }
        return false;
    }

    function setTokenAddress(string memory tokenName, address _token) external onlyAdmin {
        require(isTokenContract(_token), "Not a valid token address");
        require(bytes(tokenName).length > 0, "Token name cannot be empty");
        tokenAddresses[tokenName] = _token;
    }
    
    function calculateCommission(uint256 amount)
        external
        view
        returns (uint256[2] memory)
    {
        uint256 commissionAmount = amount.mul(commissionRate).div(1000);
        uint256 totalAmount = amount.add(commissionAmount);
        return [totalAmount, commissionAmount];
    }

    function postAd(uint256 amount, string memory tokenName) external payable{
        require(msg.sender != admin, "Admin cannot create an ad");
        require(amount >= minAmount && amount <= maxAmount, "Invalid ad amount");

        address _tokenAddr = tokenAddresses[tokenName];

        uint256 adId = adCount.current();
        adCount.increment();


        ads[adId].buyer = msg.sender;
        ads[adId].amount = amount;
        ads[adId].remainAmount = amount;
        ads[adId].status = AdStatus.Open;
        ads[adId].tokenAddr = _tokenAddr;

        emit AdPosted(msg.sender, amount, adId);
    }
 
    function updateAd(uint256 newAmount, uint256 adId) external payable {
        require(msg.sender != admin, "Admin cannot create an ad");
        require(ads[adId].buyer == msg.sender, "Only buyer can call this");
        require(newAmount >= minAmount && newAmount <= maxAmount, "Invalid ad amount");
        require(adId >= 0 && adId <= adCount.current(), "Invalid Ad ID");
        
        uint256 oldAmount = ads[adId].amount;
        uint256 newTotal = oldAmount.add(newAmount);

        ads[adId].amount = newTotal;
        ads[adId].remainAmount = newTotal;
    }

    function cancelAd(uint256 adId) external {
        require(adId >= 0 && adId <= adCount.current(), "Invalid Ad ID");
        Ad storage ad = ads[adId];
        require(ad.buyer == msg.sender, "Only the buyer can cancel the ad");
        require(ad.status == AdStatus.Open, "Ad is not in the open state");
        require(!ad.isProcessing, "Ad cannot be canceled right now");

        
        ad.status = AdStatus.Cancelled;
        emit AdCancelled(msg.sender, adId);
    }

    function transferToContract(uint256 adId, uint256 _amount) external payable {
        require(msg.sender != admin, "admin can't perform this!");
        require(adId >= 0 && adId <= adCount.current(), "Invalid Ad ID");
        require(ads[adId].buyer != msg.sender, "Buyer cannot call this function");
        require(!ads[adId].isProcessing, "Ad is already being processed");
        require(ads[adId].status == AdStatus.Open, "Ad is not open");
        

        uint256 commissionAmount = _amount.mul(commissionRate).div(1000);
        uint256 totalCommission = _amount.add(commissionAmount);

        address tokenAddr = ads[adId].tokenAddr;
        ads[adId].sellerAmount = _amount;
        ads[adId].seller = msg.sender;
        ads[adId].isProcessing = true;
        ads[adId].commissionAmount = commissionAmount;
        address payable buyer = payable(ads[adId].buyer);

        assignedAmount[buyer][admin].adId = adId;
        assignedAmount[buyer][admin].adminAmount = _amount;

        if (tokenAddr != address(0) && isTokenContract(tokenAddr)) {
            IERC20 token = IERC20(tokenAddr);
            uint256 sellerBalance = token.balanceOf(msg.sender);
            require(sellerBalance >= _amount, "Insufficient Token Balance");
            require(token.allowance(msg.sender, address(this)) >= _amount, "Insufficient Allowance");

            bool tokenTransferSuccess = token.transferFrom(msg.sender, address(this), _amount);
            require(tokenTransferSuccess, "Token transfer failed");
            require(
                msg.value == commissionAmount,
                "Insufficient Ether Balance"
            );
        } else {
            require(msg.value == totalCommission, "Insufficient Ether Balance");
        }
    }

    function cancelTransferToContract(uint256 adId, uint256 _amount) external payable {
        require(msg.sender != admin, "admin can't perform this!");
        require(adId >= 0 && adId <= adCount.current(), "Invalid Ad ID");
        require(ads[adId].buyer == msg.sender || ads[adId].seller == msg.sender);
        require(ads[adId].isProcessing, "Ad process not started yet!");
        require(ads[adId].status == AdStatus.Open, "Ad is not open");

        address tokenAddr = ads[adId].tokenAddr;
        ads[adId].isProcessing = false;
        address payable seller = payable(ads[adId].seller);
        uint256 sellerAmount = ads[adId].sellerAmount;
        uint256 total = sellerAmount.add(ads[adId].commissionAmount);
        uint256 commissionAmount = ads[adId].commissionAmount;

        ads[adId].commissionAmount = 0;
        ads[adId].seller = address(0);
        ads[adId].sellerAmount = 0;
        

        if (tokenAddr != address(0) && isTokenContract(tokenAddr)) {
            IERC20 token = IERC20(tokenAddr);
            uint256 tokenBalance = token.balanceOf(address(this));
            require(tokenBalance >= sellerAmount, "Insufficient Token Balance");

            bool tokenTransferSuccess = token.transfer(seller, _amount);
            require(tokenTransferSuccess, "Token transfer failed");
            seller.transfer(commissionAmount);
        } else {
            seller.transfer(total);
        }
    }

    function releaseCrypto(uint256 adId) external nonReentrant {
        require(msg.sender != admin, "admin can't perform this!");
        require(adId >= 0 && adId <= adCount.current(), "Invalid Ad ID");
        Ad storage ad = ads[adId];
        require(ad.seller == msg.sender, "You are not the seller of this ad");
        require(ad.isProcessing, "Ad is not being processed");

        address tokenAddr = ad.tokenAddr;
        uint256 sellerAmount = ad.sellerAmount;
        address payable buyer = payable(ad.buyer);
        uint256 commissionAmount = ad.commissionAmount;

        if (tokenAddr != address(0)) {
            IERC20 token = IERC20(tokenAddr);
            uint256 contractBalance = token.balanceOf(address(this));
            require(contractBalance >= sellerAmount, "Insufficient contract balance");

            bool tokenTransferSuccess = token.transfer(buyer, sellerAmount);
            require(tokenTransferSuccess, "Token transfer failed");
        } else {
            require(address(this).balance >= sellerAmount, "Insufficient contract balance");
            (bool sent, ) = buyer.call{value: sellerAmount}("");
            require(sent, "Failed to send Ether");
        }

        ad.remainAmount = ad.remainAmount.sub(sellerAmount);
        ad.sellerAmount = 0;
        ad.seller = address(0);
        ad.isProcessing = false;
        payable(admin).transfer(commissionAmount);
        ad.commissionAmount = 0;

        if(ad.remainAmount == 0){
            ad.status = AdStatus.Completed;
        }
    }

    function resolveDispute(uint256 adId) external nonReentrant onlyAdmin {
        require(adId >= 0 && adId <= adCount.current(), "Invalid Ad ID");
        Ad storage ad = ads[adId];
        require(ad.isProcessing, "Ad is not being processed");
        require(assignedAmount[ad.buyer][admin].adId == adId, "Not assigned to admin");
        require(assignedAmount[ad.buyer][admin].adminAmount == ad.sellerAmount, "Amount mismatch");

        address tokenAddr = ad.tokenAddr;
        uint256 adminAmount = assignedAmount[ad.buyer][admin].adminAmount;
        address payable buyer = payable(ad.buyer);
        uint256 commissionAmount = ad.commissionAmount;


        if (tokenAddr != address(0)) {
            IERC20 token = IERC20(tokenAddr);
            uint256 contractBalance = token.balanceOf(address(this));
            require(contractBalance >= adminAmount, "Insufficient contract balance");

            bool tokenTransferSuccess = token.transfer(buyer, adminAmount);
            require(tokenTransferSuccess, "Token transfer failed");
        } else {
            require(address(this).balance >= adminAmount, "Insufficient contract balance");
            (bool sent, ) = buyer.call{value: adminAmount}("");
            require(sent, "Failed to send Ether");
        }

        ad.commissionAmount = 0;
        ad.remainAmount = ad.remainAmount.sub(adminAmount);
        ad.sellerAmount = 0;
        ad.seller = address(0);
        ad.isProcessing = false;
        payable(admin).transfer(commissionAmount);
        
        if(ad.remainAmount == 0){
            ad.status = AdStatus.Completed;
        }
    }

    function cancelDispute(address buyer, uint256 amount, uint256 adId) external onlyAdmin {
        require(
            assignedAmount[buyer][admin].adminAmount == amount && ads[adId].sellerAmount == amount,
            "Invalid Amount"
        );
        require(
            assignedAmount[buyer][admin].adId == adId,
            "Invalid Ad ID"
        );
        assignedAmount[buyer][admin] = AssignedAmount(0, 0);

        Ad storage ad = ads[adId];        
        address tokenAddr = ad.tokenAddr;

        address payable seller = payable(ad.seller);
        uint256 sellerAmount = ad.sellerAmount;
        uint256 total = sellerAmount.add(ad.commissionAmount);
        uint256 commissionAmount = ads[adId].commissionAmount;

        ad.seller = address(0);
        ad.sellerAmount = 0;
        ad.commissionAmount = 0;

        if (tokenAddr != address(0)) {
            IERC20 token = IERC20(tokenAddr);
            uint256 contractBalance = token.balanceOf(address(this));
            require(contractBalance >= amount, "Insufficient contract balance");

            bool tokenTransferSuccess = token.transfer(seller, sellerAmount);
            require(tokenTransferSuccess, "Token transfer failed");
            (bool sent, ) = seller.call{value: commissionAmount}("");
            require(sent, "Failed to send Ether");
        } else {
            require(address(this).balance >= amount, "Insufficient contract balance");
            (bool sent, ) = payable (seller).call{value: total}("");
            require(sent, "Failed to send Ether");
        }
        ad.isProcessing = false;
    }

    function updateMinAmount(uint256 _minAmount) external onlyAdmin {
        minAmount = _minAmount;
    }

    function updateMaxAmount(uint256 _maxAmount) external onlyAdmin {
        maxAmount = _maxAmount;
    }

    function getAssignedAmount(address buyer) external view returns (uint256) {
        return assignedAmount[buyer][admin].adminAmount;
    }

    function getAssignedAdID(address buyer) external view returns (uint256) {
        return assignedAmount[buyer][admin].adId;
    }

    function getAdCount() external view returns (uint256) {
        return adCount.current();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.18;

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
    event Approval(address indexed owner, address indexed spender, uint256 value);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.18;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.18;

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}