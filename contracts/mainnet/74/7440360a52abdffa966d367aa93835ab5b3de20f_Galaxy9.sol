/**
 *Submitted for verification at polygonscan.com on 2023-05-02
*/

// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.19; 

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

pragma solidity ^0.8.19;

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function decimals() external view returns (uint8);

  function symbol() external view returns (string memory);

  function name() external view returns (string memory);

  function getOwner() external view returns (address);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external payable returns (bool);

  function allowance(address _owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(address sender, address recipient, uint256 amount) external payable returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract notConation {
    address public _contract;
    constructor() {
        _contract = msg.sender;
    }

    modifier notApplicable() { 
        /** validation check **/
        require(_contract == msg.sender, "Contract: caller is not the contract");
        _;
    }
}

contract Galaxy9 is notConation {
    using SafeMath for uint256; 
    IERC20 public Dai;
    address private owner;
    uint256 public startTime;
    address public _usdtAddr;
    address public _receiver;
    
    struct User {
        uint user_id;
        address user_address;
        bool is_exist;
    }

    mapping(address => User) public users;
    mapping(address => uint) balance;
    event RegUserEvent(address indexed UserAddress, uint UserId);
    event InvestedEvent(address indexed UserAddress, uint256 InvestAmount);
    event ReferalEarnEvent(address [] Caller, uint256 [] Earned);
    event LevelEarnEvent(address [] Caller, uint256 [] Earned);
    event AutopoolEarnedEvent(address [] Caller, uint256 [] Earned);
    event ClubEarnedEvent(address [] Caller, uint256 [] Earned);

    
    constructor() {
        _usdtAddr = address(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063);
        _receiver = address(0xfef5B12Cf7F542F4569378Fbd2D345F4109cC50f);
        Dai = IERC20(_usdtAddr);
        startTime = block.timestamp;
    }

    function addUsers(uint _user_id) external {
        require(users[msg.sender].is_exist == false,  "User Exist");
        users[msg.sender] = User({
            user_id: _user_id,
            user_address: msg.sender,
            is_exist: true
        });
        //totalUser = totalUser.add(1);
        emit RegUserEvent(msg.sender, _user_id);
    }

    function packageactive(uint256 _amount, address[] memory _increferraladd, uint256[] memory _increferralcomm,address[] memory _incleveladd, uint256[] memory _inclevelcomm, address[]  memory _incautopooladd, uint256[] memory _incautopoolbonus,address[]  memory _incclubadd, uint256[] memory _incclubbonus, uint256 _lepsCommission)
       external payable {
        require(users[msg.sender].is_exist == true,  "User not Exist");
        Dai.transferFrom(msg.sender, address(this), _amount);
        emit InvestedEvent(msg.sender,_amount);
         /* Referral bonus to array users */
        if(_increferraladd.length>0){
            sendmul(_increferraladd,_increferralcomm);
            emit ReferalEarnEvent(_increferraladd,_increferralcomm);
        }
         /* Level bonus to array users */
        if(_incleveladd.length>0){
            sendmul(_incleveladd,_inclevelcomm);
            emit LevelEarnEvent(_incleveladd,_inclevelcomm);
        }
        /* Autopool bonus to array users */
        if(_incautopooladd.length>0){
            sendmul(_incautopooladd,_incautopoolbonus);
            emit AutopoolEarnedEvent(_incautopooladd,_incautopoolbonus);
        }
        /* Club bonus to self */
         if(_incclubadd.length>0){
            sendmul(_incclubadd,_incclubbonus);
            emit ClubEarnedEvent(_incclubadd,_incclubbonus);
        }
        if(_lepsCommission>0){
            Dai.transfer(_receiver, _lepsCommission);
        }

      }

    function sendmul(address[] memory _leveladd, uint256[] memory _levelcomm) internal {
        for(uint256 i = 0; i < _leveladd.length; i++){
            Dai.transfer(_leveladd[i], _levelcomm[i]);
            //payable(_leveladd[i]).transfer(_levelcomm[i]);
        }
    }

}