/**
 *Submitted for verification at polygonscan.com on 2023-04-25
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: Lottery.sol


pragma solidity ^0.8.9;


contract Lottery is Ownable {

    struct DrawStruct {
        uint drawNumber;
        uint ticketCost;
        uint start_at;
        uint stop_at;
        uint16 ticketCount;
        uint16 winningTicketCount;
        uint8 commissionPercent;
        bool isComplete;
    }

    struct TicketStruct {
        address addr;
        uint16 ticketCount;
    }

    mapping(uint => DrawStruct) public drawHistory;
    mapping(uint => TicketStruct[]) public drawWinners;
    mapping(uint16 => TicketStruct) public tickets;

    uint public currentDraw = 0;
    uint16 currentTicket = 0;
    uint16 public countTicket = 0;
    bool public drawClosed = true;


    event DrawIsCreatedEvent(
        uint indexed _drawNumber,
        uint _ticketCost,
        uint _start_at,
        uint _stop_at,
        uint16 _ticketCount,
        uint16 _winningTicketCount,
        uint8 _commissionPercent
    );

    event TicketIsBoughtEvent(
        address indexed addr,
        uint indexed _drawNumber,
        uint16 ticketCount
    );

    event DrawIsStoppedEvent(
        uint indexed _drawNumber,
        uint _stop_at
    );

    event TransferToWinnerEvent(
        uint indexed _drawNumber,
        address indexed winner,
        uint _cost,
        bool success
    );

    function renounceOwnership() public override onlyOwner {
        // do nothing - disable renounceOwnership function
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function createDraw(
        uint _ticketCost,
        uint16 _ticketCount,
        uint16 _winningTicketCount,
        uint8 _commissionPercent,
        uint _stop_in
    ) external onlyOwner {
        require(drawClosed, "Draw is going");
        require(currentDraw == 0 || drawHistory[currentDraw].isComplete, "Cannot create a new draw until the previous one is complete");
        require(_commissionPercent < 50, "Incorrect commission!");
        require(_ticketCount > 1, "Incorrect tickets!");
        require(_winningTicketCount > 0, "Incorrect win tickets!");
        require(_winningTicketCount <= _ticketCount, "Incorrect tickets!");

        currentDraw++;

        drawHistory[currentDraw] = DrawStruct({
            drawNumber: currentDraw,
            ticketCost: _ticketCost,
            ticketCount: _ticketCount,
            winningTicketCount: _winningTicketCount,
            commissionPercent: _commissionPercent,
            isComplete: false,
            start_at: block.timestamp,
            stop_at: block.timestamp + _stop_in
        });

        currentTicket = 0;
        countTicket = 0;
        drawClosed = false;

        emit DrawIsCreatedEvent(
            drawHistory[currentDraw].drawNumber,
            drawHistory[currentDraw].ticketCost,
            drawHistory[currentDraw].start_at,
            drawHistory[currentDraw].stop_at,
            drawHistory[currentDraw].ticketCount,
            drawHistory[currentDraw].winningTicketCount,
            drawHistory[currentDraw].commissionPercent
        );

    }

    function buyTickets() external payable {
        require(msg.sender != address(0), "Invalid address");
        require(msg.sender.code.length == 0, "Invalid address");
        require(!drawClosed, "Draw is not going");
        require(currentDraw > 0 && !drawHistory[currentDraw].isComplete, "Lottery is complete");
        require(msg.value > 0, "Error value");
        require((msg.value % drawHistory[currentDraw].ticketCost) == 0, "Buying an incomplete ticket");
        require(countTicket < drawHistory[currentDraw].ticketCount, "Tickets are over");

        uint betTickets = msg.value / drawHistory[currentDraw].ticketCost;
        require(betTickets + uint(countTicket) <= uint(drawHistory[currentDraw].ticketCount), "Many tickets");

        tickets[currentTicket] = TicketStruct({
            addr: msg.sender,
            ticketCount: uint16(betTickets)
        });

        currentTicket += 1;
        countTicket += uint16(betTickets);

        emit TicketIsBoughtEvent(
            msg.sender,
            currentDraw,
            uint16(betTickets)
        );
    }

    function stopDraw() external onlyOwner {
        drawClosed = true;

        emit DrawIsStoppedEvent(
            drawHistory[currentDraw].drawNumber,
            block.timestamp
        );
    }

    function selectWinners() external onlyOwner {
        require(drawClosed, "Draw is going");
        require(currentDraw > 0 && !drawHistory[currentDraw].isComplete, "Lottery is complete");

        uint16 count_winners = 0;
        if (countTicket <= drawHistory[currentDraw].winningTicketCount) {
            count_winners = countTicket;
        } else {
            count_winners = drawHistory[currentDraw].winningTicketCount;
        }

        uint16[] memory winners = new uint16[](count_winners);

        if (countTicket <= drawHistory[currentDraw].winningTicketCount) {
            for(uint16 i = 0; i < countTicket; i++) {
                winners[i] = i;
            }
        } else {
            winners = getRandom();
        }
        address[] memory _tickets = new address[](countTicket);

        uint16 index = 0;
        for(uint16 i = 0; i < currentTicket; i++) {
            for(uint16 j = 0; j < tickets[i].ticketCount; j++) {
                _tickets[index++] = tickets[i].addr;
            }
        }

        drawHistory[currentDraw].isComplete = true;

        if ( count_winners > 0 ) {
            for(uint16 j = 0; j < winners.length; j++) {
                pushWinner(_tickets[winners[j]]);
            }

            uint winningTicketCount = drawHistory[currentDraw].winningTicketCount;
            if (winningTicketCount > countTicket) {
                winningTicketCount = countTicket;
            }

            uint cost = ((countTicket * drawHistory[currentDraw].ticketCost) * (100 - drawHistory[currentDraw].commissionPercent) / 100) / winningTicketCount;

            for(uint16 i = 0; i < drawWinners[currentDraw].length; i++) {
                uint _cost = drawWinners[currentDraw][i].ticketCount * cost;

                (bool success,) = payable(drawWinners[currentDraw][i].addr).call{value: _cost}("");

                emit TransferToWinnerEvent(
                    drawHistory[currentDraw].drawNumber,
                    drawWinners[currentDraw][i].addr,
                    _cost,
                    success
                );

            }
        }

        payable(owner()).call{value: address(this).balance}("");

    }

    function pushWinner(address _addr) private {
        bool needCreate = true;
        for(uint16 i = 0; i < drawWinners[currentDraw].length; i++) {
            if (drawWinners[currentDraw][i].addr == _addr) {
                drawWinners[currentDraw][i].ticketCount++;
                needCreate = false;
            }
        }
        if (needCreate) {
            drawWinners[currentDraw].push(TicketStruct({
                addr: _addr,
                ticketCount: 1
            }));
        }
    }

    function getRandom() private view returns (uint16[] memory) {

        uint16[] memory shuffledArray = new uint16[](countTicket);
        for (uint16 i = 0; i < countTicket; i++) {
            shuffledArray[i] = i;
        }
        uint16 index = 0;
        for (uint16 i = 0; i < countTicket; i++) {
            address salt = tickets[index++].addr;
            if (salt == address(0)) {
                index = 0;
                salt = tickets[index++].addr;
            }
            uint randomIndex = uint(keccak256(abi.encodePacked(block.timestamp, salt, i))) % (countTicket - i) + i;
            (shuffledArray[i], shuffledArray[randomIndex]) = (shuffledArray[randomIndex], shuffledArray[i]);
        }

        uint16[] memory selected = new uint16[](drawHistory[currentDraw].winningTicketCount);

        for (uint16 i = 0; i < drawHistory[currentDraw].winningTicketCount; i++) {
            selected[i] = shuffledArray[i];
        }

        return selected;
    }

}