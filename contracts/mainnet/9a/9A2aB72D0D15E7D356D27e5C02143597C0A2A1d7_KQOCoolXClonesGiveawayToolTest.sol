/**
 *Submitted for verification at polygonscan.com on 2022-06-24
*/

// SPDX-License-Identifier: MIT

/*
 ___  ___  ________  ________  ___       ___  ___  ________      
|\  \|\  \|\   __  \|\   ___ \|\  \     |\  \|\  \|\   __  \     
\ \  \\\  \ \  \|\  \ \  \_|\ \ \  \    \ \  \\\  \ \  \|\  \    
 \ \   __  \ \  \\\  \ \  \ \\ \ \  \    \ \   __  \ \  \\\  \   
  \ \  \ \  \ \  \\\  \ \  \_\\ \ \  \____\ \  \ \  \ \  \\\  \  
   \ \__\ \__\ \_______\ \_______\ \_______\ \__\ \__\ \_____  \ 
    \|__|\|__|\|_______|\|_______|\|_______|\|__|\|__|\|___| \__\
                                                            \|__|
*/

//Line 379 for main class



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

// File: CoolXClonesGiveawayTool.sol

pragma solidity ^0.8.7;

contract KQOCoolXClonesGiveawayToolTest is VRFConsumerBaseV2, Ownable {
    uint64 s_subscriptionId;
    address vrfCoordinator = 0xAE975071Be8F8eE67addBC1A82488F1C24858067;
    bytes32 s_keyHash = 0xd729dc84e21ae57ffb6be0053bf2b0668aa2aaf300a2a7b2ddf7dc0bb6e875a8;
    uint32 callbackGasLimit = 400000;
    uint16 requestConfirmations = 3;
    uint32 numWords =  1;
    VRFCoordinatorV2Interface COORDINATOR;
    uint public listLength = 55;

    address[55] public addressList = [
        address(0xc5E49AC5a5D11c8ca65d27309Aaf85d8CE8F8a4A),
        address(0xBF23F63FecEa0235A143a9bd94B8aae36f953B4d),
        address(0xAEc1ef944354faF21DFF3BEe76C2fCA5Ca58b3ce),
        address(0x715cc980013fA23F198a42aFBd9A479FcfFB464E),
        address(0x1440738DB5431b5B8CD0a00E9646A2c96E091f44),
        address(0x09332AC1638F390Af039c37a6B5C9382BE1bcfB8),
        address(0xd9C128EeEaaB4B80FA07C45431F89DAD10dDBF7A),
        address(0x6061098711B4ce3f107A509AC27247375E536D54),
        address(0x23c2477145Bc767e916E12ff6dB2CDe86faB8294),
        address(0x360cb7ebD85Fd8aDaD909BE393f9CDcC378b5cF6),
        address(0x3Ea40A276055DaDED71E326490cF1275F18BEf00),
        address(0xA2f3A2cf12FF3eddcc13a322B2eBe61A7AF5af6E),
        address(0xB5507Aa0Efd9e1B6C343c9eC3f5B4e5C40cEF654),
        address(0x534b8531e362Da97D808ba2ab3959fa2597BeF11),
        address(0xcD54FF0E52A61B6daB8c24D1348116ca3bB522A9),
        address(0x0Ef9D9b1b493069C264b373e1a42e0c8284d7951),
        address(0x785c8D210Ab8888dA6d121faA0a9568f75400B13),
        address(0xD1f25598ce30759F8F86e7e3b07c852bd36b49a7),
        address(0xAa6d90c3589473b278f47cC8586F8d2b9bfF7F29),
        address(0xEbcF567b673a1E1a1358C38B36E7384690dC7353),
        address(0x83Eb1f67E97906e7D21802C28F23f3D0eF16dE9D),
        address(0x31ab42f972841631c139E52Edfa990e67f3cc402),
        address(0x7BAce095602E2BaB41d09a26e0CBCCD13485D9eb),
        address(0xBA7A4c521DfCD18fEB7cdA4B7CA182d739B7A6a0),
        address(0x302DfdfDDb63f92c2c9985B0a6f9276F8697b436),
        address(0x427192C963Ebe7b600693eFE018d9526866398E4),
        address(0x2Cb94DFF679C15B3aEbb8E6beAb6012DA02dbC51),
        address(0xf4aEC459a622CF565De6a5446625E6a7A4f4C490),
        address(0xDDd7629086B612A8CCF8261887A47867419a1A18),
        address(0xd4305CE93d418d0Ee358EBf005425210980D341A),
        address(0x08492eaa6301b71aaBE8c269F03663b6B6a2d116),
        address(0x30d874A055c1A36161BB1cFE9B2feEd7E9930a01),
        address(0x20c350D67184b42d8626f6f38D487e0A08D37D11),
        address(0xb09209db8a7E4077d10A8Aea927CcF65242CFd9c),
        address(0x9D17F4E3f9FF2a6ea31bf75aFf1F23e5649E3976),
        address(0x5DcCd52f8425C4e9b05a90016D43Da64f8b1e472),
        address(0x94BBC2f753C4BF5f760a816560515cEe33d412FA),
        address(0x56fCf7dCa9B452ef252e8D59917AAf95aFcc9D67),
        address(0x19B10a0a9d911f56baD594222028a522B5F2D40c),
        address(0x5ac2379B7664d3729bcf82Db87C7A702Ef93F89b),
        address(0x67FcBC05CBe192abF58931f129992724A48C77B2),
        address(0x2DEC3F3c3f0B0c28F3fEd8003f3804853dc6F2A2),
        address(0x84705E94c98184b2D47026664CFaB2c38ccA1bf9),
        address(0x0B365305E034F8Ef63D39C9ed33fD060e05724dD),
        address(0xd10aF0000e7B124CAf601C87f95056f394aFeBC3),
        address(0x2aBEAd0274aB1304B16b6720019493a42F83b940),
        address(0xbd871A0119e63c410506beD673d3ee68054B869a),
        address(0xba55A4AD8B09C532fD5f330768A5C415e5cd689B),
        address(0xD06cB99d71fF3d6C2A1eE263db9A11dDD65Bd691),
        address(0x82a76439aCe5ba2B4e7830d3953891ab210df59F),
        address(0xA37FD8dCb5bD4bAEC2d1C96A1E3Df8A7901e7364),
        address(0x0Bdf418041922819d3a94D1B0a3b572C6f3C137B),
        address(0xAdfC4C71D50fEe1eC2dAf720Aa0b74A4d9a488f3),
        address(0x8Bb70849269d6Bf1106c0725E120794CA020C605),
        address(0xD520F4Fa8F2104630DCa20e0eC143859931381BE)
    ];

    constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
    }

    event Milked(uint256 indexed requestId, address winner);
    event StripingTeat(uint256 indexed requestId, string meta);

    function StartStriping(string memory meta) public onlyOwner returns (uint256 requestId) {
        requestId = COORDINATOR.requestRandomWords(s_keyHash,s_subscriptionId,requestConfirmations,callbackGasLimit,numWords);
        emit StripingTeat(requestId, meta);
    }

    function fulfillRandomWords(uint256 requestId , uint256[] memory randomWords) internal override {
        uint256 index = (randomWords[0] % listLength);
        emit Milked(requestId, addressList[index]);
    }
}