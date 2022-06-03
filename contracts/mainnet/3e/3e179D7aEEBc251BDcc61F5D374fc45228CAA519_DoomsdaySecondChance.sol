/**
 *Submitted for verification at polygonscan.com on 2022-06-02
*/

// SPDX-License-Identifier: Unlicense

/*
    This is free and unencumbered software released into the public domain.

    Anyone is free to copy, modify, publish, use, compile, sell, or
    distribute this software, either in source code form or as a compiled
    binary, for any purpose, commercial or non-commercial, and by any
    means.

    In jurisdictions that recognize copyright laws, the author or authors
    of this software dedicate any and all copyright interest in the
    software to the public domain. We make this dedication for the benefit
    of the public at large and to the detriment of our heirs and
    successors. We intend this dedication to be an overt act of
    relinquishment in perpetuity of all present and future rights to this
    software under copyright law.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
    OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
    ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
    OTHER DEALINGS IN THE SOFTWARE.

    For more information, please refer to <http://unlicense.org/>
*/

/*

    How to use if you are a bunker owner in the Doomsday NFT game (Season 2)
    - double CHECK you are on the polygon network
    - use WMATIC contract ( 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270 ) to "approve"
      this contract ( 0x3e179D7aEEBc251BDcc61F5D374fc45228CAA519 ) to get a payment for
      not confirming hits on your bunkers. The payment is 60 matic for a missed hit.
    - if you do not want to use this contract anymore call "approve" again on WMATIC
      contract and set approval to 0
    - DO NOT transfer anything to this contract, including WMATIC, MATIC, bunkers


    How it works
    - every time your bunker is vulnerable the bot will check if you are willing to pay
      60 matic in return for not getting a hit confirmed
    - if you are happy to pay the bot will register the possibility of the hit in this contract
    - if your bunker survived the current round without getting a hit confirmed the bot will try
      to get a payment from WMATIC in the next round using the previously registered possibility of
      the hit as an evidence of the entitlement to get a payment


    What if
    Q: you "approved" enough funds but were hit by the bot anyway
    A: there is no guarantee that you will not be hit by the bot or other bots / people

    Q: your bunker is not vulnerable
    A: the bot will not be able to register a possibility of the hit and therefore will not be
       able to claim a payment in the next round

    Q: you were hit by somebody else
    A: the contract will not allow a bot to claim a payment from you in the next round

    Q: you did not approve enough funds to cover all your vulnerable bunkers
    A: some of your bunkers will be hit by the bot, some will be spared in return for getting
       a payment in the next round (provided they were not hit by somebody else)

    Q: you removed the approval to spend funds after the bot registered the possibility of the hit
    A: the bot continuously monitors your ability to pay and if for some reason you are not able
       to pay the bot will hit your vulnerable bunkers

    Q: you evacuated the bunker in the next round before the bot was able to claim a payment
    A: Well done, since you are no longer a bunker owner you will not be charged

    Q: you transferred the bunker in the next round to somebody else before the bot was able to claim a payment
    A: The bot will try to take a payment from the new owner. If the new owner did not approve funds
       on WMATIC contract the new owner will not pay

    Q: The bot did not take a payment in the next round
    A: The contract allows to take the payment in the next round only. If the payment was not taken in the next
       round the bot loses ability to collect this payment. The bunker owner escaped the hit for free

    Q: you are an owner of another bot
    A: you have an incentive to use this contract instead of confirming hits. If you confirm hit you will get
       0.6 matic, however if you do not confirm hit you will get 2 matic for a successful collection of
       the payment on behalf of this contract

    Q: why is flat fee charged instead of a fee proportional to the current damage
    A: proportional fee creates an incentive to hit anyway in the hope of charging a higher fee later

    Q: why 60 matic?
    A: Every time a bunker owner reinforces they lose 15% of the reinforcement payment, only 85% is added
       into the pool. Therefore though losing 60 matic straight away seems high at some point the loss
       to the doomsday contract owner will be higher than the loss to this contract. Consider a scenario
       where the bunker owner wants to have a bunker that can withstand at least one hit. Suppose the current
       damage is 3 and reinforcement is 4. If they do not want to pay to this contract, their bunker will be
       hit and they will have to reinforce again paying (2 ** 4) * 60 = 960 matic, losing 15% * 960 = 144 matic
       to the doomsday contract owner straightaway and getting back the payment (960-144)=816 matic only if
       they win. However if they agree to pay to this contract they will not need to reinforce and will
       lose 60 matic only and still have 900 matic to spend on other bunkers. They do not need to commit funds
       to the game.

*/

pragma solidity ^0.8.4;

interface Doomsday {
    enum Stage {Initial, PreApocalypse, Apocalypse, PostApocalypse}
    function stage() external view returns (Stage);
    function getStructuralData(uint tokenId) external view returns (uint8 reinforcement, uint8 damage, bytes32 lastImpact);
    function ownerOf(uint256 tokenId) external view returns (address);
    function isVulnerable(uint tokenId) external view returns (bool);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function confirmHit(uint tokenId) external;
    function reinforce(uint tokenId) external payable;
}

interface WMATIC {
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address guy, uint wad) external returns (bool);
    function balanceOf(address guy) external view returns (uint);
    function transferFrom(address src, address dst, uint wad) external;
    function withdraw(uint wad) external;
}

struct Damage {
    bool hasValue;
    // the bunker's damage when the bunker was vulnerable
    uint8 damage;
}

contract DoomsdaySecondChance {

    address immutable owner;

    Doomsday constant doomsday = Doomsday(0x2a1BABF79436d8aE047089719116f4EFDfce0E8F);
    WMATIC constant wmatic = WMATIC(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);

    uint constant IMPACT_BLOCK_INTERVAL = 255;

    uint constant INCENTIVE_COST = 60 ether;

    // a small fee to pay for calling collectPaymentForNotHitting
    uint constant CALLER_FEE = 2 ether;

    mapping (uint => mapping (uint => Damage)) public storedDamage;

    event RegisterPossibilityOfHit(uint indexed tokenId, uint indexed eliminationBlock, uint8 indexed damage);
    event CollectPaymentForNotHitting(uint indexed tokenId, uint indexed eliminationBlock, uint8 indexed damage);

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {
        require(msg.sender == address(wmatic), 'not WMATIC');
    }

    function getCurrentEliminationBlock() private view returns (uint) {
        return block.number - (block.number % IMPACT_BLOCK_INTERVAL) + 1;
    }

    function getBunkerDamage(uint tokenId) private view returns (uint8) {
        (/*uint8 reinforcement*/, uint8 damage, /*bytes32 lastImpact*/) = doomsday.getStructuralData(tokenId);
        return damage;
    }

    function registerPossibilityOfHit(uint tokenId) external {
        // prove that bunker was vulnerable when registerPossibilityOfHit was called
        // and it was possible to destroy the bunker (if it was alive) by calling confirmHit
        // note that if the bunker was already destroyed isVulnerable can still return true
        // but in this case it will not be possible to collect the payment since
        // the destroyed bunker does not have an owner
        require(doomsday.stage() == Doomsday.Stage.Apocalypse, 'stage');
        require(doomsday.isVulnerable(tokenId), 'vulnerable');

        // if the call was not reverted yet it means that the caller managed to prove that
        // it is possible to call confirmHit and do some damage to the bunker
        // remember what the damage was
        uint8 damage = getBunkerDamage(tokenId);
        uint eliminationBlock = getCurrentEliminationBlock();
        storedDamage[tokenId][eliminationBlock] = Damage({hasValue: true, damage: damage});

        emit RegisterPossibilityOfHit(tokenId, eliminationBlock, damage);
    }

    function collectPaymentForNotHitting(uint tokenId) external {
        // the caller can collect a payment for not hitting the bunker
        // in the next impact interval only
        uint eliminationBlock = getCurrentEliminationBlock() - IMPACT_BLOCK_INTERVAL;
        Damage storage data = storedDamage[tokenId][eliminationBlock];
        require(data.hasValue, 'not found');
        uint8 previousDamage = data.damage;
        uint8 currentDamage = getBunkerDamage(tokenId);
        // pay only if the bunker has not been damaged
        require(currentDamage == previousDamage, 'damage');

        // the caller can collect a payment for not hitting in the impact interval once only
        // if collectPaymentForNotHitting called again it should revert with 'not found' message
        delete storedDamage[tokenId][eliminationBlock];

        // at this point the caller proved that the bunker was vulnerable in the previous impact interval
        // and the bunker was not hit (i.e. the damage did not change)
        // try to get WMATIC from the token owner
        // if they did not agree to provide a payment too bad for the owner of this contract
        // they missed a chance to hit the bunker and get a small payment

        address tokenOwner = doomsday.ownerOf(tokenId);
        wmatic.transferFrom(tokenOwner, address(this), INCENTIVE_COST);

        if (msg.sender != owner) {
            // if you are a competitor bot you are better off not confirming hits and collecting
            // a fee for calling collectPaymentForNotHitting instead
            // The payment is better, if you call confirmHit you get 0.6 MATIC
            // but if you do not call confirmHit and call collectPaymentForNotHitting you get 2 MATIC
            wmatic.withdraw(CALLER_FEE);
            payable(msg.sender).transfer(CALLER_FEE);
        }

        emit CollectPaymentForNotHitting(tokenId, eliminationBlock, currentDamage);
    }

    // owner can clear a damage data, in case it was not possible to collect a payment
    // and there is a desire to keep everything in the clean state
    function clearPossibilityOfHit(uint tokenId, uint eliminationBlock) external {
        require(msg.sender == owner, 'owner');
        delete storedDamage[tokenId][eliminationBlock];
    }

    // Send payments collected in this contract to the contract owner
    function withdraw() external {
        {
            // withdraw WMATIC if any is available
            uint balance = wmatic.balanceOf(address(this));
            if (balance > 0) {
                wmatic.withdraw(balance);
            }
        }
        {
            // withdraw MATIC
            uint balance = address(this).balance;
            if (balance > 0) {
                payable(owner).transfer(balance);
            }
        }
    }

    // Transfer any bunker stuck in this contract at the discretion of the contract owner
    // This is an escape hatch, should not happen
    function transferBunker(address to, uint tokenId) external {
        require(msg.sender == owner, 'owner');
        doomsday.transferFrom(address(this), to, tokenId);
    }
}