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

/// @title Staking
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

// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
// slither-disable-next-line solc-version
pragma solidity ^0.8.4;

abstract contract Utils {
    // false positive
    // slither-disable-next-line timestamp
    function safe32(uint256 n) internal pure returns (uint32) {
        require(n < 2**32, "UNSAFE32");
        return uint32(n);
    }

    function safe96(uint256 n) internal pure returns (uint96) {
        require(n < 2**96, "UNSAFE96");
        return uint96(n);
    }

    // disabled since false positive
    // slither-disable-next-line dead-code
    function safe128(uint256 n) internal pure returns (uint128) {
        require(n < 2**128, "UNSAFE128");
        return uint128(n);
    }

    // disabled since false positive
    // slither-disable-next-line dead-code
    function safe160(uint256 n) internal pure returns (uint160) {
        require(n < 2**160, "UNSAFE160");
        return uint160(n);
    }

    function safe32TimeNow() internal view returns (uint32) {
        return safe32(timeNow());
    }

    // disabled since false positive
    // slither-disable-next-line dead-code
    function safe32BlockNow() internal view returns (uint32) {
        return safe32(blockNow());
    }

    /// @dev Returns the current block timestamp (added to ease testing)
    function timeNow() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    /// @dev Returns the current block number (added to ease testing)
    // disabled since false positive
    // slither-disable-next-line dead-code
    function blockNow() internal view virtual returns (uint256) {
        return block.number;
    }

    // disabled since false positive
    // slither-disable-next-line dead-code
    function revertZeroAddress(address account) internal pure {
        require(account != address(0), "UNEXPECTED_ZERO_ADDRESS");
    }
}

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
// slither-disable-next-line solc-version
pragma solidity 0.8.4;

import "./interfaces/IErc20Min.sol";
import "./interfaces/IRewardPool.sol";
import "../common/Claimable.sol";
import "../common/ImmutableOwnable.sol";
import "../common/Utils.sol";
import "../common/NonReentrant.sol";

/**
 * @title MaticRewardPool
 * @notice It vests $ZKP token from its balance gradually over time.
 * @dev This contract is supposed to release $ZKP to the `RewardMaster` on Matic.
 * Tokens to vest will be bridged from the mainnet to Matic (maybe, a few times).
 */
contract MaticRewardPool is
    ImmutableOwnable,
    NonReentrant,
    Claimable,
    IRewardPool,
    Utils
{
    /// @notice Address of the token vested ($ZKP)
    IErc20Min public immutable token;

    /// @notice Address to vest tokens to
    address public recipient;

    /// @notice (UNIX) Timestamp when vesting starts
    uint32 public startTime;
    /// @notice (UNIX) Timestamp when vesting ends
    uint32 public endTime;

    constructor(address _token, address _owner)
        ImmutableOwnable(_owner)
        nonZeroAddress(_token)
    {
        token = IErc20Min(_token);
    }

    /// @inheritdoc IRewardPool
    function releasableAmount() external view override returns (uint256) {
        if (recipient == address(0)) return 0;

        return _releasableAmount();
    }

    /// @inheritdoc IRewardPool
    function vestRewards() external override returns (uint256 amount) {
        // revert if unauthorized or recipient not yet set
        require(msg.sender == recipient, "RP: unauthorized");

        amount = _releasableAmount();

        // false positive
        // slither-disable-next-line timestamp
        if (amount != 0) {
            // trusted contract - no reentrancy guard needed
            // slither-disable-next-line unchecked-transfer,reentrancy-events
            token.transfer(recipient, amount);
            emit Vested(amount);
        }
    }

    /// @notice Sets the {recipient}, {startTime} and {endTime} to given values
    /// @dev Owner only may call, once only
    function initialize(
        address _recipient,
        uint32 _startTime,
        uint32 _endTime
    ) external onlyOwner nonZeroAddress(_recipient) {
        // once only
        require(recipient == address(0), "RP: initialized");
        // _endTime can't be in the past
        // Time comparison is acceptable in this case since block time accuracy is enough for this scenario
        // slither-disable-next-line timestamp
        require(_endTime > timeNow(), "RP: I2");
        require(_endTime > _startTime, "RP: I3");

        recipient = _recipient;
        startTime = _startTime;
        endTime = _endTime;

        emit Initialized(0, _recipient, _endTime);
    }

    /// @notice Withdraws accidentally sent token from this contract
    /// @dev May be only called by the {OWNER}
    function claimErc20(
        address claimedToken,
        address to,
        uint256 amount
    ) external onlyOwner nonReentrant {
        if (claimedToken == address(token)) {
            // Time comparison is acceptable in this case since block time accuracy is enough for this scenario
            // slither-disable-next-line timestamp
            require(timeNow() > endTime, "RP: prohibited");
        }
        _claimErc20(claimedToken, to, amount);
    }

    function _releasableAmount() internal view returns (uint256) {
        uint256 _timeNow = timeNow();

        // Time comparison is acceptable in this case since block time accuracy is enough for this scenario
        // slither-disable-next-line timestamp
        if (startTime > _timeNow) return 0;

        // trusted contract - no reentrancy guard needed
        uint256 balance = token.balanceOf(address(this));
        // Time comparison is acceptable in this case since block time accuracy is enough for this scenario
        // slither-disable-next-line timestamp
        if (_timeNow >= endTime) return balance;

        // @dev Next line has a bug (it ignores already released amounts).
        // The buggy line left unchanged here as it is at:
        // matic:0x773d49309c4E9fc2e9254E7250F157D99eFe2d75
        // The PIP-4 deactivated this code:
        // https://docs.pantherprotocol.io/dao/governance/proposal-4-polygon-fix
        return (balance * (_timeNow - startTime)) / (endTime - startTime);
    }

    modifier nonZeroAddress(address account) {
        require(account != address(0), "RP: zero address");
        _;
    }
}

// SPDX-License-Identifier: MIT
// slither-disable-next-line solc-version
pragma solidity ^0.8.4;

interface IErc20Min {
    /// @dev ERC-20 `balanceOf`
    function balanceOf(address account) external view returns (uint256);

    /// @dev ERC-20 `transfer`
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /// @dev ERC-20 `transferFrom`
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /// @dev EIP-2612 `permit`
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
// slither-disable-next-line solc-version
pragma solidity ^0.8.4;

interface IRewardPool {
    /// @notice Returns token amount that may be released (vested) now
    function releasableAmount() external view returns (uint256);

    /// @notice Vests releasable token amount to the {recipient}
    /// @dev {recipient} only may call
    function vestRewards() external returns (uint256 amount);

    /// @notice Emitted on vesting to the {recipient}
    event Vested(uint256 amount);

    /// @notice Emitted on parameters initialized.
    event Initialized(uint256 _poolId, address _recipient, uint256 _endTime);
}