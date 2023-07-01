/**
 *Submitted for verification at polygonscan.com on 2023-06-30
*/

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

// File: contracts/LuckBall.sol


/**
 * @title LuckBall Event Contract
 * @author Atomrigs Lab
 *
 * Supports ChainLink VRF_V2
 * Using EIP712 signTypedData_v4 for relay signature verification
 **/

pragma solidity ^0.8.18;

//import "@openzeppelin/contracts/access/Ownable.sol";
//import "@openzeppelin/contracts/security/ReentrancyGuard.sol";



contract LuckyBall is VRFConsumerBaseV2{

    uint private _ballId;
    uint private _seasonId;
    uint private _revealGroupId;    
    address private _owner;
    address private _operator;

    uint[] public ballGroups;
    address[] public addrGroups;
    uint public ballCount;
    bool public revealNeeded;
    struct Season {
        uint seasonId;
        uint startBallId;
        uint endBallId;
        uint winningBallId;
        uint winningCode;
    }

    //chainlink 
    VRFCoordinatorV2Interface immutable COORDINATOR;
    uint64 immutable s_subscriptionId; //= 5320; //https://vrf.chain.link/
    //address immutable vrfCoordinator; //= 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed; //Mumbai 
    bytes32 immutable s_keyHash; // = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;
    uint32 constant callbackGasLimit = 400000;
    uint16 constant requestConfirmations = 3;
    uint32 constant numWords =  1;
    uint256 public lastRequestId;

    struct RequestStatus {
        bool exists; // whether a requestId exists        
        bool isSeasonPick; //True if this random is for picking up the season BallId winner 
        uint seed;
    }
    mapping(uint => RequestStatus) public s_requests; /* requestId --> requestStatus */   
    //

    //EIP 712 related
    bytes32 public DOMAIN_SEPARATOR;
    mapping (address => uint) private _nonces;
    //

    mapping(uint => Season) public seasons;
    mapping(address => mapping(uint => uint[])) public userBallGroups; //user addr => seasonId => ballGroupPos
    mapping(uint => uint) public revealGroups; //ballId => revealGroupId
    mapping(uint => uint) public revealGroupSeeds; // revealGroupId => revealSeed 
    mapping(address => uint) public newRevealPos;
    mapping(address => mapping(uint => uint)) public userBallCounts; //userAddr => seasonId => count
    mapping(uint => uint[]) public ballPosByRevealGroup; // revealGroupId => [ballPos]

    event BallIssued(uint seasonId, address indexed recipient, uint qty, uint lastBallId);
    event RevealRequested(uint seasonId, uint revealGroupId, address indexed requestor);
    event SeasonStarted(uint seasonId);
    event SeasonEnded(uint seasonId);
    event CodeSeedRevealed(uint seasonId, uint revealGroupId);
    event WinnerPicked(uint indexed seasonId, uint ballId);

    modifier onlyOperators() {
        require(_operator == msg.sender || _owner == msg.sender, "LuckyBall: caller is not the operator address!");
        _;
    } 
    modifier onlyOwner() {
        require(_owner == msg.sender, "LuckyBall: caller is not the owner address!");
        _;
    }       

    constructor(
        uint64 subscriptionId,
        address vrfCoordinator,
        bytes32 keyHash
    ) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_keyHash = keyHash;
        s_subscriptionId = subscriptionId;
        _revealGroupId++;
        _owner = msg.sender;
        _operator = msg.sender;
        _setDomainSeparator(); //EIP712
    }

    // EIP 712 and Relay functions
    function nonces(address user) public view returns (uint256) {
        return _nonces[user];
    }   

    function getDomainInfo() public view returns (string memory, string memory, uint, address) {
        string memory name = "LuckyBall_Relay";
        string memory version = "1";
        uint chainId = block.chainid;
        address verifyingContract = address(this);
        return (name, version, chainId, verifyingContract);
    }

    function getRelayMessageTypes() public pure returns (string memory) {
      string memory dataTypes = "Relay(address owner,uint256 deadline,uint256 nonce)";
      return dataTypes;      
    }

    function _setDomainSeparator() internal {
        string memory EIP712_DOMAIN_TYPE = "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)";
        ( string memory name, string memory version, uint chainId, address verifyingContract ) = getDomainInfo();
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(abi.encodePacked(EIP712_DOMAIN_TYPE)),
                keccak256(abi.encodePacked(name)),
                keccak256(abi.encodePacked(version)),
                chainId,
                verifyingContract
            )
        );
    }

    function getEIP712Hash(address _user, uint _deadline, uint _nonce) public view returns (bytes32) {
        string memory MESSAGE_TYPE = getRelayMessageTypes();
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19\x01", // backslash is needed to escape the character
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        keccak256(abi.encodePacked(MESSAGE_TYPE)),
                        _user,
                        _deadline,
                        _nonce
                    )
                )
            )
        );
        return hash;
    }

    function verifySig(address _user, uint _deadline, uint _nonce,  uint8 v, bytes32 r,bytes32 s) public view returns (bool) {
        bytes32 hash = getEIP712Hash(_user, _deadline, _nonce);
        if (v < 27) {
          v += 27;
        }
        return _user == ecrecover(hash, v, r, s);
    }

    //

    function setOperator(address _newOperator) public onlyOwner returns (bool) {
        _operator = _newOperator;
        return true;
    }

    function getOperator() public view returns (address) {
        return _operator;
    }

    function getCurrentSeasionId() public view returns (uint) {
        return _seasonId;
    }

    function getCurrentBallGroupPos() public view returns (uint) {
        return ballGroups.length;
    }

    function getCurrentRevealGroupId() public view returns (uint) {
        return _revealGroupId;
    }     

    function startSeason() external onlyOperators() returns (uint) {
        _seasonId++;
        uint start;
        if (ballGroups.length == 0) {
            start = 1;    
        } else {
            start = ballGroups[getCurrentBallGroupPos()-1]+1;
        }    

        seasons[_seasonId] = 
                Season(_seasonId, 
                        start, 
                        uint(0), 
                        uint(0),
                        generateWinningCode());

        emit SeasonStarted(_seasonId);
        return _seasonId;
    }

    function isSeasonActive() public view returns (bool) {
        if(seasons[_seasonId].winningBallId > 0) {
            return false;
        }
        if (_seasonId == uint(0)) {
            return false;
        }
        return true;
    }    

    function issueBalls(address[] calldata _tos, uint[] calldata _qty) external onlyOperators() returns (bool) {
        require(_tos.length == _qty.length, "LuckBall: address and qty counts do not match");
        require(isSeasonActive(), "LuckyBall: Season is not active");
        for(uint i=0; i<_tos.length; i++) {
            require(_qty[i] > 0, "LuckyBall: qty should be bigger than 0");
            ballCount += _qty[i];
            ballGroups.push(ballCount);
            addrGroups.push(_tos[i]);
            userBallGroups[_tos[i]][_seasonId].push(ballGroups.length-1);
            userBallCounts[_tos[i]][_seasonId] += _qty[i];
            emit BallIssued(_seasonId, _tos[i], _qty[i], ballCount);
        } 
        return true;       
    }

    function getUserBallGroups(address addr, uint seasonId) public view returns (uint[] memory) {
        uint[] memory myGroups = userBallGroups[addr][seasonId];
        return myGroups;
    }

/*
    function issueTest() public onlyOperators() {
        address a = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        ballCount += 100;
        ballGroups.push(ballCount);
        addrGroups.push(a);
        userBallGroups[a][getCurrentSeasionId()].push(ballGroups.length-1);
        userBallCounts[a][getCurrentSeasionId()] += 100;
        emit BallIssued(a, 100);
    }
*/

    function ownerOf(uint ballId) public view returns (address) {
        if (ballId == 0) {
            return address(0);
        }
        for(uint i=0; i < ballGroups.length; i++) {
            if(ballId <= ballGroups[i]) {
                return addrGroups[i];
            }
        }
        return address(0);
    }         

    function generateWinningCode() internal view returns (uint) {
        return extractCode(uint(keccak256(abi.encodePacked(blockhash(block.number -1), block.timestamp))));        
    }
    /*
    function setWinningBallId(uint winner) public onlyOperators() returns (bool) {
        seasons[getCurrentSeasionId()].winningBallId = winner;
        return true;
    }
    */

    function extractCode(uint n) internal pure returns (uint) {
        uint r = n % 1000000;
        if (r < 100000) { r += 100000; }
        return r;
    } 

    function requestReveal() external returns (bool) {
        return _requestReveal(msg.sender);
    }

    function _requestReveal(address _addr) internal returns (bool) {
        uint[] memory myGroups = userBallGroups[_addr][_seasonId];
        uint revealGroupId = _revealGroupId;
        uint newPos = newRevealPos[_addr];
        require(myGroups.length > 0, "LuckyBall: No balls to reveal");
        require(myGroups.length >= newPos, "LuckyBall: No new balls to reveal");
        for (uint i=newPos; i<myGroups.length; i++) {
            revealGroups[myGroups[i]] = revealGroupId;
            ballPosByRevealGroup[revealGroupId].push(myGroups[i]);
        }            
        newRevealPos[_addr] = myGroups.length;

        if (!revealNeeded) {
            revealNeeded = true;
        }
        emit RevealRequested(_seasonId, _revealGroupId, _addr);
        return false;
    }

    function getRevealGroup(uint ballId) public view returns (uint) {
        return revealGroups[getBallGroupPos(ballId)];
    }

    function getBallGroupPos(uint ballId) public view returns (uint) {
        require (ballId > 0 && ballId <= ballCount, "LuckyBall: ballId is out of range");
        require (ballGroups.length > 0, "LuckBall: No ball issued");
    
        for (uint i=ballGroups.length-1; i >= 0; i--) {
            uint start;
            if (i == 0) {
                start = 1;
            } else {
                start = ballGroups[i-1]+1;
            }
            uint end = ballGroups[i];

            if (ballId <= end && ballId >= start) {
                return i;
            }
            continue;
        }
        revert("BallId is not found");
    } 

    function getBallCode(uint ballId) public view returns (uint) {
        uint randSeed = revealGroupSeeds[getRevealGroup(ballId)];
        if (randSeed > uint(0)) {
            return extractCode(uint(keccak256(abi.encodePacked(randSeed, ballId))));
        }
        return uint(0);
    }

    function getBalls(address addr, uint seasonId) public view returns (uint[] memory) {
        uint[] memory myGroups = userBallGroups[addr][seasonId];
        uint[] memory ballIds = new uint[](userBallCounts[addr][seasonId]);

        uint pos = 0;
        for (uint i=0; i < myGroups.length; i++) {
            uint end = ballGroups[myGroups[i]];
            uint start;
            if (myGroups[i] == 0) {
                start = 1;    
            } else {
                start = ballGroups[myGroups[i] - 1] + 1;
            }
            for (uint j=start; j<=end; j++) {
                ballIds[pos] = j;
                pos++;
            }                           
        }
        return ballIds;
    }

    function getBalls() public view returns(uint[] memory) {
        return getBalls(msg.sender, _seasonId);
    }

    function getBallsByRevealGroup(uint revealGroupId) public view returns (uint[] memory) {
        uint[] memory ballPos = ballPosByRevealGroup[revealGroupId];
        uint groupBallCount;
        for (uint i=0; i < ballPos.length; i++) {
            uint start;
            uint end = ballGroups[ballPos[i]];
            if (ballPos[i] == 0) {
                start = 1;
            } else {
                start = ballGroups[ballPos[i] - 1] + 1;
            }
            groupBallCount += (end - start + 1);
        }
        uint[] memory ballIds = new uint[](groupBallCount);
        uint pos = 0;
        for (uint i=0; i < ballPos.length; i++) {
            uint end = ballGroups[ballPos[i]];            
            uint start;
            if (ballPos[i] == 0) {
                start = 1;
            } else {
                start = ballGroups[ballPos[i] - 1] + 1;
            }
            for (uint j=start; j <= end; j++) {
                ballIds[pos] = j;
                pos++;
            }
        }
        return ballIds;
    }

    function relayRequestReveal(        
        address user,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s) 
        public returns (bool) {

        require(deadline >= block.timestamp, "LuckyBall: expired deadline");
        require(verifySig(user, deadline, _nonces[user], v, r, s), "LuckyBall: user sig does not match");
        
        _requestReveal(user);
        _nonces[user]++;
        return true;
    }

    function relayRequestRevealBatch(
        address[] calldata users,
        uint[] calldata deadlines,
        uint8[] calldata vs,
        bytes32[] calldata rs,
        bytes32[] calldata ss) 
        public returns(bool) {
        
        for(uint i=0; i<users.length; i++) {
            relayRequestReveal(users[i],deadlines[i], vs[i], rs[i], ss[i]);
        }
        return true;
    }

    function endSeason() external onlyOperators() returns (bool) {
        if (ballGroups.length == 0) {
            return false;
        }
        if (revealNeeded) {
            requestRevealGroupSeed();
        }
        uint endBallId = ballGroups[ballGroups.length-1];
        if (endBallId == seasons[_seasonId].endBallId ) {
            return false;
        }
        seasons[_seasonId].endBallId = endBallId;
        requestRandomSeed(true); 
        return true;
    }

    function requestRevealGroupSeed() public onlyOperators() returns (uint) {
        if (revealNeeded) {
            return requestRandomSeed(false);
        } else {
            return 0;      
        }
    }

    function setRevealGroupSeed(uint randSeed) internal {
        revealGroupSeeds[_revealGroupId] = randSeed;
        emit CodeSeedRevealed(_seasonId, _revealGroupId);
        revealNeeded = false;        
        _revealGroupId++;
    }

    function requestRandomSeed(bool _isSeasonPick) internal returns (uint) {
        uint requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        lastRequestId = requestId;
        s_requests[requestId] = RequestStatus(true, _isSeasonPick, 0);
        return requestId;    
    }

    function setSeasonWinner(uint randSeed) internal {
        Season storage season = seasons[_seasonId];
        uint seasonBallCount = season.endBallId - season.startBallId + 1;
        season.winningBallId = season.startBallId + (randSeed % seasonBallCount);
        emit WinnerPicked(_seasonId, season.winningBallId); 
        emit SeasonEnded(_seasonId);
    }    

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        uint seed =  uint(keccak256(abi.encodePacked(randomWords[0], block.timestamp)));
        s_requests[requestId].seed = seed;
        if (s_requests[requestId].isSeasonPick) {
            setSeasonWinner(seed);
        } else {
            setRevealGroupSeed(seed);
        }
    }
}