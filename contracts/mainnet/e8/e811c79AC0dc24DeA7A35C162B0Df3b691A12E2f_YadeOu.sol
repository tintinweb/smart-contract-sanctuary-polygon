/**
 *Submitted for verification at polygonscan.com on 2023-07-17
*/

// SPDX-License-Identifier: UNLICENSE
pragma solidity >=0.8.0 <0.9.0;

contract YadeOu {
    using SafeMath for uint256;
    mapping(string => OrderOne)  orders;
    mapping(address => string[]) ordersIdByAddress;
    mapping(address =>InfoZekr)  infoByAddress;
    mapping(string=>InfoZekr) infoById;
    int[14] indexz;
    address owner;
    event OrderPlaced(
        address indexed customer,
        uint amount,
        bool paid
    );
  
     constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }
    modifier activeId(){
    require(infoByAddress[msg.sender].active==true,"It's Not Active");
    _;
    }

   struct InfoZekr{
        string  UniqId;
        uint constPay;
        int indexZekr;
        int constZekr;
        uint cPay;
        uint  startTime;
        uint cPeriod;
        uint pPeriod;
        bool  active;
    }

    struct OrderOne {
        address customer;
        uint amount;
        bool paid;
    }
    int  constantVersion = 1; // Update version
    function update(int version) public onlyOwner() {
    constantVersion = version;
    }
    
    string private constantMessage = "";// Send notification massage
    function notifiMassage(string memory message) public onlyOwner {
        constantMessage = message;
    }

    function clearMessage() public onlyOwner {
        constantMessage = "";
    }
    function getIndexZ() public view onlyOwner returns (int[14] memory) {
        return indexz;
    }
    

    function placeOrder(string calldata _orderId,int _indexZekr,int _payPeriod) payable external {
        require(msg.value >= 0, "Payment amount must be greater than 0");
    int _constZekr;
    if (_indexZekr == 1) {
        indexz[0]++;
        _constZekr = 41;
    } else if (_indexZekr == 2) {
         indexz[1]++;
        _constZekr = 32;
    } else if (_indexZekr == 3) {
         indexz[2]++;
        _constZekr = 44;
    } else if (_indexZekr == 4) {
         indexz[3]++;
        _constZekr = 56;
    } else if (_indexZekr == 5) {
         indexz[4]++;
        _constZekr = 71;
    } else if (_indexZekr == 6) {
         indexz[5]++;
        _constZekr = 23;
    } else if (_indexZekr == 7) {
         indexz[6]++;
        _constZekr = 41;
    } else if (_indexZekr == 8) {
         indexz[7]++;
        _constZekr = 85;
    } else if (_indexZekr == 9) {
         indexz[8]++;
        _constZekr = 80;
    } else if (_indexZekr == 10) {
         indexz[9]++;
        _constZekr = 26;
    } else if (_indexZekr == 11) {
         indexz[10]++;
        _constZekr = 101;
    } else if (_indexZekr == 12) {
         indexz[11]++;
        _constZekr = 13;
    } else if (_indexZekr == 13) {
         indexz[12]++;
        _constZekr = 22;
    } else {
         indexz[13]++;
        _constZekr = 34;
    }
     uint _constPay;
     uint pPeriod;
      if (_payPeriod==101) {
          _constPay=10;
          pPeriod=60;
      } else if(_payPeriod==2010) {
         _constPay=2;
          pPeriod=600;
      }else{
          _constPay=1;
          pPeriod=1200;
      }
        orders[_orderId] = OrderOne(msg.sender, msg.value, true);
        ordersIdByAddress[msg.sender].push(_orderId);
        infoByAddress[msg.sender]=InfoZekr(_orderId,_constPay,_indexZekr, _constZekr,
        0,block.timestamp,1,pPeriod,true);
        emit OrderPlaced( msg.sender, msg.value,true);
    }
    

    function placeInfoZekr(int counterZekr) public activeId() {
      uint counterPay=infoByAddress[msg.sender].cPay;
      uint periodic=infoByAddress[msg.sender].cPeriod;
      uint payPeriod=infoByAddress[msg.sender].pPeriod;
      uint start=infoByAddress[msg.sender].startTime;
      int constZekr=infoByAddress[msg.sender].constZekr;
      uint constPay=infoByAddress[msg.sender].constPay;

       periodic=((block.timestamp.sub(start)).div(payPeriod)).add(1);
      if (counterPay<periodic) {
          require(counterZekr==constZekr, "Go to The Payment");
          payment(counterPay,payPeriod,constPay);
      }

    }
    function payment(uint periodic,uint _payPeriod,uint constPay) internal returns (uint){
        // code
         if (_payPeriod==101) {
         (bool success, ) = msg.sender.call{value:  0.01e18, gas: gasleft()}("");
    require(success, "Failed to transfer funds to customer");
      } else if(_payPeriod==2010) {
          (bool success, ) = msg.sender.call{value:  0.015e18, gas: gasleft()}("");
    require(success, "Failed to transfer funds to customer");
      }else{
          (bool success, ) = msg.sender.call{value:  0.02e18, gas: gasleft()}("");
    require(success, "Failed to transfer funds to customer");
      }
        
        if (periodic==constPay) {
            delete infoByAddress[msg.sender];
        }
      return   periodic++;
    }
    

    function isPaid(string memory _orderId) public view returns (bool) {
        if ((orders[_orderId].amount>0) && (orders[_orderId].paid==true)) {
            return true;
        } else {
            return  false;
        }
      
       
    }
    function listIdByAddress() public view returns (string[] memory) {
      
        return  ordersIdByAddress[msg.sender];
    }
    function getInfoByUniqId(string calldata uniqId) public view returns (InfoZekr memory) {
    return infoById[uniqId];
    }

}
    library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c=a + b;
        assert(c>=a);
        return c;
    }

   
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert (b<=a);
        return a - b;
    }
   
   function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
}