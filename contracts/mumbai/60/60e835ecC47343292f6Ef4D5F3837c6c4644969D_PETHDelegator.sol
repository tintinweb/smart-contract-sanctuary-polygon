// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./ProxyWithRegistry.sol";
import "./RegistryInterface.sol";
import "./ErrorReporter.sol";

/**
 * @title DeFiPie's PETHDelegator Contract
 * @notice PETH which wrap a delegate to an implementation
 * @author DeFiPie
 */
contract PETHDelegator is ImplementationStorage, ProxyWithRegistry, TokenErrorReporter {

    /**
      * @notice Emitted when implementation is changed
      */
    event NewImplementation(address oldImplementation, address newImplementation);

    /**
     * @notice Construct a new money market
     * @param pETHImplementation_ The address of the PEthImplementation
     * @param controller_ The address of the Controller
     * @param interestRateModel_ The address of the interest rate model
     * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
     * @param initialReserveFactorMantissa_ The initial reserve factor, scaled by 1e18
     * @param name_ ERC-20 name of this token
     * @param symbol_ ERC-20 symbol of this token
     * @param decimals_ ERC-20 decimal precision of this token
     * @param registry_ The address of the registry contract
     */
    constructor(
        address pETHImplementation_,
        address controller_,
        address interestRateModel_,
        uint initialExchangeRateMantissa_,
        uint initialReserveFactorMantissa_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address registry_
    ) {
        // Set registry
        _setRegistry(registry_);
        _setImplementationInternal(pETHImplementation_);

        // First delegate gets to initialize the delegator (i.e. storage contract)
        delegateTo(implementation, abi.encodeWithSignature("initialize(address,address,address,uint256,uint256,string,string,uint8)",
                                                            registry_,
                                                            controller_,
                                                            interestRateModel_,
                                                            initialExchangeRateMantissa_,
                                                            initialReserveFactorMantissa_,
                                                            name_,
                                                            symbol_,
                                                            decimals_));
    }

    /**
     * @notice Internal method to delegate execution to another contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     * @param callee The contract to delegatecall
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateTo(address callee, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returnData) = callee.delegatecall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize())
            }
        }
        return returnData;
    }

    function delegateAndReturn() private returns (bytes memory) {
        (bool success, ) = implementation.delegatecall(msg.data);

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize())

            switch success
            case 0 { revert(free_mem_ptr, returndatasize()) }
            default { return(free_mem_ptr, returndatasize()) }
        }
    }

    /**
     * @notice Delegates execution to an implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     */
    fallback() external payable {
        // delegate all other functions to current implementation
        delegateAndReturn();
    }

    receive() external payable {
        // delegate all other functions to current implementation
        delegateAndReturn();
    }

    function _setImplementation(address newImplementation) external returns(uint) {
        if (msg.sender != RegistryInterface(registry).admin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_NEW_IMPLEMENTATION);
        }

        address oldImplementation = implementation;
        _setImplementationInternal(newImplementation);

        emit NewImplementation(oldImplementation, implementation);

        return(uint(Error.NO_ERROR));
    }
}