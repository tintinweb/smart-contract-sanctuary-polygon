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
pragma solidity ^0.8.18;

import "./Counters.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

contract DP2P_V3 is ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    address public admin;
    uint256 public minAmount = 0.001 ether;
    uint256 public maxAmount = 200 ether;
    uint256 public commissionRate = 2;
    uint256 public totalCommissions = 0;

    enum AdStatus {
        Open,
        Cancelled,
        Completed
    }

    struct AdsInfo {
        address seller;
        address token;
        uint256 amount;
        AdStatus status;
        uint256 remainAmount;
        uint256 commissionAmount;
    }

    struct AssignedAmount {
        uint256 adId;
        uint256 amount;
    }

    mapping(string => address) public tokenAddresses;
    mapping(uint256 => AdsInfo) public ads;
    mapping(uint256 => address) private canceledAds;
    mapping(address => mapping(uint256 => bool)) private canceledBySeller;
    mapping(address => mapping(address => AssignedAmount))
        public assignedAmounts;

    Counters.Counter private adCount;

    event AdPosted(
        address indexed seller,
        uint256 indexed adId,
        uint256 amount
    );
    event AdCanceled(address indexed seller, uint256 indexed adId);
    event AdUpdated(
        uint256 indexed _adId,
        uint256 indexed oldAmount,
        uint256 indexed _newAmount
    );

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not authorized");
        _;
    }

    modifier validInputs(
        uint256 _amount,
        uint256 _adId,
        address _recipient
    ) {
        require(_recipient != address(0), "Invalid Recipient Address");
        require(ads[_adId].seller != address(0), "Invalid Ad ID");
        require(_amount > 0, "Invalid Amount");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    // Utility function to check if the given address is a token contract
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

    function setTokenAddress(
        string memory tokenName,
        address _token
    ) external onlyAdmin {
        require(isTokenContract(_token), "Not a valid token address");
        tokenAddresses[tokenName] = _token;
    }

    function calculateCommission(
        uint256 amount
    ) public view returns (uint256[2] memory) {
        uint256 commissionAmount = amount.mul(commissionRate).div(1000);
        uint256 totalAmount = amount.add(commissionAmount);
        return [totalAmount, commissionAmount];
    }

    function postAd(uint256 amount, string memory tokenName) external payable {
        require(msg.sender != admin, "Admin cannot create an Ad");
        require(amount > 0, "Amount must be greater than zero");
        require(
            amount >= minAmount && amount <= maxAmount,
            "Amount not in range"
        );

        // uint256 commissionAmount = amount.mul(commissionRate).div(1000);

        // totalCommissions = totalCommissions.add(commissionAmount);

        address _token = tokenAddresses[tokenName];

        uint256 adId = adCount.current();
        adCount.increment();
        ads[adId].seller = msg.sender;
        ads[adId].amount = amount;
        ads[adId].status = AdStatus.Open;
        ads[adId].remainAmount = amount;

        if (_token != address(0) && isTokenContract(_token)) {
            IERC20 token = IERC20(_token);
            require(
                token.balanceOf(msg.sender) >= amount,
                "Insufficient Token Balance"
            );
            require(
                token.allowance(msg.sender, address(this)) >= amount,
                "Insufficient Allowance"
            );
            require(
                token.transferFrom(msg.sender, address(this), amount),
                "Token transfer failed"
            );
            uint256 commission = msg.value;
            ads[adId].token = _token;
            ads[adId].commissionAmount = commission;
            totalCommissions = totalCommissions.add(commission);
            // require(
            //     msg.value == commissionAmount,
            //     "Insufficient Ether Balance"
            // );
        } else {
            uint256[2] memory totalAmount = calculateCommission(amount);
            require(msg.value == totalAmount[0], "Insufficient Ether Balance");
            ads[adId].commissionAmount = totalAmount[1];
            totalCommissions = totalCommissions.add(totalAmount[1]);
        }

        emit AdPosted(msg.sender, adId, amount);
    }

    function updatePostAd(
        uint256 adId,
        uint256 newAmount,
        string memory tokenName
    ) external payable {
        address _token = tokenAddresses[tokenName];
        AdsInfo storage ad = ads[adId];
        require(ad.seller == msg.sender, "Not the seller of this ad");
        require(
            newAmount >= minAmount && newAmount <= maxAmount,
            "Amount not in range"
        );

        // uint256 commissionAmount = newAmount.mul(commissionRate).div(1000);
        // uint256 totalAmount = newAmount.add(commissionAmount);
        // totalCommissions = totalCommissions.add(commissionAmount);

        if (isTokenContract(_token)) {
            IERC20 token = IERC20(_token);
            require(
                token.balanceOf(msg.sender) >= newAmount,
                "Insufficient Token Balance"
            );
            token.transferFrom(msg.sender, address(this), newAmount);
            // require(
            //     msg.value == commissionAmount,
            //     "Insufficient Ether Balance"
            // );
            uint256 commission = msg.value;
            totalCommissions = totalCommissions.add(commission);
            ads[adId].commissionAmount = ads[adId].commissionAmount.add(commission);
        } else {
            uint256[2] memory totalAmount = calculateCommission(newAmount);
            require(msg.value == totalAmount[0], "Insufficient Ether Balance");
            ad.commissionAmount = ad.commissionAmount.add(totalAmount[1]);
            totalCommissions = totalCommissions.add(totalAmount[1]);
        }

        uint256 oldAmount = ad.amount;
        uint256 newTotal = oldAmount.add(newAmount);
        // uint256 oldCommission = ad.commissionAmount;
        // uint256 newTotalCommission = oldCommission.add(commissionAmount);
        ad.amount = newTotal;
        ad.remainAmount = newTotal;
        // ad.commissionAmount = newTotalCommission;

        emit AdUpdated(adId, oldAmount, newAmount);
    }

    function transferFunds(
        uint256 amount,
        uint256 adId,
        address recipient
    ) external payable nonReentrant validInputs(amount, adId, recipient) {
        require(ads[adId].seller == msg.sender, "Not the seller of this ad");
        require(
            ads[adId].amount >= amount,
            "Insufficient balance for transfer"
        );

        address _token = ads[adId].token;

        if (_token != address(0) && isTokenContract(_token)) {
            IERC20 token = IERC20(_token);
            token.transfer(recipient, amount);
        } else {
            (bool sent, ) = recipient.call{value: amount}("");
            require(sent, "Failed to send Ether");
        }

        ads[adId].remainAmount = ads[adId].remainAmount.sub(amount);

        if (ads[adId].remainAmount == 0) {
            ads[adId].status = AdStatus.Completed;
        }
    }

    function cancelAd(uint256 adId) external payable {
        AdsInfo storage ad = ads[adId];
        require(adId >= 0 && adId <= adCount.current(), "Invalid Ad ID");
        require(
            !canceledBySeller[msg.sender][adId],
            "Ad already canceled by this seller"
        );
        require(msg.sender == ad.seller, "Not the ad seller");
        require(ad.status == AdStatus.Open, "Ad already canceled");

        ad.status = AdStatus.Cancelled;

        address payable seller = payable(ad.seller);

        address _token = ad.token;
        if (ad.remainAmount == ad.amount) {
            if (_token != address(0)) {
                IERC20 token = IERC20(_token);
                token.transfer(seller, ad.amount);
                seller.transfer(ad.commissionAmount);
                ad.commissionAmount = 0;
            } else {
                seller.transfer(ad.amount.add(ad.commissionAmount));
                ad.commissionAmount = 0;
            }
            totalCommissions = totalCommissions.sub(ad.commissionAmount);
        } else {
            if (_token != address(0)) {
                IERC20 token = IERC20(_token);
                token.transfer(seller, ad.remainAmount);
            } else {
                seller.transfer(ad.remainAmount);
            }
        }
        ad.amount = 0;
        ad.remainAmount = 0;
        canceledAds[adId] = msg.sender;
        canceledBySeller[msg.sender][adId] = true;

        emit AdCanceled(ad.seller, adId);
    }

    function resolveDispute(
        uint256 amount,
        uint256 adId,
        address recipient
    )
        external
        payable
        nonReentrant
        onlyAdmin
        validInputs(amount, adId, recipient)
    {
        require(
            assignedAmounts[recipient][admin].amount >= amount,
            "Insufficient balance for transfer"
        );
        require(
            assignedAmounts[recipient][admin].adId == adId,
            "Invalid Ad ID"
        );
        address _token = ads[adId].token;

        if (_token != address(0) && isTokenContract(_token)) {
            IERC20 token = IERC20(_token);
            require(token.transfer(recipient, amount), "Token transfer failed");
        } else {
            (bool sent, ) = recipient.call{value: amount}("");
            require(sent, "Failed to send Ether");
        }

        assignedAmounts[recipient][admin] = AssignedAmount(0, 0);
        ads[adId].remainAmount = ads[adId].remainAmount.sub(amount);

        if (ads[adId].remainAmount == 0) {
            ads[adId].status = AdStatus.Completed;
        }
    }

    function cancelDispute(
        address recipient,
        uint256 amount,
        uint256 adId
    ) external onlyAdmin {
        require(
            assignedAmounts[recipient][admin].amount >= amount,
            "Insufficient balance for transfer"
        );
        require(
            assignedAmounts[recipient][admin].adId == adId,
            "Invalid Ad ID"
        );
        assignedAmounts[recipient][admin] = AssignedAmount(0, 0);
    }

    function setAssignedAmountToAdmin(
        uint256 adId,
        address recipient,
        uint256 amount
    ) external {
        require(ads[adId].seller == msg.sender, "Not the seller of this ad");
        require(
            adId >= 0 &&
                adId <= adCount.current() &&
                amount > 0 &&
                recipient != address(0),
            "Invalid Inputs"
        );
        assignedAmounts[recipient][admin] = AssignedAmount(adId, amount);
    }

    function calculateWithdrawFunds() external view returns (uint256) {
        uint256 totalCommission = 0;

        for (uint256 adId = 0; adId < adCount.current(); adId++) {
            if (
                ads[adId].status == AdStatus.Completed ||
                ads[adId].status == AdStatus.Cancelled
            ) {
                uint256 commissionAmount = ads[adId].commissionAmount;

                totalCommission += commissionAmount;
            }
        }

        return totalCommission;
    }

    function withdrawFunds() external onlyAdmin {
        uint256 totalCommission = 0;

        for (uint256 adId = 0; adId < adCount.current(); adId++) {
            if (
                ads[adId].status == AdStatus.Completed ||
                ads[adId].status == AdStatus.Cancelled
            ) {
                uint256 commissionAmount = ads[adId].commissionAmount;
                ads[adId].commissionAmount = 0;

                totalCommission += commissionAmount;
            }
        }
        payable(admin).transfer(totalCommission);
    }

    function updateMinAmount(uint256 _minAmount) external onlyAdmin {
        minAmount = _minAmount;
    }

    function updateMaxAmount(uint256 _maxAmount) external onlyAdmin {
        maxAmount = _maxAmount;
    }

    function getAssignedAmount(
        address recipient
    ) external view returns (uint256) {
        return assignedAmounts[recipient][admin].amount;
    }

    function getAssignedAdID(
        address recipient
    ) external view returns (uint256) {
        return assignedAmounts[recipient][admin].adId;
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