/**
 *Submitted for verification at polygonscan.com on 2023-07-07
*/

/////////////////////////////////////////////////////////////////////////////////
//                                                                             //   
//  shimadamasafumi ArtWork On-chain Datebase v1                               //
//                                                                             //
//  InventoryNumber (sm19M1_a1) {                                              //
//      sm(Name),                                                              //
//      19(Year of public),                                                    //
//      M(Term:EARLY,MID,LATE),                                                //
//      1(Total number),                                                       //
//      _a1(Edition a=AP 1~?=ED 1=UNIQUE)                                      //
//                                                                             //
/////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////
//                                                                             //
//                           .    4  .     j                                   //
//                            -dT"""77777"""6a,.]                              //
//                         .J"`                 (4a,                           //
//                       .(=                        (S,                        //
//                     .F                             /h.                      //
//                    .F                                4 ,                    //
//                   #                                    ,b                   //
//                 .%                                      ,L                  //
//                 J~                                       (p   `             //
//                 H                                         ?mAj,             //
//                [email protected]                             ..JT""Ya,.   W. .W,           //
//                .F          ..                J"        ?m. .b   W.          //
//              .J4]      .J"!``?"h,           J:   .gMN,   W. d,  ,b          //
//             [email protected] .F     .F  JMMe  ,h.         ([   HMMM#   .\ .b   #          //
//             f  .b     d  ,MMMM`  .\ `d\      ?m,  ?"=   .Y   W   #          //
//             @   H     v,   7^   .Y       ,     (4nJ..Jk"`    J; .]          //
//             W.  J<     ?WJ...JTF         4,     3  t  ?      ,].K           //
//             .h.+,b      ,   $            .b                  ,hB`           //
//              .MB=d,                      .F                  ,]             //
//              [email protected], N                      !                   (:             //
//              .#b?9"b                                         K              //
//             ,h.#   ?x                                      .%               //
//                     T,              .J"G.Y5.              .F                //
//                      v,             .D                  [email protected]                  //
//                        ?a.          ?! 7`            .J^                    //
//                           ?h,                     .J"`                      //
//                              "U(,.           ..JT"                          //
//                                   ?7""""""""^`                              //
//                                                                             //
/////////////////////////////////////////////////////////////////////////////////

// SPDX-License-Identifier: MIT

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

    function LinkURL() public view returns (string memory) {
        return _linkUrl;
    }

    function updateLinkURL(string memory newLinkUrl) public {
        _linkUrl = newLinkUrl;
    }

    mapping(uint256 => Work) private works;
    mapping(string => uint256) private workIdByTitle;
    uint256 private workCount;
    string private latestUpdateTitle;

    event WorkAdded(string indexed inventoryNumber, uint256 indexed tokenId);
    event InformationAdded(string indexed inventoryNumber, string newInformation, uint256 indexed tokenId);
    event ImageUrlUpdated(string indexed inventoryNumber, string newImageUrl, uint256 indexed tokenId);
    event StatusDeleted(string indexed inventoryNumber, uint256 indexed tokenId);
    event WorkRemoved(string indexed inventoryNumber);

    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(msg.sender);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function _checkOwner() internal view {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

    function renounceOwnership() public onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

        workCount++;
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
        emit WorkAdded(_inventoryNumber, workCount);
    }

    function addNewInformation(string memory _inventoryNumber, string memory _newInformation) external onlyOwner {
        require(workIdByTitle[_inventoryNumber] > 0, "Work does not exist");

        uint256 workId = workIdByTitle[_inventoryNumber];
        string memory currentInformation = works[workId].status;
        string memory updatedInformation = string(abi.encodePacked(currentInformation, " \u2710 ", _newInformation));
        works[workId].status = updatedInformation;
        latestUpdateTitle = _inventoryNumber;
        emit InformationAdded(_inventoryNumber, updatedInformation, workId);
    }

    function updateImageUrl(string memory _inventoryNumber, string memory _newImageUrl) external onlyOwner {
        require(workIdByTitle[_inventoryNumber] > 0, "Work does not exist");
        
        uint256 workId = workIdByTitle[_inventoryNumber];
        works[workId].imageUrl = _newImageUrl;
        latestUpdateTitle = _inventoryNumber;
        emit ImageUrlUpdated(_inventoryNumber, _newImageUrl, workId);
    }

    function deleteStatus(string memory _inventoryNumber) external onlyOwner {
        require(workIdByTitle[_inventoryNumber] > 0, "Work does not exist");

        uint256 workId = workIdByTitle[_inventoryNumber];
        works[workId].status = "";
        emit StatusDeleted(_inventoryNumber, workId);
    }

    function removeWork(string memory _inventoryNumber) external onlyOwner {
        require(workIdByTitle[_inventoryNumber] > 0, "Work does not exist");

        uint256 workId = workIdByTitle[_inventoryNumber];
        delete works[workId];
        delete workIdByTitle[_inventoryNumber];
        emit WorkRemoved(_inventoryNumber);
    }

    function latestUpdate() external view returns (string memory) {
        return latestUpdateTitle;
    }

    function allInventoryNumber_Titles() external view returns (string memory) {
        string memory titleInventoryNumbers;
        for (uint256 i = 1; i <= workCount; i++) {
            titleInventoryNumbers = string(abi.encodePacked(
                titleInventoryNumbers,
                works[i].inventoryNumber,
                "(",
                works[i].title_en,
                "), "
            ));
        }
        return titleInventoryNumbers;
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

    // Trim the result array if needed
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