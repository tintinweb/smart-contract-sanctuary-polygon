/**
 *Submitted for verification at polygonscan.com on 2023-01-29
*/

/**
 宾果零和博弈合约地址：0xa3cF335faAc9f7a3E900C4d1a7aB82C841922313
*/
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Ownable {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor ()  {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }   
    
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
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

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract BingoLiquidityLocker is Ownable{
    using SafeMath for uint256;

    bool init = true;
    
    uint256 public startLockTime;
    uint256 public lockPeriod = 1095 days;
    uint256 public lastClaimPeriodNumber;
    uint256 public releaseAmountPerPeriod;
    address public lockToken;
    mapping(address=>bool) isTeam;

    constructor(){
        isTeam[msg.sender] = true;
    }

    modifier onlyTeam() {
        require(isTeam[msg.sender], "Ownable: caller is not in team");
        _;
    }

    function startLock(address tokenAddress) public onlyTeam{
        require(init, "You have started");

        lockToken = tokenAddress;
        startLockTime = block.timestamp;

        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        releaseAmountPerPeriod = balance.mul(1).div(100);
    }

    function claim(address claimAddress) public onlyTeam{
       
        require(lockToken!=address(0), "Have not set lock token address");

        uint256 nowTime = block.timestamp;
        uint256 lastClaimPeriodTime = startLockTime.add(lastClaimPeriodNumber.mul(lockPeriod));
        uint256 lockedPeriods = nowTime.sub(lastClaimPeriodTime).div(lockPeriod);
        require(lockedPeriods>0, "Released amount is zero");

        uint256 balance = IERC20(lockToken).balanceOf(address(this));
        uint256 newReleaseAmount = releaseAmountPerPeriod.mul(lockedPeriods);
        if (newReleaseAmount > balance){
            newReleaseAmount = balance;
        }
        require(newReleaseAmount>0, "Locked amount is zero");
        IERC20(lockToken).transfer(claimAddress, newReleaseAmount);
        lastClaimPeriodNumber = lastClaimPeriodNumber.add(lockedPeriods);
    }

    function addTeam(address teamAddress) public onlyTeam{
        isTeam[teamAddress] = true;
    }

    function deleteTeam(address teamAddress) public onlyTeam{
        isTeam[teamAddress] = false;
    }

}