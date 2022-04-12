// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import './IActivePool.sol';
import "./SafeMath.sol";
import "./Ownable.sol";
import "./CheckContract.sol";
import "./IaMATICToken.sol";

/*
 * The Active Pool holds the ROSE collateral and OSD debt (but not OSD tokens) for all active vaults.
 *
 * When a vault is liquidated, it's ROSE and OSD debt are transferred from the Active Pool, to either the
 * Stability Pool, the Default Pool, or both, depending on the liquidation conditions.
 *
 */
contract ActivePool is Ownable, CheckContract, IActivePool {

    string constant public NAME = "ActivePool";

    address public borrowerOpsAddress;
    address public vaultManagerAddress;
    address public stabilityPoolAddress;
    address public defaultPoolAddress;
    uint256 internal ROSE;  // deposited rose tracker
    uint256 internal OSDDebt;

    // --- Contract setters ---

    function setAddresses(
        address _borrowerOpsAddress,
        address _vaultManagerAddress,
        address _stabilityPoolAddress,
        address _defaultPoolAddress
    )
        external
        onlyOwner
    {
        checkContract(_borrowerOpsAddress);
        checkContract(_vaultManagerAddress);
        checkContract(_stabilityPoolAddress);
        checkContract(_defaultPoolAddress);

        borrowerOpsAddress = _borrowerOpsAddress;
        vaultManagerAddress = _vaultManagerAddress;
        stabilityPoolAddress = _stabilityPoolAddress;
        defaultPoolAddress = _defaultPoolAddress;

        emit BorrowerOpsAddressChanged(_borrowerOpsAddress);
        emit VaultManagerAddressChanged(_vaultManagerAddress);
        emit StabilityPoolAddressChanged(_stabilityPoolAddress);
        emit DefaultPoolAddressChanged(_defaultPoolAddress);
    }

    // --- Getters for public variables. Required by IPool interface ---

    /*
    * Returns the ROSE state variable.
    *
    *Not necessarily equal to the the contract's raw ROSE balance - rose can be forcibly sent to contracts.
    */
    function getROSE() external view override returns (uint) {
        return ROSE;
    }

    function getOSDDebt() external view override returns (uint) {
        return OSDDebt;
    }

    // --- Pool functionality ---

    function sendROSE(IaMATICToken _amatic_Token , address _to, uint _amount) external override { 
        _requireCallerIsBOorVaultMorSP();
        ROSE -= _amount;
        emit ActivePoolROSEBalanceUpdated(ROSE);
        emit RoseSent(_to, _amount);

        if (_amount>0){

        // (bool success, ) = payable(_account).call{ value: _amount }("");
        bool sucess = _amatic_Token.transfer(payable(_to), _amount);
        require(sucess, "ActivePool sendROSE: sending matic failed");
        emit SentRose_ActiveVault(_to,_amount );
        }
    }

    function increaseOSDDebt(uint _amount) external override {
        _requireCallerIsBOorVaultM();
        OSDDebt  += _amount;
        emit ActivePoolOSDDebtUpdated(OSDDebt);
    }

    function decreaseOSDDebt(uint _amount) external override {
        _requireCallerIsBOorVaultMorSP();
        OSDDebt -= _amount;
        emit ActivePoolOSDDebtUpdated(OSDDebt);
    }

    // --- 'require' functions ---

    function _requireCallerIsBorrowerOpsOrDefaultPool() internal view {
        require(
            msg.sender == borrowerOpsAddress ||
            msg.sender == defaultPoolAddress,
            "ActivePool: Caller is neither BO nor Default Pool");
    }

    function _requireCallerIsBOorVaultMorSP() internal view {
        require(
            msg.sender == borrowerOpsAddress ||
            msg.sender == vaultManagerAddress ||
            msg.sender == stabilityPoolAddress,
            "ActivePool: Caller is neither BorrowerOps nor VaultManager nor StabilityPool");
    }

    function _requireCallerIsBOorVaultM() internal view {
        require(
            msg.sender == borrowerOpsAddress ||
            msg.sender == vaultManagerAddress,
            "ActivePool: Caller is neither BorrowerOps nor VaultManager");
    }

    // --- Fallback function ---

    receive() external payable {
        _requireCallerIsBorrowerOpsOrDefaultPool();
        ROSE += msg.value;
        emit ActivePoolROSEBalanceUpdated(ROSE);
    }
}