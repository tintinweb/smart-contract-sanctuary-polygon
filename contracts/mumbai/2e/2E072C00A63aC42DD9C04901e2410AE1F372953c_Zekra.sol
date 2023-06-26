/**
 *Submitted for verification at polygonscan.com on 2023-06-25
*/

// SPDX-License-Identifier: UNLICENSE
pragma solidity >=0.8.0 <0.9.0;

contract Zekra {
    using SafeMath for uint256;
    mapping(uint => Order) public orders;
    mapping(address => uint[]) ordersByAddress;
    mapping(address =>InfoZekr) public infoByAddress;

    event OrderPlaced(
        uint indexed orderId,
        address indexed customer,
        string zekrCode,
        uint256 amount
    );

    modifier activeId(){
    require(infoByAddress[msg.sender].active==true,"It's Not Active");
    _;
    }

    struct InfoZekr{
        uint  UniqId;
        uint8 cZekr;
        uint8 cPay;
        uint8 constNumberZekr;
        uint  startTime;
        uint8  cPeriod;
        bool  active;
    }

    struct Order {
        address customer;
        string zekrCode;
        uint256 amount;
        bool paid;
    }

    function placeOrder(string calldata _zekrCode) payable external {
        require(msg.value >= 0, "Payment amount must be greater than 0");
        uint256 orderId = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _zekrCode)));
        orders[orderId] = Order(msg.sender, _zekrCode, msg.value, true);
        ordersByAddress[msg.sender].push(orderId);
        emit OrderPlaced(orderId, msg.sender, _zekrCode, msg.value);
    }
    function placeInfoZekr() public activeId() {
      uint8 counterPay=infoByAddress[msg.sender].cPay;
      uint counterPeriod=infoByAddress[msg.sender].cPeriod;
      uint8 counterZekr=infoByAddress[msg.sender].cZekr;
      uint start=infoByAddress[msg.sender].startTime;
      uint8 constNumber=infoByAddress[msg.sender].constNumberZekr;
      //bool act=infoByAddress[msg.sender].active;
       counterPeriod=((block.timestamp.sub(start)).div(86400)).add(1);
      if (counterPay<counterPeriod) {
          require(counterZekr==constNumber, "Go to The Payment");
          payment(counterPay);
      }

    }
    function payment(uint8 counterPay) internal returns (uint8){
        // code
        if (counterPay==20) {
            delete infoByAddress[msg.sender];
        }
      return   counterPay++;
    }
    
    function getOrderById(uint256 orderId) public view returns (address, string memory, uint256, bool) {
    
    return (orders[orderId].customer, orders[orderId].zekrCode, orders[orderId].amount, orders[orderId].paid);
    }
    function isPaid(uint _orderId) public view returns (bool) {
      
        return  orders[_orderId].paid;
    }
      function listIdByAddress() public view returns (uint[] memory) {
      
        return  ordersByAddress[msg.sender];
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