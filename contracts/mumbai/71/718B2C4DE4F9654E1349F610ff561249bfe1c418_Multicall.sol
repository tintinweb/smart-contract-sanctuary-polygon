// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/// @title Multicall.
/// @notice Contract that batches view function calls and aggregates their results.
/// @author Adapted from Makerdao's Multicall2 (https://github.com/makerdao/multicall/blob/master/src/Multicall2.sol).

contract Multicall {
    /// @dev 0x
    error CallFailed(string reason);

    struct Call {
        address target;
        bytes callData;
    }
    struct Result {
        bool success;
        bytes returnData;
    }

    //prettier-ignore
    constructor(/*  */) payable {/*  */}

    function mtc1(Call[] calldata calls)
        external
        returns (uint256, bytes[] memory)
    {
        uint256 bn = block.number;
        uint256 len = calls.length;
        bytes[] memory res = new bytes[](len);
        uint256 j;

        while (j < len) {
            (bool success, bytes memory ret) = calls[j]
                .target
                .call(calls[j].callData);
            if (!success) {
                if (ret.length < 0x44) revert CallFailed("");
                assembly {
                    ret := add(ret, 0x04)
                }
                revert CallFailed({
                    reason: abi.decode(ret, (string))
                });
            }
            res[j] = ret;
            ++j;
        }
        return (bn, res);
    }

    function mtc2(Call[] calldata calls)
        external
        returns (
            uint256,
            bytes32,
            Result[] memory
        )
    {
        uint256 bn = block.number;
        // µ 0 s [0] ≡ P(IHp , µs [0], 0) ∴ P is the hash of a block of a particular number, up to a maximum age.
        // 0 is left on the stack if the looked for `block.number` is >= to the current `block.number` or more than 256
        // blocks behind the current block (Yellow Paper, p. 33, https://ethereum.github.io/yellowpaper/paper.pdf).
        bytes32 bh = blockhash(
            bn /* - 1 */
        );
        uint256 len = calls.length;
        Result[] memory res = new Result[](len);
        uint256 i;
        for (i; i < len; ) {
            (bool success, bytes memory ret) = calls[i]
                .target
                .call(calls[i].callData);

            res[i] = Result(success, ret);
            ++i;
        }
        return (bn, bh, res);
    }
}