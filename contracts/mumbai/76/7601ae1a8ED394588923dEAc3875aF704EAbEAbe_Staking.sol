// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./interfaces/IPoolCreator.sol";
import "./deposits/DelegationsAdapter.sol";

contract Staking is IPoolCreator, DelegationsAdapter {
    using SafeMathUpgradeable for uint256;

    /// @notice main erc20 token used for distributing staking rewards
    IERC20Upgradeable public rewardsToken;

    /**
     * @dev Emitted when `amount` of `rewardsToken` has been deposited on the rewards fund.
     */
    event DepositFunds(uint256 amount);

    /**
     * @dev Emitted when the commission fee of `poolId` has been set to `commission`.
     */
    event SetPoolCommissionFee(bytes32 indexed poolId, uint256 commission);

    /**
     * @dev Emitted when beneficiary account of `poolId` has been set to `beneficiary`.
     */
    event SetPoolBeneficiary(bytes32 indexed poolId, address indexed beneficiary);

    /**
     * @dev Emitted when `poolId` has been jailed.
     */
    event JailPool(bytes32 indexed poolId);

    /**
     * @dev Emitted when `poolId` has been unjailed following the deposit of
     * the required fee to the rewards fund.
     */
    event UnjailPool(bytes32 indexed poolId);

    /**
     * @dev Emitted when a new pool of id `poolId` has been created by `owner` account who
     * deposited `currencies` of supported tokens.
     */
    event CreateNewPool(address indexed owner, bytes32 poolId, CurrencyAmount[] currencies);

    /**
     * @dev Emitted when `member` account has delegated `currencies` of supported tokens
     * to `poolId` either as a top-up to an existing delegation or creation of a new one.
     */
    event Delegate(address indexed member, bytes32 indexed poolId, CurrencyAmount[] currencies);

    /**
     * @dev Emitted when `member` account has undelegated `currencies` of supported tokens
     * from `poolId` which created a singleton withdraw request to be later executed.
     */
    event Undelegate(address indexed member, bytes32 indexed poolId, CurrencyAmount[] currencies);

    /**
     * @dev Emitted when `member` account has redelegated `currencies` of supported tokens
     * from suspended `fromPool` and delegated them to `toPool`.
     */
    event Redelegate(
        address indexed member,
        bytes32 indexed fromPool,
        bytes32 indexed toPool,
        CurrencyAmount[] currencies
    );

    /**
     * @dev Emitted when `member` account has restaked `amount` of its unclaimed rewards produced
     * as `source` to pool `toPool`.
     */
    event Restake(address indexed member, RewardSrc indexed source, bytes32 indexed toPool, uint256 amount);

    /**
     * @dev Emitted when `member` account has cancelled its singleton withdraw request on pool
     * `fromPool` and restored the embedded tokens to pool `toPool`.
     */
    event WithdrawRequestCancelled(address indexed member, bytes32 indexed fromPool, bytes32 indexed toPool);

    /**
     * @dev Emitted when `member` account has executed its singleton withdraw request on pool
     * `poolId` and got the embedded tokens transferred back to its wallet.
     */
    event WithdrawRequestExecuted(address indexed member, bytes32 indexed poolId);

    /**
     * @dev Emitted when account `to` has claimed `amount` of its unclaimed rewards produced
     * as `source`.
     */
    event Claim(address indexed to, RewardSrc indexed source, uint256 amount);

    /**
     * @notice Upgradeable initializer of contract.
     * @param ownerAddress initial contract owner
     * @param rewardsToken_ immutable token used for rewards
     * @param epochDuration initial epochs duration
     */
    function initialize(
        address ownerAddress,
        IERC20Upgradeable rewardsToken_,
        uint256 epochDuration
    ) public initializer {
        __StakingEpochManager_init_unchained(epochDuration);

        _setupRole(OWNER_ROLE, ownerAddress);
        _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
        _setRoleAdmin(PAUSER_ROLE, OWNER_ROLE);
        _setRoleAdmin(JAILER_ROLE, OWNER_ROLE);
        _setRoleAdmin(FINALIZER_ROLE, OWNER_ROLE);
        _setRoleAdmin(NODE_MANAGER_ROLE, OWNER_ROLE);

        rewardsToken = rewardsToken_;

        // pause contract until entirely configured
        _pause();
    }

    /**
     * @notice Set the version of the implementation contract.
     * @dev Called when linking a new implementation to the proxy
     * contract at `upgradeToAndCall` using the hard-coded integer version.
     */
    function upgradeVersion() external reinitializer(1) {}

    /**
     * @notice Set the value of global config `key`.
     * @param key id of the configuration
     * @param value new value of the configuration
     */
    function setConfig(bytes32 key, uint256 value) external onlyRole(OWNER_ROLE) {
        _setConfig(key, value);
    }

    /**
     * @notice Set for multiple blockchains the chain-rewards reserved to the pool owner.
     * @param chainIds list of chains to update for
     * @param amounts list of new rewards for each chain type
     */
    function setChainRewards(uint32[] calldata chainIds, uint256[] calldata amounts) external onlyRole(OWNER_ROLE) {
        require(chainIds.length == amounts.length, "setChainRewards: != lengths of chainIds/amounts");
        for (uint256 it; it < chainIds.length; ++it) {
            _setChainRewards(chainIds[it], amounts[it]);
        }
    }

    /**
     * @notice Pause contract: freeze its exposed API.
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @notice Unpause contract.
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @notice Deposit main token on the rewards fund.
     * @param amount amount to deposit
     */
    function depositFunds(uint256 amount) public whenNotPaused {
        depositedRewardFunds += amount = _strictTransferFrom(_msgSender(), rewardsToken, amount);
        emit DepositFunds(amount);
    }

    /**
     * @notice Filter from a set of pool ids the ones never used to create a pool.
     * @param poolIds set of pool ids
     */
    function filterPoolIdsIdle(bytes32[] calldata poolIds) external view returns (bytes32[] memory poolIdsIdle) {
        poolIdsIdle = new bytes32[](poolIds.length);
        uint256 count;
        for (uint256 it; it < poolIds.length; ++it) {
            if (_isPoolOwner(address(0), poolIds[it])) {
                poolIdsIdle[count++] = poolIds[it];
            }
        }
        count = poolIds.length - count;
        assembly {
            mstore(poolIdsIdle, sub(mload(poolIdsIdle), count))
        }
    }

    /**
     * @notice Get deferred balance of account on a pool as observed at current epoch.
     * @param member account to query for
     * @param poolId id of the pool
     */
    function getMemberBalance(address member, bytes32 poolId) external view returns (DeferredDeposit memory) {
        return _loadCurrentBalance(poolsArchive[poolId].members[member].deposited);
    }

    /**
     * @notice Get amount of specific currency deposited by an account on a pool.
     * @param member account to query for
     * @param poolId id of the pool
     * @param erc20 type of token to filter on
     */
    function getMemberCurrency(
        address member,
        bytes32 poolId,
        IERC20Upgradeable erc20
    ) external view returns (uint256) {
        return poolsArchive[poolId].members[member].currencies[erc20];
    }

    /**
     * @notice Get withdraw request of an account on a pool.
     * @param member account to query for
     * @param poolId id of the pool
     */
    function getMemberWithdrawRequest(address member, bytes32 poolId) external view returns (WithdrawRequest memory) {
        return poolsArchive[poolId].members[member].withdrawRequest;
    }

    /**
     * @notice Create a staking pool along with its initial configuration by
     * depositing multiple amounts of supported tokens.
     * @dev Reverts on insufficient balance for minimum requirement or already created pool of same id
     * @param mbr_ packed owner account + list of amounts of each token + id of new pool
     * @param beneficiary recipient of rewards produced for owner
     * @param commissionFee percent fee charged by owner from delegators rewards
     */
    function createNewPool(
        MoveBalanceRequest memory mbr_,
        address beneficiary,
        uint16 commissionFee
    ) external override onlyRole(NODE_MANAGER_ROLE) payPoolOpFee(mbr_.poolId) {
        // `owner` acts as a proxy for pool creation
        require(_isPoolOwner(address(0), mbr_.poolId), "createNewPool: already used pool id");
        // assign owner before bonding pledge to pool
        poolsArchive[mbr_.poolId].owner = mbr_.member;

        _strictTransferFrom(mbr_);
        _moveMemberBalance(mbr_, MoveBalanceDirection.INTO);

        // pool requires finalization from next epoch onwards
        ++nextEpochPoolCount;

        emit CreateNewPool(mbr_.member, mbr_.poolId, mbr_.currencies);

        // emit params config events after the pool creation one
        _setPoolBeneficiary(mbr_.poolId, beneficiary);
        _setPoolCommission(mbr_.poolId, commissionFee);
    }

    /**
     * @dev Modifier that checks if the caller is pool`s owner.
     */
    modifier onlyPoolOwner(bytes32 poolId) {
        require(_isPoolOwner(_msgSender(), poolId), "caller is not the pool owner");
        _;
    }

    /**
     * @dev Returns whether an account is the pool`s owner.
     */
    function _isPoolOwner(address account, bytes32 poolId) private view returns (bool) {
        return account == poolsArchive[poolId].owner;
    }

    /**
     * @notice Set commission fee for a pool as its owner.
     * @dev Cannot set commission more often that `POOL_FEE_COOLDOWN` epochs
     * @param poolId id of the pool
     * @param commission new value of the fee
     */
    function setPoolCommission(bytes32 poolId, uint16 commission) external onlyPoolOwner(poolId) payPoolOpFee(poolId) {
        require(
            currentEpoch >= poolsArchive[poolId].commissionFeeEpochSet + getConfig(POOL_FEE_COOLDOWN),
            "cannot change pool commission fee yet"
        );
        _setPoolCommission(poolId, commission);
    }

    /**
     * @dev Set commission fee for a pool as its owner.
     * @param poolId id of the pool
     * @param commission new value of the fee
     */
    function _setPoolCommission(bytes32 poolId, uint16 commission) private {
        require(commission >= MIN_POOL_FEE && commission <= MAX_PPM, "fee out of bounds");
        poolsArchive[poolId].commissionFee = commission;
        poolsArchive[poolId].commissionFeeEpochSet = currentEpoch;

        emit SetPoolCommissionFee(poolId, commission);
    }

    /**
     * @notice Set beneficiary account for a pool.
     * @param poolId id of the pool
     * @param beneficiary new recipient of pool owner`s rewards
     */
    function setPoolBeneficiary(bytes32 poolId, address beneficiary)
        external
        onlyPoolOwner(poolId)
        payPoolOpFee(poolId)
    {
        // collect owner`s rewards produced under the old beneficiary
        _syncMemberRewards(poolsArchive[poolId].owner, poolId);
        _setPoolBeneficiary(poolId, beneficiary);
    }

    /**
     * @dev Set beneficiary account for a pool.
     * @param poolId id of the pool
     * @param beneficiary new recipient of pool owner`s rewards
     */
    function _setPoolBeneficiary(bytes32 poolId, address beneficiary) private {
        require(beneficiary != address(0), "zero address beneficiary");
        poolsArchive[poolId].beneficiary = beneficiary;

        emit SetPoolBeneficiary(poolId, beneficiary);
    }

    /**
     * @notice Returns whether a pool has been terminated (irreversible operation).
     * @dev Once `pledged` amount becomes zero it can never be increased.
     * @param poolId id of the pool
     */
    function isPoolOperative(bytes32 poolId) public view returns (bool) {
        return poolsArchive[poolId].pledged.nextEpochBalance > 0;
    }

    /**
     * @notice Returns whether a pool is currently jailed.
     * @param poolId id of the pool
     */
    function isPoolJailed(bytes32 poolId) public view returns (bool) {
        return currentEpoch < poolsArchive[poolId].jailedToEpoch;
    }

    /**
     * @notice Returns whether a pool is fully operational or terminated/jailed.
     * @param poolId id of the pool
     */
    function _poolNotSuspended(bytes32 poolId) private view returns (bool) {
        return isPoolOperative(poolId) && !isPoolJailed(poolId);
    }

    /**
     * @dev Move into a pool multiple amounts of different tokens already
     * deposited on the protocol by an account.
     * @param mbr_ packed account + list of amounts of each token + sink pool
     */
    function _delegate(MoveBalanceRequest memory mbr_) private {
        require(_poolNotSuspended(mbr_.poolId), "_delegate: only deposit to non-suspended pools");
        _moveMemberBalance(mbr_, MoveBalanceDirection.INTO);
    }

    /**
     * @notice Delegate to an operative pool multiple amounts of supported tokens.
     * @dev Reverts on pool not operative or insufficient delegation's balance.
     * @dev Regular delegators can only delegate main token.
     * @param mbr_ packed source account + list of amounts of each token + sink pool
     */
    function delegate(MoveBalanceRequest memory mbr_) external payPoolOpFee(mbr_.poolId) {
        mbr_.member = _msgSender();
        _strictTransferFrom(mbr_);
        _delegate(mbr_);
        require(
            (mbr_.currencies.length == 1 && mbr_.currencies[0].erc20 == rewardsToken) ||
                _isPoolOwner(mbr_.member, mbr_.poolId),
            "delegate: delegators can only deposit main token"
        );

        emit Delegate(mbr_.member, mbr_.poolId, mbr_.currencies);
    }

    /**
     * @dev Move out of a pool multiple amounts of different tokens owned by an account.
     * @dev Reverts on insufficient delegation's balance for minimum requirement.
     * @param mbr_ packed account + list of amounts of each token + source pool
     */
    function _undelegate(MoveBalanceRequest memory mbr_) private returns (uint256) {
        return _moveMemberBalance(mbr_, MoveBalanceDirection.OUT);
    }

    /**
     * @notice Undelegate from a pool multiple amounts of supported tokens.
     * @dev In case owner extracts its entire balance the pool is terminated.
     * @dev Owner cannot undelegate if pool is marked as jailed.
     * @dev Only one withdraw request can exist at a time.
     * @param mbr_ packed account + list of amounts of each token + source pool
     */
    function undelegate(MoveBalanceRequest memory mbr_)
        external
        override
        onlyRole(NODE_MANAGER_ROLE)
        payPoolOpFee(mbr_.poolId)
        returns (bool poolDeleted)
    {
        poolDeleted = _isPoolOwner(mbr_.member, mbr_.poolId);
        // cannot undelegate as owner if pool is jailed
        require(!(poolDeleted && isPoolJailed(mbr_.poolId)), "undelegate: should unjail pool");

        // ensure `_undelegate` not disabled by short-circuit evaluation
        poolDeleted = (_undelegate(mbr_) == 0) && poolDeleted;
        // pledged balance != 0 acts as a proxy for pool liveness
        if (poolDeleted) {
            // pool does not require finalization from next epoch onwards
            --nextEpochPoolCount;
            // remember last epoch of cumulative rewards that will ever be set
            lastStoredCRwd[mbr_.poolId] = currentEpoch + 1;
        }
        _createWithdrawRequest(poolsArchive[mbr_.poolId].members[mbr_.member].withdrawRequest, mbr_);

        emit Undelegate(mbr_.member, mbr_.poolId, mbr_.currencies);
    }

    /**
     * @notice Redelegate from a suspended (terminated or jailed) pool to another one.
     * @dev Owner cannot redelegate from its pool.
     * @param mbr_ packed source account + list of amounts of each token + source pool
     * @param toPool sink pool to delegate to
     */
    function redelegate(MoveBalanceRequest memory mbr_, bytes32 toPool) external payPoolOpFee(toPool) {
        mbr_.member = _msgSender();
        require(!_poolNotSuspended(mbr_.poolId), "redelegate: source pool !suspended");
        require(!_isPoolOwner(mbr_.member, mbr_.poolId), "redelegate: !delegator");

        _undelegate(mbr_);
        (mbr_.poolId, toPool) = (toPool, mbr_.poolId);
        _delegate(mbr_);

        emit Redelegate(mbr_.member, toPool, mbr_.poolId, mbr_.currencies);
    }

    /**
     * @notice Jail a pool explicitly.
     * @dev Pool will not produce rewards or accept delegations from now on.
     * @param poolId id of the pool to jail
     */
    function jail(bytes32 poolId) external whenNotPaused onlyRole(JAILER_ROLE) {
        require(!isPoolJailed(poolId), "jail: pool is already jailed");
        poolsArchive[poolId].jailedToEpoch = type(uint64).max;

        emit JailPool(poolId);
    }

    /**
     * @notice Unjail a pool by paying a fixed fee in main tokens.
     * @dev Pool will produce rewards starting next epoch and accept delegations from now on.
     * @param poolId id of the pool to unjail
     */
    function unjail(bytes32 poolId) external payPoolOpFee(poolId) {
        require(isPoolJailed(poolId), "unjail: pool is not jailed");

        // collect the unjailing fee
        if (!hasRole(JAILER_ROLE, _msgSender())) {
            depositFunds(getConfig(POOL_UNJAIL_FEE));
        }
        poolsArchive[poolId].jailedToEpoch = currentEpoch;

        emit UnjailPool(poolId);
    }

    /**
     * @dev Fill up a withdraw object with a fresh request and set its execution timestamp.
     * @param withdrawObj storage pointer to withdraw object to populate
     * @param mbr_ packed withdrawer account + list of amounts of each token
     */
    function _createWithdrawRequest(WithdrawRequest storage withdrawObj, MoveBalanceRequest memory mbr_) private {
        require(withdrawObj.currencies.length == 0, "_createWithdrawRequest: existing pending request");
        for (uint256 it; it < mbr_.currencies.length; ++it) {
            withdrawObj.currencies.push(mbr_.currencies[it]);
        }
        withdrawObj.executeTime = getEpochEarliestEndTime() + getConfig(WITHDRAW_LOCK_TIME);
    }

    /**
     * @dev Clear up the pending withdraw request of an account on a pool and
     * delegate the embedded tokens back to another pool.
     * @param member owner of the withdraw request
     * @param fromPool withdrawal`s host pool
     * @param toPool sink pool to delegate to
     */
    function _cancelWithdrawRequest(
        address member,
        bytes32 fromPool,
        bytes32 toPool
    ) private {
        WithdrawRequest storage withdrawObj = poolsArchive[fromPool].members[member].withdrawRequest;
        require(withdrawObj.currencies.length > 0, "_cancelWithdrawRequest: no pending request");

        _delegate(MoveBalanceRequest(member, toPool, withdrawObj.currencies, 0));
        delete withdrawObj.currencies;

        emit WithdrawRequestCancelled(member, fromPool, toPool);
    }

    /**
     * @notice Cancel a pending withdraw request on a suspended pool and
     * redelegate it to another one.
     * @dev Owner cannot cancel withdraw and redelegate it from its pool.
     * @param fromPool withdrawal`s host pool
     * @param toPool sink pool to delegate to
     */
    function cancelAndRedelegateWithdrawRequest(bytes32 fromPool, bytes32 toPool) external payPoolOpFee(toPool) {
        require(!_poolNotSuspended(fromPool), "cancelAndRedelegateWithdraw: source pool !suspended");
        require(!_isPoolOwner(_msgSender(), fromPool), "cancelAndRedelegateWithdraw: !delegator");
        _cancelWithdrawRequest(_msgSender(), fromPool, toPool);
    }

    /**
     * @notice Cancel a pending withdraw request on a pool and restore (delegate) its tokens back.
     * @param poolId withdrawal`s host pool
     */
    function cancelWithdrawRequest(bytes32 poolId) external payPoolOpFee(poolId) {
        _cancelWithdrawRequest(_msgSender(), poolId, poolId);
    }

    /**
     * @notice Execute a pending withdraw request once its thawing period is over and
     * transfer the tokens back to their owner.
     * @param poolId withdrawal`s host pool
     */
    function executeWithdrawRequest(bytes32 poolId) external payPoolOpFee(poolId) {
        WithdrawRequest storage withdrawObj = poolsArchive[poolId].members[_msgSender()].withdrawRequest;
        require(withdrawObj.currencies.length > 0, "executeWithdrawRequest: no pending request");
        require(
            withdrawObj.executeTime <= block.timestamp,
            "executeWithdrawRequest: unlocking period has not expired yet"
        );

        CurrencyAmount[] memory currencies = withdrawObj.currencies;
        for (uint256 it; it < currencies.length; ++it) {
            _strictTransferTo(_msgSender(), currencies[it]);
        }
        delete withdrawObj.currencies;

        emit WithdrawRequestExecuted(_msgSender(), poolId);
    }

    /**
     * @notice Claim all rewards collected already as well as produced over a set of pools
     * either as a regular delegator or pool`s beneficiary.
     * @dev Pools commission fees are already collected on finalizations.
     * @param poolIds list of pools to collect member-rewards from
     * @param source whether to use rewards gained as delegator or beneficiary
     */
    function claim(bytes32[] calldata poolIds, RewardSrc source) external {
        // collect member rewards for caller from provided pools
        syncMemberRewards(poolIds, _msgSender(), source);

        (, uint256 unclaimed) = unclaimedRewards[_msgSender()][source].trySub(1);
        // optimization: ensure rewards accumulator never goes free
        unclaimedRewards[_msgSender()][source] = 1;

        _strictTransferTo(_msgSender(), CurrencyAmount(rewardsToken, unclaimed));

        emit Claim(_msgSender(), source, unclaimed);
    }

    /**
     * @notice Restake to a specific pool some amount out of the
     * rewards collected already as well as produced over a set of pools.
     * @param poolIds list of pools to collect member-rewards from
     * @param source whether to use rewards gained as delegator or beneficiary
     * @param toPool id of the pool to delegate to
     * @param amount amount to restake
     */
    function restake(
        bytes32[] calldata poolIds,
        RewardSrc source,
        bytes32 toPool,
        uint256 amount
    ) external {
        require(amount > 0, "!amount to restake");
        syncMemberRewards(poolIds, _msgSender(), source);

        uint256 unclaimed = unclaimedRewards[_msgSender()][source];
        unchecked {
            if (unclaimed.sub(amount, "!enough rewards synced for restake") == 0) {
                // optimization: ensure rewards accumulator never goes free
                amount -= 1;
            }
            unclaimedRewards[_msgSender()][source] = unclaimed - amount;
        }

        MoveBalanceRequest memory mbr_ = MoveBalanceRequest(_msgSender(), toPool, new CurrencyAmount[](1), amount);
        mbr_.currencies[0] = CurrencyAmount(rewardsToken, amount);
        _delegate(mbr_);

        emit Restake(_msgSender(), source, toPool, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./IMoveBalanceStructs.sol";

interface IPoolCreator is IMoveBalanceStructs {
    function createNewPool(
        MoveBalanceRequest memory mbr_,
        address beneficiary,
        uint16 commissionFee
    ) external;

    function undelegate(MoveBalanceRequest memory mbr_) external returns (bool poolDeleted);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./TransfersAdapter.sol";

abstract contract DelegationsAdapter is TransfersAdapter {
    using SafeMathUpgradeable for uint256;

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow with a custom error message.
     * @dev Defined for avoiding name clashes when importing from `SafeMathUpgradeable`
     */
    function subCurrency(uint256 a, uint256 b) private pure returns (uint256) {
        (bool success, uint256 res) = a.trySub(b);
        require(success, "insufficient currency for move request");
        return res;
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow with a custom error message.
     */
    function addCurrency(uint256 a, uint256 b) private pure returns (uint256) {
        (bool success, uint256 res) = a.tryAdd(b);
        require(success, "overflow for currency on move request");
        return res;
    }

    /**
     * @dev Update individual currency balances deposited on a pool by an account.
     * @param mbr_ packed account + list of deltas for each token + targeted pool
     * @param changeCurrencyFn mathematical operation to apply
     */
    function _changeCurrencyAmount(
        MoveBalanceRequest memory mbr_,
        function(uint256, uint256) returns (uint256) changeCurrencyFn
    ) private {
        require(mbr_.currencies.length > 0, "_changeCurrencyAmount: no currency supplied");
        mbr_.moved = 0;
        address prevCurrency;
        Delegation storage delegationObj = poolsArchive[mbr_.poolId].members[mbr_.member];

        for (uint256 it; it < mbr_.currencies.length; ++it) {
            CurrencyAmount memory ca_ = mbr_.currencies[it];
            require(ca_.amount > 0, "_changeCurrencyAmount: zero amount currency");

            require(address(ca_.erc20) > prevCurrency, "_changeCurrencyAmount: unordered or duplicated currencies");
            prevCurrency = address(ca_.erc20);

            mbr_.moved += ca_.amount;
            delegationObj.currencies[ca_.erc20] = changeCurrencyFn(delegationObj.currencies[ca_.erc20], ca_.amount);
        }
    }

    /**
     * @dev Update total deferred balance deposited on a pool by an account.
     * @param mbr_ packed account + currency-agnostic delta for balance + targeted pool
     * @param changeDepositFn deferred mathematical operation to apply
     */
    function _changeMemberBalance(
        MoveBalanceRequest memory mbr_,
        function(DeferredDeposit storage, uint256) returns (uint256) changeDepositFn
    ) private returns (uint256 deposited) {
        // collect pending member rewards produced under the old balance
        _syncMemberRewards(mbr_.member, mbr_.poolId);

        // update the deferred balance of the delegation itself
        Pool storage poolObj = poolsArchive[mbr_.poolId];
        deposited = changeDepositFn(poolObj.members[mbr_.member].deposited, mbr_.moved);

        // check that required deposit amount is preserved
        require(
            (deposited == 0) ||
                (deposited >= getConfig(mbr_.member == poolObj.owner ? LEAST_PLEDGE_AMT : LEAST_DELEGATE_AMT)),
            "_changeMemberBalance: !preserve required deposit amount"
        );

        // update the deferred pledged and total-deposited balances of the pool
        if (mbr_.member == poolObj.owner) {
            changeDepositFn(poolObj.pledged, mbr_.moved);
        }
        changeDepositFn(poolObj.deposited, mbr_.moved);

        // update the deferred balance of total-deposited on the protocol
        changeDepositFn(depositedTotal, mbr_.moved);
    }

    /**
     * @dev Move into/out of pool multiple amounts of different tokens owned by an account.
     * @param mbr_ packed account + list of amounts of each token + targeted pool
     * @param direction whether to insert/extract currencies
     */
    function _moveMemberBalance(MoveBalanceRequest memory mbr_, MoveBalanceDirection direction)
        internal
        returns (uint256 deposited)
    {
        if (direction == MoveBalanceDirection.INTO) {
            _changeCurrencyAmount(mbr_, addCurrency);
            deposited = _changeMemberBalance(mbr_, _increaseNextBalance);
        } else if (direction == MoveBalanceDirection.OUT) {
            _changeCurrencyAmount(mbr_, subCurrency);
            deposited = _changeMemberBalance(mbr_, _decreaseNextBalance);
        }
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

interface IMoveBalanceStructs {
    /**
     * @dev Individual request for a balance displacement.
     * @param member account owning the balance
     * @param poolId destination or source pool of the tokens
     * @param currencies list of amounts for each currency to be moved
     * @param moved total amount moved over all currencies
     */
    struct MoveBalanceRequest {
        address member;
        bytes32 poolId;
        CurrencyAmount[] currencies;
        uint256 moved;
    }

    /**
     * @dev Encapsulates an amount of a specific currency token.
     * @param erc20 address of the token
     * @param amount amount of tokens
     */
    struct CurrencyAmount {
        IERC20Upgradeable erc20;
        uint256 amount;
    }

    /**
     * @dev displacement directions for a `MoveBalanceRequest`
     */
    enum MoveBalanceDirection {
        INTO,
        OUT
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../rewards/MemberRewardsAdapter.sol";
import "../../libraries/ERC20Utils.sol";

abstract contract TransfersAdapter is MemberRewardsAdapter {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * @dev States of currency tokens used for deposits.
     */
    enum CurrencySupport {
        INEXISTENT,
        OPERATIVE,
        DEPRECATED
    }

    /// @notice set of ERC20 tokens supported for staking
    mapping(IERC20Upgradeable => CurrencySupport) public currencySupport;

    /**
     * @dev Emitted when setting support-level of token `erc20` to `state`.
     */
    event SetCurrencySupport(IERC20Upgradeable indexed erc20, CurrencySupport indexed state);

    /**
     * @notice Configure the support-level for an ERC20 token.
     * @param erc20 token to configure for
     * @param state new support state for the token
     */
    function setCurrencySupport(IERC20Upgradeable erc20, CurrencySupport state) external onlyRole(OWNER_ROLE) {
        require(
            IERC20MetadataUpgradeable(address(erc20)).decimals() == STRICT_TOKEN_DECIMALS,
            "!constant denomination"
        );
        currencySupport[erc20] = state;
        emit SetCurrencySupport(erc20, state);
    }

    /**
     * @dev Transfer custom amount of a supported token from this contract to an account.
     * @param account address to transfer to
     * @param ca_ packed token address and amount
     */
    function _strictTransferTo(address account, CurrencyAmount memory ca_) internal {
        require(currencySupport[ca_.erc20] != CurrencySupport.INEXISTENT, "_strictTransferTo: currency not supported");
        // do not call unknown erc20: zero amount signals token might never been supported before
        if (ca_.amount > 0) {
            ca_.erc20.safeTransfer(account, ca_.amount);
        }
    }

    /**
     * @dev Transfer custom amount of operative token from an account into this contract.
     * @param account address to transfer from
     * @param erc20 token to transfer
     * @param amount amount of tokens
     */
    function _strictTransferFrom(
        address account,
        IERC20Upgradeable erc20,
        uint256 amount
    ) internal returns (uint256) {
        require(currencySupport[erc20] == CurrencySupport.OPERATIVE, "_strictTransferFrom: currency not supported");
        return ERC20Utils.strictTransferFrom(erc20, account, address(this), amount);
    }

    /**
     * @dev Transfer multiple amounts of operative tokens from an account into this contract.
     * @param mbr_ packed source account + list of amounts of each token
     */
    function _strictTransferFrom(MoveBalanceRequest memory mbr_) internal {
        for (uint256 it; it < mbr_.currencies.length; ++it) {
            mbr_.currencies[it].amount = _strictTransferFrom(
                mbr_.member,
                mbr_.currencies[it].erc20,
                mbr_.currencies[it].amount
            );
        }
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

library ERC20Utils {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * @notice Some tokens may use an internal fee and reduce the absolute amount that was deposited.
     * This method calculates that fee and returns the real amount of deposited tokens.
     */
    function strictTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal returns (uint256 finalValue) {
        uint256 balanceBefore = token.balanceOf(to);
        token.safeTransferFrom(from, to, value);
        finalValue = token.balanceOf(to) - balanceBefore;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./Finalizer.sol";

abstract contract MemberRewardsAdapter is Finalizer {
    using MathUpgradeable for uint256;

    /// @dev last allocated slot on `poolCumulativeReward` per pool
    mapping(bytes32 => uint256) private lastAllocatedCRwd;

    /// @dev last stored slot on `poolCumulativeReward` per pool (recorded once at pool deletion)
    mapping(bytes32 => uint256) internal lastStoredCRwd;

    /**
     * @dev Emitted when `collectedAmt` of rewards produced on `poolId`
     * up to epoch `collectedTo` are collected on behalf of `member`.
     */
    event CollectMemberRewards(
        address indexed member,
        bytes32 indexed poolId,
        uint256 collectedAmt,
        uint256 collectedTo
    );

    /**
     * @dev Modifier enforcing the pay-off on pool operation as storage allocations.
     */
    modifier payPoolOpFee(bytes32 poolId) {
        _payPoolOpFee(poolId);
        _;
    }

    /**
     * @dev Allocate `POOL_OP_COST` slots on `poolCumulativeReward` sequently
     * from latest allocated/finalized epoch onwards.
     * @param poolId id of the pool to allocate for
     */
    function _payPoolOpFee(bytes32 poolId) private whenNotPaused {
        uint256 from = lastAllocatedCRwd[poolId];
        if (from == 0) {
            // this operation is a pool creation one
            from = currentEpoch + 1;
        }
        from = from.max(_getMostRecentCRwdEpoch(poolId)) + 1;
        uint256 to = (from + POOL_OP_COST).min(type(uint64).max);
        for (; from < to; ++from) {
            poolCumulativeReward[poolId][from].atEpoch = uint64(from + 1);
        }
        lastAllocatedCRwd[poolId] = from - 1;
    }

    /**
     * @dev Check whether the pool cumulative rewards have been set on given epoch.
     * @param cr_ cumulative rewards object
     * @param epoch_ direct-lookup epoch index
     */
    function _isCumulativeRewardSet(CumulativeReward memory cr_, uint64 epoch_) private pure returns (bool) {
        // `atEpoch` is being set to `epoch_` + 1 when slot `epoch_` is allocated on a pool-operation fee
        return epoch_ > 0 && cr_.atEpoch == epoch_;
    }

    function _isCumulativeRewardSet(bytes32 poolId, uint64 epoch_) private view returns (bool) {
        return _isCumulativeRewardSet(poolCumulativeReward[poolId][epoch_], epoch_);
    }

    /**
     * @dev Get latest finalized epoch of an operative pool.
     * @dev If pool deleted or not operative yet return previous epoch index.
     * @param poolId pool id
     */
    function _getMostRecentCRwdEpoch(bytes32 poolId) private view returns (uint64 epoch_) {
        epoch_ = currentEpoch;
        if (!_isCumulativeRewardSet(poolId, epoch_)) {
            epoch_ -= 1;
        }
    }

    /**
     * @dev Get cumulative reward produced by a pool up to a given epoch.
     * @dev Invariant: each pool is finalized every epoch since creation,
     * otherwise would be required to store last finalization.
     * @param poolId pool id
     * @param epoch_ epoch index to query for
     */
    function _getCRwdAtEpoch(bytes32 poolId, uint64 epoch_) private view returns (uint128) {
        // going backwards check if pool finalized at `epoch_`
        CumulativeReward memory cr_ = poolCumulativeReward[poolId][epoch_];
        if (_isCumulativeRewardSet(cr_, epoch_)) {
            return cr_.rewardRatio;
        }

        // otherwise pool must have been finalized at `epoch_ - 1`
        cr_ = poolCumulativeReward[poolId][epoch_ - 1];
        if (_isCumulativeRewardSet(cr_, epoch_ - 1)) {
            return cr_.rewardRatio;
        }

        // otherwise pool must have been deleted some epochs back
        uint64 mostRecentEpoch = SafeCastUpgradeable.toUint64(lastStoredCRwd[poolId]);
        if (mostRecentEpoch < epoch_) {
            cr_ = poolCumulativeReward[poolId][mostRecentEpoch];
            if (_isCumulativeRewardSet(cr_, mostRecentEpoch)) {
                return cr_.rewardRatio;
            }
        }

        // or pool has never been operative (nor finalized) by `epoch_` inclusively
        return 0;
    }

    /**
     * @dev Compute member-reward produced over epochs [beginEpoch, endEpoch)
     * @param poolId pool id
     * @param memberBalanceOverInterval constant balance of member over epochs interval
     * @param beginEpoch inclusive start epoch
     * @param endEpoch exclusive end epoch
     */
    function _computeMemberRewardOverInterval(
        bytes32 poolId,
        uint256 memberBalanceOverInterval,
        uint64 beginEpoch,
        uint64 endEpoch
    ) private view returns (uint256 memberReward) {
        // skip computation when no rewards produced
        if (memberBalanceOverInterval == 0 || beginEpoch == endEpoch) {
            return 0;
        }

        // sanity check interval
        require(beginEpoch < endEpoch, "invalid CRwd interval");

        // compute member reward
        memberReward = _getCRwdAtEpoch(poolId, endEpoch) - _getCRwdAtEpoch(poolId, beginEpoch);
        memberReward = (memberReward * memberBalanceOverInterval) / ONE_TOKEN_UNITS;
    }

    /**
     * @notice Compute amount of uncollected member-reward of an account
     * produced over a set of owned delegations.
     * @param member account to compute for
     * @param poolIds list of pools to aggregate account`s rewards from
     */
    function computeMemberReward(address member, bytes32[] calldata poolIds)
        external
        view
        returns (uint256 memberReward)
    {
        for (uint256 it; it < poolIds.length; ++it) {
            memberReward += _computeMemberReward(poolsArchive[poolIds[it]].members[member].deposited, poolIds[it]);
        }
    }

    /**
     * @dev Compute member-reward produced by a delegation since latest collect and up to
     * latest finalization of its pool (`collectedEpoch`, `currentEpoch(-1)`]
     * @param memberDeposit storage pointer to delegation`s deposit
     * @param poolId id of the delegation`s host pool
     */
    function _computeMemberReward(DeferredDeposit storage memberDeposit, bytes32 poolId)
        private
        view
        returns (uint256 memberReward)
    {
        // invariant: `memberEpoch` <= `currentEpoch`
        uint64 memberEpoch_ = memberDeposit.currentEpoch;
        // invariant: `collectedEpoch` == `memberEpoch` or `memberEpoch - 1` in case pool
        // not finalized for previous epoch at the latest deposit update
        uint64 collectedEpoch_ = memberDeposit.collectedEpoch;

        // reward has been collected completely up to present epoch
        uint64 currentEpoch_ = currentEpoch;
        if (collectedEpoch_ == currentEpoch_) {
            return 0;
        }

        // earned in epoch `memberEpoch - 1` but not finalized at that point
        memberReward = _computeMemberRewardOverInterval(
            poolId,
            memberDeposit.prevEpochBalance, // balance over epoch previous to latest deposit update
            collectedEpoch_,
            memberEpoch_
        );

        // already collected prior rewards possibly excluding the ones to be finalized this epoch
        if (memberEpoch_ == currentEpoch_) {
            return memberReward;
        }

        // earned in epoch `memberEpoch` under `currentEpochBalance`
        memberReward += _computeMemberRewardOverInterval(
            poolId,
            memberDeposit.currentEpochBalance,
            memberEpoch_, // last update of the delegation
            memberEpoch_ + 1 // from this epoch balance has been `nextEpochBalance`
        );

        // earned in epochs [`memberEpoch + 1` .. `currentEpoch`) under `nextEpochBalance`
        memberReward += _computeMemberRewardOverInterval(
            poolId,
            memberDeposit.nextEpochBalance,
            memberEpoch_ + 1, // first epoch when member balance becomes `nextEpochBalance`
            currentEpoch_ // and remains constant up until current epoch
        );
    }

    /**
     * @dev Gather uncollected member-reward of a delegation to its owner`s accumulator and record this operation.
     * @param member account to collect for
     * @param poolId delegation`s host pool
     */
    function _syncMemberRewards(address member, bytes32 poolId) internal {
        Pool storage poolObj = poolsArchive[poolId];
        DeferredDeposit storage memberDeposit = poolObj.members[member].deposited;

        uint256 toCollect = _computeMemberReward(memberDeposit, poolId);
        if (member == poolObj.owner) {
            unclaimedRewards[poolObj.beneficiary][RewardSrc.POOL_OWNERSHIP] += toCollect;
        } else {
            unclaimedRewards[member][RewardSrc.REGULAR_DELEGATOR] += toCollect;
        }

        // record how far member rewards could be collected
        memberDeposit.collectedEpoch = _getMostRecentCRwdEpoch(poolId);
        // shift member balance to current epoch
        _storeBalance(memberDeposit, _loadCurrentBalance(memberDeposit));

        emit CollectMemberRewards(member, poolId, toCollect, memberDeposit.collectedEpoch);
    }

    /**
     * @notice Collect finalized member-reward produced over a set of pools either as
     * a regular delegator or pool`s beneficiary.
     * @param poolIds list of pools to collect from
     * @param account account to collect for
     * @param source whether to consider delegator/beneficiary case
     */
    function syncMemberRewards(
        bytes32[] calldata poolIds,
        address account,
        RewardSrc source
    ) public whenNotPaused {
        for (uint256 it; it < poolIds.length; ++it) {
            // collect member rewards to pool beneficiary or as regular delegator
            _syncMemberRewards(
                source == RewardSrc.POOL_OWNERSHIP ? poolsArchive[poolIds[it]].owner : account,
                poolIds[it]
            );
        }
    }

    uint256[48] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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
interface IERC20PermitUpgradeable {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../StakingStorage.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

abstract contract Finalizer is StakingStorage, AccessControlUpgradeable, PausableUpgradeable {
    using MathUpgradeable for uint256;

    /// @notice reserve of `rewardsToken` allocated for protocol rewards
    uint256 public depositedRewardFunds;

    /// @dev number of operative (created and not deleted) pools at current epoch
    uint32 private currentEpochPoolCount;
    /// @dev operative pools count at next epoch
    uint32 internal nextEpochPoolCount;

    /// @notice pool cumulative rewards at the `beginning` of each epoch
    mapping(bytes32 => mapping(uint256 => CumulativeReward)) public poolCumulativeReward;

    /// @notice unclaimed collected rewards produced by each reward-source per account
    mapping(address => mapping(RewardSrc => uint256)) public unclaimedRewards;

    /// @dev snapshot of previous epoch stats, recycled on each new epoch ended
    EpochSnapshot private prevEpochSnapshot;

    /// @notice uniform(agnostic to pool`s balances) chain rewards for pool owners
    mapping(uint256 => uint256) public chainRewards;
    /// @dev bit-mask for extracting the pool`s chain from its id
    uint256 private constant CHAIN_ID_MASK = (1 << 32) - 1;

    /**
     * @dev Cumulative reward produced by a pool up to an epoch.
     * @param atEpoch reverse-lookup of the closing epoch
     * @param rewardRatio sum of pool rewards / balance at each epoch since creation up to `atEpoch`
     */
    struct CumulativeReward {
        // if `atEpoch` != direct-lookup epoch in `poolCumulativeReward` then pool not finalized yet
        uint64 atEpoch;
        uint128 rewardRatio;
    }

    /**
     * @dev Types of reward sources for an account.
     */
    enum RewardSrc {
        POOL_OWNERSHIP,
        REGULAR_DELEGATOR
    }

    /**
     * @dev Snapshot of parameters and protocol stats used within distribution formula,
     * created at the end of an epoch and immutable over the next one.
     * @param finalizerEpoch epoch following the one to be finalized
     * @param prevEpochPoolCount number of pools to finalize for previous epoch
     * @param pledgeFactorNum pledge influence numerator
     * @param pledgeFactorDenom pledge influence denominator
     * @param saturationCap saturation capacity
     * @param prevEpochLength length of previous epoch in seconds
     * @param prevEpochRewards rewards to be distributed for previous epoch
     * @param depositedTotal tokens on protocol at previous epoch
     * @param prevEpochDistributed rewards finalized so far on current epoch for previous one
     */
    struct EpochSnapshot {
        uint64 finalizerEpoch;
        uint32 prevEpochPoolCount;
        uint16 pledgeFactorNum;
        uint16 pledgeFactorDenom;
        uint128 saturationCap;
        uint256 prevEpochLength;
        uint128 prevEpochRewards;
        uint128 depositedTotal;
        uint256 prevEpochDistributed;
    }

    /**
     * @dev Emitted when `poolId` is finalized for previous epoch of penalty
     * `performance` and producing `ownerReward` and cumulative `rewardRatio`.
     */
    event FinalizedPool(bytes32 indexed poolId, uint16 performance, uint128 rewardRatio, uint256 ownerReward);

    /**
     * @dev Emitted when `snapshot` of ended epoch`s stats has been created.
     */
    event SnapshottedEpoch(EpochSnapshot snapshot);

    /**
     * @dev Emitted when yearly chain-rewards for `chainId` pools is set to `amount`.
     */
    event SetChainRewards(uint32 indexed chainId, uint256 amount);

    /**
     * @dev Get the chain-rewards a pool would produce for its owner over a year.
     * @param poolId id of the pool
     */
    function _getChainRewards(bytes32 poolId) private view returns (uint256) {
        return chainRewards[uint256(poolId) & CHAIN_ID_MASK];
    }

    /**
     * @dev Set amount of chain-rewards gained by owners of pools of `chainId` type.
     * @param chainId blockchain type
     * @param amount rewards over a year
     */
    function _setChainRewards(uint32 chainId, uint256 amount) internal {
        require(prevEpochSnapshot.prevEpochPoolCount == 0, "!constant over previous epoch finalizations");
        chainRewards[chainId] = amount;
        emit SetChainRewards(chainId, amount);
    }

    /**
     * @dev Validate parameters of the distribution formula before snapshotting them.
     * @dev If left unchecked would lead to overflow and implicitly finalization freeze.
     */
    function _checkRewardsFormulaParams() private view {
        require(getConfig(POOL_SATURATION_CAP) != 0, "!POOL_SATURATION_CAP");
        require(getConfig(PLEDGE_INFLUENCE_DEN) != 0, "!PLEDGE_INFLUENCE_DEN");
    }

    /**
     * @dev Compute epoch rewards required to sustain the protocol`s average APY.
     * @param snapshot packed epoch`s length and deposited tokens
     */
    function _computeEpochRewards(EpochSnapshot memory snapshot) private view returns (uint256 epochRewards) {
        epochRewards = (snapshot.depositedTotal * getConfig(AVERAGE_TOKEN_APY)) / MAX_PPM;
        epochRewards = (epochRewards * snapshot.prevEpochLength) / ONE_YEAR_SEC;
        epochRewards = epochRewards.min(depositedRewardFunds);
    }

    /**
     * @notice End current epoch by snapshotting global stats required in
     * the distribution formula for pool finalizations.
     */
    function endEpoch() external whenNotPaused {
        require(prevEpochSnapshot.prevEpochPoolCount == 0, "previous epoch partially finalized");
        // validate settings before creating snapshot
        _checkRewardsFormulaParams();

        // reserve total rewards distributed for previous epoch (finalized on current one)
        depositedRewardFunds -= prevEpochSnapshot.prevEpochDistributed;

        // aggregate pool finalization common configs
        EpochSnapshot memory snapshot = EpochSnapshot(
            currentEpoch + 1,
            currentEpochPoolCount,
            SafeCastUpgradeable.toUint16(getConfig(PLEDGE_INFLUENCE_NUM)),
            SafeCastUpgradeable.toUint16(getConfig(PLEDGE_INFLUENCE_DEN)),
            SafeCastUpgradeable.toUint128(getConfig(POOL_SATURATION_CAP)),
            _goToNextEpoch(),
            0,
            SafeCastUpgradeable.toUint128(_getPreviousBalance(depositedTotal)),
            prevEpochSnapshot.prevEpochDistributed
        );
        snapshot.prevEpochRewards = SafeCastUpgradeable.toUint128(_computeEpochRewards(snapshot));
        emit SnapshottedEpoch(snapshot);

        // snapshot previous epoch metadata
        snapshot.prevEpochDistributed = 0;
        prevEpochSnapshot = snapshot;

        // update number of pools to finalize in this new epoch
        currentEpochPoolCount = nextEpochPoolCount;
    }

    /**
     * @notice Finalize multiple pools operative at the previous epoch.
     * @dev If current epoch expires the finalization of previous one becomes public and
     * no penalty is applied to pools.
     * @param poolIds list of pools to finalize
     * @param performances list of node penalties
     */
    function finalizePools(bytes32[] calldata poolIds, uint16[] calldata performances) external whenNotPaused {
        bool expiredEpoch = block.timestamp > getEpochEarliestEndTime();
        if (!expiredEpoch) _checkRole(FINALIZER_ROLE, _msgSender());

        require(poolIds.length == performances.length, "!= lengths of pools/performances");

        EpochSnapshot memory snapshot = prevEpochSnapshot;
        for (uint256 it; it < poolIds.length; ++it) {
            snapshot.prevEpochDistributed += _finalizePool(
                poolIds[it],
                expiredEpoch ? MAX_PPM : performances[it],
                snapshot
            );
        }
        prevEpochSnapshot.prevEpochDistributed = snapshot.prevEpochDistributed;
        prevEpochSnapshot.prevEpochPoolCount -= SafeCastUpgradeable.toUint32(poolIds.length);
    }

    function _requirePoolDetail(
        bool condition,
        string memory errorMessage,
        bytes32 poolId
    ) private pure {
        if (!condition)
            revert(string(abi.encodePacked(errorMessage, StringsUpgradeable.toHexString(uint256(poolId), 32))));
    }

    /**
     * @dev Finalizes a pool operative at previous epoch, distributes owner`s share
     * and records member rewards to be individually collected later.
     * @dev Invariant: each pool will be finalized sequently each epoch since creation up to deletion
     * @param poolId id of the pool to finalize
     * @param performance node penalty to apply
     * @param snapshot previous epoch stats
     */
    function _finalizePool(
        bytes32 poolId,
        uint16 performance,
        EpochSnapshot memory snapshot
    ) private returns (uint256) {
        _requirePoolDetail(performance <= MAX_PPM, "performance !% for pool:", poolId);

        Pool storage poolObj = poolsArchive[poolId];
        uint256 pledged = _getPreviousBalance(poolObj.pledged);
        uint256 delegated = _getPreviousBalance(poolObj.deposited);
        _requirePoolDetail(pledged != 0, "!operative pool:", poolId);

        CumulativeReward storage cr_ = poolCumulativeReward[poolId][snapshot.finalizerEpoch];
        _requirePoolDetail(cr_.atEpoch != snapshot.finalizerEpoch, "already finalized pool:", poolId);

        uint256 chainReward;
        uint256 membersReward;
        // if not jailed on previous epoch
        if ((snapshot.finalizerEpoch - 1) > poolObj.jailedToEpoch) {
            // compute pool share out of epoch rewards
            membersReward = _computePoolEpochRewards(pledged, delegated, snapshot);
            // compute fixed chain reward for pool operator
            chainReward = (_getChainRewards(poolId) * snapshot.prevEpochLength) / ONE_YEAR_SEC;
        }

        // apply node slashing on overall pool rewards
        chainReward = (chainReward * performance) / MAX_PPM;
        membersReward = (membersReward * performance) / MAX_PPM;

        // ensure rebate rewards are not allocated as fixed chain rewards
        chainReward = chainReward.min(depositedRewardFunds - snapshot.prevEpochRewards);
        // consume fixed chain rewards from total funds
        depositedRewardFunds -= chainReward;

        // reward the pool operator its commission fee
        uint256 ownerReward = (membersReward * poolObj.commissionFee) / MAX_PPM;
        unclaimedRewards[poolObj.beneficiary][RewardSrc.POOL_OWNERSHIP] += ownerReward + chainReward;

        // get remaining rewards for member delegations
        membersReward -= ownerReward;

        // record pool has been finalized for prev epoch and cumulative-rewards sum
        cr_.atEpoch = snapshot.finalizerEpoch;
        cr_.rewardRatio =
            poolCumulativeReward[poolId][snapshot.finalizerEpoch - 1].rewardRatio +
            SafeCastUpgradeable.toUint128((membersReward * ONE_TOKEN_UNITS) / delegated);

        emit FinalizedPool(poolId, performance, cr_.rewardRatio, ownerReward + chainReward);
        return ownerReward + membersReward;
    }

    /**
     * @dev Compute pool`s share out of total epoch rewards given the distribution
     * of token balances at that epoch.
     * @param pledged pledged amount on pool at the epoch
     * @param delegated total amount on pool at the epoch
     * @param snapshot packed epoch stats
     */
    function _computePoolEpochRewards(
        uint256 pledged,
        uint256 delegated,
        EpochSnapshot memory snapshot
    ) private pure returns (uint256 poolRewards) {
        pledged = pledged.min(snapshot.saturationCap);
        delegated = delegated.min(snapshot.saturationCap);

        poolRewards = (pledged * (snapshot.saturationCap - delegated)) / snapshot.saturationCap;
        poolRewards = (pledged * (delegated - poolRewards)) / snapshot.saturationCap;
        poolRewards = (poolRewards * snapshot.pledgeFactorNum) / snapshot.pledgeFactorDenom;
        poolRewards += delegated;
        poolRewards =
            (poolRewards * (snapshot.pledgeFactorDenom)) /
            (snapshot.pledgeFactorDenom + snapshot.pledgeFactorNum);
        poolRewards = (snapshot.prevEpochRewards * poolRewards) / snapshot.depositedTotal;
    }

    uint256[41] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./interfaces/IMoveBalanceStructs.sol";
import "./deposits/DepositsAdapter.sol";

abstract contract StakingStorage is IMoveBalanceStructs, DepositsAdapter {
    /**
     * @dev Delegation pool metadata.
     * @param owner address of the pool creator
     * @param beneficiary optional destination for owner`s rewards
     * @param jailedToEpoch inclusive epoch until which pool is jailed
     * @param commissionFee share of pool`s rewards paid to its owner
     * @param commissionFeeEpochSet last epoch when commission fee has been set
     * @param pledged owner`s balance (stored to optimize pool finalizations)
     * @param deposited total balance on pool: delegated by owner + others
     * @param members set of delegations indexed by delegator address
     */
    struct Pool {
        address owner;
        address beneficiary;
        uint64 jailedToEpoch;
        uint16 commissionFee;
        uint64 commissionFeeEpochSet;
        DeferredDeposit pledged;
        DeferredDeposit deposited;
        mapping(address => Delegation) members;
    }

    /**
     * @dev Individual delegation metadata.
     * @param deposited balance deposited by the delegator
     * @param withdrawRequest saved withdraw request waiting to be executed or cancelled
     * @param currencies amount of each constituent currency summing up to `deposited`
     */
    struct Delegation {
        DeferredDeposit deposited;
        WithdrawRequest withdrawRequest;
        mapping(IERC20Upgradeable => uint256) currencies;
    }

    /**
     * @dev Individual withdraw request for a delegation balance.
     * @param executeTime timestamp when delegator can execute request
     * @param currencies list of amounts of each token to be withdrawn
     */
    struct WithdrawRequest {
        uint256 executeTime;
        CurrencyAmount[] currencies;
    }

    /// @notice data of all pools by id
    mapping(bytes32 => Pool) public poolsArchive;

    /// @notice balance deposited globally over all pools and containing delegations
    DeferredDeposit public depositedTotal;

    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../epochs/StakingEpochManager.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

abstract contract DepositsAdapter is StakingEpochManager {
    /**
     * @dev Encapsulates a deposit of tokens capable of postponing
     * balance updates to the epoch following the one when changes occurred.
     * @dev `currentEpoch` < current global epoch means the deposit has been stalled for
     * some epoch(s) already and its observed balance should be `nextEpochBalance`.
     * @param currentEpoch epoch at latest balance change
     * @param collectedEpoch epoch by which member-rewards have been sequently collected
     * @param currentEpochBalance operative balance at epoch `currentEpoch`
     * @param nextEpochBalance balance applying on epochs following `currentEpoch`
     * @param prevEpochBalance operative balance at previous epoch of `currentEpoch`
     */
    struct DeferredDeposit {
        // pack `epoch` with `next` in same slot as deposits are expected to be often stalled
        uint64 currentEpoch;
        uint64 collectedEpoch;
        // invariant: `nextEpochBalance` == amount of tokens actually on the deposit now
        uint128 nextEpochBalance;
        uint128 currentEpochBalance;
        uint128 prevEpochBalance;
    }

    /**
     * @dev Loads deposit with all postponed changes applied for current-epoch view.
     * @param balancePtr storage pointer to deposit
     */
    function _loadCurrentBalance(DeferredDeposit storage balancePtr)
        internal
        view
        returns (DeferredDeposit memory balance)
    {
        balance = balancePtr;
        uint64 currentEpoch_ = currentEpoch;
        if (currentEpoch_ > balance.currentEpoch) {
            // only one advanced epoch means `prev` will become `current` otherwise `next`
            balance.prevEpochBalance = currentEpoch_ > balance.currentEpoch + 1
                ? balance.nextEpochBalance
                : balance.currentEpochBalance;
            balance.currentEpochBalance = balance.nextEpochBalance;
            balance.currentEpoch = currentEpoch_;
        }
        return balance;
    }

    /**
     * @dev Get operative balance of deposit at previous epoch.
     * @dev Optimized version of `_loadCurrentBalance` for accessing `prev` only.
     * @dev Only used on pool finalization to get protocol stats at previous epoch.
     * @param balancePtr storage pointer to deposit
     */
    function _getPreviousBalance(DeferredDeposit storage balancePtr) internal view returns (uint256) {
        uint64 currentEpoch_ = currentEpoch;
        uint64 balanceEpoch_ = balancePtr.currentEpoch;
        if (currentEpoch_ == balanceEpoch_) {
            return balancePtr.prevEpochBalance;
        } else if (currentEpoch_ == balanceEpoch_ + 1) {
            return balancePtr.currentEpochBalance;
        } else {
            return balancePtr.nextEpochBalance;
        }
    }

    /**
     * @dev Override deferred balances and latest-change epoch for a deposit.
     * @param balancePtr storage pointer to deposit
     * @param balance object to update by
     */
    function _storeBalance(DeferredDeposit storage balancePtr, DeferredDeposit memory balance) internal {
        balancePtr.currentEpoch = balance.currentEpoch;
        balancePtr.nextEpochBalance = balance.nextEpochBalance;
        balancePtr.currentEpochBalance = balance.currentEpochBalance;
        balancePtr.prevEpochBalance = balance.prevEpochBalance;
    }

    /**
     * @dev Increments operative balance applying from next epoch.
     * @param balancePtr storage pointer to deposit
     * @param amount to increment by
     */
    function _increaseNextBalance(DeferredDeposit storage balancePtr, uint256 amount) internal returns (uint256) {
        DeferredDeposit memory balance = _loadCurrentBalance(balancePtr);
        balance.nextEpochBalance += SafeCastUpgradeable.toUint128(amount);

        _storeBalance(balancePtr, balance);
        return balance.nextEpochBalance;
    }

    /**
     * @dev Decrements operative balance applying from next epoch.
     * @param balancePtr storage pointer to deposit
     * @param amount to decrement by
     */
    function _decreaseNextBalance(DeferredDeposit storage balancePtr, uint256 amount) internal returns (uint256) {
        DeferredDeposit memory balance = _loadCurrentBalance(balancePtr);
        balance.nextEpochBalance = SafeCastUpgradeable.toUint128(
            SafeMathUpgradeable.sub(balance.nextEpochBalance, amount, "_decreaseNextBalance: subtraction overflow")
        );

        _storeBalance(balancePtr, balance);
        return balance.nextEpochBalance;
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../config/Configurable.sol";
import "../config/StakingConstants.sol";

abstract contract StakingEpochManager is Initializable, Configurable, StakingConstants {
    /// @notice index of the current staking epoch
    uint64 public currentEpoch;

    /// @notice starting timestamp of the current epoch
    uint256 public currentEpochStartTimestamp;

    /**
     * @dev Emitted when the current epoch is ended.
     */
    event EndEpoch();

    /**
     * @dev Start the first epoch and init duration per epoch.
     */
    function __StakingEpochManager_init_unchained(uint256 epochDuration) internal onlyInitializing {
        _goToNextEpoch();
        _setConfig(EPOCH_DURATION_SEC, epochDuration);
    }

    /**
     * @notice Returns the earliest end timestamp of the current epoch.
     */
    function getEpochEarliestEndTime() public view returns (uint256) {
        return currentEpochStartTimestamp + getConfig(EPOCH_DURATION_SEC);
    }

    /**
     * @dev Move to the next epoch if enough time has passed.
     * @return prevEpochLength length of the ended epoch in seconds
     */
    function _goToNextEpoch() internal returns (uint256 prevEpochLength) {
        prevEpochLength = block.timestamp - currentEpochStartTimestamp;
        require(
            // strict inequality blocks ending more than one epoch per second
            prevEpochLength > getConfig(EPOCH_DURATION_SEC),
            "_goToNextEpoch: !enough time passed"
        );
        ++currentEpoch;
        currentEpochStartTimestamp = block.timestamp;
        emit EndEpoch();
    }

    uint256[48] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCastUpgradeable {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248) {
        require(value >= type(int248).min && value <= type(int248).max, "SafeCast: value doesn't fit in 248 bits");
        return int248(value);
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240) {
        require(value >= type(int240).min && value <= type(int240).max, "SafeCast: value doesn't fit in 240 bits");
        return int240(value);
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232) {
        require(value >= type(int232).min && value <= type(int232).max, "SafeCast: value doesn't fit in 232 bits");
        return int232(value);
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224) {
        require(value >= type(int224).min && value <= type(int224).max, "SafeCast: value doesn't fit in 224 bits");
        return int224(value);
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216) {
        require(value >= type(int216).min && value <= type(int216).max, "SafeCast: value doesn't fit in 216 bits");
        return int216(value);
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208) {
        require(value >= type(int208).min && value <= type(int208).max, "SafeCast: value doesn't fit in 208 bits");
        return int208(value);
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200) {
        require(value >= type(int200).min && value <= type(int200).max, "SafeCast: value doesn't fit in 200 bits");
        return int200(value);
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192) {
        require(value >= type(int192).min && value <= type(int192).max, "SafeCast: value doesn't fit in 192 bits");
        return int192(value);
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184) {
        require(value >= type(int184).min && value <= type(int184).max, "SafeCast: value doesn't fit in 184 bits");
        return int184(value);
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176) {
        require(value >= type(int176).min && value <= type(int176).max, "SafeCast: value doesn't fit in 176 bits");
        return int176(value);
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168) {
        require(value >= type(int168).min && value <= type(int168).max, "SafeCast: value doesn't fit in 168 bits");
        return int168(value);
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160) {
        require(value >= type(int160).min && value <= type(int160).max, "SafeCast: value doesn't fit in 160 bits");
        return int160(value);
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152) {
        require(value >= type(int152).min && value <= type(int152).max, "SafeCast: value doesn't fit in 152 bits");
        return int152(value);
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144) {
        require(value >= type(int144).min && value <= type(int144).max, "SafeCast: value doesn't fit in 144 bits");
        return int144(value);
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136) {
        require(value >= type(int136).min && value <= type(int136).max, "SafeCast: value doesn't fit in 136 bits");
        return int136(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120) {
        require(value >= type(int120).min && value <= type(int120).max, "SafeCast: value doesn't fit in 120 bits");
        return int120(value);
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112) {
        require(value >= type(int112).min && value <= type(int112).max, "SafeCast: value doesn't fit in 112 bits");
        return int112(value);
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104) {
        require(value >= type(int104).min && value <= type(int104).max, "SafeCast: value doesn't fit in 104 bits");
        return int104(value);
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96) {
        require(value >= type(int96).min && value <= type(int96).max, "SafeCast: value doesn't fit in 96 bits");
        return int96(value);
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88) {
        require(value >= type(int88).min && value <= type(int88).max, "SafeCast: value doesn't fit in 88 bits");
        return int88(value);
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80) {
        require(value >= type(int80).min && value <= type(int80).max, "SafeCast: value doesn't fit in 80 bits");
        return int80(value);
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72) {
        require(value >= type(int72).min && value <= type(int72).max, "SafeCast: value doesn't fit in 72 bits");
        return int72(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56) {
        require(value >= type(int56).min && value <= type(int56).max, "SafeCast: value doesn't fit in 56 bits");
        return int56(value);
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48) {
        require(value >= type(int48).min && value <= type(int48).max, "SafeCast: value doesn't fit in 48 bits");
        return int48(value);
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40) {
        require(value >= type(int40).min && value <= type(int40).max, "SafeCast: value doesn't fit in 40 bits");
        return int40(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24) {
        require(value >= type(int24).min && value <= type(int24).max, "SafeCast: value doesn't fit in 24 bits");
        return int24(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

abstract contract Configurable {
    /// @dev dictionary of all global configs of the contract
    mapping(bytes32 => uint256) private config;

    /**
     * @dev Emitted when parameter `key` has been set to `value`.
     */
    event SetConfigParam(bytes32 indexed key, uint256 value);

    /**
     * @notice Get the current value of global config `key`.
     * @param key id of the configuration
     * @return value of the configuration
     */
    function getConfig(bytes32 key) public view returns (uint256) {
        return config[key];
    }

    /**
     * @dev Set the value of global config `key`.
     * @param key id of the configuration
     * @param value new value of the configuration
     */
    function _setConfig(bytes32 key, uint256 value) internal {
        config[key] = value;
        emit SetConfigParam(key, value);
    }

    /**
     * @dev empty reserved space to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

abstract contract StakingConstants {
    /* Access roles */

    /// @dev owner role of the contract and admin over all existing access-roles
    bytes32 internal constant OWNER_ROLE = keccak256("OWNER_ROLE");

    /// @dev access-role used for pausing/unpausing the contract
    bytes32 internal constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /// @dev access-role used to create/delete pools
    bytes32 internal constant NODE_MANAGER_ROLE = keccak256("NODE_MANAGER_ROLE");

    /// @dev access-role used to finalize pools with off-chain node performances
    bytes32 internal constant FINALIZER_ROLE = keccak256("FINALIZER_ROLE");

    /// @dev access-role used to explicitly jail pools
    bytes32 internal constant JAILER_ROLE = keccak256("JAILER_ROLE");

    /* Configuration keys */

    /// @dev minimum duration of one epoch in seconds
    bytes32 internal constant EPOCH_DURATION_SEC = "EPOCH_DURATION_SEC";

    /// @dev average APY to be sustained per token deposited
    bytes32 internal constant AVERAGE_TOKEN_APY = "AVERAGE_TOKEN_APY";

    /// @dev minimum deposit of tokens to create a new pool
    bytes32 internal constant LEAST_PLEDGE_AMT = "LEAST_PLEDGE_AMT";

    /// @dev minimum deposit of tokens to create a new delegation
    bytes32 internal constant LEAST_DELEGATE_AMT = "LEAST_DELEGATE_AMT";

    /// @dev global currency-agnostic saturation threshold for pools
    bytes32 internal constant POOL_SATURATION_CAP = "POOL_SATURATION_CAP";

    /// @dev pledge influence numerator
    bytes32 internal constant PLEDGE_INFLUENCE_NUM = "PLEDGE_INFLUENCE_NUM";

    /// @dev pledge influence denominator
    bytes32 internal constant PLEDGE_INFLUENCE_DEN = "PLEDGE_INFLUENCE_DEN";

    /// @dev locking interval in seconds to be applied to withdrawals
    bytes32 internal constant WITHDRAW_LOCK_TIME = "WITHDRAW_LOCK_TIME";

    /// @dev number of epochs to pass before changing a pool`s fee again
    bytes32 internal constant POOL_FEE_COOLDOWN = "POOL_FEE_COOLDOWN";

    /// @dev amount of tokens to be paid in order to unjail a pool
    bytes32 internal constant POOL_UNJAIL_FEE = "POOL_UNJAIL_FEE";

    /* Constants */

    /// @dev fixed cost paid on each pool operation as contiguous slot allocations
    uint16 internal constant POOL_OP_COST = 3;

    /// @dev normalizer for percentages of double digit precision
    uint16 internal constant MAX_PPM = 10_000;

    /// @dev minimum pool commission fee allowed (2%)
    uint16 internal constant MIN_POOL_FEE = 200;

    /// @dev fixed number of decimals enforced over supported tokens
    uint8 internal constant STRICT_TOKEN_DECIMALS = 18;

    /// @dev scaling factor for fractions of token amounts
    uint256 internal constant ONE_TOKEN_UNITS = 10**STRICT_TOKEN_DECIMALS;

    /// @dev number of seconds within a year
    uint256 internal constant ONE_YEAR_SEC = 365 days;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}