/**
 *Submitted for verification at polygonscan.com on 2022-02-07
*/

// Sources flattened with hardhat v2.8.2 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address sender,
        address recipient,
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


// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


// File @openzeppelin/contracts/utils/math/[email protected]

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


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/security/[email protected]

// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


// File contracts/Progressing.sol

pragma solidity ^0.8.0;

/**
* @dev Interface that provides a progress indicator expressed a pair of two numbers, a progress number and a progresMax number representing 100%.
*
* Progress(%): p = progress * 100 / progressMax
*/
interface Progressing {
    function getProgress() external view returns (uint256 progress, uint256 progressMax);
}


// File contracts/Parameters.sol

pragma solidity ^0.8.0;

abstract contract Parameters {
    // The DEMO mode limits rewards to 1 per challenge and limits blocks per challenge to 2
    bool public constant DEMO = false;

    // Number of decimals in reward token
    uint8 public constant TOKEN_DECIMALS = 18;
    uint256 public constant TOKEN_UNIT = 10 ** TOKEN_DECIMALS; // 1 LUMI

    // The lucky number determines the premium challenges
    uint8 public constant LUCKY_NUMBER = 2;

    // Challenges
    uint8 public constant CHALLENGE_NULL = 255;
    uint8 public constant MAX_CHALLENGE_CNT = 100;
    uint8 public constant MIN_CHALLENGE_DIFFICULTY = DEMO ? 10 : 20;
    uint8 public constant MAX_CHALLENGE_DIFFICULTY = DEMO ? 208 : 218;
    uint8 public constant CHALLENGE_DIFFICULTY_STEP = 2;

    // Creating new challenges
    uint64 public constant BLOCKS_PER_DAY = 39272; // 3600*24 / 2.2

    uint64 public constant MAX_DONOR_BLOCKS = 200; // number of most recent consecutive blocks that can be used as donors

    // Number of blocks we need to wait for a new challenge
    uint8 public constant BLOCKS_PER_CHALLENGE = DEMO ? 2 : 100;

    // Hard limit on number of claims per challenge
    uint16 public constant REWARDS_CNT_LIMIT = DEMO ? 2 : 500;

    // Ramp-up in Newton Epoch
    uint256 public constant REWARD_UNIT = 10 ** (TOKEN_DECIMALS-3); // 0.001 LUMI
    uint16 public constant REWARD_UNITS_START = 10; // 0.01 LUMI
    uint16 public constant REWARD_UNITS_INC = 10; // 0.01 LUMI
    uint16 public constant REWARD_UNITS_STANDARD = 1000; // 1 LUMI
    uint16 public constant REWARD_INC_INTERVAL = DEMO ? 5 : 2700; // One increase per 2700 regular challenges, ~ add reward unit every week

    // external miners can only make claims on addresses with at least 0.01 LUMI
    uint256 public constant MINERS_CLAIM_MIN_RECIPIENT_BALANCE = 10 * REWARD_UNIT; // 0.01 LUMI

    uint256 public constant MAX_REGISTERED_BALANCE = 1000 * TOKEN_UNIT;

    // Cooldown in Einstein Epoch
    // Increase BLOCKS_PER_CHALLENGE by 2 blocks every week
    uint64 public constant BLOCKS_PER_CHALLENGE_INC = 2;
    uint64 public constant BLOCKS_PER_CHALLENGE_INC_INTERVAL = 1 * 7 * BLOCKS_PER_DAY;

}


// File contracts/Utils.sol

pragma solidity ^0.8.0;

library Utils {

    // finds the highest significant bit of the argument
    // the result is encoded as if bits were numbered from 1
    // e.g. findHsb of 0 returns 0
    //      findHsb of 1 returns 1
    //      findHsb of 2 returns 2
    //      findHsb of 4 returns 3
    //      etc.
    function _findHsb(uint256 n) internal pure returns (uint16) {
        uint16 from = 0;
        uint16 to = 256;

        while(from < to) {
            uint16 middle = (from + to) >> 1;
            uint256 mask = (2 ** middle) - 1;
            if(n <= mask) {
                to = middle;
            } else {
                from = middle+1;
            }
        }

        return from;
    }

    // finds the lowest significant bit of the argument
    // the result is encoded as if bits were numbered from 1
    // e.g. findLsb of 0 returns 0
    //      findLsb of 1 returns 1
    //      findLsb of 2 returns 2
    //      findLsb of 4 returns 3
    //      etc.
    function _findLsb(uint256 n) internal pure returns (uint16) {
        if(n == 0) {
            return 0;
        }
        uint16 from = 1;
        uint16 to = 256;

        while(from < to) {
            uint16 middle = (from + to) >> 1;
            uint256 mask = (2 ** middle) - 1;
            if((n & mask) == 0) {
                from = middle+1;
            } else {
                to = middle;
            }
        }

        return from;
    }

    function concat(string memory _a, string memory _b) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ab = new string(_ba.length + _bb.length);
        bytes memory bab = bytes(ab);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bab[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) bab[k++] = _bb[i];
        return string(bab);
    }

}


// File contracts/Rules.sol

pragma solidity ^0.8.0;


abstract contract Rules is Parameters {
    using SafeMath for uint256;

    function _getWalletDifficultyDiscount(uint256 challengeHash, address addr, uint256 balance) internal pure returns (uint8) {
        uint256 h1 = challengeHash;
        uint256 h2 = uint256(uint160(addr));

        uint256 o = h1 ^ h2;
        uint16 lsb = Utils._findLsb(o);
        if(lsb == 0) {
            lsb = 256;
        } else {
            lsb--;
        }

        uint256 b1 = balance.div(TOKEN_UNIT);
        uint8 n = 0;
        if(b1 >= 1) {
            if(lsb >= 20) {
                n = 30;
            } else if(lsb >= 10) {
                n = 20 + (uint8(lsb) - 10);
            } else {
                n = 2 * uint8(lsb);
            }
        } else {
            if(lsb > 10) {
                n = 10;
            } else {
                n = uint8(lsb);
            }
        }

        return n;
    }

   function _getBalanceDifficultyDiscount(uint256 balance) internal pure returns (uint8) {
        uint256 b1 = balance.div(TOKEN_UNIT);
        uint256 b2 = balance.mod(TOKEN_UNIT).div(REWARD_UNIT);

        uint8 discount;
        if(b1 >= 1) {
            if(b1 >= 1000) {
                discount = 2 * 10 + 10;
            } else if(b1 >= 500) {
                discount = 2 * 9 + 10;
            } else if(b1 >= 200) {
                discount = 2 * 8 + 10;
            } else if(b1 >= 100) {
                discount = 2 * 7 + 10;
            } else if(b1 >= 50) {
                discount = 2 * 6 + 10;
            } else if(b1 >= 20) {
                discount = 2 * 5 + 10;
            } else if(b1 >= 10) {
                discount = 2 * 4 + 10;
            } else if(b1 >= 5) {
                discount = 2 * 3 + 10;
            } else if(b1 >= 3) {
                discount = 2 * 2 + 10;
            } else if(b1 >= 2) {
                discount = 2 * 1 + 10;
            } else {
                discount = 2 * 0 + 10;
            }
        } else {
            if(b2 >= 500) {
                discount = 9;
            } else if(b2 >= 200) {
                discount = 8;
            } else if(b2 >= 100) {
                discount = 7;
            } else if(b2 >= 50) {
                discount = 6;
            } else if(b2 >= 20) {
                discount = 5;
            } else if(b2 >= 10) {
                discount = 4;
            } else if(b2 >= 5) {
                discount = 3;
            } else if(b2 >= 2) {
                discount = 2;
            } else if(b2 >= 1) {
                discount = 1;
            } else {
                discount = 0;
            }
        }
        return discount;
    }

    // Now of tokens is means in Einstein era, during Newton era the number need to be multiplies with current units per token number
    function _getRewardTokens(uint256 challengeHash) internal pure returns (uint16 rewardsCnt, uint16 tokens) {
        uint256 h = challengeHash;

        if(((h >> (256-20)) & 0xFFFFF) == 0x22222) {
            return (500, 2000);
        } else if(((h >> (256-16)) & 0xFFFF) == 0x2222) {
            return (200, 500);
        } else if(((h >> (256-12)) & 0xFFF) == 0x222) {
            return (100, 100);
        } else if(((h >> (256-2)) & 0xFF) == 0x22) {
            return (50, 20);
        } else if(((h >> (256-4)) & 0xF) == 0x2) {
            return (20, 5);
        } else {
            return (10, 1);
        }
    }

}


// File contracts/ILuminaRecords.sol

pragma solidity ^0.8.0;

interface ILuminaRecords {

    function getBalances() external view returns (uint256[] memory balances, uint64[] memory blockNumbers);
    function findBalance(address wallet, uint64 blockNumber) external view returns (uint256 balance);
    function getClaimsCnt(uint64 blockNumber) external view returns (uint16);
    function hasClaimed(uint64 blockNumber, address recipient) external view returns (uint32 rewardUnits);
    function getClaims(uint64[] memory blockNumbers, address recipient) external view returns (uint16[] memory claimsCnt, bool[] memory claimed);
    function setCommision(uint8 commisionPrc) external;
    function getCommision(address wallet) external view returns (uint8 commisionPrc);
    function _registerBalance(address sender, uint256 balance, bool force) external returns (bool registered); // onlyToken
    function _updateBalance(address sender, uint256 balance) external; // onlyToken
    function _addClaim(uint64 blockNumber, address recipient, uint32 rewardUnits) external; // onlyTrustee
    function _updateFirstBlockNumber(uint64 blockNumber) external; // onlyAdmin

}


// File contracts/ChallengeRecords.sol

pragma solidity ^0.8.0;


abstract contract ChallengeRecords is Parameters {

    struct Challenge {
        uint256 challengeHash;
        uint64 blockNumber;
        uint16 rewardUnits; // 1 - 1000
        uint8 index;
        bool valid;
        uint8 prev;
        uint8 next;
    }

    struct ChallengeSet {
        Challenge[MAX_CHALLENGE_CNT] ch;
        uint8 cnt;
        uint8 freeIndex;
        uint8 head;
        uint8 tail;
    }

    function _challengeSetInit(ChallengeSet storage chs) internal {

        require(CHALLENGE_NULL < 256, "ChallengeRecords: Invalid configuration: CHALLENGE_NULL");
        require(MAX_CHALLENGE_CNT <= CHALLENGE_NULL, "ChallengeRecords: Invalid configuration: MAX_CHALLENGE_CNT");

        for(uint8 i = 0; i < MAX_CHALLENGE_CNT; i++) {
            Challenge storage ch = chs.ch[i];
            ch.challengeHash = 0;
            ch.blockNumber = 0;
            ch.rewardUnits = 0;
            ch.index = i;
            ch.valid = false;
            ch.prev = CHALLENGE_NULL;
            ch.next = i+1 < MAX_CHALLENGE_CNT ? i+1 : CHALLENGE_NULL;
        }

        chs.cnt = 0;
        chs.freeIndex = 0;
        chs.head = CHALLENGE_NULL;
        chs.tail = CHALLENGE_NULL;
    }

    // Returns CHALLENGE_NULL  if not found
    function _challengeFind(ChallengeSet storage chs, uint64 blockNumber) internal view returns (uint8 index, uint8 generalDifficulty) {
        uint8 cnt = chs.cnt;
        require(cnt <= MAX_CHALLENGE_CNT, "ChallengeRecords: Invalid configuration: cnt <= MAX_CHALLENGE_CNT failed");
        index = chs.head;
        generalDifficulty = 0;
        for(uint8 i = 0; i < cnt; i++) {
            Challenge memory ch = _challengeGet(chs, index);

            if(ch.blockNumber == blockNumber) {
                require(index == ch.index, "ChallengeRecords._challengeFind(): corrupt list");
                generalDifficulty = MAX_CHALLENGE_DIFFICULTY - CHALLENGE_DIFFICULTY_STEP * (cnt - i - 1);
                require(MIN_CHALLENGE_DIFFICULTY <= generalDifficulty && generalDifficulty <= MAX_CHALLENGE_DIFFICULTY, "ChallengeRecords._challengeFind(): generalDifficulty out of range");
                return (index, generalDifficulty);
            }

            index = ch.next;
        }
        require(index == CHALLENGE_NULL, "ChallengeRecords._challengeFind(): corrupt list");
    }

    function _challengeGet(ChallengeSet storage chs, uint8 index) internal view returns (Challenge storage) {
        require(index < MAX_CHALLENGE_CNT, "ChallengeRecords._challengeGet(): index is out of range");

        Challenge storage ch = chs.ch[index];
        require(ch.index == index, "ChallengeRecords: corrupt challenge index");

        return ch;
    }

    function _challengesGet(ChallengeSet storage chs, uint8 limit)
    internal view returns (uint8 totalCnt, uint8[] memory indexes, uint64[] memory blockNumbers, uint16[] memory rewardUnits, uint256[] memory challengeHashes, uint8[] memory nexts) {
        uint8 cnt = limit < chs.cnt ? limit : chs.cnt;
        totalCnt = chs.cnt;
        indexes = new uint8[](cnt);
        blockNumbers = new uint64[](cnt);
        challengeHashes = new uint256[](cnt);
        nexts = new uint8[](cnt);
        rewardUnits = new uint16[](cnt);
        uint8 index = chs.head;
        for(uint8 i = 0; i < cnt; i++) {
            Challenge memory ch = _challengeGet(chs, index);
            indexes[i] = ch.index;
            blockNumbers[i] = ch.blockNumber;
            rewardUnits[i] = ch.rewardUnits;
            challengeHashes[i] = ch.challengeHash;
            nexts[i] = ch.next;
            index = ch.next;
        }
        require(limit < chs.cnt || index == CHALLENGE_NULL, "ChallengeRecords._challengesGet(): corrupt list");
    }

    function _challengeSetIsFull(ChallengeSet storage chs) internal view returns (bool) {
        return chs.cnt >= MAX_CHALLENGE_CNT;
    }

    function _challengeSetIsEmpty(ChallengeSet storage chs) internal view returns (bool) {
        return chs.cnt == 0;
    }

    function _challengeGetFirstBlock(ChallengeSet storage chs) internal view returns (uint64 blockNumber) {
        uint8 index = chs.head;
        if(index == CHALLENGE_NULL) {
            blockNumber = uint64(block.number);
        } else {
            Challenge memory ch = _challengeGet(chs, index);
            require(ch.valid, "ChallengeRecords: corrupt challenge item in the list");
            blockNumber = ch.blockNumber;
        }
    }

    function _challengeInsertHead(ChallengeSet storage chs, uint64 blockNumber, uint256 challengeHash, uint16 rewardUnits) internal {
        require(!_challengeSetIsFull(chs), "ChallengeRecords: Challenge set is full");

        uint8 index = chs.freeIndex;
        require(index < MAX_CHALLENGE_CNT, "ChallengeRecords: corrupt freeIndex");
        Challenge storage ch = _challengeGet(chs, index);
        require(!ch.valid, "ChallengeRecords: corrupt challenge item in freeList");
        chs.freeIndex = ch.next;

        ch.challengeHash = challengeHash;
        ch.blockNumber = blockNumber;
        ch.rewardUnits = rewardUnits;
        ch.valid = true;
        ch.prev = CHALLENGE_NULL;
        ch.next = chs.head;
        if(chs.head != CHALLENGE_NULL) {
            Challenge storage head = _challengeGet(chs, chs.head);
            head.prev = index;
        }
        chs.head = index;
        if(chs.tail == CHALLENGE_NULL) {
            chs.tail = index;
        }
        chs.cnt++;
    }

    function _challengeInsertTail(ChallengeSet storage chs, uint64 blockNumber, uint256 challengeHash, uint16 rewardUnits) internal {
        require(!_challengeSetIsFull(chs), "ChallengeRecords: Challenge set is full");

        uint8 index = chs.freeIndex;
        require(index < MAX_CHALLENGE_CNT, "ChallengeRecords: corrupt freeIndex");
        Challenge storage ch = _challengeGet(chs, index);
        require(!ch.valid, "ChallengeRecords: corrupt challenge item in freeList");
        chs.freeIndex = ch.next;

        ch.challengeHash = challengeHash;
        ch.blockNumber = blockNumber;
        ch.rewardUnits = rewardUnits;
        ch.valid = true;
        ch.prev = chs.tail;
        ch.next = CHALLENGE_NULL;
        if(chs.tail != CHALLENGE_NULL) {
            Challenge storage tail = _challengeGet(chs, chs.tail);
            tail.next = index;
        }
        chs.tail = index;
        if(chs.head == CHALLENGE_NULL) {
            chs.head = index;
        }
        chs.cnt++;
    }

    function _challengeRemove(ChallengeSet storage chs, uint8 index) internal {
        require(!_challengeSetIsEmpty(chs), "ChallengeRecords: Challenge set is empty");

        Challenge storage ch = _challengeGet(chs, index);
        require(ch.valid, "ChallengeRecords: removing invalid item");

        // Reconnect the double linked list
        if(ch.prev != CHALLENGE_NULL) {
            Challenge storage prev = _challengeGet(chs, ch.prev);
            prev.next = ch.next;
        }
        if(ch.next != CHALLENGE_NULL) {
            Challenge storage next = _challengeGet(chs, ch.next);
            next.prev = ch.prev;
        }

        if(index == chs.head) {
            chs.head = ch.next;
        }

        if(index == chs.tail) {
            chs.tail = ch.prev;
        }

        // Put the removed item back into the free list
        uint8 freeIndex = chs.freeIndex;
        require(freeIndex < MAX_CHALLENGE_CNT || freeIndex == CHALLENGE_NULL, "ChallengeRecords: corrupt freeIndex");
        ch.challengeHash = 0;
        ch.blockNumber = 0;
        ch.rewardUnits = 0;
        ch.valid = false;
        ch.prev = CHALLENGE_NULL;
        ch.next = freeIndex;
        chs.freeIndex = index;
        chs.cnt--;
    }

}


// File contracts/ILuminaAdmin.sol

pragma solidity ^0.8.0;

interface ILuminaAdmin {

    function readChallenges(bool premium, uint8 limit) external view returns (uint8 totalCnt, uint8[] memory indexes, uint64[] memory blockNumbers, uint16[] memory rewardUnits, uint256[] memory challengeHashes, uint8[] memory nexts, uint16[] memory claimsCnt, bool[] memory claimed);
    function getChallengesAllowance() external view returns (uint8);
    function addChallenges(uint8 limit) external returns (uint8);
    function retrieveChallenge(uint64 blockNumber) external view returns (ChallengeRecords.Challenge memory ch, bool premium, uint8 generalDifficulty);
    function _cleanupChallenge(uint64 blockNumber, bool premium) external; // onlyTrustee
}


// File contracts/ILuminaMarketing.sol

pragma solidity ^0.8.0;

interface ILuminaMarketing {

    function owner() external view returns (address);
    function _claim(uint64 blockNumber, address miner, address recipient, uint32 rewardUnits, uint8 commisionPrc) external; // onlyTrustee

}


// File contracts/ILuminaFund.sol

pragma solidity ^0.8.0;

interface ILuminaFund {

    function isLuminaFund() external pure returns (bool);

}


// File contracts/LuminaTrustee.sol

pragma solidity ^0.8.0;










contract LuminaTrustee is Ownable, Pausable, Progressing, Rules {
    using SafeMath for uint256;

    // Public address of the linked token contract
    address public tokenAddr;
    // Public address of the linked records contract
    address public recordsAddr;
    // Public address of the linked administrator contract
    address public adminAddr;
    // Public address of the linked marketing contract
    address public marketingAddr;

    // Link to ERC20 tokens contract
    IERC20 private token;
    // Link to LuminaRecords contract
    ILuminaRecords private records;
    // Link to LuminaAdministator contract
    ILuminaAdmin private admin;

    uint64 private _claimedChallenges;
    uint256 private _claimedTokens;
    uint64 private _marketingCallSuccessCnt;
    uint64 private _marketingCallFailedCnt;

    event Claim(uint64 indexed blockNumber, address indexed recipient, address indexed miner, uint256 solution, uint8 commisionPrc, uint16 claimNo);
    event MarketingCallFailed(address marketingAddr, uint64 blockNumber, string message);

    constructor(address tokenAddr_, address recordsAddr_, address adminAddr_) {
        pause();

        tokenAddr = tokenAddr_;
        recordsAddr = recordsAddr_;
        adminAddr = adminAddr_;
        token = IERC20(tokenAddr);
        records = ILuminaRecords(recordsAddr);
        admin = ILuminaAdmin(adminAddr);

        _claimedChallenges = 0;
        _claimedTokens = 0;
    }

    function pause() public onlyOwner {
        super._pause();
    }

    function unpause() public onlyOwner {
        super._unpause();
    }

    function renounceOwnership() public virtual override onlyOwner whenNotPaused {
        super.renounceOwnership();
    }

    function getProgress() public view override returns (uint256 progress, uint256 progressMax) {
        progress = _claimedTokens;
        progressMax = _claimedTokens+token.balanceOf(address(this));
    }

    function getClaimedTokens() public view returns (uint256) {
        return _claimedTokens;
    }

    function setMarketingAddr(address marketingAddr_) external onlyOwner {
        require(marketingAddr_ == address(0) || ILuminaMarketing(marketingAddr_).owner() == owner(), "The marketing contract address must point to a contract with the same owner");
        marketingAddr = marketingAddr_;
    }

    function _getAdjustedDifficulty(uint64 blockNumber, address recipient, uint8 generalDifficulty, uint256 challengeHash) private view returns (uint8 adjustedDifficulty) {
        uint256 registeredBalance = records.findBalance(recipient, blockNumber);

        uint8 walletDiscount = _getWalletDifficultyDiscount(challengeHash, recipient, registeredBalance);
        uint8 balanceDiscount = _getBalanceDifficultyDiscount(registeredBalance);

        // Calculate Adjusted Difficulty
        require(MIN_CHALLENGE_DIFFICULTY <= generalDifficulty && generalDifficulty <= MAX_CHALLENGE_DIFFICULTY, "verifyClaim(): generalDifficulty out of range");
        uint8 totalDiscount = walletDiscount + balanceDiscount;
        adjustedDifficulty = generalDifficulty >= totalDiscount ? generalDifficulty - totalDiscount : 0;
        if(adjustedDifficulty < MIN_CHALLENGE_DIFFICULTY) {
            adjustedDifficulty = MIN_CHALLENGE_DIFFICULTY;
        }
        require(MIN_CHALLENGE_DIFFICULTY <= adjustedDifficulty && adjustedDifficulty <= MAX_CHALLENGE_DIFFICULTY, "verifyClaim(): adjustedDifficulty out of range");
    }

    function verifySolution(uint64 blockNumber, address miner, address recipient, uint256 solution) public view whenNotPaused returns (uint16 solvedDifficulty) {
        (ChallengeRecords.Challenge memory ch, bool premium, uint8 generalDifficulty) = admin.retrieveChallenge(blockNumber);

        require(MIN_CHALLENGE_DIFFICULTY <= generalDifficulty && generalDifficulty <= MAX_CHALLENGE_DIFFICULTY, "Difficulty is out of range");
        require(premium == false || premium == true);

        bytes memory data = abi.encodePacked(solution, ch.challengeHash, uint256(uint160(recipient)), uint256(uint160(miner)));
        require(data.length == 128, "Invalid solution data");
        bytes32 digest = keccak256(data);

        solvedDifficulty = 256 - Utils._findHsb(uint256(digest));
    }

    function _isLuminaFund(address recipient) private pure returns (bool) {
        ILuminaFund maybeFund = ILuminaFund(recipient);
        try maybeFund.isLuminaFund() returns (bool isFund) {
            return isFund;
        } catch {
            return false;
        }
    }

    // Reasons
    // 0 - satisfies all criteria, at this moment, to claim the tokens
    // 1 - blockNumber does not exist or has no live challenge assigned right now
    // 2 - solvedDifficulty doesn't safisfy the current requirements
    // 3 - this challenge has already been claimed by this address
    // 4 - all available rewards have been already claimed
    // 5 - recipient's address is not eligible for rewards, external miners can only make claims on addresses with at least 0.001 LUMI
    // 6 - recipient's address is not eligible for rewards, it is a contract that is not a Lumina Fund
    function verifyClaim(uint64 blockNumber, address miner, address recipient, uint256 solution) public view whenNotPaused
        returns (uint32 rewardUnits, uint8 reason, bool premium, uint16 rewardsCnt, uint16 claimsCnt)
    {
        ChallengeRecords.Challenge memory ch;

        // Retrieve the challenge information
        uint8 generalDifficulty;
        (ch, premium, generalDifficulty) = admin.retrieveChallenge(blockNumber);

        require(ch.valid, "Invalid challenge record");

        // Get adjustd difficulty
        uint8 adjustedDifficulty = _getAdjustedDifficulty(blockNumber, recipient, generalDifficulty, ch.challengeHash);

        // Get actual solved difficulty
        uint16 solvedDifficulty = verifySolution(blockNumber, miner, recipient, solution);

        // Calculate Reward Tokens
        rewardUnits = 0;
        reason = 0;
        if(solvedDifficulty >= adjustedDifficulty) {
            uint256 balance = token.balanceOf(recipient);
            if(records.hasClaimed(blockNumber, recipient) != 0) {
                reason = 3;
            } else if(miner != recipient && balance < MINERS_CLAIM_MIN_RECIPIENT_BALANCE) {
                reason = 5;
            } else if(Address.isContract(recipient) && !_isLuminaFund(recipient)) {
                reason = 6;
            }
        } else {
            reason = 2;
        }

        if(reason == 0) {
            uint16 rewardTokens;
            (rewardsCnt, rewardTokens) = _getRewardTokens(ch.challengeHash);

            if(rewardsCnt > REWARDS_CNT_LIMIT) {
                rewardsCnt = REWARDS_CNT_LIMIT;
            }

            claimsCnt = records.getClaimsCnt(blockNumber);
            if(claimsCnt < rewardsCnt) {
                rewardUnits = uint32(rewardTokens) * uint32(ch.rewardUnits);
                reason = 0;
            } else {
                reason = 4;
            }
        }
    }

    function claimReward(uint64 blockNumber, address miner, address recipient, uint256 solution) external whenNotPaused
        returns (uint32 rewardUnits, uint8 reason, bool premium, uint16 claimsCnt)
    {
        uint16 rewardsCnt;

        (rewardUnits, reason, premium, rewardsCnt, claimsCnt) = verifyClaim(blockNumber, miner, recipient, solution);

        if(reason == 0) {
            // Extra check that we don't have some unexpected leak
            require(rewardUnits > 0, "Invalid reward amount");
            require(rewardUnits <= uint256(2000).mul(REWARD_UNITS_STANDARD), "Invalid reward, amount too big");

            // Transfer reward to msg.sender
            uint256 rewardAmount = uint256(rewardUnits).mul(REWARD_UNIT);

            uint8 commisionPrc = records.getCommision(recipient);
            if(miner != recipient) {
                uint256 commisionAmount = rewardAmount.mul(commisionPrc).div(100);
                uint256 recipientAmount = rewardAmount.sub(commisionAmount);
                token.transfer(recipient, recipientAmount);
                token.transfer(miner, commisionAmount);
                emit Claim(blockNumber, recipient, miner, solution, commisionPrc, claimsCnt);
            } else {
                token.transfer(recipient, rewardAmount);
                emit Claim(blockNumber, recipient, miner, solution, 0, claimsCnt);
            }

            _claimedTokens = _claimedTokens.add(rewardAmount);

            // Extra check that we don't have some unexpected leak
            require(claimsCnt < REWARDS_CNT_LIMIT, "claim count is too big");
            require(claimsCnt < rewardsCnt, "claim count is too big");
            claimsCnt++;
            records._addClaim(blockNumber, recipient, rewardUnits);

            if(claimsCnt >= rewardsCnt) {
                _claimedChallenges++;
                admin._cleanupChallenge(blockNumber, premium);
            }

            // Notify the marketing contract
            if(marketingAddr != address(0)) {
                ILuminaMarketing marketing = ILuminaMarketing(marketingAddr);
                try marketing._claim(blockNumber, miner, recipient, rewardUnits, commisionPrc) {
                } catch Error(string memory message) {
                    _marketingCallSuccessCnt++;
                    emit MarketingCallFailed(marketingAddr, blockNumber, message);
                } catch {
                    _marketingCallFailedCnt++;
                    emit MarketingCallFailed(marketingAddr, blockNumber, "");
                }
            }
        }
    }

}