/**
 *Submitted for verification at polygonscan.com on 2022-10-10
*/

// SPDX-License-Identifier: GPLv3
pragma solidity ^0.6.12; 

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract ibstestv1 {

    address private owner;
    address[1] public feeReceivers;
    uint256 public totalUser; 

    struct User {
      uint user_id;
      uint ref_id;
      address user_address;
      bool is_exist;
    }

    using SafeMath for uint256;

    mapping(address => User) public users;
    mapping (uint => address) public userList;
    mapping(address => uint) balance;
    event regUserEvent(address indexed UserAddress, uint UserId,uint Referrerid, uint Time);
    
    constructor() public {
        //feeReceivers[0] = address(0x825B5FF302924ffcf77f7F92afc6CaB584005a20);
        owner = msg.sender;
    }
   
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function addUsers(uint _user_id, uint _ref_id) external {
        require(users[msg.sender].is_exist == false,  "User Exist");
        require(_ref_id >= 0 && _ref_id <= _user_id, "Incorrect referrerID");
        users[msg.sender] = User({
            user_id: _user_id,
            ref_id: _ref_id,
            user_address: msg.sender,
            is_exist: true
        });
        totalUser = totalUser.add(1);
        emit regUserEvent(msg.sender, _user_id, _ref_id, now);
    }

    function investment(address refaddress, uint256 _value) external payable {
        require(users[msg.sender].is_exist == true,  "User not Exist");
        _sendToUser(refaddress,_value);
    }

    function investment2(address[] memory _leveladd, uint256 _levelshare) external payable {
        require(users[msg.sender].is_exist == true,  "User not Exist");
        sendmul(_leveladd,_levelshare);
    }

    function _sendToUser(address _to, uint256 _value) internal {
        payable(_to).transfer(_value);
    }

    function sendmul(address[] memory _leveladd, uint256 _levelshare) internal {
        for(uint256 i = 0; i < _leveladd.length; i++){
            _sendToUser(_leveladd[i],_levelshare);
        }
    }

    function viewlevels (address[] memory _addr) external pure returns (address[] memory){
        return _addr;
    }

    function getUserBalance(address _owner) external view returns (uint) {
        return address(_owner).balance;
    }

}