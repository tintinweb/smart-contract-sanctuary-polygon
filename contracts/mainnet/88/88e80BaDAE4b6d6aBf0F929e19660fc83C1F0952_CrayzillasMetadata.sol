// SPDX-License-Identifier: MIT
// Creator: 0xVinasaur
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./interfaces/IColorableMetadata.sol";
import "./ColorableSectionMap.sol";

contract CrayzillasMetadata is
    Ownable,
    IColorableMetadata,
    ColorableSectionMap
{
    mapping(uint256 => uint256) internal _collectionMetadata; // tokenId -> traitIds (compressed)
    address public rootChainCollectionAddress;
    string public name;
    uint8 internal numTraits;

    constructor(address _collection, string memory _name) {
        rootChainCollectionAddress = _collection;
        name = _name;
        numTraits = 8;
    }

    function setColorableAreas(
        uint256[] calldata _traitIds,
        uint256[] calldata _colorableAreas
    ) external override onlyOwner {
        _setColorableAreas(_traitIds, _colorableAreas);
    }

    function setName(string memory _name) public onlyOwner {
        name = _name;
    }

    function setRootChainCollectionAddress(address _collection)
        public
        onlyOwner
    {
        rootChainCollectionAddress = _collection;
    }

    function setCollectionMetadata(
        uint256[] calldata tokenIds,
        uint256[][] calldata tokenTraits
    ) external onlyOwner {
        uint256 _loopThrough = tokenIds.length;
        require(
            _loopThrough == tokenTraits.length,
            "CrayzillasMetadata#setCollectionMetadata: PARAM_LENGTH_MISMATCH"
        );
        for (uint256 i = 0; i < _loopThrough; i++) {
            _collectionMetadata[tokenIds[i]] = _compressTokenTraitsArray(tokenTraits[i]);
        }
    }

    // public view functions
    function collectionMetadata(uint256 tokenId) public view override returns (uint256[] memory) {
        return _parseCollectionMetadata(tokenId);
    }

    function _compressTokenTraitsArray(uint256[] memory tokenTraits) internal view returns (uint256) {
        uint256 traitIdsClamped = 0;
        uint256 len = tokenTraits.length;
        require(len == numTraits, "CrayzillasMetadata#_compressTokenTraitsArray: INVALID_TOKEN_TRAITS_LENGTH");

        for (uint256 i = 0; i < len; i++) {
            traitIdsClamped = traitIdsClamped*10000;
            traitIdsClamped += tokenTraits[i];
        }
        return traitIdsClamped;
    }

    function _parseCollectionMetadata(uint256 tokenId) internal view returns (uint256[] memory) {
        uint256 traitIdsClamped = _collectionMetadata[tokenId];
        uint256[] memory traitIds = new uint256[](numTraits);
        uint256 i = 0;
        while(traitIdsClamped > 0) {
            uint256 _traitId = traitIdsClamped % 10000;
            traitIds[i] = _traitId;
            i++;
            traitIdsClamped = traitIdsClamped/10000;
        }
        return traitIds;
    }
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

import "./IColorableSectionMap.sol";

interface IColorableMetadata is IColorableSectionMap {
    function collectionMetadata(uint256 tokenId) external returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
// Creator: 0xVinasaur
pragma solidity ^0.8.4;

import "./interfaces/IColorableSectionMap.sol";

abstract contract ColorableSectionMap is IColorableSectionMap {
    /**
    TraitIds -> TraitType
        0 -> Background
        1 -> Plates
        2 -> Base
        3 -> Skin
        4 -> Body
        5 -> Mouth
        6 -> Eye
        7 -> Head

    View Documentation for mapping of:
        TraitTypeIds to TraitTypes,
        TraitNameIds to TraitNames,
        TraitIds to Traits
    TraitId = <TraitTypeId><TraitNameIds>
    eg: 00010123
     
    /**
    @dev maps traitIds to the layer Ids that are colorable
        traitIds -> # colorable areas
    */
    mapping(uint256 => mapping(uint256 => bool)) internal _colorableAreas; // traitId -> layerId -> isColorable
    mapping(uint256 => uint256) internal _numColorableAreas; // traitIds -> # colorable areas

    function colorableAreas(uint256 traitId, uint256 layerId)
        public
        view
        override
        returns (bool isColorable)
    {
        return _colorableAreas[traitId][layerId];
    }

    function numColorableAreas(uint256 traitId)
        public
        view
        override
        returns (uint256 numColorableAreasOfTrait)
    {
        return _numColorableAreas[traitId];
    }

    // pass in an array of arrays
    function _setColorableAreas(uint256[] calldata _traitIds, uint256[] calldata _colorableLayerIds)
        internal
        virtual
    {
        uint256 _loopThrough = _traitIds.length;
        require(
            _loopThrough == _colorableLayerIds.length,
            "ColorableSectionMap#_setColorableAreas: PARAM_LENGTH_MISMATCH"
        );
        for (uint256 i = 0; i < _loopThrough; i++) {
            uint256 traitId = _traitIds[i];
            uint256 colorableLayerId = _colorableLayerIds[i];
            _colorableAreas[traitId][colorableLayerId] = true;
            _numColorableAreas[traitId]++;
        }
    }

    /**
    @dev verifies that each layerId is colorable for a traitId
     */
    function verifyColorMap(uint256[] memory _traitIds, uint256[] memory _layerIdsToColor)
        public
        view
        override
    {
        uint256 _loopThrough = _traitIds.length;
        require(
            _loopThrough == _layerIdsToColor.length,
            "ColorableSectionMap#colorInCanvas: COLORMAP_LENGTH_MISMATCH"
        );
        for (uint256 i = 0; i < _loopThrough; i++) {
            require(
                _colorableAreas[_traitIds[i]][_layerIdsToColor[i]],
                "verifyColorMap#colorInCanvas: AREA_NOT_COLORABLE"
            );
        }
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