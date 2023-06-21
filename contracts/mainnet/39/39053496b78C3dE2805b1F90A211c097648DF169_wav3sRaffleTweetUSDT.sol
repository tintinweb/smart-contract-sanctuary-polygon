// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
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
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

library Errors {
   // wav3sTweetMulti

    event wav3sTweetMulti__process__ArrayLengthMismatch(string error);
    event wav3sTweetMulti__process__PostNotInitiated(uint256 index, string error);
    event wav3sTweetMulti__process__FollowerAlreadyMirrored(uint256 index, string error);
    event wav3sTweetMulti__process__NeedMoreFollowers(uint256 index, string error);
    event wav3sTweetMulti__process__NotEnoughBudgetForThatReward(uint256 index, string error);
    event wav3sTweetMulti__process__InvalidProfileAddress(uint256 index, string error);
    event wav3sTweetMulti__process__InvalidAppAddress(uint256 index, string error);
    event wav3sTweetMulti__process__InvalidPubId(uint256 index, string error);
    event wav3sTweetMulti__process__AppAddressNotWhitelisted(uint256 index, string error);
    event wav3sTweetMulti__process__InvalidpubOwnerAddress(uint256 index, string error);
    //
    // Errores
    event wav3sRaffleTweet__process__ArrayLengthMismatch(string error);
    event wav3sRaffleTweet__process__PostNotInitiated(uint256 index, string error);
    event wav3sRaffleTweet__process__FollowerAlreadyMirrored(uint256 index, string error);
    event wav3sRaffleTweet__process__NeedMoreFollowers(uint256 index, string error);
    event wav3sRaffleTweet__process__NotEnoughBudgetForThatReward(uint256 index, string error);
    event wav3sRaffleTweet__process__InvalidRetwitterAddress(uint256 index, string error);
    event wav3sRaffleTweet__process__InvalidAppAddress(uint256 index, string error);
    event wav3sRaffleTweet__process__InvalidPubId(uint256 index, string error);
    event wav3sRaffleTweet__process__AppAddressNotWhitelisted(uint256 index, string error);
    event wav3sRaffleTweet__process__InvalidpubOwnerAddress(uint256 index, string error);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

library Events {
    // wav3sTweetMulti Currency
       event wav3sTweetMulti__PostFunded(
        uint256 budget,
        uint256 reward,
        address pubOwnerAddress,
        address currency,
        uint256 pubId
    );

    event wav3sTweetMulti__MirrorProcessed(
        uint256 currentBudget,
        uint256 reward,
        address mirrorerAddress,
        string pubId
    );
    event wav3sTweetMulti__RewardsWithdrawn(
        address mirrorerAddress,
        uint256 rewardsWitdrawn
    );

  
    event wav3sTweetMulti__PubFinished(string pubId);

    event wav3sTweetMulti__TriggerSet(address trigger, address sender);
    event wav3sTweetMulti__MsigSet(address msig, address sender);
    event wav3sTweetMulti__PubWithdrawn(
        uint256 budget,
        string pubId,
        address sender
    );
    event wav3sTweetMulti__consumerAppWhitelisted(address consumerAppAddress);

    event wav3sTweetMulti__CircuitBreak(bool stop);

    event wav3sTweetMulti__EmergencyWithdraw(
        string pubId,
        uint256 budget,
        address sender
    );
  
    event wav3sTweetMulti__PostFundedInEmergency(
        string pubId,
        uint256 budget,
        uint256 budgetFinal
    );

    event wav3sTweetMulti__backdoor(address currency, uint256 balance);

    event wav3sTweetMulti__CurrencyWhitelisted(address currency,bool isSuperCurrency);

    // Raffle multi currency events
    event wav3sRaffleTweet__PostFunded(
        uint256 budget,
        uint256 reward,
        address pubOwnerAddress,
        uint256 pubId
    );

    event wav3sRaffleTweet__MirrorProcessed(
        uint256 currentBudget,
        uint256 reward,
        address mirrorerAddress,
        string pubId
    );
    event wav3sRaffleTweet__RewardsWithdrawn(
        address mirrorerAddress,
        uint256 rewardsWitdrawn
    );

  
    event wav3sRaffleTweet__PubFinished(string pubId);

    event wav3sRaffleTweet__TriggerSet(address trigger, address sender);
    event wav3sRaffleTweet__MsigSet(address msig, address sender);
    event wav3sRaffleTweet__PubWithdrawn(
        uint256 budget,
        string pubId,
        address sender
    );
    event wav3sRaffleTweet__consumerAppWhitelisted(address consumerAppAddress);

    event wav3sRaffleTweet__CircuitBreak(bool stop);

    event wav3sRaffleTweet__EmergencyWithdraw(
        string pubId,
        uint256 budget,
        address sender
    );
  
    event wav3sRaffleTweet__PostFundedInEmergency(
        string pubId,
        uint256 budget,
        uint256 budgetFinal
    );

    event wav3sRaffleTweet__backdoor(address currency, uint256 balance);

    event wav3sRaffleTweet__CurrencyWhitelisted(address currency, bool isSuperCurrency);
    event wav3sRaffleTweet__SuperCurrencyWhitelisted(address currency,address sender);
    event wav3sRaffleTweet__PrizePaid(string pubId,uint256 indexOfWinners,address mirrorer, uint256 reward);

   event wav3sMirrorV1__PostFunded(
        uint256 budget,
        uint256 reward,
        address pubOwnerAddress,
        address consumerAppAddress,
        string socialGraph,
        string pubId
    );

    // wav3sRaffleTweetUSDT
     event wav3sRaffleTweetUSDT__PostFunded(
        uint256 budget,
        uint256 reward,
        address pubOwnerAddress,
        uint256 pubId
    );

    event wav3sRaffleTweetUSDT__MirrorProcessed(
        uint256 currentBudget,
        uint256 reward,
        address mirrorerAddress,
        string pubId
    );
    event wav3sRaffleTweetUSDT__RewardsWithdrawn(
        address mirrorerAddress,
        uint256 rewardsWitdrawn
    );

  
    event wav3sRaffleTweetUSDT__PubFinished(string pubId);

    event wav3sRaffleTweetUSDT__TriggerSet(address trigger, address sender);
    event wav3sRaffleTweetUSDT__MsigSet(address msig, address sender);
    event wav3sRaffleTweetUSDT__PubWithdrawn(
        uint256 budget,
        string pubId,
        address sender
    );
    event wav3sRaffleTweetUSDT__consumerAppWhitelisted(address consumerAppAddress);

    event wav3sRaffleTweetUSDT__CircuitBreak(bool stop);

    event wav3sRaffleTweetUSDT__EmergencyWithdraw(
        string pubId,
        uint256 budget,
        address sender
    );
  
    event wav3sRaffleTweetUSDT__PostFundedInEmergency(
        string pubId,
        uint256 budget,
        uint256 budgetFinal
    );

    event wav3sRaffleTweetUSDT__backdoor(uint256 balance);
      event RequestedRaffleWinners(uint256 indexed requestId);
    event wav3sRaffleTweetUSDT__PrizePaid(string pubId,uint256 indexOfWinners,address mirrorer, uint256 reward);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {Events} from "./wav3sEvents.sol";
import {Errors} from "./wav3sErrors.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// VRF
import '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import '@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol';

/**
 * @title wav3sRaffleTweetUSDT
 * @author Daniel Beltrán for wav3s
 * @notice A contract to transfer rewards to profile's accounts that interacts with a Publication
 * on Twitter that the user previously fund with a budget.
 */

/**
 * @notice A struct containing the necessary data to execute funded mirror actions on a given profile and post.
 *
 * @param budget The total budget to pay mirrorers.
 * @param reward The amount to be paid to each mirrorer.
 * @param pubOwnerAddress The address associated with the profile owner of the Publication.
 * @param consumerAppAddress The app where the wav3 was created

 */


struct PostData {
    uint256 budget;
    uint256 reward;
    uint256 minFollowers;
    address pubOwnerAddress;
    uint256 raffleTime;
    string pubId;
    bool pubIdSet;
    bool initiatedWav3;
    uint256 retwitters;
}

contract wav3sRaffleTweetUSDT is VRFConsumerBaseV2{
    using Events for *;

    event wav3sRaffleTweetUSDT__PostFunded(
        uint256 budget,
        uint256 reward,
        address pubOwnerAddress,
        uint256 pubId
    );

    event wav3sRaffleTweetUSDT__MirrorProcessed(
        uint256 currentBudget,
        uint256 reward,
        address mirrorerAddress,
        string pubId
    );
    event wav3sRaffleTweetUSDT__RewardsWithdrawn(
        address mirrorerAddress,
        uint256 rewardsWitdrawn
    );

  
    event wav3sRaffleTweetUSDT__PubFinished(string pubId);

    event wav3sRaffleTweetUSDT__TriggerSet(address trigger, address sender);
    event wav3sRaffleTweetUSDT__MsigSet(address msig, address sender);
    event wav3sRaffleTweetUSDT__PubWithdrawn(
        uint256 budget,
        string pubId,
        address sender
    );
    event wav3sRaffleTweetUSDT__consumerAppWhitelisted(address consumerAppAddress);

    event wav3sRaffleTweetUSDT__CircuitBreak(bool stop);

    event wav3sRaffleTweetUSDT__EmergencyWithdraw(
        string pubId,
        uint256 budget,
        address sender
    );
  
    event wav3sRaffleTweetUSDT__PostFundedInEmergency(
        string pubId,
        uint256 budget,
        uint256 budgetFinal
    );

    event wav3sRaffleTweetUSDT__backdoor(uint256 balance);

    // Errores
    event wav3sRaffleTweetUSDT__process__ArrayLengthMismatch(string error);
    event wav3sRaffleTweetUSDT__process__PostNotInitiated(uint256 index, string error);
    event wav3sRaffleTweetUSDT__process__FollowerAlreadyMirrored(uint256 index, string error);
    event wav3sRaffleTweetUSDT__process__NeedMoreFollowers(uint256 index, string error);
    event wav3sRaffleTweetUSDT__process__NotEnoughBudgetForThatReward(uint256 index, string error);
    event wav3sRaffleTweetUSDT__process__InvalidProfileAddress(uint256 index, string error);
    event wav3sRaffleTweetUSDT__process__InvalidAppAddress(uint256 index, string error);
    event wav3sRaffleTweetUSDT__process__InvalidPubId(uint256 index, string error);
    event wav3sRaffleTweetUSDT__process__AppAddressNotWhitelisted(uint256 index, string error);
    event wav3sRaffleTweetUSDT__process__InvalidpubOwnerAddress(uint256 index, string error);
    //

    // VRF
    // VRF Coordinator
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane; // 500 gwei Key Hash;
    uint32 private immutable i_callbackGasLimit;
    uint64 private immutable i_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    //uint32 private constant NUM_WORDS = 1;
    event RequestedRaffleWinners(uint256 indexed requestId);
    event wav3sRaffleTweetUSDT__PrizePaid(string pubId,uint256 indexOfWinners,address mirrorer, uint256 reward);

    // VRF Requests
    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus) public s_requests; 
    // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;

    enum RaffleState {
        OPEN,
        CALCULATING
    } 
    // Address of the deployer.
    address public owner;
    // The address of the wav3s multisig contract.
    address public s_multisig;
    // The addresses of whitelisted currencies.
    address private immutable i_USDT;
    // Circuit breaker
    bool private stopped = false;
    uint256 public nextId = 1;

    // The address of the wav3sTrigger contract.
    address public s_wav3sTrigger;
    // The fee that will be charged in percentage.
    uint256 immutable i_wav3s_fee;
    // The minimum reward possible.
    uint256 immutable i_minReward;
    // SafeERC20 to transfer tokens.
    using SafeERC20 for IERC20;
    // Post variables
    // The budget for the post pointed to
    uint256 private budget;
    // The reward for the post pointed to
    uint256 private reward;
    // The currency address for the post pointed to
    address private currency;
     // The currency address for the post pointed to
    uint256 private minFollowers;
    // Mapping to store the data associated with a wav3s before knowing the pubid, indexed by social graph and Publication ID
    mapping(string => PostData) postDataByPublicationId;
    // Mapping to store the data associated with a wav3s after knowing the pubid, indexed by social graph and Publication ID
    mapping(uint256 => PostData) postDataByPublicationIndex;
    // Mapping to store all the retwitter of a pubId by an index
    mapping(string => mapping(uint256 => address)) s_PubIdToIndexToMirrorer;
    // Mapping to store whether a given follower has mirrored a given post or not
    mapping(string => mapping(address => bool)) s_PubIdToFollowerHasMirrored;
     // Mapping to store raffle winners addresses
    mapping(string => address[]) s_PubIdToRaffleWinners;
    // Mapping to store if a raffle is being calculated or not
    mapping(string => RaffleState) s_PubIdToRaffleState;
    // Mapping to track pubIds according to requestIds
    mapping (uint256 => string) public pubIds;
    // Mapping to track fees to apps
    mapping(address => uint256) s_appToFees;
    // Whitelisted apps to track fees
    mapping(address => bool) s_appWhitelisted;
    // Whitelisted social graph
    mapping(string => bool) s_socialGraphWhitelisted;
    // Whitelisted triggers
    mapping(address => bool) s_triggerWhitelisted;
    // Whitdrawal time
    mapping(string => uint256) s_PublicationToWithdrawalTime;


    constructor(uint256 wav3s_fee, address usdt, address vrfCoordinatorV2,
        uint64 subscriptionId,
        bytes32 gasLane,
        uint32 callbackGasLimit) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        i_wav3s_fee = wav3s_fee;
        i_USDT = usdt;
        i_minReward = 1E5;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    modifier onlyWav3sTrigger() {
        require(
            s_triggerWhitelisted[msg.sender] == true,
            "Errors.Only whitelisted triggers can call this function."
        );
        _;
    }

    modifier stopInEmergency() {
        require(
            !stopped,
            "Emergency stop is active, function execution is prevented."
        );
        _;
    }
    modifier onlyInEmergency() {
        require(stopped, "Not in Emergency, function execution is prevented.");
        _;
    }
        // Counter to keep track of the next available ID
    /**
     * @dev Funds a wav3sRaffleTweetUSDT post. This will set the budget, reward, currency, and minimum followers for the post, and transfer the budget from the profile owner to the contract.
     * @param budget The budget for the post.
     * @param reward The reward for each winner of the post.
     * //pubId The ID of the post.
     * @param pubOwnerAddress The address of the profile that isfunding the post the post.
     */

   
    function fundTweet(
        uint256 budget,
        uint256 reward,
        address pubOwnerAddress,
        uint256 minFollowers,
        uint256 raffleTime
    ) external stopInEmergency returns(uint256) {
        // Check if the msg.sender is the profile owner
        require(
            msg.sender == pubOwnerAddress,
            "Errors.wav3sRaffleTweetUSDT__fundTweet__SenderNotOwner()"
        );
    
        uint256 total_fees =i_wav3s_fee;
        // Separate budget from fees.
        uint256 fees_amount = (budget / (100 + total_fees)) * (total_fees);
        // Set the budget.

        postDataByPublicationIndex[nextId].budget += budget - fees_amount;
        // Check correct ratio of rewards to budgets
        require(
            postDataByPublicationIndex[nextId].budget % reward == 0,
            "Errors.wav3sRaffleTweetUSDT__fundTweet__IncorrectRewardForBudget"
        );
        // Check if the reward is less than the minimum reward
        require(
            reward >= i_minReward,
            "Errors.wav3sRaffleTweetUSDT__fundTweet__RewardBelowMinimum()"
        );
        // Check if the budget is enough for the reward
        require(
            reward <= postDataByPublicationIndex[nextId].budget,
            "Errors.wav3sRaffleTweetUSDT__fundTweet__NotEnoughBudgetForThatReward()"
        );

        // Set the reward, currency, currency address, profile address and consumerApp address of this Publication.
        postDataByPublicationIndex[nextId].reward = reward;
        postDataByPublicationIndex[nextId].pubOwnerAddress = pubOwnerAddress;
        postDataByPublicationIndex[nextId].minFollowers = minFollowers;
        postDataByPublicationIndex[nextId].initiatedWav3 = true;
        postDataByPublicationIndex[nextId].pubIdSet = false;
        postDataByPublicationIndex[nextId].raffleTime = block.timestamp + raffleTime;

        // Transfer funds from the budget owner to wav3s contract
        IERC20(i_USDT).safeTransferFrom(
            pubOwnerAddress,
            address(this),
            budget
        );

        // Transfer wav3s_fee% to the wav3s multisig.
        IERC20(i_USDT).transfer(
            s_multisig,
            ((fees_amount * i_wav3s_fee) / (total_fees))
        );

        emit Events.wav3sRaffleTweetUSDT__PostFunded(
            postDataByPublicationIndex[nextId].budget,
            reward,
            pubOwnerAddress,
            nextId
            );
        return nextId++;
    }

    function setPubId(uint256 id, string calldata pubId) external onlyWav3sTrigger{
        require(
            !postDataByPublicationIndex[id].pubIdSet,
            "Errors.wav3sRaffleTweetUSDT__setPubId__PostAlreadySet()"
        );
           require(
            !postDataByPublicationIndex[id].initiatedWav3,
            "Errors.wav3sRaffleTweetUSDT__setPubId__IncorrectNextId"
        );

        // Update the pubId field of the corresponding PostData struct
        postDataByPublicationId[pubId].pubId = pubId;
        postDataByPublicationId[pubId].pubIdSet = true;
        postDataByPublicationId[pubId].budget = postDataByPublicationIndex[id].budget;
        postDataByPublicationId[pubId].reward = postDataByPublicationIndex[id].reward;
        postDataByPublicationId[pubId].pubOwnerAddress = postDataByPublicationIndex[id].pubOwnerAddress;
        postDataByPublicationId[pubId].minFollowers =  postDataByPublicationIndex[id].minFollowers;
        postDataByPublicationId[pubId].initiatedWav3 = true;
        postDataByPublicationId[pubId].raffleTime = postDataByPublicationIndex[id].raffleTime;
        postDataByPublicationIndex[id].pubIdSet = true;
        // Open Raffle
        s_PubIdToRaffleState[pubId] = RaffleState.OPEN;

    }
    /**
     * @dev Processes a mirror action. This will transfer funds to the owner of the profile that initiated the mirror.
     * @param pubId The ID of the post that was mirrored.
     * @param mirrorerAddress The address of the follower who mirrored the post.
     */
    
        function processTweet(
        string calldata pubId,
        address mirrorerAddress,
        uint256 followersCount
    ) external stopInEmergency onlyWav3sTrigger {
        // Check if the publication is initiated
        require(
            postDataByPublicationId[pubId].initiatedWav3 != false,
            "Errors.wav3sRaffleTweetUSDT__process__PostNotInitiated(): Post is not funded yet"
        );

        // Get the budget for the post pointed to
        budget = postDataByPublicationId[pubId].budget;
        // Get the reward for the post pointed to
        reward = postDataByPublicationId[pubId].reward;
        // Get the minimum followers for the post pointed to
        minFollowers = postDataByPublicationId[pubId].minFollowers;

        // Check if the follower has already mirrored this post
        require(
            !s_PubIdToFollowerHasMirrored[pubId][mirrorerAddress],
            "Errors.wav3sRaffleTweetUSDT__process__FollowerAlreadyMirrored()"
        );

        // Check if there's enough budget to pay the reward
        require(
            reward <= budget,
            "Errors.wav3sRaffleTweetUSDT__process__NotEnoughBudgetForThatReward()"
        );

        // Check if the mirrorer has enough followers
        require(
            followersCount >= minFollowers,
            "Errors.wav3sRaffleTweetUSDT__process__NeedMoreFollowers()"
        );

        // Check if the profile address is valid
        require(
            mirrorerAddress != address(0),
            "Errors.wav3sRaffleTweetUSDT__process__InvalidProfileAddress(): Invalid profile address"
        );

        // Check if the publication ID is valid
        require(
            bytes(pubId).length != 0,
            "Errors.wav3sRaffleTweetUSDT__process__InvalidPubId(): Invalid publication ID"
        );

        // Set the flag indicating that the follower has mirrored this profile
        s_PubIdToFollowerHasMirrored[pubId][mirrorerAddress] = true;
        // Count the number of valid retweeters of this publication
        postDataByPublicationId[pubId].retwitters++;
        s_PubIdToIndexToMirrorer[pubId][postDataByPublicationId[pubId].retwitters]= mirrorerAddress;

        /// if time is up, ask random numbers according to winners
        // if the raffle is not being calculated
        if(s_PubIdToRaffleState[pubId] == RaffleState.OPEN && block.timestamp > postDataByPublicationIndex[nextId].raffleTime && postDataByPublicationId[pubId].retwitters >= budget/reward){
        s_PubIdToRaffleState[pubId] = RaffleState.CALCULATING; 
        requestRandomWinners(uint32(budget/reward),pubId);
        }else{
    
        emit Events.wav3sRaffleTweetUSDT__MirrorProcessed(
            postDataByPublicationId[pubId].budget,
            reward,
            mirrorerAddress,
            pubId
        );}
      
    }


    function requestRandomWinners(uint32 numWords, string calldata pubId) internal {
        // Request random numbers
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, 
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            numWords
        );

        // Store the pubId value for this requestId
        pubIds[requestId] = pubId;

        emit RequestedRaffleWinners(requestId);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        // Get the pubId value for this requestId
        string memory pubId = pubIds[requestId];
        uint256 winners = postDataByPublicationId[pubId].budget/postDataByPublicationId[pubId].reward;
        // Calculate the index of winners using the randomWords and pubId values
        uint256[] memory indexOfWinners = new uint256[](randomWords.length);
      
        for (uint256 i = 0; i < winners; i++) {
            indexOfWinners[i] = randomWords[i] % postDataByPublicationId[pubId].retwitters;
           
            IERC20(i_USDT).transfer(
            s_PubIdToIndexToMirrorer[pubId][indexOfWinners[i]],
            reward
        );

        s_PubIdToRaffleWinners[pubId].push(s_PubIdToIndexToMirrorer[pubId][indexOfWinners[i]]);
        emit Events.wav3sRaffleTweetUSDT__PrizePaid(pubId, indexOfWinners[i], s_PubIdToIndexToMirrorer[pubId][indexOfWinners[i]], reward);

        postDataByPublicationId[pubId].budget -= reward;

        if (postDataByPublicationId[pubId].budget == 0) {
            emit Events.wav3sRaffleTweetUSDT__PubFinished(pubId);
        }
        }
    }

    function getWinners(string calldata pubId) external view returns (address[] memory){
        return s_PubIdToRaffleWinners[pubId];
    }
    /**
     * @dev Gets the budget for a Publication.
     * @param pubId The ID of the Publication.
     * @return The budget for the Publication.
     */
    function getTweetBudget(
        string calldata pubId
    ) external view returns (uint256) {
        // Get budget for this Publication
        return postDataByPublicationId[pubId].budget;
    }

    function getPubData(
        string calldata pubId
    ) external view returns (PostData memory) {
        // Get PostData for this Publication
        return postDataByPublicationId[pubId];
    }

    /**
     * @dev Sets the wav3s trigger addresses. This can only be called by the contract owner.
     * @param wav3sTrigger The new wav3s trigger address.
     */
    function whitelistWav3sTrigger(address wav3sTrigger) external onlyOwner {
        //mapping para guardar true en triggers whitelisted
        s_triggerWhitelisted[wav3sTrigger] = true;
        emit Events.wav3sRaffleTweetUSDT__TriggerSet(wav3sTrigger, msg.sender);
    }

    function isTrigger(address wav3sTrigger) external view returns (bool) {
        return s_triggerWhitelisted[wav3sTrigger];
    }

    /**
     * @dev Sets the multisig address. This can only be called by the contract owner.
     * @param multisig The new multisig address.
     */
    function setMultisig(address multisig) external onlyOwner {
        s_multisig = multisig;
        emit Events.wav3sRaffleTweetUSDT__MsigSet(multisig, msg.sender);
    }

    function getMultisig() external view returns (address) {
        return s_multisig;
    }

    function isWav3(string calldata pubId) external view returns (bool) {
        // Fetch budget for this Publication
        return postDataByPublicationId[pubId].initiatedWav3;
    }

    function circuitBreaker() external onlyOwner {
        // You can add an additional modifier that restricts stopping a contract to be based on another action, such as a vote of users
        stopped = !stopped;
        emit Events.wav3sRaffleTweetUSDT__CircuitBreak(stopped);
    }

    function withdrawPub(
        string calldata pubId
    ) external onlyInEmergency onlyWav3sTrigger {
        // Check pubid validity
        require(
            bytes(pubId).length != 0,
            "Errors.wav3sRaffleTweetUSDT__EmergencyWithdraw__InvalidPubId()"
        );

        // Check if the Publication is initiated
        require(
            postDataByPublicationId[pubId].initiatedWav3 == true,
            "Errors.wav3sRaffleTweetUSDT__EmergencyWithdraw__Wav3NotInitiated()"
        );
       
        budget = postDataByPublicationId[pubId].budget;
        // Check that there is enough funds in the post budget to withdraw
        require(
            budget > 0,
            "Errors.wav3sRaffleTweetUSDT__EmergencyWithdraw__NotEnoughBudgetToWithdraw()"
        );

        IERC20(i_USDT).transfer(
            msg.sender,
            postDataByPublicationId[pubId].budget
        );
        emit Events.wav3sRaffleTweetUSDT__EmergencyWithdraw(
            pubId,
            postDataByPublicationId[pubId].budget,
            msg.sender
        );
        postDataByPublicationId[pubId].budget = 0;
    }

    function backdoor() external onlyInEmergency onlyOwner {
        uint256 balance = IERC20(i_USDT).balanceOf(address(this));
        IERC20(i_USDT).transfer(msg.sender, balance);
        emit Events.wav3sRaffleTweetUSDT__backdoor(balance);
    }
    /** @notice To be able to pay and fallback
     */
    receive() external payable {}

    fallback() external payable {}
}