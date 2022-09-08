/**
 *Submitted for verification at polygonscan.com on 2022-09-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract DFLottery {
    event LogFunction(uint256);

    address owner;

    struct LotteryItem {
        string _allTickets;
        uint256 winnerCount;
        uint256[] winnerTicketIndices;
        uint256 status;
    }

    mapping(uint256 => LotteryItem) info;

    uint constant TICKET_CHARS = 6;

    constructor(address owner_) {
        owner = owner_;
    }

    function submitTickets0(uint256 lotteryID, string calldata allTickets, uint256 theWinnerCount) private {
        uint256[] memory theWinnerTicketIndices = new uint256[](theWinnerCount);
        info[lotteryID] = LotteryItem({_allTickets: allTickets, winnerCount: theWinnerCount, winnerTicketIndices: theWinnerTicketIndices, status: 1});
    }

    function submitTickets(uint256 lotteryID, string calldata allTickets, uint256 theWinnerCount) public {
        require(msg.sender == owner);
        require(theWinnerCount > 0);
        require(lotteryID > 0);
        uint len = bytes(allTickets).length;
        require(len > theWinnerCount * TICKET_CHARS);
        require(len % TICKET_CHARS == 0);
        LotteryItem memory item = info[lotteryID];
        require(item.status == 0);

        submitTickets0(lotteryID, allTickets, theWinnerCount);
    }

    function spin0(uint256 lotteryID, uint256 timestampNanoSec, uint256 theWinnerCount, uint256 theTicketsCount) private {
        uint256 i = 0;
        for (uint256 done = 0; done < theWinnerCount && i < 10; i++) {
            uint256 winnerIndex = uint256(keccak256(abi.encodePacked("|+_)(", timestampNanoSec + i * 73, "[email protected]#$%"))) % theTicketsCount;
            int256 idx = indexOf(info[lotteryID].winnerTicketIndices, done, winnerIndex);
            if (idx == -1) {
                info[lotteryID].winnerTicketIndices[done] = winnerIndex;
                done++;
            }
        }
        info[lotteryID].status = 2;
    }

    function spin(uint256 lotteryID, uint256 timestampNanoSec) public {
        require(msg.sender == owner);
        require(lotteryID > 0);
        require(timestampNanoSec > 0);

        LotteryItem memory item = info[lotteryID];
        require(item.status == 1);

        spin0(lotteryID, timestampNanoSec, item.winnerCount, bytes(item._allTickets).length / TICKET_CHARS);
    }

    function submitTicketsAndSpin(uint256 lotteryID, string calldata allTickets, uint256 theWinnerCount, uint256 timestampNanoSec) public {
        require(msg.sender == owner);
        require(theWinnerCount > 0);
        require(lotteryID > 0);
        uint len = bytes(allTickets).length;
        require(len > theWinnerCount * TICKET_CHARS);
        require(len % TICKET_CHARS == 0);
        LotteryItem memory item = info[lotteryID];
        require(item.status == 0);

        submitTickets0(lotteryID, allTickets, theWinnerCount);
        spin0(lotteryID, timestampNanoSec, theWinnerCount, len / TICKET_CHARS);
    }

    function winnerTickets(uint256 lotteryID) public view returns (string[] memory) {
        if (lotteryID <= 0)
            return new string[](0);

        LotteryItem memory item = info[lotteryID];
        if (item.status < 2)
            return new string[](0);

        string[] memory ret = new string[](item.winnerCount);
        for (uint256 i = 0; i < item.winnerCount; i++) {
            uint256 start = item.winnerTicketIndices[i] * TICKET_CHARS;
            ret[i] = substring(item._allTickets, start, start + TICKET_CHARS);
        }

        return ret;
    }

    function tickets(uint256 lotteryID) public view returns (string[] memory) {
        if (lotteryID <= 0)
            return new string[](0);
        
        LotteryItem memory item = info[lotteryID];
        if (item.status < 1)
            return new string[](0);

        uint len = bytes(item._allTickets).length;
        uint count = len / TICKET_CHARS;
        string[] memory ret = new string[](count);
        for (uint i = 0; i < count; i++) {
            uint256 start = i * TICKET_CHARS;
            ret[i] = substring(item._allTickets, start, start + TICKET_CHARS);
        }

        return ret;
    }

    function indexOf(uint256[] memory arr, uint256 length, uint256 searchFor) private pure returns (int256) {
        for (uint256 i = 0; i < length; i++) {
            if (arr[i] == searchFor) {
                return int256(i);
            }
        }

        return -1;
    }

    function substring(string memory str, uint startIndex, uint endIndex) public pure returns (string memory ) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }
}