// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.0;

import "./CheckContract.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ILockupContractFactory.sol";
import "./LockupContract.sol";

/*
* The LockupContractFactory deploys LockupContracts - its main purpose is to keep a registry of valid deployed 
* LockupContracts. 
* 
* This registry is checked by OrumToken when the Liquity deployer attempts to transfer Orum tokens. During the first year 
* since system deployment, the Liquity deployer is only allowed to transfer Orum to valid LockupContracts that have been 
* deployed by and recorded in the LockupContractFactory. This ensures the deployer's Orum can't be traded or staked in the
* first year, and can only be sent to a verified LockupContract which unlocks at least one year after system deployment.
*
* LockupContracts can of course be deployed directly, but only those deployed through and recorded in the LockupContractFactory 
* will be considered "valid" by OrumToken. This is a convenient way to verify that the target address is a genuine 
* LockupContract.
*/

contract LockupContractFactory is ILockupContractFactory, Ownable, CheckContract {
    using SafeMath for uint;

    // --- Data ---
    string constant public NAME = "LockupContractFactory";

    uint constant public SECONDS_IN_ONE_YEAR = 31536000;

    address public orumTokenAddress;
    
    mapping (address => address) public lockupContractToDeployer;

    // --- Functions ---

    function setOrumTokenAddress(address _orumTokenAddress) external override onlyOwner {
        checkContract(_orumTokenAddress);

        orumTokenAddress = _orumTokenAddress;
        emit OrumTokenAddressSet(_orumTokenAddress);
    }

    function deployLockupContract(address _beneficiary, uint _unlockTime) external override {
        address orumTokenAddressCached = orumTokenAddress;
        _requireOrumAddressIsSet(orumTokenAddressCached);
        LockupContract lockupContract = new LockupContract(
                                                        orumTokenAddressCached,
                                                        _beneficiary, 
                                                        _unlockTime);

        lockupContractToDeployer[address(lockupContract)] = msg.sender;
        emit LockupContractDeployedThroughFactory(address(lockupContract), _beneficiary, _unlockTime, msg.sender);
    }

    function isRegisteredLockup(address _contractAddress) public view override returns (bool) {
        return lockupContractToDeployer[_contractAddress] != address(0);
    }

    // --- 'require'  functions ---
    function _requireOrumAddressIsSet(address _orumTokenAddress) internal pure {
        require(_orumTokenAddress != address(0), "LCF: Orum Address is not set");
    }
}