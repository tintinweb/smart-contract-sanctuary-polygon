// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./INFTCollection.sol";
import "./ICollectionFactory.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// TODO: EVENTS!!

contract NftStore is VRFConsumerBaseV2 {

  // Chainlink price feed interface
  AggregatorV3Interface priceFeed;
  // ChainLink parameters for getting random number
  VRFCoordinatorV2Interface COORDINATOR;
  LinkTokenInterface LINKTOKEN;
  // RadikalRiders Chainlink subscription ID.
  uint64 s_subscriptionId;
  // Polygon Mainnet coordinator
  address vrfCoordinator;
  // Polygon Mainnet LINK token contract
  address link;
  // The gas lane to use, which specifies the maximum gas price to bump to
  bytes32 keyHash;
  // fulfillRandomWords() function. Storing each word costs about 20,000 gas
  uint32 callbackGasLimit;
  // The default is 3, but you can set this higher.
  uint16 requestConfirmations;
  // Last Chainlink requestId generated for this contract
  uint256 public s_requestId;
  // LINK fee in Matic to be charged to user as result of using ChainLink
  uint chainlinkFeeMatic;
  // Admin address
  address payable admin;

  address public factoryAddress;
  ICollectionFactory collectionFactory;

  struct UserMysteryBoxes {
    address collectionAddres;
    uint counter;
  }

  struct UserNfts {
    address collectionAddres;
    uint[] nftIds;
  }

  mapping(address => mapping(address => uint)) public mysteryBoxUserCounter;
  mapping(address => mapping(address => bool)) userHasCollectionMB;
  mapping(address => mapping(address => bool)) userHasCollectionNft;
  mapping(address => address[]) userToCollectionsMB;
  mapping(address => address[]) userToCollectionsNft;
  mapping(address => uint) public mysteryBoxCounter;
  mapping(address => uint) public nftCounter;
  mapping(uint => address) requestToSender;
  mapping(uint => address) requestToCollection;
  mapping(address => uint) userToRequest;
  mapping(uint => uint16) requestToIndex;

  constructor(
    address _priceFeedAddress,
    address _factoryAddress,
    uint64 subscriptionId, 
    address _vrfCoordinator, 
    address _link, 
    bytes32 _keyHash, 
    uint32 _callbackGasLimit, 
    uint16 _requestConfirmations,
    address payable _admin
  )
    VRFConsumerBaseV2(_vrfCoordinator)
  {
    priceFeed = AggregatorV3Interface(_priceFeedAddress);
    collectionFactory = ICollectionFactory(_factoryAddress);
    vrfCoordinator = _vrfCoordinator;
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    link = _link; 
    keyHash = _keyHash;
    callbackGasLimit = _callbackGasLimit;
    requestConfirmations = _requestConfirmations;
    LINKTOKEN = LinkTokenInterface(link);    
    s_subscriptionId = subscriptionId;
    // Fee to pay chainLink VRF usage in presale
    chainlinkFeeMatic = 60000000000000000;
    admin = _admin;
  }  

  function buyMysteryBox(address _collectionAddress) public payable {    
    ICollectionFactory.Collections memory collections = collectionFactory.getCollection(_collectionAddress);
    require(
      mysteryBoxCounter[_collectionAddress] < collections.mysteryBoxCap,
      "NftStore: all Mystery Boxes were already sold"
    );
    require(
      block.timestamp < collections.presaleDate, 
      "NftStore: presale is over"
    );
    uint price = collections.mysteryBoxUsdPrice * (10 ** 18) * (10 ** 6) / getLatestPrice();
    require(
      (price + chainlinkFeeMatic) <= msg.value,
      "NftStore: the amount paid did not cover the price"
    );

    address payable owner = payable(collections.owner);
    owner.transfer(price);
    admin.transfer(chainlinkFeeMatic);
    payable(msg.sender).transfer(msg.value - price - chainlinkFeeMatic);
    mysteryBoxUserCounter[msg.sender][_collectionAddress] ++;
    mysteryBoxCounter[_collectionAddress] ++;
    if(userHasCollectionMB[msg.sender][_collectionAddress] == false) {
      userHasCollectionMB[msg.sender][_collectionAddress] = true;
      userToCollectionsMB[msg.sender].push(_collectionAddress);
    }
  }

  function mint(address _collectionAddress) public payable {
    ICollectionFactory.Collections memory collections = collectionFactory.getCollection(_collectionAddress);
    require(
      block.timestamp > collections.presaleDate,
      "NftStore: NFT cannot be minted during presale"
    );

    require(
      nftCounter[_collectionAddress] < (collections.nftCap + mysteryBoxCounter[_collectionAddress]),
      "NftStore: all NFT were already sold"
    );

    if(mysteryBoxUserCounter[msg.sender][_collectionAddress] == 0) {
      uint price = collections.nftUsdPrice * (10 ** 18) * (10 ** 6) / getLatestPrice();
      require(
        (price + chainlinkFeeMatic) <= msg.value,
       "NftStore: the amount paid did not cover the price"
      );
      address payable owner = payable(collections.owner);
      owner.transfer(price);
      admin.transfer(chainlinkFeeMatic);
      payable(msg.sender).transfer(msg.value - price - chainlinkFeeMatic);
    } else {
      mysteryBoxUserCounter[msg.sender][_collectionAddress] --;
      mysteryBoxCounter[_collectionAddress] --;
    }
    nftCounter[_collectionAddress] ++;
    _requestRandomWords(1, _collectionAddress, msg.sender);
    if(userHasCollectionNft[msg.sender][_collectionAddress] == false) {
      userHasCollectionNft[msg.sender][_collectionAddress] = true;
      userToCollectionsNft[msg.sender].push(_collectionAddress);
    }

  }

  function _requestRandomWords(uint32 _numWords, address _collectionAddress, address _user) internal {
    s_requestId  = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      _numWords
    );
    requestToSender[s_requestId] = msg.sender;
    requestToCollection[s_requestId] = _collectionAddress;
    userToRequest[_user] = s_requestId;
  }

  function fulfillRandomWords(
    uint256 requestId,
    uint256[] memory randomWords
  ) 
    internal override 
  {
    address collectionAddress = requestToCollection[requestId];
    uint remaining = collectionFactory.getCollection(collectionAddress).availableNfts.length;
    uint16 index = uint16(randomWords[0] % remaining);
    requestToIndex[requestId] = index;
  }

  function revealNFT(address _user) external {
    collectionFactory.updateAvailableNFts(
      requestToCollection[userToRequest[_user]],
      _user, 
      requestToIndex[userToRequest[_user]]); // REVIEW: updateColllection is named udateAvailableNFTs now
  }

  function getLatestPrice() public view returns (uint) {
    (
      /*uint80 roundID*/,
      int price,
      /*uint startedAt*/,
      /*uint timeStamp*/,
      /*uint80 answeredInRound*/
    ) = priceFeed.latestRoundData();
    return uint(price);
  }

  function getUserMysteryBoxes(address _user) public view returns (UserMysteryBoxes[] memory) {
    address[] memory collections = userToCollectionsMB[_user];
    UserMysteryBoxes[] memory userMysteryBoxes = new UserMysteryBoxes[](collections.length);
    for(uint i = 0; i < collections.length; i++) {
      uint counter = mysteryBoxUserCounter[_user][collections[i]];
      userMysteryBoxes[i] = UserMysteryBoxes(
        collections[i],
        counter
      );    
    }
    return userMysteryBoxes;
  }

  function getUserNfts(address _user) public view returns(UserNfts[] memory) {
    address[] memory collections = userToCollectionsNft[_user];
    UserNfts[] memory userNfts = new UserNfts[](collections.length);
    for(uint i = 0; i < collections.length; i++) {
      uint[] memory nftIds = collectionFactory.getTokenIdsByUser(_user, collections[i]);
      userNfts[i] = UserNfts(
        collections[i],
        nftIds
      );    
    }
    return userNfts;
  }

  function getTokenAmount(uint _usdAmount) public view returns(uint) {
    uint amount = _usdAmount * (10 ** 18) * (10 ** 6) / getLatestPrice();
    return (amount + (amount * 5 / 100));
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INFTCollection {
	function mint(uint _nftIndex, address _nftOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICollectionFactory {
  
  struct Collections {
    address collectionAddress;
    uint presaleDate;
    uint16 mysteryBoxCap;
    uint16 nftCap;
    uint16[] availableNfts;
    address owner;
    uint mysteryBoxUsdPrice;
    uint nftUsdPrice;
    bool frozen;
    string coverImageUri;
    string tokenName;
    string tokenDescription;
  }

	function updateAvailableNFts(address _nftCollection,address _user, uint16 _indexToDelete) external;
  function getCollection(address _collectionAddress) external view returns(Collections memory);
  function getUserCollections(address _userAddress) external view returns(address[] memory);
  function getTokenIdsByUser(address _user, address _collection) external view returns (uint [] memory);
}

// SPDX-License-Identifier: MIT
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

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}