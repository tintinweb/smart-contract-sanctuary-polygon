// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Player {
    uint256 level;
    uint256 xp;
    uint256 status;
    uint256 strength;
    uint256 health;
    uint256 stamina;
    uint256 mana;
    uint256 agility;
    uint256 luck;
    uint256 wisdom;
    uint256 haki;
    uint256 perception;
    string name;
    string uri;
    bool male;
}

struct PlayerListing {
    address payable seller;
    uint256 playerId;
    uint256 price;
}

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
        mapping(uint256 => PlayerListing) listings;
        mapping(address => uint256[]) addressToListiongs;
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

    function _crateListing(uint256 _id, uint256 _price) internal {
        PlayerStorage storage s = diamondStoragePlayer();
        ExStorage storage e = diamondStorageEx();
        require(s.owners[_id] == msg.sender); //ownerOf
        require(s.players[_id].status == 0); //make sure player is idle
        e.listings[_id] = PlayerListing(payable(msg.sender), _id, _price);

        for (uint256 i = 0; i < s.balances[msg.sender]; i++) {
            if (s.addressToPlayers[msg.sender][i] == _id) {
                delete s.addressToPlayers[msg.sender][i];
                break;
            }
        }
        s.balances[msg.sender]--;
    }

    function _purchasePlayer(uint256 _listingId) internal {
        PlayerStorage storage s = diamondStoragePlayer();
        ExStorage storage e = diamondStorageEx();
        CoinStorage storage c = diamondStorageCoin(); 
        require(c.goldBalance[msg.sender] >= e.listings[_listingId].price); //check if buyer has enough value
        s.owners[e.listings[_listingId].playerId] = msg.sender; //transfer ownership
        s.addressToPlayers[msg.sender].push(e.listings[_listingId].playerId); //add id to players array
        c.goldBalance[msg.sender] -= e.listings[_listingId].price; //deduct balance from buys
        c.goldBalance[e.listings[_listingId].seller] += e.listings[_listingId].price; //increase balance from buys
        delete e.listings[_listingId];
        s.balances[msg.sender]++; //increment the balance
    }

    function _getListing(address _address) internal view returns (uint256[] memory) {
        ExStorage storage e = diamondStorageEx();
        return e.addressToListiongs[_address];
    }



}

contract ExchangeFacet {

    event List(address indexed _from, uint256 indexed _playerId, uint256 _price);
    event Purchase(address indexed _to, uint256 _id);

    function crateListing(uint256 _id, uint256 _price) public {
        ExchangeStorageLib._crateListing(_id, _price);
        emit List(msg.sender, _id, _price);
    }

    function purchasePlayer(uint256 _listingId) public {
        ExchangeStorageLib._purchasePlayer(_listingId);
        emit Purchase(msg.sender, _listingId);
    }

    function _getListing(address _address) public view {
        ExchangeStorageLib._getListing(_address);
    }


 


    //function supportsInterface(bytes4 _interfaceID) external view returns (bool) {}
}