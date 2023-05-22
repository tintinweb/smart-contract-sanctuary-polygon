// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract ZikiLeaks {
    // Publication id to upvotes count
    mapping(string => uint256) public upvotes;

    // Publication id to downvotes count
    mapping(string => uint256) public downvotes;

    // Voted publication
    mapping(address => bool) public voted;

    // =========================== Events ==============================

    /**
     * @dev Emitted when a publication is upvoted
     */
    event PublicationUpvoted(string indexed publicationId, address voter);

        /**
     * @dev Emitted when a publication is upvoted
     */
    event PublicationDownvoted(string indexed publicationId, address voter);


    // =========================== User Functions ==============================

    /**
     * @dev Upvotes a publication
     * @param _publicationId The publication id
     */
    function upvotePublication(string memory _publicationId) public {
        require(!voted[msg.sender], "Already voted");
        upvotes[_publicationId] += 1;
        voted[msg.sender] = true;


        emit PublicationUpvoted(_publicationId, msg.sender);
    }

        /**
     * @dev Downvotes a publication
     * @param _publicationId The publication id
     */
    function downvotePublication(string memory _publicationId) public {
        require(!voted[msg.sender], "Already voted");
        downvotes[_publicationId] += 1;
        voted[msg.sender] = true;


        emit PublicationDownvoted(_publicationId, msg.sender);
    }
}