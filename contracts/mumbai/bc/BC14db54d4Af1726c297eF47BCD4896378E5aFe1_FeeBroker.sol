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

// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
// slither-disable-next-line solc-version
pragma solidity ^0.8.4;

/**
 * @title NonReentrant
 * @notice It provides reentrancy guard.
 * The code borrowed from openzeppelin-contracts.
 * Unlike original, this version requires neither `constructor` no `init` call.
 */
abstract contract NonReentrant {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _reentrancyStatus;

    modifier nonReentrant() {
        // Being called right after deployment, when _reentrancyStatus is 0 ,
        // it does not revert (which is expected behaviour)
        require(_reentrancyStatus != _ENTERED, "claimErc20: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _reentrancyStatus = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _reentrancyStatus = _NOT_ENTERED;
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
// slither-disable-next-line solc-version
pragma solidity ^0.8.16;

// solhint-disable var-name-mixedcase

// The "prp grant type" for the "release and bridge" ZKPs
// bytes4(keccak256("ZKP_RELEASE_AND_BRIDGE"))
bytes4 constant ZKP_RELEASE_AND_BRIDGE_PRP_GRANT_TYPE = 0x02c37d4a;

// The "prp grant type" for swapping zkp for fee token
// bytes4(keccak256("ZKP_SWAP_FOR_FEE_TOKEN"))
bytes4 constant ZKP_SWAP_FOR_FEE_TOKEN_PRP_GRANT_TYPE = 0xacabdeb3;

// The "prp grant type" for the transferring ZKP to treasury and PRP converter
// bytes4(keccak256("ZKP_TRANSFER_TO_TREASURY_AND_PRP_CONVERTER"))
bytes4 constant ZKP_TRANSFER_TO_TREASURY_AND_PRP_CONVERTER_PRP_GRANT_TYPE = 0xe96177c4;

// solhint-enable var-name-mixedcase

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2023 Panther Ventures Limited Gibraltar
pragma solidity 0.8.16;

import "../common/ImmutableOwnable.sol";
import "../common/TransferHelper.sol";
import "../common/Claimable.sol";
import "../common/NonReentrant.sol";

import "./interfaces/IPrpGranter.sol";
import "./interfaces/IZkpPriceOracle.sol";
import "./actions/Constants.sol";

/***
 * @title FeeBroker
 * @notice It collects fee tokens, exchange them for ZKP and transfer its ZKP balance to the
 * PRP converter and Treasury contracts.
 * @dev This contract is supposed to transfer the fee token from panther shielded pool. It let's
 * users to sell their ZKPs for the collected fee tokens. Users needs to define the exact amount
 * of ZKP which they aim to sell, then this contract used Uniswap v3 as price oracle to calculate
 * the fee token which can be sent to them. At the end of the day, some portion of the ZKP
 * balance of this contract can be sent to the PrpConverter and the rest can go to
 * the PantherTreasury. Users who exchange their ZKPs for fee tokens or trigger this contract to
 * move its ZKP balance to the PRP converter and Treasury are granted PRPs as rewards.
 ***/
contract FeeBroker is ImmutableOwnable, Claimable, NonReentrant {
    // solhint-disable var-name-mixedcase

    // Address of the $ZKP token contract
    address private immutable ZKP_TOKEN;

    /// @notice PrpConverter contract instance
    address public immutable PRP_CONVERTER;

    /// @notice PrpGranter contract instance
    address public immutable PRP_GRANTER;

    /// @notice PantherPoolV0 contract instance
    address public immutable PANTHER_POOL;

    /// @notice Panther treasury contract instance
    address public immutable PANTHER_TREASURY;

    /// @notice The divider which represents total percentages. scaled by 1e2
    uint256 private constant DIVIDER = 100_00;

    /// @notice Address of the ZkpPriceOracle contract
    IZkpPriceOracle public ZkpPriceOracle;

    // solhint-enable var-name-mixedcase

    /// @notice The percentage of ZKPs that are transfered to treasury
    uint256 public treasuryPercentage;

    event TreasuryPercentageUpdated(uint256 newPercentage);
    event ZkpPriceOracleUpdated(address newZkpPriceOracle);
    event Swapped(
        address exchanger,
        address recipient,
        address feeToken,
        uint256 zkpAmount,
        uint256 feeTokenAmount
    );
    event FeeCollected(address token, uint256 amount);
    event TransferedZkpToTreasuryAndPrpConverter(
        uint256 totalZkps,
        uint256 treasuryPortion
    );

    constructor(
        address _owner,
        address zkpToken,
        address prpConverter,
        address prpGranter,
        address pantherPool,
        address pantherTreasury,
        address zkpPriceOracle
    ) ImmutableOwnable(_owner) {
        require(
            zkpToken != address(0) &&
                prpConverter != address(0) &&
                prpGranter != address(0) &&
                pantherPool != address(0) &&
                pantherTreasury != address(0) &&
                zkpPriceOracle != address(0),
            "FB: Zero address"
        );

        ZKP_TOKEN = zkpToken;
        PRP_CONVERTER = prpConverter;
        PRP_GRANTER = prpGranter;
        PANTHER_POOL = pantherPool;
        PANTHER_TREASURY = pantherTreasury;

        ZkpPriceOracle = IZkpPriceOracle(zkpPriceOracle);
    }

    /// @notice Send ZKP balance to PrpConverter and PantherTreasury
    function transferZkpToTreasuryAndPrpConverter() external {
        uint256 totalZkpBalance = TransferHelper.safeBalanceOf(
            ZKP_TOKEN,
            address(this)
        );
        if (totalZkpBalance < DIVIDER) return;

        uint256 treasuryPortion = (totalZkpBalance * treasuryPercentage) /
            DIVIDER;

        TransferHelper.safeTransfer(
            ZKP_TOKEN,
            PANTHER_TREASURY,
            treasuryPortion
        );

        TransferHelper.safeTransfer(
            ZKP_TOKEN,
            PRP_CONVERTER,
            totalZkpBalance - treasuryPortion
        );

        IPrpGranter(PRP_GRANTER).grant(
            ZKP_TRANSFER_TO_TREASURY_AND_PRP_CONVERTER_PRP_GRANT_TYPE,
            msg.sender
        );

        emit TransferedZkpToTreasuryAndPrpConverter(
            totalZkpBalance,
            treasuryPortion
        );
    }

    /// @notice Sell fee token to user and receive ZKP.
    function swapExactZkpTokenForFeeToken(
        address feeToken,
        uint256 zkpTokenAmountIn,
        uint256 feeTokenAmountOutMin,
        address recipient
    ) external nonReentrant {
        uint256 feeTokenAmountOut = ZkpPriceOracle.getFeeTokenAmountOut(
            feeToken,
            zkpTokenAmountIn
        );

        require(
            feeTokenAmountOut >= feeTokenAmountOutMin,
            "FB: Low output amount"
        );

        require(
            TransferHelper.safeBalanceOf(feeToken, address(this)) >=
                feeTokenAmountOut,
            "FB: Insufficient output balance"
        );

        TransferHelper.safeTransferFrom(
            ZKP_TOKEN,
            msg.sender,
            address(this),
            zkpTokenAmountIn
        );

        TransferHelper.safeTransfer(feeToken, recipient, feeTokenAmountOut);

        IPrpGranter(PRP_GRANTER).grant(
            ZKP_SWAP_FOR_FEE_TOKEN_PRP_GRANT_TYPE,
            msg.sender
        );

        emit Swapped(
            msg.sender,
            recipient,
            feeToken,
            zkpTokenAmountIn,
            feeTokenAmountOut
        );
    }

    /// @notice Collect fee tokens from PantherPool
    /// @dev Only PantherPool may call it.
    function collectFeeToken(address token, uint256 amount) external {
        require(msg.sender == PANTHER_POOL, "FB: unauthorized");
        //!! can user send eth as fee?
        //!! should we transfer fee from masp, or user?

        TransferHelper.safeTransferFrom(
            token,
            PANTHER_POOL,
            address(this),
            amount
        );

        emit FeeCollected(token, amount);
    }

    /* ========== ONLY FOR OWNER FUNCTIONS ========== */

    function updateTreasuryPercentage(uint256 newPercentage)
        external
        onlyOwner
    {
        require(newPercentage > 0, "FB: Zero percentage");

        treasuryPercentage = newPercentage;

        emit TreasuryPercentageUpdated(newPercentage);
    }

    function updateZkpPriceOracle(address newZkpPriceOracle)
        external
        onlyOwner
    {
        require(newZkpPriceOracle != address(0), "FB: Zero zkp price oracle");
        ZkpPriceOracle = IZkpPriceOracle(newZkpPriceOracle);

        emit ZkpPriceOracleUpdated(newZkpPriceOracle);
    }

    /// @notice Withdraws accidentally sent token from this contract
    /// @dev May be only called by the {OWNER}
    function claimErc20(
        address claimedToken,
        address to,
        uint256 amount
    ) external onlyOwner nonReentrant {
        _claimErc20(claimedToken, to, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IPrpGranter {
    function grant(bytes4 grantType, address grantee) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IZkpPriceOracle {
    function getFeeTokenAmountOut(address feeToken, uint256 zkpTokenAmountIn)
        external
        returns (uint256 feeTokenAmountOut);
}