// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./ERC20.sol";
import "./TokensRecoverable.sol";

contract dark0X is ERC20("DarkX Steak", "dark0X"), TokensRecoverable {
    using SafeMath for uint256;

    IERC20 public immutable darkX;

    uint256 public totalStakers;
    uint256 public allTimeStaked;
    uint256 public allTimeUnstaked;

    struct AddressRecords {
        uint256 totalStaked;
        uint256 totalUnstaked;
								uint256 lastStaked;
    }

    mapping(address => AddressRecords) public addressRecord;

    event onStakeTokens(address indexed _caller, uint256 _amount, uint256 _timestamp);
    event onUnstakeTokens(address indexed _caller, uint256 _amount, uint256 _timestamp);

    constructor(IERC20 _darkX) {
        darkX = _darkX;
    }

    function statsOf(address _user) public view returns (uint256 _totalStaked, uint256 _totalUnstaked, uint256 _lastStaked) {
        return (
            addressRecord[_user].totalStaked,
            addressRecord[_user].totalUnstaked
									,addressRecord[_user].lastStaked
        );
    }

    function baseToStaked(uint256 _amount) public view returns (uint256 _stakedAmount) {
        uint256 totalDarkX = darkX.balanceOf(address(this));
        uint256 totalDark0X = this.totalSupply();

        if (totalDark0X == 0 || totalDarkX == 0) {
            return _amount;
        } else {
            return _amount.mul(totalDark0X).div(totalDarkX);
        }
    }

    function stakedToBase(uint256 _amount) public view returns (uint256 _baseAmount) {
        uint256 totalDark0X = this.totalSupply();
        return _amount.mul(darkX.balanceOf(address(this))).div(totalDark0X);
    }

    // Stake darkX, get staking dark0Xs
    function stake(uint256 amount) public {
        uint256 totalDarkX = darkX.balanceOf(address(this));
        uint256 totalDark0X = this.totalSupply();

        if (addressRecord[msg.sender].totalStaked == 0) {
            totalStakers += 1;
        }

        if (totalDark0X == 0 || totalDarkX == 0) {
            _mint(msg.sender, amount);
        } else {
												uint256 mintAmount = amount.mul(totalDark0X).div(totalDarkX);
            _mint(msg.sender, mintAmount);
        }

        darkX.transferFrom(msg.sender, address(this), amount);
        addressRecord[msg.sender].totalStaked += amount;
								addressRecord[msg.sender].lastStaked = block.timestamp;
        allTimeStaked += amount;
        emit onStakeTokens(msg.sender, amount, block.timestamp);
    }

    // Unstake dark0Xs, claim back darkX
    function unstake(uint256 dark0X) public {
						require(block.timestamp >= addressRecord[msg.sender].lastStaked + 24 hours)
        ;uint256 totalDark0X = this.totalSupply();
        uint256 unstakeAmount = dark0X.mul(darkX.balanceOf(address(this))).div(totalDark0X);

        _burn(msg.sender, dark0X);
        darkX.transfer(msg.sender, unstakeAmount);

        addressRecord[msg.sender].totalUnstaked += unstakeAmount;
        allTimeUnstaked += unstakeAmount;

        emit onUnstakeTokens(msg.sender, dark0X, block.timestamp);
    }

    function canRecoverTokens(IERC20 token) internal override view returns (bool) {
        return address(token) != address(this) && address(token) != address(darkX);
    }
}