/**
 *Submitted for verification at polygonscan.com on 2022-10-18
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

contract IbsTestV2 {

    address private owner;
    //uint256 public totalUser; 

    struct User {
      uint user_id;
      uint ref_id;
      address user_address;
      bool is_exist;
    }

    using SafeMath for uint256;

    mapping(address => User) public users;
    mapping(address => uint) balance;
    event RegUserEvent(address indexed UserAddress, uint UserId,uint Referrerid);
    event InvestedEvent(address indexed UserAddress, uint256 InvestAmount);
    event LevelEarnEvent(address [] Caller, uint256 [] Earned);
    event SelfLeaderEarnEvent(address Caller, uint256 Earned);
    event LeaderEarnedEvent(address [] Caller, uint256 [] Earned);
    event WithdrawEvent(address Caller, uint256 Earned);

    constructor() public {
        owner = msg.sender;
    }
   
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function addUsers(uint _user_id, uint _ref_id) external {
        require(users[msg.sender].is_exist == false,  "User Exist");
        //require(_ref_id >= 0 && _ref_id <= _user_id, "Incorrect referrerID");
        users[msg.sender] = User({
            user_id: _user_id,
            ref_id: _ref_id,
            user_address: msg.sender,
            is_exist: true
        });
        //totalUser = totalUser.add(1);
        emit RegUserEvent(msg.sender, _user_id, _ref_id);
    }

    function simpinvest(address[] memory _incleveladd, uint256[] memory _inclevelcomm, address[] memory _incleadadd, uint256[] memory _incleadbonus, uint256 _selfleadbonus) external payable {
        require(users[msg.sender].is_exist == true,  "User not Exist");
        emit InvestedEvent(msg.sender,msg.value);
        /* level bonus to array users */
        if(_incleveladd.length>0){
            sendmul(_incleveladd,_inclevelcomm);
            emit LevelEarnEvent(_incleveladd,_inclevelcomm);
        }
        /* Leader bonus to array users */
        if(_incleadadd.length>0){
            sendmul(_incleadadd,_incleadbonus);
            emit LeaderEarnedEvent(_incleadadd,_incleadbonus);
        }
        /* Leader bonus to self */
        if(_selfleadbonus>0){
            payable(msg.sender).transfer(_selfleadbonus*(10**18));
            //_sendToUser(msg.sender,_selfleadbonus);
            emit SelfLeaderEarnEvent(msg.sender,_selfleadbonus);
        }
    }
    
    function reinvest(address[] memory _incleveladdress, uint256[] memory _inclevelcommission, address[] memory _incleadaddress, uint256[] memory _incleadbonuses, uint256 _selfleadbonuses) external payable {
        require(users[msg.sender].is_exist == true,  "User not Exist");
        emit InvestedEvent(msg.sender,msg.value);
        /* 15% to withdraw to investment */
        uint256 per = msg.value.mul(15).div(100);
        uint256 withdrawamt = msg.value.add(per);
        if(withdrawamt>0){
            payable(msg.sender).transfer(withdrawamt);
            //_sendToUser(msg.sender,_selfleadbonus);
            emit WithdrawEvent(msg.sender,withdrawamt);
        }

        /* level bonus to array users */
        if(_incleveladdress.length>0){
            sendmul(_incleveladdress,_inclevelcommission);
            emit LevelEarnEvent(_incleveladdress,_inclevelcommission);
        }
        /* Leader bonus to array users */
        if(_incleadaddress.length>0){
            sendmul(_incleadaddress,_incleadbonuses);
            emit LeaderEarnedEvent(_incleadaddress,_incleadbonuses);
        }
        /* Leader bonus to self */
        if(_selfleadbonuses>0){
            payable(msg.sender).transfer(_selfleadbonuses*(10**18));
            //_sendToUser(msg.sender,_selfleadbonus);
            emit SelfLeaderEarnEvent(msg.sender,_selfleadbonuses);
        }
    }

    function sendmul(address[] memory _leveladd, uint256[] memory _levelcomm) internal {
        for(uint256 i = 0; i < _leveladd.length; i++){
            //_sendToUser(_leveladd[i],_levelcomm[i]);
            payable(_leveladd[i]).transfer(_levelcomm[i]*(10**18));
        }
    }

    function _sendToUser(address _to, uint256 _value) internal {
        payable(_to).transfer(_value*(10**18));
    }

}