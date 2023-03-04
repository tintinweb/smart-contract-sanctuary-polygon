// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Library {
    address ownerAddress;


//data structure
    struct LibraryDetails {
        uint32 id;
        string bookName;
        string issuerName;
        string studentName;
        uint32 studentId;
        string bookEdition;
        uint256 issueDate;
        uint256 deliveryDate;
    }

    constructor() {
        ownerAddress = msg.sender;
    }

//modifier to restrict other person to add book details
   modifier onlyOwner() {

        require(msg.sender == ownerAddress,"Only Owner/Librarian can add book Details");

        _;

    }


    //mapping
    mapping(uint256 => LibraryDetails) public libraryDetails;


//function to add book details
    function addBookDetails(
        uint32 _id,
        string memory _bookName,
        string memory _issuerName,
        string memory _studentName,
        uint32 _studentId,
        string memory _bookEdition
    ) public onlyOwner {
        libraryDetails[_id].bookName = _bookName;
        libraryDetails[_id].issuerName = _issuerName;
        libraryDetails[_id].studentName = _studentName;
        libraryDetails[_id].studentId = _studentId;
        libraryDetails[_id].bookEdition = _bookEdition;
        libraryDetails[_id].issueDate = getCurrentDate();
        libraryDetails[_id].deliveryDate = getDate10DaysAfter();
    }

    //function to get particular bookdetails

    function getBookDetailsById(uint32 _id)
        public
        view
        returns (
            string memory bookName,
            string memory issuerName,
            string memory studentName,
            uint32 studentId,
            string memory bookEdition,
            uint256 issueDate,
            uint256 deliveryDate
        )
    {
        return (
            libraryDetails[_id].bookName,
            libraryDetails[_id].issuerName,
            libraryDetails[_id].studentName,
            libraryDetails[_id].studentId,
            libraryDetails[_id].bookEdition,
            libraryDetails[_id].issueDate,
            libraryDetails[_id].deliveryDate

        );
    }


//transfer book ownership

function transferBook(uint32 _id, string memory newStudentName ) public onlyOwner {
libraryDetails[_id].studentName=newStudentName;

}


    //function to get current date
    function getCurrentDate() public view returns (uint256) {
        uint256 timestamp = block.timestamp;
        uint256 day = ((timestamp / 86400) % 31) + 1; // 1-based day of month
        uint256 month = ((timestamp / 2678400) % 12) + 1; // 1-based month
        uint256 year = (timestamp / 31536000) + 1970; // year since 1970
        return year * 10000 + month * 100 + day;
    }

    //function to get 10 days after today's date
    function getDate10DaysAfter() public view returns (uint256) {
        uint256 timestamp = block.timestamp + 864000; // add 10 days' worth of seconds
        uint256 day = ((timestamp / 86400) % 31) + 1; // 1-based day of month
        uint256 month = ((timestamp / 2678400) % 12) + 1; // 1-based month
        uint256 year = (timestamp / 31536000) + 1970; // year since 1970
        return year * 10000 + month * 100 + day;
    }
}