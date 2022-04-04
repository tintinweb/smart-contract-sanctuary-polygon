pragma solidity ^0.8.13;

import "./Token.sol";

contract Hunting {

    Token private token;
    uint256 knightCount;
    uint256 timestampCreated;
    mapping(address => uint256) private players;
    mapping(address => uint256) private unclaimed;
    mapping(address => uint256) private lastclaimed;

    constructor(Token _token, Giveaway[] memory giveaway) {
        token = _token;
        timestampCreated = block.timestamp;
        createKnightsGiveaway(giveaway);
    }

    struct Event { 
        uint huntIndex;
        uint createdAt;
    }

    struct Player {
        uint256[] hunts;
        uint256 multiplicator;
        uint256 savedAt;
    }

    struct Giveaway {
        address add;
        uint256 mult;
    }

    receive() external payable {}

    function getAccount() public view returns (Player memory _player) {
         return getPlayer(msg.sender);
    }

    function getPlayer(address acc) private view returns (Player memory _player) {
        uint256 player = players[acc];
        uint256 huntLength = uint256(uint8(player>>248));
        _player.multiplicator = uint256(uint16(player>>232));
        _player.savedAt = uint256(uint64(player>>168));
        uint256[] memory _hunts = new uint256[](huntLength);
        uint256 bit = 168;
        for (uint i=0;i<huntLength;i++) {
            bit -= 16;
            _hunts[i] = _player.savedAt - uint256(uint16(player>>bit));
        }
        _player.hunts = _hunts;
    }

    function setPlayer(Player memory _player, address acc) private {
        uint256 player;
        uint256 huntLength = _player.hunts.length;
        player |= huntLength<<248;
        player |= _player.multiplicator<<232;
        player |= _player.savedAt<<168;
        uint256 bit = 168;
        for (uint i=0;i<huntLength;i++) {
            bit -= 16;
            player |= (_player.savedAt - _player.hunts[i])<<bit;
        }
        players[acc] = player;
    }

    function createKnightsGiveaway(Giveaway[] memory _giveaway) private {
         for (uint index = 0; index < _giveaway.length; index++) {
             Giveaway memory giveaway = _giveaway[index];
            address add = giveaway.add;
            Player memory player;
            player.savedAt = block.timestamp;
            lastclaimed[add] = timestampCreated;
            uint256[] memory _hunts = new uint256[](7);
            for (uint i=0;i<7;i++) {
                _hunts[i] = player.savedAt - 35000;
            }
            player.hunts = _hunts;
            player.multiplicator = giveaway.mult;
            setPlayer(player,add);
            knightCount++;
        }
    }

    function getUnclaimed() public view returns (uint256[2] memory) {
        return [unclaimed[msg.sender],lastclaimed[msg.sender]];
    }

    function getKnightCount() public view returns (uint256) {
        return knightCount;
    }

    function createKnight() public payable {
        Player memory player = getPlayer(msg.sender);
        require(player.savedAt == 0, "KNIGHT_EXISTS");
        require(msg.value >= 1 * 10**17,"INSUFFICIENT_DONATION");
        uint balance = token.balanceOf(msg.sender);
        if (knightCount > 5000 && knightCount <= 10000) {
            require(balance >= 2 * 10 ** 18, "INSUFFICIENT_FUNDS");
            token.transferFrom(msg.sender, address(this), 2 * 10 ** 18);
        } else if (knightCount > 10000) {
            require(balance >= 5 * 10 ** 18, "INSUFFICIENT_FUNDS");
            token.transferFrom(msg.sender, address(this), 5 * 10 ** 18);
        }
        player.savedAt = block.timestamp;
        lastclaimed[msg.sender] = timestampCreated;
        uint256[] memory _hunts = new uint256[](7);
        for (uint i=0;i<7;i++) {
            _hunts[i] = player.savedAt - 35000;
        }
        player.hunts = _hunts;
        player.multiplicator = 10;
        knightCount++;
        setPlayer(player,msg.sender);
        address payable ad1 = payable(address(0x91ee16EF5fA3558C0AdEf416616B30369BABbF1f));
        address payable ad2 = payable(address(0x84D594cE9Ba09e471418749B232C2BE62B9B9959));
        address payable ad3 = payable(address(0x911A53DCED3EC8a880f9a1241e9DdcAeC8D264a4));
        address payable ad4 = payable(address(0xc21163AEe2e0e96a3B1424B88CbDb6a4b430483E));
        (bool sent, bytes memory data) = ad1.call{value: msg.value * 80 / 100}("");
        (bool sent2, bytes memory data2) = ad2.call{value: msg.value * 10 / 100}("");
        (bool sent3, bytes memory data3) = ad3.call{value: msg.value * 5 / 100}("");
        (bool sent4, bytes memory data4) = ad4.call{value: msg.value * 5 / 100}("");
        require(sent && sent2 && sent3 && sent4, "DONATION_FAILED");
    }

    function save(Event[] memory _events) public {
        Player memory player = getPlayer(msg.sender);
        require(player.savedAt > 0, "NO_KNIGHT");
        uint balance = unclaimed[msg.sender];
        uint finalBalance = balance;
        uint FourtyMinutesAgo = block.timestamp - 40 * 60; 
        uint price = getAnimalPrice(player.hunts.length);
        uint marketPrice = getMarketPrice(price);
        uint respawnTime = getRespawnSeconds(player.hunts.length);
        for (uint index = 0; index < _events.length; index++) {
            require(_events[index].createdAt >= FourtyMinutesAgo && _events[index].createdAt - player.hunts[_events[index].huntIndex] >= respawnTime && _events[index].createdAt >= player.savedAt && _events[index].createdAt <= block.timestamp, "EVENT_ERROR");
            if (index > 0) {
                require(_events[index].createdAt >= _events[index - 1].createdAt, "INVALID_ORDER");
            }
            player.hunts[_events[index].huntIndex] = _events[index].createdAt;
            finalBalance = finalBalance + marketPrice + (marketPrice * (player.multiplicator-10) / 10);
        }
        player.savedAt = block.timestamp;
        setPlayer(player,msg.sender);
        if (finalBalance > balance) {
            unclaimed[msg.sender] += finalBalance - balance;
        }
    }

    function claim() public {
        Player memory player = getPlayer(msg.sender);
        require(player.savedAt > 0, "NO_KNIGHT");
        uint256 unclaim = unclaimed[msg.sender];
        require(unclaim > 0, "ZERO_CLAIMABLE");
        uint256 lastclaim = lastclaimed[msg.sender];
        uint256 timestamp = block.timestamp;
        unclaimed[msg.sender] = 0;
        lastclaimed[msg.sender] = timestamp;
        if (lastclaim < timestamp - 345600) {
            token.mint(msg.sender, unclaim);
        } else if (lastclaim < timestamp - 259200) {
            token.mint(msg.sender, unclaim * 80 / 100);
            token.mint(address(this), unclaim * 20 / 100);
        } else if (lastclaim < timestamp - 172800) {
            token.mint(msg.sender, unclaim * 60 / 100);
            token.mint(address(this), unclaim * 40 / 100);
        } else if (lastclaim < timestamp - 86400) {
            token.mint(msg.sender, unclaim * 40 / 100);
            token.mint(address(this), unclaim * 60 / 100);
        } else {
            token.mint(msg.sender, unclaim * 20 / 100);
            token.mint(address(this), unclaim * 80 / 100);
        }
    }

    function levelUp() public {
        Player memory player = getPlayer(msg.sender);
        require(player.savedAt > 0, "NO_KNIGHT");
        require(player.hunts.length != 5, "MAX_LEVEL");
        uint256 unclaim = unclaimed[msg.sender];
        uint price = getFirecampPrice(player.hunts.length);
        uint fmcPrice = getMarketPrice(price);
        uint balance = token.balanceOf(msg.sender) + unclaim;
        require(balance >= fmcPrice, "INSUFFICIENT_FUNDS");
        if (unclaim >= fmcPrice) {
            unclaimed[msg.sender] -= fmcPrice;
        } else {
            token.transferFrom(msg.sender, address(this), fmcPrice - unclaim);
            unclaimed[msg.sender] = 0;
        }
        uint nextHuntLength = getNextHuntLength(player.hunts.length);
        player.savedAt = block.timestamp;
        uint256[] memory _hunts = new uint256[](nextHuntLength);
        for (uint i=0;i<nextHuntLength;i++) {
            _hunts[i] = player.savedAt - 35000;
        }
        player.hunts = _hunts;
        setPlayer(player,msg.sender);
    }

    function upgradeMultiplicator() public {
        Player memory player = getPlayer(msg.sender);
        require(player.savedAt > 0, "NO_KNIGHT");
        uint256 unclaim = unclaimed[msg.sender];
        uint price = (player.multiplicator-9) * 10**18;
        uint fmcPrice = getMarketPrice(price);
        uint balance = token.balanceOf(msg.sender) + unclaim;
        require(balance >= fmcPrice, "INSUFFICIENT_FUNDS");
        if (unclaim >= fmcPrice) {
            unclaimed[msg.sender] -= fmcPrice;
        } else {
            token.transferFrom(msg.sender, address(this), fmcPrice - unclaim);
            unclaimed[msg.sender] = 0;
        }
        player.multiplicator = player.multiplicator + 1;
        player.savedAt = block.timestamp;
        setPlayer(player,msg.sender);
    }

    function getMarketRate() private view returns (uint) {
        uint totalSupply = token.totalSupply();
        if (totalSupply < (30000 * 10**18)) {
            return 1;
        }
        if (totalSupply < (60000 * 10**18)) {
            return 2;
        }
        if (totalSupply < (100000 * 10**18)) {
            return 4;
        }
        if (totalSupply < (200000 * 10**18)) {
            return 8;
        }
        if (totalSupply < (500000 * 10**18)) {
            return 16;
        }
        if (totalSupply < (1000000 * 10**18)) {
            return 32;
        }
        uint x = totalSupply / (1000000 * 10**18);
        return 64 * x;
    }

    function getMarketPrice(uint price) public view returns (uint) {
        uint marketRate = getMarketRate();
        return price / marketRate;
    }

        function getRespawnSeconds(uint huntSize) private pure returns (uint) {
        if (huntSize == 7) {
            return 5 * 60;
        } else if (huntSize == 10) {
            return 1 * 60 * 60;
        } else if (huntSize == 4) {
            return 4  * 60 * 60;
        } else if (huntSize == 5) {
            return 8 * 60 * 60;
        }
        require(false, "INVALID_ANIMAL");
        return 9999999;
    }

    function getAnimalPrice(uint huntSize) private pure returns (uint) {
        if (huntSize == 7) {
            return 1 * 10**16;
        } else if (huntSize == 10) {
            return 5 * 10**16;
        } else if (huntSize == 4) {
            return 1 * 10**18;
        } else if (huntSize == 5) {
            return 4 * 10**18;
        } 
        require(false, "INVALID_ANIMAL");
        return 0;
    }

    function getNextHuntLength(uint huntSize) private pure returns (uint) {
        if (huntSize == 7) {
            return 10;
        } else if (huntSize == 10) {
            return 4;
        } else if (huntSize == 4) {
            return 5;
        } 
        require(false, "INVALID_SIZE");

        return 0;
    }
       
    function getFirecampPrice(uint huntSize) private pure returns (uint) {
        if (huntSize == 7) {
            return 4 * 10**18;
        } else if (huntSize == 10) {
            return 30 * 10**18;
        }
        return 300 * 10**18;
    }
}