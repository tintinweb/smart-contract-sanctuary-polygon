//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Strings.sol";
import "./Base64.sol";
import "./IFishData.sol";

contract FishMetadata {
    using Strings for uint256;

    address immutable headDataAddr;
    address immutable eyesDataAddr;
    address immutable mouthDataAddr;
    address immutable bodyDataAddr;
    address immutable finsDataAddr;
    address immutable tailDataAddr;
    address immutable skinDataAddr;
    address immutable decoDataAddr;

    constructor(address _headDataAddr,
                address _eyesDataAddr,
                address _mouthDataAddr,
                address _bodyDataAddr,
                address _finsDataAddr,
                address _tailDataAddr,
                address _skinDataAddr,
                address _decoDataAddr) {
        headDataAddr = _headDataAddr;
        eyesDataAddr = _eyesDataAddr;
        mouthDataAddr = _mouthDataAddr;
        bodyDataAddr = _bodyDataAddr;
        finsDataAddr = _finsDataAddr;
        tailDataAddr = _tailDataAddr;
        skinDataAddr = _skinDataAddr;
        decoDataAddr = _decoDataAddr;
    }

    function buildURI(uint256 fishId,
                      uint8 headIdx,
                      uint8 eyesIdx,
                      uint8 mouthIdx,
                      uint8 bodyIdx,
                      uint8 finsIdx,
                      uint8 tailIdx,
                      uint8 skinIdx,
                      uint8 decoIdx) public view returns (string memory) {
        bytes memory metadata = buildMetadata(fishId, headIdx, eyesIdx, mouthIdx, bodyIdx, finsIdx, tailIdx, skinIdx, decoIdx);
        return string(bytes.concat('data:application/json;base64,', bytes(Base64.encode(metadata))));
    }

    function buildMetadata(uint256 fishId,
    	                   uint8 headIdx,
                           uint8 eyesIdx,
                           uint8 mouthIdx,
                           uint8 bodyIdx,
                           uint8 finsIdx,
                           uint8 tailIdx,
                           uint8 skinIdx,
                           uint8 decoIdx) private view returns (bytes memory) {
        bytes memory attrs = buildAttrs(headIdx, eyesIdx, mouthIdx, bodyIdx, finsIdx, tailIdx, skinIdx, decoIdx);
        bytes memory svg = buildSVG(headIdx, eyesIdx, mouthIdx, bodyIdx, finsIdx, tailIdx, skinIdx, decoIdx);
        bytes memory md = bytes.concat('{',
            '"description":"~ NFT Fishbowl ~",',
            '"name":"Fish#', bytes(fishId.toString()), '",', // TODO
            '"attributes":', attrs, ','
            '"image":"', bytes(svg), '"'
            '}');
        return md;
    }

    function buildAttrs(uint8 headIdx,
                        uint8 eyesIdx,
                        uint8 mouthIdx,
                        uint8 bodyIdx,
                        uint8 finsIdx,
                        uint8 tailIdx,
                        uint8 skinIdx,
                        uint8 decoIdx) private view returns (bytes memory) {
        bytes memory headAttr = IFishData(headDataAddr).getAttr(headIdx);
        bytes memory eyesAttr = IFishData(eyesDataAddr).getAttr(eyesIdx);
        bytes memory mouthAttr= IFishData(mouthDataAddr).getAttr(mouthIdx);
        bytes memory bodyAttr = IFishData(bodyDataAddr).getAttr(bodyIdx);
        bytes memory finsAttr = IFishData(finsDataAddr).getAttr(finsIdx);
        bytes memory tailAttr = IFishData(tailDataAddr).getAttr(tailIdx);
        bytes memory skinAttr = IFishData(skinDataAddr).getAttr(skinIdx);
        bytes memory decoAttr = IFishData(decoDataAddr).getAttr(decoIdx);

        bytes memory attrs = bytes.concat('[{"trait_type":"Head","value":"', headAttr);
        attrs = bytes.concat(attrs, '"},{"trait_type":"Eyes","value":"', eyesAttr);
        attrs = bytes.concat(attrs, '"},{"trait_type":"Mouth","value":"',mouthAttr);
        attrs = bytes.concat(attrs, '"},{"trait_type":"Body","value":"', bodyAttr);
        attrs = bytes.concat(attrs, '"},{"trait_type":"Fins","value":"', finsAttr);
        attrs = bytes.concat(attrs, '"},{"trait_type":"Tail","value":"', tailAttr);
        attrs = bytes.concat(attrs, '"},{"trait_type":"Skin","value":"', skinAttr);
        attrs = bytes.concat(attrs, '"},{"trait_type":"Deco","value":"', decoAttr);
        attrs = bytes.concat(attrs, '"}]');
        return attrs;
    }

    function buildSVG(uint8 headIdx,
                      uint8 eyesIdx,
                      uint8 mouthIdx,
                      uint8 bodyIdx,
                      uint8 finsIdx,
                      uint8 tailIdx,
                      uint8 skinIdx,
                      uint8 decoIdx) public view returns (bytes memory) {
        bytes memory style;
        {
            bytes memory headStyle = IFishData(headDataAddr).getStyle(headIdx);
            bytes memory eyesStyle = IFishData(eyesDataAddr).getStyle(eyesIdx);
            bytes memory mouthStyle= IFishData(mouthDataAddr).getStyle(mouthIdx);
            bytes memory bodyStyle = IFishData(bodyDataAddr).getStyle(bodyIdx);
            bytes memory finsStyle = IFishData(finsDataAddr).getStyle(finsIdx);
            bytes memory tailStyle = IFishData(tailDataAddr).getStyle(tailIdx);
            bytes memory skinStyle = IFishData(skinDataAddr).getStyle(skinIdx);
            bytes memory decoStyle = IFishData(decoDataAddr).getStyle(decoIdx);
            style = bytes.concat('.a{fill:none;}', 
                headStyle, eyesStyle, mouthStyle, bodyStyle, finsStyle, tailStyle, skinStyle, decoStyle);
        }

        bytes memory data;
        {
            bytes memory headData = IFishData(headDataAddr).getData(headIdx);
            bytes memory eyesData = IFishData(eyesDataAddr).getData(eyesIdx);
            bytes memory mouthData= IFishData(mouthDataAddr).getData(mouthIdx);
            bytes memory bodyData = IFishData(bodyDataAddr).getData(bodyIdx);
            bytes memory finsData = IFishData(finsDataAddr).getData(finsIdx);
            bytes memory tailData = IFishData(tailDataAddr).getData(tailIdx);
            bytes memory skinData = IFishData(skinDataAddr).getData(skinIdx);
            bytes memory decoData = IFishData(decoDataAddr).getData(decoIdx);
            data = bytes.concat(
                headData, mouthData, eyesData, tailData, finsData, bodyData, skinData, decoData);
        }

        bytes memory svg = bytes.concat('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 200"><defs><style>',
            style, '</style></defs><title>fish</title><rect class="a" width="400" height="200"/>', data, '</svg>');

        return bytes.concat("data:image/svg+xml;base64,", bytes(Base64.encode(svg)));
    }

}