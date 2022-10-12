/**
 *Submitted for verification at polygonscan.com on 2022-10-11
*/

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;




interface TugStorageInterface {
    // Deploy status
    function getDeployedStatus() external view returns (bool);

    // Guardians
    function getGuardian() external view returns (address);

    function setGuardian(address _newAddress) external;

    function confirmGuardian() external;

    // Getters
    function getAddress(bytes32 _key) external view returns (address);

    function getUint(bytes32 _key) external view returns (uint256);

    function getString(bytes32 _key) external view returns (string memory);

    function getBytes(bytes32 _key) external view returns (bytes memory);

    function getBool(bytes32 _key) external view returns (bool);

    function getInt(bytes32 _key) external view returns (int256);

    function getBytes32(bytes32 _key) external view returns (bytes32);

    // Setters
    function setAddress(bytes32 _key, address _value) external;

    function setUint(bytes32 _key, uint256 _value) external;

    function setString(bytes32 _key, string calldata _value) external;

    function setBytes(bytes32 _key, bytes calldata _value) external;

    function setBool(bytes32 _key, bool _value) external;

    function setInt(bytes32 _key, int256 _value) external;

    function setBytes32(bytes32 _key, bytes32 _value) external;

    // Deleters
    function deleteAddress(bytes32 _key) external;

    function deleteUint(bytes32 _key) external;

    function deleteString(bytes32 _key) external;

    function deleteBytes(bytes32 _key) external;

    function deleteBool(bytes32 _key) external;

    function deleteInt(bytes32 _key) external;

    function deleteBytes32(bytes32 _key) external;

    // Arithmetic
    function addUint(bytes32 _key, uint256 _amount) external;

    function subUint(bytes32 _key, uint256 _amount) external;

    // Known frequent queries to reduce calldata gas
    function getPricingEngineAddress() external view returns (address);

    function getTreasuryAddress() external view returns (address);

    function getTokenRegistryAddress() external view returns (address);
}


/// @author Adapted from Eternal Storage implementation @ https://github.com/rocket-pool/rocketpool/blob/master/contracts/contract/RocketStorage.sol
contract TugStorage is TugStorageInterface {
    // Events
    event GuardianChanged(address oldGuardian, address newGuardian);

    // Errors
    error InvalidOrOutdatedTugContract();
    error InvalidOrOutdatedTugContractDuringDeployment();

    // Storage maps
    mapping(bytes32 => string) private stringStorage;
    mapping(bytes32 => bytes) private bytesStorage;
    mapping(bytes32 => uint256) private uintStorage;
    mapping(bytes32 => int256) private intStorage;
    mapping(bytes32 => address) private addressStorage;
    mapping(bytes32 => bool) private booleanStorage;
    mapping(bytes32 => bytes32) private bytes32Storage;

    // Guardian address
    address public guardian;
    address public newGuardian;

    address public priceEngine;
    address public treasury;
    address public tokenRegistry;

    // Flag storage has been initialised
    bool public storageInit = false;

    /// @dev Only allow access from the latest version of a contract in the Tug network after deployment
    modifier onlyLatestTugContract() {
        if (storageInit == true) {
            // Make sure the access is permitted to only contracts in our Dapp
            if (
                !booleanStorage[
                    keccak256(abi.encodePacked("contract.exists", msg.sender))
                ]
            ) {
                revert InvalidOrOutdatedTugContract();
            }
        } else {
            // Only Dapp and the guardian account are allowed access during initialisation.
            // tx.origin is only safe to use in this case for deployment since no external contracts are interacted with
            if (
                !booleanStorage[
                    keccak256(abi.encodePacked("contract.exists", msg.sender))
                ] && tx.origin != guardian
            ) {
                revert InvalidOrOutdatedTugContractDuringDeployment();
            }
        }
        _;
    }

    /// @dev Construct RocketStorage
    constructor() {
        // Set the guardian upon deployment
        guardian = msg.sender;
    }

    // Get guardian address
    function getGuardian() external view override returns (address) {
        return guardian;
    }

    // Transfers guardianship to a new address
    /// @notice Call 'ConfirmGuardian()' from new guardian account to confirm that we have access to the newGuardian address.
    function setGuardian(address _newAddress) external override {
        // Check tx comes from current guardian
        require(msg.sender == guardian, "Is not guardian account");
        // Store new address awaiting confirmation
        newGuardian = _newAddress;
    }

    // Confirms change of guardian
    /// @notice Call this after calling 'setGuardian' to confirm that we have access to the newGuardian address.
    function confirmGuardian() external override {
        // Check tx came from new guardian address
        require(msg.sender == newGuardian, "Not new guardian address");
        // Store old guardian for event
        address oldGuardian = guardian;
        // Update guardian and clear storage
        guardian = newGuardian;
        delete newGuardian;
        // Emit event
        emit GuardianChanged(oldGuardian, guardian);
    }

    // Set this as being deployed now
    function getDeployedStatus() external view override returns (bool) {
        return storageInit;
    }

    // Set this as being deployed now
    function setDeployedStatus() external {
        // Only guardian can lock this down
        require(msg.sender == guardian, "Is not guardian account");
        // Set it now
        storageInit = true;
    }

    /// @param _key The key for the record
    function getAddress(bytes32 _key) public view override returns (address r) {
        return addressStorage[_key];
    }

    /// @param _key The key for the record
    function getUint(bytes32 _key) public view override returns (uint256 r) {
        return uintStorage[_key];
    }

    /// @param _key The key for the record
    function getString(bytes32 _key)
        public
        view
        override
        returns (string memory)
    {
        return stringStorage[_key];
    }

    /// @param _key The key for the record
    function getBytes(bytes32 _key)
        public
        view
        override
        returns (bytes memory)
    {
        return bytesStorage[_key];
    }

    /// @param _key The key for the record
    function getBool(bytes32 _key) public view override returns (bool r) {
        return booleanStorage[_key];
    }

    /// @param _key The key for the record
    function getInt(bytes32 _key) public view override returns (int256 r) {
        return intStorage[_key];
    }

    /// @param _key The key for the record
    function getBytes32(bytes32 _key) public view override returns (bytes32 r) {
        return bytes32Storage[_key];
    }

    /// @param _key The key for the record
    function setAddress(bytes32 _key, address _value)
        public
        override
        onlyLatestTugContract
    {
        addressStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setUint(bytes32 _key, uint256 _value)
        public
        override
        onlyLatestTugContract
    {
        uintStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setString(bytes32 _key, string calldata _value)
        public
        override
        onlyLatestTugContract
    {
        stringStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setBytes(bytes32 _key, bytes calldata _value)
        public
        override
        onlyLatestTugContract
    {
        bytesStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setBool(bytes32 _key, bool _value)
        public
        override
        onlyLatestTugContract
    {
        booleanStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setInt(bytes32 _key, int256 _value)
        public
        override
        onlyLatestTugContract
    {
        intStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setBytes32(bytes32 _key, bytes32 _value)
        public
        override
        onlyLatestTugContract
    {
        bytes32Storage[_key] = _value;
    }

    /// @param _key The key for the record
    function deleteAddress(bytes32 _key) public override onlyLatestTugContract {
        delete addressStorage[_key];
    }

    /// @param _key The key for the record
    function deleteUint(bytes32 _key) public override onlyLatestTugContract {
        delete uintStorage[_key];
    }

    /// @param _key The key for the record
    function deleteString(bytes32 _key) public override onlyLatestTugContract {
        delete stringStorage[_key];
    }

    /// @param _key The key for the record
    function deleteBytes(bytes32 _key) public override onlyLatestTugContract {
        delete bytesStorage[_key];
    }

    /// @param _key The key for the record
    function deleteBool(bytes32 _key) public override onlyLatestTugContract {
        delete booleanStorage[_key];
    }

    /// @param _key The key for the record
    function deleteInt(bytes32 _key) public override onlyLatestTugContract {
        delete intStorage[_key];
    }

    /// @param _key The key for the record
    function deleteBytes32(bytes32 _key) public override onlyLatestTugContract {
        delete bytes32Storage[_key];
    }

    /// @param _key The key for the record
    /// @param _amount An amount to add to the record's value
    function addUint(bytes32 _key, uint256 _amount)
        external
        override
        onlyLatestTugContract
    {
        uintStorage[_key] += _amount;
    }

    /// @param _key The key for the record
    /// @param _amount An amount to subtract from the record's value
    function subUint(bytes32 _key, uint256 _amount)
        external
        override
        onlyLatestTugContract
    {
        uintStorage[_key] -= _amount;
    }

    // Known calls
    function getPricingEngineAddress() external view returns (address) {
        return priceEngine;
    }

    function getTreasuryAddress() external view returns (address) {
        return treasury;
    }

    function getTokenRegistryAddress() external view returns (address) {
        return tokenRegistry;
    }

    function setPricingEngineAddress(address _priceEngine) external  {
        require(msg.sender == guardian, "Is not guardian account");
        priceEngine = _priceEngine;
    }

    function setTreasuryAddress(address _treasury) external  {
        require(msg.sender == guardian, "Is not guardian account");
        treasury = _treasury;
    }

    function setTokenRegistryAddress(address _tokenRegistry) external {
        require(msg.sender == guardian, "Is not guardian account");
        tokenRegistry = _tokenRegistry;
    }
}