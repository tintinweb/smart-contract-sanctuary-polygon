// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import {Context} from '@openzeppelin/contracts/utils/Context.sol';
import {IPixelynxOwnership} from 'interfaces/IPixelynxOwnership.sol';

contract PixelynxOwnership is IPixelynxOwnership, Context {
    address private deployer;

    // ERRORS
    error NotADeployedContract();
    // END ERRORS

    mapping(address => bool) private _deployedContracts;
    // deployedContracts[userAddress] == the amount they own of that token
    mapping(address => mapping(address => uint256)) private _userDeployedContractsOwnedTokensCount;

    constructor(address _deployer) {
        deployer = _deployer;
    }

    /**
     * @dev Throws if called by a account which is not the deployer
     */
    modifier isDeployer() {
        require(deployer == _msgSender(), 'deployer only');
        _;
    }

    /// @inheritdoc IPixelynxOwnership
    function isDeployedContract(address deployedContract) external view returns (bool) {
        return _deployedContracts[deployedContract];
    }

    /// @inheritdoc IPixelynxOwnership
    function setDeployedContract(address deployedContract) external isDeployer {
        _deployedContracts[deployedContract] = true;
    }

    /// @inheritdoc IPixelynxOwnership
    function ownershipTransferStateUpdate(address from, address to) external {
        address caller = _msgSender();
        if (!_deployedContracts[caller]) revert NotADeployedContract();

        // dont take of dead addresses as it always come from that
        if (from != address(0) && _userDeployedContractsOwnedTokensCount[caller][from] > 0) {
            _userDeployedContractsOwnedTokensCount[caller][from]--;
        }
        _userDeployedContractsOwnedTokensCount[caller][to]++;
    }

    /// @inheritdoc IPixelynxOwnership
    function userOwnershipCheck(address[] memory contractAddresses, address user) external view returns (bool) {
        if (contractAddresses.length == 0) return true; // No contracts to check
        for (uint256 i = 0; i < contractAddresses.length; i++) {
            if (_userDeployedContractsOwnedTokensCount[contractAddresses[i]][user] > 0) return true; // User holds ownership of at least one contract
        }
        return false; // User doesnt hold ownership of any of the contracts
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

interface IPixelynxOwnership {
    /**
     * Check if the contract is deployed
     */
    function isDeployedContract(address deployedContract) external view returns (bool);
    /**
     * Set the deployed contract address
     */
    function setDeployedContract(address deployedContract) external;

    /**
     * Set the transfer state of ownership
     */
    function ownershipTransferStateUpdate(address from, address to) external;

    /**
     * Check if user owns all the contracts
     */
    function userOwnershipCheck(address[] memory contractAddresses, address user) external view returns (bool);
}