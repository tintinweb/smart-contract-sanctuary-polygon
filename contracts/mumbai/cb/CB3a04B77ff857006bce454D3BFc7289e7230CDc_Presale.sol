// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../libraries/PriceConverter.sol";
import "../token/interfaces/IERC20Custom.sol";

contract Presale is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    struct PresaleData {
        uint256 startingTime;
        uint256 usdPrice;
        uint256 minimumUSDPurchase;
        uint256 maximumPresaleAmount;
    }
    struct PresalePaymentTokenData {
        bool available;
        address aggregatorAddress;
    }

    event TokenPresold(
        address indexed to,
        address indexed paymentTokenAddress,
        uint256 amount,
        uint256 paymentTokenamount
    );
    event PresaleRoundUpdated(
        uint256 indexed presaleRound,
        uint256 startingTime,
        uint256 usdPrice,
        uint256 minimumUSDPurchase,
        uint256 maximumPresaleAmount
    );
    event PresaleReceiverUpdated(address receiverAddress);
    event PresalePaymentTokenUpdated(
        address tokenAddress,
        bool tokenAvailability,
        address aggregatorAddress
    );
    event PresaleTokenUpdated(address tokenAddress);

    Counters.Counter public totalPresaleRound;
    address public tokenAddress;
    address payable public presaleReceiver;

    // Mapping `presaleRound` to its data details
    mapping(uint256 => PresaleData) public presaleDetailsMapping;
    mapping(uint256 => uint256) public presaleAmountByRoundMapping;
    mapping(address => PresalePaymentTokenData)
        public presalePaymentTokenMapping;

    error presaleRoundClosed();
    error presaleTokenNotAvailable();
    error presaleNativeTokenPaymentNotSufficient();
    error presaleStartingTimeInvalid();
    error presaleUSDPriceInvalid();
    error presaleMimumumUSDPurchaseInvalid();
    error presaleMaximumPresaleAmountInvalid();
    error presaleUSDPurchaseNotSufficient();
    error presaleAmountOverdemand();
    error presaleNonZeroAddressInvalid();

    modifier onlyNonZeroAddress(address _address) {
        if (_address == address(0)) revert presaleNonZeroAddressInvalid();
        _;
    }

    constructor(address _tokenAddress, address payable _presaleReceiver) {
        tokenAddress = _tokenAddress;
        presaleReceiver = _presaleReceiver;
    }

    /**
     * Get total amount of presale round
     */
    function getTotalPresaleRound() public view returns (uint256) {
        return totalPresaleRound.current();
    }

    /**
     * Get presale total amount By presale round
     *
     * @dev _presaleRound - The presale round chosen
     */
    function getPresaleAmountByRound(uint256 _presaleRound)
        public
        view
        returns (uint256)
    {
        return presaleAmountByRoundMapping[_presaleRound];
    }

    /**
     * Get total amount of presale from all rounds
     */
    function getTotalPresaleAmount() public view returns (uint256) {
        uint256 totalPresale = 0;
        for (
            uint256 presaleRound = 0;
            presaleRound < totalPresaleRound.current();
            presaleRound++
        ) {
            totalPresale += presaleAmountByRoundMapping[presaleRound];
        }

        return totalPresale;
    }

    /**
     * Get Current Presale Round
     */
    function getCurrentPresaleRound() public view returns (uint256) {
        for (
            uint256 presaleRound = totalPresaleRound.current() - 1;
            presaleRound > 0;
            presaleRound--
        ) {
            if (
                presaleDetailsMapping[presaleRound].startingTime <=
                block.timestamp
            ) {
                return presaleRound;
            }
        }

        return 0;
    }

    /**
     * Getting the Current Presale Details, including:
     * - Starting Time
     * - USD Price
     * - Minimum USD Purchase
     * - Maximum Presale Amount
     */
    function getCurrentPresaleDetails()
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 currentPresaleRound = getCurrentPresaleRound();
        return (
            presaleDetailsMapping[currentPresaleRound].startingTime,
            presaleDetailsMapping[currentPresaleRound].usdPrice,
            presaleDetailsMapping[currentPresaleRound].minimumUSDPurchase,
            presaleDetailsMapping[currentPresaleRound].maximumPresaleAmount
        );
    }

    /**
     * Execute the Presale of ALPS Token in exchange of other token
     *
     * @dev _paymentTokenAddress - Address of the token use to pay (address 0 is for native token)
     * @dev _amount - Amount denominated in the `paymentTokenAddress` being paid
     */
    function presaleTokens(address _paymentTokenAddress, uint256 _amount)
        public
        payable
        nonReentrant
    {
        (
            uint256 currentPresaleStartingTime,
            uint256 currentPresalePrice,
            uint256 currentPresaleMinimumUSDPurchase,
            uint256 currentPresaleMaximumPresaleAmount
        ) = getCurrentPresaleDetails();

        // Check whether the presale round is still open
        require(block.timestamp >= currentPresaleStartingTime, "Presale:");

        // Check whether token is valid
        if (!presalePaymentTokenMapping[_paymentTokenAddress].available)
            revert presaleTokenNotAvailable();

        // Convert the token with Chainlink Price Feed
        IERC20Custom token = IERC20Custom(tokenAddress);
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            presalePaymentTokenMapping[_paymentTokenAddress].aggregatorAddress
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 presaleUSDAmount = SafeMath.mul(
            uint256(
                PriceConverter.scalePrice(
                    price,
                    priceFeed.decimals(),
                    token.decimals()
                )
            ),
            _amount
        );

        if (
            uint256(
                PriceConverter.scalePrice(int256(presaleUSDAmount), 18, 0)
            ) < currentPresaleMinimumUSDPurchase
        ) revert presaleUSDPurchaseNotSufficient();

        uint256 presaleAmount = uint256(
            PriceConverter.scalePrice(
                int256(SafeMath.div(presaleUSDAmount, currentPresalePrice)),
                0,
                18
            )
        );

        if (
            presaleAmount >
            currentPresaleMaximumPresaleAmount -
                presaleAmountByRoundMapping[getCurrentPresaleRound()]
        ) revert presaleAmountOverdemand();

        presaleAmountByRoundMapping[getCurrentPresaleRound()] += presaleAmount;

        // Receive the payment token and transfer it to another address
        if (_paymentTokenAddress == address(0)) {
            if (msg.value < _amount) {
                revert presaleNativeTokenPaymentNotSufficient();
            } else {
                presaleReceiver.transfer(_amount);

                // in case you deployed the contract with more ether than required,
                // transfer the remaining ether back to yourself
                payable(msg.sender).transfer(address(this).balance);
            }
        } else {
            IERC20 paymentToken = IERC20(_paymentTokenAddress);
            paymentToken.transferFrom(msg.sender, presaleReceiver, _amount);
        }

        // Send ALPS token to `msg.sender`
        token.mint(msg.sender, presaleAmount);
        emit TokenPresold(
            msg.sender,
            _paymentTokenAddress,
            presaleAmount,
            _amount
        );
    }

    /**
     * Set new Presale Receiver Address
     *
     * @dev _newPresaleReceiver - Address that'll receive the presale payment token
     */
    function setPresaleReceiver(address payable _newPresaleReceiver)
        public
        onlyOwner
    {
        presaleReceiver = _newPresaleReceiver;

        emit PresaleReceiverUpdated(_newPresaleReceiver);
    }

    /**
     * Set new Presale Token Address
     *
     * @dev _newTokenAddress - Address of token that'll be presaled
     */
    function setPresaleTokenAddress(address _newTokenAddress)
        public
        onlyOwner
        onlyNonZeroAddress(_newTokenAddress)
    {
        tokenAddress = _newTokenAddress;

        emit PresaleTokenUpdated(_newTokenAddress);
    }

    /**
     * Set Presale Payment Token Info
     *
     * @dev _tokenAddress - Token Address use to purchase Presale
     * @dev _tokenAvailability - Indication whether Token Address can be used for Presale
     * @dev _aggregatorAddress - Chainlink's Aggregator Address to determine the USD price (for `presaleTokens`)
     */
    function setPresalePaymentToken(
        address _tokenAddress,
        bool _tokenAvailability,
        address _aggregatorAddress
    ) public onlyOwner onlyNonZeroAddress(_aggregatorAddress) {
        presalePaymentTokenMapping[_tokenAddress]
            .available = _tokenAvailability;
        presalePaymentTokenMapping[_tokenAddress]
            .aggregatorAddress = _aggregatorAddress;

        emit PresalePaymentTokenUpdated(
            _tokenAddress,
            _tokenAvailability,
            _aggregatorAddress
        );
    }

    /**
     * Creating/Updating a presale round information
     *
     * @dev _presaleRound - The presale round chosen
     * @dev _startingTime - The starting Presale time
     * @dev _usdPrice - The USD Price of the Token in certain Presale Round
     * @dev _minimumUSDPurchase - The minimum USD amount to purchase the token
     * @dev _maximumPresaleAmount - The maximum amount of token available for a presale round
     */
    function setPresaleRound(
        uint256 _presaleRound,
        uint256 _startingTime,
        uint256 _usdPrice,
        uint256 _minimumUSDPurchase,
        uint256 _maximumPresaleAmount
    ) public onlyOwner {
        uint256 presaleStartingTime = presaleDetailsMapping[_presaleRound]
            .startingTime;
        uint256 presaleUSDPrice = presaleDetailsMapping[_presaleRound].usdPrice;
        uint256 presaleMinimumUSDPurchase = presaleDetailsMapping[_presaleRound]
            .minimumUSDPurchase;
        uint256 presaleMaximumPresaleAmount = presaleDetailsMapping[
            _presaleRound
        ].maximumPresaleAmount;

        // Increment the total round counter when new presale is created
        if (
            presaleStartingTime == 0 &&
            presaleUSDPrice == 0 &&
            presaleMinimumUSDPurchase == 0 &&
            presaleMaximumPresaleAmount == 0
        ) totalPresaleRound.increment();

        // Starting time has to be:
        // - larger than zero
        // - larger than previous round starting time
        if (
            _startingTime == 0 ||
            (_presaleRound != 0 &&
                _startingTime <
                presaleDetailsMapping[_presaleRound - 1].startingTime)
        ) revert presaleStartingTimeInvalid();

        // These values given must be larger than zero
        if (_usdPrice == 0) revert presaleUSDPriceInvalid();
        if (_minimumUSDPurchase == 0) revert presaleMimumumUSDPurchaseInvalid();
        if (_maximumPresaleAmount == 0)
            revert presaleMaximumPresaleAmountInvalid();

        presaleDetailsMapping[_presaleRound].startingTime = _startingTime;
        presaleDetailsMapping[_presaleRound].usdPrice = _usdPrice;
        presaleDetailsMapping[_presaleRound]
            .minimumUSDPurchase = _minimumUSDPurchase;
        presaleDetailsMapping[_presaleRound]
            .maximumPresaleAmount = _maximumPresaleAmount;

        emit PresaleRoundUpdated(
            _presaleRound,
            _startingTime,
            _usdPrice,
            _minimumUSDPurchase,
            _maximumPresaleAmount
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Custom is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function cap() external view returns (uint256);

    function setCap(uint256 _newCap) external;

    function increaseCap(uint256 _increaseCap) external;

    function decreaseCap(uint256 _decreaseCap) external;

    function pause() external;

    function unpause() external;

    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.11;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getDerivedPrice(
        address _base,
        address _quote,
        uint8 _decimals
    ) public view returns (int256) {
        require(
            _decimals > uint8(0) && _decimals <= uint8(18),
            "Invalid _decimals"
        );
        int256 decimals = int256(10**uint256(_decimals));
        (, int256 basePrice, , , ) = AggregatorV3Interface(_base)
            .latestRoundData();
        uint8 baseDecimals = AggregatorV3Interface(_base).decimals();
        basePrice = scalePrice(basePrice, baseDecimals, _decimals);

        (, int256 quotePrice, , , ) = AggregatorV3Interface(_quote)
            .latestRoundData();
        uint8 quoteDecimals = AggregatorV3Interface(_quote).decimals();
        quotePrice = scalePrice(quotePrice, quoteDecimals, _decimals);

        return (basePrice * decimals) / quotePrice;
    }

    function scalePrice(
        int256 _price,
        uint8 _priceDecimals,
        uint8 _decimals
    ) internal pure returns (int256) {
        if (_priceDecimals < _decimals) {
            return _price * int256(10**uint256(_decimals - _priceDecimals));
        } else if (_priceDecimals > _decimals) {
            return _price / int256(10**uint256(_priceDecimals - _decimals));
        }
        return _price;
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}