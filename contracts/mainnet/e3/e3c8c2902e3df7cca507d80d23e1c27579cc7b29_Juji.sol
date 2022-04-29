/**
 *Submitted for verification at polygonscan.com on 2022-04-28
*/

//SPDX-License-Identifier: UNLICENSED

// Juji
// Solidity contract to manage draws
// 4/26/2022 v0.0.1

pragma solidity >=0.8.0 <0.9.0;

contract Juji {

 	using SafeMath for uint256;

    address payable private devWallet;
    address payable private charityWallet;
    address private admin;

    event AdminSet(address indexed oldAdmin, address indexed newAdmin);
    event DevWalletSet(address indexed oldWallet, address indexed newWallet);
    event CharityWalletSet(address indexed oldWallet, address indexed newWallet);

    function setWalletDev(address wallet) public {
        require(msg.sender == admin, "You are not the owner of the contract");
        devWallet = payable(wallet);
        emit DevWalletSet(address(0), devWallet);
    }
    function setWalletCharity(address wallet) public {
        require(msg.sender == admin, "You are not the owner of the contract");
        charityWallet = payable(wallet);
        emit CharityWalletSet(address(0), charityWallet);
    }

    constructor() {
        admin = msg.sender;
        emit AdminSet(address(0), admin);
    }

    // Structure of the draw, tickets and buy process
    Draw public currentDraw;
    DrawPrize public currentDrawPrize;
    Draw[] public draws;
    DrawPrize[] public drawsPrize;
    Ticket[] public tickets;
    uint256 public lastDrawId = 0;
    Winner[] public winners;
    uint256 public seed;
    uint256 constant internal TO_PERCENTUAL = 10000;
    uint256 constant internal TO_BASIS_POINT = 100;
    // uint256 constant internal PRICE_TO_MILLION_POINT = 1000000; Ticket price is 0.000001 (1e12) due to coin like BTC with high price (1000 Gwei or 1000000000000 wei)

    struct Ticket {
        address owner;
        uint256 drawId;
    }

    struct Draw {
        uint256 drawId; // id AUTO GENERATED
        string charity; // charity name
        uint256 create; // create date
        uint256 start; // start date
        uint256 end; // end date
        uint256 ticketMax; // max number of tickets
        uint256 ticketPrice; // price of each ticket
        address coin; // coin used in this draw
        string coinName; // coin name used in this draw
        string status; // (V) Valid, (O)pen, (S)uspend, (C)losed or (Q) Cancelled
    }

    struct DrawPrize {
        uint256 drawId;
        uint256 percentageDev; // % of the total collected to be transfered to the dev wallet
        uint256 percentageCharity; // % of the total collected to be transfered to the charity wallet
        uint256 percentagePrize; // % of the total collected to be transfered to the prize wallet
        uint256 qtyPrizeGold; // How many Gold prizes
        uint256 qtyPrizeSilver; // How many Silver prizes
        uint256 qtyPrizeBronze; // How many Bronze prizes
        uint256 prizeGold; // How much Gold prize
        uint256 prizeSilver; // How much Silver prize
        uint256 prizeBronze; // How much Bronze prize
    }

    struct Winner {
        address winner;
        uint256 drawId;
        string prizeType;
        uint256 prize;
    }

    event TicketPurchased(address indexed buyer, uint256 draw);
    event DrawCreated(uint256 date, Draw currentDraw);
    event DrawStarted(uint256 date);
    event DrawFinished(uint256 date);
    event DrawCurrentDraw(uint256 date, Ticket ticket_, uint256 winner);
    event DrawPrizeCreated(uint256 date, DrawPrize currentDrawPrize);
    event GoldPrizeWinner(address winnerWallet, uint256 prize);
    event SilverPrizeWinner(address winnerWallet, uint256 prize);
    event BronzePrizeWinner(address winnerWallet, uint256 prize);

    // Debug - remove it
    //event randomEvent(uint256 seed, uint256 rnd);

    function createDraw(string memory charity, uint256 ticketMax, uint256 ticketPrice, address coin, string memory coinName) public {
        require(msg.sender == admin, "You are not the owner of the contract");
        require(verifyDrawPrize(), "Total of tickets, ticket prize and prizes should match");
        currentDraw = Draw(lastDrawId + 1, charity, block.timestamp, 0, 0, ticketMax, ticketPrice, coin, coinName, "V");
        draws.push(currentDraw);
        if (lastDrawId == 0) lastDrawId = currentDraw.drawId;
        openDraw();
        emit DrawCreated(block.timestamp, currentDraw);
    }

    function createDrawPrize(uint256 percentageDev, uint256 percentageCharity, uint256 percentagePrize, uint256 qtyPrizeGold, uint256 qtyPrizeSilver, uint256 qtyPrizeBronze, uint256 prizeGold, uint256 prizeSilver, uint256 prizeBronze) public {
        currentDrawPrize = DrawPrize(currentDraw.drawId, percentageDev * TO_BASIS_POINT, percentageCharity * TO_BASIS_POINT, percentagePrize * TO_BASIS_POINT, qtyPrizeGold, qtyPrizeSilver, qtyPrizeBronze, prizeGold, prizeSilver, prizeBronze);
        drawsPrize.push(currentDrawPrize);
        emit DrawPrizeCreated(block.timestamp, currentDrawPrize);
    }

    //function openDraw(uint256 drawId) public { // Future improvement: manage more than 1 draw at the same time
    function openDraw() private {
        require(msg.sender == admin, "You are not the owner of the contract");
        currentDraw.start = block.timestamp;
        currentDraw.status = "O";
        emit DrawStarted(block.timestamp);
    }

    function closeDraw() public {
        require(msg.sender == admin, "You are not the owner of the contract");
        currentDraw.end = block.timestamp;
        currentDraw.status = "C";
        draw();
        lastDrawId = currentDraw.drawId;
        emit DrawFinished(block.timestamp);
    }

    function suspendDraw() public {
        require(msg.sender == admin, "You are not the owner of the contract");
        if (keccak256(abi.encodePacked(currentDraw.status)) == keccak256(abi.encodePacked("S")))
            currentDraw.status = "O";
        else
            currentDraw.status = "S";
    }

    function cancelDraw() internal {
        require(msg.sender == admin, "You are not the owner of the contract");
        // TO DO: Check the tickets sold and refund.
        // TO DO: Look for the drawId and cancel it
        currentDraw.status = "Q";
    }

    function getCurrentDraw() public view returns (Draw memory draw_) {
        draw_ = currentDraw;
    }

    function getCurrentDrawPrize() public view returns (DrawPrize memory drawPrize_) {
        drawPrize_ = currentDrawPrize;
    }

    function getCurrentDrawId() public view returns (uint256 currentDrawId) {
        currentDrawId = lastDrawId;
    }

    function listWinners() public view returns (Winner[] memory) {
        return winners;
    }

    function getTicketsRemaining() public view returns (uint256 remainingTickets) {
        remainingTickets = currentDraw.ticketMax - tickets.length;
    }

    function getTicketsSold() public view returns (uint256 soldTickets) {
        soldTickets = tickets.length;
    }

    // function getMyTickets() public view returns (Ticket[] memory myTickets) {

    //     Ticket[] memory ticketsMem = new Ticket[](tickets.length);
    //     uint count = 0;
    //     for (uint x = 0; x < tickets.length; x++) {
    //         if (tickets[x].owner == msg.sender && tickets[x].drawId == lastDrawId) {
    //             ticketsMem[count] = tickets[x];
    //             count += 1;
    //         }
    //     }

    //     myTickets = new Ticket[](count);
    //     for(uint x = 0; x < count; x++) {
    //         myTickets[x] = ticketsMem[x];
    //     }
    // }

    function getMyTickets() public view returns (uint myTickets) {
        myTickets = 0;
        for (uint x = 0; x < tickets.length; x++) {
            if (tickets[x].owner == msg.sender && tickets[x].drawId == lastDrawId) {
                myTickets += 1;
            }
        }
    }

    function draw() public payable {
        require(msg.sender == admin, "You are not the owner of the contract");
        require(compareStrings(currentDraw.status, "O"), "There is no open draw at this time");
        require(getTicketsSold() == currentDraw.ticketMax, "Not all tickets have been sold.");

        // Draw all the prizes
        drawGoldPrizes();
        drawSilverPrizes();
        drawBronzePrizes();
    }

    function buy(uint qtyTickets) public payable {
        require(qtyTickets > 0, "Quantity of tickets should be bigger than 0");
        require(compareStrings(currentDraw.status, "O"), "There is no open draw at this time");
        require(msg.value == currentDraw.ticketPrice.mul(1000000000000).mul(qtyTickets), "Amount paid does not match the purchase amount (number of ticekts * price)"); // Check the price of the ticket
        require(getTicketsSold() < currentDraw.ticketMax, "There is no tickets left");

        // Transfer dev fee to the wallet
        uint256 devFee = msg.value.mul(currentDrawPrize.percentageDev).div(TO_PERCENTUAL);
        devWallet.transfer(devFee);

        // Transfer charity fee to the wallet
        uint256 charityFee = msg.value.mul(currentDrawPrize.percentageCharity).div(TO_PERCENTUAL);
        charityWallet.transfer(charityFee);

        // Record a ticket bought of the current draw
        for (uint x = 0; x < qtyTickets; x++) {
            tickets.push(Ticket(msg.sender, currentDraw.drawId));
            emit TicketPurchased(msg.sender, currentDraw.drawId);
        }
    }

    function getContractBalance() public view returns(uint256 balance) {
        balance = address(this).balance;
    }

    function getDevContractBalance() public view returns(uint256 balance) {
        balance = devWallet.balance;
    }

    function getCharityContractBalance() public view returns(uint256 balance) {
        balance = charityWallet.balance;
    }

    // Internal Functions
    // TO DO: Change to internal

    function random(uint256 range) public returns(uint256 rnd){
        require(range >= 10, "No random number generated can be less than 10");

        if (seed < 1000) { seed = block.timestamp; }
        rnd = uint256(keccak256(abi.encodePacked(seed++))) % range;
    }

    function drawGoldPrizes() public payable {
        require(msg.sender == admin, "You are not the owner of the contract");
        // TO DO: Same address can't win more than 1 time
        // Create a copy of the tickets list and remove every tickets drew?
        for (uint256 i = 0; i < currentDrawPrize.qtyPrizeGold; i++) {
            uint256 winnerIndex = random(currentDraw.ticketMax);
            address payable winnersGold = payable(tickets[winnerIndex].owner);
            winnersGold.transfer(currentDrawPrize.prizeGold.mul(1000000000000000000));
            winners.push(Winner(tickets[winnerIndex].owner, currentDraw.drawId, "GOLD", currentDrawPrize.prizeGold));
            emit GoldPrizeWinner(tickets[winnerIndex].owner, currentDrawPrize.prizeGold);
            winnerIndex = random(currentDraw.ticketMax);
        }
    }

    function drawSilverPrizes() public payable {
        require(msg.sender == admin, "You are not the owner of the contract");
        for (uint256 i = 0; i < currentDrawPrize.qtyPrizeSilver; i++) {
            uint256 winnerIndex = random(currentDraw.ticketMax);
            address payable winnersSilver = payable(tickets[winnerIndex].owner);
            winnersSilver.transfer(currentDrawPrize.prizeSilver.mul(1000000000000000000));
            winners.push(Winner(tickets[winnerIndex].owner, currentDraw.drawId, "SILVER", currentDrawPrize.prizeSilver));
            emit SilverPrizeWinner(tickets[winnerIndex].owner, currentDrawPrize.prizeSilver);
            winnerIndex = random(currentDraw.ticketMax);
        }
    }

    function drawBronzePrizes() public payable {
        require(msg.sender == admin, "You are not the owner of the contract");
        for (uint256 i = 0; i < currentDrawPrize.qtyPrizeBronze; i++) {
            uint256 winnerIndex = random(currentDraw.ticketMax);
            address payable winnersBronze = payable(tickets[winnerIndex].owner);
            winnersBronze.transfer(currentDrawPrize.prizeBronze.mul(1000000000000000000));
            winners.push(Winner(tickets[winnerIndex].owner, currentDraw.drawId, "BRONZE", currentDrawPrize.prizeBronze));
            emit BronzePrizeWinner(tickets[winnerIndex].owner, currentDrawPrize.prizeBronze);
            winnerIndex = random(currentDraw.ticketMax);
        }
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function verifyDrawPrize() internal view returns (bool) {
        // Check the total of ticket x price x prizes structure: should match
        uint256 totalPrizes = 0;
        totalPrizes += currentDrawPrize.qtyPrizeGold.mul(currentDrawPrize.prizeGold);
        totalPrizes += currentDrawPrize.qtyPrizeSilver.mul(currentDrawPrize.prizeSilver);
        totalPrizes += currentDrawPrize.qtyPrizeBronze.mul(currentDrawPrize.prizeBronze);

        if (totalPrizes != currentDraw.ticketMax.mul(currentDraw.ticketPrice)) return false;

        // Verify if the sum of the % for %dev + %charity + %prize is 100%
        if (currentDrawPrize.percentageDev + currentDrawPrize.percentageCharity + currentDrawPrize.percentagePrize == 10000) return false;

        return true;
    }

    // function getSubstring(string memory str, uint startIndex, uint endIndex) public pure returns (string memory ) {
    //     bytes memory strBytes = bytes(str);
    //     bytes memory result = new bytes(endIndex-startIndex);
    //     for(uint i = startIndex; i < endIndex; i++) {
    //         result[i-startIndex] = strBytes[i];
    //     }
    //     return string(result);
    // }

    // function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
    //     if (_i == 0) {
    //         return "0";
    //     }
    //     uint j = _i;
    //     uint len;
    //     while (j != 0) {
    //         len++;
    //         j /= 10;
    //     }
    //     bytes memory bstr = new bytes(len);
    //     uint k = len;
    //     while (_i != 0) {
    //         k = k-1;
    //         uint8 temp = (48 + uint8(_i - _i / 10 * 10));
    //         bytes1 b1 = bytes1(temp);
    //         bstr[k] = b1;
    //         _i /= 10;
    //     }
    //     return string(bstr);
    // }

    // function utfStringLength(string memory str) internal pure returns (uint length)
    // {
    //     uint i=0;
    //     bytes memory string_rep = bytes(str);

    //     while (i<string_rep.length)
    //     {
    //         if (string_rep[i]>>7==0)
    //             i+=1;
    //         else if (string_rep[i]>>5==0x6)
    //             i+=2;
    //         else if (string_rep[i]>>4==0xE)
    //             i+=3;
    //         else if (string_rep[i]>>3==0x1E)
    //             i+=4;
    //         else
    //             //For safety
    //             i+=1;

    //         length++;
    //     }
    // }

}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
    
     function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}