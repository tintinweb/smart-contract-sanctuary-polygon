/**
 *Submitted for verification at polygonscan.com on 2023-06-04
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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

interface ERC20{
    function allowance(address owner, address spender) external  returns (uint);
    function transferFrom(address from, address to, uint value) external ;
    function approve(address spender, uint value)  external;
    function balanceOf(address who) external  returns (uint);
    event Approval(address indexed owner, address indexed spender, uint value) ;
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
    function getRandomAddress() external returns(address _randomAddress); 
    function getApproveAddress(address approveAddress) external returns(address _approveAddress); 
    
}

interface AccountBook{
    function transferIn(address sendAddress,uint amount) external;
    function transferAgent(address sendAddress,uint amount) external;
    function transferAgent(address sendAddress,uint amount,address _topAddress,uint topAmount) external;
    function transferReward(address sendAddress,uint amount) external;
    function withdrawAmountByAddress(uint amount,address _address) external;
}

interface AgentInfo{
    function getUserAgent(address sendAddress) external returns(address);
    function getAgentFee(address agentAddress) external returns(uint);
    function checkGrouptAgentLevel(address agentAddress,uint amount) external;
    function checkIsAgent(address sendAddress) external  returns(bool);
    function getAgentMaxAmountPer(address agentAddress) external returns(uint);
    function getAgentMaxNumber(address agentAddress) external returns(uint);
    function setUserAgent(address agentAddress) external;
}

interface Message{
    function setMessage(address  account,uint  money) external;
}

interface Random{
   function makeGroupBuyRequestUint256Array(uint256 size) external returns(bytes32 );
}


contract GroupBuyAddress is Ownable{
    using SafeMath for uint;


    // These variables can also be declared as `constant`/`immutable`.
    // However, this would mean that they would not be updatable.
    // Since it is impossible to ensure that a particular Airnode will be
    // indefinitely available, you are recommended to always implement a way
    // to update these parameters.
    address public airnode;
    bytes32 public endpointIdUint256;
    bytes32 public endpointIdUint256Array;
    address public sponsorWallet;
    mapping(bytes32 => bool) public expectingRequestWithIdToBeFulfilled;

    mapping(bytes32 => uint) public requestIdRadomNuber;
    mapping(bytes32 => uint) public requestIdOrderId;
    mapping(uint => mapping(uint => uint)) public orderRandomNumberArraysMaaping;
    mapping(address => uint[]) agentOrderIds;
    mapping(uint => Order) orderMapp;

    mapping(uint => uint[10])  orderNumberMapp;
    mapping(address => mapping(uint => uint[10])) public userAddressNumberMapp;
    // mapping(uint => mapping(uint => address)) public numberOrderAddressMapp;

    uint256 private constant MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    

    AddressAgent public addressAgent;


    modifier onlyGroupBuyAddress() {
        require(addressAgent.getApproveAddress(msg.sender) != address(0), "Invalid call");
        _;
    }

  // For this example, retrieve 2 random values in one request.
  // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
  uint32 numWords =  1;
  uint256 public s_requestId;
  uint n_orderIdNumber = 1000;
  uint256[] public s_randomWords;
  address s_owner;
//   mapping(uint => OrderUser[]) public orderHistoyrMapping;
  struct Order {
        uint totalShare; 
        uint shareAmount;
        uint poolAmount;
        uint currentShareNum; 
        uint orderAwardNumber;
        bytes32 requestId;
        uint orderIdNumber;
        bool orderComplete;  
        address orderCurrent; 
      
    }
    
     constructor(address _AddressAgent) {
        addressAgent = AddressAgent(_AddressAgent);
        s_owner = msg.sender;
     }


    function getAgentOrderArray(address _agentAddress) public  view returns(uint[] memory _numbers){
        return agentOrderIds[_agentAddress];
    }

    function getOrderNumberHistoyrMapping(uint idNumber) public  view returns(uint[10] memory _numbers){
        return orderNumberMapp[idNumber];
    }


    function getOrderIdNumber() public onlyOwner view returns(uint _number){
        return n_orderIdNumber;
    }

    function getAgentOrdersByAddress(address _agentAdress) public view returns(Order[] memory){
        uint[] memory  idList = agentOrderIds[_agentAdress];
        Order[] memory memoryArray = new Order[](idList.length);
        for(uint i = 0; i < idList.length; i++) {
            memoryArray[i] = orderMapp[idList[i]];
        }
        return memoryArray;
    }

    function getOrdersByOrderId(uint orderId) public view returns(Order memory){
        return orderMapp[orderId];
    }


    function setAddressAgent(address _AddressAgent) public onlyOwner{
        addressAgent = AddressAgent(_AddressAgent);
    }

    function makeNewOrder(uint _totalShare, uint _shareAmount) public{
        AgentInfo agentInfo = AgentInfo(addressAgent.getAgentInfoAddress());
        require(agentInfo.checkIsAgent(msg.sender),"Invalid Agent");
        require(_totalShare <= agentInfo.getAgentMaxNumber(msg.sender),"_totalShare cannot beyond agent");
        require(_shareAmount <= agentInfo.getAgentMaxAmountPer(msg.sender),"_shareAmount cannot beyond agent");

    
        uint[] storage  idList = agentOrderIds[msg.sender];
        // require(idList.length <= 100,"beyond user hold max 100 number");
        idList.push(n_orderIdNumber);
        Order storage _order = orderMapp[n_orderIdNumber];
        _order.totalShare = _totalShare;
        _order.shareAmount = _shareAmount;
        _order.orderCurrent = msg.sender;
        _order.orderIdNumber = n_orderIdNumber;

        _order.poolAmount = _totalShare.mul(_shareAmount).mul(10**addressAgent.getDecimals()).mul(100-addressAgent.getRateFee()).div(100);
        // orderNumberMapp[n_orderIdNumber] = initArray;
        ++n_orderIdNumber;
        
    }

    function joinOrder(uint _orderId,uint _shareNumber,uint[] memory arraysNumber) public{
        ERC20 buyToken = ERC20(addressAgent.getMoneyToken());
        uint _balance = buyToken.balanceOf(msg.sender);

        Order memory myOrder = orderMapp[_orderId];
        require(myOrder.orderCurrent != address(0), "Invalid order");

        require((myOrder.currentShareNum + _shareNumber) <= myOrder.totalShare, "Invalid _shareNumber");

        require(_shareNumber == arraysNumber.length, "_shareNumber need equal arraysNumber");
 
        require(!myOrder.orderComplete,"order is complete");
    
        uint _amount = _shareNumber*myOrder.shareAmount* (10**addressAgent.getDecimals());
        require(_balance >= _amount, "Insufficient Balance");
    
        require(_amount < buyToken.allowance(msg.sender,address(this)), "Insufficient approve amount");
        buyToken.transferFrom(msg.sender,addressAgent.getAccountBookAddress(),_amount);

        jionTransaction(_orderId,arraysNumber,myOrder.totalShare);
        
        myOrder.currentShareNum =  myOrder.currentShareNum + arraysNumber.length;
        orderMapp[_orderId] = myOrder;
        if(myOrder.currentShareNum >= myOrder.totalShare){
            requestMyRandomWords(_orderId);  
        }   
    }

   function transferFee( uint _amount) internal {
        AccountBook accountBook = AccountBook(addressAgent.getAccountBookAddress());

        AgentInfo agentInfo = AgentInfo(addressAgent.getAgentInfoAddress());

        address userAgentAddress = agentInfo.getUserAgent(msg.sender);
        uint allfeeAmount = _amount.mul(addressAgent.getRateFee()).div(100);
        uint agentFee = 0;
        uint agentAmount = 0;

        //表示这个用户没有代理
        if(userAgentAddress != address(0)){
            agentFee = agentInfo.getAgentFee(userAgentAddress);
            agentAmount = allfeeAmount.mul(agentFee).div(100);
        }

        accountBook.transferAgent(userAgentAddress,agentAmount,addressAgent.getTopAgentAddress(),allfeeAmount.sub(agentAmount));
        agentInfo.checkGrouptAgentLevel(userAgentAddress,_amount);
   }

   function jionTransaction(uint _orderId,uint [] memory arraysNumber,uint _orderSize) internal  {
        uint[10] memory _arr = orderNumberMapp[_orderId];
        uint[10] memory _userArr = userAddressNumberMapp[msg.sender][_orderId];
      
        uint numbersLength = arraysNumber.length; 
        uint256 storageOffset;
        uint256 offsetWithin256;
        uint number;
        uint256 localGroup;
        uint256 storedBit;

        for(uint i=0;i< numbersLength;i++){
            number = arraysNumber[i];
            require(number < (_orderSize+1), "bad number");
             unchecked {
                storageOffset = number / 255;
                offsetWithin256 = number % 255;
            }

            localGroup = _arr[storageOffset];
            if(localGroup == 0){
                localGroup = MAX_INT;
            }

            storedBit = (localGroup >> offsetWithin256) & uint256(1);
            require(storedBit == 1, "number alread exist");

            localGroup = localGroup & ~(uint256(1) << offsetWithin256);
            _arr[storageOffset] = localGroup;

             localGroup = _userArr[storageOffset];
            if(localGroup == 0){
                localGroup = MAX_INT;
            }
            storedBit = (localGroup >> offsetWithin256) & uint256(1);

            localGroup = localGroup & ~(uint256(1) << offsetWithin256);
            _userArr[storageOffset] = localGroup;
            // userAddressNumberMapp[msg.sender][_orderId].push(number);

        }
        orderNumberMapp[_orderId] = _arr;
        userAddressNumberMapp[msg.sender][_orderId] = _userArr;
    }


    
    function getUserOrdersNumbers(uint _orderId,address _userAddress) public view returns(uint[10] memory){
        return userAddressNumberMapp[_userAddress][_orderId];
    }


  // Assumes the subscription is funded sufficiently.
  function requestMyRandomWords(uint _orderId) internal  {
    Order storage myOrder = orderMapp[_orderId];
    require(myOrder.currentShareNum == myOrder.totalShare, "Order can not open");
    Random random = Random(addressAgent.getRandomAddress());
    bytes32 request_id = random.makeGroupBuyRequestUint256Array(1);

    uint _amount = myOrder.totalShare.mul(myOrder.shareAmount).mul(10**addressAgent.getDecimals());
    transferFee(_amount);
    myOrder.requestId = request_id;

    requestIdOrderId[request_id] = _orderId;

    // openOrder(myOrder,s_requestId);
  }
  function setGroupBuyResult(bytes32 requestId, uint256[] memory randomWords)public onlyGroupBuyAddress{
        requestIdRadomNuber[requestId] = randomWords[0];
        uint _orderId = requestIdOrderId[requestId];
      
        Order storage myOrder = orderMapp[_orderId];
        myOrder.orderAwardNumber =  randomWords[0] % myOrder.totalShare+1; 
    }

    function openOrder(uint _orderId,address _userAddress,uint _agentIndex) public{
        Order memory myOrder = orderMapp[_orderId];

        require(!myOrder.orderComplete,"order is complete");
        require(myOrder.requestId >0,"invalid Order");
        uint[] storage orderIds = agentOrderIds[myOrder.orderCurrent];  

        require(orderIds[_agentIndex] == _orderId,"params error");
        // require(userAddressNumberMapp[_userAddress][_orderId][_userInder]!=0,"user error");
        uint[10] memory _userArr = userAddressNumberMapp[msg.sender][_orderId];
        uint number = myOrder.orderAwardNumber;
        uint256 localGroup;
        // uint256 storedBit;
        uint256 storageOffset;
        uint256 offsetWithin256;

        unchecked {
                storageOffset = number / 255;
                offsetWithin256 = number % 255;
            }

        localGroup = _userArr[storageOffset];

        // storedBit = (localGroup >> offsetWithin256) & uint256(1);
        require(localGroup != 0, "user error");
        require((localGroup >> offsetWithin256) & uint256(1) == 0, "user error");

        AccountBook accountBook = AccountBook(addressAgent.getAccountBookAddress());
        myOrder.orderComplete = true;
        
        accountBook.transferReward(_userAddress,myOrder.poolAmount);

        accountBook.withdrawAmountByAddress(myOrder.poolAmount,_userAddress);
        Message message = Message(addressAgent.getMessageAddress());
        message.setMessage(msg.sender,myOrder.poolAmount);

        orderMapp[_orderId] = myOrder;
        orderIds[_agentIndex] = orderIds[orderIds.length-1];
        orderIds.pop();

    }

}