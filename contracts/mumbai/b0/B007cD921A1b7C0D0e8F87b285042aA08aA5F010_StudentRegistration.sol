// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
/*

  /$$$$$$   /$$                     /$$                       /$$     /$$$$$$$                      /$$             /$$                          /$$     /$$                          
 /$$__  $$ | $$                    | $$                      | $$    | $$__  $$                    |__/            | $$                         | $$    |__/                          
| $$  \__//$$$$$$   /$$   /$$  /$$$$$$$  /$$$$$$  /$$$$$$$  /$$$$$$  | $$  \ $$  /$$$$$$   /$$$$$$  /$$  /$$$$$$$ /$$$$$$    /$$$$$$  /$$$$$$  /$$$$$$   /$$  /$$$$$$  /$$$$$$$       
|  $$$$$$|_  $$_/  | $$  | $$ /$$__  $$ /$$__  $$| $$__  $$|_  $$_/  | $$$$$$$/ /$$__  $$ /$$__  $$| $$ /$$_____/|_  $$_/   /$$__  $$|____  $$|_  $$_/  | $$ /$$__  $$| $$__  $$      
 \____  $$ | $$    | $$  | $$| $$  | $$| $$$$$$$$| $$  \ $$  | $$    | $$__  $$| $$$$$$$$| $$  \ $$| $$|  $$$$$$   | $$    | $$  \__/ /$$$$$$$  | $$    | $$| $$  \ $$| $$  \ $$      
 /$$  \ $$ | $$ /$$| $$  | $$| $$  | $$| $$_____/| $$  | $$  | $$ /$$| $$  \ $$| $$_____/| $$  | $$| $$ \____  $$  | $$ /$$| $$      /$$__  $$  | $$ /$$| $$| $$  | $$| $$  | $$      
|  $$$$$$/ |  $$$$/|  $$$$$$/|  $$$$$$$|  $$$$$$$| $$  | $$  |  $$$$/| $$  | $$|  $$$$$$$|  $$$$$$$| $$ /$$$$$$$/  |  $$$$/| $$     |  $$$$$$$  |  $$$$/| $$|  $$$$$$/| $$  | $$      
 \______/   \___/   \______/  \_______/ \_______/|__/  |__/   \___/  |__/  |__/ \_______/ \____  $$|__/|_______/    \___/  |__/      \_______/   \___/  |__/ \______/ |__/  |__/      
                                                                                          /$$  \ $$                                                                                   
                                                                                         |  $$$$$$/                                                                                   
                                                                                          \______/                                                                                    

*/

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract StudentRegistration is Ownable{

    /*
        It saves bytecode to revert on custom errors instead of using require
        statements. We are just declaring these errors for reverting with upon various
        conditions later in this contract. Thanks, Chiru Labs!
    */
    error inputConnectedWalletAddress();
    error addressAlreadyRegistered();
    error idAlreadyTaken();

   
    mapping(address => mapping(uint256 => bool)) private studentLinkToID;
    mapping(address => mapping(uint256 => StudentInformation)) private studentInfostruct;
    mapping(uint256 => uint256) private idToId;
    mapping(uint256 => string) private idTopassword;
    mapping(uint256 => bool) private idVerification;
    mapping(uint => address) private idToUserAddress;

    uint[] private allIds;
    address[] private pushStudents;


    event StudentRegistered(string indexed mailId, string indexed status);

    struct StudentInformation{
        string firstName;
        string lastName;
        uint256 phoneNo;
        string mailID;
        address walletAddress;
        uint256 studentID;
        string password;
    }


    // function initialize() external initializer{
    //   ///@dev as there is no constructor, we need to initialise the OwnableUpgradeable explicitly
    //    __Ownable_init();
    // }

    // function _authorizeUpgrade(address) internal override onlyOwner {}


    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }

    
    
    
    function addStudent(StudentInformation memory _studentInfo) external{
        StudentInformation memory si = _studentInfo;
        if(msg.sender != si.walletAddress){ revert inputConnectedWalletAddress();}
        if(studentLinkToID[msg.sender][si.studentID] == true){ revert addressAlreadyRegistered();}
        for(uint i = 0; i < allIds.length; i++){
            if(si.studentID == allIds[i]){
                revert idAlreadyTaken();
            }
        }
        studentLinkToID[msg.sender][si.studentID] = true;
        studentInfostruct[msg.sender][si.studentID].firstName = si.firstName;
        studentInfostruct[msg.sender][si.studentID].lastName = si.lastName;
        studentInfostruct[msg.sender][si.studentID].phoneNo = si.phoneNo;
        studentInfostruct[msg.sender][si.studentID].mailID = si.mailID;
        studentInfostruct[msg.sender][si.studentID].walletAddress = si.walletAddress;
        studentInfostruct[msg.sender][si.studentID].studentID = si.studentID;
        studentInfostruct[msg.sender][si.studentID].password = si.password;
        idToUserAddress[si.studentID] = si.walletAddress;
        idVerification[si.studentID] = true;
        idToId[si.studentID] = si.studentID;
        idTopassword[si.studentID] = si.password;
        allIds.push(studentInfostruct[msg.sender][si.studentID].studentID);
        pushStudents.push(msg.sender);
        emit StudentRegistered(studentInfostruct[msg.sender][si.studentID].mailID, "Student is Registered Successfully");
    }

    function verifyStudent(address _studentAddress, uint256 _studentId) public view returns(bool condition){
        if(studentLinkToID[_studentAddress][_studentId]){
            return true;
        }else{
            return false;
        }
    }

    function verifyStudentWithId(uint _studentId) public view returns(bool status){
        if(idVerification[_studentId]){
            status = true;
            return status;
        }else{
            return false;
        }
    }

    function getAllStudentAddress() external view returns(address[] memory){
        return pushStudents;
    }  

    function viewStudentInformation( address _studentAddress, uint256 _id) external view returns(
    uint256 phno, 
    string memory mailid, 
    address walletad, 
    uint256 studentid,
    string memory password ){
        require(verifyStudent(_studentAddress,_id) == true, "Student not listed!!");
        return (
        studentInfostruct[_studentAddress][_id].phoneNo,
        studentInfostruct[_studentAddress][_id].mailID,
        studentInfostruct[_studentAddress][_id].walletAddress,
        studentInfostruct[_studentAddress][_id].studentID,
        studentInfostruct[_studentAddress][_id].password);
    }   

    function loginVerify(uint256 _studentID, string memory _password) external view returns (bool verificationStatus){
        if((_studentID == idToId[_studentID]) && (equal(_password,idTopassword[_studentID]))){
            verificationStatus = true;
            return verificationStatus;
        }else{
            verificationStatus = false;
            return verificationStatus;
        }
    }

    function getStudentAddress(uint _studentID) external view returns(address studentAddress){
        return idToUserAddress[_studentID];
    }

}