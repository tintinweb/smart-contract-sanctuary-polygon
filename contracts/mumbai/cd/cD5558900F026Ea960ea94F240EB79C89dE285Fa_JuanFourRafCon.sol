/**
 *Submitted for verification at polygonscan.com on 2023-01-06
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

// File: swerty/SwertRafHosted.sol


pragma solidity ^0.8.7;




interface IERC20 {
    function mint(uint256 amount) external;
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

contract JuanFourRafCon is VRFConsumerBaseV2, ReentrancyGuard {
    VRFCoordinatorV2Interface COORDINATOR;

    // Your subscription ID.
    uint64 s_subscriptionId;

    // Goerli coordinator. For other networks,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    address vrfCoordinator = 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed; //mumbai testnet
    // address vrfCoordinator = 0xAE975071Be8F8eE67addBC1A82488F1C24858067;
    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 keyHash = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f; //mumbai testnet
    // bytes32 keyHash = 0xcc294a196eeeb44da2888d17c0625cc88d70d9760a69d58d853ba6581a9ab0cd;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 400000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords =  3;

    uint256[] public s_randomWords;
    uint256 public s_requestId;
    address payable public s_owner;
    uint public balance = 0;
    bool public isActive = true;
    IERC20 public token_address; //SWRTC
    IERC20 public lease_address; //BIGT
    uint lastCreatedRoom;
    
    struct Room{
        bool active;
        bool forSale;
        address lessee;
        uint lessee_updatedAt;
        uint entryfee;
        uint price;
        uint pot;
        uint burn_rate;
        uint limit;
        uint playingSlot;
        address[] s_players;
        mapping(uint256 => uint256) prizes;
        mapping(address => uint256) s_player_wallets;
        mapping(uint256=>address) winning_places;
    }

    struct Rake{
        uint l_rake;
        uint l_rakeCollected;
    }

    //roomid=>Rake
    mapping(uint=>Rake) public rakeRecord;
    //roomid=>amount
    // mapping(uint=>uint) public RoomPrizePool;
     //roomid=>Room
    mapping(uint256=>Room) public raffle_room;

    mapping(uint=>bool) prizeSelection;

    uint[] public readyRooms;

    event TransferReceived(uint room_number,address _from, uint _amount, uint playersLength);
    event WinnerPicked(uint room_number,uint place, address player,uint amount, uint groupid); 
    event RakeTransfer(uint room_number,uint amount, address rakeCollector); 
    event ContractReset(uint room_number,uint timestamp); 
    event ChangeContractState(string state); 
    event ChangeContractStateByRoom(uint room_number,string state); 
    event PlayerWithdraw(uint room_number,address player,uint playersLength); 
    // event LeaseExpired(uint room_number,uint time);
    event NewRaffle(uint room_number,uint price, bool active);
    event NewLease(uint room_number,address lessee,uint newEntryfee,uint pot,uint limit,bool active,uint grandPrize,uint leaseType); // 0 = standard, 1 = sponsored
    // event OpenRaffleLease(uint room_number,uint time);
    event ExtendLease(uint room_number,uint time);
    event BurnedToken(uint room_number, uint amount, uint time);

    constructor(uint64 subscriptionId,IERC20 lease_token,IERC20 main_token) ReentrancyGuard() VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_owner = payable(msg.sender);
        s_subscriptionId = subscriptionId;
        token_address = IERC20(main_token);
        lease_address = lease_token;
        prizeSelection[50] = true;
        prizeSelection[75] = true;
        prizeSelection[100] = true;
    }

    modifier onlyOwner() {
        require(msg.sender == s_owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner{
        s_owner = payable(newOwner);
    }

    //B: Admin functions
    function createRaffle(uint room_number, uint256 price) public onlyOwner{
      require(raffle_room[room_number].active == false,"This room is taken");
        Room storage newRaffle = raffle_room[room_number];
        newRaffle.active = false;
        newRaffle.forSale = true;
        newRaffle.lessee = msg.sender;
        newRaffle.lessee_updatedAt = block.timestamp;
        newRaffle.entryfee = 1 ether; 
        newRaffle.price = price;
        newRaffle.playingSlot = 0;
        lastCreatedRoom = room_number;
        emit NewRaffle(room_number,price,false);
    }

    function removeReadyroom(uint index) public onlyOwner{
        removeRoom(index);
    }

    //General controle --- WARNING - this will pause all contracts
    function pauseContract() public onlyOwner{
        isActive = false;
        emit ChangeContractState("INACTIVE");
    }

    function reactiveContract() public onlyOwner{
        isActive = true;
        emit ChangeContractState("ACTIVE");
    }

    //
    function pauseContractByRoom(uint room_number) public onlyOwner{
        raffle_room[room_number].active = false;
        emit ChangeContractStateByRoom(room_number,"INACTIVE");
    }

    function reactiveContractByRoom(uint room_number) public onlyOwner{
        raffle_room[room_number].active = true;
        emit ChangeContractStateByRoom(room_number,"ACTIVE");
    }


    function join(uint entryFee, uint room_number) public nonReentrant {
        require(raffle_room[room_number].active == true, "This room is paused at the moment.");
        require(raffle_room[room_number].forSale == false, "This room is for sale.");
        require(raffle_room[room_number].playingSlot > 0, "This room does not have enough playing slots.");

        require(entryFee >= raffle_room[room_number].entryfee, "Please enter enough amount");
        require(raffle_room[room_number].s_players.length < raffle_room[room_number].limit, "This room is full");

        uint256 allowance = token_address.allowance(msg.sender,address(this));
        require(allowance >= entryFee, "You don't have enough allowance to join.");

        token_address.transferFrom(msg.sender, address(this), entryFee);
        raffle_room[room_number].s_players.push(msg.sender);
        emit TransferReceived(room_number,msg.sender, entryFee, raffle_room[room_number].s_players.length);
        balance = balance + entryFee;

        if(raffle_room[room_number].s_players.length == raffle_room[room_number].limit){
            readyRooms.push(room_number);
            _requestRandomWords();
            // _test_requestRW();
        }
    }

    //prevents duplication of winner
    function remove(uint room_number,uint index)  private {
        if (index >= raffle_room[room_number].s_players.length) return;
        for (uint i = index; i < raffle_room[room_number].s_players.length-1; i++){
            raffle_room[room_number].s_players[i] = raffle_room[room_number].s_players[i+1];
        }
        raffle_room[room_number].s_players.pop();
    }

    function removeRoom(uint index) private{
        if (index >= readyRooms.length) return;
        for (uint i = index; i < readyRooms.length-1; i++){
            readyRooms[i] = readyRooms[i+1];
        }
        readyRooms.pop();
    }

    function resetContract(uint room_number) private {
        delete raffle_room[room_number].s_players;
        emit ContractReset(room_number,block.timestamp);
    }
    //E: Admin functions


    //B: Oracle
    // Assumes the subscription is funded sufficiently.
    function _requestRandomWords() internal {
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
        s_randomWords = randomWords;
        for(uint x = 0; x < readyRooms.length; x++){
            uint room = readyRooms[x];
            uint groupid = room + block.timestamp;
            for(uint i = 0; i < numWords; i++) {
                uint place_index = randomWords[i] % raffle_room[room].s_players.length;
                address winner = raffle_room[room].s_players[place_index];
                emit WinnerPicked(room,i, winner, raffle_room[room].prizes[i],groupid); 
                raffle_room[room].s_player_wallets[winner] = raffle_room[room].s_player_wallets[winner] + raffle_room[room].prizes[i];
                remove(room,place_index);
            }
            rakeCollection(room);
            resetContract(room);
            removeRoom(x);
            raffle_room[room].playingSlot = raffle_room[room].playingSlot - raffle_room[room].limit;
            //TODO:
            //call SWRTC minting here
            token_address.mint(raffle_room[room].burn_rate * 10);
        }
    }
    function rakeCollection(uint room_number) private{
        rakeRecord[room_number].l_rakeCollected = rakeRecord[room_number].l_rakeCollected + rakeRecord[room_number].l_rake;
        emit RakeTransfer(room_number,rakeRecord[room_number].l_rakeCollected,raffle_room[room_number].lessee);   
    }
    //E: Oracle

    
    //B: General Functions
    function gettimestamp() public view returns(uint){
        return block.timestamp;
    }

    function getPlayersByRoom(uint room_number,uint order) public view returns(address){
        return raffle_room[room_number].s_players[order];
    }

    function checkPlayerBalance(uint room_number, address player) public view returns(uint){
        return raffle_room[room_number].s_player_wallets[player];
    }
    //E: General Functions

    //B: Player functions

    function hostARaffle(uint newEntryfee, uint room_number, uint grandPrize,uint limit) public {
        require(msg.sender == raffle_room[room_number].lessee,"You do not own this raffle");
        
        require(limit >= 3, "Limit should be 3 or higher");
        require(limit <= 10, "Limit should not be greater than 10");
        require(prizeSelection[grandPrize] == true, "Invalid grand prize");

        raffle_room[room_number].active = true;
        raffle_room[room_number].entryfee = newEntryfee;
        raffle_room[room_number].limit = limit;
        raffle_room[room_number].pot = newEntryfee * limit;
        raffle_room[room_number].burn_rate = raffle_room[room_number].pot * 1 / 100; //1% of of the whole balance is burned... as there is no way to withdraw.
        raffle_room[room_number].lessee_updatedAt = block.timestamp;
        rakeRecord[room_number].l_rake = raffle_room[room_number].pot * 2 / 100;

        uint fullrake = raffle_room[room_number].burn_rate + rakeRecord[room_number].l_rake;

        if(grandPrize == 50){
            computePrizes(room_number,50,35,15,fullrake);
        }
        if(grandPrize == 75){
            computePrizes(room_number,75,15,10,fullrake);

        }
        if(grandPrize == 100){
            computePrizes(room_number,100,0,0,fullrake);
        }
        
        emit NewLease(room_number,msg.sender,newEntryfee,raffle_room[room_number].pot,limit,true,raffle_room[room_number].prizes[0],0);
        resetContract(room_number);
    }

    function computePrizes(uint room_number, uint grand, uint first, uint second, uint fullrake) private{
        raffle_room[room_number].prizes[0] =  raffle_room[room_number].pot * grand / 100;
        raffle_room[room_number].prizes[1] =  raffle_room[room_number].pot * first / 100;
        raffle_room[room_number].prizes[2] =  raffle_room[room_number].pot * second / 100;
        raffle_room[room_number].prizes[0] = raffle_room[room_number].prizes[0] - fullrake;
    }

    function getPrizeByRoom(uint room_number, uint order) public view returns(uint){
        return raffle_room[room_number].prizes[order];
    }   

    function getAllowance() public view returns(uint){
        return token_address.allowance(msg.sender,address(this));
    }

    //TODO: Remove on productions
    function _test_requestRW() private{
        s_randomWords = [1234687631,3247869663,789986534];
        for(uint x = 0; x < readyRooms.length; x++){
            uint room = readyRooms[x];
            uint groupid = room + block.timestamp;
            for(uint i = 0; i < numWords; i++) {
                uint place_index = s_randomWords[i] % raffle_room[room].s_players.length;
                address winner = raffle_room[room].s_players[place_index];
                emit WinnerPicked(room,i, winner, raffle_room[room].prizes[i],groupid); 
                raffle_room[room].s_player_wallets[winner] = raffle_room[room].s_player_wallets[winner] + raffle_room[room].prizes[i];
                remove(room,place_index);
            }
            rakeCollection(room);
            resetContract(room);
            removeRoom(x);
            token_address.mint(raffle_room[room].burn_rate * 10);
            raffle_room[room].playingSlot = raffle_room[room].playingSlot - raffle_room[room].limit;

        }
    }

    function loadSlots(uint room_number,uint amount) public{
        require(msg.sender == raffle_room[room_number].lessee,"This account is not allowed to update this room.");
        require(amount > 0,"Please enter a valid amount");
        uint256 allowance = lease_address.allowance(msg.sender,address(this));
        require(allowance >= amount, "You don't have enough allowance to host.");
        lease_address.transferFrom(msg.sender, address(this), amount);
        raffle_room[room_number].playingSlot = raffle_room[room_number].playingSlot + amount;
    }

    function sellRaffleRoom(uint room_number, uint price) public{
        require(msg.sender == raffle_room[room_number].lessee,"This account is not allowed to update this room.");
        raffle_room[room_number].price = price;
        raffle_room[room_number].forSale = true;
        raffle_room[room_number].active = false;
    }

    function voidRoomSelling(uint room_number) public{
        require(msg.sender == raffle_room[room_number].lessee,"This account is not allowed to update this room.");
        raffle_room[room_number].forSale = false;
        raffle_room[room_number].active = true;
    }

    function buyRaffleRoom(uint room_number, uint price) public{
        require(raffle_room[room_number].forSale = true,"This room is not for sale");
        uint256 allowance = lease_address.allowance(msg.sender,address(this));
        require(allowance >= raffle_room[room_number].price, "You don't have enough allowance to host.");
        require(price >= raffle_room[room_number].price, "Please enter enough amount");
        lease_address.transferFrom(msg.sender, raffle_room[room_number].lessee, raffle_room[room_number].price);
        raffle_room[room_number].lessee = msg.sender;
        raffle_room[room_number].forSale = false;
        emit BurnedToken(room_number,price,block.timestamp);
    }

    


    function withdrawRakeLessee(uint amount, uint room_number) public nonReentrant{
        require(msg.sender == raffle_room[room_number].lessee,"This account is not allowed to withdraw");
        balance = balance - amount;
        token_address.transfer(msg.sender, amount);
        rakeRecord[room_number].l_rakeCollected = rakeRecord[room_number].l_rakeCollected - amount;
    }

    function playerCollect(uint room_number) public nonReentrant{
        require(raffle_room[room_number].s_player_wallets[msg.sender] > 0,"This account is not allowed to withdraw.");
        balance = balance - raffle_room[room_number].s_player_wallets[msg.sender];
        token_address.transfer(msg.sender, raffle_room[room_number].s_player_wallets[msg.sender]);
        raffle_room[room_number].s_player_wallets[msg.sender] = 0;
    }

    function playerWithdraw(uint room_number) public nonReentrant{
        //TODO: apply reentrancy guard here
        for (uint i = 0; i <= raffle_room[room_number].s_players.length; i++) {
           if(raffle_room[room_number].s_players[i] == msg.sender){
                balance = balance - raffle_room[room_number].entryfee;
                token_address.transfer(msg.sender, raffle_room[room_number].entryfee);
                remove(room_number,i);
                emit PlayerWithdraw(room_number,msg.sender,raffle_room[room_number].s_players.length);
                return;
           }
        }
    }



    //E: Lessee Functions

}