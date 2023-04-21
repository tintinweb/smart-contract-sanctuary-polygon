// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract MyContract4 {
    struct User {
        uint256 identityNumber;
        string areasOfInterest;
        uint256 publishedPapers;
        uint256 wantToBeReviewer;
        CID[] userCIDS; /// display only after mapping
    }
    // need a temporary BA to submit a paper.
    struct CID {
        uint256 cid;
        string title;
        string area;
        string publisher;
        string journal;
        uint256 review_flag;
        address submittedBy;
        address[] interestedReviewers;
        uint8 reviewerLen;
    }

    mapping(address => CID) public submission;
    mapping(address => User) public users;
    uint256[] public identities;
    address[] public addresses;

    address[] public submissionAddresses;

    CID[] allCID;
    CID[] pendingCID;

    function register(
        uint256 identityNumber,
        string memory _areasOfInterest,
        uint256 reviewer
    ) public {
        require(
            identityExists(identityNumber) == false,
            "Biometric already registered"
        );
        require(
            addressExists(msg.sender) == false,
            "Address already registered"
        );
        address userAddress = msg.sender;
        User storage user = users[userAddress];
        user.identityNumber = identityNumber;
        user.areasOfInterest = _areasOfInterest;
        user.publishedPapers = 0;
        user.wantToBeReviewer = reviewer;
        identities.push(identityNumber);
        addresses.push(userAddress);
        emit LogNewUser(userAddress, identityNumber, _areasOfInterest);
    }

    // function to check whether the biometric/identity entered by the user exists already in system or not.

    function identityExists(uint256 identity) public view returns (bool) {
        for (uint256 i = 0; i < identities.length; i++) {
            if (identities[i] == identity) {
                return true;
            }
        }
        return false;
    }

    // function to check whether the blockchain address already exists in database or not.
    // Will use Bloom Filter here.

    function addressExists(address userAddress) public view returns (bool) {
        for (uint256 i = 0; i < addresses.length; i++) {
            if (addresses[i] == userAddress) {
                return true;
            }
        }
        return false;
    }

    function getCIDbySubmission (address subAddress) public view returns(CID memory){
        return submission[subAddress];
    }

    function getUserInterest(address userAddress)
        public
        view
        returns (string memory)
    {
        return users[userAddress].areasOfInterest;
    }

    //  function getUserCID(address userAddress) public view returns (CID[] memory) {

    //     return users[userAddress].cids;
    // }

    function getUserPaper(address userAddress) public view returns (uint256) {
        return users[userAddress].publishedPapers;
    }

    function getAllCIDLen() public view returns (uint256) {
        return allCID.length;
    }

    function getUserCIDS(address userAddress)
        public
        view
        returns (CID[] memory)
    {
        return users[userAddress].userCIDS;
    }

    function getPendingCIDS() public returns (CID[] memory) {
        fillPendingCID();
        return pendingCID;
    }

    function fillPendingCID() public {
        uint256 len = getAllCIDLen();
        uint256 i;
        
        for (i = 0; i < len; i++) {
            CID memory cidCheck = submission[submissionAddresses[i]];
            if (cidCheck.review_flag==1) {pendingCID.push(cidCheck);}
        }
    }

    function getSubmissionAddresses() public view returns (address[] memory) {
        return submissionAddresses;
    }

    function setUser(
        address userAddress,
        uint256 paperPublished,
        string memory _areasOfInterest
    ) public {
        User storage user = users[userAddress];
        user.areasOfInterest = _areasOfInterest;
        user.publishedPapers = paperPublished;
    }

    // function to get random addresses based on area of interest and number of published papers
    // here we are selecting 4 random reviewers.
    //
    function selectResearchers(address userSubAddress)
        public
        returns (address[] memory selectedAddresses)
    {
        CID memory selectForCID = submission[userSubAddress];

        uint8 interestedLen = selectForCID.reviewerLen;

        for (uint256 i = 0; i < 1; i++) {
            uint256 randomIndex = uint256(
                keccak256(abi.encodePacked(block.timestamp, block.difficulty))
            ) % interestedLen;
            selectedAddresses[selectedAddresses.length] = selectForCID
                .interestedReviewers[randomIndex];
        }

        emit LogSelectedReviewers(selectedAddresses);
    }

    //function to submit the CID of the manuscript uploaded on IPFS
    // paramater is the unique CID generated when a document is uploaded on IPFS

    function submitManuscript(
        uint256 _cid,
        string memory _title,
        string memory _area,
        string memory _publisher,
        string memory _journal
    ) public {
        address userAddress = msg.sender;
        address[] memory empty;
        // User storage user = users[userAddress];
        CID memory cid = CID({
            cid: _cid,
            title: _title,
            review_flag: 0,
            area: _area,
            publisher: _publisher,
            journal: _journal,
            interestedReviewers: empty,
            submittedBy: userAddress,
            reviewerLen: 0
        });
        submission[userAddress] = cid;
        allCID.push(cid);
        //user.cids.push(cid);
    }

    function mapToPermanent(address permanentAddress, address submissionAddress)
        public
    {
        CID memory cid_2 = submission[submissionAddress];
        User storage user = users[permanentAddress];
        cid_2.review_flag = 1;
        user.userCIDS.push(cid_2);
        user.publishedPapers++;
    }

    function interestedForReview(
        address reviewAddress,
        address submissionAddress
    ) public {
        CID storage cid_3 = submission[submissionAddress];
        cid_3.interestedReviewers.push(reviewAddress);
        cid_3.reviewerLen++;
    }

    event LogNewUser(address user, uint256 identity, string areaOfInterest);
    event LogSelectedReviewers(address[] selectedAddresses);
}