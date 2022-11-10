// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract BlockX is ERC20, ERC20Burnable, Ownable {
    
    mapping(address => uint256) public userUnlockTime;

    struct VestingAgreement {
        uint256 vestStart; // timestamp at which vesting starts, acts as a vesting delay
        uint256 vestPeriod; // time period over which vesting occurs
        uint256 totalAmount; // total KAP amount to which the beneficiary is promised
        uint256 amountCollected; // portion of `totalAmount` which has already been collected
    }

    mapping(address => VestingAgreement[]) vestingAgreements;
    
    constructor() ERC20("BlockX", "BCX") {
        _mint(msg.sender, 1000000000 * 10 ** 18);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
    
    function lockAndTransfer(address walletAddr, uint256 amount, uint256 vestStart, uint256 vestPeriod)  public onlyOwner returns (bool) {
        require(vestStart > block.timestamp, "Vest Start Date should be later than now");
        require(vestPeriod > 0, "Vest Period is too short");
        vestingAgreements[walletAddr].push(VestingAgreement({
            vestStart: vestStart,
            vestPeriod: vestPeriod,
            totalAmount: amount,
            amountCollected: 0
        }));
        _transfer(_msgSender(), walletAddr, amount);
        return true;
    }
    
    function getLocked(address walletAddr) public returns (uint256) {
        uint256 lockedAmount = 0;
        for (uint i = 0; i < vestingAgreements[walletAddr].length; i++) {
            VestingAgreement memory currentVest = vestingAgreements[walletAddr][i];
            lockedAmount += currentVest.totalAmount - currentVest.amountCollected;
            if (block.timestamp > currentVest.vestStart) {
                lockedAmount -= currentVest.totalAmount * (block.timestamp - currentVest.vestStart) / currentVest.vestPeriod / 60 - currentVest.amountCollected;
            }
        }

        return lockedAmount;
    }
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(amount > 0, 'Amount must not be 0');
        if (from == owner() || from == address(0)) {
            return;
        }
        uint256 stakedAmount = 0;
        uint256 availableStakedAmount = 0;
        uint256 amountToTransfer = amount;
        for (uint i = 0; i < vestingAgreements[from].length; i++) {
            VestingAgreement memory currentVest = vestingAgreements[from][i];
            stakedAmount += currentVest.totalAmount - currentVest.amountCollected;
            if (amountToTransfer == 0) {
                return;
            }
            if (block.timestamp > currentVest.vestStart) {
                uint256 availableToCollect = currentVest.totalAmount * (block.timestamp - currentVest.vestStart) / currentVest.vestPeriod / 60 - currentVest.amountCollected;
                availableStakedAmount += availableToCollect;
                if (amountToTransfer > availableToCollect) {
                    vestingAgreements[from][i].amountCollected += availableStakedAmount;
                    amountToTransfer -= availableStakedAmount;
                } else {
                    vestingAgreements[from][i].amountCollected += amountToTransfer;
                    amountToTransfer = 0;
                }
                
            }
        }

        require(balanceOf(from) - stakedAmount + availableStakedAmount > amount, "Transfer Amount exceeds allowance");
    }
}