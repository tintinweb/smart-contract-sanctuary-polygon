// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.17;

import {UsingTellor} from "./UsingTellor.sol";
import {IDIVAOwnershipSecondary} from "./interfaces/IDIVAOwnershipSecondary.sol";

/**
 * @notice Ownership contract for secondary chain which uses the Tellor oracle protocol to sync
 * the main chain owner returned by `getCurrentOwner()` function in `DIVAOwnershipMain.sol`.
 * @dev `setOwner()` function pulls the latest value that remained undisputed for more than 12 hours.
 * - Reverts with `NoOracleSubmission` if there is no value inside the Tellor smart contract that remained
 *   undisputed for more than 12 hours.
 * - Reverts with `ValueTooOld` if the last reported undisputed value is older than 36 hours.
 * 
 * Tellor reporters can verify the validity of a reported value by simulating the return value
 * of `getCurrentOwner()` on the main chain as of a block with a timestamp shortly before the
 * time of reporting using an archive node.
 *  
 * As Tellor is a permissionless system that allows anyone to report outcomes, constant
 * monitoring of value submissions is required. Incentives built into the Tellor system encourage
 * Tellor watchers to dispute inaccurate reportings. The main chain owner has a
 * natural incentive to participate as a Tellor watcher and dispute any wrong submissions.
 * In the event that an invalid submission goes unnoticed and a bad actor takes over ownership
 * on a secondary chain, the potential harm is limited. Functions such as `updateFees`,
 * `updateSettlementPeriods`, `updateFallbackDataProvider`, and `updateTreasury` have an
 * activation delay and can be revoked as soon as the rightful owner regains control. The
 * revoke functions as well as `pauseReturnCollateral` do not implement a delay and changes will
 * take immediate effect if triggered by an unauthorized account. Former will require the rightful
 * owner to trigger the updates again after regaining control. Latter will delay the possibility
 * to redeem by a maximum of 8 days, but will not interrupt the settlement process, ensuring that
 * all outstanding pools will settle correctly. The pause can be immediately reversed once the
 * rightful owner regains control.
 */
contract DIVAOwnershipSecondary is UsingTellor, IDIVAOwnershipSecondary {

    address private _owner;
    address private immutable _ownershipContractMainChain;
    uint256 private immutable _mainChainId;
    uint256 private constant _minUndisputedPeriod = 12 hours;
    uint256 private constant _maxAllowedAgeOfReportedValue = 36 hours;

    constructor(
        address _initialOwner,
        address payable _tellorAddress,
        uint256 mainChainId_,
        address ownershipContractMainChain_
    ) payable UsingTellor(_tellorAddress) {
        _owner = _initialOwner; 
        _mainChainId = mainChainId_;
        _ownershipContractMainChain = ownershipContractMainChain_;
    }
    
    function setOwner() external override {
        
        // Get reported owner address from Tellor smart contract.
        // Only values that remained undisputed for at least 12 hours and are not older
        // than 36 hours are accepted.

        // Get queryId
        bytes32 _queryId = getQueryId();

        // Retrieve the latest value (encoded owner address) that remained undisputed for at least
        // 12 hours as well as the reporting timestamp
        (bytes memory _valueRetrieved, uint256 _timestampRetrieved) = 
            getDataBefore(_queryId, block.timestamp - _minUndisputedPeriod);

        
        // Check that data exists
        if (_timestampRetrieved == 0) {
            revert NoOracleSubmission();
        }

        // Check that value is not older than 36 days
        uint256 _maxAllowedTimestampRetrieved = block.timestamp - _maxAllowedAgeOfReportedValue;
        if (_timestampRetrieved < _maxAllowedTimestampRetrieved) {
            revert ValueTooOld(_timestampRetrieved, _maxAllowedTimestampRetrieved);
        }

        // Reported owner address is expected to match the address returned by `getCurrentOwner`
        // in `DIVAOwnershipMain.sol` as of the time of reporting (`_timestampRetrieved`).
        address _formattedOwner = abi.decode(_valueRetrieved, (address));

        // Update owner to the owner returned by the Tellor protocol
        _owner = _formattedOwner;

        // Log set owner on secondary chain
        emit OwnerSet(_formattedOwner);
    }

    function getCurrentOwner() external view override returns (address) {
        return _owner;
    }

    function getOwnershipContractMainChain() external view override returns (address) {
        return _ownershipContractMainChain;
    }

    function getMainChainId() external view override returns (uint256) {
        return _mainChainId;
    }

    function getQueryId() public view override returns (bytes32) {
        // Construct Tellor queryID:
        // https://github.com/tellor-io/dataSpecs/blob/main/types/EVMCall.md
        // 0xa18a186b = bytes4(keccak256(abi.encodePacked("getCurrentOwner()")));
        return
            keccak256(
                abi.encode(
                    "EVMCall",
                    abi.encode(_mainChainId, _ownershipContractMainChain, 0xa18a186b)
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./interfaces/ITellor.sol";

/**
 * @title UserContract
 * This contract allows for easy integration with the Tellor System
 * by helping smart contracts to read data from Tellor
 */
contract UsingTellor {
    ITellor public tellor;

    /*Constructor*/
    /**
     * @dev the constructor sets the oracle address in storage
     * @param _tellor is the Tellor Oracle address
     */
    constructor(address payable _tellor) {
        tellor = ITellor(_tellor);
    }

    /*Getters*/
    /**
     * @dev Retrieves the latest value for the queryId before the specified timestamp
     * @param _queryId is the queryId to look up the value for
     * @param _timestamp before which to search for latest value
     * @return _value the value retrieved
     * @return _timestampRetrieved the value's timestamp
     */
    function getDataBefore(bytes32 _queryId, uint256 _timestamp)
        public
        view
        returns (bytes memory _value, uint256 _timestampRetrieved)
    {
        (, _value, _timestampRetrieved) = tellor.getDataBefore(
            _queryId,
            _timestamp
        );
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.17;

import {IDIVAOwnershipShared} from "../interfaces/IDIVAOwnershipShared.sol";

interface IDIVAOwnershipSecondary is IDIVAOwnershipShared {
    // Thrown in `setOwner` if Tellor reporting timestamp is older than 36 hours
    error ValueTooOld(
        uint256 _timestampRetrieved,
        uint256 _maxAllowedTimestampRetrieved
    );

    // Thrown in `setOwner` if there is no value inside the Tellor smart contract
    // that remained undisputed for more than 12 hours
    error NoOracleSubmission();

    /**
     * @notice Emitted when owner is set on the secondary chain.
     * @param owner The owner address set on the secondary chain.
     */
    event OwnerSet(address indexed owner);

    /**
     * @notice Function to update the owner on the secondary chain based on the
     * value reported to the Tellor smart contract. The reported value has to
     * satisfy the following two conditions in order to be considered valid:
     *   1. Reported value hasn't been disputed for at least 12 hours
     *   2. Timestamp of reporting is not older than 36 hours
     * @dev Reverts if:
     * - there is no value inside the Tellor smart contract that remained
     *   undisputed for more than 12 hours.
     * - the last reported undisputed value is older than 36 hours.
     */
    function setOwner() external;

    /**
     * @notice Function to return the ownership contract address on the main chain.
     */
    function getOwnershipContractMainChain() external view returns (address);

    /**
     * @notice Function to return the main chain id.
     */
    function getMainChainId() external view returns (uint256);

    /**
     * @notice Function to return the Tellor query Id which is used to report values
     * to Tellor protocol.
     * @dev The query Id is the `keccak256` hash of an encoded string consisting of
     * the query type string "EVMCall", the main chain Id (1 for Ethereum), the address of
     * the ownership contract on main chain as well as the function signature of the main
     * chain function `getCurrentOwner()` (`0xa18a186b`). Refer to
     * the Tellor specs (https://github.com/tellor-io/dataSpecs/blob/main/types/EVMCall.md)
     * for details.
     */
    function getQueryId() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ITellor {
    function getDataBefore(bytes32 _queryId, uint256 _timestamp)
        external
        view
        returns (
            bool _ifRetrieve,
            bytes memory _value,
            uint256 _timestampRetrieved
        );
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.17;

interface IDIVAOwnershipShared {
    /**
     * @notice Function to return the current DIVA Protocol owner address.
     * @return Current owner address. On main chain, equal to the existing owner
     * during an on-going election cycle and equal to the new owner afterwards. On secondary
     * chain, equal to the address reported via Tellor oracle.
     */
    function getCurrentOwner() external view returns (address);
}