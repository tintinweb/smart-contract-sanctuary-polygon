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
    
    ILendingPoolAddressesProvider provider;
    using SafeMath for uint256;
    uint256 flashAaveAmt0;
    uint256 flashDaiAmt1;
    uint256 flashLinkAmt2;
    address lendingPoolAddr;
    
    // polygon reserve asset addresses
    address polygonAave = 0xD6DF932A45C0f255f85145f286eA0b292B21C90B;
    address polygonDai = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
    address polygonLink = 0x53E0bca35eC356BD5ddDFebbD1Fc0fD03FaBad39;
    
    // intantiate lending pool addresses provider and get lending pool address
    constructor(ILendingPoolAddressesProvider _addressProvider) FlashLoanReceiverBase(_addressProvider) public {
        provider = _addressProvider;
        lendingPoolAddr = provider.getLendingPool();
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
        
        // initialise lending pool instance
        ILendingPool lendingPool = ILendingPool(lendingPoolAddr);
        
        // deposits the flashed AAVE, DAI and Link liquidity onto the lending pool
        flashDeposit(lendingPool);

        uint256 borrowAmt = .1 * 1e18; // to borrow 100 units of x asset
        
        // borrows 'borrowAmt' amount of LINK using the deposited collateral
        flashBorrow(lendingPool, polygonLink, borrowAmt);
        
        // repays the 'borrowAmt' mount of LINK to unlock the collateral
        flashRepay(lendingPool, polygonLink, borrowAmt);
 
        // withdraws the AAVE, DAI and LINK collateral from the lending pool
        flashWithdraw(lendingPool);

        // Approve the LendingPool contract allowance to *pull* the owed amount
        // i.e. AAVE V2's way of repaying the flash loan
        for (uint i = 0; i < assets.length; i++) {
            uint amountOwing = amounts[i].add(premiums[i]);
            IERC20(assets[i]).approve(address(_lendingPool), amountOwing);
        }

        return true;
    }

    /*
    * Deposits the flashed AAVE, DAI and LINK liquidity onto the lending pool as collateral
    */
    function flashDeposit(ILendingPool _lendingPool) public {
        
        // approve lending pool
        IERC20(polygonDai).approve(lendingPoolAddr, flashDaiAmt1);
        IERC20(polygonAave).approve(lendingPoolAddr, flashAaveAmt0);
        IERC20(polygonLink).approve(lendingPoolAddr, flashLinkAmt2);
        
        // deposit the flashed AAVE, DAI and LINK as collateral
        _lendingPool.deposit(polygonDai, flashDaiAmt1, address(this), uint16(0));
        _lendingPool.deposit(polygonAave, flashAaveAmt0, address(this), uint16(0));
        _lendingPool.deposit(polygonLink, flashLinkAmt2, address(this), uint16(0));
        
    }

    /*
    * Withdraws the AAVE, DAI and LINK collateral from the lending pool
    */
    function flashWithdraw(ILendingPool _lendingPool) public {
        
        _lendingPool.withdraw(polygonAave, flashAaveAmt0, address(this));
        _lendingPool.withdraw(polygonDai, flashDaiAmt1, address(this));
        _lendingPool.withdraw(polygonLink, flashLinkAmt2, address(this));
        
    }
    
    /*
    * Borrows _borrowAmt amount of _borrowAsset based on the existing deposited collateral
    */
    function flashBorrow(ILendingPool _lendingPool, address _borrowAsset, uint256 _borrowAmt) public {
        
        // borrowing x asset at stable rate, no referral, for yourself
        _lendingPool.borrow(
            _borrowAsset, 
            _borrowAmt, 
            1, 
            uint16(0), 
            address(this)
        );
        
    }

    /*
    * Repays _repayAmt amount of _repayAsset
    */
    function flashRepay(ILendingPool _lendingPool, address _repayAsset, uint256 _repayAmt) public {
        
        // approve the repayment from this contract
        IERC20(_repayAsset).approve(lendingPoolAddr, _repayAmt);
        
        _lendingPool.repay(
            _repayAsset, 
            _repayAmt, 
            1, 
            address(this)
        );
    }

    /*
    * Repays _repayAmt amount of _repayAsset
    */
    function flashSwapBorrowRate(ILendingPool _lendingPool, address _asset, uint256 _rateMode) public {
        
        _lendingPool.swapBorrowRateMode(_asset, _rateMode);
        
    }
    
    /*
    * This function is manually called to commence the flash loans sequence
    */
    function executeFlashLoans(uint256 _flashAaveAmt0, uint256 _flashDaiAmt1, uint256 _flashLinkAmt2) public onlyOwner {
        address receiverAddress = address(this);

        // the various assets to be flashed
        address[] memory assets = new address[](3);
        assets[0] = polygonAave; 
        assets[1] = polygonDai;
        assets[2] = polygonLink;
        
        // the amount to be flashed for each asset
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = _flashAaveAmt0;
        amounts[1] = _flashDaiAmt1;
        amounts[2] = _flashLinkAmt2;
        
        flashAaveAmt0 = _flashAaveAmt0;
        flashDaiAmt1 = _flashDaiAmt1;
        flashLinkAmt2 = _flashLinkAmt2;

        // 0 = no debt, 1 = stable, 2 = variable
        uint256[] memory modes = new uint256[](3);
        modes[0] = 0;
        modes[1] = 0;
        modes[2] = 0;

        address onBehalfOf = address(this);
        bytes memory params = "";
        uint16 referralCode = 0;

        _lendingPool.flashLoan(
            receiverAddress,
            assets,
            amounts,
            modes,
            onBehalfOf,
            params,
            referralCode
        );
    }
    
        
    /*
    * Rugpull all ERC20 tokens from the contract
    */
    function rugPull() public payable onlyOwner {
        
        // withdraw all ETH
        msg.sender.call{ value: address(this).balance }("");   
    }
}