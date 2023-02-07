/**
 *Submitted for verification at polygonscan.com on 2023-02-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
contract BookingContract{

    struct User{
        bool isApproved;
        bool isRegisterred;
        bool rideStarted;
        uint rideCount;
        uint rideFee;
    }
  address public owner;
  address public bookingAgent;
  uint256 public rideFee = 0.01 ether;
  uint256 public bookingAgentrideFee = 10;
  address private marketingAddress;

 mapping (address => User) public _user;

  constructor (address _bookingAgent, address _marketingAddress){
      bookingAgent = _bookingAgent;
      owner = msg.sender;
      marketingAddress = _marketingAddress;
  }

 modifier onlyowner() {
        require(owner == msg.sender, "only owner");
        _;
    }

 receive() payable  external {}

  function booking() public  payable {
      require(!_user[msg.sender].isRegisterred, "You already registerred");
      require(msg.value == rideFee, "Not enough rideFee to get register");
      _user[msg.sender].isRegisterred = true;
      _user[msg.sender].rideFee += msg.value;
  }
  function aproveClient(address client)external{
     require(msg.sender == bookingAgent,"Only bookingAgent can call this function");
     require(_user[client].isRegisterred != false, "Client is not registerred");
     require(_user[client].isApproved != true, "Client is already approved");
      _user[client].isApproved = true;
      _user[client].rideStarted = true;
      _user[client].rideCount++;
  }
  
  function finishRide(address _client)external{
    require(msg.sender == bookingAgent,"Only bookingAgent can call this function");
    require(_user[_client].rideStarted || _user[_client].isApproved, "Client's ride is not started yet");
     payable(msg.sender).transfer(bookingAgentrideFee);
      _user[_client].rideFee -= bookingAgentrideFee;
     payable(marketingAddress).transfer(rideFee);
     _user[_client].isApproved = false;
     _user[_client].rideStarted = false;
      
  }
   function changeRideFee(uint256 _newrideFee)external onlyowner{
         rideFee = _newrideFee;
  }
  function changeBookingAgent(address _newbookingAgent)external onlyowner{
         bookingAgent = _newbookingAgent;
  }
   function changeBookingAgentFee(uint256 _newbookingAgentrideFee)external onlyowner{
         bookingAgentrideFee = _newbookingAgentrideFee;
  }
   function changeMarketingAddress(address _newMarketingAddress)external onlyowner{
         marketingAddress = _newMarketingAddress;
  }
  function getContractBalance()external view returns(uint){
      return (address(this).balance);
      
  }
}