/**
 *Submitted for verification at BscScan.com on 2022-08-28
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract LOTTO is VRFConsumerBaseV2, ConfirmedOwner {
    address payable ownerAddress;
    address authAddress;
    VRFCoordinatorV2Interface COORDINATOR;

    //lotto contract
    uint256 gameStartTime;
    IERC20 busd;
    uint256 lastId = 1;
    uint256 nftId = 1;
    uint256 betId = 1;

    //Nft contract
    uint256 accumulatingPer = 250;
    uint256 public globalAmount = 0;
    uint256 nftBuyAmount = 50 * 1e18;
    uint256 secondNftBuyAmount = 200 * 1e18;
    uint256 DevEarningsPer = 1000;
    address nftContract;
    NftMintInterface NftMint;
    uint8 constant BonusLinesCount = 5;
    uint256[BonusLinesCount] public referralBonus = [2000, 1000, 600, 200, 200];
    uint16 constant percentDivider = 10000;
    uint256 public accumulatRoundID = 1;

    uint64 s_subscriptionId;
    uint256[] public requestIds;
    uint256 public lastRequestId;
    uint256[] public _randomWordsInRange;
    uint256[] public getRandomNumbers;
    //uint256[6] randomWordsas;
    bytes32 keyHash =
        0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;
    uint32 callbackGasLimit = 600000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 6;

    uint256[7] public hitsAndRewards = [0,0, 0, 1, 10, 500, 250000];
    uint256[6] public accumulatedAmount = [500/10, 100/10, 100/10, 100/10, 100/10, 100/10];

    address[4] public adminsWalletAddress = [
        0xeC1cd23986763E2d03a09fb36F2d6A38447D8249,
        0xc8A00dcECF0cfE1060Cb684D56d470ead73F9F6F,
        0x93D1a91CBa4eB8d29d079509a3CD7Ec2109E5E42,
        0x703632A0b52244fAbca04aaE138fA8EcaF72dCBC
    ];

    struct playerStruct {
        address userAddress;
        uint256 playerId;
        address referral;
        uint256 totalReferralCount;
        //uint256 totalReferralCountSecondNft;
        uint256 totalReward;
        bool isBuyFirstNft;
        bool isBuySecondNft;
    }

    struct bet {
        uint256 betId;
        uint256 gameId;
        uint256 nftId;
        bool isClaim;
        uint256[6] betsNumber;
        uint256 totalMatchNumber;
    }

    struct DailyRound {
        mapping(uint256 => address) player; //address of the player with highest referrals
    }

    struct PlayerDailyRounds {
        uint256 referrers; // total referrals user has in a particular round
        uint256 totalReferralInsecondNft;
    }

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }

    struct BetResult {
        uint256 gameId;
        bool isResultDeclared;
    }

    mapping(address => playerStruct) public player;
    mapping(uint256 => mapping(address => bet)) public bets;
    mapping(address => bet) public betDetails;
    mapping(address => uint256) public getBetIdByWalletAddress;
    mapping(uint256 => BetResult) public betResult;
    mapping(uint256 => mapping(uint256 => bool)) public isPlayed;
    mapping(uint256 => uint256) public requestIdWithBetId;

    //mapping (uint => bool) public isResultDeclared;

    mapping(uint256 => DailyRound) round;
    mapping(address => mapping(uint256 => PlayerDailyRounds)) public plyrRnds_;

    mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */

    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    event PlayerDataEvent(uint256 playerId,address userAddress,address referral,uint256 time);
    event ClaimDataEvent(uint256 betId,uint256 gameId,uint256 matchedNumber,uint256 reward,address walletAddress);
    event BetPlayEvent(uint256 betId,uint256 gameId,uint256 nftId,address walletAddress, bool isClaim,uint256[6] betsNumber,uint256 time);
    event BetResultEvent(uint256 betId,uint256 gameId, uint256 matchedNumber,uint256[] resultNumber, bool isResultDeclared,uint256 winPrice, address walletAddress);


    constructor(
        address payable _ownerAddress,
        address _authAddress,
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

        busd = IERC20(0x1FAdc992EA93CcCEbE3F965e72DF9c7d0F4035c9);
        nftContract = 0x072b9aC7B2976eCB186070f75eCF05d3741076Ca;

        NftMint = NftMintInterface(nftContract);
        ownerAddress = _ownerAddress;
        authAddress = _authAddress;
        gameStartTime = _gameStartTime;

            uint256 _lastId = lastId;
         playerStruct memory _playerStruct = playerStruct({
                userAddress: msg.sender,
                playerId: _lastId,
                referral: address(0),
                totalReferralCount: 0,
                //totalReferralCountSecondNft: 0,
                totalReward: 0,
                isBuyFirstNft: false,
                isBuySecondNft: false
            });

            player[msg.sender] = _playerStruct;

            lastId++;
        //event PlayerData(uint256 playerId,address userAddress,address referral,uint256 totalReferralCount,uint256 totalReward);
        emit PlayerDataEvent(_lastId,msg.sender,address(0),block.timestamp);
    }

    function play(uint256[6] memory selectNum, uint256 _nftId) public {
        uint256 nftBuyDate = NftMint.getNftMintedDate(_nftId);

        require(block.timestamp < nftBuyDate + 365 days ,"You can play upto one year after nft buy");
        require(
            NftMint.ownerOf(_nftId) == msg.sender,
            "You are not owner of nft"
        );
        uint256 gameId = (block.timestamp / 300 - gameStartTime / 300) + 1;
        require(
            isPlayed[gameId][_nftId] == false,
            "You can play once in 24 hrs"
        );
        isPlayed[gameId][_nftId] = true;
        //check duplicate numbers
        for (uint256 i = 0; i < 6; i++) {
            //if (1 <= x && x <= 100)
            require(selectNum[i] > 0 && selectNum[i] <= 50,"Selected number should be in range of 1 to 50");

            for (uint256 j = i + 1; j < 6; j++) {
                require(selectNum[i] != selectNum[j],"Enter unique number");
            }
        }


        uint256 _betId = betId;
        betId++;
        bet memory _bet = bet({
            betId:_betId,
            gameId: gameId,
            nftId:_nftId,
            isClaim: false,
            betsNumber: selectNum,
            totalMatchNumber: 0
        });

        bets[gameId][msg.sender] = _bet;
        betDetails[msg.sender] = _bet;
         getBetIdByWalletAddress[msg.sender] = gameId;
         //event BetPlayEvent(uint256 betId,uint256 nftId,address walletAddress, bool isClaim,uint256[6] betsNumber,uint256 time);
         emit BetPlayEvent(_betId,gameId,_nftId,msg.sender,false,selectNum,block.timestamp);
    }

    function claim(uint256 gameId) public {
        require(bets[gameId][msg.sender].gameId > 0, "Invalid game");
        require(bets[gameId][msg.sender].isClaim == false, "Already claimed");

        /////////////////generate random num////////////////////
        //getResult(betId);

        /////////////////generate random num////////////////////

        // require(
        //     betResult[betId].isResultDeclared == false,
        //     "Result is not declared yet"
        // );
        ////////////start get result////////////
        uint256 counter = 0;
        uint256[6] memory userSelectedNumbers = bets[gameId][msg.sender]
            .betsNumber;
        for (uint256 i = 0; i < _randomWordsInRange.length; i++) {
            for (uint256 j = 0; j < userSelectedNumbers.length; j++) {
                if (_randomWordsInRange[i] == userSelectedNumbers[j]) {
                    counter++;
                }
            }
        }
        bets[gameId][msg.sender].totalMatchNumber = counter;

        ////////////end get result////////////

        bets[gameId][msg.sender].isClaim = true;
        player[msg.sender].totalReward += hitsAndRewards[counter];

        //payable(msg.sender).transfer(address(this).balance < 1 ? hitsAndRewards[bets[betId][msg.sender].totalMatchNumber] : 1);
        IERC20(busd).transfer(
            msg.sender,
            hitsAndRewards[counter]
        );


        //IERC20(busd).transfer(ownerAddress, DevEarnings);
        //emit ClaimDataEvent(betId,counter,hitsAndRewards[counter],msg.sender);

        emit BetResultEvent(betId,gameId,counter, _randomWordsInRange,true,hitsAndRewards[counter],msg.sender);
    }

    function buyFirstNft(address _referral) public payable {
        IERC20(busd).transferFrom(msg.sender, address(this), nftBuyAmount);


        if(_referral != ownerAddress)
        {
            require(player[_referral].isBuyFirstNft,"Invalid referral");
        //set referral;
            _setUpUpline(msg.sender, _referral);
        }

        //if(globalAmount >= 1000*1e18)
        if(globalAmount >= 10*1e18)
        {
            sendAccumulatedAmount();
        }
        uint256 _accumulatedAmount = (nftBuyAmount * accumulatingPer) /
            percentDivider;

        // 50*250 / 10000

        //referral distribution
        _refPayout(msg.sender, nftBuyAmount);
        globalAmount += _accumulatedAmount;

        uint256 DevEarnings = (nftBuyAmount * DevEarningsPer)/percentDivider;
        IERC20(busd).transfer(ownerAddress, DevEarnings);

        if (player[msg.sender].isBuyFirstNft == false) {
            player[msg.sender].isBuyFirstNft = true;
        }
        NftMint.mintReward(msg.sender,nftBuyAmount);

        if (player[msg.sender].playerId == 0) {

            uint256 _lastId = lastId;
            playerStruct memory _playerStruct = playerStruct({
                userAddress: msg.sender,
                playerId: _lastId,
                referral: _referral,
                totalReferralCount: 0,
                //totalReferralCountSecondNft: 0,
                totalReward: 0,
                isBuyFirstNft: true,
                isBuySecondNft: false
            });

            player[msg.sender] = _playerStruct;
            player[_referral].totalReferralCount++;
            lastId++;
          //event PlayerData(uint256 playerId,address userAddress,address referral,uint256 totalReferralCount,uint256 totalReward);
         emit PlayerDataEvent(_lastId,msg.sender,_referral,block.timestamp);

        }
    }

    function buySecondNft(address _referral) public payable {

        IERC20(busd).transferFrom(msg.sender, address(this), secondNftBuyAmount);
        require(player[msg.sender].isBuyFirstNft,"You need to buy 50 USDT nft first");

        if(player[_referral].isBuySecondNft == true)
            {
        plyrRnds_[_referral][accumulatRoundID].referrers++;
        _highestReferrer(_referral);
            }

        if (plyrRnds_[_referral][accumulatRoundID].referrers % 5 <= 4) {
            //payable(msg.sender).transfer(_amount);
            if(player[msg.sender].isBuySecondNft == true)
            {
            IERC20(busd).transfer(msg.sender, secondNftBuyAmount);
            }
            else
            {
                IERC20(busd).transfer(ownerAddress, secondNftBuyAmount);
            }
        } else {
            for (uint256 i = 0; i <= adminsWalletAddress.length; i++) {
                // payable(adminsWalletAddress[i]).transfer(50);
                IERC20(busd).transfer(adminsWalletAddress[i], 50 * 1e18);
            }
        }

        NftMint.mintReward(msg.sender,secondNftBuyAmount);

         if (player[msg.sender].isBuySecondNft == false) {
            player[msg.sender].isBuySecondNft = true;
        }
    }


    function _highestReferrer(address _referrer) private {
        address upline = _referrer;

        if (upline == address(0)) return;

        for (uint8 i = 0; i < 6; i++) {
            if (round[accumulatRoundID].player[i] == upline) break;

            if (round[accumulatRoundID].player[i] == address(0)) {
                round[accumulatRoundID].player[i] = upline;
                break;
            }

            if (
                plyrRnds_[_referrer][accumulatRoundID].referrers >
                plyrRnds_[round[accumulatRoundID].player[i]][accumulatRoundID]
                    .referrers
            ) {
                for (uint256 j = i + 1; j < 6; j++) {
                    if (round[accumulatRoundID].player[j] == upline) {
                        for (uint256 k = j; k <= 6; k++) {
                            round[accumulatRoundID].player[k] = round[
                                accumulatRoundID
                            ].player[k + 1];
                        }
                        break;
                    }
                }

                for (uint8 l = uint8(6 - 1); l > i; l--) {
                    round[accumulatRoundID].player[l] = round[accumulatRoundID]
                        .player[l - 1];
                }

                round[accumulatRoundID].player[i] = upline;

                break;
            }
        }
    }

    function _setUpUpline(address _addr, address _upline) private {
        require(player[_upline].playerId <= 0, "Invalid referral");

        if (player[_addr].referral == address(0)) {
            player[_addr].referral = _upline;
            player[_addr].totalReferralCount++;
        }
    }

    function _refPayout(address _addr, uint256 _amount) private {
        address up = player[_addr].userAddress;

        for (uint256 i = 0; i < BonusLinesCount; i++) {
            if (up == address(0)) {
                up = ownerAddress;
            }

            uint256 sendAmount = (_amount * referralBonus[i]) / percentDivider;
            // 50*2000 / 10000
            busd.transfer(up, sendAmount);

            up = player[up].userAddress;
        }
    }



    function getResult(uint256 _betId) public {
        if(!betResult[_betId].isResultDeclared){
        // require(
        //     _betId < (block.timestamp / 300 - gameStartTime / 300) + 1,
        //     "Result can declared only after 24 hrs"
        // );

        requestRandomWords(_betId);

        }
    }

    function sendAccumulatedAmount() internal {
        require(globalAmount >= 10*1e18,"Accumulated amount should be greator than 1000$");

        for (uint256 i = 0; i < 6; i++) {

            //  payable(round[accumulatRoundID].player[i]).transfer(accumulatedAmount[i]);
            if(round[accumulatRoundID].player[i] != address(0))
            {
            IERC20(busd).transfer(
                round[accumulatRoundID].player[i],
                accumulatedAmount[i]
            );
            }

            player[round[accumulatRoundID].player[i]].totalReward += accumulatedAmount[i];
        }
        accumulatRoundID++;
        globalAmount = 0;

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
        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        requestIdWithBetId[requestId] = _gameId;
        betResult[_gameId].gameId = _gameId;
        betResult[_gameId].isResultDeclared = true;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
       for (uint256 _index = 0; _index < 6; _index++) {
         _randomWordsInRange.push((_randomWords[_index] % 50) + 1);
        }

        s_requests[_requestId].randomWords = _randomWordsInRange;

        bool checkDuplicate;
            for(uint256 k=0; k < _randomWordsInRange.length; k++)
            {
                for(uint256 j=1; j < _randomWordsInRange.length; j++)
                {
                    if(_randomWordsInRange[k] == _randomWordsInRange[j])
                    {
                        checkDuplicate = true;
                    }
                }

            }

            if(checkDuplicate)
            {
                requestRandomWords(requestIdWithBetId[_requestId]);
            }
        //getRandom(_randomWords);
        emit RequestFulfilled(_requestId, _randomWords);
    }

    function getRequestStatus(uint256 _requestId)
        external
        view
        returns (bool fulfilled, uint256[] memory randomWords)
    {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }



    // function getArray() public view returns (uint256[] memory) {
    //     return _randomWordsInRange;
    // }

    function setOwnerAddress(address payable _address) public {
        ownerAddress = _address;
    }

    function setAuthAddress(address _address) public {
        require(msg.sender == ownerAddress, "Only owner can set authaddress");
        authAddress = _address;
    }

    function setNftAmount(uint256 amount) external {
        require(msg.sender == ownerAddress, "Only owner can change amount");
        nftBuyAmount = amount;
    }

    function getPlayerDetails(address _address)
        public
        view
        returns (playerStruct memory)
    {
        return player[_address];
    }


    function getBetNumbersByUser(uint256 _betId, address _address) public view returns(uint256[6] memory)
    {
        return bets[_betId][_address].betsNumber;
    }

    function getBetDetails(uint256 _betId, address _address) public view returns(bet memory)
    {
        return bets[_betId][_address];
    }

    function getBetDetailsList(address _address) public view returns(bet memory)
    {
        return betDetails[_address];
    }


    function getGlobalAmount() public view returns(uint256)
    {
        return globalAmount;
    }

    function setAdminsWalletAddress(address[4] memory walletAddress) public {
        require(msg.sender == ownerAddress, "Only owner can set authaddress");
        adminsWalletAddress = walletAddress;
    }
}

// contract interface
interface NftMintInterface {
    // function definition of the method we want to interact with
    function mintReward(address to,uint256 nftPrice) external;

    function ownerOf(uint256 tokenId) external view returns (address);

    function getNftMintedDate(uint256 nftId) external view returns(uint256);

    function getNftNftPrice(uint256 nftId) external view returns(uint256);
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