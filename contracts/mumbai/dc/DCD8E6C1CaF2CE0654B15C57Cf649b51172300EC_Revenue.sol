/**
 *Submitted for verification at polygonscan.com on 2022-11-27
*/

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function lockedTokenAmount(address sender) external view returns (uint256);

    function lockedTotalAmount() external view returns (uint256);

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        _previousOwner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _previousOwner = _owner;
        _owner = newOwner;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(
            _previousOwner == msg.sender,
            "You don't have permission to unlock"
        );
        require(block.timestamp > _lockTime, "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

contract Revenue is Ownable {
    uint256 totalRevenueAmount;
    uint256 public revenueAmount;
    uint256 claimedAmount;
    address vsqAddress;
    address lockerAddress;
    mapping(address => uint256) tokens;

    constructor(address lockerAddress_) {
        lockerAddress = lockerAddress_;
    }

    function addRevenue(uint256 addAmount) external {
        IERC20(vsqAddress).transferFrom(msg.sender, address(this), addAmount);
        uint256 currentAmount = IERC20(vsqAddress).balanceOf(address(this));
        uint256 totalAddAmount = currentAmount - revenueAmount;
        totalRevenueAmount += totalAddAmount;
        revenueAmount += totalAddAmount;
    }

    event Claim(address sender, uint256 amount);

    function claimRevenue() external {
        uint256 lockAmount = IERC20(lockerAddress).lockedTokenAmount(
            msg.sender
        );
        uint256 totalLockAmount = IERC20(lockerAddress).lockedTotalAmount();
        require(totalLockAmount > 0, "no LockAmount");
        require(lockAmount > 0, "didn't locked amount");
        uint256 currentAmount = IERC20(vsqAddress).balanceOf(address(this));
        revenueAmount += currentAmount;
        uint256 myTotalRevenueAmount = (totalRevenueAmount * lockAmount) /
            totalLockAmount;
        if (tokens[msg.sender] == 0) {
            tokens[msg.sender] = myTotalRevenueAmount;
            require(
                myTotalRevenueAmount < revenueAmount,
                "not enough Balance!"
            );
            revenueAmount -= myTotalRevenueAmount;
            IERC20(vsqAddress).transfer(msg.sender, myTotalRevenueAmount);
            emit Claim(msg.sender, myTotalRevenueAmount);
            return;
        }
        require(
            myTotalRevenueAmount > tokens[msg.sender],
            "not enough Balance!"
        );
        uint256 claimAmount = myTotalRevenueAmount - tokens[msg.sender];
        revenueAmount -= claimAmount;
        tokens[msg.sender] = myTotalRevenueAmount;
        IERC20(vsqAddress).transfer(msg.sender, claimAmount);
        emit Claim(msg.sender, claimAmount);
    }

    function setVSQAddress(address vsqaddress_) external onlyOwner {
        vsqAddress = vsqaddress_;
    }

    function setLockerAddress(address lockerAddress_) external onlyOwner {
        lockerAddress = lockerAddress_;
    }
}