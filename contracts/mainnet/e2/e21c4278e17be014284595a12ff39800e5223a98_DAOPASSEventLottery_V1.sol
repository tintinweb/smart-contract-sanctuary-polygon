/**
 *Submitted for verification at polygonscan.com on 2023-03-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;


library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }


    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }


    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }


    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(abi.encodePacked("0x", s));
        // return string(s);
    }


    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


interface IERC721 is IERC165 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}


interface IERC721Enumerable is IERC721 {

    function totalSupply() external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    function tokenByIndex(uint256 index) external view returns (uint256);
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}



/**
 * DAOPASS Event Lottery contract V1
 */
contract DAOPASSEventLottery_V1 is Ownable {

    string public name = "DAOPASS Event Lottery V1";

    using Strings for uint256;

    event EventAdded(uint256 indexed eventNo, string eventName, address indexed contractAddress);
    event GiftAdded(uint256 indexed eventNo, uint256 indexed giftNo, string giftName);
    event WinnerDrawed(uint256 indexed eventNo, uint256 giftNo, address indexed winner, uint256 drawedIndex);

    // 이벤트 정보
    struct Event {
        string name;
        address contractAddress;
    }

    // 이벤트 경품 정보
    struct Gift {
        string name;
        uint256 rank;
        uint256 limit;
    }

    // 이벤트 당첨자 정보
    struct Winner {
        uint256 eventNo;
        uint256 giftNo;
        address winnerAddress;
    }

    mapping(uint256 => Event) _eventList; // 이벤트 정보 리스트
    mapping(uint256 => Gift[]) _giftList; // 이벤트 경품 정보 리스트
    mapping(uint256 => Winner[]) _winnerList; // 이벤트 당첨자 정보 리스트


    // 이벤트 번호 => 당첨자 지갑주소 => 당첨 이력 존재여부 mapping
    mapping(uint256 => mapping(address => bool)) private _winners;


    // 이벤트 정보 등록
    function addEvent(uint256 eventNo, string memory eventName, address contractAddress) public onlyOwner {
        _eventList[eventNo] = Event(eventName, contractAddress);
        emit EventAdded(eventNo, eventName, contractAddress);
    }

    // 이벤트 경품 정보 등록
    function addGift(uint256 eventNo, string memory giftName, uint256 rank, uint256 limit) public onlyOwner {
        _giftList[eventNo].push(Gift({
            name: giftName,
            rank: rank,
            limit: limit
        }));
        emit GiftAdded(eventNo, (_giftList[eventNo].length - 1), giftName);
    }

    // 이벤트 당첨자 정보 등록
    function addWinner(uint256 eventNo, uint256 giftNo, address winnerAddress, uint256 drawedIndex) internal {
        _winnerList[eventNo].push(Winner({
            eventNo: eventNo,
            giftNo: giftNo,
            winnerAddress: winnerAddress
        }));
        emit WinnerDrawed(eventNo, giftNo, winnerAddress, drawedIndex);
    }

    // 이벤트 정보 조회
    function getEvent(uint256 eventNo) public view returns (Event memory) {
        return _eventList[eventNo];
    }

    // 이벤트 경품 정보 조회
    function getGift(uint256 eventNo, uint256 giftNo) public view returns (Gift memory) {
        return _giftList[eventNo][giftNo];
    }

    // 이벤트 경품 정보 리스트 조회
    function getGiftList(uint256 eventNo) public view returns (Gift[] memory) {
        return _giftList[eventNo];
    }


    // 이벤트 당첨자 정보 리스트 조회
    function getWinnerList(uint256 eventNo) public view returns (Winner[] memory) {
        return _winnerList[eventNo];
    }


    // 이벤트 당첨자 추첨
    function drawRandomWinnerFromHolder(uint256 eventNo, uint256 giftNo) external onlyOwner {
        require(bytes(_eventList[eventNo].name).length != 0, "Event does not exist.");
        require(bytes(_giftList[eventNo][giftNo].name).length != 0, "Gift does not exist.");

        address contractAddress = _eventList[eventNo].contractAddress;

        IERC721Enumerable nft = IERC721Enumerable(contractAddress);

        uint256 totalSupply = nft.totalSupply();
        require(totalSupply > 0, "No NFTs are minted yet");

        uint256 randomSeed = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp)));

        uint256 drawedIndex = generateRandomNumber(randomSeed, totalSupply);
        address winner = nft.ownerOf(nft.tokenByIndex(drawedIndex));

        uint256 loopCount = 0;
        while (isWinner(eventNo, winner)) {
            loopCount++;
            require(loopCount < 10, string(abi.encodePacked("The number of loops exceeded 10. Last picked index: ", Strings.toString(drawedIndex))));

            drawedIndex = generateRandomNumber(randomSeed, totalSupply);
            winner = nft.ownerOf(nft.tokenByIndex(drawedIndex));
        }

        _winners[eventNo][winner] = true;
        addWinner(eventNo, giftNo, winner, drawedIndex);
    }

    // 랜덤 번호 생성
    function generateRandomNumber(uint256 randomSeed, uint256 range) internal view returns (uint256) {
        uint256 rand = uint256(keccak256(abi.encodePacked(randomSeed, msg.sender)));
        uint256 randomNumber = rand % range;
        return randomNumber;
    }

    // 이벤트 당첨자 여부 확인
    function isWinner(uint256 eventNo, address holderAddress) public view returns (bool) {
        return _winners[eventNo][holderAddress];
    }

}