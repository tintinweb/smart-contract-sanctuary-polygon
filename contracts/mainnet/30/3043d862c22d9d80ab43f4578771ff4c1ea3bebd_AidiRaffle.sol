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

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

pragma solidity ^0.8.4;

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

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

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

/**
 * @title AidiWithdrawable
 * @dev Supports being able to get tokens or ETH out of a contract with ease
 */
contract AidiWithdrawable is Ownable {
  using SafeERC20 for IERC20;

  function withdrawTokens(address _tokenAddress, uint256 _amount) external onlyOwner {
    IERC20 _token = IERC20(_tokenAddress);
    _amount = _amount > 0 ? _amount : _token.balanceOf(address(this));
    require(_amount > 0, "Nothing to withdraw");
    _token.safeTransfer(owner(), _amount);
  }

  function withdrawETH() external onlyOwner {
    (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Failed to send Ether");
  }
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IAccessControl {
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

abstract contract AccessControl is Context, IAccessControl, ERC165{
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function hasRole(bytes32 role, address account)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _roles[role].members[account];
    }

    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    function getRoleAdmin(bytes32 role)
        public
        view
        virtual
        override
        returns (bytes32)
    {
        return _roles[role].adminRole;
    }

    function grantRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        _revokeRole(role, account);
    }

    function renounceRole(bytes32 role, address account)
        public
        virtual
        override
    {
        require(
            account == _msgSender(),
            "AccessControl: can only renounce roles for self"
        );

        _revokeRole(role, account);
    }

    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

/**
 * @title AidiRaffle
 * @dev This is the main contract that supports lotteries and raffles.
 */
contract AidiRaffle is AidiWithdrawable, AccessControl, VRFConsumerBaseV2 {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

  struct Raffle {
    address owner;
    address entryToken; // Raffle entry ERC20 token
    uint256 entryFee; // Raffle entry fees amount for one entry, 0 if there is no entry fee
    uint256 minEntriesForDraw; // Minimum number of entries required to conduct the raffle draw (0 means no minimum)
    uint256 maxEntriesForRaffle; // 0 means unlimited entries
    uint256 maxEntriesPerAddress; // 0 means unlimited entries
    address[] entries;
    uint256 entryFeesCollected; // Total collected entry fees
    uint8 totalRewardPercentage;// Percentage of collected entry fees that is split among winners
    uint256 start; // timestamp (uint256) of start time (0 if start when raffle is created)
    uint256 end; // timestamp (uint256) of end time (0 if can be entered until owner draws)
    uint256 numberOfwinners;
    address[] winners;
    bool isComplete;
    bool isClosed;
    bool isDeleted;
    string ipfsdetails;
  }

  uint8 public aidiUtilityFee = 2;
  uint256 public raffleCreateFee = 100 ether; //100 MATIC

  mapping(bytes32 => Raffle) public raffles;
  bytes32[] public raffleIds;
  bytes32[] public activeRaffleIds;
  mapping(bytes32 => mapping(address => uint256)) public entriesIndexed;
  mapping(bytes32 => address[]) private uniqueAddressEntries;
  mapping(bytes32 => mapping(address => bool)) public isUniqueAddressAdded;  
  mapping(uint256 => bytes32) public requestIDRaffleIdMap;
  mapping(address => uint256) public tokenTransferFees;
  mapping(uint256 => mapping(uint256 => bool)) private randomIndexArrayDupChecker;

  struct RequestStatus {
    bool fulfilled; 
    bool exists;
    uint256 randomResult;
  }
  mapping(uint256 => RequestStatus) public s_requests;
  VRFCoordinatorV2Interface COORDINATOR;
  uint256[] public requestIds;
  uint256 public lastRequestId;
  uint32 public numWords = 1;
  bytes32 public keyHash = 0xd729dc84e21ae57ffb6be0053bf2b0668aa2aaf300a2a7b2ddf7dc0bb6e875a8;
  uint64 public s_subscriptionId = 463;
  uint32 public callbackGasLimit = 2500000;
  uint16 public requestConfirmations = 3;

  event CreateRaffle(address indexed creator, bytes32 id);
  event EnterRaffle(
    bytes32 indexed id,
    address raffler,
    uint256 numberOfEntries
  );
  event DrawWinnersCalc(bytes32 indexed id, uint256 totalCollected, uint256 aidiFee, uint256 raffleOwnerFee, uint256 prizePerWinner);
  event DrawWinners(bytes32 indexed id, address[] winners, uint256 amount);
  event PayWinnersCalc(bytes32 indexed id, uint256 totalCollected, uint256 aidiFee, uint256 raffleOwnerFee, uint256 prizePerWinner);
  event PayWinners(bytes32 indexed id, address[] winners, uint256 amount);
  event CloseRaffle(bytes32 indexed id);
  event DeleteRaffle(bytes32 indexed id);
  event TokenAddress(address indexed tokenaddress);
  event TokenAmount( uint256 amount);

  constructor()VRFConsumerBaseV2(0xAE975071Be8F8eE67addBC1A82488F1C24858067)
  {
    COORDINATOR = VRFCoordinatorV2Interface(
        0xAE975071Be8F8eE67addBC1A82488F1C24858067
    );
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    addAdminAddress(msg.sender);
    tokenTransferFees[address(0xBeFc2781C187376ac54248b84e8E8F7DE87f6679)] = 2; //AIDI
    tokenTransferFees[address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174)] = 0; //USDC
    tokenTransferFees[address(0xc2132D05D31c914a87C6611C10748AEb04B58e8F)] = 0; //USDT
    tokenTransferFees[address(0x48C97cf0A3837106Cb58009D308DF4DfAbe441C7)] = 0; //VERSE
    tokenTransferFees[address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270)] = 0; //WMATIC
  }

  function setKeyHash(bytes32 _keyHash) public onlyOwner {
    keyHash = _keyHash;
  }

  function setSubscriptionId(uint64 _subscriptionId) public onlyOwner {
    s_subscriptionId = _subscriptionId;
  }

  function setCallbackGasLimit(uint32 _callbackGasLimit) public onlyOwner {
    require(_callbackGasLimit <= 2500000, "More than Max Gas Limit!");
    callbackGasLimit = _callbackGasLimit;
  }

  function setRequestConfirmations(uint16 _requestConfirmations) public onlyOwner {
    requestConfirmations = _requestConfirmations;
  }
  
  function isAdmin(address addy) internal view returns (bool) {
    if (hasRole(ADMIN_ROLE, addy) || addy == owner()) {
        return true;
    } else {
        return false;
    }
  }

  function getAllRaffles() external view returns (bytes32[] memory) {
    return raffleIds;
  }

  function getAllActiveRaffles() external view returns (bytes32[] memory) {
    return activeRaffleIds;
  }

  function setRaffeCreateFee(uint256 _newpublicprice) public onlyOwner {
      raffleCreateFee = _newpublicprice;
  }

  function getRaffleEntries(bytes32 _id)
    external
    view
    returns (address[] memory)
  {
    return raffles[_id].entries;
  }

  function getTotalNumOfRaffles()
    external
    view
    returns (uint256)
  {
    return raffleIds.length;
  }

  function getRaffleAtIndex(uint256 _index)
    external
    view
    returns (bytes32)
  {
    return raffleIds[_index];
  }

  function getTotalEntryFeesCollected(bytes32 _id)
    external
    view
    returns (uint256)
  {
    return raffles[_id].entryFeesCollected;
  }

  function getTotalPrizeForRaffle(bytes32 _id)
    external
    view
    returns (uint256)
  {
    uint256 _totalPrizeToSendWinners =  (raffles[_id].entryFeesCollected * raffles[_id].totalRewardPercentage) / 100;
    return _totalPrizeToSendWinners ;
  }

  function getPrizeForSingleWinnerInRaffle(bytes32 _id)
    external
    view
    returns (uint256)
  {
    uint256 _totalPrizeToSendWinners =  (raffles[_id].entryFeesCollected * raffles[_id].totalRewardPercentage) / 100;
    if(raffles[_id].numberOfwinners>0)
    {
        return (_totalPrizeToSendWinners/ raffles[_id].numberOfwinners);
    }
    return 0;
  }

  function isUserOwnerOrPartcipating(bytes32 _id, address userAddress)
    external
    view
    returns (uint256)
  {
    uint256 returnVal = 0; //not participating returns 0
    
    if(userAddress == raffles[_id].owner) //If Creator returns 2
    {
     returnVal = 2;
    }
    address[] memory addresses = uniqueAddressEntries[_id];
    for(uint256 i = 0; i < addresses.length; i++) {
      if(userAddress == addresses[i]) //If Participant and owner returns 3. If only participating, returns 1
      {
        returnVal +=1;
        break;
      }
    }
   
    return returnVal; 
  }

  function isRaffleDrawn(bytes32 _id)
    external
    view
    returns (bool)
  {
    return raffles[_id].isComplete;
  }

  function isRaffleClosed(bytes32 _id)
    external
    view
    returns (bool)
  {
    return raffles[_id].isClosed;
  }

  function isRaffleDeleted(bytes32 _id)
    external
    view
    returns (bool)
  {
    return raffles[_id].isDeleted;
  }

  function getNumberOfWinnersForRaffle(bytes32 _id)
    external
    view
    returns (uint256)
  {
    return raffles[_id].numberOfwinners;
  }

  function getRaffleWinners(bytes32 _id)
    external
    view
    returns (address[] memory)
  {
    return raffles[_id].winners;
  }

  function getNameOfEntryTokenForRaffle(bytes32 _id)
    external
    view
    returns (string memory)
  {
      IERC20Metadata _entryToken = IERC20Metadata(raffles[_id].entryToken);
      return _entryToken.name();
  }

  function getEntryTokenForRaffle(bytes32 _id)
    external
    view
    returns (address)
  {
      return raffles[_id].entryToken;
  }

  function getMinEntriesForDraw(bytes32 _id)
    external
    view
    returns (uint256)
  {
    return raffles[_id].minEntriesForDraw;
  }

  function getMaxEntriesForRaffle(bytes32 _id)
    external
    view
    returns (uint256)
  {
    return raffles[_id].maxEntriesForRaffle;
  }

  function getMaxEntriesPerAddressForRaffle(bytes32 _id)
    external
    view
    returns (uint256)
  {
    return raffles[_id].maxEntriesPerAddress;
  }

  function getEntryPriceForRaffle(bytes32 _id)
    external
    view
    returns (uint256)
  {
    return raffles[_id].entryFee;
  }

  function getUniqueAddressesLengthInRaffle(bytes32 _id)
    external
    view
    returns (uint256)
  {
    return uniqueAddressEntries[_id].length;
  }

  function getUniqueAddressesInRaffle(bytes32 _id)
    external
    view
    returns (address[] memory)
  {
    return uniqueAddressEntries[_id];
  }

  function getEntriesForAddressInRaffle(bytes32 _id, address addy)
    external
    view
    returns (uint256)
  {
    return entriesIndexed[_id][addy];
  }

  function addAdminAddress(address admin) public virtual onlyOwner {
    grantRole(ADMIN_ROLE, admin);
  }

  function removeAdminAddress(address admin) public virtual onlyOwner {
    revokeRole(ADMIN_ROLE, admin);
  }

  function getTokenTransferFees(address token) internal view returns (uint256 fees)
  {
    fees = tokenTransferFees[token];
    if(fees > 0)
    {
      return fees;
    }
    return 0;
  }

  function setTokenTransferFees(address token, uint256 fees) external onlyOwner
  {
    require(fees >= 0, "Fees should be greater than or equal to 0");
    tokenTransferFees[token] = fees;
  }

  function setDeleted(bytes32 _id) external onlyOwner 
  {
    Raffle storage _raffle = raffles[_id];
    require(!_raffle.isDeleted, "Raffle already deleted.");
    _raffle.isDeleted = true;
    _raffle.isComplete = true;
    _raffle.isClosed = true;
    removeActiveRaffleID(_id);
    emit DeleteRaffle(_id);
  }

// Creating Rafflee 
  function createRaffle(
    address _entryToken,
    uint256 _entryFee,
    uint256 _minEntriesForDraw,
    uint256 _maxEntriesForRaffle,
    uint256 _maxEntriesPerAddress,
    uint8 _totalRewardPercentage,
    uint256 _start,
    uint256 _end,
    uint256 _numberOfwinners,
    string memory ipfsdetails
  ) external payable 
  {
    require(isAdmin(msg.sender), "Not an admin, please contact AidiVerse team!");
    _validateDates(_start, _end);
    require(_numberOfwinners > 0, "There should be at least one winner!");
    require(_numberOfwinners <= _maxEntriesForRaffle, "Number of winners should be lesser than or equal to max entries per raffle!");
    require(_numberOfwinners >= _minEntriesForDraw, "Number of winners should be greater than or equal to min entries per raffle!");
    require(_totalRewardPercentage >= 0 && _totalRewardPercentage <= (100 - aidiUtilityFee), "Reward percentage should be between 0 and (100 - aidiUtilityFee).");
    require(_maxEntriesPerAddress <= _maxEntriesForRaffle, "Max entries per address should be lesser than or equal to max entries per raffle!");
    require(_minEntriesForDraw <= _maxEntriesForRaffle, "Min entries for draw should be lesser than or equal to max entries per raffle!");
    require(msg.value >= raffleCreateFee, "Raflle creation fee is low.");

    bytes32 _id = sha256(abi.encodePacked(msg.sender, block.number));
    address[] memory _entries;
    address[] memory _winners;

    raffles[_id] = Raffle({
    owner: msg.sender,
    entryToken: _entryToken,
    entryFee: _entryFee,
    minEntriesForDraw: _minEntriesForDraw,
    maxEntriesForRaffle: _maxEntriesForRaffle,
    maxEntriesPerAddress: _maxEntriesPerAddress,
    entries: _entries,
    entryFeesCollected: 0,
    totalRewardPercentage: _totalRewardPercentage,
    start: _start,
    end: _end,
    numberOfwinners: _numberOfwinners,
    winners: _winners,
    isComplete: false,
    isClosed: false,
    isDeleted: false,
    ipfsdetails: ipfsdetails
    });
    raffleIds.push(_id);
    addActiveRaffleID(_id);
    sendETHToOwner();
    emit CreateRaffle(msg.sender, _id);
  }

  function sendETHToOwner() internal {
    (bool success, ) = payable(owner()).call{value: address(this).balance}("");
    require(success, "Failed to send Ether");
  }

  function closeRaffleAndRefund(bytes32 _id) external {
    require(isAdmin(msg.sender), "Not an admin, please contact AidiVerse team!");
    Raffle storage _raffle = raffles[_id];
    require(address(_raffle.owner) == msg.sender || msg.sender == address(owner()), "Caller must be the raffle owner to close the raffle.");
    require(!_raffle.isComplete, "Raffle cannot be closed if it is completed already.");

    address[] memory _entries = _raffle.entries;
    IERC20 _entryToken = IERC20(address(_raffle.entryToken));
    uint256 _entryFees = _raffle.entryFee;
    uint256 erc20balance = _entryToken.balanceOf(address(this));
    uint256 _entryFeesCollected = _raffle.entryFeesCollected;
    require(erc20balance > 0, "Balance is low");

    if(_entryFeesCollected > erc20balance)
    {
      _entryFeesCollected = erc20balance;
    }

    if(_entries.length > 0 && _entryFeesCollected < (_entryFees.mul(_entries.length)))
    {
      _entryFees = _entryFeesCollected.div(_entries.length);
    }

    for (uint256 _i = 0; _i < _entries.length; _i++) {
      address _user = address(_entries[_i]);
      _entryToken.safeTransfer(_user, _entryFees);
    }
    _raffle.isComplete = true;
    _raffle.isClosed = true;
    emit CloseRaffle(_id);
  }

  function deleteRaffleAndRefund(bytes32 _id) external {
    require(isAdmin(msg.sender), "Not an admin, please contact AidiVerse team!");
    Raffle storage _raffle = raffles[_id];
    require(address(_raffle.owner) == msg.sender || msg.sender == address(owner()), "Caller must be the raffle owner to close the raffle.");
    require(!_raffle.isDeleted, "Raffle already deleted.");

    address[] memory _entries = _raffle.entries;
    IERC20 _entryToken = IERC20(address(_raffle.entryToken));
    uint256 _entryFees = _raffle.entryFee;
    uint256 erc20balance = _entryToken.balanceOf(address(this));
    uint256 _entryFeesCollected = _raffle.entryFeesCollected;
    require(_entryFeesCollected <= erc20balance, "Balance is low");

    if(_entries.length > 0 && _entryFeesCollected < (_entryFees.mul(_entries.length)))
    {
      _entryFees = _entryFeesCollected.div(_entries.length);
    }

    for (uint256 _i = 0; _i < _entries.length; _i++) {
      address _user = address(_entries[_i]);
      _entryToken.safeTransfer(_user, _entryFees);
    }
    _raffle.isDeleted = true;
    _raffle.isComplete = true;
    _raffle.isClosed = true;
    removeActiveRaffleID(_id);
    emit DeleteRaffle(_id);
  }

  function enterRaffle(bytes32 _id, uint256 _numEntries) external {
    Raffle storage _raffle = raffles[_id];
    require(address(_raffle.owner) != address(0), "We do not recognize this raffle.");
    require(_raffle.start <= block.timestamp, "Raffle is not started yet!");
    require(_raffle.end == 0 || _raffle.end >= block.timestamp, "Sorry, this raffle has ended.");
    require(_numEntries > 0 &&(_raffle.maxEntriesPerAddress == 0 || entriesIndexed[_id][msg.sender] + _numEntries <= _raffle.maxEntriesPerAddress),
    "You have purchased maximum entries.");
    require(!_raffle.isComplete && !_raffle.isClosed, "Sorry, this raffle has closed entries.");
    require((_raffle.entries.length + _numEntries) <= _raffle.maxEntriesForRaffle, "Sorry, the max entries for this raffle has reached.");
    
    if (_raffle.entryFee > 0) {

      IERC20 _entryToken = IERC20(address(_raffle.entryToken));
      uint256 approvedValue = _entryToken.allowance(msg.sender, address(this));
      uint256 transferAdjustedEntryFee = _raffle.entryFee.mul(100).div(100 - getTokenTransferFees(address(_raffle.entryToken)));
      require( approvedValue >= transferAdjustedEntryFee * _numEntries, "Not approved!");
      _entryToken.safeTransferFrom(
        msg.sender,
        address(this),
        transferAdjustedEntryFee.mul(_numEntries)
      );
      _raffle.entryFeesCollected += _raffle.entryFee.mul(_numEntries);
    }

    for (uint256 _i = 0; _i < _numEntries; _i++) {
      _raffle.entries.push(msg.sender);
    }
    entriesIndexed[_id][msg.sender] += _numEntries;
    addUniqueAddressInRaffle( _id, msg.sender);
    emit EnterRaffle(_id, msg.sender, _numEntries);
  }

  function drawWinners(bytes32 _id) external {
    Raffle storage _raffle = raffles[_id];
    require(!_raffle.isComplete && !_raffle.isClosed, "Raffle has already been drawn and completed.");
    require((_raffle.end > 0 && _raffle.entries.length >= _raffle.minEntriesForDraw) || (_raffle.end == 0 && _raffle.owner == msg.sender) || (_raffle.end > 0 && block.timestamp > _raffle.end), "Raffle's minimum entry requirement for drawing not met or the raffle entry period is not over yet.");
    uint256 reqID = callVRFAndDrawRaffle();
    requestIDRaffleIdMap[reqID] = _id;
  }

  function callVRFAndDrawRaffle() internal returns (uint256 requestId)
  {
    requestId = COORDINATOR.requestRandomWords(
        keyHash,
        s_subscriptionId,
        requestConfirmations,
        callbackGasLimit,
        numWords
    );
    s_requests[requestId] = RequestStatus({
        randomResult: 0,
        exists: true,
        fulfilled: false
    });
    requestIds.push(requestId);
    lastRequestId = requestId;
    return requestId;
  }

  function fulfillRandomWords( uint256 _requestId, uint256[] memory _randomWords) internal override 
  {
    require(s_requests[_requestId].exists, "request not found");
    bytes32 _id = requestIDRaffleIdMap[_requestId];
    Raffle storage _raffle = raffles[_id];
    require(address(_raffle.owner) != address(0), "We do not recognize this raffle.");
    require(!_raffle.isComplete, "Raffle has already been drawn and completed.");
    s_requests[_requestId].fulfilled = true;
    s_requests[_requestId].randomResult = _randomWords[0];
    address[] memory _entries = _raffle.entries;
    
    if (_raffle.entryFeesCollected > 0) {
        IERC20 _entryToken = IERC20(address(_raffle.entryToken));
        uint256 _entryFeesCollected = _raffle.entryFeesCollected;
        uint8 _totalRewardPercentage = _raffle.totalRewardPercentage;
        uint256 _numberOfwinners = _raffle.numberOfwinners;

        uint256 _feeAidi = _entryFeesCollected.mul(aidiUtilityFee).div(100);
        uint256 _totalPrizeToSendWinners =  _entryFeesCollected.mul( _totalRewardPercentage).div(100);
        uint256 _feesToSendRaffleOwner = _entryFeesCollected - _totalPrizeToSendWinners - _feeAidi;
        uint256 _prizePerEachWinner = _totalPrizeToSendWinners.div(_numberOfwinners);

        emit DrawWinnersCalc(_id, _entryFeesCollected, _feeAidi, _feesToSendRaffleOwner, _prizePerEachWinner);
        uint256 erc20balance = _entryToken.balanceOf(address(this));
        require(_entryFeesCollected <= erc20balance, "Balance is low");

        if (_feeAidi > 0) {
            _entryToken.safeTransfer(address(owner()), _feeAidi);
        }
        if (_feesToSendRaffleOwner > 0) {
            _entryToken.safeTransfer(address(_raffle.owner), _feesToSendRaffleOwner);
        }

        if (_prizePerEachWinner > 0) {
            uint256 randomValue = uint256(s_requests[_requestId].randomResult);
            uint256[] memory randomArray = randomIndexArray(_requestId, randomValue, _numberOfwinners, _entries.length);
            for(uint256 i = 0; i < _numberOfwinners; i++) {
                uint256 _winnerIdx = randomArray[i];
                address _winner = address(_entries[_winnerIdx]);
                _raffle.winners.push(_winner);
            }
        }
        emit DrawWinners(_id, _raffle.winners, _prizePerEachWinner);
    }else{
        emit DrawWinners(_id, _raffle.winners, 0);
    }
    _raffle.isClosed = true;
  }

  function getRequestStatus(uint256 _requestId) external view onlyOwner returns (bool fulfilled, uint256 randomResult) 
  {
    require(s_requests[_requestId].exists, "request not found");
    RequestStatus memory request = s_requests[_requestId];
    return (request.fulfilled, request.randomResult);
  }

  function randomIndexArray(uint256 _requestId, uint256 randomValue, uint256 length, uint256 range) internal returns (uint256[] memory randomArray) {
    randomArray = new uint256[](length);
    for (uint256 i = 0; i < length; i++) {
      uint256 ran = getRandomNumberFromSeed(randomValue, i, range);
      uint256 j = 1;
      while(randomIndexArrayDupChecker[_requestId][ran])
      {
        ran = getRandomNumberFromSeed(randomValue + j, i, range);
        j = j+i+1;
      }
      randomIndexArrayDupChecker[_requestId][ran] = true;
      randomArray[i] = ran;
    }
    return randomArray;
  }

  function getRandomNumberFromSeed(uint256 randomValue, uint256 index, uint256 range) internal pure returns (uint256)
  {
    return uint256((uint256(keccak256(abi.encode(randomValue, index))) % range));
  }

  function payWinners(bytes32 _id) external {
    require(isAdmin(msg.sender), "Not an admin, please contact AidiVerse team!");
    Raffle storage _raffle = raffles[_id];
    require(address(_raffle.owner) != address(0), "We do not recognize this raffle.");
    require(address(_raffle.owner) == msg.sender || msg.sender == address(owner()), "Caller must be the raffle owner!");
    require(!_raffle.isDeleted, "This raffle is deleted!");
    require(!_raffle.isComplete, "This raffle is completed!");
    require(_raffle.isClosed, "Raffle not drawn!");
    require(_raffle.winners.length > 0, "Zero Raffle winners!");
    address[] memory winners = _raffle.winners;

    if (_raffle.entryFeesCollected > 0) {
        IERC20 _entryToken = IERC20(address(_raffle.entryToken));
        uint256 _entryFeesCollected = _raffle.entryFeesCollected;
        uint8 _totalRewardPercentage = _raffle.totalRewardPercentage;
        uint256 _numberOfwinners = winners.length;

        uint256 _feeAidi = _entryFeesCollected.mul(aidiUtilityFee).div(100);
        uint256 _totalPrizeToSendWinners =  _entryFeesCollected.mul( _totalRewardPercentage).div(100);
        uint256 _feesToSendRaffleOwner = _entryFeesCollected - _totalPrizeToSendWinners - _feeAidi;
        uint256 _prizePerEachWinner = _totalPrizeToSendWinners.div(_numberOfwinners);

        emit PayWinnersCalc(_id, _entryFeesCollected, _feeAidi, _feesToSendRaffleOwner, _prizePerEachWinner);
        uint256 erc20balance = _entryToken.balanceOf(address(this));
        require(_totalPrizeToSendWinners <= erc20balance, "Balance is low");

        if (_prizePerEachWinner > 0) {
           for(uint256 i = 0; i < _numberOfwinners; i++) {
                _entryToken.safeTransfer(winners[i], _prizePerEachWinner);
            }
        }
        emit PayWinners(_id, _raffle.winners, _prizePerEachWinner);
    }
    _raffle.isComplete = true;
  }

  function addUniqueAddressInRaffle(bytes32 _id, address account) private {
    if (!isUniqueAddressAdded[_id][account])
    {
        isUniqueAddressAdded[_id][account] = true;
        uniqueAddressEntries[_id].push(account);
    }
  }

  function changeRaffleOwner(bytes32 _id, address _newOwner) external {
    require(isAdmin(msg.sender), "Not an admin, please contact AidiVerse team!");
    require(isAdmin(_newOwner), "New owner is not an admin, please contact AidiVerse team!");
    Raffle storage _raffle = raffles[_id];
    require(address(_raffle.owner) == msg.sender || msg.sender == address(owner()), "Caller must be the raffle owner to change the raffle ownership.");
    require(!_raffle.isComplete, "Raffle has already been drawn and completed.");

    _raffle.owner = _newOwner;
  }

  function changeStartDate(bytes32 _id, uint256 _newStart) external {
    require(isAdmin(msg.sender), "Not an admin, please contact AidiVerse team!");
    Raffle storage _raffle = raffles[_id];
    require(address(_raffle.owner) == msg.sender || msg.sender == address(owner()), "Caller must be the raffle owner to change the dates.");
    require(_raffle.start > block.timestamp +30, "Raffle already started");
    require(_newStart == 0 || (_newStart >= block.timestamp && _raffle.end > _newStart), "Start time should be 0 or after the current time");
    require(!_raffle.isComplete, "Raffle has already been drawn and completed.");
    _raffle.start = _newStart;
  }

  function changeEndDate(bytes32 _id, uint256 _newEnd) external {
    require(isAdmin(msg.sender), "Not an admin, please contact AidiVerse team!");
    Raffle storage _raffle = raffles[_id];
    require(address(_raffle.owner) == msg.sender || msg.sender == address(owner()), "Caller must be the raffle owner to change the dates.");
    require(_newEnd == 0 || (_newEnd > block.timestamp && _raffle.start < _newEnd), "End time should be 0 or after the current time");
    require(!_raffle.isComplete, "Raffle has already been drawn and completed.");
    _raffle.end = _newEnd;
  }

  function changeAidiUtilityFee(uint8 _newPercentage) external onlyOwner {
    require(_newPercentage >= 0 && _newPercentage < 100, "Should be between 0 and 100.");
    aidiUtilityFee = _newPercentage;
  }

  function _validateDates(uint256 _start, uint256 _end) private view {
    require(_start == 0 || _start >= block.timestamp, "Start time should be 0 or after the current time");
    require(_end == 0 || _end > block.timestamp, "End time should be 0 or after the current time");
    if (_start > 0) {
      if (_end > 0) {
        require(_start < _end, "Start time must be before the end time");
      }
    }
  }

  function addActiveRaffleID(bytes32 _id) internal {
        activeRaffleIds.push(_id);
  }

  function removeActiveRaffleID(bytes32 _id) internal {
    for (uint256 i = 0; i < activeRaffleIds.length; i++) {
        if (activeRaffleIds[i] == _id) {
            activeRaffleIds[i] = activeRaffleIds[activeRaffleIds.length - 1];
            activeRaffleIds.pop();
            break;
        }
    }
  }
}