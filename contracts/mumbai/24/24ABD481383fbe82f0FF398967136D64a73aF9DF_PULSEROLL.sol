/**
 *Submitted for verification at polygonscan.com on 2022-01-18
*/

/**
 *Submitted for verification at polygonscan.com on 2021-12-29
*/

/**
 *Submitted for verification at polygonscan.com on 2021-12-21
*/

pragma solidity 0.8.6;

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
    bytes32 private s_keyHash;
    uint256 private s_fee;
    
    //--->playersvars
    mapping(bytes32 => address) public playerAddress; //players address
    mapping(bytes32 => address) public playerTempAddress; //players temporary address
    mapping(bytes32 => bytes32) public playerBetId; //players bet id
    mapping(bytes32 => uint256) public playerBetValue; //players bet value
    mapping(bytes32 => uint256) public  playerTempBetValue;
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
        require (  _rollUnder >= minNumber &&  _rollUnder <= maxNumber && Profit <= IHousePool(StakingContract).maxProfit(),"Something gone wrong in the rollunder number and profits received" );
        _;
    }

    modifier CheckOddEven(uint _odd){
        require (_odd == 0 || _odd == 1 || _odd ==2,"The oddEven Status needs to be  0 or 1 or 2");
        _;
    }

    modifier CheckRangeSelect(uint _rangelower,uint _rangeupper)
    {
        if(_rangelower !=0 && _rangeupper !=0)
        {   
            require(_rangelower >=MinRange && _rangeupper <=MaxRange,"Wrong Range Selection");
            require(_rangelower != _rangeupper && _rangeupper > _rangelower ,"The range Endpoints needs to be different and the range upper always needs to be greater than range lower");
        }
        _;
    }
    
    modifier gameIsActive() {
        require (gamePaused != true,"The game is Paused") ;
        _;
    }

    /*
     * checks payouts are currently active
     */
    modifier payoutsAreActive() {
        require (payoutsPaused != true,"The payouts are paused ")  ;
        _;
    }

   

    /*
     * checks only owner address is calling
     */
    modifier onlyOwner() {
        require(msg.sender == owner,"The msg sender needs to Owner") ;
        _;
    }

    
    modifier CheckZero(){
        require(msg.value > 0,"Sending amount needs to be greater than 0");
        _;
    }
    
    /*
    
    
     ---> game vars
     */
    uint256 public  houseEdgeDivisor = 10000; //supports upto two decimal only
    uint256 public  maxNumber = 99; //max he can roll under 99
    uint256 public  minNumber = 2; //min he can roll under 2
    uint256 public MinRange =1;
    uint256 public MaxRange = 100;
    uint public BaseMulNum = 99;
    uint public BaseRangeDivisor = 2;
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
    address public StakingContract;
    address public FounderAddress;
    uint256 public totalweiLost;
    //Founder and Housepool Percent
    uint public FounderNum=5000;
    uint public HousePoolNum=5000;
    uint public CombinedDivisor=10000;
    
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
        // uint256 indexed ResultSerialNumber,
        bytes32 indexed BetID,
        address indexed PlayerAddress,
        uint256 PlayerNumber,
        uint256 DiceResult,
        uint256 Value,
        int256 Status,
        uint playerOddEvenStatus,
        uint playerRangeUpperLimit,
        uint playerRangeLowerLimit
        // bytes Proof
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
        owner = msg.sender;
        StakingContract=_stakingaddress;
        FounderAddress = _founderaddress;
        ownerSetHouseEdge(9900);
        s_keyHash = keyHash;
        s_fee = 0.001*10**18 ;
    }
    
    
    
    
    function playerRollDice(uint256 rollUnder,uint _OddEvenStatus ,uint rangeLowerLimit,uint rangeUpperLimit) public payable gameIsActive  CheckOddEven(_OddEvenStatus) CheckRangeSelect(rangeLowerLimit,rangeUpperLimit) betIsValid(rollUnder,_OddEvenStatus,rangeLowerLimit,rangeUpperLimit) CheckZero 
    returns(bytes32)
    {

        LINK.transferFrom(msg.sender,address(this),s_fee);
        require(LINK.balanceOf(address(this)) >= s_fee, "Not enough LINK to pay");
        totalBets += 1; 
        totalWeiWagered += msg.value;
        bytes32 requestId = requestRandomness(s_keyHash, s_fee);

        
        playerBetId[requestId] = requestId; //mapping(bytes32==>bytes32)
        /* map player lucky number to this oraclize query */
        playerNumber[requestId] = rollUnder; //map the rollid
        /* map value of wager to this oraclize query */
        playerBetValue[requestId] = msg.value; //map rngId to value
        /* map player address to this oraclize query */
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
                playerBetId[requestId],
                playerAddress[requestId],
                (playerBetValue[requestId] + playerProfit[requestId]),
                playerProfit[requestId],
                playerBetValue[requestId],
                playerNumber[requestId],
                playerOddEvenStatus[requestId],
                playerRangeUpperLimit[requestId],
                playerRangeLowerLimit[requestId]
            );
        return playerBetId[requestId];
    }
    
    
    
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal payoutsAreActive override 
    {
        // emit GotIt("fulfillRandomness",1);
        require (playerAddress[requestId] != address(0),"The player address should not be Zero address");
        uint256 DiceRoll = (randomness%(100))+(1);
        

        playerDieResult[requestId] = DiceRoll;
        playerTempAddress[requestId] = playerAddress[requestId]; 
      
        delete playerAddress[requestId];

        /* map the playerProfit for this query id */
        playerTempReward[requestId] = playerProfit[requestId]; //player estimated profit move to the temporary variable
        /* set  playerProfit for this query id to 0 */
        playerProfit[requestId] = 0;

        maxPendingPayouts = maxPendingPayouts - playerTempReward[requestId]; //reduce the payoutsfor theuser



        /* map the playerBetValue for this query id */
        playerTempBetValue[requestId] = playerBetValue[requestId]; //move temporary bet value of the user tothe temporary variable
        /* set  playerBetValue for this query id to 0 */
        playerBetValue[requestId] = 0;
           
        if ( playerDieResult[requestId] == 0 || bytes32(randomness).length == 0 ) 
        {   
            /**
              if we haven't have received any result or proof from the oracle ,then we can refund the user funds
             */

            payable(playerTempAddress[requestId]).transfer(playerTempBetValue[requestId]);
            emit LogResult(
                // serialNumberOfResult,
                playerBetId[requestId],
                playerTempAddress[requestId],
                playerNumber[requestId],
                playerDieResult[requestId],
                playerTempBetValue[requestId],
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
     * used only if bet placed + oraclize failed to __callback
     * filter LogBet by address and/or playerBetId:
     * LogBet(playerBetId[rngId], playerAddress[rngId], safeAdd(playerBetValue[rngId], playerProfit[rngId]), playerProfit[rngId], playerBetValue[rngId], playerNumber[rngId]);
     * check the following logs do not exist for playerBetId and/or playerAddress[rngId] before refunding:
     * LogResult or LogRefund--->because this are present in the callback
     * if LogResult exists player should use the withdraw pattern playerWithdrawPendingTransactions-->if logResult exists 
     */
    function ownerRefundPlayer(
        bytes32 originalPlayerBetId,
        address sendTo,
        uint256 originalPlayerProfit,
        uint256 originalPlayerBetValue
    ) public onlyOwner {
        /* safely reduce pendingPayouts by playerProfit[rngId] */
        maxPendingPayouts = (maxPendingPayouts - originalPlayerProfit);//take out the player profit from maxpendingpayouts
        /* send refund */
         payable(sendTo).transfer(originalPlayerBetValue) ;//original betamount is betamount
        /* log refunds */
        emit LogRefund(originalPlayerBetId, sendTo, originalPlayerBetValue);
    }
 
    receive() external payable{
    }
    
    function ownerSetOraclizeSafeGas(uint _Scalednewfee)
        public
        onlyOwner
    {
        s_fee = _Scalednewfee;//keep it in 1*10**18(1 Token)
    }
    

    /* only owner address can set houseEdge */
    function ownerSetHouseEdge(uint256 newHouseEdge) public onlyOwner {
        houseEdge = newHouseEdge;
    }


    /* only owner address can set emergency pause #1 */
    function ownerPauseGame(bool newStatus) public onlyOwner {
        gamePaused = newStatus;
    }

    /* only owner address can set emergency pause #2 */
    function ownerPausePayouts(bool newPayoutStatus) public onlyOwner {
        payoutsPaused = newPayoutStatus;
    }
    

    /* only owner address can suicide - emergency */
    function ownerkill() public onlyOwner {
        selfdestruct(payable(owner));
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
        if(playerDieResult[requestId] >= playerRangeLowerLimit[requestId] && playerDieResult[requestId] < playerRangeUpperLimit[requestId])
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
        if(playerTempReward[requestId] > 0)
        {
            IHousePool(StakingContract).Transfer(playerTempReward[requestId]);
        }
          


         /* update total wei won */
         totalWeiWon = (totalWeiWon + playerTempReward[requestId]); //update the total amount won in wei


         /* safely calculate payout via profit plus original wager */
         playerTempReward[requestId] = ( playerTempReward[requestId] + playerTempBetValue[requestId]); //update the player reward(the profit he receive + the bet value he has submitted)

         payable(playerTempAddress[requestId]).transfer(playerTempReward[requestId]);         
         emit LogResult(
            // serialNumberOfResult,
            playerBetId[requestId],
            playerTempAddress[requestId],
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
            // serialNumberOfResult,
            playerBetId[requestId],
            playerTempAddress[requestId],
            playerNumber[requestId],
            playerDieResult[requestId],
            playerTempBetValue[requestId],
            0,
            playerOddEvenStatus[requestId],
            playerRangeUpperLimit[requestId],
            playerRangeLowerLimit[requestId]
            //proof
        );
        totalweiLost=(totalweiLost +(playerTempBetValue[requestId]));

        DistributeFunds(FounderAddress,playerTempBetValue[requestId]);

    }

    function DistributeFunds(address _receiver,uint _amount)internal{
        require(_receiver != address(0) && StakingContract != address(0),"The address cant be zero address");
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
           IHousePool(StakingContract).SendRewardFunds{value:HousePoolAmount}();
       }
          
    }

    //Get functions 
    function GetMultiplier(uint _RollUnder,uint _OddEvenStatus,bool _IsRangeTrue,uint RangeLow,uint RangeHigh)public view CheckOddEven(_OddEvenStatus) CheckRangeSelect(RangeLow,RangeHigh) returns(uint)
    {
        uint Multiplier=(BaseMulNum*(1e18))/(_RollUnder-1);
        if(_OddEvenStatus==1 || _OddEvenStatus ==2)
        {
            uint chances=(_RollUnder*(1e18))/2;
            uint oddEvenMultiplier=(_RollUnder*(1e18))/chances;
            Multiplier =Multiplier + (oddEvenMultiplier*(1e18));
        }
        if(_IsRangeTrue == true)
        {
            uint range = RangeHigh - RangeLow;
            uint totalChances = ((100 - range)*(1e18)) / BaseRangeDivisor;
            Multiplier =Multiplier + totalChances;
        }
        return Multiplier;
    }

    function GetProfit(uint _RollUnder,uint _OddEvenStatus,uint RangeLow,uint RangeHigh,uint betValue )public view CheckOddEven(_OddEvenStatus) CheckRangeSelect(RangeLow,RangeHigh) returns(uint )
    {
        
        bool _IsRangeTrue;
        if(RangeLow !=0 && RangeHigh !=0 )
        {
            _IsRangeTrue = true;
        }
        uint Mul=GetMultiplier(_RollUnder,_OddEvenStatus,_IsRangeTrue,RangeLow,RangeHigh);
        uint returnedAmount=(betValue)*Mul;
        uint scaledreturnAmount=returnedAmount/(1e18);
        uint CutHouse=CutHouseEdge(scaledreturnAmount);
        uint Profit;
        if(CutHouse > betValue)
        {
            Profit=CutHouse - betValue;
        }
        return (Profit);
    }

    function CutHouseEdge(uint payout)internal view returns(uint){
        return (payout*houseEdge/(houseEdgeDivisor));
    }

   //Owner functions

    function nominateNewOwner(address _wallet) external onlyOwner {
        require(_wallet != address(0));
        nominatedWallet = _wallet;
        emit walletNominated(_wallet);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedWallet, "You must be nominated before you can accept ownership");
        emit walletChanged(owner, nominatedWallet);
        owner = nominatedWallet;
        nominatedWallet = address(0);
    }


    function SetFounderAddress(address _account)public onlyOwner
    {
        require(_account != address(0));
        FounderAddress=_account;
    }
    function ChangeStakingAddress(address _contractAddress)public onlyOwner
    {
        require(_contractAddress != address(0));
        StakingContract=_contractAddress;
    }
    function ChangeMAXandMINnumber(uint _MaxNumber,uint _MinNumber)public onlyOwner
    {
        require(_MaxNumber !=0 && _MinNumber !=0);
        minNumber=_MinNumber;
        maxNumber=_MaxNumber;
    }
    function ChangeMAXandMINRange(uint _MaxRange,uint _MinRange)public onlyOwner
    {
        require(_MaxRange !=0 && _MinRange !=0);
        MinRange=_MinRange;
        MaxRange=_MaxRange;
    }
    function ChangePercentForFounderAndHousePool(uint _NumFounder,uint _NumHousePool,uint _Divisor)public onlyOwner{
        require((_NumFounder + _NumHousePool) == _Divisor);
        FounderNum=_NumFounder;
        HousePoolNum=_NumHousePool;
        CombinedDivisor=_Divisor;
    }
    function ChangeMulandRangeBase(uint _mulBase,uint _RangeBase)public onlyOwner{
        require(_mulBase != 0 && _RangeBase !=0);
        BaseMulNum= _mulBase;
        BaseRangeDivisor= _RangeBase;
    }
    function emergencyWithdraw(address  _recepient) public onlyOwner{
        require(_recepient != address(0));
        payable(_recepient).transfer(address(this).balance);
    }



    
}