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
    function withdrawal(uint256 amount) external;
}

contract Pool is IPool, ReentrancyGuard {
    using SafeERC20 for IERC20;
    address constant MATIC = 0x0000000000000000000000000000000000001010;
    uint256 totalBalance;
    mapping(address => uint256) private _balances;

    function withdrawal(uint256 _amount) external nonReentrant {
        totalBalance += _amount;
        payable(msg.sender).transfer(_amount);
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
    ) external payable returns (address) {
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
        // address from = msg.sender;
        // selectedPool.deposite(from, bids);
    }

    // struct Person {
    //     address acc;
    // }

    // Person[] public people;

    // function addPerson(string memory _name, uint _age) public {
    //     people.push(Person(_name, _age));
    // }

    // address[] news;

    // function testTransferMoney(address to, uint256 _amount) public {
    //     IERC20(MATIC).safeTransferFrom(msg.sender, to, _amount);
    // }

    // function getPeople() public view returns (address[] memory) {
    //     return news;
    // }

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

    // function testDepositMoney(string memory accounthash)
    //     public
    // {
    //     // address selectedPool = _getPool(accounthash);
    //     payable(0x451e6040cCAb1450a3cBc7D0b5EEE3D0446CB7B1).transfer(10000000000000000);
    // }

    function startGame(string memory accounthash, string memory txhash)
        external
    {
        IPool selectedPool = IPool(_getPool(accounthash));
        DepositState storage selectedDepositState = _getDepositState(
            accounthash
        );
        // address from = msg.sender;
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
        // address poolAccount = address(selectedPool);
        for (uint256 i = 0; i < winner_ids.length; i++) {
            selectedPool.withdrawal(reward_amount);
            // selectedPool.withdrawal(9000000000000000);
        }
        selectedPool.withdrawal(fee_amount);
        selectedDepositState.winners_selected = true;
    }

    function selectWinners(
        string memory hash,
        uint256 n,
        uint256 m,
        string memory txhash
    ) internal pure returns (uint256[] memory) {
        bytes32 aHex = sha256(abi.encodePacked(hash, txhash));
        uint256[] memory winners = new uint256[](n / m);
        uint256[] memory indexArr = new uint256[](2 * n);
        uint256 hexLength = aHex.length;
        string memory algorithmFlag = string(
            abi.encodePacked(aHex[hexLength - 3], aHex[hexLength - 2])
        );
        uint256 startCount = 0;
        uint256 isNumber = 0;
        for (uint256 i = 0; i < 2 * n; i++) {
            indexArr[i] = i;
        }
        if (
            keccak256(abi.encodePacked(algorithmFlag)) ==
            keccak256(abi.encodePacked(toUpper(algorithmFlag)))
        ) {
            startCount = 3;
            isNumber++;
        }
        if (
            keccak256(abi.encodePacked(algorithmFlag)) ==
            keccak256(abi.encodePacked(toLower(algorithmFlag)))
        ) {
            startCount = 5;
            isNumber++;
        }
        if (isNumber == 2) {
            startCount = 7;
            isNumber = 0;
        }
        if (startCount == 3) {
            indexArr[n] = indexArr[0];
            indexArr[n + 1] = indexArr[1];
        }
        if (startCount == 5) {
            indexArr[n] = indexArr[0];
            indexArr[n + 1] = indexArr[1];
            indexArr[n + 2] = indexArr[2];
            indexArr[n + 3] = indexArr[3];
        }
        if (startCount == 7) {
            indexArr[n] = indexArr[0];
            indexArr[n + 1] = indexArr[1];
            indexArr[n + 2] = indexArr[2];
            indexArr[n + 3] = indexArr[3];
            indexArr[n + 4] = indexArr[4];
            indexArr[n + 5] = indexArr[5];
        }
        uint256 k = 0;
        for (uint256 i = startCount - 1; i < n + startCount - 2; i += m) {
            winners[k] = indexArr[i];
            k++;
        }
        return winners;
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