/**
 *Submitted for verification at polygonscan.com on 2022-07-10
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

// File: @chainlink/contracts/src/v0.8/VRFRequestIDBase.sol


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

// File: @chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol


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

// File: @chainlink/contracts/src/v0.8/VRFConsumerBase.sol


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
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
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

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorInterface.sol


pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
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

// File: @openzeppelin/contracts/finance/PaymentSplitter.sol


// OpenZeppelin Contracts v4.4.1 (finance/PaymentSplitter.sol)

pragma solidity ^0.8.0;




/**
 * @title PaymentSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 *
 * NOTE: This contract assumes that ERC20 tokens will behave similarly to native tokens (Ether). Rebasing tokens, and
 * tokens that apply fees during transfers, are likely to not be supported as expected. If in doubt, we encourage you
 * to run tests before sending real value to this contract.
 */
contract PaymentSplitter is Context {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    mapping(IERC20 => uint256) private _erc20TotalReleased;
    mapping(IERC20 => mapping(address => uint256)) private _erc20Released;

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    constructor(address[] memory payees, uint256[] memory shares_) payable {
        require(payees.length == shares_.length, "PaymentSplitter: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20
     * contract.
     */
    function totalReleased(IERC20 token) public view returns (uint256) {
        return _erc20TotalReleased[token];
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Getter for the amount of `token` tokens already released to a payee. `token` should be the address of an
     * IERC20 contract.
     */
    function released(IERC20 token, address account) public view returns (uint256) {
        return _erc20Released[token][account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = address(this).balance + totalReleased();
        uint256 payment = _pendingPayment(account, totalReceived, released(account));

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _released[account] += payment;
        _totalReleased += payment;

        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function release(IERC20 token, address account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = token.balanceOf(address(this)) + totalReleased(token);
        uint256 payment = _pendingPayment(account, totalReceived, released(token, account));

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _erc20Released[token][account] += payment;
        _erc20TotalReleased[token] += payment;

        SafeERC20.safeTransfer(token, account, payment);
        emit ERC20PaymentReleased(token, account, payment);
    }

    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return (totalReceived * _shares[account]) / _totalShares - alreadyReleased;
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) private {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(_shares[account] == 0, "PaymentSplitter: account already has shares");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


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

// File: contracts/testStake.sol


pragma solidity ^0.8.7;


contract PolyWars is Ownable, VRFConsumerBase, PaymentSplitter {
    bytes32 internal keyHash;
    uint256 internal fee;

    IERC20 pchi; // pchi;
    IERC20 weth;
    IERC721 public Evilgotchi; // Evilgotchi;
    IERC721 public Polygotchi; // Polygotchi;
    AggregatorInterface internal ethChainFeed;
    AggregatorInterface internal maticChainFeed;

    bool public paused = true;

    enum Area { Grove, Jungle, Greenhouse, Battlezone}
    uint256[] public pEarningRate = [5, 15, 30, 90];
    uint256[] public pLossRate = [0, 10, 25, 80];

    uint8 public taxFreeDays = 3;
    uint8 public taxPercentage = 10;

    struct StakingPolygotchi {
        uint256 timestamp;
        address owner;
        Area area;
        uint256 loss;
    }

    struct StakingInfoPolygotchi {
        uint256 tokenId;
        uint256 timestamp;
        uint256 rewards;
        uint256 loss;
        uint256 area;
    }

    mapping(uint256 => StakingPolygotchi) public pStakings;
    mapping(address => uint256[]) public pStakingsByOwner;
    uint256[] public tokenByIndex;
    uint256 public battlezoneStakePrice = 5 * 10 ** 7;

    struct StakingEvilgotchi {
        uint256 timestamp;
        address owner;
        uint256 taxValue;
    }

    struct Poly {
        uint256 timestamp;
        uint256 dailyCount;
        uint256 steal;
    }

    struct StakingInfoEvilgotchi {
        uint256 tokenId;
        uint256 timestamp;
        uint256 rewards;
        uint256 taxRewards;
    }

    mapping(uint256 => StakingEvilgotchi) public eStakings;
    mapping(uint256 => Poly) public polys;
    mapping(address => uint256[]) public eStakingsByOwner;
    mapping(bytes32 => uint256) raids;
    uint256 public stakedEvilgotchiCount;
    uint256 public taxValue;
    uint256 public raidBasePrice = 2 * 10 ** 7;

    event CaughtByEvilgotchi(
        address indexed evilgotchiOwner,
        uint256 indexed evilgotchiId,
        uint256 indexed polygotchiId,
        uint256 lossAmount
    );

    constructor(
        address[] memory payees,
        uint256[] memory shares,
        address _admin,
        address _evilgotchi,
        address _polygotchi,
        address _pchi,
        address _weth,
        address _vrf,
        address _link,
        bytes32 _keyHash,
        uint256 _fee
    ) VRFConsumerBase (_vrf, _link) PaymentSplitter(payees, shares) {
        Evilgotchi = IERC721(_evilgotchi);
        Polygotchi = IERC721(_polygotchi);
        pchi = IERC20(_pchi);
        weth = IERC20(_weth);
        ethChainFeed = AggregatorInterface(0xF9680D99D6C9589e2a93a78A04A279e509205945);
        maticChainFeed = AggregatorInterface(0xAB594600376Ec9fD91F8e885dADF0CE036862dE0);
        keyHash = _keyHash;
        fee = _fee;
        IERC20(_link).approve(_admin, type(uint256).max);
        pchi.approve(_admin, type(uint256).max);
    }

    /*
        Evilgotchi functions
    **/

    // staking in control room
    function stakeEvilgotchi(uint256 tokenId) public {
        require(!paused, "Contract paused");
        require (msg.sender == Evilgotchi.ownerOf(tokenId), "Sender must be the owner");
        require(Evilgotchi.isApprovedForAll(msg.sender, address(this)));

        StakingEvilgotchi memory staking = StakingEvilgotchi(block.timestamp, msg.sender, taxValue);
        eStakings[tokenId] = staking;
        eStakingsByOwner[msg.sender].push(tokenId);
        Evilgotchi.transferFrom(msg.sender, address(this), tokenId);

        stakedEvilgotchiCount++;
    }

    // batch stake
    function batchStakeEvilgotchi(uint256[] memory tokenIds) external {
        for (uint8 i = 0; i < tokenIds.length; i++) {
            stakeEvilgotchi(tokenIds[i]);
        }
    }

    // un-staking from control room
    function unstakeEvilgotchi(uint256 tokenId) internal {
        StakingEvilgotchi storage staking = eStakings[tokenId];
        uint256[] storage stakedEvilgotchi = eStakingsByOwner[msg.sender];
        uint16 index = 0;
        for (; index < stakedEvilgotchi.length; index++) {
            if (stakedEvilgotchi[index] == tokenId) {
                break;
            }
        }
        require(index < stakedEvilgotchi.length, "Evilgotchi not found");
        stakedEvilgotchi[index] = stakedEvilgotchi[stakedEvilgotchi.length - 1];
        stakedEvilgotchi.pop();
        staking.owner = address(0);
        Evilgotchi.transferFrom(address(this), msg.sender, tokenId);
        stakedEvilgotchiCount--;
    }

    // claim Evilgotchi rewards
    function claimEvilgotchiRewards(uint256 tokenId, bool unstake) external {
        require(!paused, "Contract paused");
        uint256 netRewards = _claimEvilgotchi(tokenId);
        uint256 taxRewards = _claimTax(tokenId);

        if (unstake) {
            unstakeEvilgotchi(tokenId);
        }

        if (netRewards + taxRewards > 0) {
            require(pchi.transfer(msg.sender, netRewards + taxRewards));
        }
    }

    // batch Evilgotchi claim rewards
    function batchClaimEvilgotchiRewards(uint256[] memory tokenIds, bool unstake) external {
        require(!paused, "Contract paused");

        uint256 netRewards = 0;
        uint256 netTaxRewards = 0;
        for (uint8 i = 0; i < tokenIds.length; i++) {
            netRewards += _claimEvilgotchi(tokenIds[i]);
            netTaxRewards += _claimTax(tokenIds[i]);
        }

        if (netRewards + netTaxRewards > 0) {
            require(pchi.transfer(msg.sender, netRewards + netTaxRewards));
        }

        if (unstake) {
            for (uint8 i = 0; i < tokenIds.length; i++) {
                unstakeEvilgotchi(tokenIds[i]);
            }
        }
    }

    function _claimEvilgotchi(uint256 tokenId) internal returns (uint256) {
        require(Evilgotchi.ownerOf(tokenId) == address(this), "The Evilgotchi must be staked");
        StakingEvilgotchi storage staking = eStakings[tokenId];
        require(staking.owner == msg.sender, "Sender must be the owner");

        uint256 rewards = calculateEvilgotchiReward(tokenId);
        staking.timestamp = block.timestamp;

        return rewards;
    }

    function calculateEvilgotchiReward(uint256 tokenId) public view returns (uint256) {
        require(Evilgotchi.ownerOf(tokenId) == address(this), "The Evilgotchi must be staked");
        uint256 balance = pchi.balanceOf(address(this));
        uint256 dayCount = daysStaked(tokenId, 0);
        if (dayCount < 1 || balance == 0) {
            return 0;
        }
        uint256 n = dayCount - 1;
        uint256 r = (n*n + n) / 2 +  1 * dayCount;
        uint256 reward = r * 1 ether; // convert to wei
        return reward <= balance ? reward : balance;
    }

    function _claimTax(uint256 tokenId) internal returns (uint256) {
        require(Evilgotchi.ownerOf(tokenId) == address(this), "The Evilgotchi must be staked");
        StakingEvilgotchi storage staking = eStakings[tokenId];
        require(staking.owner == msg.sender, "Sender must be the owner");

        uint256 taxRewards = calculateTaxReward(tokenId);
        staking.taxValue = taxValue;
        return taxRewards;
    }

    function calculateTaxReward(uint256 tokenId) public view returns (uint256) {
        require(Evilgotchi.ownerOf(tokenId) == address(this), "The Evilgotchi must be staked");
        StakingEvilgotchi storage staking = eStakings[tokenId];

        if (staking.taxValue < taxValue) {
            uint256 tax = taxValue - staking.taxValue;
            return tax;
        } else {
            return 0;
        }
    }

    // Get Evilgotchi staking info by user
    function stakingInfoEvilgotchi(address owner) public view returns (StakingInfoEvilgotchi[] memory) {
        uint256 balance = stakedBalanceOf(owner, 0);
        StakingInfoEvilgotchi[] memory list = new StakingInfoEvilgotchi[](balance);

        for (uint16 i = 0; i < balance; i++) {
            uint256 tokenId = eStakingsByOwner[owner][i];
            StakingEvilgotchi memory staking = eStakings[tokenId];
            uint256 reward = calculateEvilgotchiReward(tokenId);
            uint256 taxRewards = calculateTaxReward(tokenId);
            list[i] = StakingInfoEvilgotchi(tokenId, staking.timestamp, reward, taxRewards);
        }

        return list;
    }

    // Raid
    function raid(uint256 tokenId) public payable {
        require(!paused, "Contract paused");
        require (msg.sender == Evilgotchi.ownerOf(tokenId), "Sender must be the owner");

        Poly storage poly = polys[tokenId];
        if (poly.timestamp == 0) {
            poly.timestamp = block.timestamp;
        }
        uint256 diff = block.timestamp - poly.timestamp;
        uint256 cost = raidCost(tokenId);

        if (msg.value > 0) {
            uint256 maticCost = MATICPrice(cost);
            require(msg.value >= maticCost, "You must pay the correct amount of MATIC");
        } else {
            uint256 allowance = weth.allowance(msg.sender, address(this));
            uint256 balance = weth.balanceOf(msg.sender);
            uint256 ethCost = ETHPrice(cost);
            require(allowance >= ethCost && balance >= ethCost, "You must pay the correct amount of ETH");
            weth.transferFrom(msg.sender, address(this), ethCost);
        }

        // reset the raid after one day
        if (diff > 1 days) {
            poly.timestamp = block.timestamp;
            poly.dailyCount = 1;
        } else {
            poly.dailyCount++;
        }

        // request a random number
        bytes32 requestId = requestRandomness(keyHash, fee);
        raids[requestId] = tokenId;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        uint256 evilgotchiId = raids[requestId];
        address evilgotchiOwner = Evilgotchi.ownerOf(evilgotchiId);
        require(evilgotchiOwner != address(0)); // ignore if it's null address
        uint256 index = randomness % Polygotchi.balanceOf(address(this));
        uint256 polygotchiTokenId = tokenByIndex[index];
        StakingPolygotchi storage staking = pStakings[polygotchiTokenId];
        if (staking.area == Area.Grove) {
            emit CaughtByEvilgotchi(evilgotchiOwner, evilgotchiId, 0, 0);
            return; // Grove
        }

        uint256 dayCount = daysStaked(polygotchiTokenId, 1);
        if (dayCount < taxFreeDays) {
            emit CaughtByEvilgotchi(evilgotchiOwner, evilgotchiId, 0, 0);
            return; // only applicable if daily count >= taxFreeDays
        }

        uint256 lossAmount = dayCount * pLossRate[uint256(staking.area)] * 1 ether;
        staking.loss += lossAmount;

        if (lossAmount > 0) {
            Poly storage poly = polys[evilgotchiId];
            poly.steal += lossAmount;
            pchi.transfer(evilgotchiOwner, lossAmount);
        }

        if (staking.area == Area.Battlezone) {
            claimPolygotchiRewards(polygotchiTokenId, true);
        }

        emit CaughtByEvilgotchi(evilgotchiOwner, evilgotchiId, polygotchiTokenId, lossAmount);
    }

    function raidCost(uint256 tokenId) public view returns (uint256) {
        Poly storage poly = polys[tokenId];
        uint256 m = 2 ** (poly.dailyCount);
        return raidBasePrice * m;
    }


    /*
        Polygotchi functions
    **/

    // staking
    function stakePolygotchi(uint256 tokenId, Area _area) public payable {
        require(!paused, "Contract paused");
        require (msg.sender == Polygotchi.ownerOf(tokenId), "Sender must be the owner");
        require(Polygotchi.isApprovedForAll(msg.sender, address(this)));

        if (_area == Area.Battlezone) {
            if (msg.value > 0) {
                uint256 maticCost = MATICPrice(battlezoneStakePrice);
                require(msg.value >= maticCost, "You must pay the correct amount of MATIC");
            } else {
                uint256 allowance = weth.allowance(msg.sender, address(this));
                uint256 balance = weth.balanceOf(msg.sender);
                uint256 ethCost = ETHPrice(battlezoneStakePrice);
                require(allowance >= ethCost && balance >= ethCost, "You must pay the correct amount of ETH");
                weth.transferFrom(msg.sender, address(this), ethCost);
            }
        }

        StakingPolygotchi memory staking = StakingPolygotchi(block.timestamp, msg.sender, _area, 0);
        pStakings[tokenId] = staking;
        pStakingsByOwner[msg.sender].push(tokenId);
        tokenByIndex.push(tokenId);

        Polygotchi.transferFrom(msg.sender, address(this), tokenId);
    }

    // batch stake
    function batchStakePolygotchi(uint256[] memory tokenIds, Area _area) external payable {
        for (uint8 i = 0; i < tokenIds.length; i++) {
            stakePolygotchi(tokenIds[i], _area);
        }
    }

    // un-staking Polygotchi
    function unstakePolygotchi(uint256 tokenId) internal {
        StakingPolygotchi storage staking = pStakings[tokenId];
        uint256[] storage stakedPolygotchi = pStakingsByOwner[msg.sender];
        uint16 index = 0;
        for (; index < stakedPolygotchi.length; index++) {
            if (stakedPolygotchi[index] == tokenId) {
                break;
            }
        }
        require(index < stakedPolygotchi.length, "Polygotchi not found");
        stakedPolygotchi[index] = stakedPolygotchi[stakedPolygotchi.length - 1];
        stakedPolygotchi.pop();

        tokenByIndex[index] = tokenByIndex[tokenByIndex.length - 1];
        tokenByIndex.pop();

        staking.owner = address(0);
        Polygotchi.transferFrom(address(this), msg.sender, tokenId);
    }

    // claim Polygotchi rewards
    function claimPolygotchiRewards(uint256 tokenId, bool unstake) public {
        require(!paused, "Contract paused");
        uint256 netRewards = _claimPolygotchi(tokenId);
        if (unstake) {
            unstakePolygotchi(tokenId);
        }
        if (netRewards > 0) {
            require(pchi.transfer(msg.sender, netRewards));
        }
    }

    // batch Polygotchi claim rewards
    function batchClaimPolygotchiRewards(uint256[] memory tokenIds, bool unstake) external {
        require(!paused, "Contract paused");

        uint256 netRewards = 0;
        for (uint8 i = 0; i < tokenIds.length; i++) {
            netRewards += _claimPolygotchi(tokenIds[i]);
        }

        if (netRewards > 0) {
            require(pchi.transfer(msg.sender, netRewards));
        }

        if (unstake) {
            for (uint8 i = 0; i < tokenIds.length; i++) {
                unstakePolygotchi(tokenIds[i]);
            }
        }
    }

    function _claimPolygotchi(uint256 tokenId) internal returns (uint256) {
        require(Polygotchi.ownerOf(tokenId) == address(this), "The Polygotchi must be staked");
        StakingPolygotchi storage staking = pStakings[tokenId];
        require(staking.owner == msg.sender, "Sender must be the owner");

        uint256 rewards = calculatePolygotchiReward(tokenId);
        require(rewards >= staking.loss, "You have no rewards at this time");
        rewards -= staking.loss;
        uint256 tax = daysStaked(tokenId, 1) >= taxFreeDays ? 0 : (taxPercentage * rewards ) / 100;
        uint256 netRewards = rewards - tax;

        if (stakedEvilgotchiCount > 0 && tax > 0) {
            taxValue += tax / stakedEvilgotchiCount;
        }

        staking.loss = 0;
        staking.timestamp = block.timestamp;

        return netRewards;
    }

    function calculatePolygotchiReward(uint256 tokenId) public view returns (uint256) {
        require(Polygotchi.ownerOf(tokenId) == address(this), "The Polygotchi must be staked");
        uint256 balance = pchi.balanceOf(address(this));
        StakingPolygotchi storage staking = pStakings[tokenId];
        uint256 dayCount = daysStaked(tokenId, 1);
        if (dayCount < 1 || balance == 0) {
            return 0;
        }
        uint256 n = dayCount - 1;
        uint256 r = (n*n + n) / 2 + pEarningRate[uint256(staking.area)] * dayCount;
        uint256 reward = r * 1 ether; // convert to wei
        return reward <= balance ? reward : balance;
    }

    // Get Polygotchi staking info by user
    function stakingInfoPolygotchi(address owner) public view returns (StakingInfoPolygotchi[] memory) {
        uint256 balance = stakedBalanceOf(owner, 1);
        StakingInfoPolygotchi[] memory list = new StakingInfoPolygotchi[](balance);

        for (uint16 i = 0; i < balance; i++) {
            uint256 tokenId = pStakingsByOwner[owner][i];
            StakingPolygotchi memory staking = pStakings[tokenId];
            uint256 reward = calculatePolygotchiReward(tokenId);
            list[i] = StakingInfoPolygotchi(tokenId, staking.timestamp, reward, staking.loss, uint256(staking.area));
        }

        return list;
    }

    // common
    function ETHPrice(uint256 price) public view returns (uint256) {
        uint256 v = uint256(ethChainFeed.latestAnswer()); // Get real value
        return 1 ether * price / v;
    }

    function MATICPrice(uint256 price) public view returns (uint256) {
        uint256 v = uint256(maticChainFeed.latestAnswer()); // Get real value
        return 1 ether * price / v;
    }

    function daysStaked(uint256 tokenId, uint256 collection) public view returns (uint256) {
        if (collection == 0) {
            // Evilgotchi
            StakingEvilgotchi storage staking = eStakings[tokenId];
            uint256 diff = block.timestamp - staking.timestamp;
            return uint256(diff) / (1 days);
        } else {
            // Polygotchi
            StakingPolygotchi storage staking = pStakings[tokenId];
            uint256 diff = block.timestamp - staking.timestamp;
            return uint256(diff) / (1 days);
        }
    }

    function stakedBalanceOf(address owner, uint256 collection) public view returns (uint256) {
        if (collection == 0) {
            // Evilgotchi
            return eStakingsByOwner[owner].length;
        } else {
            // Polygotchi
            return pStakingsByOwner[owner].length;
        }
    }

    /*
        Admin
    **/
    function togglePause() external onlyOwner {
        paused = !paused;
    }

    function withdraw(uint256 amount) external onlyOwner {
        payable(owner()).transfer(amount);
    }

    /**
    * @dev Function allows admin unstake in case of emergency.
    */
    function emergencyUnstake(uint256[] memory tokenIds, uint256 collection) external onlyOwner {
        require(tokenIds.length <= 50, "50 is max per tx");
        if (collection == 0) {
            // Evilgotchi
            for (uint8 i = 0; i < tokenIds.length; i++) {
                unstakeEvilgotchi(tokenIds[i]);
            }
        } else {
            // Polygotchi
            for (uint8 i = 0; i < tokenIds.length; i++) {
                unstakePolygotchi(tokenIds[i]);
            }
        }
    }

    /**
    * @dev Function allows users to unstake their ERC721 in case of emergency.
    */
    function emergencyUnstakeByUser(uint256[] memory tokenIds, uint256 collection) external {
        require(tokenIds.length <= 50, "50 is max per tx");
        if (collection == 0) {
            // Evilgotchi
            for (uint8 i = 0; i < tokenIds.length; i++) {
                require(Evilgotchi.ownerOf(tokenIds[i]) == address(this), "The Evilgotchi must be staked");
                StakingEvilgotchi storage staking = eStakings[tokenIds[i]];
                require(staking.owner == msg.sender, "Sender must be the owner");
                unstakeEvilgotchi(tokenIds[i]);
            }
        } else {
            // Polygotchi
            for (uint8 i = 0; i < tokenIds.length; i++) {
                require(Polygotchi.ownerOf(tokenIds[i]) == address(this), "The Polygotchi must be staked");
                StakingPolygotchi storage staking = pStakings[tokenIds[i]];
                require(staking.owner == msg.sender, "Sender must be the owner");
                unstakePolygotchi(tokenIds[i]);
            }
        }
    }
}