/**
 *Submitted for verification at polygonscan.com on 2022-08-17
*/

// SPDX-License-Identifier: MIT
// Sources flattened with hardhat v2.10.1 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]


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


// File contracts/proposals.sol


pragma solidity >=0.7.0 <0.9.0;

contract proposals{
    using Counters for Counters.Counter;

    Counters.Counter private _idCounter;

    struct historyUpdates{
        uint256 lastUpdateId;
        uint8 buyerChoose;
        uint8 sellerChoose;
        //
        mapping(uint256 => proposal) proposalsInfo;
    }

    struct proposal{
        uint256 created;
        uint8 proposalType; // 0 = informative, 1 = update deadline
        uint8 accepted; //(0 = No answer, 1 = Accepted, 2 = Cancelled, 3 =  No changes, 4 = time updated)
        string description;
        bool proposalStatus;
    }


    // deal ID to history updates
    mapping(uint256 => historyUpdates) public updates;


    function newProposal(uint _dealID, address _dealBuyer, address _dealSeller, 
                        uint256 _lastProposal, uint8 _proposalType, string memory _description)
                        internal   {

        (, , , ,bool _status) = _seeProposals(_dealID, _lastProposal);
        
        if(_lastProposal > 0){
            require(_status,"First complete pending proposal before to create a new one");
        }
        
        historyUpdates storage _historyUpdates = updates[_dealID];
        _historyUpdates.lastUpdateId += 1;

        if(msg.sender == _dealBuyer){
             _historyUpdates.buyerChoose = 1;
        }

        if(msg.sender == _dealSeller){
             _historyUpdates.sellerChoose  = 1;
        }

        //deals[_dealID].numOfProposals = _historyUpdates.lastUpdateId;
        _historyUpdates.proposalsInfo[_historyUpdates.lastUpdateId] = proposal(block.timestamp, _proposalType, 0, _description, false);

    }
    function _deadlineUpdatedStatus(uint _dealId)internal{
        updates[_dealId].proposalsInfo[updates[_dealId].lastUpdateId].accepted = 4;
    }

    function _seeProposals(uint _dealId, uint _proposalId) internal  view returns(uint256, uint8, uint8, string memory, bool){
        proposal memory _info = updates[_dealId].proposalsInfo[_proposalId];
        return(_info.created,_info.proposalType,_info.accepted, _info.description, _info.proposalStatus);
    }


    function proposalChoose(uint _dealID, uint256 _lastProposal ,address _dealBuyer, address _dealSeller ,uint8 _choose) internal{

        historyUpdates storage _historyUpdates = updates[_dealID];

        if(msg.sender == _dealBuyer){
            _historyUpdates.buyerChoose = _choose;
        }

        if(msg.sender == _dealSeller){
            _historyUpdates.sellerChoose  = _choose;
        }

        uint8 _buyerChoose = _historyUpdates.buyerChoose;
        uint8 _sellerChoose= _historyUpdates.sellerChoose;

        //accepted
        if(_buyerChoose == 1 && _sellerChoose == 1){
            updates[_dealID].proposalsInfo[_lastProposal].accepted = 1;
            updates[_dealID].proposalsInfo[_lastProposal].proposalStatus = true;
            _historyUpdates.buyerChoose = 0;
            _historyUpdates.sellerChoose  = 0;
            return;
        }

        //cancelled
        if(_buyerChoose == 2 && _sellerChoose == 2){
            updates[_dealID].proposalsInfo[_lastProposal].accepted = 2;
            updates[_dealID].proposalsInfo[_lastProposal].proposalStatus = true;
            _historyUpdates.buyerChoose = 0;
            _historyUpdates.sellerChoose  = 0;
            return;
        }

        //no changes
        if(_buyerChoose > 0 && _sellerChoose > 0){
            updates[_dealID].proposalsInfo[_lastProposal].accepted = 3;
            updates[_dealID].proposalsInfo[_lastProposal].proposalStatus = true;
            _historyUpdates.buyerChoose = 0;
            _historyUpdates.sellerChoose  = 0;
            return;

        }
    }

}


// File @openzeppelin/contracts/utils/math/[email protected]


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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


// File @openzeppelin/contracts/token/ERC20/[email protected]


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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}


// File @openzeppelin/contracts/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;



/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File contracts/utils.sol


pragma solidity >=0.7.0 <0.9.0;

contract utils{

        function _feeCalculation(uint256 _amount, uint256 _defaultFee)internal pure returns (uint256){

        (bool flagMultiply,uint256 mult) = SafeMath.tryMul(_amount, _defaultFee);
        if(!flagMultiply) revert();
        
        (bool flagDiv, uint256 _fee) = SafeMath.tryDiv(mult,10000);
        if(!flagDiv) revert();

        (bool flagAmountFee, uint256 _diff)= SafeMath.trySub(_amount, _fee);
        if(!flagAmountFee) revert();

        (bool flagFee, uint256 _newAmount)= SafeMath.trySub(_amount, _diff);
        if(!flagFee) revert();
        return(_newAmount);
    }

    function _deadlineCal(uint256 _deadlineInDays, uint256 defaultLifeTime)internal view returns(uint256){
        // TODO> hacer test a esta funcion y revisar que el _newDeadline funcione en createDeal
        if(_deadlineInDays > 0){
            (bool _flagMul,uint256 secs) = SafeMath.tryMul(_deadlineInDays, 86400);
            if(!_flagMul) revert();

            (bool _flagAdd, uint256 _newDeadline) = SafeMath.tryAdd(secs,block.timestamp);
            if(!_flagAdd) revert();

            return(_newDeadline);
        }else{
            (bool _flagAddDeadline, uint256 _defaultDeadline) = SafeMath.tryAdd(0, block.timestamp);//SafeMath.tryAdd(defaultLifeTime, block.timestamp);
            if(!_flagAddDeadline) revert();
            defaultLifeTime; //borrar despues
            return(_defaultDeadline); 
        }
    }
}


// File contracts/test_contract.sol



pragma solidity >=0.8.0 <0.9.0;






contract test_contract is proposals, utils {

    uint256 public defaultLifeTime;
    uint256 public defaultFee;
    uint256 public defaultPenalty;
    address payable owner;
    address public oracle;
    address public tribunal;

    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    IERC20 _token;
    Counters.Counter private _idCounter;

    struct metadataDeal{
        address buyer; 
        address seller; 
        string title;
        string description; 
        uint256 amount; 
        uint256 goods; 
        uint16 status; //0=pending, 1= open, 2= completed, 3= cancelled, 4= tribunal
        uint256 created;
        uint256 deadline; // timestamp
        string coin;
        uint256 numOfProposals;
    }

    // (0 = No answer, 1 = Accepted, 2 = Cancelled, 3 = Paid, 4 = Refund)
    struct agreement{
        uint8 buyerChoose;
        uint8 sellerChoose;
        bool buyerAcceptDraft;
        bool sellerAcceptDraft;
    }


    // deal ID to metadata Deal 
    mapping(uint256 => metadataDeal) public deals;

    // deal ID to partTake choose
    mapping(uint256 => agreement) public acceptance;


    // tokens contract
    mapping(string => address) public tokens;
    
    // tokens contract > decimals
    mapping(string => uint) public tokenDecimal;

    // EVENTS
    event _dealEvent(uint256 ID, string TOKEN, bool STATUSCREATE);

    constructor(address _tokenAddress, string memory _tokenName,  uint256 _tokenDecimal,uint256 _defaultPenalty){
        // TODO> Agregar funciones para la proteccion de tiempos del BUYER
        // TODO> Agregar funcion para modificar defaultLifeTime
        // TODO> Agregar funcion para modificar limitLifeTime para limite proteccion de tiempos del BUYER
        // TODO> solucionar defaultpenalty para ir acorder a los decimales del token

        owner = payable(msg.sender);
        tokens[_tokenName] = _tokenAddress;
        tokenDecimal[_tokenName] = _tokenDecimal;
        defaultFee = 150; 
        defaultPenalty = _defaultPenalty;
        defaultLifeTime = 604800;
        //================================================================
        // Rinkeby ETH testnet
        // BUSD 0x4e2442A6f7AeCE64Ca33d31756B5390860BF973E //decimals 18
        // USDT 0xD9BA894E0097f8cC2BBc9D24D308b98e36dc6D02 //decimals 18
        // USDC 0xeb8f08a975Ab53E34D8a0330E0D34de942C95926 //decimals 6
    }

    // Validate Only the buyer or seller can edit
    modifier isPartTaker(uint256 _dealID){
        require(((msg.sender == deals[_dealID].buyer)||(msg.sender == deals[_dealID].seller)), "You are not part of the deal");
        _;
    }


    // Validate the Deal status still OPEN
    modifier openDeal(uint256 _dealID){
        require(deals[_dealID].status == 1," DEAL are not OPEN");
        _;
    }

    // Validate the Deal status is a DRAFT
    modifier openDraft(uint256 _dealID){
        require(deals[_dealID].status == 0," DRAFT are not PENDING");
        _;
    }

    modifier tokenValid(string memory _tokenName){
        require(tokens[_tokenName] != address(0),"token not supportedt");
        _;
    }


    // Change Defaults parms
    function _changeDefaultFee(uint256 _newDefaultFee) public{
        // use Points Basis 1% = 100
        require(msg.sender == owner, "Only Owner");
        require((_newDefaultFee >= 10),"Fee in PB MIN 0.1% = 10" );
        require((_newDefaultFee <= 1000),"Fee in PB MAX 10% = 1000");
        defaultFee = _newDefaultFee;
    }

    function _changeDefaultPenalty(uint256 _newDefaultPenalty) public{
        require(msg.sender == owner, "Only Owner can change it");
        defaultPenalty = _newDefaultPenalty;
    }

    function _changeDefaultLifeTime(uint256 _newDefaultLifeTime) public{
        require(msg.sender == owner, "Only Owner can change it");
        defaultLifeTime = _newDefaultLifeTime;
    }
    function _changeTribunalAdress(address _newAddress) public{
        require(msg.sender == owner, "Only Owner");
        tribunal = _newAddress;
    }
    function _changeOracleAddress(address _newAddress) public{
        require(msg.sender == owner, "Only Owner");
        oracle = _newAddress;
    }

    function _addNewToken(string memory _tokenName, address _tokenAddress, uint256 _tokenDecimal)public {
        require(msg.sender == owner, "Only Owner can add a token it");
        require(tokens[_tokenName] == address(0), "token already exists");
        
        tokens[_tokenName] = _tokenAddress;
        tokenDecimal[_tokenName] = _tokenDecimal;
    }


// TODO> HACER TEST PARA IMPORTAR LAS FUNCIONES PARA LAS PROPUESTAS
// TODO> HACER FUNCIONES PARA EL ORACULO
// TODO> HACER FUNCIONES PARA EL TRIBUNAL
    function _updateDeadline(uint256 _dealID, uint256 _addDays)public openDeal(_dealID) isPartTaker(_dealID) returns(bool){
        // TODO> Agregar nueva variable para actualizacion de decisiones
        (,uint8 _proposalType, uint8 _accepted, , bool _status) = _seeProposals(_dealID,deals[_dealID].numOfProposals);

        require(deals[_dealID].buyer == msg.sender, "Only BUYER");
        require(deals[_dealID].numOfProposals > 0,"First make a proposal");
        require(_proposalType == 1,"NOT deadline type");
        require(_accepted == 1, "not accepted");
        require(_status == true, "still pending ");

        _deadlineUpdatedStatus(_dealID);
        deals[_dealID].deadline = deadlineCal(_addDays);
        return(true);
    }



    function _newProposal(uint _dealID, uint8 _proposalType, string memory _description) 
                        public openDeal(_dealID) isPartTaker(_dealID) returns(bool){

        newProposal( _dealID,  deals[_dealID].buyer,  deals[_dealID].seller, deals[_dealID].numOfProposals,  _proposalType,   _description);
        deals[_dealID].numOfProposals += 1;
        return true;
    }

    function _proposalChoose(uint _dealID, uint8 _choose)public openDeal(_dealID) isPartTaker(_dealID) returns(bool){

       proposalChoose(_dealID, deals[_dealID].numOfProposals, deals[_dealID].buyer, deals[_dealID].seller, _choose);
       return true;
    }
    function __seeProposals(uint _dealId, uint _proposalId)  public view returns(uint256, uint8, uint8, string memory, bool){
        (uint256 created, uint8 proposalType, uint8 accepted, string memory _description, bool proposalStatus) = _seeProposals(_dealId, _proposalId);
        return(created, proposalType, accepted, _description, proposalStatus);
    }

    function createDeal(
        address _buyer, 
        address _seller, 
        string memory _title,
        string memory _description,
        uint256 _amount,
        string memory _coin, 
        uint256 _deadlineInDays

        )public tokenValid(_coin)  returns(bool){
        
        require(_amount > 0, "above 0 wei");
        require(_deadlineInDays >= 0 && _deadlineInDays <= 30,"Deadline in days. 0 to 30");

        uint256 _newDeadline = deadlineCal(_deadlineInDays);
        uint256 _current = _idCounter.current();

        if(_buyer == msg.sender){
        acceptance[_current] = agreement(0,0,true,false);
        deals[_current] = metadataDeal(msg.sender, _seller, _title, _description, _amount, 0, 0, block.timestamp, _newDeadline, _coin, 0);
        _idCounter.increment();
        }else if(_seller == msg.sender){
        acceptance[_current] = agreement(0,0,false,true);
        deals[_current] = metadataDeal(_buyer, msg.sender, _title, _description, _amount, 0, 0, block.timestamp, _newDeadline, _coin, 0);
        _idCounter.increment();
        } else{
            revert("only B or S");
        }
        
        emit _dealEvent( _current,  _coin,  true);
        return(true);
    }

    function deadlineCal(uint256 _deadlineInDays)internal view returns(uint256){
        // TODO> hacer test a esta funcion y revisar que el _newDeadline funcione en createDeal
            uint256 _defaultDeadline = _deadlineCal(_deadlineInDays, defaultLifeTime);
            return(_defaultDeadline); 
        
    }
    
    function depositGoods(uint256 _dealID)public openDeal(_dealID) isPartTaker(_dealID) { 
        // TODO> Pendiente por hacer Test para el require Allowance
        _token = IERC20 (tokens[deals[_dealID].coin]);
        require(_token.allowance(msg.sender, address(this)) >= deals[_dealID].amount, "increaseAllowance to ERC20 contract");
        require(deals[_dealID].buyer == msg.sender, "only buyer");


        (bool _success) =_token.transferFrom(msg.sender, address(this), deals[_dealID].amount);
        if(!_success) revert();
        
        deals[_dealID].goods += deals[_dealID].amount;
    }

    function payDeal(uint256 _dealID)internal openDeal(_dealID) returns(bool){
        // TODO> Agregar anti Reentry Guard
        _token = IERC20 (tokens[deals[_dealID].coin]);
        uint256 _fee = feeCalculation(deals[_dealID].amount);

        require(_fee > 0, "Fee > 0");
        require(deals[_dealID].goods > 0, "No tokens ");
        require(deals[_dealID].goods == deals[_dealID].amount, "Goods and Amount diff value");

        //closing the Deal as completed
        deals[_dealID].status = 2;

        (bool flagAmountFee, uint256 _newAmount)= SafeMath.trySub(deals[_dealID].amount, _fee);
        if(!flagAmountFee) revert();

        deals[_dealID].goods = 0;
        acceptance[_dealID].buyerChoose = 3;
        acceptance[_dealID].sellerChoose = 3;

        // send the Fee to owner
        (bool _success)=_token.transfer(owner, _fee);
        if(!_success) revert();
        // send to Seller tokens
        (bool _successSeller) = _token.transfer(deals[_dealID].seller, _newAmount);
        if(!_successSeller) revert();

        return(true);
    }

    function refundBuyer(uint256 _dealID)internal openDeal(_dealID) returns(bool){
        // TODO> Agregar anti Reentry Guard
        // TODO> pendiente de testear el calculo del penalty
        _token = IERC20 (tokens[deals[_dealID].coin]);
        
        require(deals[_dealID].goods > 0, "No tokens ");
        require(deals[_dealID].goods == deals[_dealID].amount, "Goods and Amount diff value");

        deals[_dealID].status = 3; //cancel
        uint256 _refundAmount = deals[_dealID].goods;
        deals[_dealID].goods = 0;
        acceptance[_dealID].buyerChoose = 4;
        acceptance[_dealID].sellerChoose = 4;
        
        uint256 _newPenalty = (defaultPenalty * 10 ** tokenDecimal[deals[_dealID].coin]);
        (bool flagPenalty, uint256 _newamount)= SafeMath.trySub(_refundAmount, _newPenalty);
        if(!flagPenalty) revert();

        uint256 _penaltyFee = _refundAmount -= _newamount;
        // send the Fee to owner
        (bool _success)=_token.transfer(owner, _penaltyFee);
        if(!_success) revert();
       
        (bool _successBuyer)= _token.transfer(deals[_dealID].buyer, _newamount);
        if(!_successBuyer) revert();

        return(true);
    }

    function feeCalculation(uint256 _amount)internal view returns (uint256){
        uint256 _newAmount = _feeCalculation(_amount,  defaultFee);
        return(_newAmount);
    }

    function acceptDraft(uint256 _dealID, bool _decision)public openDraft(_dealID) isPartTaker(_dealID){
        if(msg.sender == deals[_dealID].buyer){
            acceptance[_dealID].buyerAcceptDraft = _decision;
        }
        if(msg.sender == deals[_dealID].seller){
            acceptance[_dealID].sellerAcceptDraft = _decision;
        }
        if(acceptance[_dealID].buyerAcceptDraft == true && acceptance[_dealID].sellerAcceptDraft == true ){
            deals[_dealID].status = 1;
        }
    }

    function partTakerDecision(uint256 _dealID, uint8 _decision)public isPartTaker(_dealID) openDeal(_dealID){
        require(deals[_dealID].goods == deals[_dealID].amount, "Buyer needs send the tokens");
        require((_decision > 0 && _decision < 3), "1 = Accepted, 2 = Cancelled");
        if(msg.sender == deals[_dealID].buyer){
            acceptance[_dealID].buyerChoose = _decision;
        }
        if(msg.sender == deals[_dealID].seller){
            acceptance[_dealID].sellerChoose = _decision;
        }
    }


    function cancelDeal(uint256 _dealID)public isPartTaker(_dealID) openDeal(_dealID) {
        //both want to cancel and finish
        require(msg.sender == deals[_dealID].buyer,"Only Buyer");
        require((acceptance[_dealID].buyerChoose == 2 && acceptance[_dealID].sellerChoose == 2),"B&S must be agree");
            
        (bool _flag) = refundBuyer(_dealID);
        if(!_flag) revert();

    }

    function completeDeal(uint256 _dealID)public isPartTaker(_dealID) openDeal(_dealID) {
        //both want to proceed and finish
        require(msg.sender == deals[_dealID].seller, "Only Seller");
        require((acceptance[_dealID].buyerChoose == 1 && acceptance[_dealID].sellerChoose == 1),"B&S must be agree");

        (bool _flag) = payDeal(_dealID);
        if(!_flag) revert();


    }

    function buyerAskDeadline(uint256 _dealID)public isPartTaker(_dealID) openDeal(_dealID){
        // agregar validacion de cuando se pueda solicitar en el deal
        require(msg.sender == deals[_dealID].buyer,"Only Buyer");
        require(deals[_dealID].deadline < block.timestamp, "Seller have time");

        (bool _flag) = refundBuyer(_dealID);
        if(!_flag) revert();
    }

    // Oracle
    // => Oracle forze Refund
    //      - Cuando deadline ha sido alcanzado y seller tiene status 0 (sin contestar)
    //      - Cuando deadline ha sido alcanzado, buyer y seller tienen status 0 (sin contestar)
    // => Oracle forze pay
    //      - Cuando deadline ha sido alcanzado y buyer tiene status agreement=0 (sin contestar) y seller status agreement=1
    //      - Cuando deadline ha sido alcanzado, buyer y seller tienen status agreement=1
}