/**
 *Submitted for verification at polygonscan.com on 2023-02-14
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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: contracts/ITournamentController.sol


pragma solidity ^0.8.0;

interface ITournamentController {

    event TeamCreated();
    event TournamentCreated();
    event TournamentStarted();

    function createTournament(Tournament memory _t) external payable;
    function setDistribution(uint [] memory _dist,uint id) external;
    function createTeam(Team memory _team) external;
    function register(uint _tournamentId,uint _teamId) external;
    // function getParticipants(uint _tid) external view returns(uint[] memory);
    // function getRound(uint _tid) external view returns(uint16);
    // function getTournamentDetails(uint _tid) external view returns(Tournament memory);
    // function getTeamDetails(uint _id) external view returns (Team memory);
    function participants(uint _tid) external returns(uint[] memory);
    function distributions(uint _tid) external returns(uint[] memory);
    function tournaments(uint _tid) external returns (Tournament memory);
    function teams(uint _id) external returns (Team memory);

    struct Team {
        string name;
        address[] members;
        address leader;
    }

    struct Organizer{
        string name;
        address Add_org;
    }
    struct RewardToken{
        address tokenAddress;
        string chain;
    }
    struct Prizes{
        uint participantPool;
        uint viewerPool;
        uint organizerFee;
        uint totalPool;
    }

    struct Tournament{
        uint16 round;
        uint16 sizeLimit;
        uint32 maxParticipants;
        bytes32 bracketType;
        uint state;
        Organizer org;
        RewardToken token;
        Prizes prize;
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

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// File: contracts/MatchMaker2.0.sol


pragma solidity ^0.8.0;







contract MatchMakerSE is VRFConsumerBaseV2, Ownable {
    // vrf settings
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);
    event MatchMade(uint MatchId,uint team1,uint team2,uint tournamentId,uint rountId);
    event BracketUpdated(uint MatchId, uint WinnerId, uint TournamentId,uint roundId);
    event RoundStarted(uint roundId,uint TournamentId);
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 s_subscriptionId;
    bytes32 keyHash =
        0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;
    uint32 callbackGasLimit = 2000000;
    uint16 requestConfirmations = 3;
    uint32 numWords=2;



    function setNumWords(uint32 _number) public onlyOwner{
        require(_number!=0,"MatchMakerSE: Can not have 0 random numbers!");
        numWords=_number;
    }

    function setRequestConfirmations(uint16 _reqConf) public onlyOwner{
        require(_reqConf !=0,"MatchMakerSE: Can't have 0 request confirmations");
        requestConfirmations=_reqConf;
    }

    function setCallBackGasLimit(uint32 _gas) public onlyOwner{
        require(_gas!=0);
        callbackGasLimit=_gas;
    }

    function setSubscriptionId(uint64 _subID) public onlyOwner{
        require(_subID!=0);
        s_subscriptionId=_subID;
    }


    // addresses
    address public TournamentControllerAddress;
    using Counters for Counters.Counter;
    Counters.Counter mid;

    // instance of Tournament controller
    ITournamentController tournamentController;

    function changeTournamentController(address _tournamentControllerAddress) public onlyOwner {
        require(_tournamentControllerAddress != address(0));
        TournamentControllerAddress=_tournamentControllerAddress;
        tournamentController=ITournamentController(TournamentControllerAddress);
    }

    constructor(
        address _tournmentControllerAddress,
        uint64 _subId
    ) VRFConsumerBaseV2(0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed) {
        TournamentControllerAddress = _tournmentControllerAddress;
        tournamentController = ITournamentController(
            TournamentControllerAddress
        );
        s_subscriptionId = _subId;
        COORDINATOR = VRFCoordinatorV2Interface(
            0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed
        );
    }

    //structs
    struct Match {
        uint id;
        // uint[2] teams;
        uint winner;
        uint tournamentId;
        uint roundId;
    }

    struct Request {
        uint requestId;
        uint tId;
    }

    // mappings
    mapping(uint => Request) internal Requests;
    // tournament wise round wise winners array
    mapping(uint => mapping(uint => uint[])) public winners;

    // tournament wise round wise playing teams
    mapping(uint => mapping(uint => uint[])) public players;

    // tournament wise round wise matches
    //this one is probably not needed!
    // mapping(uint => mapping(uint => Match[])) internal rMatches;
    mapping(uint256 => uint256[]) public getMatchTeams;

    // tournament wise bye teams
    mapping(uint => uint[]) internal byeTeams;

    // tournament wise normal teams
    mapping(uint => uint[]) internal normalTeams;

    //id wise matches
    mapping(uint => Match) public matches;

    function findIfBye(
        uint _tid,
        uint _participant
    ) internal view returns (bool) {
        bool flag = false;
        for (uint i = 0; i < byeTeams[_tid].length; i++) {
            if (byeTeams[_tid][i] == _participant) {
                flag = true;
            }
        }
        return flag;
    }
    function isMatchMade(uint[] memory matched,uint _participant) internal pure returns(bool){
        bool flag=false;
        for(uint i=0;i<matched.length;i++){
            if(matched[i]==_participant){
                flag=true;
            }
        }
        return flag;
    }


    function makeMatches(uint _round, uint _tid) public onlyOwner{
        if (_round == 1) {
            setByes(_tid);
            setNormal(_tid);
            makeMatchesR1(_tid);
        } else if(_round==2) {makeMatchesR2(_tid);}
        else{
            matchMakerRest(_tid,_round);
        }
    }

    function matchMakerRest(uint _tid,uint  _round) internal {
        uint[] memory contenders=winners[_tid][_round-1];
        require(contenders.length==players[_tid][_round].length/2,"MatchMaker: You must complete the previous round first!");
        for(uint i=0;i<contenders.length;i=i+2){
            Match memory nMatch;
            mid.increment();
            nMatch.id=mid.current();
            nMatch.roundId=_round;
            // nMatch.teams[0]=contenders[i];
            // nMatch.teams[1]=contenders[i+1];
            getMatchTeams[mid.current()].push(contenders[i]);
            getMatchTeams[mid.current()].push(contenders[i+1]);
            matches[mid.current()]=nMatch;
            players[_tid][_round].push(contenders[i]);
            players[_tid][_round].push(contenders[i+1]);
            emit MatchMade(mid.current(),contenders[i],contenders[i+1],_tid,_round);
        }
    }

    function setByes(uint _tid) internal {
        uint[] memory participants = tournamentController.participants(_tid);
        uint n = participants.length;
        uint power;
        uint no_bye;
        while (n > 2 ** power) {
            power++;
        }
        no_bye = (2 ** power) - n;
        uint midInd;
        if (n % 2 == 0) {
            midInd = n / 2;
        } else {
            midInd = (n + 1) / 2;
        }
        uint[4] memory ptrs = [n - 1, 0, midInd, midInd - 1];
        uint j = 0;
        while (no_bye > 0) {
            byeTeams[_tid].push(participants[ptrs[j]]);
            if (j == 0 || j == 3) {
                ptrs[j]--;
            } else {
                ptrs[j]++;
            }
            j = (j + 1) % 4;
            no_bye--;
        }
    }

    function setNormal(uint _tid) internal {
        uint[] memory participants = tournamentController.participants(_tid);
        for (uint i = 0; i < participants.length; i++) {
            if (!findIfBye(_tid, participants[i])) {
                normalTeams[_tid].push(participants[i]);
                players[_tid][1].push(participants[i]);
            }
        }
    }

    function makeMatchesR1(uint _tid) internal {
        uint _requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        Request memory newRequest;
        newRequest.requestId = _requestId;
        newRequest.tId = _tid;
        Requests[_requestId] = newRequest;
        emit RequestSent(_requestId, numWords);
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        uint256 _tid = Requests[_requestId].tId;
        uint256[] memory _normalTeams = normalTeams[_tid];
        uint256[] memory matched= new uint[](_normalTeams.length);
        uint matchedCount;
        // uint offset=_randomWords[0]%_normalTeams.length;
        uint256 no_left = _normalTeams.length;
        uint8 last_ri = 0;
        uint256 offset = _randomWords[last_ri] % no_left;
        if (offset == 0) {
            offset++;
        }
        for (uint256 i = 0; i < _normalTeams.length; i++) {
            if(no_left==0){
                break;
            }
            if(no_left==1){
                if(isMatchMade(matched, _normalTeams[i])){
                    continue;
                }
                else{
                    break;
                }
            }
            if (i + offset >= _normalTeams.length) {
                last_ri = (last_ri + 1) % 2;
                offset = _randomWords[last_ri] % no_left;
                if (offset == 0) {
                    offset++;
                }
            }
            if (isMatchMade(matched, _normalTeams[i + offset])) {
                last_ri = (last_ri + 1) % 2;
                offset = _randomWords[last_ri] % no_left;
                if (offset == 0) {
                    offset++;
                }
            }
            if (isMatchMade(matched, _normalTeams[i])) {
                uint256 j = 1;
                while (
                    isMatchMade(matched, _normalTeams[j]) &&
                    j < _normalTeams.length
                ) {
                    j++;
                }
                if (j == _normalTeams.length) {
                    break;
                } else {
                    i = j;
                    last_ri = (last_ri + 1) % 2;
                    offset = _normalTeams[last_ri] % no_left;
                    if (offset == 0) {
                        offset++;
                    }
                }
            }
            Match memory nMatch;
            mid.increment();
            nMatch.id = mid.current();
            // nMatch.teams[0] = _normalTeams[i];
            // nMatch.teams[1] = _normalTeams[i + offset];
            nMatch.tournamentId = _tid;
            nMatch.roundId = 1;
            matches[mid.current()] = nMatch;
            // matches[mid.current()].teams.push(_normalTeams[i]);
            // matches[mid.current()].teams.push(_normalTeams[i + offset]);
            getMatchTeams[mid.current()].push(_normalTeams[i]);
            getMatchTeams[mid.current()].push(_normalTeams[i+offset]);
            matched[matchedCount]=_normalTeams[i];
            matchedCount++;
            matched[matchedCount]=_normalTeams[i+offset];
            matchedCount++;
            // i think not needed

            // rMatches[_tid][mid.current()].push(nMatch);
            no_left = no_left - 2;
            emit MatchMade(mid.current(),_normalTeams[i],_normalTeams[i+offset],_tid,1);
        }
    }

    function makeMatchesR2(uint _tid) internal{
        uint[] memory _r1winners=winners[_tid][1];
        require(_r1winners.length==players[_tid][1].length/2,"MatchMakerSE: You have to finish Round 1 first!");
        uint[] memory _byeTeams=byeTeams[_tid];
        uint i=0;
        uint j=0;
        while(i<_r1winners.length && j<_byeTeams.length){
            Match memory nMatch;
            mid.increment();
            nMatch.id=mid.current();
            // nMatch.teams[0]=_r1winners[i];
            // nMatch.teams[1]=_byeTeams[j];
            getMatchTeams[mid.current()].push(_r1winners[i]);
            getMatchTeams[mid.current()].push(_byeTeams[j]);
            nMatch.tournamentId=_tid;
            nMatch.roundId=2;
            matches[mid.current()]=nMatch;
            i++;
            j++;
            players[_tid][2].push(_r1winners[i]);
            players[_tid][2].push(_byeTeams[j]);
            emit MatchMade(mid.current(),_r1winners[i],_byeTeams[j],_tid,2);
        }
        if(i==_r1winners.length && j<_byeTeams.length){
            while(j<_byeTeams.length){
                Match memory nMatch1;
                mid.increment();
                nMatch1.id=mid.current();
                // nMatch1.teams[0]=_byeTeams[j];
                // nMatch1.teams[1]=_byeTeams[j+1];
                getMatchTeams[mid.current()].push(_byeTeams[j]);
                getMatchTeams[mid.current()].push(_byeTeams[j+1]);
                nMatch1.tournamentId=_tid;
                nMatch1.roundId=2;
                j=j+2;
                matches[mid.current()]=nMatch1;
                players[_tid][2].push(_byeTeams[j]);
                players[_tid][2].push(_byeTeams[j+1]);
                emit MatchMade(mid.current(),_byeTeams[i],_byeTeams[j+1],_tid,2);
            }
        }
        else if (j==_byeTeams.length && i<_r1winners.length){
            while(i<_r1winners.length){
                Match memory nMatch2;
                mid.increment();
                nMatch2.id=mid.current();
                // nMatch2.teams[0]=_r1winners[i];
                // nMatch2.teams[1]=_r1winners[i+1];
                getMatchTeams[mid.current()].push(_r1winners[i]);
                getMatchTeams[mid.current()].push(_r1winners[i+1]);
                nMatch2.tournamentId=_tid;
                nMatch2.roundId=2;
                i=i+2;
                matches[mid.current()]=nMatch2;
                players[_tid][2].push(_r1winners[i]);
                players[_tid][2].push(_r1winners[i+1]);
                emit MatchMade(mid.current(),_r1winners[i],_r1winners[i+1],_tid,2);
            }
        }

    }

    function _updateWinner(uint _mid,uint _winnerId) public onlyOwner {
        require(_mid<=mid.current(),"MatchMakerSE: Wrong match id!");
        require(matches[_mid].winner==0,"MatchMakerSE: You can not modify the winner");
        // require(matches[_mid].ti)
        bool flag;
        for(uint i=0;i<2;i++){
            // if(matches[_mid].teams[i]==_winnerId){
            //     flag=true;
            // }
            if(getMatchTeams[_mid][i]==_winnerId){
                flag=true;
            }
        }
        if(!flag){
            revert("MatchMakerSE: Can only Pick a winner from participating teams!");
        }
        uint _tid=matches[_mid].tournamentId;
        uint _roundId=matches[_mid].roundId;
        matches[_mid].winner=_winnerId;
        winners[_tid][_roundId].push(_winnerId);
        //i think not needed

        // for(uint i=0;i<rMatches[_tid][_roundId].length;i++){
        //     if(rMatches[_tid][_roundId][i].id==_mid){
        //         rMatches[_tid][_roundId][i].winner=_winnerId;
        //     }
        // }
        emit BracketUpdated(_mid,_winnerId,_tid,_roundId);
    }

    

    function getTournamentRoundMatches(uint _tid,uint _rid) public view returns (Match[] memory){
        Match [] memory trmatches;
        uint count=0;
        for(uint i=0;i<mid.current();i++){
            if(matches[i].tournamentId == _tid && matches[i].roundId== _rid){
                trmatches[count]=matches[i];
                count++;
            }
        }
        return trmatches;
    }
}