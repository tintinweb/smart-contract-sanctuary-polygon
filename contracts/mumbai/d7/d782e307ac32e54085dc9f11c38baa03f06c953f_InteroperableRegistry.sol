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
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "./interfaces/IRegistry.sol";
import "./libraries/Base64.sol";

contract InteroperableRegistry is IRegistry, Ownable2Step  { 

    uint256 private propertyFee;
    uint256 private registryCreationFee;
    uint256 private registryUpdateFee;

    //mapping(contractId=>mapping(tokenId => mapping(chainId => ID))) public registryId;
    mapping(address=>mapping(uint256 => Property[])) private _propertyArray;
    mapping(address=>mapping(uint256 =>  Registry[])) private _registry;
    mapping(address => uint256) private _registryIndex;

    constructor(uint256 initialPropertyFee, uint256 initialRegistryFee, uint256 initialRegistryUpdateFee) {
        propertyFee = initialPropertyFee;
        registryCreationFee = initialRegistryFee;
        registryUpdateFee = initialRegistryUpdateFee;
    }


    function addRegistry(
        string memory contentHash, 
        string memory serviceURI, 
        uint256 tokenId, 
        address contractAddress) external payable {
            require(msg.value >= registryCreationFee, "Not enough ether to add registry");
            Registry memory newRegistry = Registry(contractAddress, tokenId, contentHash, serviceURI, msg.sender);
            if(_registry[contractAddress][tokenId].length > 0){
            require(_registry[contractAddress][tokenId][_registryIndex[msg.sender]].creator == address(0), "Registry already exists");
            }
            _registry[contractAddress][tokenId].push(newRegistry);
            _registryIndex[msg.sender] = _registry[contractAddress][tokenId].length - 1 ;

            emit NewRegistryAdded(contractAddress, tokenId, contentHash, serviceURI, msg.sender);
        }

        function updateRegistry(
        string memory contentHash, 
        string memory serviceURI, 
        uint256 tokenId, 
        address contractAddress) external payable {
            require(msg.value >= registryUpdateFee, "Not enough ether to add registry");
            
            Registry memory updatedRegistry = Registry(contractAddress, tokenId, contentHash, serviceURI, msg.sender);
            require(_registry[contractAddress][tokenId][_registryIndex[msg.sender]].creator == address(0), "Registry already exists");
            _registry[contractAddress][tokenId][_registryIndex[msg.sender]] = updatedRegistry;

            emit RegistryUpdated(contractAddress, tokenId, contentHash, serviceURI, msg.sender);
        }

    
    function addProperty(
        string memory propertyType, 
        string memory value, 
        uint256 tokenId, 
        address contractAddress ) external payable {
            uint256 targetRegistry = _registryIndex[msg.sender];
            Registry memory registryLocation = (_registry[contractAddress][tokenId])[targetRegistry];
            require(registryLocation.creator != address(0), "Registry does not exist");
            require(msg.value >= propertyFee, "Not enough ether to add property");
            require (msg.sender == registryLocation.creator, "Only creator can add properties" );

            Property memory newProperty = Property(propertyType, value);
            _propertyArray[contractAddress][tokenId].push(newProperty);
        
        emit NewPropertyAdded(propertyType, value, tokenId, contractAddress);
        }

    function addProperties(
        string[] memory propertyType, 
        string[] memory value, 
        uint256 tokenId, 
        address contractAddress) external {
            uint256 targetRegistry = _registryIndex[msg.sender];
            Registry memory registryLocation = (_registry[contractAddress][tokenId])[targetRegistry];
            require (msg.sender == registryLocation.creator, "Only creator can add properties" );

            for(uint i = 0; i < propertyType.length; i++) {
                Property memory newProperty = Property(propertyType[i], value[i]);
                _propertyArray[contractAddress][tokenId].push(newProperty);
            }

            emit PropertyArrayAdded(tokenId, contractAddress);
        }
    
    function withdraw() external onlyOwner {
       uint balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");
        (bool success, ) = (owner()).call{value: balance}("");
       require(success, "Transfer failed.");
    }

    function metadataAttributes(
        uint256 _tokenId, 
        address contractAddress) public view returns (string memory) {
        Property[] storage properties = _propertyArray[contractAddress][_tokenId];
        
        string memory propertiesStrings = '[';
        for (uint i = 0; i < properties.length; i++) {
            string memory propertiesJson = string(abi.encodePacked(
                '{"trait_type": "', 
                properties[i].trait_type, 
                '", "value": "', 
                properties[i].value, 
                '"}'
            ));
            propertiesStrings = string(abi.encodePacked(propertiesStrings, propertiesJson, i < properties.length - 1 ? "," : ""));
        }
        propertiesStrings = string(abi.encodePacked(propertiesStrings, ']'));

        string memory json = Base64.encode(
            abi.encodePacked(
            "{attributes ': ", propertiesStrings, "}"
            )
        );

        string memory output = string(
            abi.encodePacked("data:application/json;base64,", json)
        ); 
        return output;
    }

    function getPropertyArray(
        uint256 _tokenId, 
        address contractAddress) public view returns (Property[] memory) {
        return _propertyArray[contractAddress][_tokenId];
    }

    function getRegistryArray(
        uint256 _tokenId, 
        address contractAddress) public view returns (Registry[] memory) {
        return _registry[contractAddress][_tokenId];
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

interface IRegistry { 

    struct Registry {
        address contractAddress;
        uint256 tokenId;
        string contentHash;
        string serviceURI;
        address creator;
    }

    struct Property {
        string trait_type;
        string value;
    }

    event NewRegistryAdded(
        address contractAddress, 
        uint256 tokenId, 
        string contentHash, 
        string serviceURI, 
        address creator);

    event RegistryUpdated(
        address contractAddress, 
        uint256 tokenId, 
        string contentHash, 
        string serviceURI, 
        address creator);

    event NewPropertyAdded(
        string propertyType, 
        string value, 
        uint256 tokenId, 
        address contractAddress
      );

        event PropertyArrayAdded(
            uint256 tokenId,
            address contractAddress
           
        );

        function addRegistry(
            string memory contentHash, 
            string memory serviceURI, 
            uint256 tokenId, 
            address contractAddress
          ) external payable;
        
        function addProperty(
            string memory propertyType, 
            string memory value, 
            uint256 tokenId, 
            address contractAddress 
           ) external payable;
        
        function addProperties(
            string[] memory propertyType, 
            string[] memory value, 
            uint256 tokenId, 
            address contractAddress 
           ) external;

        function withdraw() external;
        
        function metadataAttributes(
            uint256 _tokenId, 
            address contractAddress
            ) external view returns (string memory);

        function getRegistryArray(
        uint256 _tokenId, 
        address contractAddress
       ) external view returns (Registry[] memory);

        function getPropertyArray(
        uint256 _tokenId, 
        address contractAddress
        ) external view returns (Property[] memory);
}

/**
 *Submitted for verification at Etherscan.io on 2021-09-05
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}