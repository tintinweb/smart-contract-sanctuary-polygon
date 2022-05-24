pragma solidity 0.8.12;
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
interface IHousePool{
    function Transfer(uint _amount)external;
    function SendRewardFunds()payable external;
    function minBet() external view returns(uint256);
    function maxBet()external view returns(uint256);
    function maxProfit() external view returns(uint256);
}

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

contract PULSEROLL is VRFConsumerBaseV2 {
    //--->Chainlink variables
    bytes32 public s_keyHash;
    uint256 public s_fee;
    VRFCoordinatorV2Interface public COORDINATOR;
    LinkTokenInterface public LINK;
    
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

    // A reasonable default is 100000, but this value could be different
    // on other networks.
    uint32 public callbackGasLimit = 2500000;

    // The default is 3, but you can set this higher.
    uint16 public requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 public numWords =  1;
    uint64 public s_subscriptionId;

    struct playersVars{
        address  playerAddress;
        uint256  playerBetValue;
        uint256  playerDieResult;
        uint256  playerNumber;
        uint256  playerProfit;
        bool  playerRequestFullfilled;
        uint256  playerTempReward;
        uint256  playerOddEvenStatus;
        uint256  playerRangeUpperLimit;
        uint256  playerRangeLowerLimit;
        bool  playerRangeTrue;   
    }

    mapping(uint256 => playersVars)public playerValues;

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
        require (!gamePaused,"The game is Paused");//gamepaused!= true
        _;
    }

    /*
     * checks payouts are currently active
     */
    modifier payoutsAreActive() {
        require (!payoutsPaused,"The payouts are paused ");//payoutspaused should not be equal to true
        _;
    }

   

    /*
     * checks only owner address is calling
     */
    modifier onlyOwner() {
        require(msg.sender == owner,"The msg sender needs to Owner");
        _;
    }

    
    modifier checkZero(){
        require(msg.value > 0,"Sending amount needs to be greater than 0");
        _;
    }
    

    
    /* events*/
    /* log bets + output to web3 for precise 'payout on win' field in UI */
    event LogBet(
        uint256 indexed BetID,
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
        uint256 indexed BetID,
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
        uint256 indexed BetID,
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
        VRFConsumerBaseV2(vrfCoordinator)
    {
        require(_stakingaddress != address(0),"staking address cannot be zero address");
        require(_founderaddress != address(0),"Founder address cannot be zero address");
        require(vrfCoordinator != address(0),"vrfCorordinator address cannot be zero address");
        require(link != address(0),"link address cannot be zero address");
        require(keyHash != bytes32(0),"The keyhash bytes should not be zero address");
        owner = msg.sender;
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINK = LinkTokenInterface(link);
         StakingContract=IHousePool(_stakingaddress);
        FounderAddress = _founderaddress;
        ownerSetHouseEdge(9900);
        s_keyHash = keyHash;
        s_fee = 0.0005*10**18 ;
        createNewSubscription();

    }

     receive() external payable{
    }
     
    function playerRollDice(uint256 rollUnder,uint _OddEvenStatus ,uint rangeLowerLimit,uint rangeUpperLimit) external payable gameIsActive  checkOddRangeSelect(rangeLowerLimit,rangeUpperLimit,_OddEvenStatus,rollUnder)  checkZero betIsValid(rollUnder,_OddEvenStatus,rangeLowerLimit,rangeUpperLimit)
    returns(uint256) 
    {
         TransferHelper.safeTransferFrom(address(LINK), msg.sender, address(this), s_fee);
        require(LINK.balanceOf(address(this)) >= s_fee, "Not enough LINK to pay");
        LINK.transferAndCall(address(COORDINATOR), s_fee, abi.encode(s_subscriptionId));
        totalBets += 1; 
        totalWeiWagered += msg.value;
        uint256 requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
           s_subscriptionId,
           requestConfirmations,
           callbackGasLimit,
           numWords
        );
        playersVars storage newPlayerVar=playerValues[requestId];
        /* map player lucky number to this chainlink query */
        newPlayerVar.playerNumber = rollUnder; //map the rollid
        /* map value of wager to this chainlink query */
        newPlayerVar.playerBetValue = msg.value; //map rngId to value
        /* map player address to this chainlink query */
        newPlayerVar.playerAddress = msg.sender;
        /*map Player odd or evenstatus*/
        newPlayerVar.playerOddEvenStatus= _OddEvenStatus;
        
        //check if Range field is true or false.
        if(rangeUpperLimit != 0 && rangeLowerLimit != 0 ){
            newPlayerVar.playerRangeTrue = true;
            //map player upper limit of range.
            newPlayerVar.playerRangeUpperLimit= rangeUpperLimit;
            //map player lower limit of range. 
            newPlayerVar.playerRangeLowerLimit= rangeLowerLimit;
        }
        
        newPlayerVar.playerProfit=GetProfit(newPlayerVar.playerNumber,newPlayerVar.playerOddEvenStatus,newPlayerVar.playerRangeLowerLimit,newPlayerVar.playerRangeUpperLimit,msg.value);

        maxPendingPayouts = maxPendingPayouts + newPlayerVar.playerBetValue;
        
        emit LogBet(
            requestId,
            newPlayerVar.playerAddress,
            (newPlayerVar.playerBetValue + newPlayerVar.playerProfit),
            newPlayerVar.playerProfit,
            newPlayerVar.playerBetValue,
            newPlayerVar.playerNumber,
            newPlayerVar.playerOddEvenStatus,
            newPlayerVar.playerRangeUpperLimit,
            newPlayerVar.playerRangeLowerLimit
        );
        return requestId;
    }
    
    
    
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal payoutsAreActive override 
    {
        playersVars storage newPlayerVar=playerValues[requestId];
        require (newPlayerVar.playerAddress != address(0),"The player address should not be Zero address");
        require(newPlayerVar.playerRequestFullfilled == false,"The request is already fullfilled");
        uint256 DiceRoll = (randomWords[0]%(100))+(1);
        
        
        newPlayerVar.playerDieResult = DiceRoll;

        maxPendingPayouts = maxPendingPayouts - newPlayerVar.playerBetValue; //reduce the payoutsfor theuser
        newPlayerVar.playerRequestFullfilled=true;
           
        if ( newPlayerVar.playerDieResult == 0 || bytes32(randomWords[0]).length == 0 ) 
        {   
            /**
              if we haven't have received any result or proof from the oracle ,then we can refund the user funds
             */

            payable(newPlayerVar.playerAddress).transfer(newPlayerVar.playerBetValue);
            emit LogResult(
                // serialNumberOfResult,
                requestId,
                newPlayerVar.playerAddress,
                newPlayerVar.playerNumber,
                newPlayerVar.playerDieResult,
                newPlayerVar.playerBetValue,
                2,
                newPlayerVar.playerOddEvenStatus,
                newPlayerVar.playerRangeUpperLimit,
                newPlayerVar.playerRangeLowerLimit
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
        if(newPlayerVar.playerDieResult < newPlayerVar.playerNumber)
        {
            if(newPlayerVar.playerOddEvenStatus == 0)
            {
                SetRange(requestId,newPlayerVar);
                return;
            }
            else if(newPlayerVar.playerOddEvenStatus == 1)
            {
                //1 refers to Odd
                //2 refers to Even
                bool check =CheckOdd(newPlayerVar.playerDieResult);
                if(check)
                {
                    SetRange(requestId,newPlayerVar);
                    return;
                }
                else{
                    DistributeLoss(requestId,newPlayerVar);
                    return;
                }
                
            }
            else if(newPlayerVar.playerOddEvenStatus ==2)
            {
                bool check =CheckEven(newPlayerVar.playerDieResult);
                if(check)
                {
                    SetRange(requestId,newPlayerVar);
                    return;
                }
                else{
                    DistributeLoss(requestId,newPlayerVar);
                    return;
                }
            }
        }

        /*
        * no win
        * send 1 wei to a losing bet
        * update contract balance to calculate new max bet
        */
        if (newPlayerVar.playerDieResult >= newPlayerVar.playerNumber) 
        {
            DistributeLoss(requestId,newPlayerVar);
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
        uint256 originalPlayerBetId
    ) external onlyOwner {
        playersVars storage newPlayerVar=playerValues[originalPlayerBetId];
        require(originalPlayerBetId != 0,"The bytes should not be empty");
        require(newPlayerVar.playerAddress != address(0),"player address should not be equal to 0");
        require(newPlayerVar.playerRequestFullfilled == false,"the requestId is already fullfilled");
        require(newPlayerVar.playerBetValue <= address(this).balance,"The bet value should be less than the balance in this contract");
        /* safely reduce pendingPayouts by playerProfit[rngId] */
        maxPendingPayouts = (maxPendingPayouts - newPlayerVar.playerBetValue);//take out the player profit from maxpendingpayouts
        newPlayerVar.playerRequestFullfilled=true;
        /* send refund */
         payable(newPlayerVar.playerAddress).transfer(newPlayerVar.playerBetValue) ;//original betamount is betamount

        /* log refunds */
        emit LogRefund(originalPlayerBetId, newPlayerVar.playerAddress, newPlayerVar.playerBetValue);
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
    function CheckRange(playersVars storage newPlayerVar)internal view  returns(bool){
        if(newPlayerVar.playerDieResult >= newPlayerVar.playerRangeLowerLimit && newPlayerVar.playerDieResult <= newPlayerVar.playerRangeUpperLimit)
        {
            return true;
        }
        return false;
    }
    function TransferProfit(uint256 requestId,playersVars storage newPlayerVar)internal{
        
         /**
                        
         -->if the result is less than the player roll under
         */
         /* safely reduce contract balance by player profit */
        if(newPlayerVar.playerProfit > 0)
        {
            StakingContract.Transfer(newPlayerVar.playerProfit);
        }
          


         /* update total wei won */
         totalWeiWon = (totalWeiWon + newPlayerVar.playerProfit); //update the total amount won in wei


         /* safely calculate payout via profit plus original wager */
         newPlayerVar.playerTempReward = ( newPlayerVar.playerProfit + newPlayerVar.playerBetValue); //update the player reward(the profit he receive + the bet value he has submitted)

         payable(newPlayerVar.playerAddress).transfer(newPlayerVar.playerTempReward);         
         emit LogResult(
            // serialNumberOfResult,
            requestId,
            newPlayerVar.playerAddress,
            newPlayerVar.playerNumber,
            newPlayerVar.playerDieResult,
            newPlayerVar.playerTempReward,//invludes profit+Amount Beted
            1,
            newPlayerVar.playerOddEvenStatus,
            newPlayerVar.playerRangeUpperLimit,
            newPlayerVar.playerRangeLowerLimit
                         //proof
        );

    }

    function SetRange(uint256 requestId,playersVars storage newPlayerVar)internal 
    {
        if(newPlayerVar.playerRangeTrue == false)
        {
            TransferProfit(requestId,newPlayerVar);
        }
        else if(newPlayerVar.playerRangeTrue == true)
        {
            bool check=CheckRange(newPlayerVar );
            if(check)
            {
             TransferProfit(requestId,newPlayerVar);
            }
            else
            {
                DistributeLoss(requestId,newPlayerVar);
            }
        }

    }

    function DistributeLoss(uint256 requestId,playersVars storage newPlayerVar )internal 
    {
        emit LogResult(
            requestId,
            newPlayerVar.playerAddress,
            newPlayerVar.playerNumber,
            newPlayerVar.playerDieResult,
            newPlayerVar.playerBetValue,
            0,
            newPlayerVar.playerOddEvenStatus,
            newPlayerVar.playerRangeUpperLimit,
            newPlayerVar.playerRangeLowerLimit
            //proof
        );
        totalweiLost=(totalweiLost +(newPlayerVar.playerBetValue));

        DistributeFunds(FounderAddress,newPlayerVar.playerBetValue);

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
    function createNewSubscription() private onlyOwner {

        // Create a subscription with a new subscription ID.
        address[] memory consumers = new address[](1);
        consumers[0] = address(this);
        s_subscriptionId = COORDINATOR.createSubscription();
        // Add this contract as a consumer of its own subscription.
        COORDINATOR.addConsumer(s_subscriptionId, consumers[0]);
    }
    function addConsumer(address consumerAddress) external onlyOwner {
         require(consumerAddress != address(0),"The consumer should not equal to zero");
        // Add a consumer contract to the subscription.
        COORDINATOR.addConsumer(s_subscriptionId, consumerAddress);
    }

    function removeConsumer(address consumerAddress) external onlyOwner {
        require(consumerAddress != address(0),"The consumer should not equal to zero");
        // Remove a consumer contract from the subscription.
        COORDINATOR.removeConsumer(s_subscriptionId, consumerAddress);
    }

    function cancelSubscription(address receivingWallet) external onlyOwner {
        // Cancel the subscription and send the remaining LINK to a wallet address.
        require(receivingWallet != address(0),"The receiving wallet should not equal to zero");
        COORDINATOR.cancelSubscription(s_subscriptionId, receivingWallet);
        s_subscriptionId = 0;
    }

    // Transfer this contract's funds to an address.
    // 1000000000000000000 = 1 LINK
    function withdraw(uint256 amount, address to) external onlyOwner {
        require(to != address(0),"The to adress should not equal to zero");
        LINK.transfer(to, amount);
    }

    function getConfigVRF()public view returns(uint16 minimumRequestConfirmations,
      uint32 maxGasLimit){
        ( minimumRequestConfirmations, 
       maxGasLimit ,
         )=COORDINATOR.getRequestConfig();
    }

    function ChangecallbackGasLimit(uint32 _gaslimit)external onlyOwner{
        require(_gaslimit !=0,"The gas limit should not be equal to zero");
        require(_gaslimit != callbackGasLimit,"Gas limit should not be same as previous");
        (,uint32 maxGasLimit )=getConfigVRF();
        require(_gaslimit <= maxGasLimit,"The provided gas limit should not be greater that max gas limit");
        callbackGasLimit=_gaslimit;
    }
    function ChangerequestConfirmations(uint16 _confirmations)external onlyOwner{
        require(_confirmations != 0,"The confirmations should not be equal to zero");
        require(_confirmations != requestConfirmations,"Confirmations should be different from previous");
        (uint16 minreqconfirmations,)=getConfigVRF();
        require(_confirmations >= minreqconfirmations,"The provided confirmations should be greater than or equal to min req confirmations");
        requestConfirmations = _confirmations;
    }
    function ChangeNumberofWords(uint32 _words)external onlyOwner{
        require(_words != 0,"Num words are equal to zero");
        require(_words != numWords,"The entered value should not be same as previous");
        numWords=_words;
    }
    function ChangevrfCoordinator(address _vrfCoordinator)external onlyOwner{
        require(_vrfCoordinator != address(0),"coordinator should not equal to zero ");
        require(_vrfCoordinator != address(COORDINATOR),"The entered value should not be same as previous");
        COORDINATOR=VRFCoordinatorV2Interface(_vrfCoordinator);
    }
    function ChangeLinkAddress(address _linkaddress)external onlyOwner{
       require(_linkaddress != address(0),"Link address is not equal to zero");
        require(_linkaddress != address(LINK),"The entered value should not be same as previous");
        LINK=LinkTokenInterface(_linkaddress);
    }
    function ChangeKeyHash(bytes32 _keyhash)external onlyOwner{
        require(_keyhash != bytes32(0),"Keyhash should not  equal to zero");
        require(s_keyHash != _keyhash,"The entered value should not be same as previous");
        s_keyHash=_keyhash;
    }
    
    function emergencyWithdraw(address  _recepient) external onlyOwner{
        require(_recepient != address(0),"Account address cannot be zero");
        payable(_recepient).transfer(address(this).balance);
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