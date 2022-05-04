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
    mapping(uint256 => uint256) public override collectionMetadata; // traitId -> metadataMapping
    address public rootChainCollectionAddress;
    string public name;

    constructor(address _collection, string memory _name) {
        rootChainCollectionAddress = _collection;
        name = _name;
    }

    function setColorableAreas(
        uint256[] calldata _traitIds,
        uint256[] calldata _colorableAreas
    ) external override(IColorableSectionMap, ColorableSectionMap) onlyOwner {
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
        uint256[] calldata tokenId,
        uint256[] calldata tokenTraits
    ) external onlyOwner {
        uint256 _loopThrough = tokenId.length;
        require(
            _loopThrough == tokenTraits.length,
            "CrayzillasMetadata#setCollectionMetadata: PARAM_LENGTH_MISMATCH"
        );
        for (uint256 i = 0; i < _loopThrough; i++) {
            collectionMetadata[tokenId[i]] = tokenTraits[i];
        }
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
    function collectionMetadata(uint256 tokenId) external returns (uint256 traits);
}

// SPDX-License-Identifier: MIT
// Creator: 0xVinasaur
pragma solidity ^0.8.4;

import "./interfaces/IColorableSectionMap.sol";

abstract contract ColorableSectionMap is IColorableSectionMap {
    // mapping of traitTypes, traitNames, and mapping of colorableSections for the trait
    // eg:
    // {
    //     "head": {
    //         "wizard-hat": {
    //             1: true,
    //             2: true
    //         }
    //     }
    // }

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
     */

    /**
        View IPFS for mapping of:
            TraitTypeIds to TraitTypes,
            TraitNameIds to TraitNames,
            TraitIds to Traits
        TraitId = <TraitTypeId><TraitNameIds>
        eg: 00010123
     */
    /**
    @dev maps traitIds to the layer Ids that are colorable
        traitIds -> # colorable areas
    */
    mapping(uint256 => mapping(uint256 => bool)) public override colorableAreas;
    mapping(uint256 => uint256) public override numColorableAreas; // traitIds -> # colorable areas

    // pass in an array of arrays
    function _setColorableAreas(
        uint256[] calldata _traitIds,
        uint256[] calldata _colorableLayerIds
    ) internal virtual {
        require(
            _traitIds.length == _colorableLayerIds.length,
            "ColorableSectionMap#_setColorableAreas: PARAM_LENGTH_MIS_MATCH"
        );
        uint256 _loopThrough = _traitIds.length;
        for (uint256 i = 0; i < _loopThrough; i++) {
            colorableAreas[_traitIds[i]][_colorableLayerIds[i]] = true;
            numColorableAreas[_traitIds[i]]++;
        }
    }

    /**
    @dev to be overriden by contract inheritting ColorableSectionMap
     */
    function setColorableAreas(
        uint256[] calldata _traitIds,
        uint256[] calldata _colorableLayerIds
    ) external virtual override {}

    function verifyColorMap(
        uint256[] memory traitIds,
        uint256[] memory layerIdsToColor
    ) public view override {
        require(
            traitIds.length == layerIdsToColor.length,
            "ColorableSectionMap#colorInCanvas: COLORMAP_LENGTH_MISMATCH"
        );
        uint256 _loopThrough = traitIds.length;
        uint256[] memory _traitIds = traitIds;
        uint256[] memory _layerIdsToColor = layerIdsToColor;
        for (uint256 i = 0; i < _loopThrough; i++) {
            bool _isColorableArea = colorableAreas[_traitIds[i]][
                _layerIdsToColor[i]
            ];
            require(
                _isColorableArea,
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