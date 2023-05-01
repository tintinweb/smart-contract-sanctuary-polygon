// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Player {
    uint256 level;
    uint256 xp;
    uint256 status;
    uint256 strength;
    uint256 health;
    uint256 magic;
    uint256 mana;
    uint256 agility;
    uint256 luck;
    uint256 wisdom;
    uint256 haki;
    uint256 perception;
    uint256 defense;
    string name;
    string uri;
    bool male;
    Slot slot;
}

struct PlayerListing {
    address payable seller;
    uint256 playerId;
    uint256 price;
    uint256 pointer;
}

struct Slot {
    uint256 head;
    uint256 body;
    uint256 leftHand;
    uint256 rightHand;
    uint256 pants;
    uint256 feet;
}

// slots {
//     0: head;
//     1: body;
//     2: lefthand;
//     3: rightHand;
//     4: pants;
//     5: feet;
// }

library ExchangeStorageLib {

    bytes32 constant PLAYER_STORAGE_POSITION = keccak256("player.test.storage.a");
    bytes32 constant EX_STORAGE_POSITION = keccak256("ex.test.storage.a");
    bytes32 constant COIN_STORAGE_POSITION = keccak256("coin.test.storage.a");

    struct PlayerStorage {
        uint256 totalSupply;
        uint256 playerCount;
        mapping(uint256 => address) owners;
        mapping(uint256 => Player) players;
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
        mapping(string => bool) usedNames;
        mapping(address => uint256[]) addressToPlayers;
    }

    struct ExStorage {
        mapping(uint256 => PlayerListing) listingsMap;
        mapping(address => uint256[]) addressToListings;
        uint256[] listingsArray;
    }

    struct CoinStorage {
        mapping(address => uint256) goldBalance;
        mapping(address => uint256) totemBalance;
        mapping(address => uint256) diamondBalance;
    }

    function diamondStoragePlayer() internal pure returns (PlayerStorage storage ds) {
        bytes32 position = PLAYER_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
    function diamondStorageEx() internal pure returns (ExStorage storage ds) {
        bytes32 position = EX_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
    function diamondStorageCoin() internal pure returns (CoinStorage storage ds) {
        bytes32 position = COIN_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function _createListing(uint256 _id, uint256 _price) internal {
        PlayerStorage storage s = diamondStoragePlayer();
        ExStorage storage e = diamondStorageEx();
        require(s.owners[_id] == msg.sender, "Not owner of player"); //ownerOf
        require(s.players[_id].status == 0, "Player is not idle"); //make sure player is idle
        e.listingsMap[_id] = PlayerListing(payable(msg.sender), _id, _price, e.listingsArray.length); //create the listing and map
        e.listingsArray.push(_id); //add new value of the listing array
        uint256 balances = s.balances[msg.sender];
        for (uint256 i; i < balances; i++) {
            if (s.addressToPlayers[msg.sender][i] == _id) {
                delete s.owners[_id];
                s.addressToPlayers[msg.sender][i] = s.addressToPlayers[msg.sender][s.addressToPlayers[msg.sender].length-1];
                s.addressToPlayers[msg.sender].pop();
                break;
            }
        }
        s.balances[msg.sender]--;
    }


    function _purchasePlayer(uint256 _listingId) internal {
        PlayerStorage storage s = diamondStoragePlayer();
        ExStorage storage e = diamondStorageEx();
        CoinStorage storage c = diamondStorageCoin(); 
        require(c.goldBalance[msg.sender] >= e.listingsMap[_listingId].price); //check if buyer has enough value
        s.owners[e.listingsMap[_listingId].playerId] = msg.sender; //transfer ownership
        s.addressToPlayers[msg.sender].push(e.listingsMap[_listingId].playerId); //add id to players array
        c.goldBalance[msg.sender] -= e.listingsMap[_listingId].price; //deduct balance from buys
        c.goldBalance[e.listingsMap[_listingId].seller] += e.listingsMap[_listingId].price; //increase balance from buys
        uint256 rowToDelete = e.listingsMap[_listingId].pointer;
        uint256 keyToMove = e.listingsArray[e.listingsArray.length-1];
        e.listingsArray[rowToDelete] = keyToMove;
        e.listingsMap[keyToMove].pointer = rowToDelete;
        e.listingsArray.pop();
        delete e.listingsMap[_listingId];
        s.balances[msg.sender]++; //increment the balance
    }

    function _getListings(address _address) internal view returns (uint256[] memory) {
        ExStorage storage e = diamondStorageEx();
        return e.addressToListings[_address];
    }

    function _getListing(uint256 _listingId) internal view returns (address payable seller, uint256 playerId, uint256 price) {
        ExStorage storage e = diamondStorageEx();
        PlayerListing memory listing = e.listingsMap[_listingId];
        return (payable(listing.seller), listing.playerId, listing.price);
    }

    function _getAllListings() internal view returns (uint256[] memory) {
        ExStorage storage e = diamondStorageEx();
        return e.listingsArray;
    }


}

contract ExchangeFacet {

    event List(address indexed _from, uint256 indexed _playerId, uint256 _price);
    event Purchase(address indexed _to, uint256 _id);

    function crateListing(uint256 _id, uint256 _price) public {
        ExchangeStorageLib._createListing(_id, _price);
        emit List(msg.sender, _id, _price);
    }

    function purchasePlayer(uint256 _listingId) public {
        ExchangeStorageLib._purchasePlayer(_listingId);
        emit Purchase(msg.sender, _listingId);
    }

    function getListings(address _address) public view returns (uint256[] memory) {
        return ExchangeStorageLib._getListings(_address);
    }

    function getLisitng(uint256 _listingId) public view returns (address payable seller, uint256 playerId, uint256 price) {
        return ExchangeStorageLib._getListing(_listingId);
    }

    function getAllListings() public view returns (uint256[] memory) {
        return ExchangeStorageLib._getAllListings();
    }
 


    //function supportsInterface(bytes4 _interfaceID) external view returns (bool) {}
}