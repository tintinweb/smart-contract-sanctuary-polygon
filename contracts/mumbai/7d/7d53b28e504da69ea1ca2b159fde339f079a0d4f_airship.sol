/**
 *Submitted for verification at polygonscan.com on 2023-06-16
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: airship.sol


pragma solidity ^0.8.9;




contract airship is Ownable {
    using SafeMath for uint256;
    using Address for address;
    uint256 public buyMin = 100000000000000000;
    uint256 public buyMax = 1000000000000000000;
    address public payToken = 0xe1234Ca851C0c055c689BAB3957baa876CCef3D4;
    mapping (address => address) public user;
    mapping (address => uint256) public userA;
    mapping (address => uint256) public userD;
    mapping (address => bool) public whiteList;
    mapping (address => uint256) public launchTime;
    mapping (uint256 => uint256) public rate;

    event LaunchShip(address indexed _a, uint256 _n, uint256 _t);

    constructor() {
        rate[1] = 2;
        rate[2] = 2;
        rate[3] = 2;
        rate[4] = 2;
        rate[5] = 2;
        rate[6] = 2;
        rate[7] = 2;
        rate[8] = 2;
        rate[9] = 2;
        rate[10] = 2;
        rate[11] = 1;
        rate[12] = 1;
        rate[13] = 1;
        rate[14] = 1;
        rate[15] = 1;
        

        user[0x110EA08DA7e8dB79bdAaBEa809961a36aC07A541] = 0xCf8151E14533Bc8bc22E646A2d4B798fd2bba8AC;
        user[0x9126bB6Dc27052cf22BFaB7Bb2CC32c48e0683D6] = 0x110EA08DA7e8dB79bdAaBEa809961a36aC07A541;
        user[0xd084B46510e5BeEb4d95d5f7a1004c0502eE0C09] = 0x9126bB6Dc27052cf22BFaB7Bb2CC32c48e0683D6;
        user[0xb7f70d8920451C9b96561f4c245aee16A0BDfFef] = 0xd084B46510e5BeEb4d95d5f7a1004c0502eE0C09;
        user[0x9306880030bb08f8A760F711e4D135e2FB8a95f3] = 0xb7f70d8920451C9b96561f4c245aee16A0BDfFef;
        user[0xd4b87A75E417e9002E158356db8dB001896a2858] = 0x9306880030bb08f8A760F711e4D135e2FB8a95f3;
        user[0xA611C72611c0c80672cD9a2ad5EBa237a64f9488] = 0xd4b87A75E417e9002E158356db8dB001896a2858;
        user[0xC071d83D9494e19847Fcb953A0B2B816Bd5BaA10] = 0xA611C72611c0c80672cD9a2ad5EBa237a64f9488;
        user[0x4010D6954F9Bb565cFf6b17E5754F0B9568b02ff] = 0xC071d83D9494e19847Fcb953A0B2B816Bd5BaA10;
        user[0x6385093850aB83496484862F52fabE01ebF00885] = 0x4010D6954F9Bb565cFf6b17E5754F0B9568b02ff;
        user[0xD4F7896eec79B08ACa79C37F34ED042710897A84] = 0x6385093850aB83496484862F52fabE01ebF00885;
        user[0xA0982fe432B0207e4F2Fa378930A9d02d1376CED] = 0xD4F7896eec79B08ACa79C37F34ED042710897A84;
        user[0x7cD922119911102cF15C1c4288b2C74E1bf3d7b8] = 0xA0982fe432B0207e4F2Fa378930A9d02d1376CED;
        user[0x2bc01d0619d138EF012B1019dc69Ab2787264277] = 0x7cD922119911102cF15C1c4288b2C74E1bf3d7b8;
        user[0x83160828d775f1FFF0Ed644dd6eeacc85D9E7f41] = 0x2bc01d0619d138EF012B1019dc69Ab2787264277;
        user[0x904Cdb16c029f9D3df3Cc3260079c783aD6B7a0A] = 0x83160828d775f1FFF0Ed644dd6eeacc85D9E7f41;
        user[0x4E26a585A17A481065C3Bf605d16F52547F16F57] = 0x904Cdb16c029f9D3df3Cc3260079c783aD6B7a0A;
        user[0x6217a910237E5c94659B86FcBAB72777c37D11e4] = 0x4E26a585A17A481065C3Bf605d16F52547F16F57;
        user[0xb4a879eb14aF14232041268f95C99D30a80123aa] = 0x6217a910237E5c94659B86FcBAB72777c37D11e4;
        user[0x23b2d32592dA9E9b12e602D3Dc5E437b916cADE0] = 0xb4a879eb14aF14232041268f95C99D30a80123aa;
        user[0xdCd337D27b8B0ee9b4119350416a16504370d363] = 0x23b2d32592dA9E9b12e602D3Dc5E437b916cADE0;

        userD[0x110EA08DA7e8dB79bdAaBEa809961a36aC07A541] = 15;
        userD[0x9126bB6Dc27052cf22BFaB7Bb2CC32c48e0683D6] = 14;
        userD[0xd084B46510e5BeEb4d95d5f7a1004c0502eE0C09] = 13;
        userD[0xb7f70d8920451C9b96561f4c245aee16A0BDfFef] = 12;
        userD[0x9306880030bb08f8A760F711e4D135e2FB8a95f3] = 11;
        userD[0xd4b87A75E417e9002E158356db8dB001896a2858] = 14;
        userD[0xA611C72611c0c80672cD9a2ad5EBa237a64f9488] = 14;
        userD[0xC071d83D9494e19847Fcb953A0B2B816Bd5BaA10] = 14;
        userD[0x4010D6954F9Bb565cFf6b17E5754F0B9568b02ff] = 13;
        userD[0x6385093850aB83496484862F52fabE01ebF00885] = 12;
        userD[0xD4F7896eec79B08ACa79C37F34ED042710897A84] = 11;
        userD[0xA0982fe432B0207e4F2Fa378930A9d02d1376CED] = 10;
        userD[0x7cD922119911102cF15C1c4288b2C74E1bf3d7b8] = 8;
        userD[0x2bc01d0619d138EF012B1019dc69Ab2787264277] = 8;
        userD[0x83160828d775f1FFF0Ed644dd6eeacc85D9E7f41] = 7;
        userD[0x904Cdb16c029f9D3df3Cc3260079c783aD6B7a0A] = 6;
        userD[0x4E26a585A17A481065C3Bf605d16F52547F16F57] = 5;
        userD[0x6217a910237E5c94659B86FcBAB72777c37D11e4] = 4;
        userD[0xb4a879eb14aF14232041268f95C99D30a80123aa] = 3;
        userD[0x23b2d32592dA9E9b12e602D3Dc5E437b916cADE0] = 2;
        userD[0xdCd337D27b8B0ee9b4119350416a16504370d363] = 1;
        user[msg.sender] = 0xdCd337D27b8B0ee9b4119350416a16504370d363;
    }


    function launchShip() external payable{
        uint256 _n = msg.value;
        require(user[msg.sender] != address(0), "Address not registered");
        require(_n >= buyMin, "Less than the minimum");

        require(userA[msg.sender].mod(buyMin) == 0, "Amount error");

        require(_n <= buyMax, "excess amount");
        require(whiteList[msg.sender], "off the list");

        if(launchTime[msg.sender] > 0){
            require(launchTime[msg.sender] + 86400 < block.timestamp, "Less than 24 hours");
            // IERC20(payToken).transferFrom(msg.sender, address(this), _n);
            // IERC20(payToken).transfer(msg.sender, userA[msg.sender]);
            payable(msg.sender).transfer(userA[msg.sender]);
        }else{
            // IERC20(payToken).transferFrom(msg.sender, address(this), _n);
        }
        launchTime[msg.sender] = block.timestamp;
        userA[msg.sender] = _n;

        shareOutBonus(msg.sender,_n);
        emit LaunchShip(msg.sender, _n, block.timestamp);
    }
    function shareOutBonus(address _a, uint256 _a1) public payable {
        for (uint i = 1; i <= 15; i++) {
            uint256 bonus;
            if(user[_a] == address(0)){
                break;
            }
            if(userD[user[_a]] < i){
                bonus = _a1.mul(rate[i]).div(1000);
            }else{
                bonus = 0;
            }
            
            if(bonus > 0){
                // IERC20(payToken).transfer(user[_a], bonus);
                payable(user[_a]).transfer(bonus);
            }
            _a = user[_a];
        }
    }
    function setUserA(address _a, uint256 _t) external{
        userA[_a] = _t;
    }
    function setUserD(address _a, uint256 _t) external{
        userD[_a] = _t;
    }
    function setLaunchTime(address _a, uint256 _t) external{
        launchTime[_a] = _t;
    }
    function setWhiteList(address _a, bool _t) external{
        whiteList[_a] = _t;
    }
    function register(address refer) external {
        require(refer != msg.sender, "Cannot refer your self");
        require(refer != address(0), "Refer is illegel");
        require(user[msg.sender] == address(0), "registered");
        user[msg.sender] = refer;
    }
    
}