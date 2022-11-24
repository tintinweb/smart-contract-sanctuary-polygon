/**
 *Submitted for verification at polygonscan.com on 2022-11-22
*/

/**
 *Submitted for verification at FtmScan.com on 2022-11-21
*/

/*  
 * LitBitLottery
 * 
 * Written by: MrGreenCrypto
 * Co-Founder of CodeCraftrs.com
 * 
 * SPDX-License-Identifier: None
 */
pragma solidity 0.8.17;

interface ICCVRF {
    function requestRandomness(uint256 requestID, uint256 howManyNumbers) external payable;
}

interface IStaking {
    function totalStakedInPool1(address) external view returns(uint256);
    function totalStakedInPool2(address) external view returns(uint256);
    function totalStakedInPool3(address) external view returns(uint256);
    function totalStakedInPool4(address) external view returns(uint256);
    function totalStakedInPool5(address) external view returns(uint256);
    function totalStakedInPool6(address) external view returns(uint256);
}

library EnumerableSet {
    struct Set {bytes32[] _values;mapping(bytes32 => uint256) _indexes;}

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {return false;}
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];
        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];
                set._values[toDeleteIndex] = lastValue;
                set._indexes[lastValue] = valueIndex;
            }
            set._values.pop();
            delete set._indexes[value];
            return true;
        } else {return false;}
    }

    function _contains(Set storage set, bytes32 value) private view returns (bool) {return set._indexes[value] != 0;}
    function _length(Set storage set) private view returns (uint256) {return set._values.length;}
    function _at(Set storage set, uint256 index) private view returns (bytes32) {return set._values[index];}
    function _values(Set storage set) private view returns (bytes32[] memory) {return set._values;}

    // AddressSet
    struct AddressSet {Set _inner;}
    function add(AddressSet storage set, address value) internal returns (bool) {return _add(set._inner, bytes32(uint256(uint160(value))));}
    function remove(AddressSet storage set, address value) internal returns (bool) {return _remove(set._inner, bytes32(uint256(uint160(value))));}
    function contains(AddressSet storage set, address value) internal view returns (bool) {return _contains(set._inner, bytes32(uint256(uint160(value))));}
    function length(AddressSet storage set) internal view returns (uint256) {return _length(set._inner);}
    function at(AddressSet storage set, uint256 index) internal view returns (address) {return address(uint160(uint256(_at(set._inner, index))));}
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;
        assembly {result := store}
        return result;
    }
    
    // UintSet
    struct UintSet {Set _inner;}
    function add(UintSet storage set, uint256 value) internal returns (bool) {return _add(set._inner, bytes32(value));}
    function remove(UintSet storage set, uint256 value) internal returns (bool) {return _remove(set._inner, bytes32(value));}
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {return _contains(set._inner, bytes32(value));}
    function length(UintSet storage set) internal view returns (uint256) {return _length(set._inner);}
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {return uint256(_at(set._inner, index));}
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;
        assembly {result := store}
        return result;
    }
}

contract LitBitLottery {
    using EnumerableSet for EnumerableSet.AddressSet;
    uint256 maxTickets = 40;
    uint256 arrayLength = maxTickets + 1;
    mapping(address => bool) public entered;
    mapping(address => uint256) public tickets;
    uint256 totalTickets;
    
    address public constant CEO = 0x78051f622c502801fdECc56d544cDa87065Acb76;

    IStaking public stakingContract = IStaking(0x644229fb8dB1a4397cEFf38bb9F3F27858705B4B);
    uint256 freeTicketPermillePool1 = 150;
    uint256 freeTicketPermillePool2 = 70;
    uint256 freeTicketPermillePool3 = 33;
    uint256 freeTicketPermillePool4 = 15;
    uint256 freeTicketPermillePool5 = 0;
    uint256 freeTicketPermillePool6 = 0;


    uint256 tokensRequiredPerTicket = 2500 * 10**9;

    EnumerableSet.AddressSet[] private players;
    address[] public winners;

    uint256 requestID;
    
    mapping(address => bool) public isAdmin;

    event PlayerRegistered(address player);

    modifier onlyCEO(){
        require (isAdmin[msg.sender], "Only admins can do that");
        _;
    }

    constructor() {
        while(players.length < arrayLength) players.push();
        isAdmin[CEO] = true;
    }

    receive() external payable {}

    function drawSomeWinners(uint256 winnersToDraw) external payable onlyCEO{
        ICCVRF(0xC0de0aB6E25cc34FB26dE4617313ca559f78C0dE).requestRandomness{value: msg.value}(requestID, winnersToDraw);
        requestID++;
    }

    function supplyRandomness(uint256, uint256[] memory randomNumbers) external {
        if(randomNumbers.length == 1) chooseRandomWinner(randomNumbers[0]);
        else chooseMultipleRandomWinners(randomNumbers);
    }

    function listOfWinners() public view returns(address[] memory) {
        return winners;
    }

    function addPlayer(address player, uint256 ticketsOfPlayer) internal returns(bool) {
        if(!players[ticketsOfPlayer].add(player)) return false;
        entered[player] = true;
        tickets[player] = ticketsOfPlayer;
        totalTickets += ticketsOfPlayer;
        return true;
    }

    function deletePlayer(address playerToBeDeleted) internal returns(bool) {
        if(!players[tickets[playerToBeDeleted]].remove(playerToBeDeleted)) return false;
        totalTickets -= tickets[playerToBeDeleted];
        tickets[playerToBeDeleted] = 0;
        entered[playerToBeDeleted] = false;
        return true;
    }

    function updateTickets(address player, uint256 newTickets) internal {
        if(newTickets > maxTickets) newTickets = maxTickets;
        if(!entered[player]) addPlayer(player, newTickets);
        uint256 playerTickets = tickets[player];
        if(playerTickets >= newTickets) return; 
        players[playerTickets].remove(player);
        players[newTickets].add(player);
        tickets[player] = newTickets;
        totalTickets = totalTickets + newTickets - playerTickets;
    }

    function updateTicketsFromServer(address player, uint256 ticketsTotal) external onlyCEO {
        updateTickets(player, ticketsTotal);
    }

    function registerForLottery() external {
        uint256 ticketsOfPlayer = calculateTickets(msg.sender);
        if(entered[msg.sender] && ticketsOfPlayer <= tickets[msg.sender]) return;
        updateTickets(msg.sender, ticketsOfPlayer);
        emit PlayerRegistered(msg.sender);
    }

    function calculateTickets(address player) internal view returns(uint256) {
        uint256 ticketsOfPlayer = 0;
        uint256 calculationToken = 0;

        uint256 pool1 = stakingContract.totalStakedInPool1(player);
        uint256 pool2 = stakingContract.totalStakedInPool2(player);
        uint256 pool3 = stakingContract.totalStakedInPool3(player);
        uint256 pool4 = stakingContract.totalStakedInPool4(player);
        uint256 pool5 = stakingContract.totalStakedInPool5(player);
        uint256 pool6 = stakingContract.totalStakedInPool6(player);

        calculationToken += pool1 * (1000 + freeTicketPermillePool1) / 1000;
        calculationToken += pool2 * (1000 + freeTicketPermillePool2) / 1000;
        calculationToken += pool3 * (1000 + freeTicketPermillePool3) / 1000;
        calculationToken += pool4 * (1000 + freeTicketPermillePool4) / 1000;
        calculationToken += pool5 * (1000 + freeTicketPermillePool5) / 1000;
        calculationToken += pool6 * (1000 + freeTicketPermillePool6) / 1000;

        ticketsOfPlayer = calculationToken / tokensRequiredPerTicket;
        return ticketsOfPlayer;
    }


    struct Player{
        address wallet;
        uint256 tickets;
        uint256 position;
    }

    function getAllData() external view returns(Player[] memory){
        uint256 totalPlayers;

        for(uint256 i = 1; i < arrayLength; i++){
            totalPlayers += players[i].length();
        }
        Player[] memory everyOne = new Player[](totalPlayers);
        uint256 index;

        for(uint256 i = 1; i < arrayLength; i++){
            address[] memory group = players[i].values();
            for(uint256 j = 0; j < group.length; j++){
                everyOne[index].wallet = group[j];
                everyOne[index].tickets = i;
                everyOne[index].position = j;
                index++;
            }
        }
        return everyOne;
    }

    function chooseRandomWinner(uint256 randomNumber) public {
        uint256 winnerLevel = 1;
        randomNumber = randomNumber % (totalTickets + 1); 

        uint256 j = 1;

        while(players[j].length() * j <= randomNumber) {
            randomNumber -= players[j].length() * j;
            winnerLevel++;
            j++;
        }

        address winner = players[winnerLevel].at((randomNumber/winnerLevel)-1);
        winners.push(winner);
        deletePlayer(winner);
    }

    function chooseMultipleRandomWinners(uint256[] memory randomNumbers) public {
        uint256 winnerLevel = 1;

        for(uint256 i = 0; i < randomNumbers.length; i++) {
            uint256 randomNumber = randomNumbers[i] % (totalTickets + 1); 

            uint256 j = 1;

            while(players[j].length() * j <= randomNumber) {
                randomNumber -= players[j].length() * j;
                winnerLevel++;
                j++;
            }

            address winner = players[winnerLevel].at((randomNumber/winnerLevel)-1);
            winners.push(winner);
            deletePlayer(winner);
            winnerLevel = 1;
        }
        
    }
}