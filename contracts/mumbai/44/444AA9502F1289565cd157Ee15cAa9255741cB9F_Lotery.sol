/**
 *Submitted for verification at polygonscan.com on 2022-09-28
*/

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// File: contracts/Lotery.sol



pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Lotery {

    struct Round {
        uint256 roundNumber;
        uint startTimeStamp;
        uint endTimeStamp;
        uint256 totalNumberOfPlayers;
        uint256 totalPrizeAmount;
        uint256 totalTickets;
    }

    struct Winner{
        uint256 roundNumber;
        uint hits;
        address winnerAddress;
        uint256 totalAmount;
        uint256 ticketReceiptId;
        TicketReceipt ticketReceipt;
    }

    struct TicketReceipt {
        uint256 id;
        uint256 roundNumber;
        Round round;
        uint transactionTimeStamp;
        string sequence;
        bytes32 hash;
        address playerAddress;
        uint256 weiValue;
    }
    uint256 roundsCount;
    uint256 ticketReceiptsCount;
    Round private currentRound;
    mapping(uint256 => Round) private rounds;
    mapping(uint256 => TicketReceipt[]) internal ticketReceipts;
    mapping(address => TicketReceipt[]) private playerCurrentRoundTicketReceipts;
    mapping(address => TicketReceipt[]) private playerTicketReceipts;
    mapping(address => Round[]) private playerRounds;
    uint256 private totalSequencesCounter;

    Round[] private roundHistory;
    TicketReceipt[] private ticketReceiptHistory;
    Winner[] private winnersHistory;

    event sequenceSlotNumberSorted(uint256, string);

    function getArrayRandomSequence(uint slots) public view returns(uint256[15] memory){
        uint256 current = 0;
        uint256 tryLoops = 1;
        uint256[15] memory result;
        uint256 tmpNumber = (block.timestamp + block.difficulty) % 100;
        while (current < slots) {
            tryLoops++;
            uint256 tmpN = uint256(keccak256(abi.encodePacked(tmpNumber, current, block.timestamp, block.difficulty, block.number, msg.sender, current, result, tryLoops)));
            tmpNumber = (tmpN > 0 ? tmpN : tmpNumber) %61;              
            result[current] = tmpNumber;
            bool skip = false;
            for(uint i=0;i<current;i++){
                if(current > 0 && current != i && result[i]==tmpNumber){
                    current--;
                    skip = true;
                }
            }

            if(!skip)
                if(tmpNumber > 0){ 
                    current++; 
                }
            
        }
        uint256[15] memory finalresult;
        for(uint i=0;i<15;i++){
            if(result[i] > 0)
                finalresult[i] = result[i];
            else
                finalresult[i] = 999;
        }
        return sort(finalresult);    
    }

    function getStringRandomSequence(uint slots) public view returns(string memory){
        uint256[15] memory result = getArrayRandomSequence(slots);
        string memory resultStr = "";
        for(uint i=0;i<slots;i++)
            resultStr = string(abi.encodePacked(resultStr, (i==0) ? "" : " - ", Strings.toString(result[i])));  
        return resultStr;      
    }

    function mintRoundTicket(address player, uint slots) public payable returns (TicketReceipt memory) {
        require(msg.value >=  1, "Ethers too small");

        string memory seq = getStringRandomSequence(slots);
        bytes32 hash = keccak256(abi.encodePacked(seq));
        
        ticketReceiptsCount += 1;
        TicketReceipt memory result = TicketReceipt(
            ticketReceiptsCount,
            roundsCount,
            currentRound,
            block.timestamp,
            seq,
            hash,
            player,
            msg.value
        );
        
        ticketReceipts[ticketReceiptsCount].push(result); // Member "push" not found or not visible after argument-dependent lookup in struct MyContract.Player memory.
        playerTicketReceipts[player].push(result);
        return result;
    }

    function getMyTickets() public view returns (TicketReceipt[] memory) {
      
        return playerTicketReceipts[msg.sender];
    }

  function quickSort(uint256[15] memory arr, int left, int right) internal pure {
    int i = left;
    int j = right;
    if (i == j) return;
    uint256 pivot = arr[uint(left + (right - left) / 2)];
    while (i <= j) {
        while (arr[uint(i)] < pivot) i++;
        while (pivot < arr[uint(j)]) j--;
        if (i <= j) {
            (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
            i++;
            j--;
        }
    }
    if (left < j)
        quickSort(arr, left, j);
    if (i < right)
        quickSort(arr, i, right);
}

    function sort(uint256[15] memory data) internal pure returns (uint256[15] memory) {
        quickSort(data, int(0), int(data.length - 1));
        return data;
    }
}