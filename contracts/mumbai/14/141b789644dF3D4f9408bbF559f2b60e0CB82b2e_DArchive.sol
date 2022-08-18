//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract DArchive {
    event ArchiveAdded(string contentID);
    error AlreadyArchived(string contentID);

    mapping(string => bool) public archiveAdded;

    constructor() {}

    function addArchive(string calldata contentID) public {
        if (archiveAdded[contentID]) {
            revert AlreadyArchived(contentID);
        }
        archiveAdded[contentID] = true;
        emit ArchiveAdded(contentID);
    }
}