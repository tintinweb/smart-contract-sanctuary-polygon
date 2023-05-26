// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract Marketplace {
    address stakingContractAddress;
    uint256 public hTypeCounter;
    uint256 public royaltyCreator;
    uint256 public royaltyMarket;

    struct HistoryType {
        string hLabel;
        bool connectContract;
        bool imgNeed;
        bool brandNeed;
        bool descNeed;
        bool brandTypeNeed;
        bool yearNeed;
        bool otherInfo;
        uint256 value;
    }
    struct LabelPercent {
        uint256 connectContract;
        uint256 image;
        uint256 brand;
        uint256 desc;
        uint256 brandType;
        uint256 year;
        uint256 otherInfo;
    }

    struct LabelValue {
        uint256 connectContract;
        uint256 image;
        uint256 brand;
        uint256 desc;
        uint256 brandType;
        uint256 year;
        uint256 otherInfo;
    }

    LabelPercent public labelPercent;
    LabelValue public labelValue;

    mapping(address => bool) public member;
    mapping(uint256 => HistoryType) historyTypes;
    mapping(uint256 => mapping(address => bool)) public allowedList;

    event HouseStakedStatusSet(uint256 indexed tokenId, bool status, uint256 timestamp);
    event RoyaltyCreatorSet(address indexed member, uint256 royalty, uint256 timestamp);
    event RoyaltyMarketSet(address indexed member, uint256 royalty, uint256 timestamp);

    constructor() {
        member[msg.sender] = true;
        royaltyCreator = 6;
        royaltyMarket = 2;
    }

    modifier onlyMember() {
        require(member[msg.sender], 'Only Member');
        _;
    }

    function setRoyaltyCreator(uint256 _royalty) external onlyMember {
        royaltyCreator = _royalty;

        emit RoyaltyCreatorSet(msg.sender, _royalty, block.timestamp);
    }

    function setRoyaltyMarket(uint256 _royalty) external onlyMember {
        royaltyMarket = _royalty;

        emit RoyaltyMarketSet(msg.sender, _royalty, block.timestamp);
    }

    function getRoyalties() external view returns (uint256, uint256) {
        return (royaltyCreator, royaltyMarket);
    }

    function setLabelPercents(LabelPercent memory newLabelPercent) external onlyMember {
        labelPercent = newLabelPercent;
    }

    function setLabelValue(LabelValue memory newLabelValue) external onlyMember {
        labelValue = newLabelValue;
    }

    function addMember(address _newMember) external onlyMember {
        member[_newMember] = true;
    }

    function removeMember(address _newMember) external onlyMember {
        member[_newMember] = false;
    }

    function addOrEditHistoryType(
        uint256 _historyIndex,
        string memory _label,
        bool _connectContract,
        bool _image,
        bool _brand,
        bool _description,
        bool _brandType,
        bool _year,
        bool _otherInfo,
        uint256 _value,
        bool flag
    ) external onlyMember {
        historyTypes[_historyIndex] = HistoryType({
            hLabel: _label,
            connectContract: _connectContract,
            imgNeed: _image,
            brandNeed: _brand,
            descNeed: _description,
            brandTypeNeed: _brandType,
            yearNeed: _year,
            otherInfo: _otherInfo,
            value: _value
        });
        if (flag) {
            hTypeCounter++;
        }
    }

    // Remove History Type
    function removeHistoryType(uint256 _hIndex) external onlyMember {
        for (uint i = _hIndex; i < hTypeCounter; i++) {
            historyTypes[i] = historyTypes[i + 1];
        }
        hTypeCounter--;
    }

    // Get History Type
    function getAllHistoryTypes() external view returns (HistoryType[] memory) {
        HistoryType[] memory tempHistoryType = new HistoryType[](hTypeCounter);
        for (uint256 i = 0; i < hTypeCounter; i++) {
            tempHistoryType[i] = historyTypes[i];
        }
        return tempHistoryType;
    }

    function getHistoryTypeById(uint256 _typeId) external view returns (HistoryType memory) {
        return historyTypes[_typeId];
    }

    function getLabelPercents() external view returns (LabelPercent memory) {
        return labelPercent;
    }

    function getLabelValue() external view returns (LabelValue memory) {
        return labelValue;
    }
}