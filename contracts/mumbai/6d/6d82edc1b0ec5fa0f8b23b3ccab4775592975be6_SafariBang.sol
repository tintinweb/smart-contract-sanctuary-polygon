/**
 *Submitted for verification at polygonscan.com on 2022-09-10
*/

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

// File: contracts/MultiOwnable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity 0.8.16;


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
abstract contract MultiOwnable is Context {
  address public superOwner;
  address private _owner;

  event SuperOwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    _transferSuperOwnership(_msgSender());
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlySubOwner() {
    _checkOwner();
    _;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlySuperOwner() {
    _checkSuperOwner();
    _;
  }

  modifier onlyOneOfTheOwners() {
    require(
      superOwner == _msgSender() || _owner == _msgSender(),
      "MultiOwnable: caller must be either owner or superOwner."
    );
    _;
  }

  /**
   * @dev Returns the addresses of the current owners.
   */
  function owners() public view virtual returns (address[2] memory) {
    return [superOwner, _owner];
  }

  /**
   * @dev Throws if the sender is not a super owner.
   */
  function _checkSuperOwner() internal view virtual {
    require(
      superOwner == _msgSender(),
      "MultiOwnable: caller is not a super owner"
    );
  }

  /**
   * @dev Throws if the sender is not an owner.
   */
  function _checkOwner() internal view virtual {
    require(_owner == _msgSender(), "MultiOwnable: caller is not an owner");
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public virtual onlySubOwner {
    _transferOwnership(address(0));
  }

  function transferSuperOwnership(address newOwner)
    public
    virtual
    onlySuperOwner
  {
    require(
      newOwner != address(0),
      "MultiOwnable: new owner is the zero address"
    );
    _transferSuperOwnership(newOwner);
  }

  function _transferSuperOwnership(address newOwner) internal virtual {
    address oldOwner = superOwner;
    superOwner = newOwner;
    emit SuperOwnershipTransferred(oldOwner, newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlySubOwner {
    require(
      newOwner != address(0),
      "MultieOwnable: new owner is the zero address"
    );
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

// File: contracts/VRFConsumerV2.sol


// An example of a consumer contract that relies on a subscription for funding.
pragma solidity 0.8.16;




/**
 * @title The VRFConsumerV2 contract
 * @notice A contract that gets random values from Chainlink VRF V2
 */
contract VRFConsumerV2 is VRFConsumerBaseV2 {
  VRFCoordinatorV2Interface immutable COORDINATOR;
  LinkTokenInterface immutable LINKTOKEN;

  // Your subscription ID.
  uint64 public s_subscriptionId;

  // The gas lane to use, which specifies the maximum gas price to bump to.
  // For a list of available gas lanes on each network,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  bytes32 immutable s_keyHash;

  // Depends on the number of requested values that you want sent to the
  // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
  // so 100,000 is a safe default for this example contract. Test and adjust
  // this limit based on the network that you select, the size of the request,
  // and the processing of the callback request in the fulfillRandomWords()
  // function.
  uint32 immutable s_callbackGasLimit = 2_500_000;

  // The default is 3, but you can set this higher.
  uint16 immutable s_requestConfirmations = 3;

  // For this example, retrieve 2 random values in one request.
  // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
  uint32 public immutable s_numWords = 5;

  uint256[] public s_randomWords;
  uint256 public s_requestId;
  address public s_owner;

  event ReturnedRandomness(uint256[] randomWords);
  event Constructed(address owner, uint64 subscriptionId);

  /**
   * @notice Constructor inherits VRFConsumerBaseV2
   *
   * @param subscriptionId - the subscription ID that this contract uses for funding requests
   * @param vrfCoordinator - coordinator, check https://docs.chain.link/docs/vrf-contracts/#configurations
   * @param keyHash - the gas lane to use, which specifies the maximum gas price to bump to
   */
  constructor(
    uint64 subscriptionId,
    address vrfCoordinator,
    address link,
    bytes32 keyHash
  ) VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    LINKTOKEN = LinkTokenInterface(link);
    s_keyHash = keyHash;
    s_owner = msg.sender;
    s_subscriptionId = subscriptionId;

    emit Constructed(s_owner, s_subscriptionId);
  }

  /**
   * @notice Requests randomness
   * Assumes the subscription is funded sufficiently; "Words" refers to unit of data in Computer Science
   */
  function requestRandomWords() external onlyOwner {
    // Will revert if subscription is not set and funded.
    s_requestId = COORDINATOR.requestRandomWords(
      s_keyHash,
      s_subscriptionId,
      s_requestConfirmations,
      s_callbackGasLimit,
      s_numWords
    );
  }

  /**
   * @notice Callback function used by VRF Coordinator
   *
   * @param requestId - id of the request
   * @param randomWords - array of random results from VRF Coordinator
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
    internal
    override
  {
    s_randomWords = randomWords;
    emit ReturnedRandomness(randomWords);
  }

  modifier onlyOwner() {
    require(msg.sender == s_owner);
    _;
  }

  function setSubscriptionId(uint64 subId) public onlyOwner {
    s_subscriptionId = subId;
  }

  function setOwner(address owner) public onlyOwner {
    s_owner = owner;
  }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// File: contracts/Storage.sol


pragma solidity 0.8.16;




contract SafariBangStorage {
  using Strings for uint256;

  error MintingPeriodOver();
  error MintPriceNotPaid();
  error MaxSupply();
  error NonExistentTokenUri();
  error WithdrawTransfer();

  event MoveToEmptySquare(address whoMoved, uint8 newRow, uint8 newCol);
  event FightAttempt(address fighter, address fightee);
  event FuckAttempt(address fucker, address fuckee);
  event FuckSuccess(address fucker, uint256 newlyMinted);
  event ChallengerWonFight(
    address victor,
    address loser,
    uint8 newChallengerRow,
    uint8 newChallengerCol
  );
  event ChallengerLostFight(
    address victor,
    address loser,
    uint8 newChallengerRow,
    uint8 newChallengerCol
  );
  event AnimalReplacedFromQuiver(
    uint256 indexed id,
    address indexed owner,
    uint8 row,
    uint8 col
  );
  event AnimalBurnedAndRemovedFromCell(
    uint256 indexed id,
    address indexed owner,
    uint8 row,
    uint8 col
  );
  event AsteroidDeathCount(
    uint256 indexed survivors,
    uint256 indexed dead,
    uint256 indexed timestamp
  );
  event Rebirth(uint256 newMintingPeriodStartTime);
  event PlayerAdded(address who, uint256 totalPlayersCount);
  event PlayerRemoved(address who, uint256 totalPlayersCount);

  modifier onlyCurrentPlayer() {
    require(
      msg.sender == whosTurnNext || whosTurnNext == address(0),
      "Only current player can call this, unless the next player has not been decided yet."
    );
    _;
  }

  string public baseURI;
  uint256 public currentTokenId = 0;
  uint256 public TOTAL_SUPPLY = 3000; // map is 64 * 64 = 4096 so leave ~25% of map empty but each time asteroid happens this goes down by number of animals that were on the map.
  uint256 public constant MINT_PRICE = 0.08 ether; // TODO: is this even necessary?

  uint8 public constant NUM_ROWS = 64;
  uint8 public constant NUM_COLS = 64;

  uint32 public roundCounter; // keep track of how many rounds of asteroid destruction

  // _superOwner will always be the contract address, in order to clear state with asteroid later.
  enum AnimalType {
    DOMESTICATED_ANIMAL, // _owner is some Eth address
    WILD_ANIMAL // _owner is SafariBang contract address
  }

  enum Specie {
    ZEBRAT, // Zebra with a bratty attitude
    LIONNESSY, // Lionness thinks she's a princess
    DOGGIE, // self explanatory canine slut
    PUSSYCAT, // self explanatory slut but feline
    THICCAPOTAMUS, // fat chick
    GAZELLA, // jumpy anxious female character
    MOUSEY, // Spouse material
    WOLVERINERASS, // wolf her in her ass i dunno man
    ELEPHAT, // phat ass
    RHINOCERHOE, // always horny
    CHEETHA, // this cat ain't loyal
    BUFFALO, // hench stud
    MONKGOOSE, // zero libido just meditates
    WARTHOG, // genital warts
    BABOOB, // double D cup baboon
    WILDEBEEST, // the other stud
    IMPALA, // the inuendos just write themselves at this point
    COCKODILE, // i may need professional help
    HORNBILL, // who names these animals
    OXPECKER // this bird is hung like an ox
  }

  enum Direction {
    Up,
    Down,
    Left,
    Right
  }

  struct Position {
    uint256 animalId;
    uint8 row;
    uint8 col;
  }

  // probably put this offchain?
  struct Animal {
    AnimalType animalType;
    Specie species; // this determines the image
    uint256 id;
    uint256 size;
    uint256 strength; // P(successfully "fight")
    uint256 speed; // P(successfully "flee")
    uint256 fertility; // P(successfully "fuck" and conceive)
    uint256 anxiety; // P(choose "flee" | isWildAnimal())
    uint256 aggression; // P(choose "fight" | isWildAnimal())
    uint256 libido; // P(choose "fuck" | isWildAnimal())
    bool gender; // animals are male or female
    address owner;
  }

  /**
        The Map
     */
  mapping(uint256 => mapping(uint256 => uint256)) public safariMap; // safariMap[row][col] => animalId
  mapping(uint256 => Position) public idToPosition;
  mapping(address => Position) public playerToPosition;
  mapping(uint256 => Animal) public idToAnimal;
  mapping(address => Animal[]) public quiver;

  /**
        Gameplay
    */
  mapping(address => uint8) public movesRemaining; // Maybe you can get powerups for more moves or something.
  mapping(address => bool) public isPendingAction; // who still can move this turn?
  address[] public allPlayers;
  address public whosTurnNext;
  bool public isGameInPlay = false;

  uint256 public mintingPeriod = 5 minutes; // change to hours for Mainnet
  uint256 public mintingPeriodStartTime;

  Specie[20] public species = [
    Specie.ZEBRAT, // Zebra with a bratty attitude
    Specie.LIONNESSY, // Lionness thinks she's a princess
    Specie.DOGGIE, // self explanatory canine slut
    Specie.PUSSYCAT, // self explanatory slut but feline
    Specie.THICCAPOTAMUS, // fat chick
    Specie.GAZELLA, // jumpy anxious female character
    Specie.MOUSEY, // Spouse material
    Specie.WOLVERINERASS, // wolf her in her ass i dunno man
    Specie.ELEPHAT, // phat ass
    Specie.RHINOCERHOE, // always horny
    Specie.CHEETHA, // this cat ain't loyal
    Specie.BUFFALO, // hench stud
    Specie.MONKGOOSE, // zero libido just meditates
    Specie.WARTHOG, // genital warts
    Specie.BABOOB, // double D cup baboon
    Specie.WILDEBEEST, // the other stud
    Specie.IMPALA, // the inuendos just write themselves at this point
    Specie.COCKODILE, // i may need professional help
    Specie.HORNBILL, // who names these animals
    Specie.OXPECKER // this bird is hung like an ox]
  ];
}

// File: https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol


pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// File: contracts/SafariBang.sol


pragma solidity 0.8.16;










contract SafariBang is
  ERC721,
  MultiOwnable,
  IERC721Receiver,
  SafariBangStorage,
  VRFConsumerV2
{
  using Strings for uint256;

  event MapGenesis();
  event VRFGetWordsSuccess();
  event CreateAnimal(uint256 id);
  event Log(string message);

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _baseURI,
    address _vrfCoordinator,
    address _linkToken,
    uint64 _subId,
    bytes32 _keyHash
  )
    ERC721(_name, _symbol)
    VRFConsumerV2(_subId, _vrfCoordinator, _linkToken, _keyHash)
  {
    baseURI = _baseURI;

    _transferSuperOwnership(msg.sender);
  }

  /**
        Set the new Minting phase
        Once the minting phase is past, mintTo closes and the isGameInPlay should be true;
     */
  function rebirth() external onlySuperOwner {
    mintingPeriodStartTime = block.timestamp;
    isGameInPlay = false;
    emit Rebirth(mintingPeriodStartTime);
  }

  /**
        "And on the 69th day, he said, let there be a bunch of horny angry animals" - God, probably
        @dev On each destruction of the game map, this genesis function is called by the contract super owner to randomly assign new animals across the map.
     */
  function mapGenesis(uint256 howMany) external onlySuperOwner {
    require(s_randomWords.length > 0, "Randomness should be fulfilled first.");
    emit MapGenesis();

    for (uint256 i = 0; i < howMany; i++) {
      createAnimal(address(this));
    }
  }

  function createAnimal(address to) internal returns (uint256 newGuyId) {
    uint256 currId = ++currentTokenId;

    emit CreateAnimal(currId);

    // if you mint multiple you get more turns
    // safari gets as many moves as there are animals
    if (movesRemaining[to] > 0) {
      movesRemaining[to] += 1;
    } else {
      movesRemaining[to] = 1;
    }

    if (currId > TOTAL_SUPPLY) {
      revert MaxSupply();
    }

    _safeMint(to, currId);

    // if something already there, try permutation of word until out of permutations or find empty square.

    bool isEmptySquare = false;
    uint256 speciesIndex;
    uint8 row;
    uint8 col;
    uint8 modulo = NUM_ROWS;

    require(s_randomWords.length > 0, "Randomness should have been fulfilled.");

    while (!isEmptySquare) {
      speciesIndex =
        s_randomWords[currId % s_randomWords.length] %
        species.length;
      row = uint8(s_randomWords[currId % s_randomWords.length] % modulo);
      col = uint8(s_randomWords[(currId + 1) % s_randomWords.length] % modulo);

      if (safariMap[row][col] == 0) {
        isEmptySquare = true;
      } else {
        modulo -= 1;
      }
    }

    Position memory position = Position({
      animalId: currId,
      row: row,
      col: col
    });

    Animal memory wipAnimal = Animal({
      animalType: to == address(this)
        ? AnimalType.WILD_ANIMAL
        : AnimalType.DOMESTICATED_ANIMAL,
      species: species[speciesIndex],
      id: currId,
      size: s_randomWords[0] % 50,
      strength: s_randomWords[0] % 49,
      speed: s_randomWords[0] % 48,
      fertility: s_randomWords[0] % 47,
      anxiety: s_randomWords[0] % 46,
      aggression: s_randomWords[0] % 45,
      libido: s_randomWords[0] % 44,
      gender: s_randomWords[0] % 2 == 0 ? true : false,
      owner: to
    });

    // only Animals have quiver, WILD_ANIMALS do not belong in a quiver
    if (wipAnimal.owner != address(this)) {
      quiver[to].push(wipAnimal);
    }

    idToAnimal[currId] = wipAnimal;

    if (quiver[to].length <= 1) {
      safariMap[row][col] = currId;
      idToPosition[currId] = position;
      playerToPosition[to] = position;
    }

    isPendingAction[wipAnimal.owner] = true;

    return wipAnimal.id;
  }

  /**
        After each turn, you roll an X sided die
        The corresponding animalId's owner gets to move next, if they exist and havne't gone yet.
     */
  function randPickNextPlayer() external onlyCurrentPlayer {
    require(allPlayers.length >= 2, "Needs to be at least 2 players to play.");
    address nextPlayer;

    uint256 i = 0;

    while (nextPlayer == address(0)) {
      require(
        s_randomWords.length > 0 && s_randomWords[i] != 0,
        "Randomness must be fulfilled"
      );
      uint256 numerator = sqrt(s_randomWords[i]);

      uint8 nextIndex = uint8(numerator % allPlayers.length);
      address potentialNextGuy = allPlayers[nextIndex];

      if (potentialNextGuy != address(0) && isPendingAction[potentialNextGuy]) {
        nextPlayer = potentialNextGuy;
      } else {
        i = (i + 1) % s_randomWords.length;
      }
    }

    whosTurnNext = nextPlayer;
    isPendingAction[msg.sender] = false;
  }

  function getAllPlayers() external returns (address[] memory) {
    return allPlayers;
  }

  /** 
    @dev A animal can move to an empty square, but it's a pussy move. You can only move one square at a time. This is only for moving to empty squares. Otherwise must fight,  or fuck
    @param direction up, down, left, or right.
    @param howManySquares usually 1, only flee() will set it to 3
    */
  function move(Direction direction, uint8 howManySquares)
    internal
    onlyCurrentPlayer
    returns (Position memory newPosition)
  {
    require(
      isPendingAction[msg.sender] == true,
      "This player has no moves left"
    );
    require(whosTurnNext == msg.sender, "It is not your turn!");

    Position memory currentPosition = playerToPosition[msg.sender];

    require(
      ownerOf(currentPosition.animalId) == msg.sender,
      "Only owner can move piece"
    );
    require(movesRemaining[msg.sender] > 0, "You are out of moves");

    movesRemaining[msg.sender] -= 1;
    isPendingAction[msg.sender] = false;

    if (direction == Direction.Up) {
      require(
        safariMap[currentPosition.row - howManySquares][currentPosition.col] ==
          0,
        "can only use move on empty square"
      );

      uint8 newRow = currentPosition.row - howManySquares >= 0
        ? currentPosition.row - howManySquares
        : NUM_ROWS;

      Position memory newPosition = Position({
        animalId: currentPosition.animalId,
        row: newRow,
        col: currentPosition.col
      });

      idToPosition[currentPosition.animalId] = newPosition;
      playerToPosition[msg.sender] = newPosition;
      safariMap[currentPosition.row][currentPosition.col] = 0;
      safariMap[newRow][currentPosition.col] = currentPosition.animalId;

      return newPosition;
    } else if (direction == Direction.Down) {
      require(
        safariMap[currentPosition.row + 1][currentPosition.col] == 0,
        "can only use move on empty square"
      );

      uint8 newRow = currentPosition.row + howManySquares <= NUM_ROWS
        ? currentPosition.row + howManySquares
        : 0;

      Position memory newPosition = Position({
        animalId: currentPosition.animalId,
        row: newRow,
        col: currentPosition.col
      });

      idToPosition[currentPosition.animalId] = newPosition;
      playerToPosition[msg.sender] = newPosition;
      safariMap[currentPosition.row][currentPosition.col] = 0;
      safariMap[newRow][currentPosition.col] = currentPosition.animalId;

      return newPosition;
    } else if (direction == Direction.Left) {
      require(
        safariMap[currentPosition.row][currentPosition.col - howManySquares] ==
          0,
        "can only use move on empty square"
      );

      uint8 newCol = currentPosition.col - howManySquares >= 0
        ? currentPosition.col - howManySquares
        : NUM_COLS;

      Position memory newPosition = currentPosition;
      newPosition.col = newCol;

      idToPosition[currentPosition.animalId] = newPosition;
      playerToPosition[msg.sender] = newPosition;
      safariMap[currentPosition.row][currentPosition.col] = 0;
      safariMap[currentPosition.row][newCol] = currentPosition.animalId;

      return newPosition;
    } else if (direction == Direction.Right) {
      require(
        safariMap[currentPosition.row][currentPosition.col + howManySquares] ==
          0,
        "can only use move on empty square"
      );
      uint8 newCol = currentPosition.col + howManySquares <= NUM_COLS
        ? currentPosition.col + howManySquares
        : 0;

      Position memory newPosition = currentPosition;
      newPosition.col = newCol;

      idToPosition[currentPosition.animalId] = newPosition;
      playerToPosition[msg.sender] = newPosition;
      safariMap[currentPosition.row][currentPosition.col] = 0;
      safariMap[currentPosition.row][newCol] = currentPosition.animalId;

      return newPosition;
    }
  }

  /**
        @dev Dev only! place animal anywhere
     */
  // function godModePlacement(address who, uint id, uint8 row, uint8 col) public {
  //     Position memory newPosition = Position({
  //         animalId: id,
  //         row: row,
  //         col: col
  //     });

  //     idToPosition[id] = newPosition;
  //     playerToPosition[who] = newPosition;
  //     safariMap[row][col] = id;
  // }

  // function godModeAttributes(
  //         uint id,
  //         uint256 fertility,
  //         uint256 libido,
  //         bool gender) public {

  //     Animal memory animal = idToAnimal[id];
  //     Animal memory newAnimal = Animal({
  //         animalType: animal.animalType,
  //         species: animal.species,
  //         id: animal.id,
  //         size: animal.size,
  //         strength: animal.strength,
  //         speed: animal.speed,
  //         fertility: fertility,
  //         anxiety: animal.anxiety,
  //         aggression: animal.aggression,
  //         libido: libido,
  //         gender: gender,
  //         owner: animal.owner
  //     });

  //     idToAnimal[id] = newAnimal;
  // }

  /**
        @dev Fight the animal on the same square as you're trying to move to.
        
        If succeed, take the square and the animal goes into your quiver. 
        If fail, you lose the animal and you're forced to use the next animal in your quiver, or mint a new one if you don't have one, or wait till the next round if there are no more animals to mint.
     */
  function fight(Direction direction)
    external
    onlyCurrentPlayer
    returns (Position memory newPosition)
  {
    Animal[] memory challengerQuiver = getQuiver(msg.sender);
    Animal memory challenger = challengerQuiver[0];
    Position memory challengerPos = playerToPosition[msg.sender];

    (uint8 rowToCheck, uint8 colToCheck) = _getCoordinatesToCheck(
      challengerPos.row,
      challengerPos.col,
      direction,
      1
    );

    // check there is an animal there
    // TODO: Check that it is wild
    require(
      !_checkIfEmptyCell(rowToCheck, colToCheck),
      "Cannot try to fight on empty square"
    );

    uint256 theGuyGettingFoughtId = safariMap[rowToCheck][colToCheck];
    Animal memory theGuyGettingFought = idToAnimal[theGuyGettingFoughtId];

    emit FightAttempt(challenger.owner, theGuyGettingFought.owner);

    // apply multiplier based on delta of aggression, speed, strength, size
    uint256 multiplier = ((challenger.aggression -
      theGuyGettingFought.aggression) +
      (challenger.speed - theGuyGettingFought.speed) +
      (challenger.strength - theGuyGettingFought.strength) +
      (challenger.size - theGuyGettingFought.size) +
      1) * (s_randomWords[0] / 1e73);

    if (multiplier > 5000) {
      emit ChallengerWonFight(
        challenger.owner,
        theGuyGettingFought.owner,
        rowToCheck,
        colToCheck
      );
      // If challenger wins the fight, challenger moves into loser's square, loser is burned
      deleteFirstAnimalFromQuiver(
        theGuyGettingFought.owner,
        theGuyGettingFought.id
      );
      Position memory newPosition;

      // Challenger won and moves into the space of the defender
      if (_checkIfEmptyCell(rowToCheck, colToCheck)) {
        newPosition = move(direction, 1);
      } else {
        // Challenger lost and he either was deleted or remains with next animal from quiver on deck
        newPosition = challengerPos;
        if (movesRemaining[challenger.owner] != 0) {
          movesRemaining[challenger.owner] -= 1;
        }
      }

      return newPosition;
    } else {
      // If lose burn loser, nobody moves
      deleteFirstAnimalFromQuiver(challenger.owner, challenger.id);
      emit ChallengerLostFight(
        challenger.owner,
        theGuyGettingFought.owner,
        challengerPos.row,
        challengerPos.col
      );
      return challengerPos;
    }
  }

  /**
        @dev Fuck an animal and maybe you can conceive (mint) a baby animal to your quiver.
     */
  function fuck(Direction direction)
    external
    onlyCurrentPlayer
    returns (bool won, Position memory newPosition)
  {
    require(movesRemaining[msg.sender] >= 1, "You have no remaining moves");
    require(whosTurnNext == msg.sender, "It ain't your turn, guy");
    require(s_randomWords.length > 0, "Randomness must be fulfilled already.");
    // load player's animal
    Animal[] memory fuckerQuiver = getQuiver(whosTurnNext);
    Animal memory fucker = fuckerQuiver[0];

    Position memory challengerPos = playerToPosition[whosTurnNext];

    (uint8 rowToCheck, uint8 colToCheck) = _getCoordinatesToCheck(
      challengerPos.row,
      challengerPos.col,
      direction,
      1
    );

    // check there is a wild animal there
    require(
      !_checkIfEmptyCell(rowToCheck, colToCheck),
      "Cannot try to fuck on empty square"
    );

    uint256 fuckeeId = safariMap[rowToCheck][colToCheck];
    Animal memory fuckee = idToAnimal[fuckeeId];

    require(fucker.owner != fuckee.owner, "Can't fuck yourself, mate");
    // require(fuckee.gender != fucker.gender, "Cannot impregnate same sex animal");

    emit FuckAttempt(whosTurnNext, fuckee.owner);

    // apply multiplier based on libido and fertility
    uint256 multiplier = ((fucker.libido * fuckee.fertility) /
      sqrt(s_randomWords[0] / 1e73)) % 100;

    if (multiplier > 50) {
      // If success, move animal to fucker's quiver mint new baby and move into the space
      uint256 idOfNewBaby = giveBirth(fucker.owner);

      quiver[fucker.owner].push(fuckee);
      deleteFirstAnimalFromQuiver(fuckee.owner, fuckee.id);
      Position memory newPosition;
      // if that was their last animal
      if (_checkIfEmptyCell(rowToCheck, colToCheck)) {
        newPosition = move(direction, 1);
      } else {
        newPosition = challengerPos;
        movesRemaining[fucker.owner] -= 1;
      }

      emit FuckSuccess(fucker.owner, idOfNewBaby);

      return (true, newPosition);
    } else {
      // If fail, replace from quiver
      deleteFirstAnimalFromQuiver(fucker.owner, fucker.id);
      return (false, challengerPos);
    }
  }

  // Babylonian method same as Uniswap uses
  function sqrt(uint256 y) internal pure returns (uint256 z) {
    if (y > 3) {
      z = y;
      uint256 x = y / 2 + 1;
      while (x < z) {
        z = x;
        x = (y / x + x) / 2;
      }
    } else if (y != 0) {
      z = 1;
    }
  }

  /**
        @dev Flee an animal and maybe end up in the next square but if the square you land on has an animal on it again, then you have to fight or fuck it.

        It will pick a random direction and move you 3 squares over any obstacles. If you land on an animal then you need to fuck or fight it.

        You need to be next to at least one animal to flee. Otherwise just move().
     */
  function flee() external payable returns (Position memory newPosition) {
    Position memory fleerPos = playerToPosition[msg.sender];
    // adjacent animals
    Position[4] memory adjacents = _getAdjacents(fleerPos);

    require(adjacents.length > 0, "Need at least one adjacent to flee.");

    uint256 directionIndex = s_randomWords[2] % 4;
    Direction direction;
    if (directionIndex == 0) {
      direction = Direction.Up;
    } else if (directionIndex == 1) {
      direction = Direction.Down;
    } else if (directionIndex == 2) {
      direction = Direction.Left;
    } else {
      direction = Direction.Right;
    }
    // move them 3 squares
    (uint8 rowToCheck, uint8 colToCheck) = _getCoordinatesToCheck(
      fleerPos.row,
      fleerPos.col,
      direction,
      3
    );

    if (_checkIfEmptyCell(rowToCheck, colToCheck)) {
      // if land on empty, stop
      Position memory newPosition = move(direction, 3);
      return newPosition;
    } else {
      // if land on animal, flee fails, player remains on their current cell.
      movesRemaining[msg.sender] -= 1;
      return fleerPos;
    }
  }

  function _getAdjacents(Position memory position)
    internal
    view
    returns (Position[4] memory adjacents)
  {
    uint256 top = safariMap[position.row - 1][position.col];
    uint256 down = safariMap[position.row + 1][position.col];
    uint256 left = safariMap[position.row][position.col - 1];
    uint256 right = safariMap[position.row][position.col + 1];

    Position[4] memory result;

    if (top != 0) {
      result[0] = Position({
        animalId: top,
        row: position.row - 1,
        col: position.col
      });
    }

    if (down != 0) {
      result[1] = Position({
        animalId: down,
        row: position.row + 1,
        col: position.col
      });
    }

    if (left != 0) {
      result[2] = Position({
        animalId: left,
        row: position.row,
        col: position.col - 1
      });
    }

    if (right != 0) {
      result[3] = Position({
        animalId: right,
        row: position.row,
        col: position.col + 1
      });
    }

    return result;
  }

  function _getCoordinatesToCheck(
    uint8 currentRow,
    uint8 currentCol,
    Direction direction,
    uint8 howManySquares
  ) internal pure returns (uint8, uint8) {
    uint8 rowToCheck = direction == Direction.Up
      ? currentRow - howManySquares
      : direction == Direction.Down
      ? currentRow + howManySquares
      : currentRow;
    uint8 colToCheck = direction == Direction.Left
      ? currentCol - howManySquares
      : direction == Direction.Right
      ? currentCol + howManySquares
      : currentCol;

    return (rowToCheck, colToCheck);
  }

  function _checkIfEmptyCell(uint8 rowToCheck, uint8 colToCheck)
    internal
    view
    returns (bool)
  {
    if (safariMap[rowToCheck][colToCheck] == 0) {
      return true;
    }
    return false;
  }

  /**
        @dev An Asteroid hits the map every interval of X blocks and we'll reset the game state:
            a) All Wild Animals are burned and taken off the map.
            b) All Domesticated Animals that are on the map are burned and taken off the map. If there is another one in the quiver, that one takes its place on the same cell.
            c) mapGenesis() again, but minus the delta of how many domesticated animals survived (were minted but in the quiver, not on the map).
     */
  function omfgAnAsteroidOhNo() external returns (bool) {
    // Take Animal's off the map if quiver empty, else place next up on the same position.
    // FIXME: this is gonna be shit O(|ROWS| + |COLS|)
    for (uint256 r = 0; r <= NUM_ROWS; r++) {
      for (uint256 c = 0; c <= NUM_COLS; c++) {
        uint256 idOfAnimalHere = safariMap[r][c];

        if (!(idOfAnimalHere == 0) && !(r == 0 && c == 0)) {
          // update the Position in Animal itself
          deleteFirstAnimalFromQuiver(ownerOf(idOfAnimalHere), idOfAnimalHere);
        }
      }
    }

    isGameInPlay = false;
    return true;
  }

  function deleteFirstAnimalFromQuiver(address who, uint256 id) internal {
    Position memory position = idToPosition[id];

    // You're out of animals, remove from map and burn
    if (who == address(this) || quiver[who].length <= 1) {
      delete idToAnimal[id];
      delete idToPosition[id];
      delete safariMap[position.row][position.col];
      delete playerToPosition[who];
      delete quiver[who];
      delete movesRemaining[who];

      emit AnimalBurnedAndRemovedFromCell(id, who, position.row, position.col);
    } else {
      // shift all the items right by 1, then pop the last element.
      for (uint256 i = 0; i < quiver[who].length - 1; i++) {
        quiver[who][i] = quiver[who][i + 1];
      }
      quiver[who].pop();

      Animal memory nextUp = quiver[who][0];

      idToPosition[nextUp.id] = position;
      idToAnimal[nextUp.id] = nextUp;
      safariMap[position.row][position.col] = nextUp.id;

      emit AnimalReplacedFromQuiver(
        nextUp.id,
        nextUp.owner,
        position.row,
        position.col
      );
    }

    _burn(id);
  }

  function giveBirth(address to) internal returns (uint256) {
    createAnimal(to);

    return currentTokenId + 1;
  }

  /**
        @dev Mint a character for a paying customer
        @param to address of who to mint the character to
     */
  function mintTo(address to) public payable returns (uint256) {
    if (msg.value < MINT_PRICE) {
      revert MintPriceNotPaid();
    }

    // FIXME: minting period
    if (mintingPeriodStartTime + 5 minutes <= block.timestamp) {
      isGameInPlay = true;

      revert MintingPeriodOver();
    }

    createAnimal(to);
    addPlayer(to);

    return currentTokenId + 1;
  }

  function addPlayer(address who) internal {
    for (uint256 i = 0; i < allPlayers.length; i++) {
      if (allPlayers[i] == who) {
        return;
      }
    }

    allPlayers.push(who);
    emit PlayerAdded(who, allPlayers.length);
  }

  function getQuiver(address who)
    public
    view
    returns (Animal[] memory myQuiver)
  {
    return quiver[who];
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    if (ownerOf(tokenId) == address(0)) {
      revert NonExistentTokenUri();
    }

    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString()))
        : "";
  }

  function withdrawPayments(address payable payee) external onlySuperOwner {
    uint256 balance = address(this).balance;
    (bool transferTx, ) = payee.call{ value: balance }("");
    if (!transferTx) {
      revert WithdrawTransfer();
    }
  }

  // VRF
  function getRandomWords() public {
    require(s_subscriptionId != 0, "Subscription ID not set");

    s_requestId = COORDINATOR.requestRandomWords(
      s_keyHash,
      s_subscriptionId,
      s_requestConfirmations,
      s_callbackGasLimit,
      s_numWords
    );
  }

  function getWords(uint256 requestId)
    internal
    view
    returns (uint256[] memory)
  {
    uint256[] memory _words = new uint256[](s_numWords);
    for (uint256 i = 0; i < s_numWords; i++) {
      _words[i] = uint256(keccak256(abi.encode(requestId, i)));
    }
    return _words;
  }

  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external returns (bytes4) {
    return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
  }
}