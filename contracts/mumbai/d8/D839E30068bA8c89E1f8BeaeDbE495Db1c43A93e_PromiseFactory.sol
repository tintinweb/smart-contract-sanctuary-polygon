// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./PromiseContract.sol";
import "./IVerifyStorage.sol";

/**
 * @author polarzero
 * @title Master Contract
 * @notice This is the master contract initializing & referencing all child contracts
 */

contract PromiseFactory {
    /// Errors
    error PromiseFactory__EMPTY_FIELD();
    error PromiseFactory__INCORRECT_FIELD_LENGTH();
    error PromiseFactory__createPromiseContract__DUPLICATE_FIELD();
    error PromiseFactory__addParticipant__NOT_PARTICIPANT();
    error PromiseFactory__addParticipant__ALREADY_PARTICIPANT();
    error PromiseFactory__NOT_OWNER();
    error PromiseFactory__NOT_VERIFIER();

    /// Variables
    address private immutable i_owner;
    // The VerifyTwitter contract
    address private s_twitterVerifier;
    // The VerifyStorage contract
    address private s_storageVerifier;

    // Map the owner addresses to the child contracts they created
    mapping(address => PromiseContract[]) private s_promiseContracts;

    // Map the user addresses to their verified Twitter account(s)
    mapping(address => string[]) private s_twitterVerifiedUsers;

    /// Events
    event PromiseContractCreated(
        address indexed _owner,
        address indexed _contractAddress,
        string _promiseName,
        string _ipfsCid,
        string _arweaveId,
        string encryptedProof,
        string[] _partyNames,
        string[] _partyTwitterHandles,
        address[] _partyAddresses
    );

    event TwitterAddVerifiedSuccessful(
        address indexed _owner,
        string _twitterHandle
    );

    event ParticipantAdded(
        address indexed _contractAddress,
        string _participantName,
        string _participantTwitterHandle,
        address _participantAddress
    );

    event StorageStatusUpdateRequested(address promiseContract);

    event StorageStatusUpdated(
        address indexed _contractAddress,
        uint8 _storageStatus
    );

    /// Modifiers
    modifier onlyOwner() {
        // msg sender should be the deployer of the contract
        if (msg.sender != i_owner) {
            revert PromiseFactory__NOT_OWNER();
        }
        _;
    }

    modifier onlyTwitterVerifier() {
        if (msg.sender != s_twitterVerifier) {
            revert PromiseFactory__NOT_VERIFIER();
        }
        _;
    }

    modifier onlyStorageVerifier() {
        if (msg.sender != s_storageVerifier) {
            revert PromiseFactory__NOT_VERIFIER();
        }
        _;
    }

    /// Functions

    /**
     * @notice Initialize the contract
     */

    constructor(address _twitterVerifier, address _storageVerifier) {
        i_owner = msg.sender;
        s_twitterVerifier = _twitterVerifier;
        s_storageVerifier = _storageVerifier;
    }

    /**
     * @notice Create a new contract and add it to the list of child contracts
     * @param _promiseName The name of the contract specified by the user
     * @param _ipfsCid The CID of the directory stored on IPFS
     * @param _arweaveId The ID of the zip stored on Arweave
     * @param _encryptedProof The encrypted string of the promise name, user
     * address, IPFS and Arweave hashes
     * @param _partyNames The names of the parties specified by the user
     * @param _partyTwitterHandles The Twitter handles of the parties specified by the user
     * @param _partyAddresses The addresses specified by the user that will be allowed to interact
     * with the contract
     */

    function createPromiseContract(
        string memory _promiseName,
        string memory _ipfsCid,
        string memory _arweaveId,
        string memory _encryptedProof,
        string[] memory _partyNames,
        string[] memory _partyTwitterHandles,
        address[] memory _partyAddresses
    ) public returns (address promiseContractAddress) {
        // Revert if one of the fields is empty
        if (
            !(bytes(_promiseName).length > 0 &&
                bytes(_ipfsCid).length > 0 &&
                _partyNames.length > 0 &&
                _partyTwitterHandles.length > 0 &&
                _partyAddresses.length > 0)
        ) revert PromiseFactory__EMPTY_FIELD();

        // Revert if the number of names, Twitter and addresses are not equal
        // If Twitter handles are not provided, it will pass an empty string
        if (
            !(_partyAddresses.length == _partyTwitterHandles.length &&
                _partyAddresses.length == _partyNames.length)
        ) revert PromiseFactory__INCORRECT_FIELD_LENGTH();

        // Revert if the same address or twitter handle is used twice
        for (uint256 i = 0; i < _partyAddresses.length; i++) {
            for (uint256 j = i + 1; j < _partyAddresses.length; j++) {
                if (
                    _partyAddresses[i] == _partyAddresses[j] ||
                    keccak256(abi.encodePacked(_partyTwitterHandles[i])) ==
                    keccak256(abi.encodePacked(_partyTwitterHandles[j]))
                )
                    revert PromiseFactory__createPromiseContract__DUPLICATE_FIELD();
            }
        }

        // We could test the validity of the Twitter handles here, but it would not really matter
        // since it won't have any value without being verified, and the verification already
        // needs it to be valid

        // Revert if the name of the promise is longer than 70 characters
        if (bytes(_promiseName).length > 70) {
            revert PromiseFactory__INCORRECT_FIELD_LENGTH();
        }

        // We don't need to check the length of the Twitter handles
        // If any were to be invalid, they would fail to get verified

        // We can't make sure the provided CID is valid,
        // because it could be provided either in a Base58 or Base32 format
        // but it will be shown in the UI

        // Create a new contract for this promise
        PromiseContract promiseContract = new PromiseContract(
            msg.sender,
            _promiseName,
            _ipfsCid,
            _arweaveId,
            _encryptedProof,
            _partyNames,
            _partyTwitterHandles,
            _partyAddresses
        );
        s_promiseContracts[msg.sender].push(promiseContract);

        emit PromiseContractCreated(
            msg.sender,
            address(promiseContract),
            _promiseName,
            _ipfsCid,
            _arweaveId,
            _encryptedProof,
            _partyNames,
            _partyTwitterHandles,
            _partyAddresses
        );

        // Request a storage status update to the VerifyStorage contract
        IVerifyStorage(s_storageVerifier).requestStorageStatusUpdate(
            address(promiseContract),
            msg.sender,
            _ipfsCid,
            _arweaveId,
            _encryptedProof
        );
        emit StorageStatusUpdateRequested(address(promiseContract));

        return address(promiseContract);
    }

    /**
     * @notice Add a participant to a promise contract
     * @dev Only a participant of the contract can call this function
     * @dev It can only be called if the contract is not locked (the child contract takes care of that)
     * @param _promiseContractAddress The address of the promise contract
     * @param _partyName The name of the party
     * @param _partyTwitterHandle The Twitter handle of the party
     * @param _partyAddress The address of the party
     */

    function addParticipant(
        address _promiseContractAddress,
        string memory _partyName,
        string memory _partyTwitterHandle,
        address _partyAddress
    ) public {
        // Revert if the sender is not a participant of the contract
        if (
            !PromiseContract(_promiseContractAddress).getIsParticipant(
                msg.sender
            )
        ) {
            revert PromiseFactory__addParticipant__NOT_PARTICIPANT();
        }

        // Revert if the user to add is already a participant of the contract
        if (
            PromiseContract(_promiseContractAddress).getIsParticipant(
                _partyAddress
            )
        ) {
            revert PromiseFactory__addParticipant__ALREADY_PARTICIPANT();
        }

        // Revert if the name of the party is longer than 30 characters
        if (bytes(_partyName).length > 30) {
            revert PromiseFactory__INCORRECT_FIELD_LENGTH();
        }

        // Add the participant to the contract and emit an event if successful
        PromiseContract(_promiseContractAddress).createParticipant(
            _partyName,
            _partyTwitterHandle,
            _partyAddress,
            true // Reset the approval status
        );

        emit ParticipantAdded(
            _promiseContractAddress,
            _partyName,
            _partyTwitterHandle,
            _partyAddress
        );
    }

    /**
     * @notice Add a verified Twitter account to the list of verified accounts
     * @dev Only the verifier contract can call this function, after the account
     * has been verified with the Chainlink Node + External Adapter
     * @param _userAddress The address of the user
     * @param _twitterHandle The Twitter handle of the verified account
     */

    function addTwitterVerifiedUser(
        address _userAddress,
        string memory _twitterHandle
    ) external onlyTwitterVerifier {
        // If the user address doesn't have a verified account yet, create a new array
        if (s_twitterVerifiedUsers[_userAddress].length == 0) {
            s_twitterVerifiedUsers[_userAddress] = new string[](1);
            // Add the verified account to the array
            s_twitterVerifiedUsers[_userAddress][0] = _twitterHandle;
        } else if (s_twitterVerifiedUsers[_userAddress].length > 0) {
            string[] memory verifiedAccounts = s_twitterVerifiedUsers[
                _userAddress
            ];
            for (uint256 i = 0; i < verifiedAccounts.length; i++) {
                // If the user already verified this account, revert
                if (
                    keccak256(abi.encodePacked(verifiedAccounts[i])) ==
                    keccak256(abi.encodePacked(_twitterHandle))
                ) {
                    emit TwitterAddVerifiedSuccessful(
                        _userAddress,
                        _twitterHandle
                    );
                    return;
                }
            }
            // But if it is not included, add it
            s_twitterVerifiedUsers[_userAddress].push(_twitterHandle);
        }

        emit TwitterAddVerifiedSuccessful(_userAddress, _twitterHandle);
    }

    function updateStorageStatus(
        address _promiseContractAddress,
        uint8 _storageStatus
    ) external onlyStorageVerifier {
        PromiseContract(_promiseContractAddress).updateStorageStatus(
            _storageStatus
        );
        emit StorageStatusUpdated(_promiseContractAddress, _storageStatus);
    }

    /// Setters
    function setTwitterVerifier(address _twitterVerifier) external onlyOwner {
        s_twitterVerifier = _twitterVerifier;
    }

    function setStorageVerifier(address _storageVerifier) external onlyOwner {
        s_storageVerifier = _storageVerifier;
    }

    /// Getters
    function getPromiseContractAddresses(address _owner)
        public
        view
        returns (PromiseContract[] memory)
    {
        return s_promiseContracts[_owner];
    }

    function getPromiseContractCount(address _userAddress)
        public
        view
        returns (uint256)
    {
        return s_promiseContracts[_userAddress].length;
    }

    function getTwitterVerifiedHandle(address _userAddress)
        public
        view
        returns (string[] memory)
    {
        // Return the username if the user has a verified account
        if (s_twitterVerifiedUsers[_userAddress].length > 0) {
            return s_twitterVerifiedUsers[_userAddress];
        } else {
            // Return an empty array
            string[] memory usernames = new string[](0);
            return usernames;
        }
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getTwitterVerifier() public view returns (address) {
        return s_twitterVerifier;
    }

    function getStorageVerifier() public view returns (address) {
        return s_storageVerifier;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
 * @author polarzero
 * @title Promise Contract
 * @notice This is the child contract generated by the Promise Factory
 * once a user creates a new promise
 */

contract PromiseContract {
    /// Errors
    error PromiseContract__NOT_FACTORY();
    error PromiseContract__NOT_PARTICIPANT();
    error PromiseContract__PROMISE_LOCKED();
    error PromiseContract__createParticipant__INCORRECT_FIELD_LENGTH();
    error PromiseContract__approvePromise__ALREADY_APPROVED();
    error PromiseContract__lockPromise__PARTICIPANT_NOT_APPROVED();
    error PromiseContract__updateStorageStatus__INVALID_STATUS();

    /// Types
    struct Participant {
        string participantName;
        string participantTwitterHandle;
        address participantAddress;
    }

    /// Variables
    uint256 private s_participantCount = 0;
    // If the promise is created through the website, the content uploaded to IPFS
    // and eventually Arweave can be verified with the encryptedProof
    // which will result in a storageStatus that provides information on the persistence of the data
    // storageStatus = 0 -> the provided IPFS and Arweave hashes have not yet been verified
    // storageStatus = 1 -> the provided IPFS and eventually Arweave hashes could not be verified
    // storageStatus = 2 -> only the IPFS hash has been provided and verified
    // storageStatus = 3 -> both the IPFS & Arweave hashes has been provided and verified
    uint8 private s_storageStatus = 0;
    // The 3 following variables need to be stored in a string because of their length
    // So they cannot be set to immutable
    string private s_promiseName;
    string private s_ipfsCid;
    string private s_arweaveId;
    string private s_encryptedProof;
    address private immutable i_owner;
    address private immutable i_promiseFactoryContract;
    address[] private s_participantAddresses;
    bool private s_promiseLocked = false;

    // Mapping of addresses to name & twitter handle
    mapping(address => Participant) private s_parties;
    // Mapping of addresses to whether or not they have approved the agreement
    mapping(address => bool) private s_approvedParties;

    /// Events
    event ParticipantCreated(
        string participantName,
        string participantTwitterHandle,
        address indexed participantAddress
    );

    event ParticipantApproved(
        string participantName,
        string participantTwitterHandle,
        address indexed participantAddress
    );

    event PromiseLocked();

    event PromiseStorageStatusUpdated(uint8 storageStatus);

    /// Modifiers
    modifier onlyParticipant() {
        bool isParticipant = getIsParticipant(msg.sender);

        if (!isParticipant) revert PromiseContract__NOT_PARTICIPANT();
        _;
    }

    modifier onlyUnlocked() {
        if (s_promiseLocked) revert PromiseContract__PROMISE_LOCKED();
        _;
    }

    modifier onlyPromiseFactory() {
        if (msg.sender != i_promiseFactoryContract)
            revert PromiseContract__NOT_FACTORY();
        _;
    }

    /// Functions
    /**
     * @dev Initialize the contract from the Master Contract with the user address as the owner
     * @param _owner The address of the creator of the promise
     * @param _promiseName The name of the promise
     * @param _ipfsCid The IPFS CID of the content
     * @param _arweaveId The Arweave ID of the content
     * @param _encryptedProof The encrypted proof of the promise (see ./VerifyStorage.sol)
     * @param _partyNames The names of the parties
     * @param _partyTwitterHandles The twitter handles of the parties (optional, if not provided = '')
     * @param _partyAddresses The addresses of the parties
     */

    constructor(
        address _owner,
        string memory _promiseName,
        string memory _ipfsCid,
        string memory _arweaveId,
        string memory _encryptedProof,
        string[] memory _partyNames,
        string[] memory _partyTwitterHandles,
        address[] memory _partyAddresses
    ) {
        i_promiseFactoryContract = msg.sender;
        i_owner = _owner;
        s_promiseName = _promiseName;
        s_ipfsCid = _ipfsCid;
        s_arweaveId = _arweaveId;
        s_encryptedProof = _encryptedProof;

        for (uint256 i = 0; i < _partyAddresses.length; i++) {
            createParticipant(
                _partyNames[i],
                _partyTwitterHandles[i],
                _partyAddresses[i],
                false // The promise is being initialized, no need to reset approval status
            );
        }
    }

    /**
     * @notice Approve the promise as a participant
     */

    function approvePromise() public onlyParticipant onlyUnlocked {
        if (s_approvedParties[msg.sender] == true) {
            revert PromiseContract__approvePromise__ALREADY_APPROVED();
        }

        s_approvedParties[msg.sender] = true;
        emit ParticipantApproved(
            s_parties[msg.sender].participantName,
            s_parties[msg.sender].participantTwitterHandle,
            msg.sender
        );
    }

    /**
     * @notice Validate the promise and lock it so that no more participants can change any state
     * or even try to and lose gas
     */

    function lockPromise() public onlyParticipant onlyUnlocked {
        address[] memory participantAddresses = s_participantAddresses;

        // Loop through the parties and check if anyone has not approved yet
        for (uint256 i = 0; i < s_participantCount; i++) {
            if (s_approvedParties[participantAddresses[i]] == false) {
                revert PromiseContract__lockPromise__PARTICIPANT_NOT_APPROVED();
            }
        }

        s_promiseLocked = true;
        emit PromiseLocked();
    }

    /**
     * @notice Create a new participant and add them to the mapping
     * @dev This function can only be called by the Promise Factory
     * @param _participantName The name of the participant
     * @param _participantTwitterHandle The twitter handle of the participant
     * @param _participantAddress The address of the participant
     * @param _resetApprovalStatus Whether or not to reset the approval status of the participants
     * -> true if a participant is being added after the promise creation
     */

    function createParticipant(
        string memory _participantName,
        string memory _participantTwitterHandle,
        address _participantAddress,
        bool _resetApprovalStatus
    ) public onlyPromiseFactory onlyUnlocked {
        // Revert if the name is not between 2 and 30 characters
        if (
            bytes(_participantName).length < 2 ||
            bytes(_participantName).length > 30
        ) {
            revert PromiseContract__createParticipant__INCORRECT_FIELD_LENGTH();
        }
        Participant memory participant = Participant(
            _participantName,
            _participantTwitterHandle,
            _participantAddress
        );
        s_parties[_participantAddress] = participant;
        s_participantAddresses.push(_participantAddress);
        s_participantCount++;

        // Make sure the promise gets disapproved for every participants
        // In case a new participant is added, they will need to approve it again
        // We just need to do this if a participant is being added, not at the initialization
        if (_resetApprovalStatus) {
            address[] memory participantAddresses = s_participantAddresses;

            for (uint256 i = 0; i < s_participantCount; i++) {
                // Set the approval to false if it's been approved already
                if (s_approvedParties[participantAddresses[i]] == true) {
                    s_approvedParties[participantAddresses[i]] = false;
                }
            }
        }

        emit ParticipantCreated(
            _participantName,
            _participantTwitterHandle,
            _participantAddress
        );
    }

    /**
     * @notice Update the storage status of the promise
     * @dev This function can only be called by the Promise Factory
     * @param _storageStatus The new storage status of the promise
     * - 1 -> the provided IPFS and eventually Arweave hashes could not be verified
     * - 2 -> only the IPFS hash has been provided and verified
     * - 3 -> both the IPFS & Arweave hashes has been provided and verified
     */

    function updateStorageStatus(uint8 _storageStatus)
        public
        onlyPromiseFactory
    {
        if (_storageStatus < 1 || _storageStatus > 3) {
            revert PromiseContract__updateStorageStatus__INVALID_STATUS();
        }

        s_storageStatus = _storageStatus;
        emit PromiseStorageStatusUpdated(_storageStatus);
    }

    /// Getters
    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getName() public view returns (string memory) {
        return s_promiseName;
    }

    function getIpfsCid() public view returns (string memory) {
        return s_ipfsCid;
    }

    function getArweaveId() public view returns (string memory) {
        return s_arweaveId;
    }

    function getEncryptedProof() public view returns (string memory) {
        return s_encryptedProof;
    }

    function getStorageStatus() public view returns (uint8) {
        return s_storageStatus;
    }

    function getParticipant(address _address)
        public
        view
        returns (Participant memory)
    {
        return s_parties[_address];
    }

    function getIsParticipant(address _participantAddress)
        public
        view
        returns (bool)
    {
        if (s_parties[_participantAddress].participantAddress == address(0)) {
            return false;
        }

        return true;
    }

    function getParticipantCount() public view returns (uint256) {
        return s_participantCount;
    }

    function getIsPromiseApproved(address _participantAddress)
        public
        view
        returns (bool)
    {
        return s_approvedParties[_participantAddress];
    }

    function getIsPromiseLocked() public view returns (bool) {
        return s_promiseLocked;
    }

    function getPromiseFactoryContract() public view returns (address) {
        return i_promiseFactoryContract;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IVerifyStorage {
    function requestStorageStatusUpdate(
        address _promiseContractAddress,
        address _userAddress,
        string memory _ipfsHash,
        string memory _arweaveId,
        string memory _encryptedProof
    ) external;
}