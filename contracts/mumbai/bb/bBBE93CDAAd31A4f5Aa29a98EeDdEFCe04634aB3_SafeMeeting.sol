// SPDX-License-Identifier:MIT
pragma solidity ^0.8.8;

/* Errors */
error SafeMeeting__DoesNotHaveAccess(address walletAddress, string companyID);
error SafeMeeting__AlreadyListed(address walletAddress, string companyID);
error SafeMeeting__MeetingNotListed(
    address walletAddress,
    string companyID,
    string meetingID
);

/**
 * @title Safe Meetings
 * @author Wahaj Javed
 * @notice This contract is for creating an untemperable storage for board meeting contents.
 * @dev This implements simple mappings and events to accomplish the task
 */
contract SafeMeeting {
    /* Events */
    event WalletListed(address indexed walletAddress, string indexed companyID);
    /* Structures */
    struct MemberRole {
        string memberName;
        string memberRole;
    }
    struct MeetingData {
        string meetingID;
        string chairpersonName;
        string timestamp;
        uint256 numberOfMembers;
        string contentHash;
        MemberRole[] memberToRoles;
    }
    /* State Variables*/
    // List of the company IDs accessible to the specific wallet
    mapping(address => string[]) private s_addressToCompanyID;
    // the company ID pointing to the data of the meetings list
    mapping(string => mapping(string => MeetingData)) private s_idToMeetingData;
    /* Modifiers */
    modifier hasAccess(address walletAddress, string memory companyID) {
        string[] memory arr = s_addressToCompanyID[walletAddress];
        bool exists = false;
        for (uint256 i = 0; i < arr.length; i++) {
            if (keccak256(bytes(arr[i])) == keccak256(bytes(companyID))) {
                exists = true;
                break;
            }
        }
        if (!exists) {
            revert SafeMeeting__DoesNotHaveAccess(walletAddress, companyID);
        }
        _;
    }
    modifier alreadyListed(address walletAddress, string memory companyID) {
        string[] memory arr = s_addressToCompanyID[walletAddress];
        bool exists = false;
        for (uint256 i = 0; i < arr.length; i++) {
            if (keccak256(bytes(arr[i])) == keccak256(bytes(companyID))) {
                exists = true;
                break;
            }
        }
        if (exists) {
            revert SafeMeeting__AlreadyListed(walletAddress, companyID);
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
        string memory companyID,
        string memory meetingID,
        string memory chairpersonName,
        string memory timestamp,
        uint256 numberOfMembers,
        string memory contentHash,
        string[] memory memberNames,
        string[] memory roles
    ) public hasAccess(msg.sender, companyID) {
        MeetingData storage meetData = s_idToMeetingData[companyID][meetingID];
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
    function getMeetingData(string memory companyID, string memory meetingID)
        public
        view
        hasAccess(msg.sender, companyID)
        returns (MeetingData memory)
    {
        return s_idToMeetingData[companyID][meetingID];
    }

    /**
     * @notice Method for registering a wallet address to allow access to company data
     * @param walletAddress: The address of the wallet of the user
     * @param companyID : the ID of the company
     */
    function addAddressToCompany(address walletAddress, string memory companyID)
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
        returns (string[] memory)
    {
        return s_addressToCompanyID[walletAddress];
    }
}