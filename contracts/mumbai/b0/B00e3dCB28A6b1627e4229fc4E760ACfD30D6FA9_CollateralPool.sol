// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import './aMATICToken.sol';
import "./SafeMath.sol";
import "./Ownable.sol";
import "./CheckContract.sol";
import "./ICollateralPool.sol";
import "./IaMATICToken.sol";
import "./IRewardsPool.sol";



/*
* Pool for swaping MATIC and aMATIC
*/

contract CollateralPool is Ownable, CheckContract, ICollateralPool {

    uint256 public MATIC_depoisted;
    uint256 public aMATIC_minted;

    address public borrowerOpsAddress;
    address public vaultManagerAddress;
    address public stabilityPoolAddress;
    address public defaultPoolAddress;
    
    IaMATICToken public aMATICTokenAddress;
    IRewardsPool public rewardsPool;

    mapping (address => bool) exists;

    function setAddresses(
        address _borrowerOpsAddress,
        address _vaultManagerAddress,
        address _stabilityPoolAddress,
        address _defaultPoolAddress,
        address _aMATICTokenAddress,
        address _rewardsPoolAddress
    )
        external
        onlyOwner
    {
        checkContract(_borrowerOpsAddress);
        checkContract(_vaultManagerAddress);
        checkContract(_stabilityPoolAddress);
        checkContract(_defaultPoolAddress);
        checkContract(_aMATICTokenAddress);


        borrowerOpsAddress = _borrowerOpsAddress;
        vaultManagerAddress = _vaultManagerAddress;
        stabilityPoolAddress = _stabilityPoolAddress;
        defaultPoolAddress = _defaultPoolAddress;
        aMATICTokenAddress = IaMATICToken(_aMATICTokenAddress);
        rewardsPool = IRewardsPool(_rewardsPoolAddress);

        emit BorrowerOpsAddressChanged(_borrowerOpsAddress);
        emit VaultManagerAddressChanged(_vaultManagerAddress);
        emit StabilityPoolAddressChanged(_stabilityPoolAddress);
        emit DefaultPoolAddressChanged(_defaultPoolAddress);
        emit aMATICTokenAddressChanged(_aMATICTokenAddress);
    }


    // function sendaMATIC(IOSDToken _osdToken)

    receive() external payable {
        
        MATIC_depoisted += msg.value;
        aMATIC_minted += msg.value;
        aMATICTokenAddress.mint(msg.sender, msg.value);
        rewardsPool.setRewardsSnapshot_B(msg.sender);
        // return aMATICTokenAddress.totalSupply();
        // sendaMATIC(msg.value );
    }

    function swapAMATICtoMATIC ( uint _amount) external payable {

        require( aMATICTokenAddress.balanceOf(msg.sender) >= _amount );

        require(MATIC_depoisted >= _amount, "cannot swap more aMATIC than deposited MATIC");
        MATIC_depoisted -= _amount;
        aMATIC_minted -= _amount;

        aMATICTokenAddress.burn(msg.sender, _amount);
        
        (bool success, ) = payable(msg.sender).call{ value: _amount }("");
        require(success, "collateral pool sending matic failed");
    }

    function swapperExists(address _borrower) external view override returns (bool) {
        return exists[_borrower];
    }

    function setSwapper(address _borrower) external override {
        exists[_borrower] = true;
    }
}