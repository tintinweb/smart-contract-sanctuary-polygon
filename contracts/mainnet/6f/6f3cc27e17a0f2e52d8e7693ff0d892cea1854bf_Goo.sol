/**
 * Gooeys, a fully on-chain game by Dogira Studios
 *
 * https://gooeys.io
 * Telegram: https://t.me/GooeysP2E
 * Twitter: https://twitter.com/GooeysP2E
 * Discord: https://discord.dogira.net
 * Game Guide/GooBook : https://dogira.gitbook.io/goobook/
 *
 * NFT Generation & Launch via Dogira NFT-Kit
 * P2E Game Developed in-house at Dogira Studios
 *
 * The $GOO Token serves as the primary in-game currency for Gooeys,
 * with both earn & spending mechanics made available in-game.
 *
 * Dogira Studios
 * Home: https://Dogira.net
 * Telegram: https://t.me/DogiraToken
 * Staking: https://Dogira.finance
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC20.sol";
import "Ownable.sol";

contract Goo is ERC20, Ownable {

    mapping(address => bool) gameControllers;
    mapping(address => bool) supplyLimitExemptions; //for adding pairs, deployer wallet etc.
    uint public deploymentBlock;
    uint public TWO_MONTHS_BLOCKS = 2225664;

    address public treasury;
    address DEAD = address(0x000000000000000000000000000000000000dEaD);

    uint public mintedWithoutChefCut = 0;
    uint public chefCutThreshold = 100000e9;
    uint public maxSupplyPerWallet = 10000000e9;
    bool public walletSupplyLimitsEnabled = true;

    event GameControllerSet(address _addr, bool _set, uint _block);
    event SupplyExemptWalletSet(address _addr, bool _set, uint _block);
    event WalletSupplyLimitsSet(bool _status, uint _block);
    event TreasuryUpdated(address _treasury);

    constructor(address _treasury) ERC20("Goo", "GOO") {
        supplyLimitExemptions[msg.sender] = true;
        supplyLimitExemptions[_treasury] = true;
        supplyLimitExemptions[DEAD] = true;
        treasury = _treasury;
        _mint(msg.sender, 2000000000e9);
        deploymentBlock = block.number;
    }

    modifier isGameController() {
        if (owner() != msg.sender && gameControllers[msg.sender] == false) {
            revert("Must be owner, or game controller!");
        }
        _;
    }

    modifier walletSupplyLimitCheck(address from, address to, uint amount) {
        if (to != owner() && from != owner()) {
            if (walletSupplyLimitsEnabled && !isWalletSupplyExempt(to)) {
                require(balanceOf(to) + amount <= maxSupplyPerWallet, "Maximum supply on recipient wallet reached");
            }
        }
        _;
    }

    function setGameController(address _addr, bool _set) external onlyOwner {
        gameControllers[_addr] = _set;
        supplyLimitExemptions[_addr] = _set;
        emit GameControllerSet(_addr, _set, block.number);
    }

    function setSupplyLimitExemption(address _addr, bool _set) external onlyOwner {
        supplyLimitExemptions[_addr] = _set;
        emit SupplyExemptWalletSet(_addr, _set, block.number);
    }

    function setWalletSupplyLimits(bool _set) external onlyOwner {
        walletSupplyLimitsEnabled = _set;
        emit WalletSupplyLimitsSet(_set, block.number);
    }

    function isWalletSupplyExempt(address _addr) view public returns (bool) {
        return supplyLimitExemptions[_addr] == true;
    }

    function getDivisionRate() view public returns(uint) {
        uint divider = 1;
        uint blocksSinceDeployment = block.number - deploymentBlock;
        uint divisionPeriods = blocksSinceDeployment / TWO_MONTHS_BLOCKS;
        for (uint i = 0; i < divisionPeriods; i++) {
            divider = divider * 2;
        }
        return divider;
    }

    function updateTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
        emit TreasuryUpdated(_treasury);
    }

    function mint(address to, uint256 amount) external isGameController {
        amount = amount / getDivisionRate();
        _mint(to, amount);
        mintedWithoutChefCut = mintedWithoutChefCut + amount;
        if (to != treasury && mintedWithoutChefCut > chefCutThreshold) {
            _mint(treasury, mintedWithoutChefCut / 20);
            mintedWithoutChefCut = 0;
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public walletSupplyLimitCheck(from, to, amount) override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function transfer(address to, uint256 amount) public
    walletSupplyLimitCheck(msg.sender, to, amount) override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }
}