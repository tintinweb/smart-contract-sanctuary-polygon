// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

import {SafeTransferLib} from "./libs/SafeTransferLib.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IWETH} from "./interfaces/IWETH.sol";

contract BasePool {
    using SafeTransferLib for IERC20;

    struct DisperseData {
        address token;
        address payable[] recipients;
        uint256[] values;
    }

    IWETH immutable wNATIVE;

    /// @notice Contract owner.
    // can not be transferred to another address
    address public owner;


    event DisperseToken(address token, uint256 totalAmount);

    constructor(address _wNATIVE) {
        wNATIVE = IWETH(_wNATIVE);
    }

    receive() external payable {}

    /// @notice Modifier to only allow the contract owner to call a function
    modifier onlyOwner() {
        require(msg.sender == owner, "only-owner");
        _;
    }

    function initialize(address _owner) virtual public {
        require(owner == address(0), "initialized");
        owner = _owner;
    }

    function disperseEther(
        address payable[] calldata recipients,
        uint256[] calldata values
    ) external payable onlyOwner {
        _disperseEther(recipients, values);
    }

    function _disperseEther(
        address payable[] calldata recipients,
        uint256[] calldata values
    ) internal {
        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; ++i) total += values[i];
        emit DisperseToken(address(0), total);

        // if (total > msg.value), tx will revert
        uint256 ethToRefund = msg.value - total;

        for (uint256 i = 0; i < recipients.length; ++i)
            _safeTransferETHWithFallback(recipients[i], values[i]);

        if (ethToRefund > 0) _safeTransferETHWithFallback(msg.sender, ethToRefund);
    }

    function disperseToken(
        IERC20 token,
        address payable[] calldata recipients,
        uint256[] calldata values
    ) external onlyOwner {
        _disperseToken(token, recipients, values);
    }

    function _disperseToken(
        IERC20 token,
        address payable[] calldata recipients,
        uint256[] calldata values
    ) internal {
        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; ++i) total += values[i];
        token.safeTransferFrom(msg.sender, address(this), total);
        emit DisperseToken(address(token), total);
        for (uint256 i = 0; i < recipients.length; ++i)
            token.safeTransfer(recipients[i], values[i]);
    }

    function batchDisperse(DisperseData[] calldata disperseDatas)
        external
        payable
        onlyOwner
    {
        uint256 disperseCount = disperseDatas.length;
        bool nativePoolAlreadyExist;
        for (uint256 i = 0; i < disperseCount; ++i) {
            if (address(disperseDatas[i].token) == address(0)) {
                if (nativePoolAlreadyExist) revert("Only one native disperse is allowed");
                nativePoolAlreadyExist = true;
                _disperseEther(
                    disperseDatas[i].recipients,
                    disperseDatas[i].values
                );
            } else {
                _disperseToken(
                    IERC20(disperseDatas[i].token),
                    disperseDatas[i].recipients,
                    disperseDatas[i].values
                );
            }
        }
    }

    // this method is identical to `disperseToken()` feature wise
    // the difference between `disperseToken()` and this method is that: 
    // instead of `transferFrom()` the caller only once, and using `transfer()` for each of the recipients; this method will call `transferFrom()` for each recipients.
    // `disperseToken()` choose to use `transfer()` for the recipients to save the gas costs for allowance checks, at the cost of one extra external call (`transferFrom` the caller to `address(this)`)
    // however, the saved amount can be less than the cost of the extra `transferFrom()`
    // this is where `disperseTokenSimple()` comes in, when the number of recipients is rather small, this method will be cheaper than `disperseToken()`
    // and the frontend should compare the gas costs of the two methods to choose which one to be used.
    function disperseTokenSimple(
        IERC20 token,
        address[] calldata recipients,
        uint256[] calldata values
    ) external onlyOwner {
        for (uint256 i = 0; i < recipients.length; ++i)
            token.transferFrom(msg.sender, recipients[i], values[i]);
    }

    // arbitrary call for retrieving tokens, airdrops, and etc
    function ownerCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external payable onlyOwner returns (bool success, bytes memory result) {
        (success, result) = to.call{value: value}(data);
    }

    /**
     * @notice Transfer ETH. If the ETH transfer fails, wrap the ETH and try send it as WETH.
     * @param to account who to send the ETH or WETH to
     * @param amount uint256 how much ETH or WETH to send
     */
    function _safeTransferETHWithFallback(address to, uint256 amount) internal {
        if (!_safeTransferETH(to, amount)) {
            wNATIVE.deposit{value: amount}();
            wNATIVE.transfer(to, amount);
        }
    }

    /**
     * @notice Transfer ETH and return the success status.
     * @dev This function only forwards 30,000 gas to the callee.
     * @param to account who to send the ETH to
     * @param value uint256 how much ETH to send
     */
    function _safeTransferETH(address to, uint256 value)
        internal
        returns (bool)
    {
        (bool success, ) = to.call{value: value, gas: 30_000}(new bytes(0));
        return success;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {IERC20} from "../interfaces/IERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    event Debug(bool one, bool two, uint256 retsize);

    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

import {IERC20} from "./interfaces/IERC20.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {IERC20Permit} from "./interfaces/IERC20Permit.sol";
import "./BasePool.sol";

contract DistributionPool is BasePool {
    using SafeTransferLib for IERC20;

    enum PoolStatus {
        None, // Pool is not exist
        Initialized, // unfunded
        Funded, // funded
        Closed // canceled or fully distributed
    }

    struct PoolData {
        string name;
        address distributor;
        IERC20 token;
        uint48 startTime;
        uint48 deadline;
        uint128 totalAmount;
        uint128 claimedAmount;
        uint128 fundedAmount;
        address[] claimers;
        uint128[] amounts;
    }

    struct PoolInfo {
        string name;
        IERC20 token;
        address distributor;
        bool fundNow;
        address[] claimers;
        uint128[] amounts;
        uint48 startTime;
        uint48 deadline;
    }

    struct PermitData {
        address token;
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    uint256 private locked = 1;

    uint256 public lastPoolId;

    mapping(uint256 => PoolData) public pools;
    mapping(uint256 => PoolStatus) public poolsStatus;
    mapping(address => mapping(uint256 => uint256)) public userClaimedAmount;

    event Created(uint256 indexed poolId);
    event Canceled(uint256 indexed poolId);
    event Claimed(uint256 indexed poolId);
    event Funded(uint256 indexed poolId, address funder);
    event Distributed(uint256 indexed poolId);

    constructor(address _wNATIVE) BasePool(_wNATIVE) {
    }

    function initialize(address _owner) override public {
        super.initialize(_owner);
        // initialize ReentrancyGuard
        locked = 1;
    }

    modifier nonReentrant() {
        require(locked == 1, "REENTRANCY");
        locked = 2;
        _;
        locked = 1;
    }

    /// Create a new distribution pool
    function create(PoolInfo calldata poolInfo)
        external
        payable
        nonReentrant
        onlyOwner
        returns (uint256)
    {
        return _create(poolInfo);
    }

    function createWithPermit(PoolInfo calldata poolInfo, PermitData[] calldata permitDatas) 
        external
        payable
        nonReentrant
        onlyOwner
        returns (uint256)
    {
        batchSelfPermit(permitDatas);
        return _create(poolInfo);
    }

    function batchCreate(PoolInfo[] calldata poolInfos)
        external
        payable
        nonReentrant
        onlyOwner
        returns (uint256[] memory)
    {
        return _batchCreate(poolInfos);
    }

    function batchCreateWithPermit(PoolInfo[] calldata poolInfos, PermitData[] calldata permitDatas)
        external
        payable
        nonReentrant
        onlyOwner
        returns (uint256[] memory)
    {
        batchSelfPermit(permitDatas);
        return _batchCreate(poolInfos);
    }

    function _create(PoolInfo calldata poolInfo)
        internal
        returns (uint256 poolId)
    {
        require(
            poolInfo.startTime > block.timestamp,
            "startTime must be in the future"
        );
        require(
            poolInfo.deadline > poolInfo.startTime,
            "deadline must be after startTime"
        );
        uint128 totalAmount;
        {
            uint256 claimersLength = poolInfo.claimers.length;
            uint256 amountsLength = poolInfo.amounts.length;
            require(
                claimersLength == amountsLength,
                "length of claimers and amounts must be equal"
            );
            for (uint256 i = 0; i < claimersLength; ++i) {
                require(
                    poolInfo.claimers[i] != address(0),
                    "claimer must be a valid address"
                );
                require(
                    poolInfo.amounts[i] > 0,
                    "amount must be greater than 0"
                );
                require(
                    i == 0 || poolInfo.claimers[i] > poolInfo.claimers[i - 1],
                    "Not sorted or duplicate"
                );
                // will revert on overflow when `totalAmount + poolInfo.amounts[i] > type(uint128).max`
                totalAmount += poolInfo.amounts[i];
            }
        }
        poolId = ++lastPoolId;
        uint128 receivedAmount;
        if (poolInfo.fundNow) {
            receivedAmount = _receiveOrPullFundsFromMsgSender(
                poolInfo.token,
                totalAmount
            );
            poolsStatus[poolId] = PoolStatus.Funded;
        } else {
            poolsStatus[poolId] = PoolStatus.Initialized;
        }
        pools[poolId] = PoolData({
            name: poolInfo.name,
            distributor: poolInfo.distributor,
            token: poolInfo.token,
            startTime: poolInfo.startTime,
            deadline: poolInfo.deadline,
            totalAmount: totalAmount,
            fundedAmount: receivedAmount,
            claimedAmount: 0,
            claimers: poolInfo.claimers,
            amounts: poolInfo.amounts
        });
        emit Created(poolId);
        return poolId;
    }

    function _batchCreate(PoolInfo[] calldata poolInfos)
        internal
        returns (uint256[] memory)
    {
        uint256 poolCount = poolInfos.length;
        uint256[] memory poolIds = new uint256[](poolCount);
        bool nativePoolAlreadyExist;
        for (uint256 i = 0; i < poolCount; ++i) {
            // only one native pool is allowed in batch create
            // because `msg.value` is used to fund the pool
            if (address(poolInfos[i].token) == address(0)) {
                if (nativePoolAlreadyExist) revert("Only one native pool is allowed");
                nativePoolAlreadyExist = true;
            }
            poolIds[i] = _create(poolInfos[i]);
        }
        return poolIds;
    }

    /// @notice claim tokens from a pool
    /// @dev nonReentrant check in single method.
    function claim(uint256[] calldata _poolIds) external {
        uint256 poolIdsLength = _poolIds.length;
        for (uint256 i = 0; i < poolIdsLength; ++i) {
            _claimSinglePool(_poolIds[i]);
        }
    }

    function claimSinglePool(uint256 _poolId) external {
        _claimSinglePool(_poolId);
    }

    function _claimSinglePool(uint256 _poolId) internal nonReentrant {
        require(
            poolsStatus[_poolId] == PoolStatus.Funded,
            "pool must be funded"
        );
        PoolData storage pool = pools[_poolId];
        require(block.timestamp > pool.startTime, "claim not started yet");
        require(block.timestamp < pool.deadline, "claim deadline passed");
        uint256 claimerLength = pool.claimers.length;
        for (uint256 i = 0; i < claimerLength; ++i) {
            if (pool.claimers[i] == msg.sender) {
                return
                    _claimTokenIfUnclaimed(
                        _poolId,
                        msg.sender,
                        pool.amounts[i],
                        pool
                    );
            }
        }
    }

    function _claimTokenIfUnclaimed(
        uint256 _poolId,
        address _claimer,
        uint128 _amount,
        PoolData storage pool
    ) internal {
        if (userClaimedAmount[_claimer][_poolId] == 0) {
            pool.claimedAmount += _amount;
            // if all the tokens are claimed, so we can close the pool
            if (pool.claimedAmount == pool.totalAmount) {
                poolsStatus[_poolId] = PoolStatus.Closed;
            }
            userClaimedAmount[_claimer][_poolId] = _amount;
            if (address(pool.token) == address(0)) {
                _safeTransferETHWithFallback(_claimer, _amount);
            } else {
                pool.token.safeTransfer(_claimer, _amount);
            }
            emit Claimed(_poolId);
        }
    }

    /// fund a pool
    function fund(uint256 _poolId) external payable nonReentrant {
        _fundSinglePool(pools[_poolId], _poolId);
    }

    function fundWithPermit(
        uint256 _poolId,
        PermitData[] calldata permitDatas
    )
        external
        payable
        nonReentrant
    {
        batchSelfPermit(permitDatas);
        _fundSinglePool(pools[_poolId], _poolId);
    }

    function batchFund(uint256[] calldata _poolIds) external payable nonReentrant {
        _batchFund(_poolIds);
    }

    function batchFundWithPermit(
        uint256[] calldata _poolIds,
        PermitData[] calldata permitDatas
    )
        external
        payable
        nonReentrant
    {
        batchSelfPermit(permitDatas);
        return _batchFund(_poolIds);
    }

    function _fundSinglePool(PoolData storage pool, uint256 _poolId) internal {
        require(
            poolsStatus[_poolId] == PoolStatus.Initialized,
            "pool must be pending"
        );
        pool.fundedAmount = _receiveOrPullFundsFromMsgSender(
            pool.token,
            pool.totalAmount
        );
        poolsStatus[_poolId] = PoolStatus.Funded;
        emit Funded(_poolId, msg.sender);
    }

    function _batchFund(uint256[] calldata _poolIds)
        internal
    {
        bool nativePoolAlreadyExist;
        for (uint256 i = 0; i < _poolIds.length; ++i) {
            PoolData storage pool = pools[_poolIds[i]];
            if (address(pool.token) == address(0)) {
                if (nativePoolAlreadyExist) revert("Only one native is allowed");
                nativePoolAlreadyExist = true;
            }
            _fundSinglePool(pool, _poolIds[i]);
        }
    }

    /// d tokens to users
    function distribute(uint256[] calldata _poolIds) external nonReentrant {
        for (uint256 i = 0; i < _poolIds.length; ++i) {
            _distributeSinglePool(_poolIds[i]);
        }
    }

    function _distributeSinglePool(uint256 _poolId) internal {
        PoolData storage pool = pools[_poolId];
        require(
            pool.distributor == msg.sender,
            "only distributor can distribute"
        );
        if (poolsStatus[_poolId] == PoolStatus.Initialized) {
            _fundSinglePool(pool, _poolId);
        } else {
            require(
                poolsStatus[_poolId] == PoolStatus.Funded,
                "pool must be funded"
            );
        }
        uint256 claimerLength = pool.claimers.length;
        for (uint256 i = 0; i < claimerLength; ++i) {
            _claimTokenIfUnclaimed(
                _poolId,
                pool.claimers[i],
                pool.amounts[i],
                pool
            );
        }
        emit Distributed(_poolId);
    }

    /// @dev cancel a pool and get unclaimed tokens back
    function cancel(uint256[] calldata _poolIds) external onlyOwner nonReentrant {
        for (uint256 i = 0; i < _poolIds.length; ++i) {
            _cancelSinglePool(_poolIds[i]);
        }
    }

    /// @notice refundable tokens will return to msg.sender
    function _cancelSinglePool(uint256 _poolId) internal {
        require(
            poolsStatus[_poolId] != PoolStatus.Closed,
            "pool already closed"
        );
        PoolData storage pool = pools[_poolId];
        require(
            pool.startTime > block.timestamp || pool.deadline < block.timestamp,
            "ongoing pool can not be canceled"
        );
        poolsStatus[_poolId] = PoolStatus.Closed;
        uint128 refundableAmount = pool.fundedAmount - pool.claimedAmount;
        if (refundableAmount > 0) {
            if (address(pool.token) == address(0)) {
                _safeTransferETHWithFallback(msg.sender, refundableAmount);
            } else {
                pool.token.safeTransfer(msg.sender, refundableAmount);
            }
        }
        emit Canceled(_poolId);
    }

    function _receiveOrPullFundsFromMsgSender(IERC20 token, uint128 wantAmount)
        internal
        returns (uint128 receivedAmount)
    {
        if (address(token) == address(0)) {
            require(msg.value == wantAmount, "!msg.value");
            receivedAmount = wantAmount;
        } else {
            // no need to require msg.value == 0 here
            // the owner can always use `ownerCall` to get eth back
            uint128 tokenBalanceBefore = _safeUint128(
                token.balanceOf(address(this))
            );
            token.safeTransferFrom(msg.sender, address(this), wantAmount);
            receivedAmount =
                _safeUint128(token.balanceOf(address(this))) -
                tokenBalanceBefore;
            // this check ensures the token is not a fee-on-transfer token
            // which is not supported yet
            require(
                receivedAmount >= wantAmount,
                "received token amount must be greater than or equal to wantAmount"
            );
        }
    }

    // Functionality to call permit on any EIP-2612-compliant token
    function selfPermit(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        IERC20Permit(token).permit(msg.sender, address(this), value, deadline, v, r, s);
    }

    function batchSelfPermit(
        PermitData[] calldata permitDatas
    ) public {
        for (uint256 i = 0; i < permitDatas.length; ++i) {
            selfPermit(
                permitDatas[i].token,
                permitDatas[i].value,
                permitDatas[i].deadline,
                permitDatas[i].v,
                permitDatas[i].r,
                permitDatas[i].s
            );
        }
    }

    // internal utils
    function _safeUint128(uint256 x) internal pure returns (uint128) {
        require(x < type(uint128).max, "!uint128.max");
        return uint128(x);
    }

    function getPoolById(uint256 poolId)
        external
        view
        returns (PoolData memory, PoolStatus)
    {
        return (pools[poolId], poolsStatus[poolId]);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "@openzeppelin/contracts/proxy/Clones.sol";

import "./DistributionPool.sol";

/// @title The PoolFactory allows users to create own dPool very cheaply.
contract PoolFactory {
    /// @notice The instance to which all proxies will point.
    DistributionPool public immutable distributionPoolImp;

    /// contract _owner => dPool contract address
    mapping(address => address) public distributionPoolOf;
    
    event DistributionPoolCreated(
        address indexed creator,
        address contractAddress
    );

    /// @notice Contract constructor.
    constructor(address _wNATIVE) {
        distributionPoolImp = new DistributionPool(_wNATIVE);
        distributionPoolImp.initialize(address(this));
    }

    /**
     * @notice Creates a clone.
     * @return The newly created contract address
     */
    function create() external returns (address) {
        address _dPool = Clones.clone(address(distributionPoolImp));
        DistributionPool(payable(_dPool)).initialize(msg.sender);

        distributionPoolOf[msg.sender] = _dPool;
        emit DistributionPoolCreated(msg.sender, _dPool);

        return _dPool;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}