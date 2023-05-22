/**
 *Submitted for verification at polygonscan.com on 2023-05-22
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    /**
      * @dev The Ownable constructor sets the original `owner` of the contract to the sender
      * account.
      */
    constructor() {
        owner = msg.sender;
    }

    /**
      * @dev Throws if called by any account other than the owner.
      */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


interface ERC20{
    function allowance(address owner, address spender) external  returns (uint);
    function transferFrom(address from, address to, uint value) external ;
    function transfer(address _to, uint _value) external;
    function approve(address spender, uint value)  external;
    function balanceOf(address who) external  returns (uint);
    event Approval(address indexed owner, address indexed spender, uint value) ;
}

interface AccountBook{
    function transferIn(address sendAddress,uint amount) external;
    function transferAgent(address sendAddress,uint amount) external;
    function transferAgent(address sendAddress,uint amount,address _topAddress,uint topAmount) external;
    function transferReward(address sendAddress,uint amount) external;
    function withdrawAmountByAddress(uint amount,address _address) external;

    function transferAmountByAddress(address _address,uint amount) external;
}

interface AgentInfo{
    function getUserAgent(address sendAddress) external returns(address);
    function getAgentFee(address agentAddress) external returns(uint);
    function checkAgentLevel(address agentAddress,uint amount) external;
    function checkIsAgent(address sendAddress) external  returns(bool);
    function getAgentMaxAmountPer(address agentAddress) external returns(uint);
    function getAgentMaxNumber(address agentAddress) external returns(uint);
    function setUserAgent(address agentAddress) external;
}

interface Random{
   function makeRequestUint256Array(uint256 size) external returns(bytes32 );
}

interface AddressAgent{
    function getGroupBuyAddress() external  returns(address);
    function getMoneyToken() external  returns(address _moneyTokenAddress);
    function getAccountBookAddress() external returns(address _accountBookn);
    function getAgentInfoAddress() external returns(address _agentInfoAddress);
    function getMessageAddress() external returns(address _messageAddress);
    function getDecimals() external view returns(uint _decimals);
    function getTopAgentAddress() external view returns(address _topAgentAddress);
    function getRateFee() external view returns(uint _rateFee);
    function getApproveAddress(address approveAddress) external returns(address _approveAddress); 
    function getRandomAddress() external returns(address _randomAddress); 
    function getTicketGameAddress() external returns(address _randomAddress); 
    
}

interface TicketGame{
   function openTicket(uint poolAmount) external;
}


contract DiceGame is Ownable {
   AddressAgent public addressAgent;
   Random public random;
 
   using SafeMath for uint;

   uint public ticketLoop = 100;
   

   uint public capitalAmount = 100 * (10**18);
   mapping(uint => mapping(address => uint))  rankAddressAmount;

    mapping(uint => address[]) public quateAddress;
    uint public totalPersonAwardNumber = 3;
    uint[] public awarPersondRates;
 
    uint public poolAwardAmount = 100 * (10**18);

    uint public totalRate = 60;
    uint public ticketRate = 30;
    uint public gameRateFee =1;

    uint public guessMaxAmount = 100;

    mapping(address => uint)  public userQuate;


    uint gameSmallSide = 100;
    uint gameBigSide = 200;

    bool public gameBollPuase = false;


    uint public bigSmallRate = 2;
    uint public cheetahRate = 20;
    uint public singleBigSmallRate = 6;
    uint public allAmountRate = 12;
    uint public threeNumbersRate = 180;



    uint defualtNumber = 101;


    struct TicketPoolRank {
        uint amount;
        address _address;
      
    }

    uint[5]  totalResult;
    mapping(bytes32 => address) public requestIdAddress;
    mapping(address => uint) public addressBuyInfo;


     
    constructor(address _AddressAgent)  {
        addressAgent = AddressAgent(_AddressAgent);

     }


    modifier onlyGroupBuyAddress() {
        require(addressAgent.getApproveAddress(msg.sender) != address(0), "Invalid call");
        _;
    }


    modifier gameBollNotPuase() {
        require(!gameBollPuase, "gameBoll is Puase");
        _;
    }

    

 

    function setAwarPersondRates(uint[] memory _awarPersondRates) public onlyOwner{
        awarPersondRates = _awarPersondRates;  
        totalPersonAwardNumber = _awarPersondRates.length; 
    }

    function getAwarPersondRates() public view returns(uint[] memory _rate){
        return awarPersondRates;    
    }

    function getTotalResult() public view  returns( uint[5] memory _totoal){
        return totalResult;
    }

    function getQuateAddress(uint loop) public view  returns( address[] memory ){
        return quateAddress[loop];
    }

   function getQuateAddressIndex(uint loop,uint index) public view  returns( address ){
        return quateAddress[loop][index];
    }
    
    function getQuateAddressLength(uint loop) public view  returns(uint ){
        return quateAddress[loop].length;
    }
    
    function setMoneyRates(uint _totalRate,uint _ticketRate,uint _gameRateFee) public onlyOwner{
         totalRate = _totalRate;
         ticketRate = _ticketRate;
        gameRateFee = _gameRateFee;
    }

    function setRates(uint _bigSmallRate,uint _cheetahRate,uint _singleBigSmallRate,uint _allAmountRate,uint _threeNumbersRate) public onlyOwner{
        bigSmallRate = _bigSmallRate;
        cheetahRate = _cheetahRate;
        singleBigSmallRate = _singleBigSmallRate;
        allAmountRate = _allAmountRate;
        threeNumbersRate = _threeNumbersRate;
    }

    function setUserClear(address _address) public onlyGroupBuyAddress{
        addressBuyInfo[_address] = 0;
    }

    function setGuessMaxAmount(uint _guessMaxAmount)public onlyOwner{
        guessMaxAmount = _guessMaxAmount;
    }

    function getGuessMaxAmount()public view returns(uint){
        return guessMaxAmount;
    }

    function getUserInfo(uint number) public pure returns(uint[4] memory _result){
        uint buyType = number/(10**30);
        uint side = number%(10**29)/(10**20);
        uint buyAmount = number%(10**19)/(10**10);
        uint result =  number%(10**3);
        return [buyType,side,buyAmount,result];
    }

    function setTotalResult(uint result) internal {
        uint temptIndex;
        for(uint i=0;i<5;i++){
            if(totalResult[i]%1000 <63){
                temptIndex = totalResult[i]%1000;
                totalResult[i] -= totalResult[i]%1000;  
                if(temptIndex ==0){
                    temptIndex = 6;
                }
                if(totalResult[i]%(10**(temptIndex+3))/10**(temptIndex) !=0){
                    totalResult[i] -= totalResult[i]%(10**(temptIndex+3))/10**(temptIndex)*10**(temptIndex+3);
                }

                totalResult[i] += (result*10**(temptIndex))+temptIndex+3;
                if(temptIndex+3 >62){
                    if(i == 4){
                        totalResult[0] -= totalResult[0]%1000;  
                    }else{
                        totalResult[i+1] -= totalResult[i+1]%1000;  
                    }   
                }
                break;
            }
        }
    }

 
    function setDiceResult(bytes32 requestId, uint256[] memory qrngUint256Array)public  onlyGroupBuyAddress{
        require(
            requestIdAddress[requestId] !=address(0),
            "Request ID not known"
        );



        uint[4] memory userInfo = getUserInfo(addressBuyInfo[requestIdAddress[requestId]]);
        AccountBook accountBook = AccountBook(addressAgent.getAccountBookAddress()); 
        
 
        if(userInfo[0] == 1 ){
     
            uint[2] memory result = guessBigSmallResult(userInfo[1],qrngUint256Array);
            if(result[0] == 0 && result[1] != 0){
                accountBook.transferAmountByAddress(requestIdAddress[requestId],userInfo[2]*(10**addressAgent.getDecimals())*bigSmallRate);
                poolAwardAmount -= userInfo[2]*bigSmallRate*(10**addressAgent.getDecimals());     
            }
            addressBuyInfo[requestIdAddress[requestId]] = addressBuyInfo[requestIdAddress[requestId]] -defualtNumber+result[1]+result[0]*(10**3);
            setTotalResult(result[1]);
        }else if(userInfo[0] == 2){
            uint[2] memory result = guessCheetahResult(qrngUint256Array);
            if(result[0] == 0 && result[1] != 0){
                accountBook.transferAmountByAddress(requestIdAddress[requestId],userInfo[2]*(10**addressAgent.getDecimals())*cheetahRate);
                poolAwardAmount -= userInfo[2]*(10**addressAgent.getDecimals())*cheetahRate;
            }
            addressBuyInfo[requestIdAddress[requestId]] = addressBuyInfo[requestIdAddress[requestId]] -defualtNumber+result[1]+result[0]*(10**3);
            setTotalResult(result[1]);
        }else if(userInfo[0] == 3){
            uint[2] memory result = guessSingleBigSmallResult(userInfo[1],qrngUint256Array);
            if(result[0] == 0 && result[1] != 0){
                accountBook.transferAmountByAddress(requestIdAddress[requestId],userInfo[2]*(10**addressAgent.getDecimals())*singleBigSmallRate);
                poolAwardAmount -= userInfo[2]*(10**addressAgent.getDecimals())*singleBigSmallRate;
            }
            addressBuyInfo[requestIdAddress[requestId]] = addressBuyInfo[requestIdAddress[requestId]] -defualtNumber+result[1]+result[0]*(10**3);
             setTotalResult(result[1]);
        }else if(userInfo[0] == 4){
            uint[2] memory result = guessAllAmountResult(userInfo[1],qrngUint256Array);
            if(result[0] == 0 && result[1] != 0){
                accountBook.transferAmountByAddress(requestIdAddress[requestId],userInfo[2]*(10**addressAgent.getDecimals())*allAmountRate);
                poolAwardAmount -= userInfo[2]*(10**addressAgent.getDecimals())*allAmountRate;
            }
            addressBuyInfo[requestIdAddress[requestId]] = addressBuyInfo[requestIdAddress[requestId]] -defualtNumber+result[1]+result[0]*(10**3);
             setTotalResult(result[1]);
        }else if(userInfo[0] == 5){
            uint[2] memory result = guessThreeNumbersResult(userInfo[1],qrngUint256Array);
            if(result[0] == 0 && result[1] != 0){
                accountBook.transferAmountByAddress(requestIdAddress[requestId],userInfo[2]*(10**addressAgent.getDecimals())*threeNumbersRate);
                poolAwardAmount -= userInfo[2]*(10**addressAgent.getDecimals())*threeNumbersRate;
            }
            addressBuyInfo[requestIdAddress[requestId]] = addressBuyInfo[requestIdAddress[requestId]] -defualtNumber+result[1]+result[0]*(10**3);
             setTotalResult(result[1]);
        }
    }


    function getNumberResult(uint _number) public view  returns(uint){
        uint number = uint(keccak256(abi.encodePacked(_number,block.timestamp,block.difficulty)));
        return number%10000000000*6/10000000000+1;
    }

    function guessBigSmallResult(uint side,uint256[] memory qrngUint256Array) public view returns(uint[2] memory){
      
        uint g1 = getNumberResult(qrngUint256Array[0]%(10**20)/(10**10));
        uint g2 = getNumberResult(qrngUint256Array[0]%(10**30)/(10**20));
        uint g3 = getNumberResult(qrngUint256Array[0]%(10**40)/(10**30));
        uint result = 1;
        if(!(g1 == g2 && g2 == g3)){
            uint  number = g1+g2+g3;
            if(side == gameSmallSide && number<=9){
                result = 0;
            }

            if(side == gameBigSide && number >= 10){
                result = 0;
            }
        }
        return [result,g1*100+g2*10+g3];
    }

    function guessCheetahResult(uint256[] memory qrngUint256Array) public view returns(uint[2] memory){
        uint g1 = getNumberResult(qrngUint256Array[0]%(10**20)/(10**10));
        uint g2 = getNumberResult(qrngUint256Array[0]%(10**30)/(10**20));
        uint g3 = getNumberResult(qrngUint256Array[0]%(10**40)/(10**30));
        uint result = 1;

        if((g1 == g2 && g2 == g3)){
            result = 0;
        }

        return [result,g1*100+g2*10+g3];
    }
  
  function guessSingleBigSmallResult(uint sideNumber,uint256[] memory qrngUint256Array) public view returns(uint[2] memory){
       
        uint result = 1;
        uint g1 = getNumberResult(qrngUint256Array[0]%(10**20)/(10**10));
        uint g2 = getNumberResult(qrngUint256Array[0]%(10**30)/(10**20));
        uint g3 = getNumberResult(qrngUint256Array[0]%(10**40)/(10**30));
       

        uint[3] memory arrays = [sideNumber/(10**6),sideNumber%(10**7)/(10*3),sideNumber%(10*3)];
         if(arrays[0] == gameSmallSide){
           result = g1<=3?0:1; 
        }else{
            result = g1>=4?0:1;  
        }

        if(result ==0){
            if(arrays[1] == gameSmallSide){
                result = g2<=3?0:1; 
            }else{
                result = g2>=4?0:1;  
            }
        }
       
        if(result ==0){
            if(arrays[2] == gameSmallSide){
                result = g3<=3?0:1; 
            }else{
                result = g3>=4?0:1;  
            }
        }

        return [result,g1*100+g2*10+g3];
    }

   function guessAllAmountResult(uint resultNumber,uint256[] memory qrngUint256Array) public view returns(uint[2] memory){
   
        uint g1 = getNumberResult(qrngUint256Array[0]%(10**20)/(10**10));
        uint g2 = getNumberResult(qrngUint256Array[0]%(10**30)/(10**20));
        uint g3 = getNumberResult(qrngUint256Array[0]%(10**40)/(10**30));
        uint result = 1;

        if(resultNumber == (g1+g2+g3)){
           result = 0; 
        }

        return [result,g1*100+g2*10+g3];
    } 

    function guessThreeNumbersResult(uint resultNumber,uint256[] memory qrngUint256Array) public view returns(uint[2] memory){
        
        uint g1 = getNumberResult(qrngUint256Array[0]%(10**20)/(10**10));
        uint g2 = getNumberResult(qrngUint256Array[0]%(10**30)/(10**20));
        uint g3 = getNumberResult(qrngUint256Array[0]%(10**40)/(10**30));
        uint result = 1;

        uint[3] memory arrays = [resultNumber/100,resultNumber%100/10,resultNumber%10];
        if(arrays[0] == g1 && arrays[1] == g2 && arrays[2] == g3){
           result = 0; 
        }

        return [result,g1*100+g2*10+g3];
    }

    function openCurrentPool() public onlyGroupBuyAddress{
        AccountBook accountBook = AccountBook(addressAgent.getAccountBookAddress());
        uint poolAmount = getCurrentLoopAmount();  
 
        uint totoalAward = poolAmount.div(100)*totalRate;
        accountBook.transferAgent(addressAgent.getTopAgentAddress(),poolAmount - totoalAward);
        poolAwardAmount = 0;
        
        uint personAward = totoalAward.div(100).mul(100 - ticketRate);
        for(uint i=0;i<totalPersonAwardNumber;i++){
            if(i < quateAddress[ticketLoop].length){
                if(quateAddress[ticketLoop][i] != address(0)){
                    accountBook.transferAmountByAddress(quateAddress[ticketLoop][i],personAward.div(100).mul(awarPersondRates[i]));
                    rankAddressAmount[ticketLoop][quateAddress[ticketLoop][i]] = personAward.div(100).mul(awarPersondRates[i]);
                }
            }
            
        }
        TicketGame ticketGame = TicketGame(addressAgent.getTicketGameAddress());
        ticketGame.openTicket(totoalAward-personAward);  
        ticketLoop++;      
        setCapitalAmount(200);
    }

    function  setCapitalAmount(uint _capitalAmount) public onlyGroupBuyAddress{
        capitalAmount = _capitalAmount*(10**addressAgent.getDecimals());
        poolAwardAmount = _capitalAmount*(10**addressAgent.getDecimals());
    }

    function  getCurrentLeftAmount() public view returns(uint ){
        return poolAwardAmount;
    }

    function getRankAddressAmount(uint _ticketLoop,address _address)public view returns(uint){
        return rankAddressAmount[_ticketLoop][_address];
    }

  function getRankAddressAmounts(uint _ticketLoop)public view returns(TicketPoolRank[] memory _ticketPoolRank){
    _ticketPoolRank = new TicketPoolRank[](quateAddress[_ticketLoop].length);
      for(uint i=0;i<quateAddress[_ticketLoop].length;i++){
          if(_ticketLoop == ticketLoop){
            uint myTicketLoop = userQuate[quateAddress[_ticketLoop][i]]%(10**19)/(10**10);
            uint loopQuate = userQuate[quateAddress[_ticketLoop][i]]%(10**9);
            if(myTicketLoop == _ticketLoop){
               _ticketPoolRank[i].amount = loopQuate;     
            }
            
          }else{
            _ticketPoolRank[i].amount = rankAddressAmount[_ticketLoop][quateAddress[_ticketLoop][i]];
          }
        
         _ticketPoolRank[i]._address = quateAddress[_ticketLoop][i]; 
      }
      
        return _ticketPoolRank;
    }
    
    
  
    function  getCurrentLoopAmount() public view returns(uint ){
        if(poolAwardAmount>capitalAmount){
            return poolAwardAmount - capitalAmount;
        }
        return 0;
    }

    function  userCanGetGoing(address _userAddress) public view returns(bool ){
        uint result = addressBuyInfo[_userAddress];
        if(result == 0){
            return true;
        }
        
        return result%1000 != defualtNumber;
    }




    function guessBigSmall( uint _buyAmount, uint _side) public gameBollNotPuase {
        require(_buyAmount <= guessMaxAmount, "Insufficient Balance");
        require(userCanGetGoing(msg.sender), "user need waiting result");
        
        ERC20 buyToken = ERC20(addressAgent.getMoneyToken());
        uint _balance = buyToken.balanceOf(msg.sender);

        uint _amount =_buyAmount* (10**addressAgent.getDecimals());

        require(_amount*2 < getCurrentLeftAmount(), "Insufficient game pool");
        require(_balance >= _amount, "Insufficient Balance");
        require(_amount < buyToken.allowance(msg.sender,address(this)), "Insufficient approve amount");
        buyToken.transferFrom(msg.sender,addressAgent.getAccountBookAddress(),_amount);

        random = Random(addressAgent.getRandomAddress());
       
        addressBuyInfo[msg.sender] = 1*(10**30)+_side*(10**20)+_buyAmount*(10**10)+defualtNumber;
        requestIdAddress[random.makeRequestUint256Array(1)] = msg.sender;
 
        transferFee(_amount);
        poolAwardAmount += _amount;
        setCurrentLoop(_buyAmount);
    }


     function guessCheetah(uint _buyAmount) public gameBollNotPuase {
        require(_buyAmount <= guessMaxAmount, "Insufficient Balance");
        require(userCanGetGoing(msg.sender), "user need waiting result");

        ERC20 buyToken = ERC20(addressAgent.getMoneyToken());
        uint _balance = buyToken.balanceOf(msg.sender);


        uint _amount =_buyAmount* (10**addressAgent.getDecimals());

        require(_amount*cheetahRate < getCurrentLeftAmount(), "Insufficient game pool");
        require(_balance >= _amount, "Insufficient Balance");
        require(_amount < buyToken.allowance(msg.sender,address(this)), "Insufficient approve amount");

        buyToken.transferFrom(msg.sender,addressAgent.getAccountBookAddress(),_amount);
        random = Random(addressAgent.getRandomAddress());
        // bytes32 requestId = random.makeRequestUint256Array(1);

        // UserBuyInfo memory userBuyInfo = gameUserBuyInfo[requestId];
        // userBuyInfo.buyType = 2;
        // userBuyInfo.buyAmount = _amount;
        // userBuyInfo.buyAddress = msg.sender;

        addressBuyInfo[msg.sender] = 2*(10**30)+1*(10**20)+_buyAmount*(10**10)+defualtNumber;
        requestIdAddress[random.makeRequestUint256Array(1)] = msg.sender;

   
       transferFee(_amount);
        poolAwardAmount += _amount;
        setCurrentLoop(_buyAmount);
    
    }

   

     function guessSingleBigSmall(uint _buyAmount,uint[] memory arrays) public gameBollNotPuase{
        require(_buyAmount <= guessMaxAmount, "Insufficient Balance");
        require(userCanGetGoing(msg.sender), "user need waiting result");

        ERC20 buyToken = ERC20(addressAgent.getMoneyToken());
        uint _balance = buyToken.balanceOf(msg.sender);
        uint _amount =_buyAmount* (10**addressAgent.getDecimals());

        require(_amount*singleBigSmallRate < getCurrentLeftAmount(), "Insufficient game pool");
        require(_balance >= _amount, "Insufficient Balance");
        require(arrays.length ==3, "error arrays");
        require(_amount < buyToken.allowance(msg.sender,address(this)), "Insufficient approve amount");

        buyToken.transferFrom(msg.sender,addressAgent.getAccountBookAddress(),_amount);
        random = Random(addressAgent.getRandomAddress());
      
        addressBuyInfo[msg.sender] = 3*(10**30)+(arrays[0]*1000000+ arrays[1]*1000+arrays[2])*(10**20)+_buyAmount*(10**10)+defualtNumber;
        requestIdAddress[random.makeRequestUint256Array(1)] = msg.sender;


        transferFee(_amount);
        poolAwardAmount += _amount;
        setCurrentLoop(_buyAmount);
    }

 

     function guessAllAmount(uint _buyAmount,uint number) public gameBollNotPuase{
        require(_buyAmount <= guessMaxAmount, "Insufficient Balance");
        require(userCanGetGoing(msg.sender), "user need waiting result");

        ERC20 buyToken = ERC20(addressAgent.getMoneyToken());
        uint _balance = buyToken.balanceOf(msg.sender);

        uint _amount =_buyAmount* (10**addressAgent.getDecimals());
        require(_amount* allAmountRate < getCurrentLeftAmount(), "Insufficient game pool");

        require(_balance >= _amount, "Insufficient Balance");
        require(number >2, "error number");
        require(number <19, "error number");
        require(_amount < buyToken.allowance(msg.sender,address(this)), "Insufficient approve amount");

        buyToken.transferFrom(msg.sender,addressAgent.getAccountBookAddress(),_amount);
        random = Random(addressAgent.getRandomAddress());
       

        addressBuyInfo[msg.sender] = 4*(10**30)+number*(10**20)+_buyAmount*(10**10)+defualtNumber;
        requestIdAddress[random.makeRequestUint256Array(1)] = msg.sender;


        transferFee(_amount);
        poolAwardAmount += _amount;
        setCurrentLoop(_buyAmount);
    }

 

     function guessThreeNumbers(uint _buyAmount,uint[] memory arrays) public gameBollNotPuase{
        require(_buyAmount <= guessMaxAmount, "Insufficient Balance");
        require(userCanGetGoing(msg.sender), "user need waiting result");

        ERC20 buyToken = ERC20(addressAgent.getMoneyToken());
        uint _balance = buyToken.balanceOf(msg.sender);


        uint _amount =_buyAmount* (10**addressAgent.getDecimals());
        
        require(_amount* threeNumbersRate < getCurrentLeftAmount(), "Insufficient game pool");

        require(_balance >= _amount, "Insufficient Balance");
        require(arrays.length ==3, "error arrays");
        require(_amount < buyToken.allowance(msg.sender,address(this)), "Insufficient approve amount");

        buyToken.transferFrom(msg.sender,addressAgent.getAccountBookAddress(),_amount);

        random = Random(addressAgent.getRandomAddress());

        addressBuyInfo[msg.sender] = 5*(10**30)+(arrays[0]*100+ arrays[1]*10+arrays[2])*(10**20)+_buyAmount*(10**10)+defualtNumber;
        requestIdAddress[random.makeRequestUint256Array(1)] = msg.sender;


        transferFee(_amount);
        poolAwardAmount += _amount;

        setCurrentLoop(_buyAmount);
    }

    function addUserQuate(address userAddress,uint _quate) public onlyGroupBuyAddress{
        userQuate[userAddress] += (_quate)*(10**20);
    }

    function reduceUserQuate(address userAddress,uint _quate) public onlyGroupBuyAddress{
        uint totalQuate = userQuate[userAddress]/(10**20);
        require(totalQuate >= _quate, "Insufficient Balance");
        userQuate[userAddress] -= (_quate)*(10**20);
    }


    function setCurrentLoop(uint _buyAmount) internal {
        
        uint totalQuate = userQuate[msg.sender]/(10**20);
        uint myTicketLoop = userQuate[msg.sender]%(10**19)/(10**10);
        uint loopQuate = userQuate[msg.sender]%(10**9);

        if(myTicketLoop == ticketLoop){
            loopQuate = loopQuate+_buyAmount;
            userQuate[msg.sender] = (totalQuate+_buyAmount)*(10**20)  + ticketLoop*(10**10)+ (loopQuate);
        }else{
            loopQuate = _buyAmount;
            userQuate[msg.sender] = (totalQuate+_buyAmount)*(10**20)  + ticketLoop*(10**10)+ (loopQuate);
        }

        if(!getRankHasAddress(msg.sender)){
            if(quateAddress[ticketLoop].length >= totalPersonAwardNumber){
                if(loopQuate > getMinAmount()){
                quateAddress[ticketLoop][getMinAmountIndex()] = msg.sender; 
                }
            }else {
                quateAddress[ticketLoop].push(msg.sender);
            }
        }
        
    }

    function getRankHasAddress(address _address) public view returns(bool ){
         bool flag = false;
        for (uint i= 0; i<quateAddress[ticketLoop].length; i++){
            if(quateAddress[ticketLoop][i] == _address){
                flag = true;
            }
        }
        return flag;
    }

    function getMinAmount() public view returns(uint ){

        uint myTicketLoop = userQuate[quateAddress[ticketLoop][0]]%(10**19)/(10**10);
        uint loopQuate = userQuate[quateAddress[ticketLoop][0]]%(10**9);

        uint flag = 0;
        if(myTicketLoop ==ticketLoop){
            flag = loopQuate;
        }

        for (uint i= 0; i<quateAddress[ticketLoop].length; i++){

            myTicketLoop = userQuate[quateAddress[ticketLoop][i]]%(10**19)/(10**10);
            loopQuate = userQuate[quateAddress[ticketLoop][i]]%(10**9);
            if(myTicketLoop ==ticketLoop){
                if(flag > loopQuate){
                    flag = loopQuate;
                }
            }else{
                flag = 0;
            }
        }
        return flag;
    }

     function getMinAmountIndex() internal view returns(uint ){
        uint myTicketLoop = userQuate[quateAddress[ticketLoop][0]]%(10**19)/(10**10);
        uint loopQuate = userQuate[quateAddress[ticketLoop][0]]%(10**9);
        uint flag = 0;
        if(myTicketLoop ==ticketLoop){
            flag = loopQuate;
        }

        uint flagIndex = 0;
        for (uint i= 0; i<quateAddress[ticketLoop].length; i++){
            myTicketLoop = userQuate[quateAddress[ticketLoop][i]]%(10**19)/(10**10);
            loopQuate = userQuate[quateAddress[ticketLoop][i]]%(10**9);
            if(myTicketLoop ==ticketLoop){
                if(flag > loopQuate){
                    flag = loopQuate;
                    flagIndex = i;
                }
            }else{
                flagIndex = i;
            }
        }
        return flagIndex;
    }

     function transferFee( uint _amount) internal {
        AccountBook accountBook = AccountBook(addressAgent.getAccountBookAddress());

        AgentInfo agentInfo = AgentInfo(addressAgent.getAgentInfoAddress());

        address userAgentAddress = agentInfo.getUserAgent(msg.sender);
        uint allfeeAmount = _amount.mul(gameRateFee).div(100);
        uint agentFee = 0;
        uint agentAmount = 0;

        if(userAgentAddress != address(0)){
            agentFee = agentInfo.getAgentFee(userAgentAddress);
            agentAmount = allfeeAmount.mul(agentFee).div(100);
        }

        accountBook.transferAgent(userAgentAddress,agentAmount,addressAgent.getTopAgentAddress(),allfeeAmount.sub(agentAmount));
        agentInfo.checkAgentLevel(userAgentAddress,_amount);
   }

  
}