// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract BlockReview {
    struct Review {
        address reviewer;
        uint rating;
        string comments;
        bool verified;
    }

    struct Project {
        uint id;
        string name;
        uint reviewCount;
    }

    mapping(uint => Project) public projects;
    mapping(uint => mapping(uint => Review)) public projectReviews;

    uint public projectCount = 0;

    // Define events
    event ProjectAdded(uint indexed projectId, string name);
    event ReviewAdded(
        uint indexed projectId,
        address indexed reviewer,
        uint rating,
        string comments,
        bool verified
    );

    function addProject(string memory _name) public {
        projectCount++;
        projects[projectCount] = Project(projectCount, _name, 0);

        // Emit the event
        emit ProjectAdded(projectCount, _name);
    }

    function addReview(
        uint _projectId,
        uint _rating,
        string memory _comments,
        bool _verified
    ) public {
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5");
        require(projects[_projectId].id != 0, "Project does not exist");

        projects[_projectId].reviewCount++;
        uint reviewId = projects[_projectId].reviewCount;
        projectReviews[_projectId][reviewId] = Review(
            msg.sender,
            _rating,
            _comments,
            _verified
        );

        // Emit the event
        emit ReviewAdded(_projectId, msg.sender, _rating, _comments, _verified);
    }

    function getReviews(
        uint _projectId
    )
        public
        view
        returns (
            address[] memory,
            uint[] memory,
            string[] memory,
            bool[] memory
        )
    {
        require(projects[_projectId].id != 0, "Project does not exist");

        uint reviewCount = projects[_projectId].reviewCount;
        address[] memory reviewers = new address[](reviewCount);
        uint[] memory ratings = new uint[](reviewCount);
        string[] memory comments = new string[](reviewCount);
        bool[] memory verifiedStatuses = new bool[](reviewCount);

        for (uint i = 1; i <= reviewCount; i++) {
            Review memory review = projectReviews[_projectId][i];
            reviewers[i - 1] = review.reviewer;
            ratings[i - 1] = review.rating;
            comments[i - 1] = review.comments;
            verifiedStatuses[i - 1] = review.verified;
        }

        return (reviewers, ratings, comments, verifiedStatuses);
    }

    function getReviewCount(uint _projectId) public view returns (uint) {
        require(projects[_projectId].id != 0, "Project does not exist");
        return projects[_projectId].reviewCount;
    }
}