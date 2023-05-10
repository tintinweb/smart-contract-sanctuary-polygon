/**
 *Submitted for verification at polygonscan.com on 2023-05-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract EscrowListing {

    enum EscrowListingStatus {
        Active,
        Inactive
    }

    event Created(uint256 escrowListingId, EscrowListingStatus escrowListingStatus, string category, string subcategory,
        string title, uint startedAt, uint256 price, string contactEmail, string contactSocial, address creator);

    event Updated(uint256 escrowListingId, EscrowListingStatus escrowListingStatus, string category, string subcategory,
        string title, uint256 price, string contactEmail, string contactSocial);

    event StatusUpdate(uint256 escrowListingId, EscrowListingStatus escrowListingStatus);

    struct EscrowListingDetail {
        uint256 escrowListingId;
        EscrowListingStatus escrowListingStatus;
        string category;
        string subcategory;
        string title;
        uint startedAt;
        uint256 price;
        string contactEmail;
        string contactSocial;
        address creator;
        bool valid;
    }

    uint256 count = 0;
    mapping(uint256 => EscrowListingDetail) public escrowListingDetails;
    mapping(address => bool) public areTrustedHandlers;
    EscrowListingDetail escrowListingDetail;

    constructor(address[] memory trustedHandlers) {
        areTrustedHandlers[msg.sender] = true;
        switchTrustedHandlers(trustedHandlers, true);
    }

    function appendItem(
        string memory category,
        string memory subcategory,
        string memory title,
        uint256 price,
        string memory contactEmail,
        string memory contactSocial) public returns (uint256) {

        EscrowListingStatus status = EscrowListingStatus.Active;

        uint startedAt = block.timestamp;

        escrowListingDetail = EscrowListingDetail(
            count,
            status,
            category,
            subcategory,
            title,
            startedAt,
            price,
            contactEmail,
            contactSocial,
            msg.sender,
            true
        );

        escrowListingDetails[count++] = escrowListingDetail;

        emit Created(escrowListingDetail.escrowListingId,
            status,
            category,
            subcategory,
            title,
            startedAt,
            price,
            contactEmail,
            contactSocial,
            msg.sender);
        return escrowListingDetail.escrowListingId;
    }

    function updateStatus(
        uint256 escrowListingId,
        EscrowListingStatus status) public returns (uint256) {

        require(escrowListingDetails[escrowListingId].valid, '___LISTING_NOT_FOUND____');
        require(areTrustedHandlers[msg.sender], '___NOT_TRUSTED___');

        escrowListingDetail = escrowListingDetails[escrowListingId];
        escrowListingDetail.escrowListingStatus = status;

        escrowListingDetails[escrowListingId] = escrowListingDetail;

        emit StatusUpdate(escrowListingDetail.escrowListingId,
            status);
        return escrowListingDetail.escrowListingId;
    }

    function updateItem(
        uint256 escrowListingId,
        EscrowListingStatus status,
        string memory category,
        string memory subcategory,
        string memory title,
        uint256 price,
        string memory contactEmail,
        string memory contactSocial) public returns (uint256) {

        require(escrowListingDetails[escrowListingId].valid, '___LISTING_NOT_FOUND____');
        require(areTrustedHandlers[msg.sender] || escrowListingDetails[escrowListingId].creator == msg.sender);

        escrowListingDetail = escrowListingDetails[escrowListingId];
        escrowListingDetail.escrowListingStatus = status;
        escrowListingDetail.category = category;
        escrowListingDetail.subcategory = subcategory;
        escrowListingDetail.title = title;
        escrowListingDetail.price = price;
        escrowListingDetail.contactEmail = contactEmail;
        escrowListingDetail.contactSocial = contactSocial;

        escrowListingDetails[escrowListingId] = escrowListingDetail;

        emit Updated(escrowListingDetail.escrowListingId,
            status,
            category,
            subcategory,
            title,
            price,
            contactEmail,
            contactSocial);
        return escrowListingDetail.escrowListingId;
    }

    function switchTrustedHandlers(address[] memory _handlers, bool approve) public {
        require(areTrustedHandlers[msg.sender], '___NOT_TRUSTED___');

        for (uint256 i = 0; i < _handlers.length; i++) {
            areTrustedHandlers[_handlers[i]] = approve;
        }
    }

    function checkTrustedHandler(address _addr) public view returns (bool) {
        require(areTrustedHandlers[msg.sender], '___NOT_TRUSTED___');
        return areTrustedHandlers[_addr];
    }

    // recent to oldest
    function getEscrowListingDetailsPagingStatus(uint256 offset, EscrowListingStatus status) external view returns (EscrowListingDetail[] memory escrowListings, uint256 total) {
        uint256 limit = 10;
        if (limit > count - offset) {
            limit = count - offset;
        }

        EscrowListingDetail[] memory values = new EscrowListingDetail[](limit);
        for (uint256 i = 0; i < limit; i++) {
            if (escrowListingDetails[count - 1 - offset - i].escrowListingStatus == status) {
                values[i] = escrowListingDetails[count - 1 - offset - i];
            }
        }
        return (values, count);
    }

    // recent to oldest
    function getEscrowListingDetailsPagingAll(uint256 offset) external view returns (EscrowListingDetail[] memory escrowListings, uint256 total) {
        uint256 limit = 10;
        if (limit > count - offset) {
            limit = count - offset;
        }

        EscrowListingDetail[] memory values = new EscrowListingDetail[](limit);
        for (uint256 i = 0; i < limit; i++) {
            values[i] = escrowListingDetails[count - 1 - offset - i];
        }
        return (values, count);
    }

    function getEscrowListingDetail(uint256 index) external view returns (EscrowListingDetail memory) {
        return escrowListingDetails[index];
    }

}