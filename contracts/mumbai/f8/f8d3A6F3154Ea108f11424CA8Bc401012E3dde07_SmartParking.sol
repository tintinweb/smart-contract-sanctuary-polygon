/**
 *Submitted for verification at polygonscan.com on 2023-04-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SmartParking {
  mapping(uint256 => Order) orders;
  mapping(uint256 => OrderDetail) public ordersDetail;

  enum Status {NOT_PAID, PAID}

  struct Order {
    uint256 user_id;
    string plat_number;
    uint256[] order_id;
    }

  struct OrderDetail {
      uint256 time_enter;
      uint256 time_exit;
      uint256 price;
      Status status;
  }

  function userRegister(uint256 _user_id, string memory _plat_number) public {
    Order storage order = orders[_user_id];
    order.user_id = _user_id;
    order.plat_number = _plat_number;
  }

  function addOrder(
      uint256 _user_id,
      uint256 _order_id,
      uint256 _time_enter,
      Status _status
      ) public payable {
          Order storage order = orders[_user_id];
          OrderDetail storage orderDetail = ordersDetail[_order_id];
          
          order.user_id = _user_id;
          order.order_id.push(_order_id);

          orderDetail.time_enter = _time_enter;
          orderDetail.price = 4000;
          orderDetail.status = _status;
  }

  function userOrderInfo(uint256 _user_id) public view returns (
      uint256 user_id, string memory plat_number, uint256[] memory order_id){
        return (orders[_user_id].user_id, orders[_user_id].plat_number, orders[_user_id].order_id);
    }

  function insertExit(uint256 _order_id, uint256 _time_exit, uint256 _price, Status _status) public {
      OrderDetail storage orderDetail = ordersDetail[_order_id];

      require (_time_exit > orderDetail.time_enter, "Time exit must greater than enter");

      orderDetail.time_exit = _time_exit;
      orderDetail.price = _price;
      orderDetail.status = _status;
  }

}