/**
 *Submitted for verification at polygonscan.com on 2023-05-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract StatstradeGateway {
  event GatewayEvent(string event_type,string event_id,address sender,uint value);
  
  address public g__SiteAuthority;
  
  mapping(address => bool) public g__SiteSupport;
  
  mapping(string => address) public g__SitePaymasters;
  
  constructor() {
    g__SiteAuthority = msg.sender;
  }
  
  function ut__assert_admin(address user_address) internal view {
    require(
      (user_address == g__SiteAuthority) || g__SiteSupport[user_address],
      "Site admin only."
    );
  }
  
  function site__change_authority(address new_authority) external {
    require(msg.sender == g__SiteAuthority,"Site authority only.");
    g__SiteAuthority = new_authority;
  }
  
  function site__add_support(address user) external {
    require(msg.sender == g__SiteAuthority,"Site authority only.");
    g__SiteSupport[user] = true;
  }
  
  function site__remove_support(address user) external {
    ut__assert_admin(msg.sender);
    delete g__SiteSupport[user];
  }
  
  function site__set_paymaster(string memory pay_id,address user) external {
    g__SitePaymasters[pay_id] = user;
  }
  
  function site__del_paymaster(string memory pay_id) external {
    ut__assert_admin(msg.sender);
    delete g__SitePaymasters[pay_id];
  }
  
  function payment_native(string memory pay_id) external payable {
    require(msg.value != 0,"Cannot be zero");
    payable(
      (g__SitePaymasters[pay_id] == address(0)) ? g__SiteAuthority : g__SitePaymasters[pay_id]
    ).transfer(msg.value);
    emit GatewayEvent("payment_native",pay_id,msg.sender,msg.value);
  }
}