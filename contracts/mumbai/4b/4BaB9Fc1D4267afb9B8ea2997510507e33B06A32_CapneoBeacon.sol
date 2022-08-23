// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ICapneoBeacon } from "./interfaces/ICapneoBeacon.sol";

contract CapneoBeacon is ICapneoBeacon {

    struct Upgrade {
        address implementation;
        uint256 timestamp;
    }

    address public immutable CORE = msg.sender;
    uint256 public immutable UPGRADE_DELAY;
    address internal _implementation;
    Upgrade internal _proposedUpgrade;

    modifier isCore() {
        if(!_isCore()) revert CallerNotCore(msg.sender, CORE);
        _;
    }
    
    constructor(address imp, uint256 minimumUpgradeDelay) {
        _setImplementation(imp);
        UPGRADE_DELAY = minimumUpgradeDelay;
    }

    function implementation() external view returns(address) {
        return _implementation;        
    }

    function proposeUpgrade(address newImplementation) external isCore {
        _setProposedUpgrade(newImplementation, block.timestamp + UPGRADE_DELAY);
    }

    function upgrade(address newImplementation) external isCore {
        if(UPGRADE_DELAY != 0) {
            require(_proposedUpgrade.timestamp < block.timestamp);
            require(_proposedUpgrade.implementation == newImplementation);
        }
        _setImplementation(newImplementation);
    }

    function _setImplementation(address imp) internal {
        require(imp.code.length > 0);
        emit Upgraded(_implementation, imp);
        _implementation = imp;
    }

    function _setProposedUpgrade(address proposedImplementation, uint256 earliest) internal {
        emit UpgradeProposed(proposedImplementation, earliest);
        _proposedUpgrade = Upgrade(proposedImplementation, earliest);
    }

    function _isCore() internal view returns(bool) {
        return msg.sender == CORE;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICapneoBeacon {

    event UpgradeProposed(address proposedImplementation, uint256 earliestExecution);
    event Upgraded(address oldImp, address newImp);
    
    error CallerNotCore(address have, address core);

    function implementation() external view returns(address);
    
    function proposeUpgrade(address newImplementation) external;
    function upgrade(address newImplementation) external;

    function CORE() external view returns(address);


}