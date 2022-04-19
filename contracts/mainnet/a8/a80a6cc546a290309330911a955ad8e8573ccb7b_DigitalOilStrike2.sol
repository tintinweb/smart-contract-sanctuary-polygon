pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "./Ownable.sol";
import "./ERC20.sol";
import "./IDigitalOilStrike1.sol";

contract DigitalOilStrike2 is ERC20, Ownable {

    uint256 public immutable SUPPLY_CAP = 1000000000; // 1B tokens

    mapping (address => bool) public whitelist; // ensure no multi-address abuse
    address[] public claimers;
    mapping (address => bool) private hasClaimed;
    mapping (address => uint) public submittedTickets;
    bool public readyForRaffleEntries = false;
    address[] private raffleParticipants;
    address public raffleWinner;
    uint public totalNumberTickets = 0;

    address private USDC_ADDRESS = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address private DigitalOilStrike1_ADDRESS = 0xD4254a61E589B781Ba2a16a5D1a39B41b2e4D144;

    /**
     * @notice Constructor
     */
    constructor(
    ) ERC20("Digital Oil Coin", "OIL") {
    }

    /**
     * @notice Mint DECISION tokens
     * @param account address to receive tokens
     * @param amount amount to mint
     * @return status true if mint is successful, false if not
     */
    function mint(address account, uint256 amount) internal onlyOwner returns (bool status) {
        if (totalSupply() + amount <= SUPPLY_CAP) {
            _mint(account, amount);
            return true;
        }
        return false;
    }

    function addToWhiteList(address[] memory participants) public onlyOwner {
        for (uint i = 0; i < participants.length; i++) {
            whitelist[participants[i]] = true;
        }
    }

    function claim() public {
        require(whitelist[msg.sender] == true || IDigitalOilStrike1(DigitalOilStrike1_ADDRESS).whitelist(msg.sender) == true, "You aren't authorized to participate");
        require(hasClaimed[msg.sender] == false, "You can't sign up twice");
        claimers.push(msg.sender);
        hasClaimed[msg.sender] = true;
    }

    function numberOfClaimers() public view returns (uint) {
        return claimers.length;
    }

    function distributeTokens() public onlyOwner {
        uint numberClaimers = claimers.length;
        require(numberClaimers > 2, "There must be at least 3 claimers to distribute tokens");
        uint doublePortion = 1500 / numberClaimers; // twice a portion times 1000. divide by 1000 in the end
        uint tokensLeft = SUPPLY_CAP/4;
        for (uint i = 0; i < numberClaimers; i++) {
            address claimer = claimers[i];
            uint amount = doublePortion * tokensLeft / 1000;
            mint(claimer, amount);
            tokensLeft -= amount;
        }
        mint(owner(), SUPPLY_CAP - totalSupply()); // mint the rest to the contract owner to add as liquidity
    }

    function openRaffle() public onlyOwner {
        readyForRaffleEntries = true;
    }

    function submitOil() public {
        require(readyForRaffleEntries, "Raffle isn't open yet");
        uint senderBalance = balanceOf(msg.sender);
        require(senderBalance > 0, "You don't have any OIL to submit into the raffle");
        transfer(address(this), senderBalance);
        submittedTickets[msg.sender] = senderBalance;
        raffleParticipants.push(msg.sender);
        totalNumberTickets += senderBalance;
    }

    function getRaffleParticipants() public view returns (address[] memory) {
        return raffleParticipants;
    }     

    function drawRaffle() public onlyOwner {
        require(readyForRaffleEntries == true, "Raffle hasn't been opened yet");
        require(raffleWinner == address(0), "We already had a winner");
        uint256 numParticipants = raffleParticipants.length;
        // Draw Winner
        uint randomNumber = random(); // random number between 1 and number of raffle tickets
        // Check where random number lies on the number line
        uint start = 0;
        for (uint i = 0; i < numParticipants; i++) {
            uint numberCoins = submittedTickets[raffleParticipants[i]];
            if (start <= randomNumber && randomNumber < start + numberCoins) {
                raffleWinner = raffleParticipants[i];
                break;
            }
            start += numberCoins;
        }
        // Send 250 USDC to winner
        require(raffleWinner != address(0), "A winner wasn't chosen");
        uint256 withdrawableUSDC = IERC20(USDC_ADDRESS).balanceOf(address(this));        
        IERC20(USDC_ADDRESS).transfer(raffleWinner, withdrawableUSDC);
    }

    function random() internal view returns (uint) {
        uint randomnumber = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % totalNumberTickets;
        return randomnumber;
    }

    // In case something goes wrong, mechanism to withdraw USDC from the contract so it doesn't get stuck
    function withdrawUSDC() public onlyOwner {
        uint256 withdrawableUSDC = IERC20(USDC_ADDRESS).balanceOf(address(this));
        require(withdrawableUSDC != 0, "There is no USDC to withdraw");
        IERC20(USDC_ADDRESS).transfer(_msgSender(), withdrawableUSDC);
    }

}