/**
 *Submitted for verification at polygonscan.com on 2023-07-12
*/

/*
SPDX-License-Identifier: MIT
    shimadamasafumi On-chain Database v1 {
        SEQUENCE {
            [RegisteredDate(Unixtime), WorkId No., InventoryNumber, Title_en, Title_ja, Material, Edition, Term&Year, Size, ImageURL, Details, Exhibition, Status, ArtistMemo]
        }

        　InventoryNumber (sm19M1_a1) {
            sm(shimadamasafumi),
            19(Year of public),
            M(Term:EARLY,MID,LATE),
            1(Total number),
            _a1(Edition a=AP 1~?=ED 1=UNIQUE)
        }

        searchByKeyword {
            Keyword search has a partial match search function and does not distinguish between uppercase and lowercase letters.
            Display all work information with a single-space search.
        }
    }
*/

pragma solidity ^0.8.19;

contract Onchain_Database_v1 {

    struct Work {
        uint256 timestamp;
        uint256 workId;
        string inventoryNumber;
        string title_en;
        string title_ja;
        string material;
        string edition;
        string year;
        string size;
        string imageUrl;
        string details;
        string exhibition;
        string status;
        string artistMemo;
    }

    string private _ArtistInfo;
    string private _sequence;
    string private _howToViewInventoryNumber;
    string private _linkUrl;
    mapping(uint256 => Work) private works;
    mapping(bytes32 => uint256) private workIdByHash;
    uint256 private workCount;
    string private latestUpdateTitle;
    string private latestUpdateFunction;
    address private _owner;

    event WorkAdded(uint256 indexed workId, string inventoryNumber, string title_en);
    event StatusAdded(uint256 indexed workId, string inventoryNumber);
    event DetailAdded(uint256 indexed workId, string inventoryNumber);
    event ExhibitionAdded(uint256 indexed workId, string inventoryNumber);
    event MemoAdded(uint256 indexed workId, string inventoryNumber);
    event ImageUrlUpdated(uint256 indexed workId, string inventoryNumber);
    event WorkRemoved(uint256 indexed workId, string inventoryNumber);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    constructor() {

        _owner = msg.sender;
        _sequence = "[RegisteredDate(Unixtime), WorkId No., InventoryNumber, Title_en, Title_ja, Material, Edition, Term&Year, Size, ImageURL, Details, Exhibition, Status, ArtistMemo]";
        _howToViewInventoryNumber = "sm19M1_a1 [sm(shimadamasafumi),19(Year of public),M(Term:EARLY,MID,LATE),1(Total number),_a1(Edition a=AP 1~?=ED 1=UNIQUE)]";

    }

    function ArtistInfo() public view returns (string memory) {
        return _ArtistInfo;
    }

    function updateArtistInformation(string memory newArtistInfo) public onlyOwner {
        _ArtistInfo = newArtistInfo;
    }

    function HowToViewSequenceOfWorksInformation() public view returns (string memory) {
        return _sequence;
    }

    function HowToViewInventoryNumber() public view returns (string memory) {
        return _howToViewInventoryNumber;
    }

    function ArtistLinkURL() public view returns (string memory) {
        return _linkUrl;
    }

    function updateLinkURL(string memory newLinkUrl) public onlyOwner {
        _linkUrl = newLinkUrl;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function renounceOwnership() public onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function addWork(
        string memory _inventoryNumber,
        string memory _title_en,
        string memory _title_ja,
        string memory _material,
        string memory _edition,
        string memory _year,
        string memory _size,
        string memory _imageUrl,
        string memory _details,
        string memory _exhibition,
        string memory _status,
        string memory _artistMemo
    ) external onlyOwner {
        bytes32 hash = keccak256(abi.encodePacked(_inventoryNumber));

        require(workIdByHash[hash] == 0, "Work already exists");

        workCount += 1;
        works[workCount] = Work({
            timestamp: block.timestamp,
            workId: workCount,
            inventoryNumber: _inventoryNumber,
            title_en: _title_en,
            title_ja: _title_ja,
            material: _material,
            edition: _edition,
            year: _year,
            size: _size,
            imageUrl: _imageUrl,
            details: _details,
            exhibition: string(abi.encodePacked(" \u26FF ", _exhibition)),
            status: string(abi.encodePacked(" \u23F1 ", _status)),
            artistMemo: string(abi.encodePacked(" \u2710 ", _artistMemo))
        });

        workIdByHash[hash] = workCount;
        latestUpdateTitle = _inventoryNumber;
        latestUpdateFunction = "addWork";
        emit WorkAdded(workCount, _inventoryNumber, _title_en);
    }

    function newDetail(string memory _inventoryNumber, string memory _newDetail) external onlyOwner {
        bytes32 hash = keccak256(abi.encodePacked(_inventoryNumber));
        uint256 workId = workIdByHash[hash];
        require(workId > 0, "Work does not exist");

        Work storage work = works[workId];
        string memory currentDetail = work.details;
        string memory updatedDetail = string(abi.encodePacked(currentDetail, " / ", _newDetail));
        work.details = updatedDetail;
        latestUpdateTitle = _inventoryNumber;
        latestUpdateFunction = "newDetail";
        emit DetailAdded(workId, _inventoryNumber);
    }

    function newExhibition(string memory _inventoryNumber, string memory _newExhibition) external onlyOwner {
        bytes32 hash = keccak256(abi.encodePacked(_inventoryNumber));
        uint256 workId = workIdByHash[hash];
        require(workId > 0, "Work does not exist");

        Work storage work = works[workId];
        string memory currentExhibition = work.exhibition;
        string memory updatedExhibition = string(abi.encodePacked(currentExhibition, " / ", _newExhibition));
        work.exhibition = updatedExhibition;
        latestUpdateTitle = _inventoryNumber;
        latestUpdateFunction = "newExhibition";
        emit ExhibitionAdded(workId, _inventoryNumber);
    }

    function newStatus(string memory _inventoryNumber, string memory _newStatus) external onlyOwner {
        bytes32 hash = keccak256(abi.encodePacked(_inventoryNumber));
        uint256 workId = workIdByHash[hash];
        require(workId > 0, "Work does not exist");

        Work storage work = works[workId];
        string memory currentStatus = work.status;
        string memory updatedStatus = string(abi.encodePacked(currentStatus, " / ", _newStatus));
        work.status = updatedStatus;
        latestUpdateTitle = _inventoryNumber;
        latestUpdateFunction = "newStatus";
        emit StatusAdded(workId, _inventoryNumber);
    }

    function newMemo(string memory _inventoryNumber, string memory _newMemo) external onlyOwner {
        bytes32 hash = keccak256(abi.encodePacked(_inventoryNumber));
        uint256 workId = workIdByHash[hash];
        require(workId > 0, "Work does not exist");

        Work storage work = works[workId];
        string memory currentMemo = work.artistMemo;
        string memory updatedMemo = string(abi.encodePacked(currentMemo, " / ", _newMemo));
        work.artistMemo = updatedMemo;
        latestUpdateTitle = _inventoryNumber;
        latestUpdateFunction = "newMemo";
        emit MemoAdded(workId, _inventoryNumber);
    }

    function updateImageUrl(string memory _inventoryNumber, string memory _newImageUrl) external onlyOwner {
        bytes32 hash = keccak256(abi.encodePacked(_inventoryNumber));
        uint256 workId = workIdByHash[hash];
        require(workId > 0, "Work does not exist");

        Work storage work = works[workId];
        work.imageUrl = _newImageUrl;
        latestUpdateTitle = _inventoryNumber;
        latestUpdateFunction = "updateImageUrl";
        emit ImageUrlUpdated(workId, _inventoryNumber);
    }

    function removeWork(string memory _inventoryNumber) external onlyOwner {
        bytes32 hash = keccak256(abi.encodePacked(_inventoryNumber));
        uint256 workId = workIdByHash[hash];
        require(workId > 0, "Work does not exist");

        delete works[workId];
        delete workIdByHash[hash];
        latestUpdateTitle = _inventoryNumber;
        latestUpdateFunction = "removeWork";
        emit WorkRemoved(workId, _inventoryNumber);
    }

    function latestUpdate() external view returns (string memory, string memory) {
        return (latestUpdateTitle, latestUpdateFunction);
    }

    function searchByKeyword(string memory _keyword) external view returns (Work[] memory) {
    uint256 count = 0;
    Work[] memory result = new Work[](workCount);

    for (uint256 i = 1; i <= workCount; i++) {
        Work memory work = works[i];
        if (containsInWorkProperties(work, _keyword)) {
            result[count] = work;
            count++;
        }
    }

    assembly {
        mstore(result, count)
    }

    return result;
    }
    
    function containsInWorkProperties(Work memory work, string memory _keyword) internal pure returns (bool) {
        return containsIgnoreCase(work.inventoryNumber, _keyword) ||
        containsIgnoreCase(work.title_en, _keyword) ||
        containsIgnoreCase(work.title_ja, _keyword) ||
        containsIgnoreCase(work.material, _keyword) ||
        containsIgnoreCase(work.edition, _keyword) ||
        containsIgnoreCase(work.year, _keyword) ||
        containsIgnoreCase(work.size, _keyword) ||
        containsIgnoreCase(work.imageUrl, _keyword) ||
        containsIgnoreCase(work.details, _keyword) ||
        containsIgnoreCase(work.exhibition, _keyword) ||
        containsIgnoreCase(work.status, _keyword) ||
        containsIgnoreCase(work.artistMemo, _keyword);
        }

    function containsIgnoreCase(string memory _str, string memory _subStr) internal pure returns (bool) {
        bytes memory strBytes = bytes(_str);
        bytes memory subStrBytes = bytes(_subStr);
        
        if (strBytes.length < subStrBytes.length) {
            return false;
        }
        
        for (uint256 i = 0; i <= strBytes.length - subStrBytes.length; i++) {
            bool found = true;
            for (uint256 j = 0; j <subStrBytes.length; j++) {
                if (toLowerCase(strBytes[i + j]) != toLowerCase(subStrBytes[j])) {
                    found = false;
                    break;
                }
            }
            if (found) {
                return true;
            }
        }
        return false;
    }
    
    function toLowerCase(bytes1 _char) internal pure returns (bytes1) {
        if (_char >= 0x41 && _char <= 0x5A) {
            return bytes1(uint8(_char) + 32);
        }
        return _char;
    }
}