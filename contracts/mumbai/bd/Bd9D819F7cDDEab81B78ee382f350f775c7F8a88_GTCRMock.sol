// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../curate/IGTCR.sol";

contract GTCRMock is IGTCR {

    function getItemInfo(bytes32)
        external
        override
        view
        returns (
            bytes memory data,
            Status status,
            uint256 numberOfRequests
        ) {
            return (
                data,
                status,
                numberOfRequests
            );
        }

    function getRequestInfo(bytes32 _itemID, uint256 _request)
        external
        override
        view
        returns (
            bool disputed,
            uint256 disputeID,
            uint256 submissionTime,
            bool resolved,
            address payable[3] memory parties,
            uint256 numberOfRounds,
            Party ruling,
            address arbitrator,
            bytes memory arbitratorExtraData,
            uint256 metaEvidenceID
        ) {

        }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IGTCR {
    /// @dev see https://github.com/kleros/tcr/blob/059372068ae3ed380e74d653b713f2a33a3e9551/contracts/GeneralizedTCR.sol
    enum Status {
        Absent, // The item is not in the registry.
        Registered, // The item is in the registry.
        RegistrationRequested, // The item has a request to be added to the registry.
        ClearingRequested // The item has a request to be removed from the registry.
    }

    enum Party {
        None, // Party per default when there is no challenger or requester. Also used for unconclusive ruling.
        Requester, // Party that made the request to change a status.
        Challenger // Party that challenges the request to change a status.
    }

    /** @dev Returns item's information. Includes length of requests array.
     *  @param _itemID The ID of the queried item.
     *  @return data The data describing the item.
     *  @return status The current status of the item.
     *  @return numberOfRequests Length of list of status change requests made for the item.
     */
    function getItemInfo(bytes32 _itemID)
        external
        view
        returns (
            bytes memory data,
            Status status,
            uint256 numberOfRequests
        );

    function getRequestInfo(bytes32 _itemID, uint256 _request)
        external
        view
        returns (
            bool disputed,
            uint256 disputeID,
            uint256 submissionTime,
            bool resolved,
            address payable[3] memory parties,
            uint256 numberOfRounds,
            Party ruling,
            address arbitrator,
            bytes memory arbitratorExtraData,
            uint256 metaEvidenceID
        );
}