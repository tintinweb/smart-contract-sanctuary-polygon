/**
 *Submitted for verification at polygonscan.com on 2022-05-24
*/

// File: @chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol


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
   * same for a registered upkeep. This can easily be broken down into specific
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

// File: @chainlink/contracts/src/v0.8/KeeperBase.sol


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

// File: @chainlink/contracts/src/v0.8/KeeperCompatible.sol


pragma solidity ^0.8.0;



abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

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

// File: contracts/Profile.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Profile {
    address public owner;
    address[] allUsers;

    constructor() {
        owner = msg.sender;
    }

    struct userProfile {
        string name;
        string avatar;
        bool canBattle;
    }

    mapping(address=>userProfile) public users;

    function addUser(string memory name, string memory avatar) public {
        userProfile storage user = users[msg.sender];
        user.name = name;
        user.avatar = avatar;
        allUsers.push(msg.sender);
        if(msg.sender==owner) user.canBattle = true;
        else user.canBattle = false;
    }

    function getUserData() public view returns (userProfile memory) {
        return users[msg.sender];
    }

    function getUsersList() public view returns (address[] memory) {
        return allUsers;
    }

    function changeAvatar(string memory avatar) public {
        users[msg.sender].avatar = avatar;
    }
    
    function changeName(string memory name) public {
        users[msg.sender].name = name;
    }
}
// File: contracts/Battle.sol

pragma solidity ^0.8.0;


contract Battle is Profile {
    uint256 public monthNo = 1;
    uint256 public battleID = 0;
    uint256 public maxBattles = 100;
    bool public battlesPaused = false;

    struct BattleStruct {
        NFT nft1;
        NFT nft2;
        uint256 votes1;
        address[] _votes1;
        uint256 votes2;
        address[] _votes2;
        address[] allVotes;
        uint256 amount;
        bool finalized;
        uint256 _id;
    }

    struct NFT {
        address nftAddress;
        address payable ownerAddress;
        string image;
        string name;
    }

    mapping(uint256=>uint256) internal battleIds;
    mapping(uint256 => mapping(uint256 => BattleStruct)) internal BattlesMapping;

    function getVotes(uint256 battleId) public view returns (uint256, uint256) {
        uint vote1 = BattlesMapping[monthNo][battleId].votes1;
        uint vote2 = BattlesMapping[monthNo][battleId].votes2;
        return (vote1, vote2);
    }

    function getVoters1(uint256 battleId) public view returns (address[] memory) {
        return BattlesMapping[monthNo][battleId]._votes1;
    }

    function IncrementVote1(uint256 battleId) public areBattlesPaused {
        bool canVote;
        require(BattlesMapping[monthNo][battleId].finalized == true, 'Finalize the battle first');
        require(BattlesMapping[monthNo][battleId].nft1.ownerAddress != msg.sender, "You can't vote your own NFT");
        if(BattlesMapping[monthNo][battleId].allVotes.length==0) canVote=true;
        else{
            for(uint i=BattlesMapping[monthNo][battleId].allVotes.length; i>0; i=i-1){
                if(BattlesMapping[monthNo][battleId].allVotes[i-1]==msg.sender) {
                    canVote=false;
                    break;
                }
                else canVote=true;
            }     
        }   
        require(canVote==true, 'Already Voted!');
        BattlesMapping[monthNo][battleId].votes1 = BattlesMapping[monthNo][battleId].votes1 + 1;
        BattlesMapping[monthNo][battleId]._votes1.push(msg.sender);
        BattlesMapping[monthNo][battleId].allVotes.push(msg.sender);
    }
    
    function IncrementVote2(uint256 battleId) public areBattlesPaused {
        bool canVote;
        require(BattlesMapping[monthNo][battleId].finalized == true, 'Finalize the battle first');
        require(BattlesMapping[monthNo][battleId].nft2.ownerAddress != msg.sender, "You can't vote your own NFT");
        if(BattlesMapping[monthNo][battleId].allVotes.length==0) canVote=true;
        else{
            for(uint i=BattlesMapping[monthNo][battleId].allVotes.length; i>0; i=i-1){
                if(BattlesMapping[monthNo][battleId].allVotes[i-1]==msg.sender) {
                    canVote=false;
                    break;
                }
                else canVote=true;
            }     
        }   
        require(canVote==true, 'Already Voted!');
        BattlesMapping[monthNo][battleId].votes2 = BattlesMapping[monthNo][battleId].votes2 + 1;
        BattlesMapping[monthNo][battleId]._votes2.push(msg.sender);
        BattlesMapping[monthNo][battleId].allVotes.push(msg.sender);
    }

    function finalizeBattle(uint256 battleId, address _candidate2, string memory image, string memory name) payable checkAmount(msg.value) public {
        require(battleId<=battleID, 'Initialize a battle first');
        require(BattlesMapping[monthNo][battleId].finalized == false, 'Battle already finalized');
        /* Commenting for testing */
        // require(BattlesMapping[monthNo][battleId].nft1.ownerAddress != msg.sender, "You can't battle yourself, sorry!");
        BattlesMapping[monthNo][battleId].nft2.nftAddress = _candidate2;
        BattlesMapping[monthNo][battleId].nft2.ownerAddress = payable(msg.sender);
        BattlesMapping[monthNo][battleId].nft2.image = image;
        BattlesMapping[monthNo][battleId].nft2.name = name;
        BattlesMapping[monthNo][battleId].votes1 = 0;
        BattlesMapping[monthNo][battleId].votes2 = 0;
        BattlesMapping[monthNo][battleId].amount += msg.value;
        BattlesMapping[monthNo][battleId].finalized = true;
        users[msg.sender].canBattle = false;
    }

    function createInitialBattle(address _candidate1, string memory image, string memory name) payable checkAmount(msg.value) public areBattlesPaused {
        require(battleID+1<=maxBattles,'Battles limit exceeded for this battle season!');
        battleID += 1;
        BattleStruct storage battle = BattlesMapping[monthNo][battleID];
        battle.nft1.nftAddress = _candidate1;
        battle.nft1.ownerAddress = payable(msg.sender);
        battle.nft1.image = image;
        battle.nft1.name = name;
        battle.amount = msg.value;
        battle.finalized = false;
        battle._id = battleID;
        users[msg.sender].canBattle = false;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getBattleAmount() public view returns (uint256) {
        return battleID;
    }

    function getBattleData(uint256 battleId) public view returns (NFT memory,NFT memory,uint256, bool, uint256){
        return (BattlesMapping[monthNo][battleId].nft1, BattlesMapping[monthNo][battleId].nft2, BattlesMapping[monthNo][battleId].amount, BattlesMapping[monthNo][battleId].finalized, BattlesMapping[monthNo][battleId]._id);
    }

    function getBattleHistory(uint256 month, uint256 battleId) public view returns (BattleStruct memory){
        require(month<monthNo, 'No history available for this month');
        return BattlesMapping[month][battleId];
    }

    function getMonthNumber() public view returns (uint256) {
        return monthNo;
    }
    
    function getBattlesPaused() public view returns (bool) {
        return battlesPaused;
    }

    function getPastBattleIds(uint256 month) public view returns (uint256) {
        return battleIds[month];
    }

    modifier checkAmount(uint256 amount) {
        /* Require only these amount to start battles in mainnet */
        // require(amount == 25000000000000000000 || amount == 50000000000000000000 || amount == 100000000000000000000,'Not correct amount');
        _;
    }
    
    modifier areBattlesPaused() {
        require(!battlesPaused,'Battles are paused, please wait until they start again.');
        _;
    }
}

// File: contracts/NFTBetting.sol

pragma solidity ^0.8.0;


contract NFTBetting is Battle {
    uint256 nftID = 0;
    uint256 maxNFTs = 6;

    struct NFTStruct {
        _NFT nft;
        address[] betters;
        uint256 bets;
        bool winner;
        uint256 _id;
    }

    struct _NFT {
        address nftAddress;
        string image;
        string name;
    }

    mapping(uint256=>mapping(uint256=>NFTStruct)) NFTMapping;


    function addNFTS(string memory name, string memory image, address nftAddress) public onlyOwner areBattlesPaused{
        nftID += 1;
        NFTStruct storage NFTInstance = NFTMapping[monthNo][nftID];
        NFTInstance.nft.name = name;
        NFTInstance._id = nftID;
        NFTInstance.nft.image = image;
        NFTInstance.nft.nftAddress = nftAddress;
        NFTInstance.bets = 0;
        NFTInstance.winner = false;
    }

    function bet(uint256 nftid) payable public {
        require(msg.value==0.01 ether, 'Not correct bet amount');
        NFTMapping[monthNo][nftid].betters.push(msg.sender);
    }

    function getNFTNum() public view returns (uint256) {
        return nftID;
    }

    function getNFTs(uint256 nftId) public view returns (NFTStruct memory) {
        return NFTMapping[monthNo][nftId];
    }

    modifier onlyOwner(){
        require(msg.sender==owner, 'Only Owner can add NFTs');
        require(nftID+uint256(1)<=maxNFTs, 'MAX NFTs added');
        _;
    }
}

// File: contracts/VRF.sol


// An example of a consumer contract that relies on a subscription for funding.
pragma solidity ^0.8.7;




contract VRF is NFTBetting, VRFConsumerBaseV2 {
  VRFCoordinatorV2Interface COORDINATOR;

  // Your subscription ID.
  uint64 s_subscriptionId;

  // Rinkeby coordinator. For other networks,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  address vrfCoordinator = 	0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed;

  // The gas lane to use, which specifies the maximum gas price to bump to.
  // For a list of available gas lanes on each network,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  bytes32 keyHash = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;

  // Depends on the number of requested values that you want sent to the
  // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
  // so 100,000 is a safe default for this example contract. Test and adjust
  // this limit based on the network that you select, the size of the request,
  // and the processing of the callback request in the fulfillRandomWords()
  // function.
  uint32 callbackGasLimit = 100000;

  // The default is 3, but you can set this higher.
  uint16 requestConfirmations = 3;

  // For this example, retrieve 2 random values in one request.
  // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
  uint32 numWords =  1;

  uint256 public s_randomWords;
  uint256 public s_requestId;
  address s_owner;

  constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    s_owner = msg.sender;
    s_subscriptionId = subscriptionId;
  }

  // Assumes the subscription is funded sufficiently.
  function requestRandomWords() public onlyOwnerAccess {
    // Will revert if subscription is not set and funded.
    s_requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );
  }
  
  function fulfillRandomWords(
    uint256, /* requestId */
    uint256[] memory randomWords
  ) internal override {
    s_randomWords = (randomWords[0] % nftID) + 1;
    NFTMapping[monthNo][s_randomWords].winner = true;
  }

  modifier onlyOwnerAccess() {
    require(msg.sender == s_owner);
    _;
  }
}
// File: contracts/Bazooka.sol

pragma solidity ^0.8.0;



contract Bazooka is VRF, KeeperCompatibleInterface {

    /**
    * Use an interval in seconds and a timestamp to slow execution of Upkeep
    */
    uint public immutable interval;
    uint public immutable interval2;
    uint public lastTimeStamp;
    uint public lastTimeStamp2;

    constructor(uint updateInterval, uint updateInterval2) VRF(321){
      interval = updateInterval;
      interval2 = updateInterval2;
      lastTimeStamp = block.timestamp;
    }

    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory /* performData */) {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval || (block.timestamp - lastTimeStamp2) > interval2;
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        //We highly recommend revalidating the upkeep in the performUpkeep function
        if ((block.timestamp - lastTimeStamp) > interval ) {
            lastTimeStamp2 = block.timestamp;
            lastTimeStamp = block.timestamp;
            for(uint256 i=1; i<=battleID; i++){
                if((BattlesMapping[monthNo][i].votes1+BattlesMapping[monthNo][i].votes2) < uint256(1) || BattlesMapping[monthNo][i].votes1==BattlesMapping[monthNo][i].votes2){
                    uint256 amount = (uint256(BattlesMapping[monthNo][i].amount)/uint256(2));
                    BattlesMapping[monthNo][i].nft1.ownerAddress.transfer(amount);
                    BattlesMapping[monthNo][i].nft2.ownerAddress.transfer(amount);
                    continue;
                }
                uint256 _amount = (uint256(BattlesMapping[monthNo][i].amount)/uint256(5))*uint256(4);
                if(BattlesMapping[monthNo][i].votes1>BattlesMapping[monthNo][i].votes2){
                    BattlesMapping[monthNo][i].nft1.ownerAddress.transfer(_amount);
                    for(uint256 j=0; j<=BattlesMapping[monthNo][i]._votes1.length; j++){
                        users[BattlesMapping[monthNo][i]._votes1[j]].canBattle = true;
                    }
                }
                else if(BattlesMapping[monthNo][i].votes1<BattlesMapping[monthNo][i].votes2){
                    BattlesMapping[monthNo][i].nft2.ownerAddress.transfer(_amount);
                    for(uint256 j=0; j<=BattlesMapping[monthNo][i]._votes2.length; j++){
                        users[BattlesMapping[monthNo][i]._votes2[j]].canBattle = true;
                    }
                }
            }
            // requestRandomWords();
            battlesPaused = true;
        }
        if((block.timestamp - lastTimeStamp2) > interval2 ) {
            lastTimeStamp = block.timestamp;
            lastTimeStamp2 = block.timestamp + interval;
            battleIds[monthNo] = battleID;
            battlesPaused = false;
            monthNo += 1;
            battleID = 0;
            nftID = 0;
        }
        // We don't use the performData in this example. The performData is generated by the Keeper's call to your checkUpkeep function
    }
}