// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "./ICollSurplusPool.sol";
import "./Ownable.sol";
import "./CheckContract.sol";

contract CollSurplusPool is Ownable, CheckContract, ICollSurplusPool {

    string constant public NAME = "CollSurplusPool";

    address public borrowerOpsAddress;
    address public vaultManagerAddress;
    address public activePoolAddress;

    // deposited ether tracker
    uint256 internal ROSE;
    // Collateral surplus claimable by vault owners
    mapping (address => uint) internal balances;
    
    // --- Contract setters ---

    function setAddresses(
        address _borrowerOpsAddress,
        address _vaultManagerAddress,
        address _activePoolAddress
    )
        external
        override
        onlyOwner
    {
        checkContract(_borrowerOpsAddress);
        checkContract(_vaultManagerAddress);
        checkContract(_activePoolAddress);

        borrowerOpsAddress = _borrowerOpsAddress;
        vaultManagerAddress = _vaultManagerAddress;
        activePoolAddress = _activePoolAddress;

        emit BorrowerOpsAddressChanged(_borrowerOpsAddress);
        emit VaultManagerAddressChanged(_vaultManagerAddress);
        emit ActivePoolAddressChanged(_activePoolAddress);
    }

    /* Returns the ROSE state variable at ActivePool address.
       Not necessarily equal to the raw ether balance - ether can be forcibly sent to contracts. */
    function getROSE() external view override returns (uint) {
        return ROSE;
    }

    function getCollateral(address _account) external view override returns (uint) {
        return balances[_account];
    }

    // --- Pool functionality ---

    function accountSurplus(address _account, uint _amount) external override {
        _requireCallerIsVaultManager();

        uint newAmount = balances[_account] + _amount;
        balances[_account] = newAmount;

        emit CollBalanceUpdated(_account, newAmount);
    }

    function claimColl(address _account) external override {
        _requireCallerIsBorrowerOps();
        uint claimableColl = balances[_account];
        require(claimableColl > 0, "CollSurplusPool: No collateral available to claim");

        balances[_account] = 0;
        emit CollBalanceUpdated(_account, 0);

        ROSE -= claimableColl;
        emit RoseSent(_account, claimableColl);

        (bool success, ) = _account.call{ value: claimableColl }("");
        require(success, "CollSurplusPool: sending ROSE failed");
    }

    // --- 'require' functions ---

    function _requireCallerIsBorrowerOps() internal view {
        require(
            msg.sender == borrowerOpsAddress,
            "CollSurplusPool: Caller is not Borrower Ops");
    }

    function _requireCallerIsVaultManager() internal view {
        require(
            msg.sender == vaultManagerAddress,
            "CollSurplusPool: Caller is not VaultManager");
    }

    function _requireCallerIsActivePool() internal view {
        require(
            msg.sender == activePoolAddress,
            "CollSurplusPool: Caller is not Active Pool");
    }

    // --- Fallback function ---

    receive() external payable {
        _requireCallerIsActivePool();
        ROSE += msg.value;
    }
}