/**
 *Submitted for verification at polygonscan.com on 2023-05-19
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

contract MusicCollaborationContract {
    struct Writer {
        string name;
        uint256 percantageSplit;
    }
    struct CompositionDetails {
        address creater;
        string compositionName;
        Writer[] writers;
        uint256 compositionCreationDate;
        string performanceRightsOrganization;
        string publisher;
        string signingWriterName;
        uint256 signingWriterDate;
        address[] collaborators;
        address[] approvedByCollaborators;
        mapping(address => bool) isApproved;
    }

    CompositionDetails public _compositionDetails;
    mapping(address => CompositionDetails) private contribution;
    event approvedCompositionDetails(
        address indexed collaborator,
        bool succeed
    );

    constructor(
        address _creater,
        string memory _compositionName,
        string[] memory _writerNames,
        uint256[] memory _writerSplits,
        uint256 _compositionCreationDate,
        string memory _performanceRightsOrganization,
        string memory _publisher,
        string memory _signingWriterName,
        address[] memory _collaborators,
        uint256 _signingWriterDate
    ) {
        require(
            _writerNames.length == _writerSplits.length,
            "Array length mismatch"
        );
        _compositionDetails.creater = _creater;
        _compositionDetails.compositionName = _compositionName;
        _compositionDetails.compositionCreationDate = _compositionCreationDate;
        _compositionDetails
            .performanceRightsOrganization = _performanceRightsOrganization;
        _compositionDetails.publisher = _publisher;
        _compositionDetails.signingWriterName = _signingWriterName;
        _compositionDetails.signingWriterDate = _signingWriterDate;
        for (uint256 i = 0; i < _writerNames.length; i++) {
            _compositionDetails.writers.push(
                Writer(_writerNames[i], _writerSplits[i])
            );
        }
        for (uint256 j = 0; j < _collaborators.length; j++) {
            _compositionDetails.collaborators.push(_collaborators[j]);
        }
    }

    // Function to check if address is available in collaborators
    function isUserInCollaborators(address inputAddress)
        public
        view
        returns (bool)
    {
        for (uint256 i = 0; i < _compositionDetails.collaborators.length; i++) {
            if (_compositionDetails.collaborators[i] == inputAddress) {
                return true;
            }
        }

        return false;
    }

    // to approve or confirm the composition as a collaborator
    function approveCompositionDetails() public {
        require(
            !contribution[msg.sender].isApproved[msg.sender],
            "You already approved composition details"
        );
        bool isUser;
        for (uint256 i = 0; i < _compositionDetails.collaborators.length; i++) {
            if (_compositionDetails.collaborators[i] == msg.sender) {
                isUser = true;
                break;
            }
        }
        require(isUser, "You are not a collaborator");

        contribution[msg.sender].isApproved[msg.sender] = true;
        _compositionDetails.approvedByCollaborators.push(msg.sender);

        emit approvedCompositionDetails(msg.sender, true);
    }

    // Getter function for the writers array
    function getWriters() external view returns (Writer[] memory) {
        return _compositionDetails.writers;
    }

    // Getter function for the collaborators array
    function getCollaborators() external view returns (address[] memory) {
        return _compositionDetails.collaborators;
    }

    // Getter function for the collaboraotr who approved/confirmed the music compositions
    function getCollaboratorsApproved()
        external
        view
        returns (address[] memory)
    {
        return _compositionDetails.approvedByCollaborators;
    }

    // Getter function for the isApproved mapping
    function isCollaboratorApproved(address collaborator)
        external
        view
        returns (bool)
    {
        return contribution[collaborator].isApproved[collaborator];
    }
}

interface IMusicCollaborationContract {
    struct Writer {
        string name;
        uint256 percantageSplit;
    }
    struct CompositionDetails {
        string compositionName;
        Writer[] writers;
        uint256 compositionCreationDate;
        string performanceRightsOrganization;
        string publisher;
        string signingWriterName;
        uint256 signingWriterDate;
        address[] collaborators;
        mapping(address => bool) isApproved;
    }

    function isCollaboratorApproved(address collaborator)
        external
        view
        returns (bool);
}

contract MusicFactory is Ownable {
    enum Roles {
        Artist,
        SongWriter,
        Production,
        Performer
    }
    uint256 public fee;
    mapping(address => mapping(address => Roles)) public userRole;
    mapping(address => address[]) private userMusicContracts;
    mapping(address => address[]) private collaboratorContracts;
    address[] private _musicCollaborationContracts;
    event musicCollaborationContractCreated(
        address indexed _creater,
        address indexed musicContract,
        Roles _role
    );

    constructor() {
        fee = 0.0001 ether;
    }

    receive() external payable {}

    function createMusicCollaborationContract(
        uint256 _role,
        string memory _compositionName,
        string[] memory _writerNames,
        uint256[] memory _writerSplits,
        uint256 _compositionCreationDate,
        string memory _performanceRightsOrganization,
        string memory _publisher,
        string memory _signingWriterName,
        address[] memory _collaborators,
        uint256 _signingWriterDate
    ) public payable {
        require(msg.value >= fee, "Not enough fee paid");
        require(_role <= uint256(Roles(3)), "Please select valid role");
        require(
            _writerNames.length == _writerSplits.length,
            "Array length mismatch"
        );
        MusicCollaborationContract _newMusicContract = new MusicCollaborationContract(
                msg.sender,
                _compositionName,
                _writerNames,
                _writerSplits,
                _compositionCreationDate,
                _performanceRightsOrganization,
                _publisher,
                _signingWriterName,
                _collaborators,
                _signingWriterDate
            );
        _musicCollaborationContracts.push(address(_newMusicContract));
        userRole[msg.sender][address(_newMusicContract)] = Roles(_role);
        userMusicContracts[msg.sender].push(address(_newMusicContract));
        for (uint256 i = 0; i < _collaborators.length; i++) {
            collaboratorContracts[_collaborators[i]].push(
                address(_newMusicContract)
            );
        }
        emit musicCollaborationContractCreated(
            msg.sender,
            address(_newMusicContract),
            Roles(_role)
        );
    }

    function changeFee(uint256 _newFee) external onlyOwner {
        fee = _newFee;
    }

    function withdrawEth() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function getAvailableRoles() external pure returns (Roles[] memory) {
        Roles[] memory roles = new Roles[](4);
        roles[0] = Roles.Artist;
        roles[1] = Roles.SongWriter;
        roles[2] = Roles.Production;
        roles[3] = Roles.Performer;
        return roles;
    }

    function getUserMusicContracts(address _user)
        external
        view
        returns (address[] memory)
    {
        return userMusicContracts[_user];
    }

    function getCollaboratorMusicContracts(address _collaborator)
        external
        view
        returns (address[] memory)
    {
        return collaboratorContracts[_collaborator];
    }

    function getAllMusicContracts() external view returns (address[] memory) {
        return _musicCollaborationContracts;
    }

    function collaboratorApprovedContracts(address _collaborator)
        external
        view
        returns (address[] memory)
    {
        address[] memory contracts = collaboratorContracts[_collaborator];
        address[] memory approvedContracts = new address[](contracts.length);
        uint256 approvedCount;
        for (uint256 i = 0; i < contracts.length; i++) {
            if (
                IMusicCollaborationContract(contracts[i])
                    .isCollaboratorApproved(_collaborator)
            ) {
                approvedContracts[approvedCount] = contracts[i];
                approvedCount++;
            }
        }
        address[] memory finalApprovedContracts = new address[](approvedCount);
        uint256 index;
        for (uint256 i = 0; i < approvedCount; i++) {
            if (
                IMusicCollaborationContract(contracts[i])
                    .isCollaboratorApproved(_collaborator)
            ) {
                finalApprovedContracts[index] = contracts[i];
                index++;
            }
        }

        return finalApprovedContracts;
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}