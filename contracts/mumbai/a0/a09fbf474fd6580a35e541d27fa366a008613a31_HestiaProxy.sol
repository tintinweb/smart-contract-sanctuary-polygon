// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./HestiaStorage.sol";

contract HestiaProxy is HestiaStorage {    

    /*
	E001: Caller is not owner
	E002: Not function found
	E003: User already exists
	E004: Unregistered user
	E005: Invalid amount, must be greater than zero
	E006: Tasker without locking enough for all tasks
	E007: Invalid hashIpfsResults, must not be empty
	E008: Error transfer to the zero address
	E009: Error amount balance
	E010: User is not locking
	E011: The amount is higher than the locking
	E012: The locking result no can be less to locking required
	E013: Task not exist
	E014: Task invalid Status
	E015: User is not poster from task
	E016: User is poster from task
	E017: Invalid hashIpfsDetails, must not be empty
	E018: Task invalid Type
	E019: Tasker can not be Job Poster
	E020: Invalid hashIpfsRefined, must not be empty
	E021: Tasker not approve this task
	E022: The value sent must be equal to the amount from task plus fee
	E023: Invalid value for percent payout Tasker
	E024: Error amount balance in vault
	E025: Error amount balance in contract
    E026: Task invalid City
    E027: Task already exists
    */

    /**
     * @dev Delegates the current call to hestia_logic.
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address hestiaLogic) internal {
        require(appStorage.settings.stopped == false, "Hestia Smart Contract Stopped");
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the hestia_logic.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), hestiaLogic, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev Fallback function that delegates calls to the address hestia_logic. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable {
        _delegate(appStorage.settings.addresses[0]);
    }

    /**
     * @dev Receive function that delegates calls to the address hestia_logic. Will run if call data
     * is empty.
     */
    receive() external payable {
        _delegate(appStorage.settings.addresses[0]);
    }

	/**
	 * @dev Initializes the contract.
	 * @param _settings Initial configurations        
	 */
    constructor(HestiaSettings memory _settings) {
        appStorage.owner = msg.sender;
        appStorage.settings = _settings;
    }

    /**
	 * @dev Change settings of Yubiai, only governor.
	 * @param _settings New settings.
	 */
	function changeSettings(HestiaSettings memory _settings) external {
		require(msg.sender == appStorage.owner, "Caller is not owner");
		appStorage.settings = _settings;
	}
}