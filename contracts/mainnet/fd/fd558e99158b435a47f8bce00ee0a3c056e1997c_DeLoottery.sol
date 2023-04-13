/**
 *Submitted for verification at polygonscan.com on 2023-04-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.0;

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity ^0.8.0;

library SafeMath {
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            // benefit is lost if 'b' is also tested.
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

pragma solidity ^0.8.0;

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
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

    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
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
}

pragma solidity ^0.8.4;

abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

pragma solidity ^0.8.0;

contract DeLoottery is VRFConsumerBaseV2, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    mapping(uint256 => Lottery) public LOTTERY;
    struct Lottery {
        uint256 pot;
        uint256 startTime;
        uint256 endTime;
        uint256 ticket_price;
        uint256[] winners;
        uint256 ticketCount;
        mapping(address => uint256[]) owned_tickets;
    }

    mapping(uint256 => TicketsData[]) public LOTTERYUSERS;
    struct TicketsData {
        address user;
        uint256 id;
    }

    mapping (address => bool) CONTROLLERS;

    uint256 public CURRENT_LOT_ID = 0;
    uint256 public MAX_BUY = 50;
    uint256 public MAX_TICKETS = 10000;
    address public TREASURE = 0xF3Cd381921bB05dD5f26C7eDf4b2906c8BaEf8A7;

    mapping(uint256 => uint256) public randomNumber;
    mapping(uint256 => uint256) public requestIds;
    VRFCoordinatorV2Interface immutable COORDINATOR;
    uint64 immutable Subscription_ID = 716;
    bytes32 immutable KeyHash = 0x6e099d640cde6de9d40ac749b4b594126b0169747122711109c9985d47751f93;
    uint32 constant CALLBACK_GAS_LIMIT = 2500000;
    uint16 constant REQUEST_CONFIRMATIONS = 3;
    uint32 public constant NUM_WORDS = 1;
    uint256 public Current_Lottery_ID;

    event WonDraw(address indexed _Address, uint256 _Lottery_ID, uint256 _Ticket_Number);

    constructor() VRFConsumerBaseV2(0xAE975071Be8F8eE67addBC1A82488F1C24858067) {
        COORDINATOR = VRFCoordinatorV2Interface(0xAE975071Be8F8eE67addBC1A82488F1C24858067);
    }

    // VIEW FUNCTIONS
    function Is_Controller(address _Address) public view returns (bool) {
        return CONTROLLERS[_Address];
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function Get_Winners_By_ID(uint256 lotteryId) public view returns (uint256[] memory) {
        return LOTTERY[lotteryId].winners;
    }

    function Get_All_Tickets_By_ID_Address(uint256 lotteryId, address _address) public view returns (uint256[] memory) {
        Lottery storage L = LOTTERY[lotteryId];
        return L.owned_tickets[_address];
    }

    function Get_Tickets_Sold_By_ID(uint256 _id) public view returns (uint256) {
        Lottery storage L = LOTTERY[_id];
        return L.ticketCount;
    }

    function Get_Ticket_Data(uint256 lotteryId, uint256 _id) public view returns (address) {
        TicketsData[] storage LU = LOTTERYUSERS[lotteryId];
        return LU[_id].user;
    }
    // VIEW FUNCTIONS

    function Create_Lottery(uint256 _startTime, uint256 _endTime, uint256 _ticket_price) external {
        Lottery storage L = LOTTERY[CURRENT_LOT_ID];
        require(Is_Controller(msg.sender), "ONLY_CONTROLLERS_CAN_EXECUTE_THIS");
        CURRENT_LOT_ID++;
        L.startTime = _startTime;
        L.endTime = _endTime;
        L.ticket_price = _ticket_price;
    }

    function Buy_Ticket(uint256 _QTY) public payable {
        Lottery storage L = LOTTERY[CURRENT_LOT_ID];
        TicketsData[] storage LU = LOTTERYUSERS[CURRENT_LOT_ID];
        require(L.startTime > 0, "DRAW_NOT_FOUND");
        require(block.timestamp >= L.startTime, "DRAW_IS_NOT_YET_STARTED");
        require(block.timestamp <= (L.endTime - 4 minutes), "DRAW_IS_FINISHED");
        require((L.owned_tickets[msg.sender].length + _QTY) <= MAX_BUY, "CANNOT_BUY_MORE_TICKETS");
        require((L.ticketCount + _QTY) <= MAX_TICKETS, "NO_MORE_TICKETS_AVAILABLE");
        require(msg.value >= (L.ticket_price * _QTY), "INVALID_ETH");
        require(L.winners.length == 0, "PRIZES_DISTRIBUTED_DRAW_IS_FINISHED");
        for (uint256 i = 0; i < _QTY; i++) {
            L.ticketCount++;
            uint256 randomnumber = uint256(
                keccak256(
                    abi.encodePacked(
                        i,
                        block.prevrandao * block.timestamp,
                        block.timestamp,
                        msg.sender,
                        L.ticketCount
                    )
                )
            ) % 1000000000;
            L.owned_tickets[msg.sender].push(randomnumber);
            LU.push(TicketsData(msg.sender, randomnumber));
        }
        L.pot += msg.value;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomness) internal override {
        require(requestId != 0, "REQUEST_ID_NOT_VALID");
        randomNumber[Current_Lottery_ID] = randomness[0];
        payWinners(Current_Lottery_ID);
    }

    function pickWinners(uint256 lotteryId) external {
        require(Is_Controller(msg.sender), "ONLY_CONTROLLERS_CAN_EXECUTE_THIS");
        require(randomNumber[lotteryId] == 0, "ALREADY_FOUND_RANDOMNESS");
        requestIds[lotteryId] = COORDINATOR.requestRandomWords(
            KeyHash,
            Subscription_ID,
            REQUEST_CONFIRMATIONS,
            CALLBACK_GAS_LIMIT,
            NUM_WORDS
        );
        Current_Lottery_ID = lotteryId;
    }

    function payWinners(uint256 lotteryId) internal {
        uint256 randomNum = randomNumber[lotteryId];
        require(randomNum != 0, "RANDOM_NUMBER_NOT_FOUND");
        Lottery storage L = LOTTERY[lotteryId];
        require(L.winners.length == 0, "PRIZES_DISTRIBUTED");
        uint256 parts = 9;
        uint256 totalUsers = L.ticketCount;
        require(parts > 0 && totalUsers > 0, "PARTS_OR_TOTALUSERS_IS_ZERO");
        for (uint256 i = 0; i < parts; i++) {
            uint256 randomPart = uint256(
                keccak256(
                    abi.encodePacked(
                        i,
                        randomNum,
                        block.prevrandao * block.timestamp,
                        block.timestamp
                    )
                )
            );
            uint256 winner = randomPart % totalUsers;
            uint256 priceToTransfer;
            if (i == 0) {
                priceToTransfer = L.pot.div(100).mul(40);
            } else if (i > 0 && i < 4) {
                priceToTransfer = L.pot.div(100).mul(30).div(3);
            } else if (i > 3 && i < 9) {
                priceToTransfer = L.pot.div(100).mul(20).div(5);
            }
            TicketsData[] storage LU = LOTTERYUSERS[lotteryId];
            uint256 LOTTERY_WINNER_TICKET_ID = LU[winner].id;
            L.winners.push(LOTTERY_WINNER_TICKET_ID);
            require(priceToTransfer > 0, "INVALID_AMOUNT");
            require(getBalance() >= priceToTransfer, "NO_SUFFICIENT_BALANCE_IN_CONTRACT");
            address LOTTERY_WINNER = Get_Ticket_Data(lotteryId, winner);
            payable(LOTTERY_WINNER).transfer(priceToTransfer);
            emit WonDraw(LOTTERY_WINNER, lotteryId, LOTTERY_WINNER_TICKET_ID);
            if(i == 8){
                priceToTransfer = L.pot.div(100).mul(10);
                require(priceToTransfer > 0, "INVALID_AMOUNT");
                require(getBalance() >= priceToTransfer, "NO_SUFFICIENT_BALANCE_IN_CONTRACT");
                payable(TREASURE).transfer(priceToTransfer);
            }
        }
    }

    function Set_Max_Tickets(uint256 _NewTickets) external onlyOwner {
        MAX_TICKETS = _NewTickets;
    }

    function Set_Max_Buy(uint256 _NewMaxBuy) external onlyOwner {
        MAX_BUY = _NewMaxBuy;
    }

    function Set_Treasure_Address(address _NewAddress) external onlyOwner {
        TREASURE = _NewAddress;
    }

    function Add_Controller(address _Address) public onlyOwner {
        CONTROLLERS[_Address] = true;
    }

    function Remove_Controller(address _Address) public onlyOwner {
        CONTROLLERS[_Address] = false;
    }

    function transfer(address payable _to, uint256 _amount) public payable onlyOwner {
        require(_amount > 0, "INVALID_AMOUNT");
        require(getBalance() >= _amount, "NO_SUFFICIENT_BALANCE_IN_CONTRACT");
        _to.transfer(_amount);
    }
}