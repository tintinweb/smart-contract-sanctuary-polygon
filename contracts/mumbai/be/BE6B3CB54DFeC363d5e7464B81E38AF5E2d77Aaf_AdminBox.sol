// contracts/AdminBox.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/proxy/Initializable.sol";
import "../../submodules/opensea-creatures/contracts/common/meta-transactions/Initializable.sol";

// 第三个版本
// 该版本限制了函数的调用, 因为在这个合约中直接调用函数是没有效果的
// 只会更改这个合约中的数据, 但是有用的数据不存储在这个合约中
// 为了避免错误操作, 限制了函数的调用
contract AdminBox is Initializable {
    uint256 private value;
    address private admin;

    // Emitted when the stored value changes
    event ValueChanged(uint256 newValue);

    function initialize(address _admin) public initializer {
        admin = _admin;
    }

    // Stores a new value in the contract
    function store(uint256 newValue) public {
        require(msg.sender == admin, "AdminBox: not admin");
        value = newValue;
        emit ValueChanged(newValue);
    }

    // Reads the last stored value
    function retrieve() public view returns (uint256) {
        return value;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Initializable {
    bool inited;

    modifier initializer() {
        require(!inited, "already inited");
        _;
        inited = true;
    }
}