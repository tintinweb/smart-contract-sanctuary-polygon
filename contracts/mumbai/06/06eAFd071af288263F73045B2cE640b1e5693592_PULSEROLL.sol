/**
 *Submitted for verification at polygonscan.com on 2022-05-13
*/

pragma solidity 0.8.12;

library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}
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
interface IHousePool{
    function Transfer(uint _amount)external;
    function SendRewardFunds()payable external;
    function minBet() external view returns(uint256);
    function maxBet()external view returns(uint256);
    function maxProfit() external view returns(uint256);
}
contract VRFRequestIDBase {
  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetiti on in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

abstract contract VRFConsumerBase is VRFRequestIDBase {
  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 private constant USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface internal immutable LINK;
  address private immutable vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 => uint256) /* keyHash */ /* nonce */
    private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}


contract PULSEROLL is VRFConsumerBase {
    //--->Chainlink variables
    bytes32 public s_keyHash;
    uint256 public s_fee;
    
     /*
     ---> game vars
     */
    uint256 public  houseEdgeDivisor = 10000; //supports upto two decimal only
    uint256 public  maxNumber = 99; //max he can roll under 99
    uint256 public  minNumber = 2; //min he can roll under 2
    uint256 public MinRange =1;
    uint256 public MaxRange = 100;
    uint public BaseMulNumAll = 99;
    uint public BaseMulNumOnlyRange=99;
    uint public BaseDivisorRange=4;
    bool public gamePaused; //is the game is paused
    bool public payoutsPaused; //is the payouts are pauced
    address public owner; //owner of the contract
    uint256 public houseEdge; //house edge percent
    int256 public totalBets; //total bets that had happened
    uint256 public maxPendingPayouts; //How many maximum pending payouts need to be there
    //init dicontinued contract data
    uint256 public totalWeiWon; //total amount won in wei
    //init dicontinued contract data
    uint256 public totalWeiWagered; //total amount that is betted in wei
    address public nominatedWallet;

    //StakingContract
    IHousePool public StakingContract;
    address public FounderAddress;
    uint256 public totalweiLost;
    //Founder and Housepool Percent
    uint public FounderNum=5000;
    uint public HousePoolNum=5000;
    uint public CombinedDivisor=10000;

    //--->playersvars
    mapping(bytes32 => address) public playerAddress; //players address
    mapping(bytes32 => uint256) public playerBetValue; //players bet value
    mapping(bytes32 => uint256) public playerDieResult;
    mapping(bytes32 => uint256) public playerNumber;
    mapping(bytes32 => uint256) public playerProfit;
    mapping(bytes32 => uint256) public playerTempReward;
    mapping(bytes32 => uint) public playerOddEvenStatus;
    mapping(bytes32 => uint) public  playerRangeUpperLimit;
    mapping(bytes32 => uint) public playerRangeLowerLimit;
    mapping(bytes32 => bool) public playerRangeTrue;



     modifier betIsValid(uint256 _rollUnder, uint256 _OddEvenStatus,uint256 _Rangelower,uint _RangeUpper) {
        uint Profit=GetProfit(_rollUnder,_OddEvenStatus,_Rangelower,_RangeUpper,msg.value);
        require (  _rollUnder >= minNumber &&  _rollUnder <= maxNumber && Profit <= StakingContract.maxProfit(),"Something gone wrong in the rollunder number and profits received" );
        _;
    }


    modifier checkOddRangeSelect(uint _rangelower,uint _rangeupper,uint _odd,uint _rollUnder)
    {
        require (_odd< 3,"The oddEven Status needs to be  0 or 1 or 2");
        if(_rangelower !=0 && _rangeupper !=0 && _rollUnder !=0)
        {   
            require(_rangelower >=MinRange && _rangeupper <=MaxRange,"Wrong Range Selection");
            require( _rangeupper > _rangelower ,"The range Endpoints needs to be different and the range upper always needs to be greater than range lower");
            require(_rangelower < _rollUnder && _rangeupper < _rollUnder,"The selected Range needs to be less than the Rollunder");
        }
         if(_odd!=0)
        {
            require(_rollUnder > 2,"The rollunder needs to be greater than 2 To select oddEven as 1 or 2");
        }
        _;
    }
    
    modifier gameIsActive() {
        require (!gamePaused,"The game is Paused") ;//gamepaused!= true
        _;
    }

    /*
     * checks payouts are currently active
     */
    modifier payoutsAreActive() {
        require (!payoutsPaused,"The payouts are paused ")  ;//payoutspaused should not be equal to true
        _;
    }

   

    /*
     * checks only owner address is calling
     */
    modifier onlyOwner() {
        require(msg.sender == owner,"The msg sender needs to Owner") ;
        _;
    }

    
    modifier checkZero(){
        require(msg.value > 0,"Sending amount needs to be greater than 0");
        _;
    }
    

    
    /* events*/
    /* log bets + output to web3 for precise 'payout on win' field in UI */
    event LogBet(
        bytes32 indexed BetID,
        address indexed PlayerAddress,
        uint256 indexed RewardValue,
        uint256 ProfitValue,
        uint256 BetValue,
        uint256 PlayerNumber,
        uint playerOddEvenStatus,
        uint playerRangeUpperLimit,
        uint playerRangeLowerLimit
    );

    /* output to web3 UI on bet result*/
    /* Status: 0=lose, 1=win, 2=refund*/
    event LogResult(
        bytes32 indexed BetID,
        address indexed PlayerAddress,
        uint256 PlayerNumber,
        uint256 DiceResult,
        uint256 Value,
        int256 Status,
        uint playerOddEvenStatus,
        uint playerRangeUpperLimit,
        uint playerRangeLowerLimit
    );
    /* log manual refunds */
    event LogRefund(
        bytes32 indexed BetID,
        address indexed PlayerAddress,
        uint256 indexed RefundValue
    );
    /* log owner transfers */
    event LogOwnerTransfer(
        address indexed SentToAddress,
        uint256 indexed AmountTransferred
    );
    
    event walletNominated(address newOwner);

    event walletChanged(address oldOwner, address newOwner);
   

    
    //Constructor 
    
    constructor(address vrfCoordinator, address link, bytes32 keyHash,address _stakingaddress,address _founderaddress)
        VRFConsumerBase(vrfCoordinator, link)
    {
        require(_stakingaddress != address(0),"staking address cannot be zero address");
        require(_founderaddress != address(0),"Founder address cannot be zero address");
        require(vrfCoordinator != address(0),"vrfCorordinator address cannot be zero address");
        require(link != address(0),"link address cannot be zero address");
        require(keyHash != bytes32(0),"The keyhash bytes should not be zero address");
        owner = msg.sender;
        StakingContract=IHousePool(_stakingaddress);
        FounderAddress = _founderaddress;
        ownerSetHouseEdge(9900);
        s_keyHash = keyHash;
        s_fee = 0.001*10**18 ;
    }

     receive() external payable{
    }
     
    function playerRollDice(uint256 rollUnder,uint _OddEvenStatus ,uint rangeLowerLimit,uint rangeUpperLimit) external payable gameIsActive  checkOddRangeSelect(rangeLowerLimit,rangeUpperLimit,_OddEvenStatus,rollUnder) betIsValid(rollUnder,_OddEvenStatus,rangeLowerLimit,rangeUpperLimit) checkZero 
    returns(bytes32)
    {
        TransferHelper.safeTransferFrom(address(LINK), msg.sender, address(this), s_fee);
        require(LINK.balanceOf(address(this)) >= s_fee, "Not enough LINK to pay");
        totalBets += 1; 
        totalWeiWagered += msg.value;
        
        bytes32 requestId = requestRandomness(s_keyHash, s_fee);

        /* map player lucky number to this chainlink query */
        playerNumber[requestId] = rollUnder; //map the rollid
        /* map value of wager to this chainlink query */
        playerBetValue[requestId] = msg.value; //map rngId to value
        /* map player address to this chainlink query */
        playerAddress[requestId] = msg.sender;
        /*map Player odd or evenstatus*/
        playerOddEvenStatus[requestId]= _OddEvenStatus;
        
        //check if Range field is true or false.
        if (rangeUpperLimit == 0 || rangeLowerLimit == 0 ){
            playerRangeTrue[requestId] = false;//send num between 1 and. 99
        }
        else {

            playerRangeTrue[requestId] = true;
            //map player upper limit of range.
            playerRangeUpperLimit[requestId]= rangeUpperLimit;
            //map player lower limit of range. 
            playerRangeLowerLimit[requestId]= rangeLowerLimit;
        }
        
        playerProfit[requestId]=GetProfit(rollUnder,_OddEvenStatus,rangeLowerLimit,rangeUpperLimit,msg.value);

        maxPendingPayouts = maxPendingPayouts + playerProfit[requestId];
        
        require (address(StakingContract).balance >= maxPendingPayouts,"There is no enough balance");
        emit LogBet(
            requestId,
            playerAddress[requestId],
            (playerBetValue[requestId] + playerProfit[requestId]),
            playerProfit[requestId],
            playerBetValue[requestId],
            playerNumber[requestId],
            playerOddEvenStatus[requestId],
            playerRangeUpperLimit[requestId],
            playerRangeLowerLimit[requestId]
        );
        return requestId;
    }
    
    
    
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal payoutsAreActive override 
    {
        require (playerAddress[requestId] != address(0),"The player address should not be Zero address");
        uint256 DiceRoll = (randomness%(100))+(1);
        

        playerDieResult[requestId] = DiceRoll;

        maxPendingPayouts = maxPendingPayouts - playerProfit[requestId]; //reduce the payoutsfor theuser

           
        if ( playerDieResult[requestId] == 0 || bytes32(randomness).length == 0 ) 
        {   
            /**
              if we haven't have received any result or proof from the oracle ,then we can refund the user funds
             */

            payable(playerAddress[requestId]).transfer(playerBetValue[requestId]);
            emit LogResult(
                // serialNumberOfResult,
                requestId,
                playerAddress[requestId],
                playerNumber[requestId],
                playerDieResult[requestId],
                playerBetValue[requestId],
                2,
                playerOddEvenStatus[requestId],
                playerRangeUpperLimit[requestId],
                playerRangeLowerLimit[requestId]
                // proof
            );


            return;
        } //send the refund and if it fails we will store in the player refunds

        /*
        * pay winner
        * update contract balance to calculate new max bet
        * send reward
        * if send of reward fails save value to playerPendingWithdrawals
        */
        if(playerDieResult[requestId] < playerNumber[requestId])
        {
            if(playerOddEvenStatus[requestId] == 0)
            {
                SetRange(requestId);
                return;
            }
            else if(playerOddEvenStatus[requestId] == 1)
            {
                //1 refers to Odd
                //2 refers to Even
                bool check =CheckOdd(playerDieResult[requestId]);
                if(check)
                {
                    SetRange(requestId);
                    return;
                }
                else{
                    DistributeLoss(requestId);
                    return;
                }
                
            }
            else if(playerOddEvenStatus[requestId] ==2)
            {
                bool check =CheckEven(playerDieResult[requestId]);
                if(check)
                {
                    SetRange(requestId);
                    return;
                }
                else{
                    DistributeLoss(requestId);
                    return;
                }
            }
        }

        /*
        * no win
        * send 1 wei to a losing bet
        * update contract balance to calculate new max bet
        */
        if (playerDieResult[requestId] >= playerNumber[requestId]) 
        {
            DistributeLoss(requestId);
            return;
        }
    }

    

    /* only owner address can do manual refund
     * used only if bet placed + chainlink failed to __callback
     * filter LogBet by address and/or playerBetId:
     * LogBet(playerBetId[rngId], playerAddress[rngId], safeAdd(playerBetValue[rngId], playerProfit[rngId]), playerProfit[rngId], playerBetValue[rngId], playerNumber[rngId]);
     * check the following logs do not exist for playerBetId and/or playerAddress[rngId] before refunding:
     * LogResult or LogRefund--->because this are present in the callback
     */
    function ownerRefundPlayer(
        bytes32 originalPlayerBetId,
        address sendTo,
        uint256 originalPlayerProfit,
        uint256 originalPlayerBetValue
    ) external onlyOwner {
        /* safely reduce pendingPayouts by playerProfit[rngId] */
        maxPendingPayouts = (maxPendingPayouts - originalPlayerProfit);//take out the player profit from maxpendingpayouts
        /* send refund */
         payable(sendTo).transfer(originalPlayerBetValue) ;//original betamount is betamount
        /* log refunds */
        emit LogRefund(originalPlayerBetId, sendTo, originalPlayerBetValue);
    }
 
   
    
    function ownerSetchainlinkSafeGas(uint _Scalednewfee)
        external
        onlyOwner
    {
        require(_Scalednewfee > 0,"The fee cannot be less than or equal to zero");
        require(_Scalednewfee != s_fee,"The fee should be differnt from the previous one");
        s_fee = _Scalednewfee;//keep it in 1*10**18(1 Token)
    }
    

    /* only owner address can set houseEdge */
    function ownerSetHouseEdge(uint256 newHouseEdge) public onlyOwner {
        require(newHouseEdge != houseEdge,"The houseEdge should not be same as previous houseedge");
        require(newHouseEdge > 0,"The HouseEdge needs to be greater than zero");
        houseEdge = newHouseEdge;
    }


    /* only owner address can set emergency pause #1 */
    function ownerPauseGame(bool newStatus) external onlyOwner {
        require(newStatus != gamePaused,"The status of game should not be same as previous one");
        gamePaused = newStatus;
    }

    /* only owner address can set emergency pause #2 */
    function ownerPausePayouts(bool newPayoutStatus) external onlyOwner {
        require(newPayoutStatus != payoutsPaused,"The status of payout should not be same as previous ");
        payoutsPaused = newPayoutStatus;
    }
    

    function CheckEven(uint _num)internal pure returns(bool){
        if((_num%2)!=0){
            return false;
        }
        return true;
    } 
    function CheckOdd(uint _num)internal pure returns(bool){
        if(_num%2==0)
        {
            return false;
        }
        return true;
    }
    function CheckRange(bytes32 requestId)internal view  returns(bool){
        if(playerDieResult[requestId] >= playerRangeLowerLimit[requestId] && playerDieResult[requestId] <= playerRangeUpperLimit[requestId])
        {
            return true;
        }
        return false;
    }
    function TransferProfit(bytes32 requestId)internal{
         /**
                        
         -->if the result is less than the player roll under
         */
         /* safely reduce contract balance by player profit */
        if(playerProfit[requestId] > 0)
        {
            StakingContract.Transfer(playerProfit[requestId]);
        }
          


         /* update total wei won */
         totalWeiWon = (totalWeiWon + playerProfit[requestId]); //update the total amount won in wei


         /* safely calculate payout via profit plus original wager */
         playerTempReward[requestId] = ( playerProfit[requestId] + playerBetValue[requestId]); //update the player reward(the profit he receive + the bet value he has submitted)

         payable(playerAddress[requestId]).transfer(playerTempReward[requestId]);         
         emit LogResult(
            // serialNumberOfResult,
            requestId,
            playerAddress[requestId],
            playerNumber[requestId],
            playerDieResult[requestId],
            playerTempReward[requestId],//invludes profit+Amount Beted
            1,
            playerOddEvenStatus[requestId],
            playerRangeUpperLimit[requestId],
            playerRangeLowerLimit[requestId]
                         //proof
        );

    }

    function SetRange(bytes32 requestId)internal 
    {
        if(playerRangeTrue[requestId] == false)
        {
            TransferProfit(requestId);
        }
        else if(playerRangeTrue[requestId] == true)
        {
            bool check=CheckRange(requestId );
            if(check)
            {
             TransferProfit(requestId);
            }
            else
            {
                DistributeLoss(requestId);
            }
        }

    }

    function DistributeLoss(bytes32 requestId)internal 
    {
        emit LogResult(
            requestId,
            playerAddress[requestId],
            playerNumber[requestId],
            playerDieResult[requestId],
            playerBetValue[requestId],
            0,
            playerOddEvenStatus[requestId],
            playerRangeUpperLimit[requestId],
            playerRangeLowerLimit[requestId]
            //proof
        );
        totalweiLost=(totalweiLost +(playerBetValue[requestId]));

        DistributeFunds(FounderAddress,playerBetValue[requestId]);

    }

    function DistributeFunds(address _receiver,uint _amount)internal{
        require(_receiver != address(0) && address(StakingContract) != address(0),"The address cant be zero address");
        require(_amount != 0,"The amount is equals to zero");
        require(address(this).balance >= _amount,"The contract didnt have the funds");
        uint ContractAmount=_amount;
       uint FounderAmount=ContractAmount*FounderNum/(CombinedDivisor);
       uint HousePoolAmount=ContractAmount*HousePoolNum/(CombinedDivisor);
       if(FounderAmount >0)
       {
           payable(_receiver).transfer(FounderAmount);
       }
       if(HousePoolAmount > 0)
       {
           StakingContract.SendRewardFunds{value:HousePoolAmount}();
       }
          
    }

    //Get functions 
    function GetMultiplier(uint _RollUnder,uint _OddEvenStatus,bool _IsRangeTrue,uint RangeLow,uint RangeHigh)public view checkOddRangeSelect(RangeLow,RangeHigh,_OddEvenStatus,_RollUnder) returns(uint)
    {
        require(_RollUnder >= minNumber &&  _RollUnder <= maxNumber,"The Entered RollUnder needs to be between minNumber and MaxNumber");
        if(RangeLow == 0 || RangeHigh ==0)
        {
            require(_IsRangeTrue == false,"IsRange needs to be false if rangelow or rangehigh setted as zero");
        }
        uint Multiplier=(BaseMulNumAll*(1e18))/(_RollUnder-1);//less is 1.0.1x and high is 99x
        if(_OddEvenStatus==1 || _OddEvenStatus ==2)
        {
            Multiplier = Multiplier + (2 * (1e18)); //It is Fixed everytime ti will give 2x
        }
        uint range;
        uint totalChances;
        if(_IsRangeTrue == true)
        {
            if(_OddEvenStatus ==1 || _OddEvenStatus == 2)
            {
                for(uint i=RangeLow;i<=RangeHigh;i++)
                {
                    bool check = _OddEvenStatus == 1?CheckOdd(i):CheckEven(i);
                    if(check)
                    {
                        range +=1;
                    }
                }
            }
            else{
                range = RangeHigh - RangeLow;
            }
            totalChances=(BaseMulNumOnlyRange*(1e18))/(range);
            totalChances=totalChances/BaseDivisorRange;
            Multiplier =Multiplier+totalChances;
        }
        return Multiplier;
    }

    function GetProfit(uint _RollUnder,uint _OddEvenStatus,uint RangeLow,uint RangeHigh,uint betValue )public view checkOddRangeSelect(RangeLow,RangeHigh,_OddEvenStatus,_RollUnder) returns(uint )
    {
       require(betValue >0 ,"betvalue needs to be greater than zero");
        bool _IsRangeTrue;
        if(RangeLow !=0 && RangeHigh !=0 )
        {
            _IsRangeTrue = true;
        }
        uint Mul=GetMultiplier(_RollUnder,_OddEvenStatus,_IsRangeTrue,RangeLow,RangeHigh);
        uint returnedAmount=(betValue)*Mul;
        uint scaledreturnAmount=returnedAmount/(1e18);
        uint Profit;
        
        if(scaledreturnAmount > betValue)
        {
            Profit=scaledreturnAmount - betValue;
        }
        uint CutHouse=CutHouseEdge(Profit);
        return (CutHouse);
    }

    function CutHouseEdge(uint payout)internal view returns(uint){
        return (payout*houseEdge/(houseEdgeDivisor));
    }

   //Owner functions

    function nominateNewOwner(address _wallet) external onlyOwner {
        require(_wallet != address(0),"Account address cannot be zero");
        nominatedWallet = _wallet;
        emit walletNominated(_wallet);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedWallet, "You must be nominated before you can accept ownership");
        emit walletChanged(owner, nominatedWallet);
        owner = nominatedWallet;
        nominatedWallet = address(0);
    }


    function SetFounderAddress(address _account)external onlyOwner
    {
        require(_account != address(0),"Account address cannot be zero");
        require(_account != FounderAddress,"Founder Address cannot be same again");
        FounderAddress=_account;
    }
    function ChangeStakingAddress(address _contractAddress)external onlyOwner
    {
        require(_contractAddress != address(0),"Account address cannot be zero");
        require(_contractAddress != address(StakingContract),"StakingContract Address cannot be same again");
        StakingContract=IHousePool(_contractAddress);
    }
    function ChangeMAXandMINnumber(uint _MaxNumber,uint _MinNumber)external onlyOwner
    {
        require(_MaxNumber !=0 && _MinNumber !=0,"Account address cannot be zero");
        require(_MinNumber >= 2 && _MaxNumber <= 99,"The Number needs to be between 2 and 99");
        require(_MinNumber < _MaxNumber,"MinNumber is always less than MaxNumber");
        minNumber=_MinNumber;
        maxNumber=_MaxNumber;
    }
    function ChangeMAXandMINRange(uint _MaxRange,uint _MinRange)external onlyOwner
    {
        require(_MaxRange !=0 && _MinRange !=0,"Account address cannot be zero");
        require(_MinRange >=1 && _MaxRange <=100,"The Number needs to be between 1 and 100");
        require(_MinRange < _MaxRange,"MinRange is always less than MaxRange");
        MinRange=_MinRange;
        MaxRange=_MaxRange;
    }
    function ChangePercentForFounderAndHousePool(uint _NumFounder,uint _NumHousePool,uint _Divisor)external onlyOwner{
        require((_NumFounder + _NumHousePool) == _Divisor,"Percent needs to be equal to the divisor");
        FounderNum=_NumFounder;
        HousePoolNum=_NumHousePool;
        CombinedDivisor=_Divisor;
    }
    function ChangeMulandOddBase(uint _mulBaseAll,uint _mulBaseOnlyRange)external onlyOwner{
        require(_mulBaseAll != 0 && _mulBaseOnlyRange !=0 ,"Values cannot be zero");
        BaseMulNumAll= _mulBaseAll;
        BaseMulNumOnlyRange=_mulBaseOnlyRange;

    }
    function ChangeBaseDivisorRange(uint _baseDivisorRange)external onlyOwner
    {
        require(_baseDivisorRange != 0,"_baseDivisorRange cannot be zero");
        require(_baseDivisorRange != BaseDivisorRange,"_baseDivisorRange cannot be same again");
        BaseDivisorRange=_baseDivisorRange;
    }
    function emergencyWithdraw(address  _recepient) external onlyOwner{
        require(_recepient != address(0),"Account address cannot be zero");
        payable(_recepient).transfer(address(this).balance);
    }  
}