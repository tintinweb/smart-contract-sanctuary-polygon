/**
 *Submitted for verification at polygonscan.com on 2021-06-09
*/

pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

/// @title Multicall - Aggregate results from multiple read-only function calls
/// @author Michael Elliot <[email protected]>
/// @author Joshua Levine <[email protected]>
/// @author Nick Johnson <[email protected]>

library BytesUtils {
    function toHexString(bytes memory data) internal pure returns (string memory) {
        bytes memory hexString = new bytes(2 * data.length);

        for (uint256 i = 0; i < data.length; i++) {
            uint256 value = uint8(data[i]);
            uint8 firstDigit = uint8(value / 16);
            uint8 secondDigit = uint8(value % 16);

            hexString[2 * i] = _toHexChar(firstDigit);
            hexString[2 * i + 1] = _toHexChar(secondDigit);
        }

        return string(hexString);
    }

    function _toHexChar(uint8 value) private pure returns (bytes1) {
        if (value < 10) {
            return bytes1(uint8(bytes1('0')) + value);
        } else {
            return bytes1(uint8(bytes1('a')) + (value - 10));
        }
    }
}

contract Multicall {
    using BytesUtils for bytes;

    struct Call {
        address target;
        bytes callData;
    }
    function aggregate(Call[] memory calls) public returns (uint256 blockNumber, bytes[] memory returnData) {
        blockNumber = block.number;
        returnData = new bytes[](calls.length);
        for(uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.call(calls[i].callData);
            require(success, calls[i].callData.toHexString());
            returnData[i] = ret;
        }
    }
    // Helper functions
    function getEthBalance(address addr) public view returns (uint256 balance) {
        balance = addr.balance;
    }
    function getBlockHash(uint256 blockNumber) public view returns (bytes32 blockHash) {
        blockHash = blockhash(blockNumber);
    }
    function getLastBlockHash() public view returns (bytes32 blockHash) {
        blockHash = blockhash(block.number - 1);
    }
    function getCurrentBlockTimestamp() public view returns (uint256 timestamp) {
        timestamp = block.timestamp;
    }
    function getCurrentBlockDifficulty() public view returns (uint256 difficulty) {
        difficulty = block.difficulty;
    }
    function getCurrentBlockGasLimit() public view returns (uint256 gaslimit) {
        gaslimit = block.gaslimit;
    }
    function getCurrentBlockCoinbase() public view returns (address coinbase) {
        coinbase = block.coinbase;
    }
}