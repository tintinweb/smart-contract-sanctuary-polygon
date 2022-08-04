/**
 *Submitted for verification at polygonscan.com on 2022-08-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface ITotosToken {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract TotosStaking is Ownable {
    address public tokenAddress;

    // uint public stakingPeriodUnit = 1 days;
    // uint public stakingPeriodSection = 90;
    // uint[5] public stakingRewards = [0, 0.066 ether, 0.077 ether, 0.088 ether, 0.099 ether];

    uint public stakingPeriodUnit = 1 hours;
    uint public stakingPeriodSection = 72;
    uint[5] public stakingRewards = [0, 0.066 ether, 0.077 ether, 0.088 ether, 0.099 ether];

    mapping(uint => bool) public onStaking;
    mapping(uint => uint) public startTime;
    mapping(uint => uint) public stakingPeriod;
    mapping(uint => uint) public multiplier;
    mapping(uint => address) public tokenOwner;

    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
    }

    function stake(uint _tokenId, address _tokenOwner, uint _stakingPeriod, uint _multiplier) external onlyOwner returns(bool) {
        require(onStaking[_tokenId] == false, "This token is already on staking.");
        require(_stakingPeriod < 5 && _stakingPeriod > 0, "Something went wrong");

        onStaking[_tokenId] = true;
        startTime[_tokenId] = block.timestamp;
        stakingPeriod[_tokenId] = _stakingPeriod;
        multiplier[_tokenId] = _multiplier;
        tokenOwner[_tokenId] = _tokenOwner;

        return true;
    }

    function unstake(uint _tokenId) external onlyOwner {
        require(onStaking[_tokenId] == true, "This token isn't on staking.");
        require(block.timestamp - startTime[_tokenId] >= stakingPeriod[_tokenId] * stakingPeriodSection * stakingPeriodUnit, "You can't unstake before the time.");

        uint reward = stakingPeriod[_tokenId] * stakingPeriodSection * stakingRewards[stakingPeriod[_tokenId]] * multiplier[_tokenId];
        ITotosToken(tokenAddress).transfer(tokenOwner[_tokenId], reward);

        onStaking[_tokenId] = false;
    }

    function forceUnstake(uint _tokenId) external onlyOwner {
        onStaking[_tokenId] = false;
    }

    function setTokenAddress(address _tokenAddress) external onlyOwner {
        tokenAddress = _tokenAddress;
    }
}