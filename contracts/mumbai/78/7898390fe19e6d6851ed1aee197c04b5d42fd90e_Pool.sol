// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.9;

import "./ReentrancyGuard.sol";

import {IERC20} from "./IERC20.sol";
import {SafeERC20} from "./SafeERC20.sol";

/**
 * @title   WrappedTokenUserVaultFactory
 * @author  Dolomite
 *
 * @notice  Abstract contract for wrapping tokens via a per-user vault that credits a user's balance within
 *          DolomiteMargin
 */

interface IPool {
    function withdrawal(address receiver, uint256 amount) external;
}

contract Owned {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }
}

contract Pool is IPool, ReentrancyGuard, Owned {
    using SafeERC20 for IERC20;
    address constant MATIC = 0x0000000000000000000000000000000000001010;
    uint256 totalBalance;
    mapping(address => uint256) private _balances;

    function withdrawal(address receiver, uint256 _amount) external onlyOwner nonReentrant {
        totalBalance += _amount;
        payable(receiver).transfer(_amount);
    }

    fallback() external payable {}

    receive() external payable {}
}

contract Userfund is ReentrancyGuard {
    using SafeERC20 for IERC20;
    address constant MATIC = 0x0000000000000000000000000000000000001010;

    struct DepositState {
        uint256 total_amount;
        uint256 total_users;
        uint256 bids;
        uint256 players;
        uint256 odds;
        string account;
        address[] users;
        bool winners_selected;
    }

    mapping(string => address) private poolList;
    mapping(string => DepositState) private depositStates;
    event NewDeposit(address _newPool);
    event CheckDeposit(address depositAddress);

    function createNewDeposit(
        string memory accounthash,
        uint256 bids,
        uint256 players,
        uint256 odds
    ) external returns (address) {
        DepositState memory newDepositeState;
        newDepositeState.total_amount = 0;
        newDepositeState.total_users = 0;
        newDepositeState.bids = bids;
        newDepositeState.players = players;
        newDepositeState.odds = odds;
        newDepositeState.account = "";
        newDepositeState.winners_selected = false;
        depositStates[accounthash] = newDepositeState;
        Pool newPool = new Pool();
        poolList[accounthash] = address(newPool);

        emit NewDeposit(address(newPool));
        return address(newPool);
    }

    function getDepositState(string memory accounthash)
        public
        view
        returns (DepositState memory)
    {
        DepositState storage selectedDepositState = _getDepositState(
            accounthash
        );
        return selectedDepositState;
    }

    function deposit(
        string memory accounthash,
        uint256 bids,
        uint256 players,
        uint256 odds
    ) external nonReentrant payable returns (address) {
        address selectedPool = _getPool(accounthash);
        DepositState storage selectedDepositState = _getDepositState(
            accounthash
        );
        require(
            bids == selectedDepositState.bids &&
                players == selectedDepositState.players &&
                odds == selectedDepositState.odds,
            "Not matched Game"
        );
        require(
            selectedDepositState.total_users != players,
            "The total deposit users exceed"
        );
        address[] storage _user = selectedDepositState.users;
        _user.push(msg.sender);
        selectedDepositState.users = _user;
        selectedDepositState.total_users += 1;
        selectedDepositState.total_amount += bids;
        if (selectedDepositState.total_users != 1) {
            selectedDepositState.account = string(
                abi.encodePacked(selectedDepositState.account, ",")
            );
        }
        selectedDepositState.account = string(
            abi.encodePacked(selectedDepositState.account, toString(msg.sender))
        );
        payable(selectedPool).transfer(msg.value);
        emit CheckDeposit(selectedPool);
        return selectedPool;
    }

    function getAddressAsUint(address _addr) public pure returns (uint256) {
        uint160 addr160 = uint160(_addr); // cast to uint160
        return uint256(addr160); // cast to uint256 if needed
    }

    function toString(address x) public pure returns (string memory) {
        bytes32 value = bytes32(getAddressAsUint(x));
        bytes memory chars = "0123456789abcdef";
        bytes memory str = new bytes(42);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = chars[uint8(value[i + 12] >> 4)];
            str[3 + i * 2] = chars[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }

    function startGame(string memory accounthash, string memory txhash)
        external
    {
        IPool selectedPool = IPool(_getPool(accounthash));
        DepositState storage selectedDepositState = _getDepositState(
            accounthash
        );
        uint256[] memory winner_ids = selectWinners(
            selectedDepositState.account,
            selectedDepositState.players,
            selectedDepositState.odds,
            txhash
        );
        uint256 fee_amount = selectedDepositState.total_amount / 10;
        uint256 reward_amount = ((selectedDepositState.total_amount -
            fee_amount) * selectedDepositState.odds) /
            selectedDepositState.players;
        for (uint256 i = 0; i < winner_ids.length; i++) {
            selectedPool.withdrawal(selectedDepositState.users[winner_ids[i]], reward_amount);
        }
        selectedPool.withdrawal(msg.sender, fee_amount);
        selectedDepositState.winners_selected = true;
    }

    function selectWinners(
        string memory hash,
        uint256 n,
        uint256 m,
        string memory txhash
    ) internal pure returns (uint256[] memory) {  // internal pure function on prod
        bytes32 aHex = sha256(abi.encodePacked(hash, txhash));
        uint256 players = n;
        uint256[] memory winners = new uint256[](n / m);
        uint256[] memory indexArr = new uint256[](2 * n);
        string memory hexString = bytes32ToString(aHex);
        string memory algorithmFlag = getPenultimateLetter(hexString);
        uint256 startCount = 0;
        uint256 isNumber = 0;
        for (uint256 i = 0; i < 2 * n; i++) {
            indexArr[i] = i;
        }
        if (
            toUpper(algorithmFlag)
        ) {
            startCount = 3;
            isNumber++;
        }
        if (
            toLower(algorithmFlag)
        ) {
            startCount = 5;
            isNumber++;
        }
        if (isNumber == 2) {
            startCount = 7;
            isNumber = 0;
        }
        if (startCount == 3) {
            indexArr[players] = indexArr[0];
            indexArr[players + 1] = indexArr[1];
        }
        if (startCount == 5) {
            indexArr[players] = indexArr[0];
            indexArr[players + 1] = indexArr[1];
            indexArr[players + 2] = indexArr[2];
            indexArr[players + 3] = indexArr[3];
        }
        if (startCount == 7) {
            indexArr[players] = indexArr[0];
            indexArr[players + 1] = indexArr[1];
            indexArr[players + 2] = indexArr[2];
            indexArr[players + 3] = indexArr[3];
            indexArr[players + 4] = indexArr[4];
            indexArr[players + 5] = indexArr[5];
        }
        uint256 k = 0;
        for (uint i = startCount - 1; i < players + startCount - 2; i += m) {
            winners[k] = indexArr[i];
            k++;
        }
        return winners;
    }

    function getPenultimateLetter(string memory str)
        public
        pure
        returns (string memory)
    {
        bytes memory bytesStr = bytes(str);
        uint256 length = bytesStr.length;

        require(length >= 2, "String is too short");

        bytes1 secondLastByte = bytesStr[length - 2];
        bytes memory resultBytes = new bytes(1);
        resultBytes[0] = secondLastByte;
        return string(resultBytes);
    }

    function bytes32ToString(bytes32 _bytes32)
        public
        pure
        returns (string memory)
    {
        uint8 i = 0;
        bytes memory bytesArray = new bytes(64);
        for (i = 0; i < 32; i++) {
            uint8 _byte = uint8(_bytes32[i]);
            bytesArray[i * 2] = bytes1ToHex(_byte / 16);
            bytesArray[i * 2 + 1] = bytes1ToHex(_byte % 16);
        }
        return string(bytesArray);
    }

    function bytes1ToHex(uint8 _byte) public pure returns (bytes1) {
        if (_byte < 10) {
            return bytes1(uint8(_byte + 48)); // 48 = '0'
        } else {
            return bytes1(uint8(_byte + 87)); // 87 = 'a' - 10
        }
    }

    function toUpper(string memory s) public pure returns (bool) {
        bytes memory b = bytes(s);
        for (uint256 i = 0; i < b.length; i++) {
            if ((uint8(b[i]) >= 97) && (uint8(b[i]) <= 122)) {
                return false;
            }
        }
        return true;
    }

    function toLower(string memory s) public pure returns (bool) {
        bytes memory b = bytes(s);
        for (uint256 i = 0; i < b.length; i++) {
            if ((uint8(b[i]) >= 65) && (uint8(b[i]) <= 90)) {
                return false;
            }
        }
        return true;
    }

    function _getPool(string memory accounthash)
        internal
        view
        returns (address)
    {
        address selectedPool = poolList[accounthash];
        return selectedPool;
    }

    function _getDepositState(string memory accounthash)
        internal
        view
        returns (DepositState storage)
    {
        DepositState storage depositState = depositStates[accounthash];
        return depositState;
    }
}