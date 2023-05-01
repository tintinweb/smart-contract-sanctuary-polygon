/**
 *Submitted for verification at polygonscan.com on 2023-04-30
*/

// Sources flattened with hardhat v2.13.0 https://hardhat.org

// File contracts/did/interfaces/IBeacon.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IDAOBeacon {
    function DAO() external view returns (address);
}

interface IDBBeacon {
    function DB() external view returns (address);
}

interface IEditorBeacon {
    function editor() external view returns (address);
}

interface IBufferBeacon {
    function buffer() external view returns (address);
}

interface IVaultBeacon {
    function vault() external view returns (address);
}

interface IBrandBeacon {
    function brand() external view returns (address);
}

interface IHookBeacon {
    function hook() external view returns (address);
}

interface IMarketBeacon {
    function market() external view returns (address);
}

interface IResolverBeacon {
    function resolver() external view returns (address);
}

interface IFilterBeacon {
    function filter() external view returns (address);
}

interface IValueMiningBeacon {
    function valueMining() external view returns (address);
}


// File contracts/did/platform/AccessControl.sol

// 

pragma solidity ^0.8.9;

abstract contract AccessControl {
    mapping(address => bool) public operators;

    address public beacon;

    event OperatorGranted(address operator, bool granted);

    constructor(address _beacon) {
        beacon = _beacon;
    }

    modifier onlyDAO() {
        require(msg.sender == _DAO(), "Caller is not the DAO");
        _;
    }

    modifier onlyOperator() {
        require(operators[msg.sender], "Caller is not an operator");
        _;
    }

    function _DAO() internal view virtual returns (address) {
        return IDAOBeacon(beacon).DAO();
    }

    function setOperator(address addr, bool granted) external onlyDAO {
        _setOperator(addr, granted);
    }

    function setOperators(address[] calldata addrs, bool granted) external onlyDAO {
        for (uint256 i = 0; i < addrs.length; i++) {
            _setOperator(addrs[i], granted);
        }
    }

    function _setOperator(address addr, bool granted) internal {
        operators[addr] = granted;
        emit OperatorGranted(addr, granted);
    }
}


// File contracts/lib/TransferHelper.sol

// 

pragma solidity ^0.8.9;

library TransferHelper {
    function sendValue(address recipient, uint256 amount) internal {
        address payable payableRecipient = payable(recipient);

        require(address(this).balance >= amount, "Insufficient balance");

        (bool success,) = payableRecipient.call{value: amount}("");
        require(success, "Unable to send value");
    }
}


// File contracts/ecosystem/Vault.sol

// 

pragma solidity ^0.8.9;


contract Vault is AccessControl {
    mapping(uint64 => uint256) public dailyIncome;
    uint256 public historyTotalIncome;

    event Income(address indexed item, uint256 income, uint256 accumulated, uint256 timestamp);
    event Withdraw(address indexed recipient, uint256 amount, uint256 timestamp);

    constructor(address _beacon) AccessControl(_beacon) {}

    function today() internal view returns (uint64) {
        return uint64(block.timestamp / (24 hours));
        // start from 0,1,2,3...
    }

    // Receive Ether and generate a log event
    receive() external payable {
        uint64 date = today();
        dailyIncome[date] += msg.value;
        historyTotalIncome += msg.value;
        emit Income(msg.sender, msg.value, dailyIncome[date], block.timestamp);
    }

    function withdraw(address recipient, uint256 amount) external onlyDAO {
        require(recipient != address(0), "Zero address");
        TransferHelper.sendValue(recipient, amount);
        emit Withdraw(recipient, amount, block.timestamp);
    }
}