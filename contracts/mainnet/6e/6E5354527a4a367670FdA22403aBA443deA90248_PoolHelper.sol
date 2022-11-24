// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.5.0;

library PoolHelper {
    bytes32 public constant POOL_INIT_CODE_HASH = 0x37b92ae39dbd52ce13f7d0e7fbf0cf32db780c5f3ee251726fab96e1c8ff34aa;

    // bytes32 internal constant POOL_INIT_CODE_HASH = 0xe6aaa4f5a582414d3408436a952811f164111f07082cc1b847d70c705b70d882;

    // bytes32 internal constant POOL_INIT_CODE_HASH = 0x346a69e912ad4c98c5960d91b576ac68e01cf72d9fba65fa485ccc09a6e0d2d4;

    function computeAddress(
        address factory,
        address token0,
        address token1
    ) public pure returns (address pool) {
        require(token0 < token1);
        pool = address(
            uint160(uint256(keccak256(abi.encodePacked(hex"ff", factory, keccak256(abi.encode(token0, token1)), POOL_INIT_CODE_HASH))))
        );
    }
}