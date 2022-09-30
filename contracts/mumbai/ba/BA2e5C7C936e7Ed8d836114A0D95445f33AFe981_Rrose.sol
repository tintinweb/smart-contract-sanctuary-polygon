// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

import "./libraries/Base64.sol";
import "./libraries/Randomness.sol";
import "./libraries/UnorderedKeySetLib.sol";

import "./interfaces/IMasterBox.sol";
import "./interfaces/IMuseum.sol";
import "./interfaces/IMasterPiece.sol";
import "./interfaces/INFTMasterBox.sol";
import "./interfaces/INFTMasterPiece.sol";
import "./interfaces/IEverRoseEvent.sol";
import "./interfaces/IEverRoseTicket.sol";

import "./external/RroseForwarder.sol";
// import "hardhat/console.sol";

contract Rrose is ERC2771Context, AccessControl, ReentrancyGuard {

    using UnorderedKeySetLib for UnorderedKeySetLib.Set;

    UnorderedKeySetLib.Set masterBoxesRaffled;

    bytes32 public constant BUY_BOX_ROLE = keccak256("BUY_BOX_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    address private marketPlaceAddress;
    address private addressMasterPieceContract;
    address private addressMuseumContract;
    address private addressMasterBoxContract;
    address private addressNFTMasterBoxContract;
    address private addressNFTMasterPieceContract;
    address private addressEverRoseEventContract;
    address private addressEverRoseTicketContract;

    bool public saleIsActive = false;
    bool public allowListIsActive = false;

    mapping(address => uint256) private _allowList;

    IMasterPiece    masterPieceContract;
    IMuseum         museumContract;
    IMasterBox      masterBoxContract;
    INFTMasterBox   nftMasterBox;
    INFTMasterPiece nftMasterPiece;
    IEverRoseEvent  everRoseEvent;
    IEverRoseTicket everRoseTicket;

    event boxDrawed(address receiver, uint tokenId, uint256[] masterPiecesWon);
    event museumRaffled(address receiver, uint tokenId, IMuseum.Museum museum);
    event AccountAddedToAllowList(address indexed account, uint256 numAllowedToMint);

    constructor(RroseForwarder forwarder) // Initialize trusted forwarder
    ERC2771Context(address(forwarder)) {
        // SETUP role Hierarchy:
        // DEFAULT_ADMIN_ROLE > BUY_BOX_ROLE || MANAGER_ROLE > no role
        _setRoleAdmin(BUY_BOX_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(MANAGER_ROLE, DEFAULT_ADMIN_ROLE);

        // NOTE: Other DEFAULT_ADMIN's can remove other admins, give this role with great care
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender()); // The creator of the contract is the default admin
        _setupRole(MANAGER_ROLE, _msgSender());
    }

    modifier onlyAdmin() {
        require(isAdmin(_msgSender()), "onlyAdmin");
        _;
    }

    modifier onlyBuyer() {
        require(isBuyer(_msgSender()), "onlyBuyer");
        _;
    }

    modifier onlyManager() {
        require(isManager(_msgSender()), "onlyManager");
        _;
    }

    function _msgSender() internal view override(Context, ERC2771Context) returns (address sender) {
        sender = ERC2771Context._msgSender();
    }

    function _msgData() internal view override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }

    function isAdmin(address account) public virtual view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    function isBuyer(address account) public virtual view returns (bool) {
        return hasRole(BUY_BOX_ROLE, account);
    }

    function isManager(address account) public virtual view returns (bool) {
        return hasRole(MANAGER_ROLE, account);
    }

    // Add a user address as a Buyer Admin
    function addBuyer(address account) public virtual onlyAdmin {
        grantRole(BUY_BOX_ROLE, account);
    }

    function removeBuyer(address account) public virtual onlyAdmin {
        revokeRole(BUY_BOX_ROLE, account);
    }

    // Add a user address as a Manager Admin (add account to Allow List / Activate Sales State
    function addManager(address account) public virtual onlyAdmin {
        grantRole(MANAGER_ROLE, account);
    }

    function removeManager(address account) public virtual onlyAdmin {
        revokeRole(MANAGER_ROLE, account);
    }

    function addAdmin(address account) public virtual onlyAdmin {
        grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    // Remove oneself from the admin role.
    function renounceAdmin() public virtual {
        renounceRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    // Used by a Manager to freeze all sales globally
    function setSaleState(bool newState) public onlyManager {
        saleIsActive = newState;
    }

    function setAllowListIsActive(bool _allowListIsActive) external onlyManager {
        allowListIsActive = _allowListIsActive;
    }

    function addToAllowListByAdmin(address[] calldata addresses, uint256 numAllowedToMint) external onlyManager {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = numAllowedToMint;
            emit AccountAddedToAllowList(addresses[i], numAllowedToMint);
        }
    }

    function numAvailableToMint(address addr) external view returns (uint256) {
        return _allowList[addr];
    }

    function setMarketPlaceAddress(address _marketPlaceAddress) public onlyAdmin {
        marketPlaceAddress = _marketPlaceAddress;
    }

    function setMasterBoxContract(address _addressMasterBoxContract) public onlyAdmin {
        addressMasterBoxContract = _addressMasterBoxContract;
        masterBoxContract = IMasterBox(addressMasterBoxContract);
    }

    function setMuseumContract(address _addressMuseumContract) public onlyAdmin {
        addressMuseumContract = _addressMuseumContract;
        museumContract = IMuseum(addressMuseumContract);
    }

    function setMasterPieceContract(address _addressMasterPieceContract) public onlyAdmin {
        addressMasterPieceContract = _addressMasterPieceContract;
        masterPieceContract = IMasterPiece(addressMasterPieceContract);
    }

    function setNftMasterBox(address _addressNFTMasterBoxContract) public onlyAdmin {
        addressNFTMasterBoxContract = _addressNFTMasterBoxContract;
        nftMasterBox = INFTMasterBox(addressNFTMasterBoxContract);
    }

    function setNFTMasterPieceContract(address _addressNFTMasterPieceContract) public onlyAdmin {
        addressNFTMasterPieceContract = _addressNFTMasterPieceContract;
        nftMasterPiece = INFTMasterPiece(addressNFTMasterPieceContract);
    }

    function setEverRoseEventContract(address _addressEverRoseEventContract) public onlyAdmin {
        addressEverRoseEventContract = _addressEverRoseEventContract;
        everRoseEvent = IEverRoseEvent(addressEverRoseEventContract);
    }

    function setEverRoseTicketContract(address _addressEverRoseTicketContract) public onlyAdmin {
        addressEverRoseTicketContract = _addressEverRoseTicketContract;
        everRoseTicket = IEverRoseTicket(addressEverRoseTicketContract);
    }

    // TODO maybe remove this function
    function getMaxBuyableBox(bytes32 key) external view returns (uint256) {
        return masterBoxContract.get(key).maxPerMint;
    }

    function getRandomMuseum(uint256 seed) private view returns (IMuseum.Museum memory) {
        //uint256 idxRandom = Randomness.RNG(seed, museumContract.count());
        return museumContract.get(museumContract.getAtIndex(Randomness.RNG(seed, museumContract.count())));
    }

    function rafflingMasterBox(uint256 _tokenId) public {
        require(nftMasterBox.exist(_tokenId), "bad tokenId");
        // require((nftMasterBox.ownerOf(_tokenId) == _msgSender() || nftMasterBox.ownerOf(_tokenId) == owner()), "onlyOwner");
        require(nftMasterBox.ownerOf(_tokenId) == _msgSender(), "onlyOwner");
        require(masterBoxesRaffled.exists(keccak256(abi.encodePacked(_tokenId))) == false, "draw twice");
        require(museumContract.countActiveMuseums() > 0, "No Museum");

        IMasterBox.masterBoxStruct memory mbStruct = masterBoxContract.get(nftMasterBox.getToken(_tokenId).masterBox.key);
        require(block.timestamp > mbStruct.rafflingStartDate, "rafflingStartDate");
        require(mbStruct.rafflingEndDate > block.timestamp, "rafflingEndDate");

        masterBoxesRaffled.insert(keccak256(abi.encodePacked(_tokenId)));

        uint256[] memory masterPiecesWon = new uint256[](mbStruct.maxMuseumByRaffling);
        for (uint256 i = 0; i < mbStruct.maxMuseumByRaffling; i++) {
            // 1 get a random Museum with available MasterPieces
            IMuseum.Museum memory museum = getRandomMuseum(i);
            while(museum.status != IMuseum.Status.ACTIVE) {
                museum = getRandomMuseum(i);
            }

            // 2 emit event to log the Museum raffled
            emit museumRaffled(_msgSender(), _tokenId, museum);

            // 3 mint a random MasterPiece according to the raffled Museum
            masterPiecesWon[i] = nftMasterPiece.randomMint(_msgSender(), i, museum.key, _tokenId);
        }
        // 4 get back the NFT MasterBox attributes and add the NFT MasterPiece minted
        nftMasterBox.setMasterPiecesWon(masterPiecesWon, _tokenId);
        nftMasterBox.setStatus(INFTMasterBox.Status.RAFFLED, _tokenId);
        // console.log("NFTMasterBox: %s raffled!", _tokenId);
        emit boxDrawed(_msgSender(), _tokenId, masterPiecesWon);
    }

    /**
     * @dev Throws if sale is not active,
     * user want's to buy more MasterBox than maxPerMint, allowListIsActive and user not in the liste.
     */
    modifier canBuyBox(uint256 _count, bytes32 key) {
        require(saleIsActive, "Sale not active");
        require(_count > 0 && _count <= masterBoxContract.get(key).maxPerMint, "Cannot mint");
        if(allowListIsActive) {
            require(_count <= _allowList[_msgSender()], "Exceeded max to mint");
            _allowList[_msgSender()] -= _count;
        }
        _;
    }

    function buyMasterBox(uint256 _count, bytes32 key) public payable nonReentrant canBuyBox(_count, key) {
        for (uint i = 0; i < _count; i++) {
            nftMasterBox.safeMint{value : msg.value / _count}(_msgSender(), false, key);
        }
    }

    function buyMasterBoxByAdmin(address to, uint256 _count, bytes32 key) public canBuyBox(_count, key) onlyBuyer {
        for (uint i = 0; i < _count; i++) {
            nftMasterBox.safeMint(to, true, key);
        }
    }

    modifier canBuyTicket(uint256 _count, bytes32 key) {
        require(saleIsActive, "Sale not active");
        require(_count > 0 && _count <= everRoseEvent.get(key).maxTicketsPerMint, "maxTicketsPerMint exceeded");
        require(everRoseEvent.get(key).isPublic, "Private event");
        _;
    }

    function buyTicket(uint256 _count, bytes32 key) public payable nonReentrant canBuyTicket(_count, key) {
        for (uint i = 0; i < _count; i++) {
            everRoseTicket.safeMint{value : msg.value / _count}(_msgSender(), false, key);
        }
    }

    function buyTicketByAdmin(address to, uint256 _count, bytes32 key) public onlyBuyer {
        require(_count > 0 && _count <= everRoseEvent.get(key).maxTicketsPerMint, "maxTicketsPerMint exceeded");
        for (uint i = 0; i < _count; i++) {
            everRoseTicket.safeMint(to, true, key);
        }
    }

    function withdraw() public onlyAdmin {
        uint256 balance = address(this).balance;
        require(balance > 0, "No money");
        payable(_msgSender()).transfer(balance);
    }
}

/**
 *Submitted for verification at Etherscan.io on 2021-09-05
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                out,
                and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                out,
                and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                out,
                and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/utils/Strings.sol";

// See: https://xtremetom.medium.com/solidity-random-numbers-f54e1272c7dd
library Randomness {
    function RNG(uint256 seed, uint256 _sizeMax) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, seed))) % _sizeMax;
    }
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library UnorderedKeySetLib {

    struct Set {
        mapping(bytes32 => uint) keyPointers;
        bytes32[] keyList;
    }

    function insert(Set storage self, bytes32 key) internal {
        require(key != 0x0, "UnorderedKeySet(100) - Key cannot be 0x0");
        require(!exists(self, key), "UnorderedKeySet(101) - Key already exists in the set.");
        self.keyList.push(key);
        self.keyPointers[key] = self.keyList.length - 1;
    }

    function remove(Set storage self, bytes32 key) internal {
        require(exists(self, key), "UnorderedKeySet(102) - Key does not exist in the set.");
        bytes32 keyToMove = self.keyList[count(self)-1];
        uint rowToReplace = self.keyPointers[key];
        self.keyPointers[keyToMove] = rowToReplace;
        self.keyList[rowToReplace] = keyToMove;
        delete self.keyPointers[key];
        self.keyList.pop();
    }

    function count(Set storage self) internal view returns(uint) {
        return(self.keyList.length);
    }

    function exists(Set storage self, bytes32 key) internal view returns(bool) {
        if(self.keyList.length == 0) return false;
        return self.keyList[self.keyPointers[key]] == key;
    }

    function keyAtIndex(Set storage self, uint index) internal view returns(bytes32) {
        return self.keyList[index];
    }

    function nukeSet(Set storage self) public {
        delete self.keyList;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface IMasterBox {

    struct masterBoxStruct {
        bytes32 key;
        uint256 creationDate;
        uint256 boxPrice;
        uint256 startSaleDate;
        uint256 endSaleDate;
        uint256 rafflingStartDate;
        uint256 rafflingEndDate;
        uint256 maxSupply;
        uint256 maxPerMint;
        uint256 maxMuseumByRaffling; // /!\ Max is 5 ! More and raffling can cost too much gaz and revert
        uint256 feesBasisPoints;     // Commissions fees in percent * 100 (e.g. 25% is 2500)
        string name;
        string description;
        string uri;
        string artistName;
    }

    event LogNewMasterBox(address sender, bytes32 key, masterBoxStruct masterBox);
    event LogUpdateMasterBox(address sender, bytes32 key, masterBoxStruct masterBox);
    event LogRemMasterBox(address sender, bytes32 key);

    function add(bytes32 key, masterBoxStruct memory masterBox) external;

    function update(bytes32 key, masterBoxStruct memory masterBox) external;

    function remove(bytes32 key) external;

    function get(bytes32 key) external view returns(masterBoxStruct memory masterBox);

    function exist(bytes32 key) external view returns (bool);

    function count() external view returns(uint256);

    function getAtIndex(uint index) external view returns(bytes32 key);

    function all() external view returns (masterBoxStruct[] memory masterBoxes);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface IMuseum {

    enum Status { INACTIVE, ACTIVE }

    struct Museum {
        bytes32 key;
        string name;
        string description;
        string uri;
        Status status;
    }

    struct MasterPieceRelationship {
        bytes32 key;
        bool supplyReached;
    }

    event LogNewMuseum(address sender, bytes32 key, Museum museum);
    event LogUpdateMuseum(address sender, bytes32 key, Museum museum);
    event LogRemMuseum(address sender, bytes32 key);
    event LogAddMasterpieceRelationship(address sender, bytes32 keyMuseum, bytes32 keyMasterPiece);
    event LogUpdatedMasterpieceRelationship(address sender, bytes32 keyMuseum, bytes32 keyMasterPiece, bool supplyReached);
    event LogRemMasterpieceRelationship(address sender, bytes32 keyMuseum, bytes32 keyMasterPiece);
    event LogMuseumStatusChanged(address sender, bytes32 key, Status newStatus);


    function add(bytes32 key, Museum memory museum) external;

    function setNFTMasterPieceContract(address addressNFTMasterPieceContract) external;

    function setMasterPieceContract(address addressMasterPieceContract) external;

    function setStatus(bytes32 key, Status newStatus) external;

    function updateStatus(bytes32 keyMuseum, bytes32 keyMasterPiece) external;

    function update(bytes32 key, Museum memory museum) external;

    function remove(bytes32 key) external;

    function get(bytes32 key) external view returns (Museum memory museum);

    function exist(bytes32 key) external view returns (bool);

    function count() external view returns (uint256);

    function countActiveMuseums() external view returns (uint256);

    function getAtIndex(uint index) external view returns (bytes32 key);

    function all() external view returns (Museum[] memory);

    function addMasterPiece(bytes32 keyMuseum, bytes32 keyMasterPiece) external;

    function removeMasterPiece(bytes32 keyMuseum, bytes32 keyMasterPiece) external;

    function getMasterPieces(bytes32 keyMuseum) external view returns (MasterPieceRelationship[] memory masterPiecesRelationships);

    function getAvailableMasterPieces(bytes32 keyMuseum) external view returns (MasterPieceRelationship[] memory masterPiecesRelationships);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface IMasterPiece {

    struct masterPieceStruct {
        bytes32 key;                // Unique identifier of the masterpiece.
        bytes32 museumKey;          // Unique identifier of the museum
        uint256 maxSupply;          // Max supply of the masterpiece, default to 30001
        uint256 feesBasisPoints;    // Commissions fees in percent * 100 (e.g. 25% is 2500)
        uint256 floorPrice;         // Minimum price in 2nd market in € cents: 15 € is saved as 1500
        string name;                // Titre de l’oeuvre
        string description;         // description de l’oeuvre
        string creationDate;        // date de création de l’oeuvre
        string museumName;          // nom du musée
        string museumId;            // identifiant museal de l’oeuvre
        string museumDate;          // date d’acquisition par le musée
        string museumCollection;    // collection de rattachement de l’oeuvre
        string artistName;          // nom de l’artiste
        string artistNationality;   // nationalité de l’artiste
        string artistBirthDeath;    // date de naissance de l’artiste (year) - date de décès de l’artiste (year)
        string period;              // période de l’oeuvre
        string style;               // style de l’oeuvre (ex. réalisme, expressionism, pointillisme, etc.)
        string category;            // catégorie de l’oeuvre (peinture, sculpture, etc.)
        string uri;                 // TokenUri de la MasterPiece
    }

    event LogNewMasterPiece(address sender, bytes32 key, masterPieceStruct masterPiece);
    event LogUpdateMasterPiece(address sender, bytes32 key, masterPieceStruct masterPiece);
    event LogRemMasterPiece(address sender, bytes32 key);

    function add(bytes32 key, masterPieceStruct memory masterPiece) external;

    function update(bytes32 key, masterPieceStruct memory masterPiece) external;

    function remove(bytes32 key) external;

    function get(bytes32 key) external view returns (masterPieceStruct memory masterPiece);

    function exist(bytes32 key) external view returns (bool);

    function count() external view returns (uint256);

    function getAtIndex(uint index) external view returns (bytes32 key);

    function all() external view returns (masterPieceStruct[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./IMasterBox.sol";

interface INFTMasterBox {

    enum Status { RAFFLED, UNRAFFLED }

    struct nftMasterBoxStruct {
        IMasterBox.masterBoxStruct masterBox;
        uint256 collectionId;
        uint256[] masterPiecesWon;
        Status status;
    }

    event boxMinted(address receiver, uint256 tokenId, uint256 collectionId, bytes32 key);


    function setStatus(Status new_status, uint256 tokenId) external;

    function getPrice(uint256 tokenId) external view returns (uint256);

    function getMasterBoxTemplate(bytes32 key) external view returns (IMasterBox.masterBoxStruct memory masterBox);

    function safeMint(address to, bool isAdmin, bytes32 key) external payable;

    function exist(uint256 _tokenId) external view returns (bool);

    function tokensOfOwner(address _owner) external view returns (uint[] memory);

    function setMasterPiecesWon(uint256[] memory masterPiecesWon, uint256 _tokenId) external;

    function getToken(uint256 _tokenId) external view returns (nftMasterBoxStruct memory nftMasterBox);

    function getMasterBoxCurrentSupply(bytes32 key) external view returns (uint256 supply);

    function ownerOf(uint256 _tokenId) external view returns (address);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./IMasterPiece.sol";

interface INFTMasterPiece {

    enum Status {LISTED, UNLISTED}

    struct nftMasterPieceStruct {
        uint256 boxTokenId;
        uint256 collectionId;
        IMasterPiece.masterPieceStruct masterPiece;
        Status status;
    }

    event masterPieceRaffled(address receiver, uint tokenId, nftMasterPieceStruct nftMasterPiece);
    event MasterPieceMaxSupplyReached(bytes32 key);

    // event FrozenFunds(address target, bool frozen);

    /**
     * onlyOwner functions
     **/
    // function freezeAccount(address target, bool freeze) external;

    function setMarketPlaceAddress(address _marketPlaceAddress) external;

    function setAddressRroseContract(address _addressRroseContract) external;

    function setMuseumContract(address _addressMuseumContract) external;

    function setMasterPieceContract(address _addressMasterPieceContract) external;

    function setStatus(Status new_status, uint256 tokenId) external;

    function tokensOfOwner(address _owner) external view returns (uint[] memory);

    function getToken(uint256 _tokenId) external view returns (nftMasterPieceStruct memory nftMasterPiece);

    function getFloorPriceForToken(uint256 _tokenId) external view returns (uint256);

    function getFeesBasisPointsForToken(uint256 _tokenId) external view returns (uint256);

    function getMasterPieceCurrentSupply(bytes32 key) external view returns (uint256 supply);

    function randomMint(address _toAddress, uint256 seed, bytes32 keyMuseum, uint256 _tokenId) external returns (uint256 newItemId);

    function exist(uint256 _tokenId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface IEverRoseEvent {

    struct everRoseEventStruct {
        bytes32 key;
        uint256 ticketPrice;
        uint256 startSaleDate;
        uint256 endSaleDate;
        uint256 startDate;
        uint256 endDate;
        uint256 maxTickets;
        uint256 maxTicketsPerMint;
        bool isPublic;
        string name;
        string description;
        string location;
        string organizer;
        string uri;
    }

    event LogNewEvent(address sender, bytes32 key, everRoseEventStruct everRoseEvent);
    event LogUpdateEvent(address sender, bytes32 key, everRoseEventStruct everRoseEvent);
    event LogRemEvent(address sender, bytes32 key);

    function add(bytes32 key, everRoseEventStruct memory everRoseEvent) external;

    function update(bytes32 key, everRoseEventStruct memory everRoseEvent) external;

    function remove(bytes32 key) external;

    function get(bytes32 key) external view returns(everRoseEventStruct memory everRoseEvent);

    function exist(bytes32 key) external view returns (bool);

    function count() external view returns(uint256);

    function getAtIndex(uint index) external view returns(bytes32 key);

    function all() external view returns (everRoseEventStruct[] memory everRoseEvents);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./IEverRoseEvent.sol";

interface IEverRoseTicket {

    enum Status { PENDING_CHECK, CHECKED, CANCELLED }

    struct ticketStruct {
        IEverRoseEvent.everRoseEventStruct everRoseEvent;
        Status status;
    }

    event ticketMinted(address receiver, uint ticketId, bytes32 key);


    function setStatus(Status newStatus, uint256 ticketId) external;

    function getPrice(uint256 ticketId) external view returns (uint256);

    function current() external view returns (uint256);

    function getEventTemplate(bytes32 key) external view returns (IEverRoseEvent.everRoseEventStruct memory everRoseEvent);

    function safeMint(address to, bool isAdmin, bytes32 key) external payable;

    function exist(uint256 _ticketId) external view returns (bool);

    function ticketsOfOwner(address _owner) external view returns (uint[] memory);

    function showTicket(uint256 _ticketId) external view returns (ticketStruct memory ticket);

    function getEventCurrentSupply(bytes32 key) external view returns (uint256 supply);

    function ownerOf(uint256 _ticketId) external view returns (address);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (metatx/MinimalForwarder.sol)

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

/**
 * @dev Simple minimal forwarder to be used together with an ERC2771 compatible contract. See {ERC2771Context}.
 */
contract RroseForwarder is EIP712 {
    using ECDSA for bytes32;

    struct ForwardRequest {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        uint256 nonce;
        bytes data;
    }

    bytes32 private constant _TYPEHASH =
    keccak256("ForwardRequest(address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data)");

    mapping(address => uint256) private _nonces;

    constructor() EIP712("RroseForwarder", "0.0.1") {}

    function getNonce(address from) public view returns (uint256) {
        return _nonces[from];
    }

    function verify(ForwardRequest calldata req, bytes calldata signature) public view returns (bool) {
        address signer = _hashTypedDataV4(
            keccak256(abi.encode(_TYPEHASH, req.from, req.to, req.value, req.gas, req.nonce, keccak256(req.data)))
        ).recover(signature);
        return _nonces[req.from] == req.nonce && signer == req.from;
    }

    function execute(ForwardRequest calldata req, bytes calldata signature) public payable returns (bool, bytes memory) {
        require(verify(req, signature), "signature does not match");
        _nonces[req.from] = req.nonce + 1;

        (bool success, bytes memory returndata) = req.to.call{gas : req.gas, value : req.value}(
            abi.encodePacked(req.data, req.from)
        );

        // Validate that the relayer has sent enough gas for the call.
        // See https://ronan.eth.link/blog/ethereum-gas-dangers/
        if (gasleft() <= req.gas / 63) {
            // We explicitly trigger invalid opcode to consume all gas and bubble-up the effects, since
            // neither revert or assert consume all gas since Solidity 0.8.0
            // https://docs.soliditylang.org/en/v0.8.0/control-structures.html#panic-via-assert-and-error-via-require
            assembly {
                invalid()
            }
        }
        return (success, returndata);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}