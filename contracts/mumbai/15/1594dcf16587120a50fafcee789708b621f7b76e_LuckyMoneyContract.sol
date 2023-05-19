/**
 *Submitted for verification at polygonscan.com on 2023-05-19
*/

// File: @chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol


pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

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
  //error OnlyCoordinatorCanFulfill(address have, address want);
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
    // if (msg.sender != vrfCoordinator) {
    //   revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    // }
    fulfillRandomWords(requestId, randomWords);
  }
}

// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



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
    constructor () {
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

// File: contracts/luckymoney.sol

pragma solidity ^0.8.18;







/**
 * @title GameContract
 */
contract LuckyMoneyContract is VRFConsumerBaseV2,Ownable {
    uint256 public  min_entryfee = 0.01 ether;
    uint8   public  fee = 10;
    uint16  public  max_limit_players = 100;
    uint256 public  game_min_time = 2 hours;
    uint256 public  redeem_min_time = 2 hours;
    uint256 private game_income = 0;

   
    struct GameData {
        uint16  maxPlayers;
        uint16  currentPlayers;
        bool    gameOver;
        uint256 gameValue;
        uint256 createtime;
        uint256 closedtime;
    }

    // Chainlink VRF Data
    bytes32 public keyHash;
    event RequestedRandomness(uint256 requestId);

    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;
    // Your subscription ID.
    uint64 public s_subscriptionId;
    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 public callbackGasLimit = 100000;

    // The default is 3, but you can set this higher.
    uint16 public requestConfirmations = 3;

    // For this example, retrieve 5 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords =  1;
    
    uint32  gameNo=0;
    mapping(uint32 => GameData)  internal allGameData; //gameid->GameData
    mapping(uint32 => address payable[]) internal  allPlayers; ////gameid->address[]
    mapping(uint256 => uint32) internal gameID;//requestid->gameid
  

    
    event GameCreated(uint32 gameid, address gameOwner,uint16 maxPlayers, uint256 amount);
    event GameJoined(uint32 gameid, address playerAddress, uint16 currentPlayers);
    event GameRandom(uint32 gameid, uint256 randomResult);
    event GameLuckyNum(uint32 gameid, uint16 num,uint256 amount);
    event GameClosed(uint32 gameid);

    /**
     * Contract's constructor
     * @param _vrfCoordinator address of Chainlink's VRFCoordinator contract
     * @param _link address of the LINK token
     * @param _keyHash public key of Chainlink's VRF
     */
    constructor(
        address _vrfCoordinator,
        address _link,
        bytes32 _keyHash
    )   VRFConsumerBaseV2(_vrfCoordinator) public {
        keyHash = _keyHash;
        
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        
        LINKTOKEN = LinkTokenInterface(_link);
    
        //Create a new subscription when you deploy the contract.
        createNewSubscription();

       
    }

    function getGameIncome() public view onlyOwner returns(uint256) {
        return game_income;
    }

    function setMaxLimitPlayer(uint16 _max_limit_players) external onlyOwner {
        max_limit_players = _max_limit_players;
    }

    function setMinEntryFee(uint256 _min_entryfee) external onlyOwner {
        min_entryfee = _min_entryfee;
    }

    function setFee(uint8 _fee) external onlyOwner {
         require(_fee < 100, "Minimum bet amount not met");
        fee = _fee;
    }

    function setCallbackGasLimit(uint32 _GasLimit) external onlyOwner {
        callbackGasLimit = _GasLimit;
    }

    function setRequestConfirmations(uint16 _requestConfirmations) external onlyOwner {
        requestConfirmations = _requestConfirmations;
    }


    function setKeyHash(bytes32 _keyHash) external onlyOwner {
        keyHash = _keyHash;
    }

    function setRedeemMinTime(uint256 _redeem_min_time) external onlyOwner {
        redeem_min_time = _redeem_min_time;
    }

    function setGameMinTime(uint256 _game_min_time) external onlyOwner {
        game_min_time = _game_min_time;
    }
    

    function canBeClosed(uint32 gameid)  public view   returns (bool)  { 
        bool ret = false;

         if(allGameData[gameid].gameOver == false){
              if(allGameData[gameid].currentPlayers < allGameData[gameid].maxPlayers){
                  if( allGameData[gameid].closedtime == 0 && block.timestamp - allGameData[gameid].createtime > game_min_time){
                       ret = true;
                       }

              }else{
                  if(allGameData[gameid].closedtime > 0 && block.timestamp - allGameData[gameid].closedtime > redeem_min_time){
                      ret = true;
                      }
              }
         }

        return ret;
    }


    function closeGame(uint32 gameid) external {
        require(canBeClosed(gameid) == true , 'game can not be close!');
        // if(allGameData[gameid].currentPlayers < allGameData[gameid].maxPlayers){
        //     require(allGameData[gameid].closedtime == 0, 'closedtime must == 0');
        //     require(block.timestamp - allGameData[gameid].createtime > game_min_time,  'game time not passed');
        // }
        // else{
        //      require(allGameData[gameid].closedtime > 0, 'closedtime must > 0');
        //      require(block.timestamp - allGameData[gameid].closedtime > redeem_min_time,  'Redeem time not passed');


        // }

        allGameData[gameid].gameOver == true;

        for (uint16 i = 0; i < allGameData[gameid].currentPlayers; i++) {
            payable(allPlayers[gameid][i]).transfer(allGameData[gameid].gameValue);
        }

         emit GameClosed(gameid);
    }
    
   

    function createGame( uint16 _maxPlayers) public payable  returns (uint32)  {
        require(msg.value >= min_entryfee, "Minimum bet amount not met");
        require(_maxPlayers > 1 && _maxPlayers <= max_limit_players, "invalid Max players");

        gameNo++;
        allGameData[gameNo] = GameData({
            maxPlayers: _maxPlayers,
            currentPlayers: 1,
            gameOver:false,
            gameValue:msg.value,
            createtime:block.timestamp,
            closedtime:0
        });

        allPlayers[gameNo].push(payable(msg.sender));
        
        emit GameCreated(gameNo, msg.sender, _maxPlayers, msg.value) ;
        return gameNo;
    }
    
    function getGameInfo(uint32 _gameid) public view returns (GameData memory) {
        return allGameData[_gameid];
    }

    function getPlayersInfo(uint32 _gameid) public view returns (address payable[] memory) {
        return allPlayers[_gameid];
    }

    function withdraw() external onlyOwner {
          require(game_income > 0);
          uint256 ret = game_income;
          game_income=0;
          payable(owner()).transfer(ret);
        
    }

   

    function fulfillRandomWords(
        uint256 requestId, /* requestId */
        uint256[] memory randomWords
    ) internal override {

        assert(randomWords.length >0);
       
        uint32 gameid = gameID[requestId];

        require(allGameData[gameid].gameOver == false);

        allGameData[gameid].gameOver=true;

        uint256 randomValue = randomWords[0];

        uint256 totalPayouts = allGameData[gameid].gameValue * allGameData[gameid].currentPlayers;
       

        uint256 maxPayout = totalPayouts * (100-fee)/ 100;
        uint256 remainingPayout = totalPayouts - maxPayout;
        game_income += remainingPayout;
         
        uint16 luckynum = uint16 ( randomValue % allGameData[gameid].currentPlayers);
        
        payable(allPlayers[gameid][luckynum]).transfer(maxPayout);
        emit GameLuckyNum(gameid, luckynum, maxPayout);


       
    }

   
   


    function joinTheGame(uint32 gameid) public payable {
        require(allGameData[gameid].currentPlayers > 0, "Game is not exist");
        require(allGameData[gameid].currentPlayers < allGameData[gameid].maxPlayers, "Game is full");
        require(allGameData[gameid].gameOver == false, "Game is over");

        require(msg.value >= min_entryfee, "Minimum bet amount not met");
        require(msg.value >= allGameData[gameid].gameValue, "Must send ether with the transaction");

        if(msg.value > allGameData[gameid].gameValue){
            game_income += msg.value - allGameData[gameid].gameValue;
        }

        allGameData[gameid].currentPlayers++;
        emit GameJoined(gameid, msg.sender,allGameData[gameid].currentPlayers);

       if (allGameData[gameid].currentPlayers == allGameData[gameid].maxPlayers) {

           uint256 requestId = getRandomNumber();
           gameID[requestId] = gameid;
           allGameData[gameid].closedtime = block.timestamp;
        }
    }


    /**
     * Creates a randomness request for Chainlink VRF
     * @return requestId id of the created randomness request
     */
    function getRandomNumber() private returns (uint256 requestId) {
        //require(LINKTOKEN.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        //uint256 seed = uint256(keccak256(abi.encode(userProvidedSeed, blockhash(block.number)))); // Hash user seed and blockhash
        //bytes32 _requestId = requestRandomness(keyHash, fee, seed);
        uint256 _requestId = COORDINATOR.requestRandomWords(
                                    keyHash,
                                    s_subscriptionId,
                                    requestConfirmations,
                                    callbackGasLimit,
                                    numWords
                                    );
        emit RequestedRandomness(_requestId);
        return _requestId;
    }



      
    // Create a new subscription when the contract is initially deployed.
    function createNewSubscription() private onlyOwner {
        // Create a subscription with a new subscription ID.
        address[] memory consumers = new address[](1);
        consumers[0] = address(this);
        s_subscriptionId = COORDINATOR.createSubscription();
        // Add this contract as a consumer of its own subscription.
        COORDINATOR.addConsumer(s_subscriptionId, consumers[0]);
    }

    // Assumes this contract owns link.
    // 1000000000000000000 = 1 LINK
    function topUpSubscription(uint256 amount) external onlyOwner {
        LINKTOKEN.transferAndCall(address(COORDINATOR), amount, abi.encode(s_subscriptionId));
    }

    function addConsumer(address consumerAddress) external onlyOwner {
        // Add a consumer contract to the subscription.
        COORDINATOR.addConsumer(s_subscriptionId, consumerAddress);
    }

    function removeConsumer(address consumerAddress) external onlyOwner {
        // Remove a consumer contract from the subscription.
        COORDINATOR.removeConsumer(s_subscriptionId, consumerAddress);
    }

    function cancelSubscription(address receivingWallet) external onlyOwner {
        // Cancel the subscription and send the remaining LINK to a wallet address.
        COORDINATOR.cancelSubscription(s_subscriptionId, receivingWallet);
        s_subscriptionId = 0;
    }

    // Transfer this contract's funds to an address.
    // 1000000000000000000 = 1 LINK
    function withdraw(uint256 amount, address to) external onlyOwner {
        LINKTOKEN.transfer(to, amount);
    }

}