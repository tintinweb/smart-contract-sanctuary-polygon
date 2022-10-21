/**
 *Submitted for verification at polygonscan.com on 2022-10-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.4.24;

interface IERC20 {
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external ;
    function transfer(address recipient, uint256 amount) external;

    function transferIn(address account, uint amount) external;
    function transferOut(address account, uint amount) external;

    function mint(address to, uint256 amount) external returns (bool);
    function burn(address to, uint256 amount) external returns (bool);
    
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

contract mtContract is Ownable {
    using SafeMath for uint256;

    IERC20 pusdt;
    IERC20 mavro;
    IERC20 score;

    uint8 ratio = 40;
    uint8 rOnes = 10;
    uint8 rTwos = 10;
    uint8 rThrs = 4;
    uint8 rFous = 16;

    address ones = 0xb7AfE89f8dD316512Db808a675666D4180B8e673;
    address twos = 0xb7AfE89f8dD316512Db808a675666D4180B8e673;
    address thrs = 0xb7AfE89f8dD316512Db808a675666D4180B8e673;
    address fous = 0xb7AfE89f8dD316512Db808a675666D4180B8e673;

    mapping(address => bool) private isCaller;

    constructor(
        IERC20 _pusdt, IERC20 _mavro, IERC20 _score
    ) public { 
        pusdt = _pusdt;
        mavro = _mavro;
        score = _score;
    }

    modifier onlyCaller() {
        require(isCaller[msg.sender], "Error: caller is not the caller");
        _;
    }

    function getPusdt() public view returns (address mpusdt, address mmavro, address mscore) {
        mpusdt = pusdt;
        mmavro = mavro;
        mscore = score;
        return (mpusdt, mmavro, mscore);
    }

    function setMaker(IERC20 puAddress, IERC20 maAddress, IERC20 scAddress) public onlyOwner {
        pusdt = puAddress;
        mavro = maAddress;
        score = scAddress;
    }

    function getOuter() public view returns (address first, address second, address third, address fouth) {
        first = ones;
        second = twos;
        third = thrs;
        fouth = fous;
        return (first, second, third, fouth);
    }

    function setOuter(address first, address second, address third, address fouth) public onlyOwner {
        ones = first;
        twos = second;
        thrs = third;
        fous = fouth;
    }

    function getRatio() public view returns (uint8 mRatio, uint8 oneRatio, uint8 twoRatio, uint8 thrRatio, uint8 fouRatio ) {
        mRatio = ratio;
        oneRatio = rOnes;
        twoRatio = rTwos;
        thrRatio = rThrs;
        fouRatio = rFous;
        return (mRatio, oneRatio, twoRatio, thrRatio, fouRatio);
    }

    function setRatio(uint8 ratioValue, uint8 oneValue, uint8 twoValue, uint8 thrValue, uint8 fouValue ) public onlyOwner {
        ratio = ratioValue;
        rOnes = oneValue;
        rTwos = twoValue;
        rThrs = thrValue;
        rFous = fouValue;
    }

    function getCaller(address account) public view returns (bool) {
        return isCaller[account];
    }

    function setCaller(address account, bool value) public onlyOwner {
        require(isCaller[account] != value, "This address is already the value of 'value'");
        isCaller[account] = value;
    }

    //  TRANSFER OUT
    function transferOut(address account, uint256 value) external onlyCaller {
        pusdt.transfer(account, value);
    }

    //  TRANSFER IN
    function transferIn(uint256 value) public {
        pusdt.transfer(address(this), value);
    }

    //  GET SCORE
    function getScore(address account, uint256 value) external onlyCaller {
        score.mint(account, value);
    }

    //  GET MAVRO
    function getMavro(address account, uint256 value) public {
        pusdt.transfer(address(this), value);
        mavro.mint(account, value);
    }

    //  GETHELP
    function PutHelp(address account, uint256 value) public {
        uint vTotal;
        uint vOnes;
        uint vTwos;
        uint vThrs;
        uint vFous;
        vTotal = value * ratio / 1000;
        vOnes = value * rOnes / 1000;
        vTwos = value * rTwos / 1000;
        vThrs = value * rThrs / 1000;
        vFous = value * rFous / 1000;
        require(pusdt.balanceOf(account) >= value);
        require(pusdt.balanceOf(mavro) >= vTotal);
        require(mavro.balanceOf(account) >= vTotal);
        require(score.balanceOf(account) >= 100000000);
        pusdt.transfer(address(this), value);
        mavro.transferOut(ones, vOnes);
        mavro.transferOut(twos, vTwos);
        mavro.transferOut(thrs, vThrs);
        mavro.transferOut(fous, vFous);
        mavro.burn(account, vTotal);
        score.burn(account, 100000000);
    }



}