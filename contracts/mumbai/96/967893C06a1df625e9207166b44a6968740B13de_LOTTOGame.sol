// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
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

pragma solidity ^0.8.11;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

contract LOTTOGame is VRFConsumerBaseV2, ConfirmedOwner {
    address payable public ownerAddress;
    address public authAddress;
    VRFCoordinatorV2Interface COORDINATOR;

    uint256 public gameStartTime;
    IERC20 BUSD;
    Lotto lottoContract;
    uint256 betId = 1;
    mapping(uint256 => uint256) public winnerCount;
    mapping(uint256 => uint256) public winningAmount;

    //Nft contract
    NftMintInterface NftMint;
    uint16 constant percentDivider = 10000;
    uint256 public availableTimeToClaim = 5 minutes;
    uint256 public availableTimeToClaimJackpot = 5 minutes;
     uint256 public gameSpan = 15 minutes;
    uint256 public lastActiveGameId = 1;
    uint256 public resultDeclaredGameId;
    
    uint64 public s_subscriptionId;
    uint256[] public requestIds;
    uint256[] public getRandomNumbers;
    bytes32 keyHash =
        0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;
    uint32 callbackGasLimit = 2500000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 6;
    uint32 maxNo = 20;

    uint256[6] public hitsAndRewards = [0, 0, 0, 1 ether, 10 ether, 500 ether];

    struct playerStruct {
        address userAddress;
        uint256 totalReward;
    }

    struct bet {
        uint256 betId;
        bool isClaim;
        uint256[6] betsNumber;
        uint256 totalMatchNumber;
        bool isJackpotAvailable;
        bool isJackpotClaimed;
    }

    struct GameResult {
        uint8 status;
        uint256[] randomWords;
        uint256 prizeMoney;
        uint256 time;
    }

    mapping(address => playerStruct) public player;
    mapping(uint256 => mapping(uint256 => bet)) public bets;
    mapping(uint256 => GameResult) public gameResult;
    mapping(uint256 => mapping(uint256 => bool)) public isPlayed;
    mapping(uint256 => uint256) public requestIdWithGameId;
    mapping(uint256 => uint256) public jackpotWinnerCount;
    mapping(uint256 => bool) public s_requests; /* requestId --> requestStatus */

    event ClaimDataEvent(uint256 nftId,uint256 gameId,uint256 betId,uint256 matchedNumber,uint256 reward,address walletAddress,bool isJackpotAvailable);
    event BetPlayEvent(uint256 betId,uint256 gameId,uint256 nftId,address walletAddress,bool isClaim,uint256[6] betsNumber,uint256 time);
    event GameResultEvent(uint256 gameId,uint256[] resultNumber,uint256 winPrice,uint256 timestamp);
    event EarningEvent(uint256 referralAmount,address walletAddress,address referral,uint8 status,uint256 time);
    event JackpotClaimed(address user,uint256 winPrice,uint256 gameId,uint256 nftId,uint256 betId,uint256 timestamp);

    constructor(
        address payable _ownerAddress,
        address _authAddress,
        address lottoAddress,
        uint256 _gameStartTime,
        uint64 subscriptionId
    )
        VRFConsumerBaseV2(0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed)
        ConfirmedOwner(msg.sender)
    {
        COORDINATOR = VRFCoordinatorV2Interface(
            0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed
        );
        s_subscriptionId = subscriptionId;

        BUSD = IERC20(0x1FAdc992EA93CcCEbE3F965e72DF9c7d0F4035c9);

        lottoContract = Lotto(lottoAddress);

        NftMint = NftMintInterface(0x33a5fA8E6B1D4CbcA6bA10978254d91704EB5821);
        ownerAddress = _ownerAddress;
        authAddress = _authAddress;
        gameStartTime = _gameStartTime;
    }

    function setLottoContract(address _lotto) external {
        require(ownerAddress==msg.sender,"Only owner");
        lottoContract = Lotto(_lotto);
    }

    function getCurrentGameId() public view returns (uint256) {
        return ((block.timestamp - gameStartTime)/gameSpan) + 1;
    }

    function play(uint256[6] memory selectNum, uint256 _nftId) public {
        declareResult();
        uint256 nftBuyDate = NftMint.getNftMintedDate(_nftId);

        require(
            block.timestamp < nftBuyDate + 5 minutes,
            "You can play upto one year after nft buy"
        );
        require(
            NftMint.ownerOf(_nftId) == msg.sender,
            "You are not owner of nft"
        );

        uint256 gameId = getCurrentGameId();
        
        require(
            isPlayed[gameId][_nftId] == false,
            "You can play once in 24 hrs"
        );
        isPlayed[gameId][_nftId] = true;
        //check duplicate numbers
        for (uint256 i = 0; i < 6; i++) {
            //if (1 <= x && x <= 100)
            require(
                selectNum[i] > 0 && selectNum[i] <= maxNo,
                "Selected number should be in range of 1 to 50"
            );

            for (uint256 j = i + 1; j < 6; j++) {
                require(selectNum[i] != selectNum[j], "Enter unique number");
            }
        }

        uint256 _betId = betId;
        betId++;
        bet memory _bet = bet({
            betId: _betId,
            isClaim: false,
            betsNumber: selectNum,
            totalMatchNumber: 0,
            isJackpotAvailable : false,
            isJackpotClaimed : false
        });

        bets[gameId][_nftId] = _bet;
        gameResult[gameId].status = 1;
        lastActiveGameId = gameId;
        emit BetPlayEvent(
            _betId,
            gameId,
            _nftId,
            msg.sender,
            false,
            selectNum,
            block.timestamp
        );
    }

    function settleBet(uint256 gameId,uint256 _nftId) public {
        require(bets[gameId][_nftId].betId > 0, "Invalid game");
        require(bets[gameId][_nftId].isClaim == false, "Already claimed");
        require(gameResult[gameId].status == 10,"Not declared ");
        require(gameResult[gameId].time+(availableTimeToClaim) > block.timestamp,"Claim time passed");
        uint256 counter = 0;
        uint256[6] memory userSelectedNumbers = bets[gameId][_nftId]
            .betsNumber;
        for (uint256 i = 0; i < gameResult[gameId].randomWords.length; i++) {
            for (uint256 j = 0; j < userSelectedNumbers.length; j++) {
                if (gameResult[gameId].randomWords[i] == userSelectedNumbers[j]) {
                    counter++;
                }
            }
        }
        
        bets[gameId][_nftId].totalMatchNumber = counter;

        winnerCount[counter]++;

        bets[gameId][_nftId].isClaim = true;
        if(counter<6){
            if(hitsAndRewards[counter]>0){
                player[msg.sender].totalReward += hitsAndRewards[counter];
                winningAmount[counter] += hitsAndRewards[counter];
                BUSD.transfer(msg.sender, hitsAndRewards[counter]);
                emit EarningEvent(hitsAndRewards[counter], msg.sender, address(0),8, block.timestamp);

                address ref = lottoContract.getUpline(msg.sender);
                if(ref!=address(0)){
                    uint256 refAmount = hitsAndRewards[counter]*20/100;
                    player[ref].totalReward += refAmount;
                    BUSD.transfer(ref, refAmount);
                    emit EarningEvent(refAmount, ref, msg.sender,9, block.timestamp);
                }
            }

            emit ClaimDataEvent(
                _nftId,
                gameId,
                bets[gameId][_nftId].betId,
                counter,
                hitsAndRewards[counter],
                msg.sender,
                false
            );
        }
        else{

            bets[gameId][_nftId].isJackpotAvailable = true;
            jackpotWinnerCount[gameId]++;
            emit ClaimDataEvent(_nftId,
                gameId,
                bets[gameId][_nftId].betId,
                counter,
                0,
                msg.sender,
                true
            );
        }
    }

    function claimJackpot(uint256 gameId,uint256 _nftId) external
    {
        require(gameResult[gameId].prizeMoney>0,"No prize money");
        require(bets[gameId][_nftId].isJackpotAvailable,"No reward available");
        require(block.timestamp >= gameResult[gameId].time+(availableTimeToClaim),"Not started yet...");
        require(gameResult[gameId].time+(availableTimeToClaim)+availableTimeToClaimJackpot > block.timestamp,"Claim time passed");
        uint256 amount = (gameResult[gameId].prizeMoney*70/100)/jackpotWinnerCount[gameId];
        BUSD.transfer(msg.sender, amount);
        winningAmount[6] += amount;
        emit EarningEvent(amount, msg.sender, address(0),8, block.timestamp);
        emit JackpotClaimed(msg.sender,amount,gameId,_nftId,bets[gameId][_nftId].betId,block.timestamp);
        address ref = lottoContract.getUpline(msg.sender);
        if(ref!=address(0)){
            uint256 refamount = (gameResult[gameId].prizeMoney*20/100)/jackpotWinnerCount[gameId];
            player[ref].totalReward += refamount;
            BUSD.transfer(ref, refamount);
            emit EarningEvent(refamount, ref, msg.sender,9, block.timestamp);
        }
        bets[gameId][_nftId].isJackpotAvailable = false;
    }

    function declareResult() internal {
        uint256 _gameId = lastActiveGameId;
        if (gameResult[_gameId].status == 1) {
            if (_gameId < getCurrentGameId()) {
                requestRandomWords(_gameId);
            }
        }
    }

    function getResult(uint256 _gameId) external {
        require(msg.sender == ownerAddress, "Only owner can declair result");
        require(gameResult[_gameId].status != 10,"Result declared");
        require(gameResult[_gameId].status != 2,"In process");
        if (gameResult[_gameId].status <= 1) {
            require(
                _gameId < getCurrentGameId(),
                "Result can declared only after 24 hrs"
            );

            requestRandomWords(_gameId);
        }
        else if(gameResult[_gameId].status == 3)
        {
            delete gameResult[_gameId].randomWords;
            requestRandomWords(_gameId);
        }
    }

    // Assumes the subscription is funded sufficiently.
    function requestRandomWords(uint256 _gameId)
        internal
        returns (uint256 requestId)
    {
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        s_requests[requestId] = true;
        requestIds.push(requestId);
        requestIdWithGameId[requestId] = _gameId;
        if(gameResult[_gameId].status==1){
            gameResult[_gameId].prizeMoney = BUSD.balanceOf(address(this));
        }
        gameResult[_gameId].status = 2;
        
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId], "request not found");
        uint256 gameId = requestIdWithGameId[_requestId];
        for (uint256 _index = 0; _index < 6; _index++) {
            gameResult[gameId].randomWords.push((_randomWords[_index] % maxNo) + 1);
        }
         bool checkDuplicate;
            for (uint256 k = 0; k < gameResult[gameId].randomWords.length; k++) {
                for (uint256 j = k+1; j < gameResult[gameId].randomWords.length; j++) {
                    if (gameResult[gameId].randomWords[k] == gameResult[gameId].randomWords[j]) {
                        checkDuplicate = true;
                    }
                }
            }
            if(checkDuplicate)
            {
                gameResult[gameId].status = 3;
                // requestRandomWords(gameId);
            }
            else{
            gameResult[gameId].status = 10;
            resultDeclaredGameId = gameId;
            gameResult[gameId].time = block.timestamp;
            emit GameResultEvent(
                gameId,
                gameResult[gameId].randomWords,
                gameResult[gameId].prizeMoney,
                block.timestamp
            );
            }
    }

    function setOwnerAddress(address payable _address) public {
        ownerAddress = _address;
    }

    function setAuthAddress(address _address) public {
        require(msg.sender == ownerAddress, "Only owner can set authaddress");
        authAddress = _address;
    }

    function getGameResult(uint256 _gameId)
        external
        view
        returns (uint8 status, uint256[] memory randomNos)
    {
        return (gameResult[_gameId].status, gameResult[_gameId].randomWords);
    }

    function getBetDetails(uint256 _betId, uint256 _nftId)
        public
        view
        returns (bet memory)
    {
        return bets[_betId][_nftId];
    }

    function getResultDetails() external view returns(uint256 gameId,uint8 status,uint256 _resultDeclaredGameId)
    {
        return (lastActiveGameId,gameResult[lastActiveGameId].status,resultDeclaredGameId);
    }

    function getGameInfo() external view returns(uint256 _gameSpan,uint256 _availableTimeToClaim,uint256 _availableTimeToClaimJackpot,uint256 _currentTime,uint256 _gameId,uint256 _gameStartTime){
        
        
        return (gameSpan,availableTimeToClaim,availableTimeToClaimJackpot,block.timestamp,getCurrentGameId(),gameStartTime);
    }

}

// contract interface
interface NftMintInterface {
    // function definition of the method we want to interact with
    function mintReward(address to, uint256 nftPrice) external;

    function ownerOf(uint256 tokenId) external view returns (address);

    function getNftMintedDate(uint256 nftId) external view returns (uint256);

    function getNftNftPrice(uint256 nftId) external view returns (uint256);
}

interface Lotto {
    function getUpline(address _addr) external view returns(address);
}