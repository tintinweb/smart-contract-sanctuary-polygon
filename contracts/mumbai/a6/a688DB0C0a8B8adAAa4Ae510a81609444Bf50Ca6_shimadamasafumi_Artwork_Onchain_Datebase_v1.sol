/**
 *Submitted for verification at polygonscan.com on 2023-07-09
*/

/*

  　　　　SPDX-License-Identifier: MIT                                               
                                                                            
      　　　　shimadamasafumi ArtWork On-chain Datebase v1 {
                                                                             
          　　　　InventoryNumber (sm19M1_a1) {
                sm(shimadamasafumi),
                19(Year of public),                                            
                M(Term:EARLY,MID,LATE),                                        
                1(Total number),                                               
                _a1(Edition a=AP 1~?=ED 1=UNIQUE)
            }

            searchByKeyword {
                Keyword search has a partial match search function and does not distinguish between uppercase and lowercase letters.
            }

        }
                                                                   
*/

pragma solidity ^0.8.0;

contract shimadamasafumi_Artwork_Onchain_Datebase_v1 {

    struct Work {
        string inventoryNumber;
        string title_en;
        string title_ja;
        string material;
        string edition;
        string year;
        string size;
        string imageUrl;
        string status;
    }

    string private _linkUrl;
    mapping(uint256 => Work) private works;
    mapping(string => uint256) private workIdByTitle;
    uint256 private workCount;
    string private latestUpdateTitle;
    address private _owner;

    event WorkAdded(uint256 indexed workId);
    event InformationAdded(uint256 indexed workId);
    event ImageUrlUpdated(uint256 indexed workId);
    event StatusDeleted(uint256 indexed workId);
    event WorkRemoved(uint256 indexed workId);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    function LinkURL() public view returns (string memory) {
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
        string memory _status
    ) external onlyOwner {
        require(workIdByTitle[_inventoryNumber] == 0, "Work already exists");

        workCount += 1;
        works[workCount] = Work({
            inventoryNumber: string(abi.encodePacked("\u29BF ", _inventoryNumber)),
            title_en: _title_en,
            title_ja: _title_ja,
            material: _material,
            edition: _edition,
            year: _year,
            size: _size,
            imageUrl: _imageUrl,
            status: _status
        });

        workIdByTitle[_inventoryNumber] = workCount;
        latestUpdateTitle = _inventoryNumber;
        emit WorkAdded(workCount);
    }

    function addNewInformation(string memory _inventoryNumber, string memory _newInformation) external onlyOwner {
        uint256 workId = workIdByTitle[_inventoryNumber];
        require(workId > 0, "Work does not exist");

        Work storage work = works[workId];
        string memory currentInformation = work.status;
        string memory updatedInformation = string(abi.encodePacked(currentInformation, " \u2710 ", _newInformation));
        work.status = updatedInformation;
        latestUpdateTitle = _inventoryNumber;
        emit InformationAdded(workId);
    }

    function updateImageUrl(string memory _inventoryNumber, string memory _newImageUrl) external onlyOwner {
        uint256 workId = workIdByTitle[_inventoryNumber];
        require(workId > 0, "Work does not exist");

        works[workId].imageUrl = _newImageUrl;
        latestUpdateTitle = _inventoryNumber;
        emit ImageUrlUpdated(workId);
    }

    function deleteStatus(string memory _inventoryNumber) external onlyOwner {
        uint256 workId = workIdByTitle[_inventoryNumber];
        require(workId > 0, "Work does not exist");

        works[workId].status = "";
        emit StatusDeleted(workId);
    }


    function removeWork(string memory _inventoryNumber) external onlyOwner {
        require(workIdByTitle[_inventoryNumber] > 0, "Work does not exist");

        uint256 workId = workIdByTitle[_inventoryNumber];
        delete works[workId];
        delete workIdByTitle[_inventoryNumber];
        emit WorkRemoved(workId);
    }

    function latestUpdate() external view returns (string memory) {
        return latestUpdateTitle;
    }

    // Note: for optimization, this function is left as it is. Consider fetching only what you need in your frontend.
    function allInventoryNumber_Titles() external view returns (string memory) {
        string memory titles = "";
        string memory separator = ", ";

        for (uint256 i = 1; i <= workCount; i++) {
            Work storage work = works[i];
            titles = string(abi.encodePacked(titles, work.inventoryNumber, ": ", work.title_en, " / ", work.title_ja, separator));
        }
        return titles;
    }

    function searchByKeyword(string memory _keyword) external view returns (Work[] memory) {
    uint256 count = 0;
    Work[] memory result = new Work[](workCount);

    for (uint256 i = 1; i <= workCount; i++) {
        Work memory work = works[i];
        if (
            containsIgnoreCase(work.inventoryNumber, _keyword) ||
            containsIgnoreCase(work.title_en, _keyword) ||
            containsIgnoreCase(work.title_ja, _keyword) ||
            containsIgnoreCase(work.material, _keyword) ||
            containsIgnoreCase(work.edition, _keyword) ||
            containsIgnoreCase(work.year, _keyword) ||
            containsIgnoreCase(work.size, _keyword) ||
            containsIgnoreCase(work.imageUrl, _keyword) ||
            containsIgnoreCase(work.status, _keyword)
        ) {
            result[count] = work;
            count++;
        }
    }

    assembly {
        mstore(result, count)
    }

    return result;
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