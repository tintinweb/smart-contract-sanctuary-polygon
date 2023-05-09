// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
// slither-disable-next-line solc-version
pragma solidity ^0.8.4;

import "./TransferHelper.sol";

/**
 * @title Claimable
 * @notice It withdraws accidentally sent tokens or ETH from this contract.
 */
abstract contract Claimable {
    /// @dev Withdraws ERC20 tokens from this contract
    /// (take care of reentrancy attack risk mitigation)
    function _claimErc20(
        address token,
        address to,
        uint256 amount
    ) internal {
        // withdraw ERC20
        TransferHelper.safeTransfer(token, to, amount);
    }

    /// @dev Withdraws ERC20 tokens from this contract
    /// (take care of reentrancy attack risk mitigation)
    // disabled since false positive
    // slither-disable-next-line dead-code
    function _claimEthOrErc20(
        address token,
        address to,
        uint256 amount
    ) internal {
        if (token == address(0)) {
            // withdraw ETH
            TransferHelper.safeTransferETH(to, amount);
        } else {
            // withdraw ERC20
            TransferHelper.safeTransfer(token, to, amount);
        }
    }
}

// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
// slither-disable-next-line solc-version
pragma solidity ^0.8.4;

/// @title ImmutableOwnable
abstract contract ImmutableOwnable {
    /// @notice The owner who has privileged rights
    // solhint-disable-next-line var-name-mixedcase
    address public immutable OWNER;

    /// @dev Throws if called by any account other than the {OWNER}.
    modifier onlyOwner() {
        require(OWNER == msg.sender, "ImmOwn: unauthorized");
        _;
    }

    constructor(address _owner) {
        require(_owner != address(0), "ImmOwn: zero owner address");
        OWNER = _owner;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// solhint-disable avoid-low-level-calls
// solhint-disable no-inline-assembly
// slither-disable-next-line solc-version
pragma solidity ^0.8.4;

/// @title TransferHelper library
/// @dev Helper methods for interacting with ERC20, ERC721, ERC1155 tokens and sending ETH
/// Based on the Uniswap/solidity-lib/contracts/libraries/TransferHelper.sol
library TransferHelper {
    /// @dev Throws if the deployed code of the `token` is empty.
    // Low-level CALL to a non-existing contract returns `success` of 1 and empty `data`.
    // It may be misinterpreted as a successful call to a deployed token contract.
    // So, the code calling a token contract must insure the contract code exists.
    modifier onlyDeployedToken(address token) {
        uint256 codeSize;
        // slither-disable-next-line assembly
        assembly {
            codeSize := extcodesize(token)
        }
        require(codeSize > 0, "TransferHelper: zero codesize");
        _;
    }

    /// @dev Approve the `operator` to spend all of ERC720 tokens on behalf of `owner`.
    // disabled since false positive
    // slither-disable-next-line dead-code
    function safeSetApprovalForAll(
        address token,
        address operator,
        bool approved
    ) internal onlyDeployedToken(token) {
        // slither-disable-next-line low-level-calls
        (bool success, bytes memory data) = token.call(
            // bytes4(keccak256('setApprovalForAll(address,bool)'));
            abi.encodeWithSelector(0xa22cb465, operator, approved)
        );
        _requireSuccess(success, data);
    }

    /// @dev Get the ERC20 balance of `account`
    // disabled since false positive
    // slither-disable-next-line dead-code
    function safeBalanceOf(address token, address account)
        internal
        returns (uint256 balance)
    {
        // slither-disable-next-line low-level-calls
        (bool success, bytes memory data) = token.call(
            // bytes4(keccak256(bytes('balanceOf(address)')));
            abi.encodeWithSelector(0x70a08231, account)
        );
        require(
            // since `data` can't be empty, `onlyDeployedToken` unneeded
            success && (data.length != 0),
            "TransferHelper: balanceOff call failed"
        );

        balance = abi.decode(data, (uint256));
    }

    /// @dev Approve the `spender` to spend the `amount` of ERC20 token on behalf of `owner`.
    // disabled since false positive
    // slither-disable-next-line dead-code
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal onlyDeployedToken(token) {
        // slither-disable-next-line low-level-calls
        (bool success, bytes memory data) = token.call(
            // bytes4(keccak256('approve(address,uint256)'));
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        _requireSuccess(success, data);
    }

    /// @dev Transfer `value` ERC20 tokens from caller to `to`.
    // disabled since false positive
    // slither-disable-next-line dead-code
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal onlyDeployedToken(token) {
        // slither-disable-next-line low-level-calls
        (bool success, bytes memory data) = token.call(
            // bytes4(keccak256('transfer(address,uint256)'));
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        _requireSuccess(success, data);
    }

    /// @dev Transfer `value` ERC20 tokens on behalf of `from` to `to`.
    // disabled since false positive
    // slither-disable-next-line dead-code
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal onlyDeployedToken(token) {
        // slither-disable-next-line low-level-calls
        (bool success, bytes memory data) = token.call(
            // bytes4(keccak256('transferFrom(address,address,uint256)'));
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        _requireSuccess(success, data);
    }

    /// @dev Transfer an ERC721 token with id of `tokenId` on behalf of `from` to `to`.
    // disabled since false positive
    // slither-disable-next-line dead-code
    function erc721SafeTransferFrom(
        address token,
        uint256 tokenId,
        address from,
        address to
    ) internal onlyDeployedToken(token) {
        // slither-disable-next-line low-level-calls
        (bool success, bytes memory data) = token.call(
            // bytes4(keccak256('safeTransferFrom(address,address,uint256)'));
            abi.encodeWithSelector(0x42842e0e, from, to, tokenId)
        );
        _requireSuccess(success, data);
    }

    /// @dev Transfer `amount` ERC1155 token with id of `tokenId` on behalf of `from` to `to`.
    // disabled since false positive
    // slither-disable-next-line dead-code
    function erc1155SafeTransferFrom(
        address token,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory _data
    ) internal onlyDeployedToken(token) {
        // slither-disable-next-line low-level-calls
        (bool success, bytes memory data) = token.call(
            // bytes4(keccak256('safeTransferFrom(address,address,uint256,uint256,bytes)'));
            abi.encodeWithSelector(0xf242432a, from, to, tokenId, amount, _data)
        );
        _requireSuccess(success, data);
    }

    /// @dev Transfer `value` Ether from caller to `to`.
    // disabled since false positive
    // slither-disable-next-line dead-code
    function safeTransferETH(address to, uint256 value) internal {
        // slither-disable-next-line low-level-calls
        (bool success, ) = to.call{ value: value }(new bytes(0));
        require(success, "TransferHelper: ETH transfer failed");
    }

    function _requireSuccess(bool success, bytes memory res) private pure {
        require(
            success && (res.length == 0 || abi.decode(res, (bool))),
            "TransferHelper: token contract call failed"
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2023 Panther Ventures Limited Gibraltar
pragma solidity 0.8.16;

import "../common/TransferHelper.sol";
import "../common/ImmutableOwnable.sol";
import "../common/Claimable.sol";

// !! TODOs:
// Define uniswap v2 lisence

interface IPantherPool {
    function burnPrp(uint256 amount, bytes calldata proof)
        external
        returns (bool);
}

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
    uint224 private constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

library PrpConverterLib {
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(
            amountIn > 0 && reserveIn > 0 && reserveOut > 0,
            "PCL: Insufficient input"
        );
        require(reserveIn > 0 && reserveOut > 0, "PCL: Insufficient liquidity");

        uint256 numerator = amountIn * reserveOut;
        uint256 denominator = reserveIn + amountIn;
        amountOut = numerator / denominator;
    }
}

contract PrpConverter is ImmutableOwnable, Claimable {
    // solhint-disable var-name-mixedcase

    /// @notice Address of the $ZKP token contract
    address private immutable ZKP_TOKEN;

    /// @notice Address of the PantherPool contract
    address public immutable PANTHER_POOL;

    // solhint-enable var-name-mixedcase

    bool private initialized;

    uint112 public prpReserve;
    uint112 public zkpReserve;
    uint32 private blockTimestampLast;

    uint256 public pricePrpCumulativeLast;
    uint256 public priceZkpCumulativeLast;

    event Sync(uint112 prpReserve, uint112 zkpReserve);

    constructor(
        address _owner,
        address zkpToken,
        address pantherPool
    ) ImmutableOwnable(_owner) {
        require(
            zkpToken != address(0) && pantherPool != address(0),
            "PC:Zero address"
        );

        ZKP_TOKEN = zkpToken;
        PANTHER_POOL = pantherPool;
    }

    function initialize(uint256 prpVirtualBalance, uint256 zkpBalance)
        external
        onlyOwner
    {
        require(!initialized, "Already initialized");

        initialized = true;

        TransferHelper.safeTransferFrom(
            ZKP_TOKEN,
            msg.sender,
            address(this),
            zkpBalance
        );

        _update(
            prpVirtualBalance,
            zkpBalance,
            uint112(prpVirtualBalance),
            uint112(zkpBalance)
        );
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure returns (uint256 amountOut) {
        return PrpConverterLib.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getReserves()
        public
        view
        returns (
            uint112 _prpReserve,
            uint112 _zkpReserve,
            uint32 _blockTimestampLast
        )
    {
        _prpReserve = prpReserve;
        _zkpReserve = zkpReserve;
        _blockTimestampLast = blockTimestampLast;
    }

    function convert(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _to,
        uint256 _deadline,
        bytes memory _proof
    ) external {
        require(_proof.length > 0, "PC: Invalid prrof");
        require(_deadline >= block.timestamp, "PC: Convert expired");
        require(_to != ZKP_TOKEN, "PC: Invalid receiver");

        (uint112 _prpReserve, uint112 _zkpReserve, ) = getReserves();

        require(_zkpReserve > 0, "PC: Insufficient liquidity");

        uint256 amountOut = PrpConverterLib.getAmountOut(
            _amountIn,
            _prpReserve,
            _zkpReserve
        );

        require(amountOut >= _amountOutMin, "PC: Insufficient output");

        require(amountOut < _zkpReserve, "PC: Insufficient liquidity");
        require(
            IPantherPool(PANTHER_POOL).burnPrp(_amountIn, _proof),
            "PC: Prp burn failed"
        );

        TransferHelper.safeTransfer(ZKP_TOKEN, _to, amountOut);

        uint256 prpVirtualBalance = _prpReserve + _amountIn;
        uint256 zkpBalance = TransferHelper.safeBalanceOf(
            ZKP_TOKEN,
            address(this)
        );

        require(
            prpVirtualBalance * zkpBalance >=
                uint256(_prpReserve) * _zkpReserve,
            "PCL: K"
        );

        _update(prpVirtualBalance, zkpBalance, _prpReserve, _zkpReserve);
    }

    function updateZkpReserve() external {
        uint256 zkpBalance = TransferHelper.safeBalanceOf(
            ZKP_TOKEN,
            address(this)
        );

        (uint112 _prpReserve, uint112 _zkpReserve, ) = getReserves();

        if (zkpBalance == _zkpReserve) return;

        uint256 zkpAmountIn = zkpBalance - _zkpReserve;

        uint256 prpAmountOut = PrpConverterLib.getAmountOut(
            zkpAmountIn,
            _zkpReserve,
            _prpReserve
        );

        uint256 prpVirtualBalance = _prpReserve - prpAmountOut;

        _update(prpVirtualBalance, zkpBalance, _prpReserve, _zkpReserve);
    }

    function _update(
        uint256 prpVirtualBalance,
        uint256 zkpBalance,
        uint112 prpReserves,
        uint112 zkpReserves
    ) private {
        prpReserve = uint112(prpVirtualBalance);
        zkpReserve = uint112(zkpBalance);
        uint32 blockTimestamp = uint32(block.timestamp);

        uint32 timeElapsed = blockTimestamp - blockTimestampLast;

        if (timeElapsed > 0 && zkpReserves != 0) {
            pricePrpCumulativeLast +=
                uint256(
                    UQ112x112.uqdiv(UQ112x112.encode(zkpReserves), prpReserves)
                ) *
                timeElapsed;

            priceZkpCumulativeLast +=
                uint256(
                    UQ112x112.uqdiv(UQ112x112.encode(prpReserves), zkpReserves)
                ) *
                timeElapsed;
        }

        prpReserve = uint112(prpVirtualBalance);
        zkpReserve = uint112(zkpBalance);
        blockTimestampLast = blockTimestamp;

        emit Sync(prpReserve, zkpReserve);
    }

    /// @dev May be only called by the {OWNER}
    function rescueErc20(
        address token,
        address to,
        uint256 amount
    ) external {
        require(OWNER == msg.sender, "ARC: unauthorized");

        _claimErc20(token, to, amount);
    }
}