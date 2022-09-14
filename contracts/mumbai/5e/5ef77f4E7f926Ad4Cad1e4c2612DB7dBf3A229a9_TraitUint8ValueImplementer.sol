//SPDX-License-Identifier: Unlicensed

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;
import "./IECRegistry.sol";

contract TraitUint8ValueImplementer {

    uint16      public immutable    traitId;
    IECRegistry public              ECRegistry;

    //  tokenID => uint value
    mapping(uint16 => uint8) public data;

    event updateTraitEvent(uint16 indexed _tokenId, uint8 _newData);

    constructor(address _registry, uint16 _traitId) public {
        traitId = _traitId;
        ECRegistry = IECRegistry(_registry);
    }

    // update multiple token values at once
    function setData(uint16[] memory _tokenIds, uint8[] memory _value) public onlyAllowed {
        for (uint16 i = 0; i < _tokenIds.length; i++) {
            data[_tokenIds[i]] = _value[i];
            emit updateTraitEvent(_tokenIds[i], _value[i]);
        }
    }

    function setData2(uint16[] memory _tokenIds, uint8[] memory _value) public onlyAllowed {
        for (uint16 i = 0; i < _tokenIds.length; i++) {
            data[_tokenIds[i]] = _value[i];
            emit updateTraitEvent(_tokenIds[i], _value[i]);
        }
    }

    // update one
    function setValue(uint16 _tokenId, uint8 _value) public onlyAllowed {
        data[_tokenId] = _value;
        emit updateTraitEvent(_tokenId, _value);
    }

    function getValue(uint16 _tokenId) public view returns (uint8) {
         return data[_tokenId];
    }

    modifier onlyAllowed() {
        require(
            ECRegistry.addressCanModifyTrait(msg.sender, traitId),
            "Not Authorised" 
        );
        _;
    }
}

pragma solidity >=0.6.0 <0.8.0;

interface IECRegistry {
    function getImplementer(uint16 traitID) external view returns (address);
    function addressCanModifyTrait(address, uint16) external view returns (bool);
    function addressCanModifyTraits(address, uint16[] calldata ) external view returns (bool);
    function hasTrait(uint16 traitID, uint16 tokenID) external view returns (bool);
    function setTrait(uint16 traitID, uint16 tokenID, bool) external;
    function setTraitOnTokens(uint16 traitID, uint16[] calldata tokenID, bool[] calldata) external;
    function owner() external view returns (address);
    function contractController(address) external view returns (bool);
}