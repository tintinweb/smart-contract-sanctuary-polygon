// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import { FlashLoanReceiverBase } from "./FlashLoanReceiverBase.sol";
import { ILendingPool, ILendingPoolAddressesProvider, IERC20 } from "./Interfaces.sol";
import { SafeMath } from "./Libraries.sol";
import "./Ownable.sol";

/*
* A contract that executes the following logic in a single atomic transaction:
*
*   1. Gets a batch flash loan of AAVE, DAI and LINK
*   2. Deposits all of this flash liquidity onto the Aave V2 lending pool
*   3. Borrows 100 LINK based on the deposited collateral
*   4. Repays 100 LINK and unlocks the deposited collateral
*   5. Withdrawls all of the deposited collateral (AAVE/DAI/LINK)
*   6. Repays batch flash loan including the 9bps fee
*
*/
contract BatchFlashDemo is FlashLoanReceiverBase, Ownable {
    using SafeMath for uint256;
    uint256 flashAmt;

    // kovan reserve asset addresses
    address Usdc = 0x2058A9D7613eEE744279e3856Ef0eAda5FCbaA7e;

    event RepayApproved(address token, uint256 amount);
    event TokenBalance(address token, uint256 balance);
    
    // intantiate lending pool addresses provider and get lending pool address
    constructor() FlashLoanReceiverBase() public {
    }

    /**
        This function is called after your contract has received the flash loaned amount
     */
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    )
        external
        override
        returns (bool)
    {
        
       

        // Approve the LendingPool contract allowance to *pull* the owed amount
        // i.e. AAVE V2's way of repaying the flash loan
        for (uint i = 0; i < assets.length; i++) {
            emit TokenBalance(assets[i],  IERC20(assets[i]).balanceOf(address(this)));
            uint amountOwing = amounts[i].add(premiums[i]);
            IERC20(assets[i]).approve(address(_lendingPool), amountOwing);
            emit RepayApproved(assets[i], amountOwing);
        }

        return true;
    }

   
    
    /*
    * This function is manually called to commence the flash loans sequence
    */
    function executeFlashLoans(uint256 _amt) public onlyOwner {
        address receiverAddress = address(this);

        // the various assets to be flashed
        address[] memory assets = new address[](1);
        assets[0] = Usdc;
        
        // the amount to be flashed for each asset
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _amt;
        
        flashAmt = _amt;

        // 0 = no debt, 1 = stable, 2 = variable
        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;

        address onBehalfOf = address(this);
        bytes memory params = "";
        uint16 referralCode = 0;

        emit TokenBalance(Usdc, IERC20(Usdc).balanceOf(address(this)));
        //require(referralCode != 0, 'Revert test.');
        _lendingPool.flashLoan(
            receiverAddress,
            assets,
            amounts,
            modes,
            onBehalfOf,
            params,
            referralCode
        );
        emit TokenBalance(Usdc, IERC20(Usdc).balanceOf(address(this)));
    }

    /*
    * This function is manually called to commence the flash loans sequence
    */
    function executeFlashLoansTest(uint256 _amt) public onlyOwner {
        address receiverAddress = address(this);

        // the various assets to be flashed
        address[] memory assets = new address[](1);
        assets[0] = Usdc;
        
        // the amount to be flashed for each asset
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _amt;
        
        flashAmt = _amt;

        // 0 = no debt, 1 = stable, 2 = variable
        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;

        address onBehalfOf = address(this);
        bytes memory params = "";
        uint16 referralCode = 0;

        emit TokenBalance(Usdc, IERC20(Usdc).balanceOf(address(this)));
        return;
    }
    
        
    /*
    * Rugpull all ERC20 tokens from the contract
    */
    function rugPull() public payable onlyOwner {
        
        // withdraw all ETH
        msg.sender.call{ value: address(this).balance }("");
        
        // withdraw all x ERC20 tokens
        IERC20(Usdc).transfer(msg.sender, IERC20(Usdc).balanceOf(address(this)));
        //IERC20(kovanDai).transfer(msg.sender, IERC20(kovanDai).balanceOf(address(this)));
        //IERC20(kovanLink).transfer(msg.sender, IERC20(kovanLink).balanceOf(address(this)));
    }
    
}