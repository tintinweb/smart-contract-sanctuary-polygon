// SPDX-License-Identifier: MIT
// Creator: 0xVinasaur
pragma solidity ^0.8.4;

import "./interfaces/IColorableMetadata.sol";
import "./interfaces/IColorableRegistry.sol";
import "./Ownable.sol";

// handles registrations of colorable collections
contract ColorableRegistry is IColorableRegistry, Ownable {
    mapping(address => bool) public override registeredColorableCollections;
    mapping(address => IColorableMetadata) public override collectionMetadata;

    function setIsRegisteredForColorableCollection(
        address _collection,
        address _collectionMetadata,
        bool _isRegistered
    ) external override onlyOwner {
        registeredColorableCollections[_collection] = _isRegistered;
        collectionMetadata[_collection] = IColorableMetadata(
            _collectionMetadata
        );
    }
}

// SPDX-License-Identifier: MIT
// Creator: 0xVinasaur
pragma solidity ^0.8.4;

import "./IColorableSectionMap.sol";

interface IColorableMetadata is IColorableSectionMap {
    function collectionMetadata(uint256 tokenId) external returns (uint256 traits);
}

// SPDX-License-Identifier: MIT
// Creator: 0xVinasaur
pragma solidity ^0.8.4;

import "./IColorableMetadata.sol";

// handles registrations of colorable collections
interface IColorableRegistry {
    function registeredColorableCollections(address collection) external returns (bool isRegistered);
    function collectionMetadata(address collection) external returns (IColorableMetadata colorableMetadata);
    function setIsRegisteredForColorableCollection(address _collection, address _colorableSectionMap, bool _isRegistered) external;
}

// SPDX-License-Identifier: MIT
// Creator: 0xVinasaur
pragma solidity ^0.8.4;

abstract contract Ownable {
    address public owner;
    event OwnershipTransferred(
        address indexed oldOwner_,
        address indexed newOwner_
    );

    constructor() {
        owner = msg.sender;
    }

    function _onlyOwner() internal view {
        require(owner == msg.sender, "Ownable: caller is not the owner");
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _transferOwnership(address newOwner_) internal virtual {
        address _oldOwner = owner;
        owner = newOwner_;
        emit OwnershipTransferred(_oldOwner, newOwner_);
    }

    function transferOwnership(address newOwner_) public virtual onlyOwner {
        require(
            newOwner_ != address(0x0),
            "Ownable: new owner is the zero address!"
        );
        _transferOwnership(newOwner_);
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0x0));
    }
}

// SPDX-License-Identifier: MIT
// Creator: 0xVinasaur
pragma solidity ^0.8.4;

interface IColorableSectionMap {    
    function colorableAreas(uint256 traitId, uint256 layerId) external returns (bool isColorable);
    function numColorableAreas(uint256 traitId) external returns (uint256 numColorableAreasOfTrait);
    function setColorableAreas(uint256[] calldata _traitIds, uint256[] calldata _colorableLayerIds) external;
    function verifyColorMap(uint256[] memory traitIds, uint256[] memory layerIdsToColor) external view;
}