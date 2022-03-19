/**
 *Submitted for verification at polygonscan.com on 2022-03-19
*/

// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.9;


interface IERC721Minimal {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

interface IWool {
    function burn(address from, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
}

library Address {
    function isContract(address account) internal view returns (bool) {

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}


interface IEntropy {
    function random(uint256 seed) external view returns (uint256);
}

contract Entropy is IEntropy {
    address private owner;

    constructor() {
        owner = msg.sender;
    }

    function random(uint256 seed) external view returns (uint256) {
        require(msg.sender == owner, "Must be MintParty contract to call function");
        
        return uint256(keccak256(abi.encodePacked(
            block.timestamp + block.difficulty +
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
            block.gaslimit + 
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
            block.number,
            blockhash(block.number - 4),
            tx.origin,
            blockhash(block.number - 2),
            blockhash(block.number - 3),
            blockhash(block.number - 1),
            seed,
            block.timestamp
        )));
    }
}

contract MintParty {
    IERC721Minimal public woolfPack;
    IWool public woolToken;
    address private tokenPool;
    uint256[] private tokenList;
    mapping(uint256 => bool) private tokens;
    bool public finished;
    bool public started;
    address public owner;
    uint256 public minted;
    uint256 public tokenCount;
    IEntropy private entropy;
    mapping(address => bool) whitelist;

    constructor() {
        owner = msg.sender;
        whitelist[owner] = true;
        woolfPack = IERC721Minimal(0xbDC91993Cc370eeD38e59cD1c68B6d2f88508Ce2);
        woolToken = IWool(0x10b1c123183E191E8e2d5B209323DE51c655e384);
        tokenPool = 0x9fA7fBF037E9A33BfbC2a84dfe8b79402fa2C2EF;
        minted = 0;
        entropy = new Entropy();
    }

    function addTokens(uint256[] memory _tokenids) external {
        require(msg.sender == owner, "Only owner pls!");
        for (uint256 i = 0; i < _tokenids.length; i++) {
            if (tokens[_tokenids[i]] == true) continue;
            tokens[_tokenids[i]] = true;
            tokenList.push(_tokenids[i]);
            tokenCount++;
        }
    }

    function finish() external {
        require(msg.sender == owner, "Only owner pls!");
        finished = true;
    }

    function start() external {
        require(msg.sender == owner, "Only owner pls!");
        started = true;
    }

    function addToWhitelist(address a) external {
        require(msg.sender == owner, "Only owner pls!");
        whitelist[a] = true;
    }

    function removeFromWhitelist(address a) external {
        require(msg.sender == owner, "Only owner pls!");
        whitelist[a] = false;
    }

    function mint(uint256 amount) external {
        require(whitelist[msg.sender] == true || started, "Minting not active");
        require(!finished, "Minting has been closed");
        require(!Address.isContract(msg.sender) && msg.sender == tx.origin, "Only real persons please");
        require(amount > 0, "Print at least 1. It is fun!");
        require(amount <= 10, "Dont't hoard 'em!");
        require(amount <= tokenCount - minted, "Can't print that many, all sold!");
        uint256 woolPrice = amount * 50000 * 10 ** 9;
        require(woolToken.balanceOf(msg.sender) >= woolPrice, "Not enoufh FFWOOL (50k a piece). Buy sum!");
        woolToken.burn(msg.sender, woolPrice);
        for (uint256 i = 0; i < amount; i++) {
            _mintOneRandom(msg.sender);
        }
    }

    function _mintOneRandom(address _to) private {
        uint256 randomness = entropy.random(minted);
        uint256 tokenIndex = randomness % tokenList.length;
        minted++;
        uint256 transferIndex = tokenList[tokenIndex];
        tokenList[tokenIndex] = tokenList[tokenList.length - 1];
        tokens[transferIndex] = false;
        tokenList.pop();
        woolfPack.safeTransferFrom(tokenPool, _to, transferIndex);
    }
}