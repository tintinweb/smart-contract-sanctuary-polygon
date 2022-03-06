/**
 *Submitted for verification at polygonscan.com on 2022-03-06
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor (address initialOwner) {
        _owner = initialOwner;
        emit OwnershipTransferred(address(0), initialOwner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is still locked");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

contract BLMVesting is Context, Ownable {
    // VESTING
    struct Vesting {
        uint256 allocation;
        uint256 claimed;
        uint256 claimAmount;
        uint256 lastClaimed;
    }
    mapping (address => Vesting) public _vesting;
    mapping (uint => address) public _vestingMap;
    uint256 public _vestingLen;
    uint256 public _vestingInterval = 1 weeks;

    // LOCKING
    mapping (address => uint256) public _locking;
    uint256 public _lockAmount = 33150000000000000000000000;
    uint256 public _lockDuration = 24 weeks;
    uint256 public _lockInitiated;


    address public _tokenAddress = 0x314659C1573d263fbbB5Bd172449388bb4958bb5;

    event  Claimed(address addr, uint256 amount, uint256 timestamp);
    event Released(address addr, uint256 amount, uint256 timestamp);

    constructor(address owner) Ownable(owner) {
        _lockInitiated = block.timestamp;

        // Vest 3 months: 1,215,500
        setVesting(0xfb83C11358654A1D88F77F09FC1dC7BAd6d0001a, 1215500000000000000000000, 12);

        // Vest 16 months: 2,071,875
        setVesting(0x944B6Dd72E9eaFb9b2D50A8732f4164C5eccC34B, 2071875000000000000000000, 64);
        setVesting(0xf54Ec0d5cD933466B2bB39A8C1dC33fE2d05633E, 2071875000000000000000000, 64);
        setVesting(0x2ce7f90191A5d57208CbAEc12C1E3B7dacee4FE8, 2071875000000000000000000, 64);
        setVesting(0xcafbc2877Be6e35a53837249724F83e56742922D, 2071875000000000000000000, 64);

        // Vest 3 months: 550,000
        setVesting(0x8E7419dbd0AA1e5092572002F462F40Dbe0B33C1, 550000000000000000000000, 12);

        // Vest 4 months: 9,392,500
        setVesting(0x28DefC05aE3241435D0Ae4728292f5921798DD1C, 9392500000000000000000000, 16);

        // Vest 2 months: 4,143,750
        setVesting(0xD75bbb976Ef7Ba8A5c0E9F85c66bdFFdd6e9bE62, 4143750000000000000000000, 8);

        // Vest 2 months: 3,867,500
        setVesting(0xB1039D587CE5b41B7efc4FF2a41F682fB4C060ba, 3867500000000000000000000, 8);

        // Vest 16 months: 2,071,875
        setVesting(0x79eCf5D8e1d7dD1B1917025bBA629D0a69724627, 2071875000000000000000000, 64);
        setVesting(0xda28010FFC52df66F02B880397D32BF557a1F13c, 2071875000000000000000000, 64);
        setVesting(0x911EDd0A172eb7CC87e9cC452262743d7380B345, 2071875000000000000000000, 64);
        setVesting(0xA1c3eF382D738D37a75D565F769D8013B2ab0C72, 2071875000000000000000000, 64);

        // Vest 16 months: 2,394,166.67
        setVesting(0xA756Ad4CB9BB668D693AC8F9eA03973E5437e4A5, 2394166670000000000000000, 64);
    }

    function setVesting(address addr, uint256 allocation, uint256 claimFrq) internal {
        _vesting[addr] = Vesting(
            allocation,
            0,
            allocation / claimFrq,
            0
        );
        _vestingMap[_vestingLen] = addr;
        _vestingLen++;
    }

    function withdrawTokens(address recipient, address contractAddress, uint256 amount) external onlyOwner returns(bool) {
        IERC20(contractAddress).transfer(recipient, amount);
        return true;
    }
    function withdraw(address recipient, uint256 amount) external onlyOwner returns(bool) {
        payable(recipient).transfer(amount);
        return true;
    }
    function setVestingInterval(uint256 interval) external onlyOwner {
        _vestingInterval = interval;
    }

    function claimAvailable() external {
        for (uint i = 0; i < _vestingLen; i++) {
            address a = _vestingMap[i];
            if (block.timestamp > _vesting[a].lastClaimed + _vestingInterval) {
                if (_vesting[a].claimed <= _vesting[a].allocation) {
                    claim(a);
                }
            }
        }
    }

    function claim(address addr) public {
        require(IERC20(_tokenAddress).balanceOf(address(this)) > _vesting[addr].claimAmount, "contract balance not enough");
        require(block.timestamp > _vesting[addr].lastClaimed + _vestingInterval, "not available for claim yet.");
        require(_vesting[addr].claimed <= _vesting[addr].allocation, "vesting balance not enough");
        require(_vesting[addr].allocation > 0, "invalid address.");

        // send token to address
        IERC20(_tokenAddress).transfer(addr, _vesting[addr].claimAmount);

        // update vesting claimed
        _vesting[addr].claimed = _vesting[addr].claimed + _vesting[addr].claimAmount;

        // update lastClaimed
        _vesting[addr].lastClaimed = block.timestamp;

        emit Claimed(addr, _vesting[addr].claimAmount, block.timestamp);
    }

    function release() external {
        require(block.timestamp > _lockInitiated + _lockDuration, "not available for release yet.");

        // release lock 1
        IERC20(_tokenAddress).transfer(0xB60744FA5d3d3D93EEA8f5205C54324006335fcE, _lockAmount);
        emit Released(0xB60744FA5d3d3D93EEA8f5205C54324006335fcE, _lockAmount, block.timestamp);

        // release lock 2
        IERC20(_tokenAddress).transfer(0x1d2a260f489a04ec1399C87bd3392fD337b2A14E, _lockAmount);
        emit Released(0x1d2a260f489a04ec1399C87bd3392fD337b2A14E, _lockAmount, block.timestamp);
    }

}