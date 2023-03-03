pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "./IECRegistry.sol";
//import "hardhat/console.sol";

contract VisualTraitRegistry {

    uint16      public immutable    traitId;
    IECRegistry public              ECRegistry;


    struct definition {
        uint8       len;
        string      name;
    }

    struct field {
        uint8       start;
        uint8       len;
        string      name;
    }

    bytes32 public constant CONTRACT_ADMIN = keccak256("CONTRACT_ADMIN");
    mapping(uint8   => mapping(uint8 => field))     public visualTraits;
    mapping(uint8   => mapping(string  => uint8))  public visualTraitPositions;

    mapping(uint8   => mapping(uint8 => mapping(uint256 => string))) public layerPointers;

    mapping(uint8 => string)                        public traitSetNames;
    mapping(uint8 => mapping(uint16 => uint256))    public visualTraitData;
    mapping(uint8 => uint256)                       public traitInfoLength;
    mapping(uint8 => uint16)                        public wordCount;
    mapping(uint8 => uint256)                       public numberOfTokens;
    mapping(uint8 =>uint256)                        public numberOfTraits;
    uint8                                           public numberOfTraitSets;

    event updateTraitEvent(uint8 _side, uint16 indexed _tokenId,  uint256 _newData, uint8 dataLength);
    event TraitsUpdated(uint8 traitSet, uint16 tokenId, uint256 newData, uint256 oldData);
    event WordFound(uint8 traitSet,uint256 nwordPos,uint256 answer);
    event WordUpdated(uint8 traitSet,uint256 wordPos,uint256 answer);


    modifier onlyAllowed() { // commented out for easy testing
        // require(
        //     ECRegistry.addressCanModifyTrait(msg.sender, traitId),
        //     "Not Authorised" 
        // );
        _;
    }


    constructor(address _registry, uint16 _traitId) public {
        traitId = _traitId;
        ECRegistry = IECRegistry(_registry);
    }

    function createTraitSet(string calldata traitSetName, definition[] calldata traitInfo) external  onlyAllowed {
        uint8 _newTraitSet = numberOfTraitSets++;
        traitSetNames[_newTraitSet] = traitSetName;
        uint8 start;
        for (uint8 pos = 0; pos < traitInfo.length; pos++) {
            // console.log(
            //     traitInfo[pos].len,
            //     traitInfo[pos].name
            // );
            visualTraitPositions[_newTraitSet][traitInfo[pos].name] = pos;
            visualTraits[_newTraitSet][pos] = field(
                start,
                traitInfo[pos].len,
                traitInfo[pos].name
            );
            start += traitInfo[pos].len;
        }
        numberOfTraits[_newTraitSet] = traitInfo.length;
        traitInfoLength[_newTraitSet] = start;
    }

    // @dev setTraitsByWordStream writes the initial words of a trait set. 
    // if there is too much data to fit in one Tx, continue with addMoreTraitsByWordStream
    function setTraitsByWordStream(uint8 traitSet, uint256[] calldata traitData, uint16 count) external onlyAllowed {
        for (uint16 pos = 0; pos < uint16(traitData.length); pos++) {
            visualTraitData[traitSet][pos] = traitData[pos];
        }
        wordCount[traitSet] = uint16(traitData.length);
        numberOfTokens[traitSet] = count;
    }

    // @dev addMoreTraitsByWordStream is used if there is too much data. 
    // in this case you would split the word array into parts. 
    // addMoreTraitsByWordStream can be called many times to append more data
    function addMoreTraitsByWordStream(uint8 traitSet, uint256[] calldata traitData, uint16 count) external onlyAllowed {
        uint16 start = wordCount[traitSet];
        for (uint16 pos = 0; pos < traitData.length; pos++) {
            visualTraitData[traitSet][start++] = traitData[pos];
        }
        wordCount[traitSet] = start;
        numberOfTokens[traitSet] = count;
    }

    function getWholeTraitData(uint8 traitSet, uint16 tokenId) external  view returns(uint256) {
        return _getWholeTraitData(traitSet,tokenId);
    }

    function _getWholeTraitData(uint8 traitSet, uint16 tokenId) internal  view returns(uint256) {
        uint256 traitsLength = traitInfoLength[traitSet];
        uint256 bitPosFromZero = uint256(tokenId) * traitsLength;
        uint256 bitPos = bitPosFromZero % 256;
        uint16  wordPos = uint16(bitPosFromZero / 256);
        if ((bitPos + traitsLength) < 256) {
            // all fits in one word
            uint256 answer = visualTraitData[traitSet][wordPos];
            answer = answer  >> bitPos;
            uint256 mask   = (1 << (traitsLength)) - 1;
            return (answer & mask);
        } else {
            //console.log("split enz");
            uint256 answer_1 = visualTraitData[traitSet][wordPos] >> bitPos;
            uint256 answer_2 = visualTraitData[traitSet][wordPos+1] << 256 - bitPos;
            uint256 mask_2   = (1 << (traitsLength)) - 1;
            return answer_1  + (answer_2 & mask_2);
        }
    }

    function getIndividualTraitData(uint8 traitSet, uint8 position, uint16 tokenId) external view returns (uint256) {
        uint wtd = _getWholeTraitData(traitSet,tokenId);
        uint start = visualTraits[traitSet][position].start;
        uint len   = visualTraits[traitSet][position].len;
        return (wtd >> start) & ((1 << len) - 1 );
    }

    function setIndividualTraitData(uint8 traitSet, uint8 position, uint16 tokenId, uint256 newData) external onlyAllowed {
        uint oldTraitData = _getWholeTraitData(traitSet,tokenId);
        uint start = visualTraits[traitSet][position].start;
        uint len   = visualTraits[traitSet][position].len;
        uint traitData = (oldTraitData >> start) & ((1 << len) - 1 );
        uint newTraitData = oldTraitData - (traitData << start) + (newData << start);
        _setWholeTraitData(traitSet,tokenId,newTraitData,oldTraitData);
    }

    function setWholeTraitData(uint8 traitSet, uint16 tokenId, uint256 newData) external onlyAllowed {
        uint oldData = _getWholeTraitData(traitSet,tokenId);
        _setWholeTraitData(traitSet,tokenId,newData, oldData);
    }

    function _setWholeTraitData(uint8 traitSet, uint16 tokenId, uint256 newData, uint256 oldData) internal {
        uint256 traitsLength = traitInfoLength[traitSet];
        uint256 bitPosFromZero = uint256(tokenId) * traitsLength;
        uint256 bitPos = bitPosFromZero % 256;
        uint16  wordPos = uint16(bitPosFromZero / 256);
        if ((bitPos + traitsLength) < 256) {
            uint256 answer = visualTraitData[traitSet][wordPos];
            emit WordFound(traitSet,wordPos,answer);
            answer -= oldData << bitPos;
            answer += newData << bitPos;
            visualTraitData[traitSet][wordPos] = answer;
            emit WordUpdated(traitSet,wordPos,answer);
        } else {
            uint256 answer_1 = visualTraitData[traitSet][wordPos];
            uint256 answer_2 = visualTraitData[traitSet][wordPos+1];
            emit WordFound(traitSet,wordPos,answer_1);
            emit WordFound(traitSet,wordPos+1,answer_2);

            answer_1 -= oldData << bitPos;
            answer_1 += newData << bitPos;

            answer_2 -= oldData >> (256 - bitPos);
            answer_2 += newData >> (256 - bitPos);

            visualTraitData[traitSet][wordPos]     = answer_1;
            visualTraitData[traitSet][wordPos + 1] = answer_2;
            emit WordUpdated(traitSet,wordPos,answer_1);
            emit WordUpdated(traitSet,wordPos+1,answer_2);
        }
        emit TraitsUpdated(traitSet, tokenId, newData,  oldData);
    }

    function getTraitNames(uint8 traitSet) external view returns (string[] memory) {
        uint256 numTraits = numberOfTraits[traitSet];
        string[] memory response = new string[](numTraits);
        for (uint8 pos = 0; pos < numTraits; pos++) {
            response[pos] = visualTraits[traitSet][pos].name;
        }
        return response;
    }

    // function getValues(uint16 tokenId) external view returns (uint256[] memory) {
    //     uint8 nts = numberOfTraitSets;
    //     uint256[] memory response = new uint256[](nts);
    //     for (uint8 pos = 0; pos < nts; pos++) {
    //         response[pos] = _getWholeTraitData(pos,tokenId);
    //     }
    //     return response;
    // }

    // function getValues(uint16[] calldata tokenIds) external view returns (uint256[][] memory) {
    //     uint8 nts = numberOfTraitSets;
    //     uint256[][] memory response = new uint256[][](tokenIds.length);
    //     for (uint tokenPos = 0; tokenPos < tokenIds.length; tokenPos++){
    //         uint16 tokenId = tokenIds[tokenPos];
    //         response[tokenPos] = new uint256[](nts);
    //         for (uint8 pos = 0; pos < nts; pos++) {
    //             response[tokenPos][pos] = _getWholeTraitData(pos,tokenId);
    //         }
    //     }
    //     return response;
    // }

    // following signatures suggested by Micky

    function getValue(uint16 tokenId, uint8 sideId, uint8 layerId ) external view returns ( uint8 ) {
        uint wtd = _getWholeTraitData(sideId,tokenId);
        uint start = visualTraits[sideId][layerId].start;
        uint len   = visualTraits[sideId][layerId].len;
        return uint8((wtd >> start) & ((1 << len) - 1 ));
    }

    function getValues(uint16 tokenId, uint8 sideId ) external view returns (uint8[] memory response) {
        uint wtd = _getWholeTraitData(sideId,tokenId);
        uint nots = numberOfTraits[sideId];
        response  = new uint8[](nots);
        uint start = 0;
        for (uint8 layerId = 0; layerId < nots; layerId++) {
            uint len = visualTraits[sideId][layerId].len;
            response[layerId] = uint8((wtd >> start) & ((1 << len) - 1 ));
            start += len;
        }
        return response;
    }

    function getValues(uint16 tokenId) external view returns (uint8[][] memory response) {
        uint8 nts = numberOfTraitSets;
        response = new uint8[][](nts);
        for (uint8 sideId = 0; sideId < nts; sideId++) {
            uint wtd = _getWholeTraitData(sideId,tokenId);
            uint numTraits = numberOfTraits[sideId];
            response[sideId] = new uint8[](numTraits);
            uint start = 0;
            for (uint8 layerId = 0; layerId < numTraits; layerId++) {
                uint len = visualTraits[sideId][layerId].len;
                response[sideId][layerId] = uint8((wtd >> start) & ((1 << len) - 1 ));
                start += len;
            }
        }
        return response;
    }

    function getValues(uint16[] calldata tokenIds) external view returns (uint8[][][] memory response) {
        uint8 numberOfSides = numberOfTraitSets;
        response = new uint8[][][](tokenIds.length);
        for (uint tokenPos = 0; tokenPos < tokenIds.length; tokenPos++){
            uint16 tokenId = tokenIds[tokenPos];
            response[tokenPos] = new uint8[][](numberOfSides);
            for (uint8 sideId = 0; sideId < numberOfSides; sideId++) {
                uint wtd = _getWholeTraitData(sideId,tokenId);
                uint numTraits = numberOfTraits[sideId];
                response[tokenPos][sideId] = new uint8[](numTraits);
                uint start = 0;
                for (uint8 layerId = 0; layerId < numTraits; layerId++) {
                    uint len = visualTraits[sideId][layerId].len;
                    response[tokenPos][sideId][layerId] = uint8((wtd >> start) & ((1 << len) - 1 ));
                    start += len;
                }
            }
        }
        return response;
    }
}

pragma solidity >=0.6.0 <0.8.0;

interface IECRegistry {
    function getImplementer(uint16 traitID) external view returns (address);
    function addressCanModifyTrait(address, uint16) external view returns (bool);
    function addressCanModifyTraits(address, uint16[] calldata ) external view returns (bool);
    function hasTrait(uint16 traitID, uint16 tokenID) external view returns (bool);
    function setTrait(uint16 traitID, uint16 tokenID, bool) external;
    function haveTrait(uint16 traitID, uint16[] calldata tokenIds) external view returns (bool[] memory result) ;
    function setTraitOnTokens(uint16 traitID, uint16[] calldata tokenID, bool[] calldata) external;
    function owner() external view returns (address);
    function contractController(address) external view returns (bool);
}