// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Marketplace {
    struct Contributor {
        address currentOwner;
        address previousOwner;
        address buyer;
        address creator;
    }
    struct House {
        uint256 houseID;
        string tokenName;
        string tokenURI;
        string tokenType;
        uint256 price;
        uint256 numberOfTransfers;
        bool nftPayable;
        bool staked;
        bool soldStatus;
        Contributor contributor;
    }
    struct HistoryType {
        string hLabel;
        bool connectContract;
        bool imgNeed;
        bool brandNeed;
        bool descNeed;
        bool brandTypeNeed;
        bool yearNeed;
        bool checkMark;
        uint256 value;
    }
    struct LabelPercent {
        uint256 connectContract;
        uint256 image;
        uint256 brand;
        uint256 desc;
        uint256 brandType;
        uint256 year;
        uint256 checkMark;
    }

    address stakingContractAddress;
    uint256 public hTypeCounter;
    uint256 public royaltyCreator;
    uint256 public royaltyMarket;
    uint256 public minPrice;
    uint256 public maxPrice;

    LabelPercent public labelPercent;

    mapping(address => bool) public member;
    mapping(uint256 => House) public allHouses;
    mapping(uint256 => HistoryType) historyTypes;
    mapping(uint256 => mapping(address => bool)) public allowedList;

    event HouseStakedStatusSet(uint256 indexed tokenId, bool status, uint256 timestamp);
    event RoyaltyCreatorSet(address indexed member, uint256 royalty, uint256 timestamp);
    event RoyaltyMarketSet(address indexed member, uint256 royalty, uint256 timestamp);
    event HistoryTypeUpdated(
        address indexed member,
        uint256 indexed hID,
        string label,
        bool connectContract,
        bool imgNeed,
        bool brandNeed,
        bool descNeed,
        bool brandTypeNeed,
        bool yearNeed,
        bool checkMark,
        uint256 value,
        uint256 hTypeCounter,
        bool flag
    );
    event HistoryTypeRemoved(address indexed member, uint256 indexed hIndex, uint256 hTypeCounter, uint256 timestamp);

    constructor() {
        member[msg.sender] = true;
        royaltyCreator = 6;
        royaltyMarket = 2;
        minPrice = 10 ** 16;
        maxPrice = 10 ** 18;

        addDefaultHTypes();
    }

    modifier onlyMember() {
        require(member[msg.sender], 'Only Member');
        _;
    }

    function addDefaultHTypes() internal {
        historyTypes[0] = HistoryType({
            hLabel: 'Construction',
            connectContract: false,
            imgNeed: false,
            brandNeed: false,
            descNeed: false,
            brandTypeNeed: false,
            yearNeed: false,
            checkMark: false,
            value: 0
        });
        historyTypes[1] = HistoryType({
            hLabel: 'Floorplan',
            connectContract: true,
            imgNeed: true,
            brandNeed: true,
            descNeed: true,
            brandTypeNeed: false,
            yearNeed: true,
            checkMark: false,
            value: 0
        });
        historyTypes[2] = HistoryType({
            hLabel: 'Pictures',
            connectContract: true,
            imgNeed: true,
            brandNeed: true,
            descNeed: true,
            brandTypeNeed: true,
            yearNeed: true,
            checkMark: false,
            value: 0
        });
        historyTypes[3] = HistoryType({
            hLabel: 'Blueprint',
            connectContract: true,
            imgNeed: true,
            brandNeed: true,
            descNeed: true,
            brandTypeNeed: true,
            yearNeed: true,
            checkMark: false,
            value: 0
        });
        historyTypes[4] = HistoryType({
            hLabel: 'Solarpanels',
            connectContract: true,
            imgNeed: true,
            brandNeed: true,
            descNeed: true,
            brandTypeNeed: true,
            yearNeed: true,
            checkMark: false,
            value: 0
        });
        historyTypes[5] = HistoryType({
            hLabel: 'Airconditioning',
            connectContract: true,
            imgNeed: true,
            brandNeed: true,
            descNeed: true,
            brandTypeNeed: true,
            yearNeed: true,
            checkMark: false,
            value: 0
        });
        historyTypes[6] = HistoryType({
            hLabel: 'Sonneboiler',
            connectContract: true,
            imgNeed: true,
            brandNeed: true,
            descNeed: true,
            brandTypeNeed: true,
            yearNeed: true,
            checkMark: false,
            value: 0
        });
        historyTypes[7] = HistoryType({
            hLabel: 'Housepainter',
            connectContract: true,
            imgNeed: true,
            brandNeed: true,
            descNeed: true,
            brandTypeNeed: true,
            yearNeed: true,
            checkMark: false,
            value: 0
        });
        hTypeCounter = 7;
    }

    function setStakingContractAddress(address _address) external onlyMember {
        stakingContractAddress = _address;
    }

    function setHouseStakedStatus(uint256 _tokenId, bool _status) external {
        require(msg.sender == stakingContractAddress, 'Only Staking contract can call this func');
        allHouses[_tokenId].staked = _status;

        emit HouseStakedStatusSet(_tokenId, _status, block.timestamp);
    }
        
    function setLabelPercents(LabelPercent memory newLabelPercent) external onlyMember {
        labelPercent = newLabelPercent;
    }

    function setRoyaltyCreator(uint256 _royalty) external onlyMember {
        royaltyCreator = _royalty;

        emit RoyaltyCreatorSet(msg.sender, _royalty, block.timestamp);
    }

    function setRoyaltyMarket(uint256 _royalty) external onlyMember {
        royaltyMarket = _royalty;

        emit RoyaltyMarketSet(msg.sender, _royalty, block.timestamp);
    }

    function setMinMaxHousePrice(uint256 _min, uint256 _max) external onlyMember {
        minPrice = _min;
        maxPrice = _max;
    }

    function getMinMaxHousePrice() external view returns(uint256, uint256) {
        return (minPrice, maxPrice);
    }

    function getRoyalties() external view returns(uint256, uint256) {
        return (royaltyCreator, royaltyMarket);
    }

    function getLabelPercents() external view returns(LabelPercent memory) {
        return labelPercent;
    }

    function addMember(address _newMember) external onlyMember {
        member[_newMember] = true;
    }

    function removeMember(address _newMember) external onlyMember {
        member[_newMember] = false;
    }

    // Add History Type
    function addHistoryType(
        uint256 _historyIndex,
        string memory _label,
        bool _connectContract,
        bool _imgNeed,
        bool _brandNeed,
        bool _descNeed,
        bool _brandTypeNeed,
        bool _yearNeed,
        bool _checkMark,
        uint256 _value,
        bool flag
    ) external onlyMember {
        historyTypes[_historyIndex] = HistoryType({
            hLabel: _label,
            connectContract: _connectContract,
            imgNeed: _imgNeed,
            brandNeed: _brandNeed,
            descNeed: _descNeed,
            brandTypeNeed: _brandTypeNeed,
            yearNeed: _yearNeed,
            checkMark: _checkMark,
            value: _value
        });
        if (flag) hTypeCounter++;

        emit HistoryTypeUpdated(
            msg.sender,
            _historyIndex,
            _label,
            _connectContract,
            _imgNeed,
            _brandNeed,
            _descNeed,
            _brandTypeNeed,
            _yearNeed,
            _checkMark,
            _value,
            hTypeCounter,
            flag
        );
    }

    // Remove History Type
    function removeHistoryType(uint256 _hIndex) external onlyMember {
        for (uint i = _hIndex; i < hTypeCounter; i++) {
            historyTypes[i] = historyTypes[i + 1];
        }
        hTypeCounter--;

        emit HistoryTypeRemoved(msg.sender, _hIndex, hTypeCounter, block.timestamp);
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
}