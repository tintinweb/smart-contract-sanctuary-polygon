// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import './utils/Address.sol';
import './utils/Context.sol';

interface LotteryContract {
    struct Ticket {
        uint drawId;
        uint id;
        address owner;
        bool winner;
    }

    function requestCounter() external view returns (uint256);
    function getUserTicketsByDraw(uint256 drawId, address user) external view returns (uint256[] memory);
    function autoSpinTimestamp() external view returns (uint256);
    function getJackpot() external view returns (uint256);
    function getJackpotinUSD() external view returns (uint256);
    function getJackpotWinnerByLotteryId(uint256 drawId) external view returns (Ticket memory);
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract LBMultiCall is Ownable {

    struct TicketInfo {
        string identifier;
        uint256 drawId;
        uint256 ticketId;
        uint256 nextSpin;
        string jackpotWinC;
        string jackpotWinU;
    }

    struct PastTicketInfo {
        string identifier;
        uint256 drawId;
        uint256 ticketId;
        bool winner;
    }

    struct LotteryContractInfo {
        address contractAddress;
        string lottery;
        bool isWContract;
    }


address[] public contractsAddresses;
mapping(address => LotteryContractInfo) public contractInfo;

constructor() {
    setContracts();
}

function setContracts() public onlyOwner {
    address[] memory addresses = new address[](8);
    LotteryContractInfo[] memory infos = new LotteryContractInfo[](8);

    addresses[0] = 0xd55e7F6003DF145Ad9821540DD7D15a2dacb041E;
    addresses[1] = 0x754369D7ce4366434e9EBbbf189d900768EFB586;
    addresses[2] = 0x224b73F863A46545A2Afa77B75a76df636FF569a;
    addresses[3] = 0x7aAbEd4c41fec16B0F457d811b9F4feA17C9628C;
    addresses[4] = 0xcC20e2f37f163e34Ca2A1916115a347c9c623aBe;
    addresses[5] = 0xfa77A27B26ac265EF5dCA8f1b7e13563A8796c8E;
    addresses[6] = 0xF686B0380Ddf1c692288fdAD878611Aa69f6839B;
    addresses[7] = 0x64Aaf51A4534c9778AE2F383E14b2f4B3Cb59E91;

    infos[0] = LotteryContractInfo(0xd55e7F6003DF145Ad9821540DD7D15a2dacb041E, "Bitcoin", false);
    infos[1] = LotteryContractInfo(0x754369D7ce4366434e9EBbbf189d900768EFB586, "Bitcoin", true);
    infos[2] = LotteryContractInfo(0x224b73F863A46545A2Afa77B75a76df636FF569a, "Ethereum", false);
    infos[3] = LotteryContractInfo(0x7aAbEd4c41fec16B0F457d811b9F4feA17C9628C, "Ethereum", true);
    infos[4] = LotteryContractInfo(0xcC20e2f37f163e34Ca2A1916115a347c9c623aBe, "Matic", false);
    infos[5] = LotteryContractInfo(0xfa77A27B26ac265EF5dCA8f1b7e13563A8796c8E, "Matic", true);
    infos[6] = LotteryContractInfo(0xF686B0380Ddf1c692288fdAD878611Aa69f6839B, "Krstm", false);
    infos[7] = LotteryContractInfo(0x64Aaf51A4534c9778AE2F383E14b2f4B3Cb59E91, "Krstm", true);

    require(addresses.length == infos.length, "Mismatched array lengths");

    for (uint256 i = 0; i < addresses.length; i++) {
        contractsAddresses.push(addresses[i]);
        contractInfo[addresses[i]] = infos[i];
    }
}


function getTicketInfo(address user) external view returns (TicketInfo[] memory) {
    TicketInfo[] memory tickets = new TicketInfo[](contractsAddresses.length);
    for (uint256 i = 0; i < contractsAddresses.length; i++) {
        address contractAddress = contractsAddresses[i];
        LotteryContractInfo memory info = contractInfo[contractAddress];
        if(!info.isWContract){
            tickets[i].identifier = info.lottery;
            tickets[i].drawId = LotteryContract(contractAddress).requestCounter();
            tickets[i].ticketId = LotteryContract(contractAddress).getUserTicketsByDraw(tickets[i].drawId, user)[0];
            tickets[i].nextSpin = LotteryContract(contractAddress).autoSpinTimestamp();
            tickets[i].jackpotWinC = uintToString(LotteryContract(contractAddress).getJackpot());
            tickets[i].jackpotWinU = uintToString(LotteryContract(contractAddress).getJackpotinUSD());
        }
    }
    return tickets;
}

function getWeeklyTicketInfo(address user) external view returns (TicketInfo[] memory) {
    TicketInfo[] memory tickets = new TicketInfo[](contractsAddresses.length);
    for (uint256 i = 0; i < contractsAddresses.length; i++) {
        address contractAddress = contractsAddresses[i];
        LotteryContractInfo memory info = contractInfo[contractAddress];
        if (info.isWContract) { 
            tickets[i].identifier = info.lottery;
            tickets[i].drawId = LotteryContract(contractAddress).requestCounter();
            tickets[i].ticketId = LotteryContract(contractAddress).getUserTicketsByDraw(tickets[i].drawId, user)[0];
            tickets[i].nextSpin = LotteryContract(contractAddress).autoSpinTimestamp();
            tickets[i].jackpotWinC = uintToString(LotteryContract(contractAddress).getJackpot());
            tickets[i].jackpotWinU = uintToString(LotteryContract(contractAddress).getJackpotinUSD());
        }
    }
    return tickets;
}

function getPastTicketInfo(address user, uint256 _drawId) external view returns (PastTicketInfo[] memory) {
    PastTicketInfo[] memory pastTickets = new PastTicketInfo[](contractsAddresses.length);
    for (uint256 i = 0; i < contractsAddresses.length; i++) {
        address contractAddress = contractsAddresses[i];
        LotteryContractInfo memory info = contractInfo[contractAddress];

        uint256[] memory userTickets = LotteryContract(contractAddress).getUserTicketsByDraw(_drawId, user);
        bool isWinner = LotteryContract(contractAddress).getJackpotWinnerByLotteryId(_drawId).owner == user;

        pastTickets[i].identifier = info.lottery;
        pastTickets[i].drawId = _drawId;
        pastTickets[i].ticketId = userTickets[0];
        pastTickets[i].winner = isWinner;
    }
    return pastTickets;
}

function uintToString(uint256 value) internal pure returns (string memory) {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, 'Address: low-level call failed');
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
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