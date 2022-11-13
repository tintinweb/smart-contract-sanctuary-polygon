/**
 *Submitted for verification at polygonscan.com on 2022-11-12
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
  function decimals() external view returns (uint8);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) { owner = _owner; }
    modifier onlyOwner() { require(isOwner(msg.sender), "!OWNER"); _; }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

contract LottoX_v1 is Ownable {
  using SafeMath for uint256;

  IERC20 public deposit_token;

  address public fee_receiver;
  uint256 public rtp = 834;
  uint256 public denominator = 1000;

  uint256 public deposit_amount;
  uint256 public slot_current = 0;
  uint256 public slot_max = 12;

  uint256 public totalPlayed;

  mapping(address => bool) public permission;
  mapping(uint256 => address) public userAddress;
  mapping(uint256 => uint256) public userBlockstamp;

  mapping(uint256 => uint256) public winnerSlot;
  mapping(uint256 => address) public winnerAddress;

  modifier onlyPermission() {
    require(permission[msg.sender], "!PERMISSION");
    _;
  }

  constructor(address _tokenAddress,uint256 _depositamount) Ownable(msg.sender) {
    permission[msg.sender] = true;
    fee_receiver = msg.sender;
    deposit_token = IERC20(_tokenAddress);
    deposit_amount = _depositamount.mul(10**deposit_token.decimals());
  }

  function flagePermission(address _account,bool _flag) public onlyOwner returns (bool) {
    permission[_account] = _flag;
    return true;
  }

  function changeRule(address _tokenAddress,address _receiver,uint256 _depositamount,uint256 _rtp) public onlyPermission returns (bool) {
    deposit_token = IERC20(_tokenAddress);
    deposit_amount = _depositamount.mul(10**deposit_token.decimals());
    fee_receiver = _receiver;
    rtp = _rtp;
    return true;
  }

  function createRandomNum(uint256 mod) public view returns (uint256) {
    uint256 randomNum = uint256(
      keccak256(abi.encodePacked(userAddress[1],userBlockstamp[1]))
    );
    return (randomNum % mod).add(1);
  }

  function deposit() external returns (bool) {
    if(slot_current<slot_max){
      slot_current = slot_current.add(1);
      userAddress[slot_current] = msg.sender;
      userBlockstamp[slot_current] = block.timestamp;
      deposit_token.transferFrom(msg.sender,address(this),deposit_amount);
    }else{
      slot_current = slot_current.add(1);
      userAddress[slot_current] = msg.sender;
      userBlockstamp[slot_current] = block.timestamp;
      deposit_token.transferFrom(msg.sender,address(this),deposit_amount);
      uint256 winner = createRandomNum(slot_max);
      totalPlayed = totalPlayed.add(1);
      winnerSlot[totalPlayed] = winner;
      winnerAddress[totalPlayed] = userAddress[winner];
      uint256 contractbalance = deposit_token.balanceOf(address(this));
      uint256 reward = contractbalance.mul(rtp).div(denominator);
      deposit_token.transfer(userAddress[winner],reward);
      deposit_token.transfer(fee_receiver,contractbalance.sub(reward));
      slot_current = 0;
    }
    return true;
  }

  function foreceend() public onlyPermission returns (bool) {
    uint256 winner = createRandomNum(slot_current);
    totalPlayed = totalPlayed.add(1);
    winnerSlot[totalPlayed] = winner;
    winnerAddress[totalPlayed] = userAddress[winner];
    uint256 contractbalance = deposit_token.balanceOf(address(this));
    uint256 reward = contractbalance.mul(rtp).div(denominator);
    deposit_token.transfer(userAddress[winner],reward);
    deposit_token.transfer(fee_receiver,contractbalance.sub(reward));
    slot_current = 0;
    return true;
  }
}