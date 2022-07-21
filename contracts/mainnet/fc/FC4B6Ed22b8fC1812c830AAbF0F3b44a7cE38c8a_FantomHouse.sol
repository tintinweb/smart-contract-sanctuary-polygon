/**
 *Submitted for verification at polygonscan.com on 2022-07-21
*/

/**
 *Submitted for verification at FtmScan.com on 2022-07-21
*/

/**
 *Submitted for verification at FtmScan.com on 2022-07-21
*/

/**
 *Submitted for verification at FtmScan.com on 2022-07-20
*/

pragma solidity ^0.8.0;
// File: @chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol


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

// File: @chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol


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

        (bool success,) = recipient.call{value : amount}("");
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

        (bool success, bytes memory returndata) = target.call{value : value}(data);
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

contract FantomHouse is VRFConsumerBaseV2, Ownable, ReentrancyGuard {
    VRFCoordinatorV2Interface COORDINATOR;
    using SafeERC20 for IERC20;

    // ChainLink VRF configs
    uint64 private s_subscriptionId = 6813;
    // rinkeby
    //    address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;
    // ftm testnet
    //    address vrfCoordinator = 0xbd13f08b8352A3635218ab9418E340c60d6Eb418;
    // ftm mainnet
    address vrfCoordinator = 0xAE975071Be8F8eE67addBC1A82488F1C24858067;

    // rinkeby
    //    bytes32 keyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;
    // ftm testnet
    //    bytes32 keyHash = 0x121a143066e0f2f08b620784af77cccb35c6242460b4a8ee251b4b416abaebd4;
    // ftm mainnet
    // 4000 Gwei 0xb4797e686f9a1548b9a2e8c68988d74788e0c4af5899020fb0c47784af76ddfa
    // 10000 Gwei 0x5881eea62f9876043df723cf89f0c2bb6f950da25e9dfe66995c24f919c8f8ab
    // 20000 Gwei 0x64ae04e5dba58bc08ba2d53eb33fe95bf71f5002789692fe78fb3778f16121c9
    bytes32 keyHash = 0xcc294a196eeeb44da2888d17c0625cc88d70d9760a69d58d853ba6581a9ab0cd; // 4000 Gwei Limit

    uint32 callbackGasLimit = 1500000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;

    uint256 maxBetPercent = 1000000000000000000; // default 1%
    uint256 minBet = 1000000000000000000; // default $1.00 USDC

    uint256 payout = 1960000000000000000; // default 1.96x
    
    uint256 betFeePercent = 1000000000000000000; // default 1%
    uint256 bettingRefPercent = 100000000000000000; // default 0.1%
    
	uint256 minHouseDeposit = 500000000000000000000; // default $500 USDC
    uint256 housePoolDepositFeePercent = 500000000000000000; // default 0.5%
    uint256 houseDepositRefPercent = 100000000000000000; // default 0.1%

    address public treasuryWallet = 0xaCd13888a6c3427F90912c01F0fd184A40f3d806;
    address public virtualFTMaddress = 0x0000000000000000000000000000000000000000;
    // rinkeby test deca token
    //    address private constant USDC_ADDRESS = 0x7D27bf231804F562013218D925588e91dA70bf65;
    // ftm testnet
    //    address private constant USDC_ADDRESS = 0xBdBd9489e041c739292b93999b769CbAF1F798D6;
    // ftm mainnet
    address private constant USDC_ADDRESS = 0x8277D89ab24D43366C3370eE6940E7dA54D96eAb;
    //    address private constant USDC_ADDRESS = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;
    IERC20 private usdcToken = IERC20(USDC_ADDRESS);

    mapping(uint256 => BetRequest) public betRequest;
    uint256 betRequestSize;
    uint256 refundedUpTo = 1;

    struct RequestParams {
        address vrfCoordinator;
        bytes32 keyHash;
        uint32 callbackGasLimit;
        uint16 requestConfirmations;
        uint32 numWords;
    }

    struct PlayRecord {
        uint256 betAmount;
        uint256 headOrTail;
        uint256 resultHeadOrTail;
    }

    struct Balance {
        address userAddress;
        uint256 depositAmount;
        uint256 userContributionPortion;
    }

    struct BetRequest {
        uint256 requestId;
        address sender;
        uint256 predict;
        uint256 betAmount;
        uint256 timestamp;
        address referral;
    }

    Balance housePoolBalance;
    Balance treasuryPoolBalance;
    mapping(address => uint256) treasuryClaimed;
    mapping(address => uint256) rewardPool;
    mapping(address => PlayRecord[]) playRecords;
    mapping(address => uint256) myTotalWaged;

    Balance[] userHouseBalances;

    event RequestedBet(uint256 indexed requestId, address indexed requestUser, uint256 predictedUserFace, uint256 betAmount);
    event ReceivedBetResult(bool userWon, uint256 indexed requestId, address indexed requestUser, uint256 response, uint256 sortedUserFace, uint256 predictedUserFace, uint256 betAmount);

    bool pauseBet = false;
    bool pauseHouseDeposit = false;
    bool pauseHouseWithdraw = false;

    mapping(address => uint256) depositRefEarned;
    mapping(address => uint256) betRefEarned;

    constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
    }

    // ChainLink VRF params
    function setRequestParameters(
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        bytes32 _keyHash,
        uint64 subscriptionId
    ) external onlyOwner() {
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
        keyHash = _keyHash;
        s_subscriptionId = subscriptionId;
    }

    /* =================== Modifier =================== */
    modifier onlyTreasury() {
        require(msg.sender == treasuryWallet, "Only Treasury");
        _;
    }

    /* ========== VIEW FUNCTIONS ========== */
	
	function getMinHouseDeposit() public view returns (uint256){
	    return minHouseDeposit;
    }
	
    function getBetRefEarned(address _address) public view returns (uint256){
        return betRefEarned[_address];
    }

    function getDepositRefEarned(address _address) public view returns (uint256){
        return depositRefEarned[_address];
    }

    function getHouseDepositRefPercent() public view returns (uint256){
        return houseDepositRefPercent;
    }

    function getBettingRefPercent() public view returns (uint256){
        return bettingRefPercent;
    }

    function getMyTotalWaged(address _address) public view returns (uint256){
        return myTotalWaged[_address];
    }

    function getUserContributionPortion(uint256 index) public view returns (uint256){
        return userHouseBalances[index].userContributionPortion;
    }

    function getRefundedUpTo() public view returns (uint256){
        return refundedUpTo;
    }

    function getRequestParams() public view returns (RequestParams memory){
        return RequestParams({
        vrfCoordinator : vrfCoordinator,
        keyHash : keyHash,
        callbackGasLimit : callbackGasLimit,
        requestConfirmations : requestConfirmations,
        numWords : numWords
        });
    }

    // Displays the Current Payout schedule.
    function getPayout() public view returns (uint256) {
        return payout;
    }

    // Displays the current house pool deposit fee.
    function getHousePoolDepositFeePercent() public view returns (uint256) {
        return housePoolDepositFeePercent;
    }

    // Displays the current bet fee.
    function getBetFeePercent() public view returns (uint256) {
        return betFeePercent;
    }

    // Displays the Current House Pool Balance.
    function getHousePoolBalance() public view returns (uint256) {
        return housePoolBalance.depositAmount;
    }

    // Displays the Current Max Bet amount.
    function getMaxBetPercent() public view returns (uint256){
        return maxBetPercent;
    }

    // Displays the Current Min Bet amount. (ex: 1.0000, etc)
    function getMinBet() public view returns (uint256){
        return minBet;
    }

    function getRewardPoolBalance(address _address) public view returns (uint256) {
        return rewardPool[_address];
    }

    // Takes Input of Wallet Address, displays the user’s House Pool Contribution Balance.
    function getUserHouseBalance(address _address) public view returns (uint256) {
        for (uint256 i = 0; i < userHouseBalances.length; i++) {
            if (_address == userHouseBalances[i].userAddress) {
                return userHouseBalances[i].depositAmount;
            }
        }
        return 0;
    }

    // Takes input of Wallet Address, displays information / status of last 10 bets of the wallet.
    function getUserLastTenBetsHistory(address _address) public view returns (PlayRecord [] memory) {
        return playRecords[_address];
    }

    // CheckTreasuryBalance
    function getTreasuryBalance() public view returns (uint256) {
        return treasuryPoolBalance.depositAmount;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    // Takes input of USDC amount, provider deposits money to House Pool.
    function depositHouse(uint256 _amount, address _referral) external {
        require(pauseHouseDeposit == false, "pauseHouseDeposit");
        require(_amount >= minHouseDeposit, "check minimum house pool deposit amount");
		address _sender = msg.sender;
        uint256 depositFeePercent;
        if (_referral == address(0)) {
            depositFeePercent = housePoolDepositFeePercent;
        } else {
            depositFeePercent = housePoolDepositFeePercent - houseDepositRefPercent;
            uint256 referralReward = houseDepositRefPercent * _amount / 1e18 / 100;
            rewardPool[_referral] += referralReward;
            depositRefEarned[_referral] += referralReward;
        }
        uint256 fee = depositFeePercent * _amount / 1e18 / 100;
        treasuryPoolBalance.depositAmount += fee;
        fee = housePoolDepositFeePercent * _amount / 1e18 / 100; // For correct HousePool & userDeposit updates
        uint256 amountAfterFee = _amount - fee;
        housePoolBalance.depositAmount += amountAfterFee;
        bool newUserAddress = true;
        for (uint256 i = 0; i < userHouseBalances.length; i++) {
            Balance memory balance = userHouseBalances[i];
            if (_sender == balance.userAddress) {
                userHouseBalances[i].depositAmount += amountAfterFee;
                newUserAddress = false;
            }
            uint256 userContributionPortion = 1e18 * balance.depositAmount / housePoolBalance.depositAmount;
            userHouseBalances[i].userContributionPortion = userContributionPortion;
        }
        if (newUserAddress) {
            uint256 userContributionPortion = 1e18 * amountAfterFee / housePoolBalance.depositAmount;
            userHouseBalances.push(Balance(_sender, amountAfterFee, userContributionPortion));
        }
        usdcToken.safeTransferFrom(_sender, address(this), _amount);
    }

    // Takes input of USDC amount, provider withdraws money from House Pool.
    function withdrawHouse(uint256 _amount) external nonReentrant {
        require(pauseHouseWithdraw == false, "pauseHouseWithdraw");
        address _sender = msg.sender;
        require(_amount <= housePoolBalance.depositAmount, "exceed house pool amount");
        housePoolBalance.depositAmount -= _amount;
        for (uint256 i = 0; i < userHouseBalances.length; i++) {
            Balance memory userHouseBalance = userHouseBalances[i];
            if (_sender == userHouseBalance.userAddress) {
                uint256 _depositAmount = userHouseBalance.depositAmount;
                require(_amount <= _depositAmount, "exceed user house amount");
                userHouseBalances[i].depositAmount -= _amount;
            }
            userHouseBalances[i].userContributionPortion = 1e18 * userHouseBalance.depositAmount / housePoolBalance.depositAmount;
        }
        usdcToken.safeTransfer(msg.sender, _amount);
    }

    // Takes input of USDC amount, user withdraws money from reward pool.
    function withdrawReward(uint256 _amount) external nonReentrant {
        address _sender = msg.sender;
        uint256 reward = rewardPool[_sender];
        require(_amount <= reward, "reward amount");
        rewardPool[_sender] -= _amount;
        usdcToken.safeTransfer(msg.sender, _amount);
    }

    function claimTreasury(uint256 _amount) external onlyTreasury nonReentrant {
        require(getTreasuryBalance() > _amount, "exceed amount");
        treasuryPoolBalance.depositAmount -= _amount;
        usdcToken.safeTransfer(msg.sender, _amount);
    }

    // No Input, claims all USDC from Treasury Pool.
    function claimTreasuryAll() external onlyTreasury nonReentrant {
        uint256 _amount = getTreasuryBalance();
        require(_amount > 0, "exceed amount");
        treasuryPoolBalance.depositAmount -= _amount;
        usdcToken.safeTransfer(msg.sender, _amount);
    }

    // Takes input of MaxBet percentage Unit Number. Changes the % number that determines max bet amount.
    function setMaxBetPercent(uint256 _new) external onlyOwner {
        require(_new <= 5000000000000000000, "maximum bet amount can't be set larger than 5% of total house pool balance");
        maxBetPercent = _new;
    }

    // Takes input of MinBet Uint number.
    function setMinBet(uint256 _new) external onlyOwner {
        minBet = _new;
    }

    // Takes input of Payout Uint Number then divide by 100 as it's percentage, changes the Payout x.
    function setPayout(uint256 _new) external onlyOwner {
        require(_new <= 1980000000000000000 && _new >= 1850000000000000000, "payout must be between 1.85 and 1.98");
        payout = _new;
    }

    // Takes input of Fee Uint Number then divide by 100 as it's percentage, changes the Fee taken from house deposit fee for Treasury.
    function setHousePoolDepositFeePercent(uint256 _new) external onlyOwner {
        require(_new <= 1000000000000000000 && _new >= 100000000000000000, "bet fee percent must be between 0.1 and 5");
        housePoolDepositFeePercent = _new;
    }

    // Takes input of Fee Uint Number then divide by 100 as it's percentage, changes the Fee taken from bet for Treasury.
    function setBetFeePercent(uint256 _new) external onlyOwner {
        require(_new <= 5000000000000000000 && _new >= 100000000000000000, "bet fee percent must be between 0.1 and 5");
        betFeePercent = _new;
    }

    function setTreasuryWallet(address _new) external onlyTreasury {
        treasuryWallet = _new;
    }

    function refund() external nonReentrant {
        for (uint256 i = refundedUpTo; i <= betRequestSize; i++) {
            BetRequest memory _betRequest = betRequest[i];
            if (_betRequest.timestamp != 0 && block.timestamp >= _betRequest.timestamp + 15 minutes) {
                delete betRequest[i].timestamp;
                rewardPool[_betRequest.sender] += _betRequest.betAmount;
                refundedUpTo ++;
            }
        }
    }

    // Takes input of USDC amount, user places bet.
    function bet(uint256 _betAmount, uint256 _faceSide, address _referral) external nonReentrant {
        require(pauseBet == false, "pauseBet");
        require(_betAmount >= minBet, "minBet");
        require(_betAmount <= maxBetPercent * housePoolBalance.depositAmount / 1e18 / 100, "maxBet");
        require(_faceSide == 0 || _faceSide == 1, "Face side must be 0 or 1");

        address _sender = msg.sender;
        usdcToken.safeTransferFrom(_sender, address(this), _betAmount);

        uint256 requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        betRequestSize++;
        betRequest[betRequestSize].requestId = requestId;
        betRequest[betRequestSize].sender = _sender;
        betRequest[betRequestSize].predict = _faceSide;
        betRequest[betRequestSize].betAmount = _betAmount;
        betRequest[betRequestSize].timestamp = block.timestamp;
        betRequest[betRequestSize].referral = _referral;

        emit RequestedBet(requestId, _sender, _faceSide, _betAmount);
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        BetRequest memory _betRequest = betRequest[betRequestSize];
        require(msg.sender == vrfCoordinator, "Fulfillment only permitted by Coordinator");
        require(_betRequest.timestamp != 0, "timestamp should exist");
        uint256 sortedFace = randomWords[0] % 2;
        //0 is Head, 1 is Cross
        uint256 playerPredict = _betRequest.predict;
        address player = _betRequest.sender;
        uint256 playerBetAmount = _betRequest.betAmount;

        PlayRecord memory _record = PlayRecord({
        betAmount : playerBetAmount,
        headOrTail : playerPredict,
        resultHeadOrTail : sortedFace
        });
        playRecords[player].push(_record);

        bool userWon;
        if (sortedFace == 0 && playerPredict == 0) {
            // user bet and result is Head
            userWon = true;
        } else if (sortedFace == 1 && playerPredict == 1) {
            // user bet and result is Cross
            userWon = true;
        } else {
            // user lost
            userWon = false;
        }
        uint256 calculatedFee;
        address _referral = _betRequest.referral;
        if (_referral != address(0)) {
            uint256 _bettingRefPercent = bettingRefPercent;
            calculatedFee = playerBetAmount * (betFeePercent - _bettingRefPercent) / 1e18 / 100;
            uint256 referralReward = _bettingRefPercent * playerBetAmount / 1e18 / 100;
            rewardPool[_referral] += referralReward;
            betRefEarned[_referral] += referralReward;
        } else {
            calculatedFee = playerBetAmount * betFeePercent / 1e18 / 100;
        }
        treasuryPoolBalance.depositAmount += calculatedFee;
        calculatedFee = playerBetAmount * betFeePercent / 1e18 / 100;
        uint256 payoutAppliedAmount = (payout * playerBetAmount / 1e18) - playerBetAmount;
        if (userWon) {
            rewardPool[player] += payoutAppliedAmount + playerBetAmount;
            housePoolBalance.depositAmount -= payoutAppliedAmount + calculatedFee;
            for (uint256 i = 0; i < userHouseBalances.length; i++) {
                userHouseBalances[i].depositAmount -= (payoutAppliedAmount + calculatedFee) * userHouseBalances[i].userContributionPortion / 1e18;
            }
        } else {
            housePoolBalance.depositAmount += playerBetAmount - calculatedFee;
            for (uint256 i = 0; i < userHouseBalances.length; i++) {
                userHouseBalances[i].depositAmount += (playerBetAmount - calculatedFee) * userHouseBalances[i].userContributionPortion / 1e18;
            }
        }
        delete betRequest[betRequestSize].timestamp;

        myTotalWaged[player] += playerBetAmount;
        emit ReceivedBetResult(userWon, requestId, player, randomWords[0], sortedFace, playerPredict, playerBetAmount);
    }

    function z1_pauseBet() external onlyOwner {
        pauseBet = true;
    }

    function z2_unpauseBet() external onlyOwner {
        pauseBet = false;
    }

    function z3_pauseHouseDeposit() external onlyOwner {
        pauseHouseDeposit = true;
    }

    function z4_unpauseHouseDeposit() external onlyOwner {
        pauseHouseDeposit = false;
    }

    function z5_pauseHouseWithdraw() external onlyOwner {
        pauseHouseWithdraw = true;
    }

    function z6_unpauseHouseWithdraw() external onlyOwner {
        pauseHouseWithdraw = false;
    }

    function setBettingRefPercent(uint256 _new) external onlyOwner {
        require(_new <= 250000000000000000 && _new >= 1000000000000000, "betting referral percent must be between 0.001 and 0.25");
        bettingRefPercent = _new;
    }

    function setHouseDepositRefPercent(uint256 _new) external onlyOwner {
        require(_new <= 250000000000000000 && _new >= 1000000000000000, "house deposit referral percent must be between 0.001 and 0.25");
        houseDepositRefPercent = _new;
    }
	
    function setMinHouseDeposit(uint256 _new) external onlyOwner {
        require(_new >= 100000000000000000000, "minimum house deposit amount must be $100 or bigger");
        minHouseDeposit = _new;
    }
	
}