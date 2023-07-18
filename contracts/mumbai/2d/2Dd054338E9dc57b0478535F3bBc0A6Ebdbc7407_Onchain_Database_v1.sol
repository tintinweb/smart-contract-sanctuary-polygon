// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/*SPDX-License-Identifier: MIT

    shimadamasafumi Onchain_Database_v1 {
        SEQUENCE {
            [RegistrationDate(Unixtime), RegistrationNumber, InventoryNumber, Title_en, Title_ja, Material, Edition, Term&Year, Size, ImageURL, Details, Exhibition, Status, ArtistMemo]
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
            * Display all work information with a single-space search.
        }
    }
*/

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Onchain_Database_v1 is Ownable {

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

    mapping(uint256 => Work) private works;
    mapping(bytes32 => uint256) private workIdByHash;
    uint256 private workCount;
    string private _ArtistInfo;
    string private _sequence;
    string private _howToViewInventoryNumber;
    string private _howToSearch;
    string private _linkUrl;
    string private latestUpdateTitle;
    string private latestUpdateFunction;

    event WorkAdded(uint256 indexed workId, string inventoryNumber, string title_en);
    event StatusAdded(uint256 indexed workId, string inventoryNumber);
    event DetailAdded(uint256 indexed workId, string inventoryNumber);
    event ExhibitionAdded(uint256 indexed workId, string inventoryNumber);
    event MemoAdded(uint256 indexed workId, string inventoryNumber);
    event ImageUrlUpdated(uint256 indexed workId, string inventoryNumber);
    event WorkRemoved(uint256 indexed workId, string inventoryNumber);

    constructor() {
        _sequence = "[RegistrationDate(Unixtime), RegistrationNumber, InventoryNumber, Title_en, Title_ja, Material, Edition, Term&Year, Size, ImageURL, Details, Exhibition, Status, ArtistMemo]";
        _howToViewInventoryNumber = "sm19M1_a1 [sm(shimadamasafumi), 19(Year of public), M(Term:EARLY,MID,LATE), 1(Total number), _a1(Edition a=AP 1~?=ED 1=UNIQUE)]";
        _howToSearch = "Keyword search has a partial match search function and does not distinguish between uppercase and lowercase letters. * Display all work information with a single-space search.";
    }

    function ARTIST_INFO() public view returns (string memory) {
        return _ArtistInfo;
    }

    function updateArtistInformation(string memory newArtistInfo) public onlyOwner {
        _ArtistInfo = newArtistInfo;
    }

    function HOW_TO_ViewSequenceOfWorksInformation() public view returns (string memory) {
        return _sequence;
    }

    function HOW_TO_ViewInventoryNumber() public view returns (string memory) {
        return _howToViewInventoryNumber;
    }

    function HOW_TO_SearchByKeyword() public view returns (string memory) {
        return _howToSearch;
    }

    function ARTIST_LINK_URL() public view returns (string memory) {
        return _linkUrl;
    }

    function updateLinkURL(string memory newLinkUrl) public onlyOwner {
        _linkUrl = newLinkUrl;
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
            status: string(abi.encodePacked(" \u2316 ", _status)),
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
        string memory updatedDetail = string(abi.encodePacked(currentDetail, " ", _newDetail));
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
        string memory updatedExhibition = string(abi.encodePacked(currentExhibition, " ", _newExhibition));
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
        string memory updatedStatus = string(abi.encodePacked(currentStatus, " ", _newStatus));
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
        string memory updatedMemo = string(abi.encodePacked(currentMemo, " ", _newMemo));
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

    function SEARCH_BY_KEYWORD(string memory _keyword) external view returns (Work[] memory) {
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