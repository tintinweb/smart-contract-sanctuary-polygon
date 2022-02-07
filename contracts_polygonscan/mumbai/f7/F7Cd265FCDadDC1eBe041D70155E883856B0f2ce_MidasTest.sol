/**
 *Submitted for verification at polygonscan.com on 2022-02-07
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma abicoder v2;

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

struct User {
    address userAddress;
    string nickname;
    string country;
    uint birthdateYear;
    string description;
    string[] interests;
    string profileImageURL;
    bool isSet;
}

struct Project {
    uint id;
    uint createdAt;
    string projectDetails;
    // string title;
    // string description;
    // string category;
    uint deadline;
    // string agreementURL;
    // string[] projectImages;

    string testType;
    string questions;

    string restrictionsDetail;
    // uint minAge;
    // uint maxAge;
    // string targetCountry;
    uint maxTestersQuantity;
    // uint minimumCompletionsRestriction;
    uint investment;

    uint status; // 0: INCOMPLETE | 1: OPENED | 2: CLOSED
}

struct TestEnrollment {
    uint id;
    uint status; // 0: PENDING | 1: DONE
    string results;
}


contract MidasTest is Ownable {
    /// *** COUNTERS *** ///
    using Counters for Counters.Counter;
    Counters.Counter private _projectId;
    Counters.Counter private _testEnrollmentId;

    /// *** VARIABLES *** ///

    uint public midasFee = 10 ether;
    uint public minimumInvestment = 50 ether;
    address[] wallets;

    mapping (address => User) private _userInfo;
    mapping (address => uint) public userCompletedTestsCount;
    
    mapping (uint => Project) private _projectInfo;
    mapping (uint => address) public projectToOwner;
    mapping (address => uint) public ownerProjectCount;
    mapping (uint => uint) public projectRemainingInvestment;

    mapping (uint => TestEnrollment) private _testEnrollment;
    mapping (uint => address) public testEnrollmentToOwner;
    mapping (uint => uint) public testEnrollmentToProject;
    mapping (address => uint) public ownerTestEnrollmentCount;
    mapping (uint => uint) public projectTestEnrollmentCount;

    /// *** EVENTS *** ///

    constructor () {}

    /// *** MIDAS FEE *** ///

    function setMidasFee(uint _newFee) external onlyOwner {
        midasFee = _newFee;
    }

    function getMidasFee() external view returns (uint) {
        return midasFee;
    }

    /// *** USER INFO *** ///

    function getUserInfo(address _userAddress) external view returns (User memory) {
        return _userInfo[_userAddress];
    }

    function getProjectOwnerName(uint _projectIdToGetOwnerName) external view returns (string memory) {
        return _userInfo[projectToOwner[_projectIdToGetOwnerName]].nickname;
    }

    function getEnrollmentUserData(uint _testEnrollmentIdToGetUserData) external view returns (string memory, uint, uint, address) {
        require(msg.sender == projectToOwner[testEnrollmentToProject[_testEnrollmentIdToGetUserData]], "A01");
        return (
            _userInfo[testEnrollmentToOwner[_testEnrollmentIdToGetUserData]].nickname,
            _userInfo[testEnrollmentToOwner[_testEnrollmentIdToGetUserData]].birthdateYear,
            userCompletedTestsCount[testEnrollmentToOwner[_testEnrollmentIdToGetUserData]],
            testEnrollmentToOwner[_testEnrollmentIdToGetUserData]
        );
    }

    function setUserInfo(
        string memory _nickname,
        string memory _country,
        uint _birthdateYear,
        string memory _description,
        string[] memory _interests,
        string memory _profileImageURL
    ) external returns (string memory) {

        bool exists = false;

        if (_userInfo[msg.sender].isSet) {
            exists = true;
        } else {
            wallets.push(msg.sender);
        }

        _userInfo[msg.sender] = User(msg.sender, _nickname, _country, _birthdateYear, _description, _interests, _profileImageURL, true);

        if (exists) {
            return "Successfully updated!";
        } else {
            return "Successfully created!";
        }

    }

    /// *** PROJECTS *** ///

    function getProjectInfo(uint _projectIdToGet) external view returns (Project memory) {
        return _projectInfo[_projectIdToGet];
    }

    function getTestEnrollmentProjectInfo(uint _testEnrollmentIdToGetProject) external view returns (Project memory) {
        return _projectInfo[testEnrollmentToProject[_testEnrollmentIdToGetProject]];
    }

    function getUserCreatedProjects() external view returns (uint[] memory) {
        uint[] memory result = new uint[](ownerProjectCount[msg.sender]);

        uint counter = 0;
        for (uint i = 0; i < _projectId.current(); i++ ) {
            if (projectToOwner[i] == msg.sender) {
                result[counter] = i;
                counter++;
            }
        }

        return result;
    }

    function getAllProjects() external view returns (uint[] memory) {
        uint[] memory result = new uint[](_projectId.current());

        uint counter = 0;
        for (uint i = 0; i < _projectId.current(); i++) {
            result[counter] = i;
            counter++;
        }

        return result;
    }

    function createProject(
        uint _createdAt,
        string memory _projectDetails,
        // string memory _title,
        // string memory _description,
        // string memory _category,
        uint _deadline,
        // string memory _agreementURL,
        // string[] memory _projectImages,
        string memory _testType,
        string memory _questions,
        string memory _restrictionsDetail,
        // uint _minAge,
        // uint _maxAge,
        // string memory _targetCountry,
        uint _maxTestersQuantity,
        // uint _minimumCompletionsRestriction,
        uint _investment
    ) public {
        require(_userInfo[msg.sender].isSet, "M01");

        _projectInfo[_projectId.current()] = Project(
            _projectId.current(),
            _createdAt,
            _projectDetails,
            // _title,
            // _description, 
            // _category, 
            _deadline, 
            // _agreementURL, 
            // _projectImages,
            _testType, 
            _questions,
            _restrictionsDetail, 
            // _minAge, 
            // _maxAge, 
            // _targetCountry, 
            _maxTestersQuantity, 
            // _minimumCompletionsRestriction,  
            _investment, 
            0
        );
        projectToOwner[_projectId.current()] = msg.sender;
        ownerProjectCount[msg.sender]++;

        _projectId.increment();
    }

    function updateProjectInfo(
        uint _projectIdToUpdate,
        string memory _projectDetails,
        // string memory _title,
        // string memory _description,
        // string memory _category,
        uint _deadline,
        // string memory _agreementURL,
        // string[] memory _projectImages,
        string memory _testType,
        string memory _questions,
        string memory _restrictionsDetail,
        // uint _minAge,
        // uint _maxAge,
        // string memory _targetCountry,
        uint _maxTestersQuantity,
        // uint _minimumCompletionsRestriction,
        uint _investment
    ) external {
        require(_projectIdToUpdate < _projectId.current(), "NE01");
        require(projectToOwner[_projectIdToUpdate] == msg.sender, "A02");
        require(_projectInfo[_projectIdToUpdate].status == 0, "C01");
        require(block.timestamp < _deadline, "D01");

        _projectInfo[_projectIdToUpdate] = Project(
            _projectIdToUpdate,
            _projectInfo[_projectIdToUpdate].createdAt,
            _projectDetails,
            // _title,
            // _description, 
            // _category, 
            _deadline, 
            // _agreementURL, 
            // _projectImages,
            _testType, 
            _questions,
            _restrictionsDetail,
            // _minAge, 
            // _maxAge, 
            // _targetCountry, 
            _maxTestersQuantity, 
            // _minimumCompletionsRestriction, 
            _investment, 
            0
        );
    }

    function projectKickOff(
        uint _projectIdToKickOff
    ) external payable {
        require(_projectInfo[_projectIdToKickOff].investment > minimumInvestment, "I01");
        require(msg.value >= (_projectInfo[_projectIdToKickOff].investment) + midasFee, "I02");
        require(_projectIdToKickOff < _projectId.current(), "NE01");
        require(projectToOwner[_projectIdToKickOff] == msg.sender, "A02");
        require(_projectInfo[_projectIdToKickOff].status == 0, "C01");
        require(block.timestamp < _projectInfo[_projectIdToKickOff].deadline, "D02");

        _projectInfo[_projectIdToKickOff].status = 1;

        projectRemainingInvestment[_projectIdToKickOff] = _projectInfo[_projectIdToKickOff].investment;
    }

    function closeProject(
        uint _projectIdToClose
    ) external {
        require(projectToOwner[_projectIdToClose] == msg.sender, "A03");
        require(_projectIdToClose < _projectId.current(), "NE02");
        require(block.timestamp < _projectInfo[_projectIdToClose].deadline, "D03");
        require(_projectInfo[_projectIdToClose].status == 1, "C02");

        for (uint i = 0; i < _testEnrollmentId.current(); i++) {
            if (testEnrollmentToProject[i] == _projectIdToClose) {
                if (_testEnrollment[i].status == 0) {
                    uint toPay = (_projectInfo[testEnrollmentToProject[i]].investment / _projectInfo[testEnrollmentToProject[i]].maxTestersQuantity);
                    payable(testEnrollmentToOwner[i]).transfer(toPay * 5 / 100);

                    projectRemainingInvestment[_projectIdToClose] -= toPay * 5 / 100;
                }
            }
        }

        payable(msg.sender).transfer(projectRemainingInvestment[_projectIdToClose]);
        projectRemainingInvestment[_projectIdToClose] -= projectRemainingInvestment[_projectIdToClose];

        _projectInfo[_projectIdToClose].status = 2;
    }

    /// *** TEST ENROLLMENT *** ///
    function enrollToProject(
        uint _projectIdToEnroll
    ) external {
        require(_userInfo[msg.sender].isSet, "M02");
        require(_projectInfo[_projectIdToEnroll].maxTestersQuantity >= projectTestEnrollmentCount[_projectIdToEnroll], "MXT01");
        require(projectToOwner[_projectIdToEnroll] != msg.sender, "A04");
        require(_projectInfo[_projectIdToEnroll].status == 1, "C03");

        _testEnrollment[_testEnrollmentId.current()] = TestEnrollment(_testEnrollmentId.current(), 0, "");
        testEnrollmentToOwner[_testEnrollmentId.current()] = msg.sender;
        testEnrollmentToProject[_testEnrollmentId.current()] = _projectIdToEnroll;
        ownerTestEnrollmentCount[msg.sender]++;
        projectTestEnrollmentCount[_projectIdToEnroll]++;

        _testEnrollmentId.increment();
    }

    function getUserEnrollments(address _address, bool _returnOnlyCompleted) external view returns (uint[] memory) {
        uint[] memory result = new uint[](ownerTestEnrollmentCount[_address]);

        uint counter = 0;
        for (uint i = 0; i < _testEnrollmentId.current(); i++) {
            if (testEnrollmentToOwner[i] == _address) {
                if (_returnOnlyCompleted) {
                    if (_testEnrollment[i].status == 1) {
                        result[counter] = i;
                        counter++;
                    }
                } else {
                    result[counter] = i;
                    counter++;
                }
            }
        }

        return result;
    }

    function updateEnrollmentResult(
        uint _testEnrollmentIdToUpdate,
        uint _status,
        string memory _results
    ) external {
        require(testEnrollmentToOwner[_testEnrollmentIdToUpdate] == msg.sender, "A05");

        require(_testEnrollment[_testEnrollmentIdToUpdate].status != 1, "C04");

        _testEnrollment[_testEnrollmentIdToUpdate].results = _results;

        if (_status == 1) {

            uint toPay = (
                _projectInfo[testEnrollmentToProject[_testEnrollmentIdToUpdate]].investment 
                / 
                _projectInfo[testEnrollmentToProject[_testEnrollmentIdToUpdate]].maxTestersQuantity);

            payable(msg.sender).transfer(toPay);

            _testEnrollment[_testEnrollmentIdToUpdate].status = _status;

            userCompletedTestsCount[msg.sender]++;

            projectRemainingInvestment[testEnrollmentToProject[_testEnrollmentIdToUpdate]] -= toPay;
        }
    }

    function getProjectResults(
        uint _projectIdToGetResults
    ) external view returns (uint[] memory) {
        require(_projectIdToGetResults < _projectId.current(), "NE03");
        require(projectToOwner[_projectIdToGetResults] == msg.sender, "A06");

        uint[] memory result = new uint[](projectTestEnrollmentCount[_projectIdToGetResults]);

        uint counter = 0;
        for (uint i = 0; i < _testEnrollmentId.current(); i++) {
            if (testEnrollmentToProject[i] == _projectIdToGetResults) {
                result[counter] = i;
                counter++;
            }
        }

        return result;
    }

    function getTestEnrollment(uint _testEnrollmentIdToGet) external view returns (TestEnrollment memory) {
        require(_testEnrollmentIdToGet < _testEnrollmentId.current(), "NE04");
        require(testEnrollmentToOwner[_testEnrollmentIdToGet] == msg.sender || projectToOwner[testEnrollmentToProject[_testEnrollmentIdToGet]] == msg.sender, "A07");
        return _testEnrollment[_testEnrollmentIdToGet];
    }

    /// *** STATISTICS *** ///
    function getUserCompletedTestsCount(address _address) external view returns (uint) {
        return userCompletedTestsCount[_address];
    }
 
}