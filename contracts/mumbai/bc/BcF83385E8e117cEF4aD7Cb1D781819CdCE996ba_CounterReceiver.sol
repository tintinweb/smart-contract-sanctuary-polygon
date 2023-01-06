// SPDX-License-Identifier: MIT

import "./interfaces/IAMBSender.sol";

pragma solidity 0.8.17;

contract CounterReceiver {
    uint256 public counter;
    bool public boolValue;
    uint256 public uint256Value;
    address public ambAddress;

    event IncrementExecuted(bool boolValue_, uint256 uint256Value_, uint256 counterValue);

    function increment(bool boolValue_, uint256 uint256Value_) external {
        boolValue = boolValue_;
        uint256Value = uint256Value_;

        uint256 counterValue = ++counter;

        emit IncrementExecuted(boolValue_, uint256Value_, counterValue);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IAMBSender {
    function send(address recipient, bytes calldata data) external;
}