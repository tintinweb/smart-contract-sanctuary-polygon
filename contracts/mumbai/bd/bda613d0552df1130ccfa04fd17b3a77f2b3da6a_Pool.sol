/**
 *Submitted for verification at polygonscan.com on 2022-04-16
*/

// File: contracts/deps/interfaces/IERC20.sol

pragma solidity ^0.8.0;

// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

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



// File: contracts/deps/interfaces/IERC165.sol

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

// File: contracts/deps/interfaces/IERC721.sol



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
    
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
    
    /**
     * @dev Returns the token collection name.
     */
     function name() external view returns (string memory);

     /**
      * @dev Returns the token collection symbol.
      */
     function symbol() external view returns (string memory);
 
     /**
      * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
      */
     function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: contracts/deps/Context.sol

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

// File: contracts/deps/Ownable.sol


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


// File: contracts/deps/interfaces/IERC721Receiver.sol

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


// File: contracts/deps/interfaces/LinkTokenInterface.sol

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
// File: contracts/deps/VRFRequestIDBase.sol


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
// File: contracts/deps/VRFConsumerBase.sol




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
// File: contracts/Pool.sol

pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT






contract Pool is Ownable, IERC721Receiver, VRFConsumerBase {
  // struct to store a stake's token, owner, and earning values
  struct Stake {
    uint16 tokenId;
    uint80 value;
    address owner;
    address token;
  }
  // VRF Logic
  struct forVRF {
      uint256 tokenId;
      address token;
      bool unstake;
  }
  mapping(bytes32 => forVRF) pending;
  // Events
  event TokenStaked(address owner, uint256 tokenId, uint256 value);
  event BabyClaimed(uint256 tokenId, uint256 earned, bool unstaked);
  event MutantClaimed(uint256 tokenId, uint256 earned, bool unstaked);
  // VRF (current: mainnet)
  bytes32 public immutable keyHash = 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4;
  uint256 public immutable fee = 0.0001 ether;
  
  // The NFT contracts 
  IERC721 babiesContract;
  IERC721 mutantsContract;
  // reference to the $FROST contract for minting $FROST earnings
  IERC20 frost;

  mapping(address => uint16[]) _babiesOfOwner;
  mapping(address => uint16[]) _mutantsOfOwner;

  // maps tokenId to stake
  mapping(address => mapping(uint256 => Stake)) public pool;   
  // amount of $FROST due for each Mutant staked
  uint256 public frostPerMutant; 


  // Babies earn fixed frost each day
  uint256 public frostRate;
  // Babies can be stolen by mutants when they're unstaked
  uint256 public chanceOfStealingNFT;
  // Mutants also have a chance to steal claimed tokens from staked babies
  uint256 public chanceOfStealingClaimed;
  // Mutants can die when unstaked
  uint256 public chanceOfDying;

  address public constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;


  // there will only ever be 50M $FROST earned through staking
  uint256 public constant MAXIMUM_GLOBAL_FROST = 50_000_000 ether;
  // amount of $FROST earned so far
  uint256 public totalFrostEarned;
  // number of Babies staked in the Pool
  uint256 public totalBabiesStaked;
  // number of Mutants staked in the Pool
  uint256 public totalMutantsStaked;
  // the last time $Frost was claimed
  uint256 public lastClaimTimestamp;


  // init
  constructor(address _babies, address _mutants, address _frost, uint256 _frostRate, uint256 _chanceOfStealingNFT, uint256 _chanceOfStealingClaimed, uint256 _chanceOfDying)  VRFConsumerBase(0x8C7382F9D8f56b33781fE506E897a4F1e2d17255, 0x326C977E6efc84E512bB9C30f76E30c160eD06FB) { 
    babiesContract = IERC721(_babies);
    mutantsContract = IERC721(_mutants);
    frost = IERC20(_frost);
    frostRate = _frostRate * 1 ether;
    chanceOfStealingNFT = _chanceOfStealingNFT;
    chanceOfStealingClaimed = _chanceOfStealingClaimed;
    chanceOfDying = _chanceOfDying;
  }
  /** READ ONLY */
  function babiesOfOwner(address account) external view returns(uint16[] memory) {
    return _babiesOfOwner[account];
  }

  function mutantsOfOwner(address account) external view returns(uint16[] memory) {
    return _mutantsOfOwner[account];
  }


  function claimableFrostForBabies(uint16[] calldata tokenIds) external view returns(uint256 claimable) {
    for (uint i = 0; i < tokenIds.length; i++) {
      require(babiesContract.ownerOf(tokenIds[i]) == address(this), "Token not staked");
      Stake memory stake = pool[address(babiesContract)][tokenIds[i]];
      claimable += figureOutOwedForBabies(stake);
    }
  }
  function claimableFrostForMutants(uint16[] calldata tokenIds) external view returns(uint256 claimable) {
    for (uint i = 0; i < tokenIds.length; i++) {
      require(mutantsContract.ownerOf(tokenIds[i]) == address(this), "Token not staked");
      Stake memory stake = pool[address(mutantsContract)][tokenIds[i]];
      claimable += figureOutOwedForMutants(stake);
    }
  }

  /** STAKING */

  /**
   * adds Babies and or mutants to the Pool, the logic is the exact same
   * @param account the address of the staker
   * @param tokenIds the IDs of the Babies and Mutants to stake
   */
  function addBabiesToPool(address account, uint16[] calldata tokenIds) external {
    require(account == _msgSender(), "DONT GIVE YOUR TOKENS AWAY");
    for (uint i = 0; i < tokenIds.length; i++) {
        require(babiesContract.ownerOf(tokenIds[i]) == _msgSender(), "AINT YO TOKEN");
        babiesContract.transferFrom(_msgSender(), address(this), tokenIds[i]);
        _babiesOfOwner[msg.sender].push(tokenIds[i]);
        pool[address(babiesContract)][tokenIds[i]] = Stake({
          owner: account,
          tokenId: uint16(tokenIds[i]),
          value: uint80(block.timestamp),
          token: address(babiesContract)
        });
        totalBabiesStaked += 1;
    }
  }
  function addMutantsToPool(address account, uint16[] calldata tokenIds) external {
    require(account == _msgSender(), "DONT GIVE YOUR TOKENS AWAY");
    frost.transferFrom(msg.sender, address(this), (100 * tokenIds.length) * 1 ether);

    for (uint i = 0; i < tokenIds.length; i++) {
        require(mutantsContract.ownerOf(tokenIds[i]) == _msgSender(), "AINT YO TOKEN");
        mutantsContract.transferFrom(_msgSender(), address(this), tokenIds[i]);
        _mutantsOfOwner[msg.sender].push(tokenIds[i]);
        pool[address(mutantsContract)][tokenIds[i]] = Stake({
          owner: account,
          tokenId: uint16(tokenIds[i]),
          value: uint80(frostPerMutant),
          token: address(mutantsContract)
        });
        totalMutantsStaked += 1;
    }
  }

  /** CLAIMING / UNSTAKING */


  /**
   * realize $FROST earnings and optionally unstake tokens from the Pool
   * @param tokenIds the IDs of the tokens to claim earnings from
   * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
   */
  function claimBabiesFromPool(uint16[] calldata tokenIds, bool unstake) external _updateEarnings {
    
    for (uint i = 0; i < tokenIds.length; i++) {
        _claimBabyFromPool(tokenIds[i], unstake);
      if(unstake) {
        uint len = _babiesOfOwner[msg.sender].length;
        uint pos;
        for(uint x; x < len; x++) {
          if(_babiesOfOwner[msg.sender][x] == tokenIds[i]) {
            pos = x;
            break;
          }
          else {continue;}
        }
        _babiesOfOwner[msg.sender][pos] = _babiesOfOwner[msg.sender][len - 1];
        _babiesOfOwner[msg.sender].pop();
      }
    }
  }
    function claimMutantsFromPool(uint16[] calldata tokenIds, bool unstake) external _updateEarnings {
    
    for (uint i = 0; i < tokenIds.length; i++) {
        _claimMutantFromPool(tokenIds[i], unstake);
      if(unstake) {
        uint len = _mutantsOfOwner[msg.sender].length;
        uint pos;
        for(uint x; x < len; x++) {
          if(_mutantsOfOwner[msg.sender][x] == tokenIds[i]) {
            pos = x;
            break;
          }
          else {continue;}
        }
        _mutantsOfOwner[msg.sender][pos] = _mutantsOfOwner[msg.sender][len - 1];
        _mutantsOfOwner[msg.sender].pop();
      }
    }  
  }


  function figureOutOwedForBabies(Stake memory stake) internal view returns(uint256 owed) {
    // NOTE : totalFrostEarned will be bigger than max global frost eventually, but transfers account for this. 
    if (totalFrostEarned < MAXIMUM_GLOBAL_FROST) {
      owed = (block.timestamp - stake.value) * frostRate / 1 days;
    } else if (stake.value > lastClaimTimestamp) {
      owed = 0; // Rewards distribution has already ended
    } else {
      owed = (lastClaimTimestamp - stake.value) * frostRate / 1 days; // stop earning additional $Frost if it's all been earned
    }
  }

  function figureOutOwedForMutants(Stake memory stake) internal view returns(uint256 owed) {
    owed = frostPerMutant - stake.value; // Calculate portion of tokens based
  }


  function _claimBabyFromPool(uint256 tokenId, bool unstake) internal {
    Stake memory stake = pool[address(babiesContract)][tokenId];
    require(babiesContract.ownerOf(tokenId) == address(this), "AINT A PART OF THE POOL");
    require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
    rollTheDice(tokenId, address(babiesContract), unstake);
  }

  function _claimMutantFromPool(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
    Stake memory stake = pool[address(mutantsContract)][tokenId];
    require(mutantsContract.ownerOf(tokenId) == address(this), "AINT A PART OF THE POOL");
    require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
    owed = figureOutOwedForMutants(stake);
    if (unstake) {
      rollTheDice(tokenId, address(mutantsContract), unstake);
    } else {
      pool[address(mutantsContract)][tokenId] = Stake({
        owner: stake.owner,
        tokenId: uint16(tokenId),
        value: uint80(frostPerMutant),
        token: address(mutantsContract)
      }); // reset stake
    }
    safeTransferFrost(stake.owner, owed);
    emit MutantClaimed(tokenId, owed, unstake);
  }

  function rollTheDice(uint tokenId, address nftContract, bool unstake) internal {
        bytes32 requestId = requestRandomness(keyHash, fee);
        pending[requestId] = forVRF(tokenId, nftContract, unstake);
    }
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
    address nftContract = pending[requestId].token;
    uint256 tokenId = pending[requestId].tokenId;
    bool unstake = pending[requestId].unstake;
    uint256 randomValue = randomness; 
    if (nftContract == address(babiesContract)) {
      realizeBaby(tokenId, unstake, randomValue);    
    }
    else {
      realizeMutant(tokenId, randomValue);
    }
  }

  function realizeBaby(uint256 tokenId, bool unstake, uint256 randomValue) internal {
    Stake memory stake = pool[address(babiesContract)][tokenId];
    uint256 owed;
    if (totalFrostEarned < MAXIMUM_GLOBAL_FROST) {
      owed = (block.timestamp - stake.value) * frostRate / 1 days;
    } else if (stake.value > lastClaimTimestamp) {
      owed = 0; // Rewards distribution has already ended
    } else {
      owed = (lastClaimTimestamp - stake.value) * frostRate / 1 days; // stop earning additional $Frost if it's all been earned
    }
    bool isStakeStolen = (randomValue % 100) < chanceOfStealingClaimed;
    uint256 newRandom = uint256(keccak256(abi.encodePacked(randomValue)));
    
    bool isTokenStolen = ((newRandom % 100) < chanceOfStealingNFT) && unstake;
    if(isStakeStolen) {
      // Distributes earnings to all the mutants
      frostPerMutant += owed / totalMutantsStaked;
    }
    else if(isTokenStolen) {
      address newOwner = randomMutantOwner(uint256(keccak256(abi.encodePacked(newRandom))));
      if (newOwner == address(0)) {
        newOwner = stake.owner;
      }
      safeTransferFrost(stake.owner, owed);
      babiesContract.safeTransferFrom(address(this), newOwner, tokenId);
    }
    else {
      safeTransferFrost(stake.owner, owed);
      if(unstake) {
        babiesContract.safeTransferFrom(address(this), stake.owner, tokenId);
      }
      else {
        pool[address(babiesContract)][tokenId] = Stake({
          owner: stake.owner,
          tokenId: uint16(tokenId),
          value: uint80(block.timestamp),
          token: address(babiesContract)
      }); // reset stake
      }
    }
    if(unstake) {
      delete pool[address(babiesContract)][tokenId];
      totalBabiesStaked--;
    }
  }
  
  function realizeMutant(uint256 tokenId,uint256 randomValue) internal {
    Stake memory stake = pool[address(mutantsContract)][tokenId];
    bool isDead = (randomValue % 100) < chanceOfDying;
    if(!isDead) {
      mutantsContract.safeTransferFrom(address(this), pool[address(mutantsContract)][tokenId].owner, tokenId);
    }
    else {
      mutantsContract.safeTransferFrom(address(this), DEAD_ADDRESS, tokenId);
    }
    delete pool[address(mutantsContract)][tokenId];
    totalMutantsStaked--; 
  }



  /** ACCOUNTING */

  /** 
   * add $FROST to claimable pot for the Pool
   * @param amount $FROST to add to the pot
   */

  /**
   * tracks $FROST earnings to ensure it stops once 50  million is eclipsed
   */
  modifier _updateEarnings() {
    if (totalFrostEarned < MAXIMUM_GLOBAL_FROST) {
      totalFrostEarned += 
        (block.timestamp - lastClaimTimestamp)
        * totalBabiesStaked
        * frostRate / 1 days; 
      lastClaimTimestamp = block.timestamp;
    }
    _;
  }


  /** ADMIN */
// The lazy way lol
function updateGameVars(uint256 _frostRate, uint256 _chanceOfStealingNFT, uint256 _chanceOfStealingClaimed, uint256 _chanceOfDying) external onlyOwner() {
  frostRate = _frostRate;
  chanceOfStealingNFT = _chanceOfStealingNFT;
  chanceOfStealingClaimed = _chanceOfStealingClaimed;
  chanceOfDying = _chanceOfDying;
}


  /** UTILS*/
  function safeTransferFrost(address to, uint256 amount) internal {
    if (amount > frost.balanceOf(address(this))) {
      amount = frost.balanceOf(address(this));
    }
    frost.transfer(to, amount);
  }

  /**
   * chooses a random Mutant when a newly minted token is stolen
   * @param seed a random value to choose a Mutant from
   * @return the owner of the randomly selected Mutant
   */
  function randomMutantOwner(uint256 seed) private view returns (address) {
    if (totalMutantsStaked == 0) return address(0x0);
    uint256 bucket = (seed & 0xFFFFFFFF) % totalMutantsStaked; // choose a value from 0 to total Mutant staked
    seed >>= 32;
    if (bucket < totalMutantsStaked)
      return pool[address(mutantsContract)][seed % totalMutantsStaked].owner;
    return address(0x0);
  }
  function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
      require(from == address(0x0), "Cannot send tokens to Pool directly");
      return IERC721Receiver.onERC721Received.selector;
    }

}