// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Chainlink VRF
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

interface IWofToken {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external;

    function allowance(address owner, address spender)
        external
        returns (uint256);
}

contract WofRacingContract is VRFConsumerBaseV2, KeeperCompatibleInterface {
    //CHAINLINK VRF
    VRFCoordinatorV2Interface COORDINATOR;
    address vrfCoordinator = 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed;
    //MAINNET - 0xAE975071Be8F8eE67addBC1A82488F1C24858067

    bytes32 keyHash =
        0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;
    //MAINNET - 0xcc294a196eeeb44da2888d17c0625cc88d70d9760a69d58d853ba6581a9ab0cd

    uint64 s_subscriptionId;
    uint256[] public s_randomWords;
    uint256 public s_requestId;
    uint16 requestConfirmations = 3;
    uint32 callbackGasLimit = 100000;

    //CHAINLINK KEEPERS
    uint256 public interval;
    uint256 public lastTimeStamp;

    //CONTRACT VARIABLES
    address public owner;
    address public garageContract;
    uint256 public MAX_PARTICIPANTS = 12;

    //INTERFACES
    IWofToken public wofToken;

    //EVENTS
    event JoinRace(
        uint256 raceID,
        address racer,
        uint256 token_id,
        uint256 seed,
        uint256 punkID
    );
    
    event SeedsGenerated(uint256 raceID);

    event PayOut(address racer, uint256 amount);

    constructor(
        uint64 subscriptionId,
        uint256 updateInterval,
        address _wofTokenAddress,
        address _garageContract
    ) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        owner = msg.sender;
        s_subscriptionId = subscriptionId;
        interval = updateInterval;
        lastTimeStamp = block.timestamp;
        wofToken = IWofToken(_wofTokenAddress);
        garageContract = _garageContract;
    }

    //DATA STRUCTURES
    /* ----- VRF MAP ----- */
    mapping(uint256 => uint256) public vrf_requests;

    /* ----- RACE STRUCT ----- */
    mapping(uint256 => Race) public races;
    struct Race {
        uint256 prizePool;
        uint256 entranceFee;
        mapping(uint256 => Participant) participants;
        bool finished;
        uint256 participant_count;
        uint256[] seeds;
    }
    struct Participant {
        address user;
        uint256 punkID;
        uint256 entranceFee;
        uint256 seed;
        uint256 place;
    }

    /* ----- FREE RACE CLAIMS ----- */
    address[] public unclaimedAddresses;
    mapping(address => uint256) public claimableRewards;

    /* ----- TOKEN STATS ----- */
    struct TokenStats {
        uint256 racesJoined;
        uint256 firstPlaces;
        uint256 secondPlaces;
        uint256 thirdPlaces;
        uint256 tokensWon;
    }
    mapping(uint256 => TokenStats) public tokenStats;
    mapping(uint256 => bool) public tokenInrace;

    /* ----- FREIGHT PUNK STATS STATS ----- */
    mapping(uint256 => TokenStats) public freightPunkStats;
    mapping(uint256 => bool) public punkInRace;

    /* ----- CONTESTANT STRUCT ----- */
    struct Contestants {
        address racer;
        uint256 tokenID;
        uint256 punkID;
        uint256 place;
    }

    /* ----- KEEPERS AND VRF FNC ----- */
    function checkUpkeep(bytes calldata)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory)
    {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
    }

    //PAY OUT THE REWARDS
    function performUpkeep(bytes calldata) external override {
        if ((block.timestamp - lastTimeStamp) > interval) {
            lastTimeStamp = block.timestamp;
            payOut();
        }
    }

    function requestRandomWords(uint32 numWords, uint256 raceID) internal {
        uint256 requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        vrf_requests[requestId] = raceID;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        uint256 raceID = vrf_requests[requestId];
        races[raceID].seeds = randomWords;
        emit SeedsGenerated(raceID);
    }

    /* ----- RACE FNC ----- */
    function addRace(
        uint256 _raceID,
        uint256 _entranceFee,
        uint256 _prizePool
    ) public {
        races[_raceID].entranceFee = _entranceFee;
        races[_raceID].finished = false;
        if (_entranceFee == 0) {
            races[_raceID].prizePool = _prizePool;
        }
        requestRandomWords(12, _raceID);
    }

    function joinRace(
        uint256 _raceID,
        address _user,
        uint256 _tokenID,
        uint256 _entranceFee,
        uint256 _punkID
    ) public {
        uint256 raceParticipants = races[_raceID].participant_count;

        require(tokenInrace[_tokenID] != true, "Token already racing");
        require(
            wofToken.allowance(_user, address(this)) > _entranceFee,
            "Entrance Fee exceeds allowance"
        );
        require(
            _entranceFee >= races[_raceID].entranceFee,
            "Entrance fee higher than sent"
        );

        require(
            raceParticipants <= MAX_PARTICIPANTS,
            "Max number of racers already registered"
        );
        require(races[_raceID].seeds.length > 0, "Seeds not yet generated");
        //GET SEED
        uint256 seed = races[_raceID].seeds[raceParticipants];
        //APPEND TOKEN STATS
        tokenInrace[_tokenID] == true;
        tokenStats[_tokenID].racesJoined = tokenStats[_tokenID].racesJoined + 1;

        //APPEND PUNK STATS
        if (_punkID > 0) {
            punkInRace[_tokenID] == true;
            freightPunkStats[_tokenID].racesJoined =
                freightPunkStats[_tokenID].racesJoined +
                1;
        }
        //JOIN THE RACE
        races[_raceID].participants[_tokenID] = Participant({
            user: _user,
            punkID: _punkID,
            entranceFee: _entranceFee,
            seed: seed,
            place: 0
        });
        //TRANSFER TOKENS TO CONTRACT
        wofToken.transferFrom(_user, address(this), _entranceFee);

        //APPEND RACERS COUNT
        races[_raceID].participant_count = raceParticipants + 1;
        //APPEND PRIZE POOL
        races[_raceID].prizePool = races[_raceID].prizePool + _entranceFee;
        emit JoinRace(_raceID, _user, _tokenID, seed, _punkID);
    }

    function uploadRaces(uint256 _raceID, Contestants[] memory _results)
        public
    {
        uint256 prizePool = races[_raceID].prizePool;

        for (uint256 i = 0; i < _results.length; i++) {
            uint256 reward = 0;
            if (isTokenInRace(_raceID, _results[i].tokenID) == true) {
                //UNJOIN TOKEN FROM THE RACE
                tokenInrace[_results[i].tokenID] = false;
                if (_results[i].punkID > 0) {
                    punkInRace[_results[i].punkID] = false;
                }

                //ASSIGN PLACES
                if (_results[i].place == 1) {
                    //APPEND STATS
                    tokenStats[_results[i].tokenID].firstPlaces =
                        tokenStats[_results[i].tokenID].firstPlaces +
                        1;

                    if (_results[i].punkID != 0) {
                        freightPunkStats[_results[i].punkID].firstPlaces =
                            tokenStats[_results[i].punkID].firstPlaces +
                            1;
                    }

                    reward = getRewardAmount(prizePool, _results[i].place);
                }
                if (_results[i].place == 2) {
                    //APPEND STATS

                    tokenStats[_results[i].tokenID].secondPlaces =
                        tokenStats[_results[i].tokenID].secondPlaces +
                        1;

                    if (_results[i].punkID != 0) {
                        freightPunkStats[_results[i].punkID].secondPlaces =
                            tokenStats[_results[i].punkID].secondPlaces +
                            1;
                    }

                    reward = getRewardAmount(prizePool, _results[i].place);
                }
                if (_results[i].place == 3) {
                    //APPEND STATS

                    tokenStats[_results[i].tokenID].thirdPlaces =
                        tokenStats[_results[i].tokenID].thirdPlaces +
                        1;

                    if (_results[i].punkID != 0) {
                        freightPunkStats[_results[i].punkID].thirdPlaces =
                            tokenStats[_results[i].punkID].thirdPlaces +
                            1;
                    }
                    reward = getRewardAmount(prizePool, _results[i].place);
                }
            }
            if (reward > 0) {
                // PAY OUT RACES WHERE ENTRANCE FEE IS NOT 0
                if (races[_raceID].entranceFee != 0) {
                    wofToken.transferFrom(
                        address(this),
                        _results[i].racer,
                        reward
                    );
                } else {
                    if (claimableRewards[_results[i].racer] == 0) {
                        unclaimedAddresses.push(_results[i].racer);
                    }
                    claimableRewards[_results[i].racer] =
                        claimableRewards[_results[i].racer] +
                        reward;
                }
            }
        }
    }

    /* ----- HELPER FNC ----- */

    function isTokenInRace(uint256 raceID, uint256 tokenID)
        public
        view
        returns (bool)
    {
        address racerAddress = races[raceID].participants[tokenID].user;
        if (racerAddress == address(0)) {
            return false;
        }
        return true;
    }

    function getParticipant(uint256 _raceID, uint256 tokenID)
        public
        view
        returns (Participant memory)
    {
        return races[_raceID].participants[tokenID];
    }

    function getRewardAmount(uint256 prizePool, uint256 place)
        internal
        pure
        returns (uint256)
    {
        if (place == 1) {
            return (prizePool * 60) / 100;
        }
        if (place == 2) {
            return (prizePool * 25) / 100;
        }
        if (place == 3) {
            return (prizePool * 15) / 100;
        }
        return 0;
    }

    function payOut() internal {
        if (unclaimedAddresses.length > 0) {
            for (uint256 i = 0; i < unclaimedAddresses.length; i++) {
                address userAddress = unclaimedAddresses[i];
                uint256 payout = claimableRewards[userAddress];
                if (payout > 0) {
                    claimableRewards[userAddress] = 0;
                    wofToken.transferFrom(garageContract, userAddress, payout);
                    emit PayOut(userAddress, payout);
                }
            }
            delete unclaimedAddresses;
        }
    }

    /* ----- MANAGEMENT FNC ----- */
    function setOwner(address _address) public {
        require(msg.sender == owner, "Not the owner");
        owner = _address;
    }

    function setTokenContract(address _address) public {
        require(msg.sender == owner, "Not the owner");
        wofToken = IWofToken(_address);
    }

    function setGarageContract(address _address) public {
        require(msg.sender == owner, "Not the owner");
        garageContract = _address;
    }

    //WIDTHRAW WOF TOKENS
    function withdraw(address _to, uint256 _amount) public {
        require(msg.sender == owner, "Not the owner");
        wofToken.transferFrom(address(this), _to, _amount);
    }

    //SET MAX PARTICIPANTS
    function setMaxParticipants(uint256 _amount) public {
        require(msg.sender == owner, "Not the owner");
        MAX_PARTICIPANTS = _amount;
    }

    //CHANGE KEEPERS INTERVAL
    function setInterval(uint256 updateInterval) public {
        require(msg.sender == owner, "Not the owner");
        interval = updateInterval;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
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

import "./KeeperBase.sol";
import "./interfaces/KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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