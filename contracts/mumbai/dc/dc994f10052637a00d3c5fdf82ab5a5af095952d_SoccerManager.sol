/**
 *Submitted for verification at polygonscan.com on 2023-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

// 1 ether = 1000000000000000000 wei

contract SoccerManager {
    using MyUIntArraysLib for uint256[];

    address private owner;
    uint256 private numPlayers;
    mapping(uint256 => Player) private players;
    mapping(address => uint256[]) private agents;
    uint256[] playerIds;

    struct Player {
        uint256 id;
        bool status;
        string name;
        uint256 price;
        string image;
        bool forSale;
        address payable agent;
    }

    event PlayerAdded(
        uint256 playerId,
        string name,
        uint256 price,
        bool forSale
    );
    event PlayerUpdated(
        uint256 playerId,
        bool oldForSaleValue,
        bool newForSaleValue
    );
    event PlayerBought(
        uint256 playerId,
        address oldAgent,
        address newAgent,
        uint256 price
    );

    modifier isOwner() {
        require(owner == msg.sender, "You are not the contract owner");
        _;
    }

    constructor() {
        owner = msg.sender;

        addPreDefinedPlayers();
    }

    function addPreDefinedPlayers() private {
        insertPlayer(
            "WEVERTON",
            1000000000000000000,
            "https://s3.amazonaws.com/sep-bucket-prod/wp-content/uploads/2019/05/02082731/weverton.png",
            payable(msg.sender)
        );
        insertPlayer(
            "FELIPE MELO",
            2000000000000000000,
            "https://s3.amazonaws.com/sep-bucket-prod/wp-content/uploads/2019/08/02080049/felipe-melo.png",
            payable(msg.sender)
        );
        insertPlayer(
            "GUSTAVO GOMEZ",
            3000000000000000000,
            "https://s3.amazonaws.com/sep-bucket-prod/wp-content/uploads/2020/01/02080153/gustavo-gomez.png",
            payable(msg.sender)
        );
    }

    function addPlayer(
        string memory name,
        uint256 price,
        string memory image
    ) public isOwner returns (uint256) {
        require(bytes(name).length > 0, "The argument 'name' cannot be empty");
        require(price > 0, "The argument 'price' must be > 0");

        uint256 id = insertPlayer(name, price, image, payable(msg.sender));

        emit PlayerAdded(id, name, price, true);
        return id;
    }

    function insertPlayer(
        string memory name,
        uint256 price,
        string memory image,
        address payable agent
    ) private returns (uint256) {
        uint256 id = ++numPlayers;
        players[id] = Player(id, true, name, price, image, true, agent);
        playerIds.push(id);
        agents[agent].push(id);
        return id;
    }

    function updatePlayer(uint256 id, bool forSale) public returns (bool) {
        require(
            players[id].status,
            "Player with the informed id doesn't exist"
        );
        require(
            players[id].forSale != forSale,
            "Player forSale status is the same already set"
        );
        require(
            players[id].agent == msg.sender,
            "You are not the agent of the player"
        );

        bool oldForSaleValue = players[id].forSale;
        players[id].forSale = forSale;

        emit PlayerUpdated(id, oldForSaleValue, forSale);
        return true;
    }

    function getPlayer(
        uint256 id
    )
        public
        view
        returns (uint256, string memory, uint256, string memory, bool, address)
    {
        require(
            players[id].status,
            "Player with the informed id doesn't exist"
        );
        Player storage player = players[id];
        return (
            player.id,
            player.name,
            player.price,
            player.image,
            player.forSale,
            player.agent
        );
    }

    function getPlayer2(uint256 id) public view returns (Player memory) {
        require(
            players[id].status,
            "Player with the informed id doesn't exist"
        );
        Player storage player = players[id];
        return player;
    }

    function getPlayersOfAgent() public view returns (uint256[] memory) {
        return agents[msg.sender];
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return playerIds.length;
    }

    function buyPlayer(uint256 id) public payable returns (bool) {
        require(players[id].status, "Player doesn't exist");
        require(players[id].forSale, "Player is not for sale");
        require(
            msg.sender != players[id].agent,
            "You are already the player agent"
        );
        require(msg.value == players[id].price, "Amount sent is incorrect");
        require(
            msg.sender.balance >= players[id].price,
            "You don't have enought ether on your balance"
        );

        address payable fromAgent = players[id].agent;
        players[id].agent = payable(msg.sender); // player has a new agent
        agents[players[id].agent].push(id);
        agents[fromAgent].removeValue(id);

        fromAgent.transfer(players[id].price);

        emit PlayerBought(id, fromAgent, msg.sender, players[id].price);
        return true;
    }
}

library MyUIntArraysLib {
    function removeValue(
        uint256[] storage array,
        uint256 value
    ) internal returns (bool) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == value) {
                array[i] = array[array.length - 1];
                //array.length--;
                return true;
            }
        }
        return false;
    }
}