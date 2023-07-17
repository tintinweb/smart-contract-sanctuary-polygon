// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
import "@openzeppelin/contracts/access/Ownable.sol";

contract Portfolio is Ownable {
    struct Project {
        uint id;
        string name;
        string description;
        string image;
        string githubLink;
        string projectLink;
    }

    struct Education {
        uint id;
        string date;
        string degree;
        string institute;
        uint percentage;
    }

    struct Experience {
        uint id;
        string organisation;
        string joiningDate;
        string position;
    }

    uint public projectCount;
    uint public educationCount;
    uint public experienceCount;

    Project[] public projects;
    Education[3] public educations;
    Experience[] public experiences;

    string public portfolioImage = "";
    string public resumeLink = "";
    string public description = "";

    /// @notice To update the portfolio image
    /// @dev Put only CID of image not the full url
    /// @param _image cid of the portfolio image
    function updatePortfolioImage(string calldata _image) external onlyOwner {
        require(
            keccak256(abi.encodePacked(portfolioImage)) !=
                keccak256(abi.encodePacked(_image)),
            "Already added"
        );
        portfolioImage = _image;
    }

    /// @notice To update the portfolio resume
    /// @dev Put only CID of resume not the full url
    /// @param _link cid of the portfolio resume
    function updateResumeLink(string calldata _link) external onlyOwner {
        require(
            keccak256(abi.encodePacked(resumeLink)) !=
                keccak256(abi.encodePacked(_link)),
            "Already added"
        );
        resumeLink = _link;
    }

    /// @notice To update the portfolio descriptiom
    /// @param _desc description about you
    function updateDescription(string calldata _desc) external onlyOwner {
        require(
            keccak256(abi.encodePacked(description)) !=
                keccak256(abi.encodePacked(_desc)),
            "Already added"
        );
        description = _desc;
    }

    /// @notice To add a new project in portFolio
    /// @param _name project name
    /// @param _description project description
    /// @param _image project image
    /// @param _githubLink project github link
    /// @param _projectLink running project link
    function addProject(
        string calldata _name,
        string calldata _description,
        string calldata _image,
        string calldata _githubLink,
        string calldata _projectLink
    ) external onlyOwner {
        projects[projectCount] = Project(
            projectCount,
            _name,
            _description,
            _image,
            _githubLink,
            _projectLink
        );
        projectCount++;
    }

    /// @notice To update an existing project in portFolio
    /// @param _name project name
    /// @param _description project description
    /// @param _image project image
    /// @param _githubLink project github link
    /// @param _projectLink running project link
    /// @param _projectId id of project to update
    function updateProject(
        string calldata _name,
        string calldata _description,
        string calldata _image,
        string calldata _githubLink,
        string calldata _projectLink,
        uint _projectId
    ) external onlyOwner {
        require(_projectId < projects.length, "Invalid project id");
        projects[_projectId] = Project(
            _projectId,
            _name,
            _description,
            _image,
            _githubLink,
            _projectLink
        );
    }

    /// @notice To add a new education in portFolio
    /// @dev  Add percentage by mutiplying it by 10e8
    /// @param _date starting date
    /// @param _degree degree earned
    /// @param _institute institute name
    /// @param _percentage percentage scored
    function addEducation(
        string calldata _date,
        string calldata _degree,
        string calldata _institute,
        uint _percentage
    ) external onlyOwner {
        require(educationCount < 3, "Only 3 education details allowed");
        educations[educationCount] = Education(
            educationCount,
            _date,
            _degree,
            _institute,
            _percentage
        );
        educationCount++;
    }

    /// @notice To update an existing education in portFolio
    /// @dev  Add percentage by mutiplying it by 10e8
    /// @param _date starting date
    /// @param _degree degree earned
    /// @param _institute institute name
    /// @param _percentage percentage scored
    /// @param _educationId id of education to update
    function updateEducation(
        string calldata _date,
        string calldata _degree,
        string calldata _institute,
        uint _percentage,
        uint _educationId
    ) external onlyOwner {
        require(_educationId < 3, "Inavlid eduction idw");
        educations[_educationId] = Education(
            _educationId,
            _date,
            _degree,
            _institute,
            _percentage
        );
    }

    /// @notice To add new experience in portFolio
    /// @param _organisation starting date
    /// @param _joiningDate degree earned
    /// @param _position institute name
    function addExperience(
        string calldata _organisation,
        string calldata _joiningDate,
        string calldata _position
    ) external onlyOwner {
        experiences[experienceCount] = Experience(
            experienceCount,
            _organisation,
            _joiningDate,
            _position
        );
        experienceCount++;
    }

    /// @notice To update an existing  experience in portFolio
    /// @param _organisation starting date
    /// @param _joiningDate degree earned
    /// @param _position institute name
    /// @param _experienceId id of experince to update
    function updateExperience(
        string calldata _organisation,
        string calldata _joiningDate,
        string calldata _position,
        uint _experienceId
    ) external onlyOwner {
        require(_experienceId < experiences.length, "Invalid experience id");
        experiences[_experienceId] = Experience(
            _experienceId,
            _organisation,
            _joiningDate,
            _position
        );
    }

    /// @notice To get all projects available in portfolio
    /// @return all projects
    function getAllProjects() public view returns (Project[] memory) {
        return projects;
    }

    /// @notice To get all experiences available in portfolio
    /// @return all experiences
    function getAllExperience() public view returns (Experience[] memory) {
        return experiences;
    }

    /// @notice To get all educations available in portfolio
    /// @return all educations
    function getAllEducation() public view returns (Education[3] memory) {
        return educations;
    }

    /// @notice To donate native currency to the portfolio owner
    function donate() public payable {
        payable(owner()).transfer(msg.value);
    }
}