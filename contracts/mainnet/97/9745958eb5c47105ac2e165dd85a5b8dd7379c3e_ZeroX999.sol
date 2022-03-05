/**
 *Submitted for verification at polygonscan.com on 2022-03-05
*/

// SPDX-License-Identifier: MIXED

// File @openzeppelin/contracts/token/ERC20/[email protected]
// License-Identifier: MIT
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
// License-Identifier: MIT
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

// File @openzeppelin/contracts/token/ERC20/utils/[email protected]
// License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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

// File @openzeppelin/contracts/utils/[email protected]
// License-Identifier: MIT
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
// License-Identifier: MIT
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
// License-Identifier: MIT
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

// File @openzeppelin/contracts/security/[email protected]
// License-Identifier: MIT
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

// File @chainlink/contracts/src/v0.8/interfaces/[email protected]
// License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// File @chainlink/contracts/src/v0.8/[email protected]
// License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {
  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// File @chainlink/contracts/src/v0.8/[email protected]
// License-Identifier: MIT
pragma solidity ^0.8.0;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {
  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 private constant USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface internal immutable LINK;
  address private immutable vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 => uint256) /* keyHash */ /* nonce */
    private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// File @chainlink/contracts/src/v0.8/[email protected]
// License-Identifier: MIT
pragma solidity ^0.8.0;

contract KeeperBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// File @chainlink/contracts/src/v0.8/interfaces/[email protected]
// License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easilly be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// File @chainlink/contracts/src/v0.8/[email protected]
// License-Identifier: MIT
pragma solidity ^0.8.0;


abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

// File contracts/ZeroX999.sol
// License-Identifier: MIT

pragma solidity ^0.8.0;







contract ZeroX999 is Ownable, Pausable, ReentrancyGuard, VRFConsumerBase, KeeperCompatibleInterface {
    using SafeERC20 for IERC20;

    bytes32 internal keyHash;
    uint256 internal fee;

    address public adminAddress; // address of the admin

    uint256 public rewardPool;
    uint256 public rewardCount;
    uint256 public betAmount;  // e.g. 1000000000000000000 wei = 1 token
    uint256 public minNotKillIndex;
    uint256 public treasuryFee; // treasury rate (e.g. 200 = 2%, 150 = 1.50%)
    uint256 public treasuryAmount; // treasury amount that was not claimed
    uint16 public maxRandomNumber;
    uint256 public constant MAX_TREASURY_FEE = 1000; // 10%
    uint16 public constant MAX_RANDOM_NUMBER = 999;

    uint16[] randomNumbers;

    mapping(uint16 => uint256) public currentNumberIndexes;
    mapping(address => uint256[]) public userIndexes;
    mapping(address => uint256) public userBalances;
    mapping(uint256 => RewardPath) public rewardPaths;

    CalculationQueue private calculationQueue;

    BetInfo[] public BetRecords;

    struct BetInfo {
        uint256 amount;
        bool isDone;
        uint16 randomNumber;
        uint256 reward;
        uint256 timestamp;
        address userAddress;
        bytes32 requestId;
        bool isGenerated;
        uint256 rewardPathId;
    }

    struct CalculationQueue {
        uint128 start;
        uint128 end;
        mapping(uint256 => CalculationQueueData) items;
    }

    struct CalculationQueueData {
        uint256 startIndex;
        uint256 endIndex;
    }

    struct RewardPath {
        uint256 id;
        uint256 startIndex;
        uint256 endIndex;
        uint256[] path;
    }

    event Claim(address indexed sender, uint256 amount);
    event NewAdminAddress(address admin);
    event NewTreasuryFee(uint256 indexed index, uint256 treasuryFee);
    event NewMaxRandomNumber(uint16 number);
    event NewBetAmount(uint256 amount);
    event RewardsCalculated(
        uint256 indexed startIndex,
        uint256 indexed endIndex,
        address firstAddress,
        address secondAddress,
        uint256 totalReward,
        uint256 treasuryAmount,
        uint256 rewardPool
    );
    event TreasuryClaim(uint256 amount);
    event Pause(uint256 indexed index);
    event Unpause(uint256 indexed index);
    event BetNumber(address indexed sender, uint256 indexed index, uint256 amount);

    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "Not admin");
        _;
    }

    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    constructor(
        address _adminAddress,
        uint256 _betAmount,
        uint256 _treasuryFee,
        uint16 _maxRandomNumber
    )
    VRFConsumerBase(
        0x3d2341ADb2D31f1c5530cDC622016af293177AE0, // VRF Coordinator (Mainnet)
        0xb0897686c545045aFc77CF20eC7A532E3120E0F1  // LINK Token (Mainnet)
    //        0x8C7382F9D8f56b33781fE506E897a4F1e2d17255, // VRF Coordinator (Testnet)
    //        0x326C977E6efc84E512bB9C30f76E30c160eD06FB  // LINK Token (Testnet)
    )
    {
        require(_betAmount >= 10000000000000000, "Bet amount too low");
        require(_treasuryFee <= MAX_TREASURY_FEE, "Treasury fee too high");
        require(_maxRandomNumber <= MAX_RANDOM_NUMBER, "Max random number too big");
        adminAddress = _adminAddress;
        betAmount = _betAmount;
        treasuryFee = _treasuryFee;
        maxRandomNumber = _maxRandomNumber;
        keyHash = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da;   // Mainnet
        //  keyHash = 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4;   // Testnet
        fee = 0.0001 * 10 ** 18;
        // 0.0001 LINK (Varies by network)
    }

    /**
     * Requests randomness
     */
    function _requestRandomNumber() internal returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        requestId = requestRandomness(keyHash, fee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        uint16 randomNumber = uint16(randomness % (maxRandomNumber + 1));

        randomNumbers.push(randomNumber);

        uint256 index = randomNumbers.length - 1;
        BetInfo storage betInfo = BetRecords[index];

        require(!betInfo.isGenerated, "Random number is not valid");

        betInfo.requestId = requestId;
        betInfo.randomNumber = randomNumber;
        betInfo.isGenerated = true;

        BetInfo storage beforeBetInfo = BetRecords[currentNumberIndexes[randomNumber]];

        if (
            index > 0 &&
            beforeBetInfo.randomNumber == randomNumber &&
            beforeBetInfo.userAddress != address(0) &&
            !beforeBetInfo.isDone
        ) {
            CalculationQueueData memory data;
            data.startIndex = currentNumberIndexes[randomNumber];
            data.endIndex = index;
            _enqueueCalculationQueue(calculationQueue, data);
        }

        currentNumberIndexes[randomNumber] = index;
    }

    /**
     * @notice Returns true if `account` is a contract.
     * @param account: account address
     */
    function _isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @notice called by the admin to pause, triggers stopped state
     * @dev Callable by admin or operator
     */
    function pause() external whenNotPaused onlyAdmin {
        _pause();

        emit Pause(BetRecords.length - 1);
    }

    /**
     * @notice called by the admin to unpause, returns to normal state
     * Reset genesis state. Once paused, the rounds would need to be kickstarted by genesis
     */
    function unpause() external whenPaused onlyAdmin {
        _unpause();
    }

    /**
     * @notice Set admin address
     * @dev Callable by owner
     */
    function setAdmin(address _adminAddress) external onlyOwner {
        require(_adminAddress != address(0), "Cannot be zero address");
        adminAddress = _adminAddress;

        emit NewAdminAddress(_adminAddress);
    }

    /**
     * @notice Set treasury fee
     * @dev Callable by admin
     */
    function setTreasuryFee(uint256 _treasuryFee) external whenPaused onlyAdmin {
        require(_treasuryFee <= MAX_TREASURY_FEE, "Treasury fee too high");
        treasuryFee = _treasuryFee;

        emit NewTreasuryFee(BetRecords.length - 1, _treasuryFee);
    }

    /**
     * @notice Set max random number
     * @dev Callable by admin
     */
    function setMaxRandomNumber(uint16 _maxRandomNumber) external whenPaused onlyAdmin {
        require(_maxRandomNumber <= MAX_RANDOM_NUMBER, "Max random number too big");
        maxRandomNumber = _maxRandomNumber;

        emit NewMaxRandomNumber(_maxRandomNumber);
    }

    /**
     * @notice Set treasury fee
     * @dev Callable by admin
     */
    function setBetAmount(uint256 _betAmount) external whenPaused onlyAdmin {
        require(_betAmount >= 10000000000000000, "Bet amount too low");
        betAmount = _betAmount;

        emit NewBetAmount(_betAmount);
    }

    /**
     * @notice Transfer tokens in a safe way
     * @param to: address to transfer tokens to
     * @param value: tokens amount to transfer (in wei)
     */
    function _safeTransfer(address to, uint256 value) internal {
        (bool success,) = to.call{value : value}("");
        require(success, "TransferHelper: TRANSFER_FAILED");
    }

    /**
     * @notice Claim all rewards in treasury
     * @dev Callable by admin
     */
    function claimTreasury() external nonReentrant onlyAdmin {
        uint256 currentTreasuryAmount = treasuryAmount;
        treasuryAmount = 0;
        _safeTransfer(adminAddress, currentTreasuryAmount);

        emit TreasuryClaim(currentTreasuryAmount);
    }

    function getCurrentIndex() public view returns (int256) {
        if (BetRecords.length == 0) {
            return (- 1);
        }
        return int256(BetRecords.length) - 1;
    }

    function betNumber() external payable whenNotPaused nonReentrant notContract {
        uint256 amount = msg.value;

        require(amount == betAmount, "Bet amount value is not valid");

        BetInfo memory betInfo;
        betInfo.amount = amount;
        betInfo.userAddress = msg.sender;
        betInfo.timestamp = block.timestamp;
        BetRecords.push(betInfo);

        uint256 currentIndex = BetRecords.length - 1;
        userIndexes[msg.sender].push(currentIndex);

        // Add to reward pool
        rewardPool += amount;

        _requestRandomNumber();

        emit BetNumber(msg.sender, currentIndex, amount);
    }

    /**
     * @notice Calculate rewards
     * @param startIndex: startIndex
     * @param endIndex: endIndex
     */
    function _calculateRewards(uint256 startIndex, uint256 endIndex) internal {
        require(BetRecords[startIndex].userAddress != address(0) && BetRecords[endIndex].userAddress != address(0), "Cannot be zero address");
        require(BetRecords[startIndex].randomNumber == BetRecords[endIndex].randomNumber, "Two random numbers are not equal");
        require(!BetRecords[startIndex].isDone && !BetRecords[endIndex].isDone, "This Record is done");

        uint256 reward;
        uint256 treasuryAmt;
        uint256 totalReward;

        rewardCount ++;
        RewardPath storage rewardPath = rewardPaths[rewardCount];
        rewardPath.id = rewardCount;
        rewardPath.startIndex = startIndex;
        rewardPath.endIndex = endIndex;

        for (uint256 i = startIndex; i <= endIndex; i++) {
            if (BetRecords[i].isDone)
                continue;
            totalReward += BetRecords[i].amount;
            BetRecords[i].isDone = true;
            BetRecords[i].rewardPathId = rewardCount;
            rewardPath.path.push(i);
        }

        treasuryAmt = totalReward * treasuryFee / 10000;
        reward = (totalReward - treasuryAmt) / 2;
        BetRecords[startIndex].reward = reward;
        BetRecords[endIndex].reward = reward;

        if (BetRecords[startIndex].userAddress == BetRecords[endIndex].userAddress) {
            uint256 startUserBalance = userBalances[BetRecords[startIndex].userAddress];
            userBalances[BetRecords[startIndex].userAddress] = startUserBalance + reward + reward;
        } else {
            uint256 startUserBalance = userBalances[BetRecords[startIndex].userAddress];
            uint256 endUserBalance = userBalances[BetRecords[endIndex].userAddress];
            userBalances[BetRecords[startIndex].userAddress] = startUserBalance + reward;
            userBalances[BetRecords[endIndex].userAddress] = endUserBalance + reward;
        }

        uint256 _rewardPool = rewardPool;
        rewardPool = _rewardPool - totalReward;
        // Add to treasury
        treasuryAmount += treasuryAmt;

        if (minNotKillIndex >= startIndex && minNotKillIndex <= endIndex) {
            minNotKillIndex = endIndex + 1;
        }

        emit RewardsCalculated(startIndex, endIndex, BetRecords[startIndex].userAddress, BetRecords[endIndex].userAddress, totalReward, treasuryAmount, rewardPool);
    }

    function _enqueueCalculationQueue(CalculationQueue storage queue, CalculationQueueData memory data) internal {
        queue.items[queue.end++] = data;
    }

    function _dequeueCalculationQueue(CalculationQueue storage queue) internal returns (CalculationQueueData memory data) {
        data = queue.items[queue.start];
        queue.start++;
        return data;
    }

    function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory performData) {
        CalculationQueueData memory queueData = calculationQueue.items[calculationQueue.start];
        upkeepNeeded = calculationQueue.start < calculationQueue.end && queueData.startIndex < queueData.endIndex;
        return (upkeepNeeded, bytes(""));
    }

    function performUpkeep(bytes calldata) external override {
        CalculationQueueData memory queueData = _dequeueCalculationQueue(calculationQueue);
        require(queueData.startIndex < queueData.endIndex, "Queue is invalid");
        if (!BetRecords[queueData.startIndex].isDone && !BetRecords[queueData.endIndex].isDone) {
            _calculateRewards(queueData.startIndex, queueData.endIndex);
        }
    }

    /**
     * @notice Claim reward amount
     */
    function claim() external nonReentrant notContract {
        // Initializes amount
        uint256 amount = userBalances[msg.sender];
        require(amount > 0, "Not eligible for claim");
        userBalances[msg.sender] = 0;
        _safeTransfer(address(msg.sender), amount);
        emit Claim(msg.sender, amount);
    }

    /**
     * @notice Returns bet information list
     * @param cursor: cursor
     * @param size: size
     */
    function getAllBetRecords(int256 cursor, uint256 size) external view returns (uint256, uint256[] memory, BetInfo[] memory, int256) {
        uint256 total = BetRecords.length;
        uint256 _cursor;
        uint256 length = size;

        _cursor = uint256(cursor);

        if (cursor < 0 && total > 0) {
            _cursor = total - 1;
        }

        if (length > 50) {
            length = 50;
        }

        if (length > _cursor) {
            length = _cursor + 1;
        }

        uint256[] memory indexes = new uint256[](length);
        BetInfo[] memory betInfo = new BetInfo[](length);

        for (uint256 i = 0; i < length; i++) {
            indexes[i] = _cursor - i;
            betInfo[i] = BetRecords[indexes[i]];
        }

        return (total, indexes, betInfo, int256(_cursor) - int256(length));
    }

    /**
     * @notice Returns bet information list for single user
     * @param user: user's address
     * @param cursor: cursor
     * @param size: size
     */
    function getUserBetRecords(address user, int256 cursor, uint256 size) external view returns (uint256, uint256[] memory, BetInfo[] memory, int256) {
        uint256 total = userIndexes[user].length;
        uint256 _cursor;
        uint256 length = size;

        if (length > 50) {
            length = 50;
        }

        _cursor = uint256(cursor);

        if (cursor < 0 && total > 0) {
            _cursor = total - 1;
        }

        if (length > _cursor) {
            length = _cursor + 1;
        }

        uint256[] memory indexes = new uint256[](length);
        BetInfo[] memory betInfo = new BetInfo[](length);

        for (uint256 i = 0; i < length; i++) {
            indexes[i] = userIndexes[user][_cursor - i];
            betInfo[i] = BetRecords[indexes[i]];
        }

        return (total, indexes, betInfo, int256(_cursor) - int256(length));
    }

    /**
     * @notice Get reward path of indexes
     * @param id: rewardId
     * @param cursor: cursor
     * @param size: size
     */
    function getRewardPath(uint256 id, uint256 cursor, uint256 size) external view returns (uint256, uint256, uint256, uint256[] memory, uint256) {
        uint256 total = rewardPaths[id].path.length;

        uint256 length = size;

        if (length > 50) {
            length = 50;
        }

        if (length > total - cursor) {
            length = total - cursor;
        }

        uint256[] memory indexes = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            indexes[i] = rewardPaths[id].path[cursor + i];
        }

        return (total, rewardPaths[id].startIndex, rewardPaths[id].endIndex, indexes, cursor + length);
    }

    /**
     * @notice Batch get BetInfo
     * @param indexes: array of indexes
     */
    function batchGetBetInfo(uint256[] memory indexes) external view returns (uint256, BetInfo[] memory) {
        require(indexes.length <= 50, "Too many indexes");

        uint256 total;

        BetInfo[] memory betInfo = new BetInfo[](total);

        for (uint256 i = 0; i < indexes.length; i++) {
            BetInfo memory _betInfo = BetRecords[indexes[i]];
            if (_betInfo.userAddress == address(0))
                continue;
            betInfo[i] = _betInfo;
            total ++;
        }

        return (total, betInfo);
    }

    /**
     * @notice It allows the admin to refund outstanding tokens to all users
     */
    function refund4All() external whenPaused onlyAdmin {
        uint256 currentIndex = BetRecords.length - 1;
        uint256 totalAmount;

        for (uint256 i = minNotKillIndex; i <= currentIndex; i++) {
            if (BetRecords[i].isDone)
                continue;
            BetRecords[i].isDone = true;
            userBalances[BetRecords[i].userAddress] += BetRecords[i].amount;
            totalAmount += BetRecords[i].amount;
        }

        rewardPool -= totalAmount;
        minNotKillIndex = currentIndex + 1;
    }

    /**
     * @notice It allows the admin to refund outstanding tokens for single bet record
     */
    function refund(uint256 index) external whenPaused onlyAdmin {
        require(BetRecords[index].amount > 0 && !BetRecords[index].isDone, "index is invalid");
        BetRecords[index].isDone = true;
        userBalances[BetRecords[index].userAddress] += BetRecords[index].amount;
        rewardPool -= BetRecords[index].amount;

        if (index == minNotKillIndex) {
            minNotKillIndex = index + 1;
        }
    }
}