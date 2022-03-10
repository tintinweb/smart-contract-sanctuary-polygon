// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "./IDefaultPool.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./CheckContract.sol";

/*
 * The Default Pool holds the ROSE and OSD debt (but not OSD tokens) from liquidations that have been redistributed
 * to active vaults but not yet "applied", i.e. not yet recorded on a recipient active vault's struct.
 *
 * When a vault makes an operation that applies its pending ROSE and OSD debt, its pending ROSE and OSD debt is moved
 * from the Default Pool to the Active Pool.
 */
contract DefaultPool is Ownable, CheckContract, IDefaultPool {

    string constant public NAME = "DefaultPool";

    address public vaultManagerAddress;
    address public activePoolAddress;
    uint256 internal ROSE;  // deposited ROSE tracker
    uint256 internal OSDDebt;  // debt

    // --- Dependency setters ---

    function setAddresses(
        address _vaultManagerAddress,
        address _activePoolAddress
    )
        external
        onlyOwner
    {
        checkContract(_vaultManagerAddress);
        checkContract(_activePoolAddress);

        vaultManagerAddress = _vaultManagerAddress;
        activePoolAddress = _activePoolAddress;

        emit VaultManagerAddressChanged(_vaultManagerAddress);
        emit ActivePoolAddressChanged(_activePoolAddress);
    }

    // --- Getters for public variables. Required by IPool interface ---

    /*
    * Returns the ROSE state variable.
    *
    * Not necessarily equal to the the contract's raw ROSE balance - ether can be forcibly sent to contracts.
    */
    function getROSE() external view override returns (uint) {
        return ROSE;
    }

    function getOSDDebt() external view override returns (uint) {
        return OSDDebt;
    }

    // --- Pool functionality ---

    function sendROSEToActivePool(uint _amount) external override {
        _requireCallerIsVaultManager();
        address activePool = activePoolAddress; // cache to save an SLOAD
        ROSE -= _amount;
        emit DefaultPoolROSEBalanceUpdated(ROSE);
        emit RoseSent(activePool, _amount);

        (bool success, ) = activePool.call{ value: _amount }("");
        require(success, "DefaultPool: sending ROSE failed");
    }

    function increaseOSDDebt(uint _amount) external override {
        _requireCallerIsVaultManager();
        OSDDebt += _amount;
        emit DefaultPoolOSDDebtUpdated(OSDDebt);
    }

    function decreaseOSDDebt(uint _amount) external override {
        _requireCallerIsVaultManager();
        OSDDebt -= _amount;
        emit DefaultPoolOSDDebtUpdated(OSDDebt);
    }

    // --- 'require' functions ---

    function _requireCallerIsActivePool() internal view {
        require(msg.sender == activePoolAddress, "DefaultPool: Caller is not the ActivePool");
    }

    function _requireCallerIsVaultManager() internal view {
        require(msg.sender == vaultManagerAddress, "DefaultPool: Caller is not the VaultManager");
    }

    // --- Fallback function ---

    receive() external payable {
        _requireCallerIsActivePool();
        ROSE += msg.value;
        emit DefaultPoolROSEBalanceUpdated(ROSE);
    }
}