/**
 *Submitted for verification at polygonscan.com on 2023-06-28
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

contract Amoeba is notConation {
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
   
    constructor() {
        _usdtAddr = address(0xb973D2876c4F161439AD05f1dAe184dbD594e04E);
        _receiver = address(0xd69bccE03Fd4aA0090D5b2Bbd91671D1856981d5);
        Dai = IERC20(_usdtAddr);
        startTime = block.timestamp;
    }

    function addUsers(uint _user_id,uint256 _amount) external payable {
        require(users[msg.sender].is_exist == false,  "User Exist");
        users[msg.sender] = User({
            user_id: _user_id,
            user_address: msg.sender,
            is_exist: true
        });
        Dai.transferFrom(msg.sender, address(this), _amount);
        emit RegUserEvent(msg.sender, _user_id);
    }

     
}