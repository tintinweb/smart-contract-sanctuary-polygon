// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

library Enterprise {
    uint256 constant MAX_LENGTH = 100;

    enum CompanyType {
        LLC,
        CC,
        SC,
        NP,
        OT
    }

    struct Info {
        string logoImg;
        bool isRG;
        CompanyType companyType;
        string address1;
        string address2;
        string country;
        string zip;
        string state;
        string city;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

/**
 * ██╗    ██╗ ██████╗ ██████╗ ██████╗     ███████╗███╗   ██╗████████╗███████╗██████╗ ██████╗ ██████╗ ██╗███████╗███████╗
 * ██║    ██║██╔═══██╗██╔══██╗██╔══██╗    ██╔════╝████╗  ██║╚══██╔══╝██╔════╝██╔══██╗██╔══██╗██╔══██╗██║██╔════╝██╔════╝
 * ██║ █╗ ██║██║   ██║██████╔╝██║  ██║    █████╗  ██╔██╗ ██║   ██║   █████╗  ██████╔╝██████╔╝██████╔╝██║███████╗█████╗
 * ██║███╗██║██║   ██║██╔══██╗██║  ██║    ██╔══╝  ██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗██╔═══╝ ██╔══██╗██║╚════██║██╔══╝
 * ╚███╔███╔╝╚██████╔╝██║  ██║██████╔╝    ███████╗██║ ╚████║   ██║   ███████╗██║  ██║██║     ██║  ██║██║███████║███████╗
 * ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═════╝     ╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝╚═╝╚══════╝╚══════╝
 **/

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./libs/Enterprise.sol";

contract WorldEnterprise is IERC20 {
    using Counters for Counters.Counter;
    using Math for uint256;

    enum ProposalStatus {
        NONE,
        ACTIVE,
        CANCELLED,
        FAILED,
        PASSED
    }

    enum OrderStatus {
        NONE,
        ACTIVE,
        CANCELLED,
        CLOSED
    }

    enum OrderType {
        BUY,
        SELL
    }

    struct Proposal {
        uint256 id;
        address owner;
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
        uint256 yes;
        uint256 no;
        ProposalStatus status;
    }

    struct Order {
        uint256 id;
        address owner;
        uint256 amount;
        uint256 price;
        OrderType orderType;
        OrderStatus status;
    }

    Counters.Counter public proposalIndex;
    Counters.Counter public orderIndex;

    uint8 public decimals;

    string public metadata;

    // proposal delay time
    uint256 public proposalDelayTime;

    Enterprise.Info public info;

    /**
     * proposal list
     * @dev mapping(proposal id => Proposal)
     **/
    mapping(uint256 => Proposal) public proposals;

    /**
     * proposal indices of proposer
     * @dev mapping(proposer address => indices)
     * */
    mapping(address => uint256[]) public proposalIndices;

    /**
     * vote info list
     * @dev mapping(proposal id => poroposer => status)
     * */
    mapping(uint256 => mapping(address => bool)) public votes;

    /**
     * order list
     * @dev mapping(order id => Order)
     **/
    mapping(uint256 => Order) public orders;

    /**
     * order indices by owner
     * @dev mapping(owner => indices)
     * */
    mapping(address => uint256[]) public orderIndices;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 private _tokenHolders;

    string private _name;
    string private _symbol;

    event JoinWorldEnterprise(
        uint256 proposalIndex,
        address indexed proposer,
        uint256 amount,
        uint256 startTime,
        uint256 endTime
    );
    event VoteYes(address account, uint256 proposalIndex);
    event VoteNo(address account, uint256 proposalIndex);
    event ExecutePassed(
        uint256 proposalIndex,
        address proposer,
        uint256 amount
    );
    event ExecuteFailed(uint256 proposalIndex);
    event CreateBuyOrder(
        uint256 orderIndex,
        address indexed owner,
        uint256 amount,
        uint256 price
    );
    event CreateSellOrder(
        uint256 orderIndex,
        address indexed owner,
        uint256 amount,
        uint256 price
    );
    event CloseOrder(uint256 orderId);
    event CancelOrder(uint256 orderId);

    modifier checkInfo(Enterprise.Info memory info_) {
        require(
            bytes(info_.logoImg).length < Enterprise.MAX_LENGTH,
            "WorldEnterpriseFactory: Logo image url should be less than the max length"
        );
        require(
            bytes(info_.address1).length < Enterprise.MAX_LENGTH,
            "WorldEnterpriseFactory: Address should be less than the max length"
        );
        require(
            bytes(info_.address2).length < Enterprise.MAX_LENGTH,
            "WorldEnterpriseFactory: Address should be less than the max length"
        );
        require(
            bytes(info_.country).length < Enterprise.MAX_LENGTH,
            "WorldEnterpriseFactory: Country should be less than the max length"
        );
        require(
            bytes(info.zip).length < Enterprise.MAX_LENGTH,
            "WorldEnterpriseFactory: Zip should be less than the max length"
        );
        require(
            bytes(info_.state).length < Enterprise.MAX_LENGTH,
            "WorldEnterpriseFactory: State should be less than the max length"
        );
        require(
            bytes(info_.city).length < Enterprise.MAX_LENGTH,
            "WorldEnterpriseFactory: City should be less than the max length"
        );
        _;
    }

    constructor(
        address[] memory users,
        uint256[] memory shares,
        string memory name_,
        string memory symbol_,
        string memory metadata_,
        Enterprise.Info memory info_
    ) checkInfo(info_) {
        require(
            users.length > 0,
            "WorldEnterprise: Users length should be greater than the zero"
        );
        require(
            users.length == shares.length,
            "WorldEnterprise: Shares length should be equal with the users length"
        );
        require(
            bytes(name_).length > 0,
            "WorldEnterprise: Name should not be as empty string"
        );
        require(
            bytes(symbol_).length > 0,
            "WorldEnterprise: Symbol should not be as empty string"
        );
        require(
            bytes(metadata_).length > 0,
            "WorldEnterprise: Metadata should not be as empty string"
        );
        _name = name_;
        _symbol = symbol_;
        metadata = metadata_;
        info = info_;

        decimals = 18;
        proposalDelayTime = 60 * 60 * 24 * 7 * 2; // 2 weeks

        for (uint256 i; i < users.length; i++) {
            _mint(users[i], shares[i]);
        }
    }

    function voteThreshold() public view returns (uint256) {
        return _tokenHolders.min(5);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @param account proposer
     * @return last propose indice of proposer
     *
     **/
    function lastProposalIndex(address account) public view returns (uint256) {
        if (proposalIndices[account].length == 0) {
            return 0;
        }

        uint256 _lastIndex = proposalIndices[account].length - 1;
        return proposalIndices[account][_lastIndex];
    }

    /**
     * @param account proposer
     * @return last propose of proposer
     *
     **/
    function lastProposal(address account)
        public
        view
        returns (Proposal memory)
    {
        uint256 _lastProposalIndex = lastProposalIndex(account);
        Proposal memory _proposal = proposals[_lastProposalIndex];
        return _proposal;
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount)
        public
        override
        returns (bool)
    {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        address owner = msg.sender;
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        address owner = msg.sender;
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "WorldEnterprise: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @param amount propose amount
     * @dev create a propose to join world enterprise
     *
     **/
    function joinWorldEnterprise(uint256 amount) external {
        Proposal memory _lastProposal = lastProposal(msg.sender);
        require(
            amount > 0,
            "WorldEnterprise: Amount should be greater than the zero"
        );
        require(
            _lastProposal.status != ProposalStatus.ACTIVE,
            "WorldEnterprise: The last propose is not finished"
        );

        uint256 _proposalIndex = proposalIndex.current();
        uint256 _startTime = block.timestamp;
        uint256 _endTime = _startTime + proposalDelayTime;

        Proposal memory _proposal = Proposal({
            id: _proposalIndex,
            owner: msg.sender,
            amount: amount,
            startTime: _startTime,
            endTime: _endTime,
            yes: 0,
            no: 0,
            status: ProposalStatus.ACTIVE
        });

        proposals[_proposalIndex] = _proposal;
        proposalIndices[msg.sender].push(_proposalIndex);

        proposalIndex.increment();

        emit JoinWorldEnterprise(
            _proposalIndex,
            msg.sender,
            amount,
            _startTime,
            _endTime
        );
    }

    /**
     * @param _proposalIndex proposal index
     * @param _status vote status
     * @dev vote proposal
     **/
    function vote(uint256 _proposalIndex, bool _status) external {
        Proposal storage _proposal = proposals[_proposalIndex];

        require(
            _proposal.status == ProposalStatus.ACTIVE,
            "WorldEnterprise: Proposal is not active"
        );
        require(
            block.timestamp < _proposal.endTime,
            "WorldEnterprise: Time over to vote for this proposal"
        );
        require(
            balanceOf(msg.sender) > 0,
            "WorldEnterprise: Only token owner can vote"
        );
        require(
            !votes[_proposalIndex][msg.sender],
            "WorldEnterprise: You've already voted for this proposal"
        );

        if (_status) {
            _proposal.yes++;
        } else {
            _proposal.no++;
        }

        votes[_proposalIndex][msg.sender] = true;

        if (_status) {
            emit VoteYes(msg.sender, _proposalIndex);
        } else {
            emit VoteNo(msg.sender, _proposalIndex);
        }
    }

    /**
     * @param _proposalIndex proposal index
     * @dev execute proposal
     **/
    function execute(uint256 _proposalIndex) external {
        Proposal storage _proposal = proposals[_proposalIndex];

        require(
            _proposal.status == ProposalStatus.ACTIVE,
            "WorldEnterprise: Proposal is not active"
        );
        require(
            block.timestamp >= _proposal.endTime,
            "WorldEnterprise: You can execute after the end time"
        );

        uint256 _voteThreshold = voteThreshold();

        if (_proposal.no < _proposal.yes && _voteThreshold <= _proposal.yes) {
            _proposal.status = ProposalStatus.PASSED;
            _mint(_proposal.owner, _proposal.amount);
            emit ExecutePassed(
                _proposalIndex,
                _proposal.owner,
                _proposal.amount
            );
        } else {
            _proposal.status = ProposalStatus.FAILED;
            emit ExecuteFailed(_proposalIndex);
        }
    }

    /**
     * @param amount token amount
     * @param price price
     * @dev create buy order
     **/
    function createBuyOrder(uint256 amount, uint256 price) external payable {
        require(
            amount > 0,
            "WorldEnterprise: Amount should be greater than the zero"
        );
        require(
            price > 0,
            "WorldEnterprise: Price should be greater than the zero"
        );
        require(
            msg.value == price,
            "WorldEnterprise: Deposit ETH as much as price"
        );

        uint256 _orderIndex = orderIndex.current();
        Order memory _order = Order({
            id: _orderIndex,
            owner: msg.sender,
            amount: amount,
            price: price,
            orderType: OrderType.BUY,
            status: OrderStatus.ACTIVE
        });

        orders[_orderIndex] = _order;

        orderIndices[msg.sender].push(_orderIndex);

        orderIndex.increment();

        emit CreateBuyOrder(_orderIndex, msg.sender, amount, price);
    }

    /**
     * @param amount token amount
     * @param price price
     * @dev create buy order
     **/
    function createSellOrder(uint256 amount, uint256 price) external {
        require(
            amount > 0,
            "WorldEnterprise: Amount should be greater than the zero"
        );
        require(
            price > 0,
            "WorldEnterprise: Price should be greater than the zero"
        );
        require(
            balanceOf(msg.sender) >= amount,
            "WorldEnterprise: Your token balance is not enough"
        );
        require(
            allowance(msg.sender, address(this)) >= amount,
            "WorldEnterprise: Token allowance is not enough"
        );
        _spendAllowance(msg.sender, address(this), amount);
        _transfer(msg.sender, address(this), amount);

        uint256 _orderIndex = orderIndex.current();
        Order memory _order = Order({
            id: _orderIndex,
            owner: msg.sender,
            amount: amount,
            price: price,
            orderType: OrderType.SELL,
            status: OrderStatus.ACTIVE
        });

        orders[_orderIndex] = _order;

        orderIndices[msg.sender].push(_orderIndex);

        orderIndex.increment();

        emit CreateSellOrder(_orderIndex, msg.sender, amount, price);
    }

    /**
     * @param orderId order id
     * @dev close order
     **/
    function closeOrder(uint256 orderId) external payable {
        Order storage _order = orders[orderId];
        require(
            _order.status == OrderStatus.ACTIVE,
            "WorldEnterprise: Order is not active"
        );

        if (_order.orderType == OrderType.BUY) {
            require(
                balanceOf(msg.sender) >= _order.amount,
                "WorldEnterprise: You have not enough ERC20 token"
            );
            require(
                allowance(msg.sender, address(this)) >= _order.amount,
                "WorldEnterprise: Allownce is not enough to transfer"
            );

            _spendAllowance(msg.sender, address(this), _order.amount);
            _transfer(msg.sender, _order.owner, _order.amount);

            (bool success, ) = (msg.sender).call{value: _order.price}("");
            require(success, "WorldEnterprise: Withdraw native token error");
        } else if (_order.orderType == OrderType.SELL) {
            require(
                msg.value == _order.price,
                "WorldEnterprise: ETH is not fair to close"
            );
            require(
                balanceOf(address(this)) >= _order.amount,
                "WorldEnterprise: There is not enough token to sell"
            );

            _transfer(address(this), msg.sender, _order.amount);

            (bool success, ) = (_order.owner).call{value: _order.price}("");
            require(success, "WorldEnterprise: Withdraw native token error");
        }

        _order.status = OrderStatus.CLOSED;

        emit CloseOrder(orderId);
    }

    /**
     * @param orderId order id
     * @dev cancel order
     **/
    function cancelOrder(uint256 orderId) external {
        Order storage _order = orders[orderId];

        require(
            _order.status == OrderStatus.ACTIVE,
            "WorldEnterprise: Order is not active"
        );

        if (_order.orderType == OrderType.BUY) {
            (bool success, ) = (_order.owner).call{value: _order.price}("");
            require(success, "WorldEnterprise: Withdraw native token error");
        } else if (_order.orderType == OrderType.SELL) {
            require(
                balanceOf(address(this)) >= _order.amount,
                "WorldEnterprise: There is not enought ERC20 token to withdraw"
            );
            require(
                transfer(_order.owner, _order.amount),
                "WorldEnterprise: Withdraw ERC20 token failed"
            );
        }

        _order.status = OrderStatus.CANCELLED;

        emit CancelOrder(orderId);
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(
            from != address(0),
            "WorldEnterprise: transfer from the zero address"
        );
        require(
            to != address(0),
            "WorldEnterprise: transfer to the zero address"
        );

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "WorldEnterprise: transfer amount exceeds balance"
        );

        uint256 _prevToBalance = _balances[to];

        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        if (_balances[from] == 0 && _tokenHolders != 0) {
            _tokenHolders--;
        }

        if (_prevToBalance == 0 && _balances[to] != 0) {
            _tokenHolders++;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(
            account != address(0),
            "WorldEnterprise: mint to the zero address"
        );

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        if (_balances[account] == 0) {
            _tokenHolders++;
        }
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(
            account != address(0),
            "WorldEnterprise: burn from the zero address"
        );

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(
            accountBalance >= amount,
            "WorldEnterprise: burn amount exceeds balance"
        );
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(
            owner != address(0),
            "WorldEnterprise: approve from the zero address"
        );
        require(
            spender != address(0),
            "WorldEnterprise: approve to the zero address"
        );

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "WorldEnterprise: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {}
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

/**
 * ██╗    ██╗ ██████╗ ██████╗ ██████╗     ███████╗███╗   ██╗████████╗███████╗██████╗ ██████╗ ██████╗ ██╗███████╗███████╗
 * ██║    ██║██╔═══██╗██╔══██╗██╔══██╗    ██╔════╝████╗  ██║╚══██╔══╝██╔════╝██╔══██╗██╔══██╗██╔══██╗██║██╔════╝██╔════╝
 * ██║ █╗ ██║██║   ██║██████╔╝██║  ██║    █████╗  ██╔██╗ ██║   ██║   █████╗  ██████╔╝██████╔╝██████╔╝██║███████╗█████╗
 * ██║███╗██║██║   ██║██╔══██╗██║  ██║    ██╔══╝  ██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗██╔═══╝ ██╔══██╗██║╚════██║██╔══╝
 * ╚███╔███╔╝╚██████╔╝██║  ██║██████╔╝    ███████╗██║ ╚████║   ██║   ███████╗██║  ██║██║     ██║  ██║██║███████║███████╗
 * ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═════╝     ╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝╚═╝╚══════╝╚══════╝
 *
 **/

import "@openzeppelin/contracts/utils/Counters.sol";
import "./libs/Enterprise.sol";
import "./WorldEnterprise.sol";

contract WorldEnterpriseFactory {
    using Counters for Counters.Counter;

    // enterprise index
    Counters.Counter public index;

    /**
     * world enterprise list
     * @dev mapping(world enterprise index => WorldEnterprise)
     **/
    mapping(uint256 => WorldEnterprise) public worldEnterprises;

    /**
     * @dev is world enterprise
     **/
    mapping(address => bool) public isWorldEnterprise;

    event CreateWorldEnterprise(
        address[] users,
        uint256[] shares,
        string name,
        string symbol,
        address indexed enterprise,
        Enterprise.Info info
    );

    modifier checkInfo(Enterprise.Info memory info) {
        require(
            bytes(info.logoImg).length < Enterprise.MAX_LENGTH,
            "WorldEnterpriseFactory: Logo image url should be less than the max length"
        );
        require(
            bytes(info.address1).length < Enterprise.MAX_LENGTH,
            "WorldEnterpriseFactory: Address should be less than the max length"
        );
        require(
            bytes(info.address2).length < Enterprise.MAX_LENGTH,
            "WorldEnterpriseFactory: Address should be less than the max length"
        );
        require(
            bytes(info.country).length < Enterprise.MAX_LENGTH,
            "WorldEnterpriseFactory: Country should be less than the max length"
        );
        require(
            bytes(info.zip).length < Enterprise.MAX_LENGTH,
            "WorldEnterpriseFactory: Zip should be less than the max length"
        );
        require(
            bytes(info.state).length < Enterprise.MAX_LENGTH,
            "WorldEnterpriseFactory: State should be less than the max length"
        );
        require(
            bytes(info.city).length < Enterprise.MAX_LENGTH,
            "WorldEnterpriseFactory: City should be less than the max length"
        );
        _;
    }

    /**
     * @param users shareholders user array
     * @param shares amount array of shareholders
     * @param name ERC20 token name
     * @param symbol ERC20 token symbol
     *
     * @dev create a new world enterprise
     **/
    function createWorldEnterprise(
        address[] calldata users,
        uint256[] calldata shares,
        string calldata name,
        string calldata symbol,
        string calldata metadata,
        Enterprise.Info memory info
    ) external checkInfo(info) {
        require(
            users.length > 0,
            "WorldEnterpriseFactory: Users length should be greater than the zero"
        );
        require(
            users.length == shares.length,
            "WorldEnterpriseFactory: Shares length should be equal with the users length"
        );
        require(
            bytes(name).length > 0,
            "WorldEnterpriseFactory: Name should not be as empty string"
        );
        require(
            bytes(symbol).length > 0,
            "WorldEnterpriseFactory: Symbol should not be as empty string"
        );
        require(
            bytes(metadata).length > 0,
            "WorldEnterpriseFactory: Metadata should not be as empty string"
        );

        WorldEnterprise _worldEnterprise = new WorldEnterprise(
            users,
            shares,
            name,
            symbol,
            metadata,
            info
        );
        worldEnterprises[index.current()] = _worldEnterprise;

        isWorldEnterprise[address(_worldEnterprise)] = true;

        index.increment();

        emit CreateWorldEnterprise(
            users,
            shares,
            name,
            symbol,
            address(_worldEnterprise),
            info
        );
    }
}