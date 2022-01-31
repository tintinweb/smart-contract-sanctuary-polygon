/**
 *Submitted for verification at polygonscan.com on 2021-12-23
*/

// Sources flattened with hardhat v2.7.0 https://hardhat.org

// File @chainlink/contracts/src/v0.7/vendor/[email protected]

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathChainlink {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// File @chainlink/contracts/src/v0.7/interfaces/[email protected]

pragma solidity ^0.7.0;

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

// File @chainlink/contracts/src/v0.7/[email protected]

pragma solidity ^0.7.0;

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

// File @chainlink/contracts/src/v0.7/[email protected]

pragma solidity ^0.7.0;

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
    using SafeMathChainlink for uint256;

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
        nonces[_keyHash] = nonces[_keyHash].add(1);
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

// File @openzeppelin/contracts/utils/[email protected]

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File @openzeppelin/contracts/access/[email protected]

pragma solidity >=0.6.0 <0.8.0;

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
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File @openzeppelin/contracts/math/[email protected]

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        require(b > 0, errorMessage);
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File @openzeppelin/contracts/token/ERC20/[email protected]

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// File @openzeppelin/contracts/token/ERC20/[email protected]

pragma solidity >=0.6.0 <0.8.0;

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
    using SafeMath for uint256;
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
        // solhint-disable-next-line max-line-length
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
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File @openzeppelin/contracts/utils/[email protected]

pragma solidity >=0.6.0 <0.8.0;

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

    constructor() internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

// File contracts/MetaDiceV1.sol

pragma solidity 0.7.6;
pragma abicoder v2;

// MetaDiceV1 is the provider of random number games at MetaDice.org: Coin Flip, Dice Roll, Roulette, Crash and Slots.
contract MetaDiceV1 is VRFConsumerBase, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Chainlink VRF related parameters
    address public constant LINK_TOKEN = 0xb0897686c545045aFc77CF20eC7A532E3120E0F1;
    address public constant VRF_COORDINATOR = 0x3d2341ADb2D31f1c5530cDC622016af293177AE0;
    bytes32 public constant keyHash = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da;
    uint256 public constant chainlinkFee = 0.0001 ether;

    // Modulo based games
    // Masks are checked against a bit mask, allowing betting on specific outcomes.
    // For example in a dice roll (modulo = 6),
    // 000001 mask means betting on 1. 000001 converted from binary to decimal becomes 1.
    // 101000 mask means betting on 4 and 6. 101000 converted from binary to decimal becomes 40.
    // The specific value is dictated by the fact that 256-bit intermediate
    // multiplication result allows implementing population count efficiently
    // for numbers that are up to 42 bits, and 40 is the highest multiple of eight below 42.
    uint256 constant MAX_MASK_MODULO = 40;

    // These are constants that make O(1) population count in placeBet possible.
    uint256 constant POPCNT_MULT = 0x0000000000002000000000100000000008000000000400000000020000000001;
    uint256 constant POPCNT_MASK = 0x0001041041041041041041041041041041041041041041041041041041041041;
    uint256 constant POPCNT_MODULO = 0x3F;

    // Crash values
    uint256 public constant MULTIPLIER_LIMIT = 2**64;

    // Slots values
    uint256[] private wheel1;
    uint256[] private wheel2;
    uint256[] private wheel3;

    uint256 private immutable wheelsLength;

    uint256 public immutable maxSlotsPayout;

    mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) public slotsPayouts; // Sorted by symbol id ascending

    // House edge fee applied to each bet.
    uint256 public houseEdgeBP = 100;

    // Minimum and maximum bet amounts.
    uint256 public minBetAmount = 0.5 ether;
    uint256 public maxBetAmount = 5000 ether;

    // Balance-to-maxProfit ratio. Used to dynamically adjusts maxProfit based on balance.
    uint256 public balanceMaxProfitRatio = 32;

    // Funds that are locked in potentially winning bets. Prevents contract from committing to new bets that it cannot pay out.
    uint256 public lockedInBets;

    // Possible bet status.
    enum Status {
        NONE,
        CREATED,
        REFUNDED,
        SETTLED
    }

    // Info of each bet.
    struct Bet {
        // Wager amount in wei.
        uint256 amount;
        // Modulo of a game.
        uint8 modulo;
        // Number of winning outcomes for when modulo < MAX_MASK_MODULO.
        // Used to compute winning payment (* modulo/rollUnder).
        uint8 rollUnder;
        // Bit mask representing the user bet.
        uint256 mask;
        // Block number of placeBet tx.
        uint256 placeBlockNumber;
        // Address of a gambler, used to pay out winning bets.
        address payable gambler;
        // Status of bet.
        Status status;
        // Outcome of bet.
        uint256 outcome;
        // Win amount.
        uint256 winAmount;
    }

    // All bets
    mapping(uint256 => Bet) public bets;
    uint256 public betsLength = 0;

    // Mapping requestId returned by Chainlink VRF to bet Id.
    mapping(bytes32 => uint256) public betMap;

    // Constructor. Using Chainlink VRFConsumerBase constructor.
    event SlotPayoutLog(uint256 symbol1, uint256 symbol2, uint256 symbol3, uint256 payout);

    constructor(
        uint256[] memory _wheel1,
        uint256[] memory _wheel2,
        uint256[] memory _wheel3,
        uint256[3][] memory _payoutLabels,
        uint256[] memory _payoutAmounts
    ) VRFConsumerBase(VRF_COORDINATOR, LINK_TOKEN) {
        require(wheel1.length == wheel2.length && wheel2.length == wheel3.length, "Wheels length mismatch");
        require(_payoutLabels.length > 0, "No payouts");
        require(_payoutLabels.length == _payoutAmounts.length, "Payouts length mismatch");

        wheel1 = _wheel1;
        wheel2 = _wheel2;
        wheel3 = _wheel3;

        wheelsLength = _wheel1.length;

        uint256 maxPayoutAmount = 0;
        for (uint256 i = 0; i < _payoutLabels.length; i++) {
            uint256[3] memory pl = _payoutLabels[i];
            require(pl[0] <= pl[1] && pl[1] <= pl[2], "Invalid payout labels order");

            slotsPayouts[pl[0]][pl[1]][pl[2]] = _payoutAmounts[i];
            if (_payoutAmounts[i] > maxPayoutAmount) {
                maxPayoutAmount = _payoutAmounts[i];
            }

            emit SlotPayoutLog(pl[0], pl[1], pl[2], _payoutAmounts[i]);
        }
        maxSlotsPayout = maxPayoutAmount;
    }

    // Receive payable function used to send funds to the contract.
    receive() external payable {}

    /**
     ** OWNER
     */

    // Modifier to ensure that there are no pending bets.
    modifier noPendingBets() {
        require(lockedInBets == 0, "There are pending bets");
        _;
    }

    // Set house edge.
    event SetHouseEdgeBPLog(uint256 basisPoints);

    function setHouseEdgeBP(uint256 _houseEdgeBP) external onlyOwner noPendingBets {
        require(_houseEdgeBP < 500, "Maximum 5%");

        houseEdgeBP = _houseEdgeBP;

        emit SetHouseEdgeBPLog(_houseEdgeBP);
    }

    // Set balance-to-maxProfit ratio.
    event SetBalanceMaxProfitRatioLog(uint256 ratio);

    function setBalanceMaxProfitRatio(uint256 _balanceMaxProfitRatio) external onlyOwner {
        require(_balanceMaxProfitRatio > 0, "Zero value");

        balanceMaxProfitRatio = _balanceMaxProfitRatio;

        emit SetBalanceMaxProfitRatioLog(_balanceMaxProfitRatio);
    }

    // Set minimum bet amount and maximum bet amount. minBetAmount should be large enough such that
    // its house edge fee can cover the Chainlink oracle fee. Additionally, setting them to zero
    // effectively disables betting.
    event SetBetAmountsLog(uint256 minAmount, uint256 maxAmount);

    function setBetAmounts(uint256 _minBetAmount, uint256 _maxBetAmount) external onlyOwner {
        require(_minBetAmount <= _maxBetAmount, "Invalid values");

        minBetAmount = _minBetAmount;
        maxBetAmount = _maxBetAmount;

        emit SetBetAmountsLog(_minBetAmount, _maxBetAmount);
    }

    // Owner can withdraw native funds not exceeding balance minus potential win amounts by open bets
    // and any non-native tokens sent to the contract.
    event WithdrawTokenLog(address tokenAddress, uint256 amount);

    function withdrawToken(address payable _tokenAddress, uint256 _amount) external onlyOwner {
        require(_amount > 0, "Nothing to withdraw");

        if (_tokenAddress == address(0)) {
            require(_amount <= balance() - lockedInBets, "Withdrawal exceeds limit");

            msg.sender.transfer(_amount);
        } else {
            uint256 tokenBalance = IERC20(_tokenAddress).balanceOf(address(this));
            require(_amount <= tokenBalance, "Not enough to withdraw");

            IERC20(_tokenAddress).safeTransfer(msg.sender, _amount);
        }

        emit WithdrawTokenLog(_tokenAddress, _amount);
    }

    /**
     ** HELPERS
     */

    // Returns game token balance.
    function balance() public view returns (uint256) {
        return address(this).balance;
    }

    // Returns maximum profit allowed per bet. Prevents contract from accepting any bets with potential profit exceeding maxProfit.
    function maxProfit() public view returns (uint256) {
        return balance() / balanceMaxProfitRatio;
    }

    // Returns the house edge fee for a given amount.
    function getHouseEdgeFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(houseEdgeBP) / 10000;
    }

    // Returns the possible win amount for a given bet.
    function getPossibleWinAmount(
        uint8 _modulo,
        uint256 _amount,
        uint256 _betMask,
        uint8 _rollUnder
    ) private view returns (uint256) {
        uint256 amountWithoutFee = _amount - getHouseEdgeFee(_amount);
        if (_modulo <= MAX_MASK_MODULO) {
            return amountWithoutFee.mul(_modulo) / _rollUnder;
        } else if (_modulo == 100) {
            return amountWithoutFee.mul(100) / _betMask;
        } else if (_modulo == 101) {
            return amountWithoutFee.mul(_betMask) / 100;
        } else if (_modulo == 102) {
            return amountWithoutFee.mul(maxSlotsPayout);
        } else {
            // Impossible to reach
            revert("Invalid modulo");
        }
    }

    // Get slots' wheels.
    function getWheels()
        external
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        uint256[] memory wheel1Info = new uint256[](wheelsLength);
        uint256[] memory wheel2Info = new uint256[](wheelsLength);
        uint256[] memory wheel3Info = new uint256[](wheelsLength);
        for (uint256 i = 0; i < wheelsLength; i++) {
            wheel1Info[i] = wheel1[i];
            wheel2Info[i] = wheel2[i];
            wheel3Info[i] = wheel3[i];
        }

        return (wheel1Info, wheel2Info, wheel3Info);
    }

    // Get more randomness from a number.
    function extraRandomness(uint256 _number) private pure returns (uint256) {
        return uint256(keccak256(abi.encode(_number)));
    }

    // Get slots' payout.
    function getSlotsPayout(
        uint256 _symbol1,
        uint256 _symbol2,
        uint256 _symbol3
    ) private view returns (uint256) {
        if (_symbol1 <= _symbol2) {
            if (_symbol2 <= _symbol3) {
                return slotsPayouts[_symbol1][_symbol2][_symbol3];
            } else {
                if (_symbol1 <= _symbol3) {
                    return slotsPayouts[_symbol1][_symbol3][_symbol2];
                } else {
                    return slotsPayouts[_symbol3][_symbol1][_symbol2];
                }
            }
        } else {
            if (_symbol2 <= _symbol3) {
                if (_symbol1 <= _symbol3) {
                    return slotsPayouts[_symbol2][_symbol1][_symbol3];
                } else {
                    return slotsPayouts[_symbol2][_symbol3][_symbol1];
                }
            } else {
                return slotsPayouts[_symbol3][_symbol2][_symbol1];
            }
        }
    }

    /**
     ** USERS
     */

    // Place bet
    event BetPlaced(
        uint256 indexed betId,
        address gambler,
        uint256 amount,
        uint8 modulo,
        uint8 rollUnder,
        uint256 mask
    );

    function placeBet(uint256 _betMask, uint8 _modulo) external payable nonReentrant {
        require(msg.sender == tx.origin, "Contracts are disallowed");

        require(LINK.balanceOf(address(this)) >= chainlinkFee, "Insufficient LINK token");
        require(_modulo > 1, "Invalid modulo");

        uint256 amount = msg.value;
        require(amount >= minBetAmount && amount <= maxBetAmount, "Bet amount not within range");

        uint8 rollUnder;
        if (_modulo <= MAX_MASK_MODULO) {
            // Modulo games (ex: 2 for coin flip, 6 for dice roll, 37 for roulette)
            // Specify the exact bet outcomes via bit mask. rollUnder is the number
            // of 1 bits in this mask (bit count). This magic looking formula is an
            // efficient way to compute bit count on EVM for numbers below 2**40.
            require(_betMask > 0 && _betMask < 2**_modulo - 1, "Mask not within range");

            rollUnder = uint8(((_betMask * POPCNT_MULT) & POPCNT_MASK) % POPCNT_MODULO);
        } else if (_modulo == 100) {
            // Custom percentage game
            // Specify the right edge of half-open interval out of 100 - [0,_betMask[.
            require(_betMask > 0 && _betMask < 100, "Mask larger than modulo");
        } else if (_modulo == 101) {
            // Crash
            require(_betMask > 100 && _betMask <= MULTIPLIER_LIMIT * 100, "Target not within range");
        } else if (_modulo == 102) {
            // Slots
            require(_betMask >= 1 && _betMask <= 7, "Mask not within range");
        } else {
            revert("Invalid modulo");
        }

        // Possible win amount.
        uint256 possibleWinAmount = getPossibleWinAmount(_modulo, amount, _betMask, rollUnder);

        // Enforce max profit limit.
        require(possibleWinAmount <= amount.add(maxProfit()), "maxProfit violation");

        // Check whether contract has enough funds to accept this bet and update the locked funds.
        uint256 newLockedInBets = lockedInBets.add(possibleWinAmount);
        require(newLockedInBets <= balance(), "Insufficient funds");

        lockedInBets = newLockedInBets;

        // Request random number from Chainlink VRF. Store requestId for validation checks later.
        bytes32 requestId = requestRandomness(keyHash, chainlinkFee);

        // Store bet in all bets.
        uint256 betId = betsLength;
        bets[betId] = Bet({
            amount: amount,
            modulo: _modulo,
            rollUnder: rollUnder,
            mask: _betMask,
            placeBlockNumber: block.number,
            gambler: msg.sender,
            status: Status.CREATED,
            outcome: 0,
            winAmount: 0
        });

        betsLength = betsLength + 1;

        // Map requestId to bet ID.
        betMap[requestId] = betId;

        // Record bet in event logs.
        emit BetPlaced(betId, msg.sender, amount, _modulo, rollUnder, _betMask);
    }

    // Callback function called by Chainlink VRF coordinator.
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        settleBet(requestId, randomness);
    }

    // Settle bet. Function can only be called by fulfillRandomness function, which in turn can only be called by Chainlink VRF.
    event BetSettled(uint256 indexed betId, uint256 outcome, uint256 winAmount);

    function settleBet(bytes32 _requestId, uint256 _randomNumber) private nonReentrant {
        uint256 betId = betMap[_requestId];
        Bet storage bet = bets[betId];

        // Validation checks.
        require(bet.status == Status.CREATED, "Bet is already settled");

        // Fetch bet parameters into local variables (to save gas).
        uint8 modulo = bet.modulo;
        uint256 amount = bet.amount;
        uint256 mask = bet.mask;

        uint256 possibleWinAmount = getPossibleWinAmount(modulo, amount, mask, bet.rollUnder);

        uint256 outcome;
        uint256 winAmount = 0;
        if (modulo <= MAX_MASK_MODULO) {
            // Do a roll by taking a modulo of random number.
            outcome = _randomNumber % modulo;

            // Determine the winAmount by checking the outcome against a bit mask.
            if ((2**outcome) & mask != 0) {
                winAmount = possibleWinAmount;
            }
        } else if (modulo == 100) {
            // Do a roll by taking a modulo of random number.
            outcome = _randomNumber % 100;

            // Determine the winAmount by checking inclusion into half-open interval.
            if (outcome < mask) {
                winAmount = possibleWinAmount;
            }
        } else if (modulo == 101) {
            // Choose the crash multiplier (scaled by 100)
            outcome = (MULTIPLIER_LIMIT * 100) / (MULTIPLIER_LIMIT - (_randomNumber % MULTIPLIER_LIMIT));

            // Determine the winAmount.
            if (mask <= outcome) {
                winAmount = possibleWinAmount;
            }
        } else if (modulo == 102) {
            // Generate a random position for each wheel
            uint256 result1 = _randomNumber % wheelsLength;

            _randomNumber = extraRandomness(_randomNumber);
            uint256 result2 = _randomNumber % wheelsLength;

            _randomNumber = extraRandomness(_randomNumber);
            uint256 result3 = _randomNumber % wheelsLength;

            outcome = (result3 << 16) | (result2 << 8) | (result1 << 0);

            // Determine the winAmount.
            uint256 totalPayout = 0;
            uint256 winningBets = 0;
            for (uint256 i = 0; i < 3; i++) {
                if ((2**i) & mask != 0) {
                    totalPayout =
                        totalPayout +
                        getSlotsPayout(
                            wheel1[(result1 + i) % wheelsLength],
                            wheel2[(result2 + i) % wheelsLength],
                            wheel3[(result3 + i) % wheelsLength]
                        );
                    winningBets = winningBets + 1;
                }
            }

            if (winningBets > 0) {
                winAmount = (amount - getHouseEdgeFee(amount)).mul(totalPayout) / winningBets;
            }
        } else {
            // Impossible to reach
            revert("Invalid modulo");
        }

        // Unlock possibleWinAmount from lockedInBets, regardless of the outcome.
        lockedInBets = lockedInBets - possibleWinAmount;

        // Update bet records
        bet.status = Status.SETTLED;
        bet.winAmount = winAmount;
        bet.outcome = outcome;

        // Send prize to winner and update house profit.
        if (winAmount > 0) {
            bet.gambler.transfer(winAmount);
        }

        // Record bet settlement in event log.
        emit BetSettled(betId, outcome, winAmount);
    }

    // Return the bet in the very unlikely scenario it was not settled by Chainlink VRF.
    // In case you find yourself in a situation like this, just contact Casino support.
    // However, nothing prevents you from calling this method yourself.
    event BetRefunded(uint256 indexed betId);

    function refundBet(uint256 _betId) external nonReentrant {
        Bet storage bet = bets[_betId];

        // Validation checks
        require(bet.status == Status.CREATED, "Bet is already settled");
        require(block.number > bet.placeBlockNumber + 21600, "Wait at least 6 hours");

        uint256 amount = bet.amount;

        // Unlock possibleWinAmount from lockedInBets, regardless of the outcome.
        uint256 possibleWinAmount = getPossibleWinAmount(bet.modulo, amount, bet.mask, bet.rollUnder);
        lockedInBets = lockedInBets - possibleWinAmount;

        // Update bet records
        bet.status = Status.REFUNDED;

        // Send the refund.
        bet.gambler.transfer(amount);

        // Record refund in event logs
        emit BetRefunded(_betId);
    }
}