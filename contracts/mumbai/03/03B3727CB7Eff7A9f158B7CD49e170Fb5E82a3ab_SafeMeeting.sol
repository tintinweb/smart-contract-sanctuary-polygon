// SPDX-License-Identifier:MIT
pragma solidity ^0.8.8;

/* Errors */
error SafeMeeting__DoesNotHaveAccess(address walletAddress, uint256 companyID);
error SafeMeeting__AlreadyListed(address walletAddress, uint256 companyID);
error SafeMeeting__MeetingNotListed(
    address walletAddress,
    uint256 companyID,
    uint256 meetingID
);

/**
 * @title Safe Meetings
 * @author Wahaj Javed
 * @notice This contract is for creating an untemperable storage for board meeting contents.
 * @dev This implements simple mappings and events to accomplish the task
 */
contract SafeMeeting {
    /* Events */
    event WalletListed(
        address indexed walletAddress,
        uint256 indexed companyID
    );
    /* Structures */
    struct MemberRole {
        string memberName;
        string memberRole;
    }
    struct MeetingData {
        uint256 meetingID;
        string chairpersonName;
        string timestamp;
        uint256 numberOfMembers;
        string contentHash;
        MemberRole[] memberToRoles;
    }
    /* State Variables*/
    // List of the company IDs accessible to the specific wallet
    mapping(address => uint256[]) private s_addressToCompanyID;
    // the company ID pointing to the data of the meetings list
    mapping(uint256 => MeetingData[]) private s_idToMeetingData;
    /* Modifiers */
    modifier hasAccess(address walletAddress, uint256 companyID) {
        uint256[] memory arr = s_addressToCompanyID[walletAddress];
        bool exists = false;
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == companyID) {
                exists = true;
                break;
            }
        }
        if (!exists) {
            revert SafeMeeting__DoesNotHaveAccess(walletAddress, companyID);
        }
        _;
    }
    modifier alreadyListed(address walletAddress, uint256 companyID) {
        uint256[] memory arr = s_addressToCompanyID[walletAddress];
        bool exists = false;
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == companyID) {
                exists = true;
                break;
            }
        }
        if (exists) {
            revert SafeMeeting__AlreadyListed(walletAddress, companyID);
        }
        _;
    }
    modifier IDExists(uint256 companyID, uint256 meetingID) {
        MeetingData[] memory arr = s_idToMeetingData[companyID];
        if (meetingID >= arr.length) {
            revert SafeMeeting__MeetingNotListed(
                msg.sender,
                companyID,
                meetingID
            );
        }
        _;
    }

    /**
     * @notice : Method for storing the meeting data into the specific company ID List
     * @param companyID: The ID of the company
     * @param meetingID: The ID of the meeting recieved from the database
     * @param chairpersonName: The Name of the chairperson in the meeting
     * @param timestamp: The time at which meeting was held
     * @param numberOfMembers: The number of members who attended the meeting
     * @param contentHash: The Hash value of the content PDF
     * @param memberNames: The List of the names of all members
     * @param roles: The List of the roles of all members
     */
    function storeContent(
        uint256 companyID,
        uint256 meetingID,
        string memory chairpersonName,
        string memory timestamp,
        uint256 numberOfMembers,
        string memory contentHash,
        string[] memory memberNames,
        string[] memory roles
    ) public hasAccess(msg.sender, companyID) {
        MeetingData storage meetData = s_idToMeetingData[companyID].push();
        meetData.meetingID = meetingID;
        meetData.chairpersonName = chairpersonName;
        meetData.timestamp = timestamp;
        meetData.numberOfMembers = numberOfMembers;
        meetData.contentHash = contentHash;
        for (uint256 i = 0; i < memberNames.length; i++) {
            meetData.memberToRoles.push();
            MemberRole memory mem = MemberRole(memberNames[i], roles[i]);
            meetData.memberToRoles[i] = mem;
        }
    }

    /**
     * @notice : Method for returning the requested meeting data
     * @param companyID: the ID of the company
     * @param meetingID : the ID of the meeting to be accessed
     * @return The requested meeting data
     */
    function getMeetingData(uint256 companyID, uint256 meetingID)
        public
        view
        hasAccess(msg.sender, companyID)
        IDExists(companyID, meetingID)
        returns (MeetingData memory)
    {
        return s_idToMeetingData[companyID][meetingID];
    }

    /**
     * @notice Method for registering a wallet address to allow access to company data
     * @param walletAddress: The address of the wallet of the user
     * @param companyID : the ID of the company
     */
    function addAddressToCompany(address walletAddress, uint256 companyID)
        external
        alreadyListed(walletAddress, companyID)
    {
        s_addressToCompanyID[walletAddress].push(companyID);
        emit WalletListed(walletAddress, companyID);
    }

    /**
     * @notice Method for returning the list of company IDs accessible to the user
     * @param walletAddress: The address of the wallet of the user
     * @return The list of company IDs
     */
    function getCompanyIDFromWallet(address walletAddress)
        external
        view
        returns (uint256[] memory)
    {
        return s_addressToCompanyID[walletAddress];
    }
}