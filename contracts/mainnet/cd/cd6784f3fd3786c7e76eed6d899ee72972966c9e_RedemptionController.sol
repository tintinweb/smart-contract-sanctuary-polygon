// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../interfaces/IRedemptionController.sol";
import "../../presets/interfaces/IOperatorTransferAnyERC20Token.sol";
import "../../presets/interfaces/IOperatorMint.sol";

/**
 * @title A protocol implementation to manage redemption plans
 *
 * @author Nerdoffice UG (haftungsbeschränkt) <[email protected]>
 */
contract RedemptionController is
    AccessControlEnumerable,
    IRedemptionController,
    IOperatorTransferAnyERC20Token
{
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant REDEEMER_ROLE = keccak256("REDEEMER_ROLE");

    uint64 internal _start;
    uint64 internal _interval;
    uint256 internal _periods;
    address internal _token;
    address internal _rewardToken;
    address internal _rewardAccount;

    struct Redemption {
        uint64 start;
        uint256 period;
        address account;
        uint256 amount;
        bytes data;
    }

    struct Redemptions {
        mapping(uint256 => uint256) plans;
        uint256 index;
        uint256 size;
    }

    mapping(uint256 => Redemption) internal _plans;
    mapping(address => Redemptions) internal _redemptions;
    uint256 internal _numRedemptions;

    /**
     * Create a new configured redemption contract.
     *
     * This contract has to have the necessary permissions to call some
     * functions of the redeem and reward token contracts.
     *
     * Reward token need to be send into this contract which itself distributes
     * the redemptions. This behavior can be changed by changing the reward
     * account but implies calls to approve transfers for this contract.
     *
     * The basic use case is to {add} redemptions for accounts, then check the
     * {redeemable} amount of tokens regularly. If the amount is not zero the
     * plans should be rewarded by calling {redeem} until the amount for all
     * plans is zero again.
     *
     * @param startTimestamp The start time of the first period
     * @param intervalSeconds The interval of each period in seconds
     * @param intervalPeriods The number of total periods
     * @param redeemTokenAddress The address of an ERC777 based token contract
     * @param rewardTokenAddress The address of an ERC20 based token contract
     */
    constructor(
        uint64 startTimestamp,
        uint64 intervalSeconds,
        uint256 intervalPeriods,
        address redeemTokenAddress,
        address rewardTokenAddress
    ) {
        require(startTimestamp == 0 || startTimestamp > block.timestamp, "RedemptionController: start time is before current time");
        _start = startTimestamp > 0 ? startTimestamp: uint64(block.timestamp);
        _interval = intervalSeconds > 0 ? intervalSeconds: 4 * (4 weeks);
        _periods = intervalPeriods > 0 ? intervalPeriods: 9;

        require(redeemTokenAddress != address(0), "RedemptionController: redeem token is a zero address");
        _token = redeemTokenAddress;

        require(rewardTokenAddress != address(0), "RedemptionController: reward token is a zero address");
        _rewardToken = rewardTokenAddress;

        _rewardAccount = address(this);

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MANAGER_ROLE, _msgSender());
        _setupRole(REDEEMER_ROLE, _msgSender());
    }

    /**
     * Destroy the contract as operator.
     */
    function destroy() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "RedemptionController: must have admin role");
        selfdestruct(payable(_msgSender()));
    }

    /**
     * Get the number of managed redemptions
     *
     * @return The number of managed redemptions
     */
    function count() public view virtual returns (uint256) {
        return _numRedemptions;
    }

    /**
     * Get the start time of the first redemption period
     *
     * @return The start time in seconds of the first redemption period
     */
    function startsAt() public view virtual returns (uint256) {
        return _start;
    }

     /**
     * Set the start time of the first redemption period. It must be a time
     * before the current block timestamp. Requires the MANAGER_ROLE.
     *
     * @param timestamp The start time in seconds for the first redemption period
     */
    function startsAt(uint64 timestamp) public virtual {
        require(hasRole(MANAGER_ROLE, _msgSender()), "RedemptionController: must have manager role");
        require(timestamp > 0, "RedemptionController: start time can not be zero");
        require(_start < block.timestamp, "RedemptionController: can not set start time if already started");
        _start = timestamp;
    }

    /**
     * Get the interval of a period in seconds
     *
     * @return The interval for a period in seconds
     */
    function interval() public view virtual returns (uint256) {
        return _interval;
    }

    /**
     * Set the interval for a period in seconds
     *
     * @param timestamp The interval for a period in seconds
     */
    function interval(uint64 timestamp) public virtual {
        require(hasRole(MANAGER_ROLE, _msgSender()), "RedemptionController: must have manager role");
        require(timestamp > 0, "RedemptionController: interval can not be zero");
        _start = timestamp;
    }

    /**
     * Get the total number of redemption periods
     *
     * @return The current number of redemption periods
     */
    function periods() public view virtual returns (uint256) {
        return _periods;
    }

    /**
     * Set the total number of redemption periods
     *
     * @param intervalPeriods The total number of periods periods to set
     */
    function periods(uint256 intervalPeriods) public virtual {
        require(hasRole(MANAGER_ROLE, _msgSender()), "RedemptionController: must have manager role");
        require(intervalPeriods > 0, "RedemptionController: interval can not be zero");
        _periods = intervalPeriods;
    }

    /**
     * Get the contract address of the ERC777 redeem token
     *
     * @return The contract address of the ERC777 redeem token
     */
    function redeemToken() public view virtual returns (address) {
        return _token;
    }

    /**
     * Set the contract address of the ERC777 redeem token
     *
     * @param at The contract address of ERC777 redeem token
     */
    function redeemToken(address at) public virtual {
        require(hasRole(MANAGER_ROLE, _msgSender()), "RedemptionController: must have manager role");
        _token = at;
    }

    /**
     * Get the account holding the reward tokens
     *
     * @return The address of the account holding reward tokens
     */
    function rewardAccount() public view virtual returns (address) {
        return _rewardAccount;
    }

    /**
     * Set the account holding the reward tokens
     *
     * @param account The address of for holding the reward tokens
     */
    function rewardAccount(address account) public virtual {
        require(hasRole(MANAGER_ROLE, _msgSender()), "RedemptionController: must have manager role");
        _rewardAccount = account;
    }

    /**
     * Get the contract address of the ERC20 reward token
     *
     * @return The address contract of the the ERC20 reward token
     */
    function rewardToken() public view virtual returns (address) {
        return _rewardToken;
    }

    /**
     * Set the contract address of the ERC20 reward token
     *
     * @param at The contract address of the ERC20 reward token
     */
    function rewardToken(address at) public virtual {
        require(hasRole(MANAGER_ROLE, _msgSender()), "RedemptionController: must have manager role");
        _rewardToken = at;
    }

    /**
     * Get the total supply of the redeem token
     *
     * @return The total supply returned by the redeem token contract
     */
    function redeemTokenTotalSupply() public view virtual returns (uint256) {
        return IERC20(redeemToken()).totalSupply();
    }

    /**
     * Get the reward token balance of the reward account
     *
     * @return balance The reward token balance of the reward account
     */
    function rewardTokenBalance() public view virtual returns (uint256 balance) {
        return IERC20(rewardToken()).balanceOf(rewardAccount());
    }

    /**
     * Add a redemption plan
     *
     * @param account The account to add a redemption plan for
     * @param amount The amount of token for the plan
     * @param data Optional custom data to track for this plan related to the account
     */
    function add(
        address account,
        uint256 amount,
        bytes memory data
    ) public
    {
        require(hasRole(MANAGER_ROLE, _msgSender()), "RedemptionController: must have manager role");

        uint64 timestamp = block.timestamp < startsAt() ? uint64(startsAt()): uint64(block.timestamp);
        _add(account, amount, timestamp, data);
    }

    /**
     * Add redemption plans in a batch
     *
     * @param accounts The accounts to add redemption plans for
     * @param amounts The amounts of token for each plan
     * @param data Optional custom data to track for this plan related to the account
     */
    function batchAdd(
        address[] memory accounts,
        uint256[] memory amounts,
        bytes[] memory data
    ) public
    {
        require(hasRole(MANAGER_ROLE, _msgSender()), "RedemptionController: must have manager role");
        require(accounts.length == amounts.length, "RedemptionController: accounts and amounts length mismatch");

        uint64 timestamp = block.timestamp < startsAt() ? uint64(startsAt()): uint64(block.timestamp);

        for (uint256 i = 0; i < accounts.length; i++) {
            _add(accounts[i], amounts[i], timestamp, data[i]);
        }
    }

    /**
     * Internal function to add a redemption plan
     *
     * @param start The start timestamp of the redemption plan
     * @param period The period of the plan
     * @param account The account address for the plan
     * @param amount The amount of token for the plan
     * @param data Optional custom data to track for this plan related to the account
     *
     * @return plan The id of the created plan
     */
    function _addRedemption(
        uint64 start,
        uint256 period,
        address account,
        uint256 amount,
        bytes memory data
    ) internal returns (uint256 plan) {
        _plans[_numRedemptions].start = start;
        _plans[_numRedemptions].period = period;
        _plans[_numRedemptions].account = account;
        _plans[_numRedemptions].amount = amount;
        _plans[_numRedemptions].data = data;

        uint256 index = _redemptions[account].index;

        _redemptions[account].plans[index] = _numRedemptions;
        _redemptions[account].index = index + 1;
        _redemptions[account].size++;

        emit RedemptionCreated(
            account,
            plan,
            _plans[_numRedemptions].amount,
            _plans[_numRedemptions].start,
            _plans[_numRedemptions].period,
            _plans[_numRedemptions].data
        );

        _numRedemptions++;

        plan = index + 1;
    }

    /**
     * Add a redemption plan and mint token to the account
     *
     * @param account The account address for the redemption
     * @param amount The amount of token for the redemption and to mint
     * @param timestamp The timestamp the redemption should start at
     * @param data Optional custom data to track for this plan related to the account
     *
     * @return plan The id of this plan
     */
    function _add(
        address account,
        uint256 amount,
        uint64 timestamp,
        bytes memory data
    ) internal returns (uint256 plan) {
        require(account != address(0), "RedemptionController: account is zero address");
        require(amount > 0, "RedemptionController: amount must be more than zero");

        IOperatorMint(redeemToken()).operatorMint(account, amount, data, "");

        uint64 shifted = timestamp < startsAt() ? uint64(startsAt()): uint64(timestamp);

        uint256 passed = shifted - startsAt();
        uint256 period = passed > interval() ? passed / interval(): 0;

        uint64 start = 0;

        if (timestamp <= startsAt()) {
            start = uint64(startsAt());
        } else {
            start = uint64(startsAt()) + uint64(uint64(interval()) * uint64(period + 1));
        }

        plan = _addRedemption(start, periods(), account, amount, data);
    }

    /**
     * Get the redemption plans for an account
     *
     * @param account The account to get information for
     *
     * @return start The start timestamps of each redemption plan
     * @return period The period of each redemption plan
     * @return amount The amount for each redemption
     * @return data The custom data tracked for this plan related to the account
     */
    function get(
        address account
    ) public view returns (
        uint64[] memory start,
        uint256[] memory period,
        uint256[] memory amount,
        bytes[] memory data
    ) {
        Redemptions storage redemptions = _redemptions[account];

        start = new uint64[](redemptions.size);
        period = new uint256[](redemptions.size);
        amount = new uint256[](redemptions.size);
        data = new bytes[](redemptions.size);

        if (redemptions.size > 0) {
            uint256 index = 0;
            while (index < redemptions.size) {
                uint256 i = redemptions.plans[index];
                start[index] = _plans[i].start;
                period[index] = _plans[i].period;
                amount[index] = _plans[i].amount;
                data[index] = _plans[i].data;
                index++;
            }
        }
    }

    /**
     * Get the informations for all redemption plans
     *
     * @return start The start timestamps of each redemption plan
     * @return period The period of each redemption plan
     * @return amount The amount for each redemption
     * @return account The account address for each redemption plan
     * @return data The custom data tracked for each plan
     */
    function getAll(
    ) public view returns (
        uint64[] memory start,
        uint256[] memory period,
        uint256[] memory amount,
        address[] memory account,
        bytes[] memory data
    ) {
        start = new uint64[](_numRedemptions);
        period = new uint256[](_numRedemptions);
        amount = new uint256[](_numRedemptions);
        account = new address[](_numRedemptions);
        data = new bytes[](_numRedemptions);

        for (uint256 i = 0; i < _numRedemptions; i++) {
            start[i] = _plans[i].start;
            period[i] = _plans[i].period;
            amount[i] = _plans[i].amount;
            account[i] = _plans[i].account;
            data[i] = _plans[i].data;
        }
    }

    /**
     * Import redemption plans from another RedemptionController contract
     *
     * @param redemptionContractAddress The address of the redemption controller to import from
     */
    function operatorMigrateFrom(
        address redemptionContractAddress
    ) public virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "RedemptionController: must have admin role");
        require(redemptionContractAddress != address(0), "RedemptionController: redemption contract is a zero address");

        _start = uint64(IRedemptionController(redemptionContractAddress).startsAt());
        _interval = uint64(IRedemptionController(redemptionContractAddress).interval());
        _periods = IRedemptionController(redemptionContractAddress).periods();
        _token = IRedemptionController(redemptionContractAddress).redeemToken();
        _rewardToken = IRedemptionController(redemptionContractAddress).rewardToken();

        // Only set reward account if different from former contract
        address rewardAccountAddress = IRedemptionController(redemptionContractAddress).rewardAccount();
        if (redemptionContractAddress != rewardAccountAddress) {
            _rewardAccount = IRedemptionController(redemptionContractAddress).rewardAccount();
        }

        uint256 redemptionsCount = IRedemptionController(redemptionContractAddress).count();

        (uint64[] memory start, uint256[] memory period, uint256[] memory amount, address[] memory account, bytes[] memory data) = IRedemptionController(redemptionContractAddress).getAll();

        for (uint256 i = 0; i < redemptionsCount; i++) {
            _addRedemption(start[i], period[i], account[i], amount[i], data[i]);
        }
    }

    /**
     * Determine the account that holds a specific redeem token. This looks at
     * all holders and their amounts and counts up until the target token to
     * pick the account this token would be in. Therefore holds with a larger
     * amount of token have a higher chance to be picked. The offset must be
     * less than the redeem token total supply.
     *
     * @param offset The token offset to use
     *
     * @return account The account that holds the token for the provided offset
     */
    function getAccountAtOffset(
        uint256 offset
    ) public view returns (address account) {
        require(offset <= redeemTokenTotalSupply(), "RedemptionController: offset must be less than than redeem token total supply");

        uint256 total = 0;

        for (uint256 i = 0; i < _numRedemptions; i++) {
            Redemption storage redemption = _plans[i];

            if (offset >= total && offset <= (total + redemption.amount)) {
                return redemption.account;
            }

            total += redemption.amount;
        }

        return address(0);
    }

    /**
     * Get the total amount of reward token for all plans of an account at a
     * specific time.
     *
     * @param account The account to calculate for
     * @param timestamp The timestamp to use for calculation
     *
     * @return amount The total amount of reward token for this account per plan
     * @return span The current periods each plan is at for this account
     */
    function redeemableAt(
        address account,
        uint64 timestamp
    ) public view returns (
        uint256[] memory amount,
        uint256[] memory span
    ) {
        Redemptions storage redemptions = _redemptions[account];

        amount = new uint256[](redemptions.size);
        span = new uint256[](redemptions.size);

        if (redemptions.size > 0) {
            uint256 index = 0;
            while (index < redemptions.size) {
                uint256 i = redemptions.plans[index];
                (amount[index], span[index]) = _redemptionSchedule(_plans[i], timestamp);
                index++;
            }
        }
    }

    /**
     * Get the total amount of reward token for all plans at a specific time.
     *
     * @param timestamp The timestamp to use for calculation
     *
     * @return amount The total amount of reward token this plan can redeem
     */
    function redeemableAt(
        uint64 timestamp
    ) public view returns (uint256 amount) {
        for (uint256 i = 0; i < _numRedemptions; i++) {
            if (_plans[i].amount > 0) {
                (uint256 redemptionAmount,) = _redemptionSchedule(_plans[i], timestamp);
                amount += redemptionAmount;
            }
        }
    }

    /**
     * Get the total amount of reward token for each plan of an account at the
     * current block timestamp. This does not transfer the rewards.
     *
     * @param account The account to calculate for
     *
     * @return amount The total amount of reward token for this account per plan
     * @return span The current periods each plan is at for this account
     */
    function redeemable(
        address account
    ) public view returns (
        uint256[] memory amount,
        uint256[] memory span
    ) {
        return redeemableAt(account, uint64(block.timestamp));
    }

    /**
     * Get the total amount of reward token for all plans at the current block
     * timestamp. This does not transfer the rewards.
     *
     * @return amount The total amount of reward token
     */
    function redeemable(
    ) public view returns (uint256 amount) {
        return redeemableAt(uint64(block.timestamp));
    }

    /**
     * Internal function to process and redeem a number of plans at a time.
     *
     * @param limit The maximum number of plans to process and redeem
     * @param timestamp The timestamp to use for calculation
     *
     * Emits {IERC20-Transfer}, {IERC777-Burned} and {RedemptionDistributed} events.
     */
    function _redeemPlansAt(
        uint256 limit,
        uint64 timestamp
    ) internal
    {
        uint256 remaining = redeemableAt(timestamp);

        uint8 decimals = IERC20Metadata(rewardToken()).decimals();
        uint256 remainingValue = remaining / (10 ** (18 - decimals));

        require(IERC20(rewardToken()).balanceOf(rewardAccount()) >= remainingValue, "RedemptionController: insufficient balance in reward account");

        if (limit == 0) {
            limit = _numRedemptions;
        }

        for (uint256 i = 0; i < _numRedemptions && limit > 0; i++) {
            uint256 left = _redeemAt(i, timestamp);
            if (left > 0) {
                limit--;
            }
        }
    }

    /**
     * Internal function to calculate the redeem amount and period at a time.
     *
     * @param plan The plan index
     * @param timestamp The timestamp to use for calculation
     *
     * @return amount The amount that was redeemed for this plan
     *
     * Emits {IERC20-Transfer}, {IERC777-Burned} and {RedemptionDistributed} events.
     */
    function _redeemAt(
        uint256 plan,
        uint64 timestamp
    ) internal returns (uint256) {
        Redemption storage redemption = _plans[plan];

        (uint256 amount, uint256 span) = _redemptionSchedule(redemption, timestamp);

        if (amount > 0) {
            address account = redemption.account;

            uint8 decimals = IERC20Metadata(rewardToken()).decimals();
            uint256 amountValue = amount / (10 ** (18 - decimals));

            if (rewardAccount() == address(this)) {
                IERC20(rewardToken()).transfer(account, amountValue);
            } else {
                IERC20(rewardToken()).transferFrom(rewardAccount(), account, amountValue);
            }

            IERC777(redeemToken()).operatorBurn(account, amount, redemption.data, "");

            redemption.amount -= amount;
            redemption.period -= span;

            emit RedemptionDistributed(
                account,
                plan,
                amount,
                redemption.amount,
                span,
                redemption.data
            );
        }

        return amount;
    }

    /**
     * Internal function to calculate the redeem amount and period at a time.
     *
     * @param redemption The redemption
     * @param timestamp The timestamp to use for calculation
     *
     * @return amount The amount to redeem for this redemption
     * @return span The period within the contract periods based on the timestamp
     */
    function _redemptionSchedule(
        Redemption memory redemption,
        uint64 timestamp
    ) internal view returns (
        uint256 amount,
        uint256 span
    ) {
        if (timestamp < startsAt() || timestamp < redemption.start) {
            return (0,0);
        } else if (redemption.period == 0) {
            return (0,0);
        } else {
            uint256 passed = timestamp - redemption.start;
            uint256 period = passed > interval() ? passed / interval(): 0;
            if (period > 0) {
                uint256 redemptionAmount = (((redemption.amount * 1e4) / redemption.period) / 1e4);
                span = period > periods() ? redemption.period: (redemption.period - (periods() - period));
                amount = redemptionAmount * span;
            }
        }
    }

    /**
     * Process a number of redemptions plans and redeem tokens to holders. The
     * use of the the limit argument allows to have some control of fees.
     *
     * @param limit The maximum number of plans to process and redeem
     */
    function redeem(
        uint256 limit
    ) public
    {
        require(hasRole(REDEEMER_ROLE, _msgSender()), "RedemptionController: must have redeemer role");

        uint64 timestamp = block.timestamp < startsAt() ? uint64(startsAt()): uint64(block.timestamp);
        _redeemPlansAt(limit, timestamp);
    }

    /**
     * Update redemption plans of an account based on current balance. This
     * is not expected to be used regularly but allows to resolve plans for
     * accounts which have been altered by an operator of the redeem token
     * directly. Handle with care.
     *
     * @param account The account to update
     */
    function update(
        address account
    ) public
    {
        require(hasRole(MANAGER_ROLE, _msgSender()), "RedemptionController: must have manager role");

        Redemptions storage redemptions = _redemptions[account];

        if (redemptions.size > 0) {
            uint256 index = 0;
            uint256 total = IERC777(redeemToken()).balanceOf(account);
            while (index < redemptions.size) {
                uint256 i = redemptions.plans[index];
                if (_plans[i].amount > 0) {
                    if (total >= _plans[i].amount) {
                        total -= _plans[i].amount;
                    } else {
                        _plans[i].amount = total;
                        total = 0;
                    }
                }
                index++;
            }
        }
    }

    /**
     * Withdraw any ERC20 token held by this contract as MANAGER_ROLE.
     *
     * @param token The contract address of the ERC20 token
     * @param recipient The address of the recipient
     * @param amount The amount of token to transfer
     *
     * @return success Returns the result of the {IERC20-Transfer} function
     */
    function operatorTransferAnyERC20Token(
        address token,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool success) {
        require(hasRole(MANAGER_ROLE, _msgSender()), "RedemptionController: must have manager role");
        return IERC20(token).transfer(recipient, amount);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

interface IOperatorTransferAnyERC20Token {
     /**
     * Owner can withdraw any ERC20 token received by the contract
     */
    function operatorTransferAnyERC20Token(address token, address recipient, uint256 amount) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

interface IOperatorMint {
    function operatorMint(address account, uint256 amount, bytes calldata data, bytes calldata operatorData) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

interface IRedemptionController {
    function count() external view returns (uint256);

    function startsAt() external view returns (uint256);

    function startsAt(uint64 timestamp) external;

    function interval() external view returns (uint256);

    function interval(uint64 timestamp) external;

    function periods() external view returns (uint256);

    function periods(uint256 intervalPeriods) external;

    function redeemToken() external view returns (address);

    function redeemToken(address at) external;

    function rewardAccount() external view returns (address);

    function rewardAccount(address account) external;

    function rewardToken() external view returns (address);

    function rewardToken(address at) external;

    function redeemTokenTotalSupply() external view returns (uint256);

    function rewardTokenBalance() external view returns (uint256 balance);

    function add(address account, uint256 amount, bytes calldata data) external;

    function batchAdd(address[] calldata accounts, uint256[] calldata amounts, bytes[] calldata data) external;

    function get(address account) external view returns (uint64[] memory start, uint256[] memory period, uint256[] memory amount, bytes[] memory data);

    function getAll() external view returns (uint64[] memory start, uint256[] memory period, uint256[] memory amount, address[] memory account, bytes[] memory data);

    function getAccountAtOffset(uint256 offset) external view returns (address account);

    function redeemableAt(address account, uint64 timestamp) external view returns (uint256[] memory amount, uint256[] memory span);

    function redeemableAt(uint64 timestamp) external view returns (uint256 amount);

    function redeemable(address account) external view returns (uint256[] memory amount, uint256[] memory span);

    function redeemable() external view returns (uint256 amount);

    function redeem(uint256 limit) external;

    event RedemptionCreated(
        address indexed account,
        uint256 indexed plan,
        uint256 amount,
        uint64 start,
        uint256 periods,
        bytes data
    );

    event RedemptionDistributed(
        address indexed account,
        uint256 indexed plan,
        uint256 redeemed,
        uint256 remaining,
        uint256 span,
        bytes data
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
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
interface IERC165 {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC777/IERC777.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777Token standard as defined in the EIP.
 *
 * This contract uses the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 registry standard] to let
 * token holders and recipients react to token movements by using setting implementers
 * for the associated interfaces in said registry. See {IERC1820Registry} and
 * {ERC1820Implementer}.
 */
interface IERC777 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the smallest part of the token that is not divisible. This
     * means all token operations (creation, movement and destruction) must have
     * amounts that are a multiple of this number.
     *
     * For most token contracts, this value will equal 1.
     */
    function granularity() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by an account (`owner`).
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * If send or receive hooks are registered for the caller and `recipient`,
     * the corresponding functions will be called with `data` and empty
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function send(
        address recipient,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev Destroys `amount` tokens from the caller's account, reducing the
     * total supply.
     *
     * If a send hook is registered for the caller, the corresponding function
     * will be called with `data` and empty `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     */
    function burn(uint256 amount, bytes calldata data) external;

    /**
     * @dev Returns true if an account is an operator of `tokenHolder`.
     * Operators can send and burn tokens on behalf of their owners. All
     * accounts are their own operator.
     *
     * See {operatorSend} and {operatorBurn}.
     */
    function isOperatorFor(address operator, address tokenHolder) external view returns (bool);

    /**
     * @dev Make an account an operator of the caller.
     *
     * See {isOperatorFor}.
     *
     * Emits an {AuthorizedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function authorizeOperator(address operator) external;

    /**
     * @dev Revoke an account's operator status for the caller.
     *
     * See {isOperatorFor} and {defaultOperators}.
     *
     * Emits a {RevokedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function revokeOperator(address operator) external;

    /**
     * @dev Returns the list of default operators. These accounts are operators
     * for all token holders, even if {authorizeOperator} was never called on
     * them.
     *
     * This list is immutable, but individual holders may revoke these via
     * {revokeOperator}, in which case {isOperatorFor} will return false.
     */
    function defaultOperators() external view returns (address[] memory);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient`. The caller must
     * be an operator of `sender`.
     *
     * If send or receive hooks are registered for `sender` and `recipient`,
     * the corresponding functions will be called with `data` and
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - `sender` cannot be the zero address.
     * - `sender` must have at least `amount` tokens.
     * - the caller must be an operator for `sender`.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the total supply.
     * The caller must be an operator of `account`.
     *
     * If a send hook is registered for `account`, the corresponding function
     * will be called with `data` and `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     * - the caller must be an operator for `account`.
     */
    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );

    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);

    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);

    event RevokedOperator(address indexed operator, address indexed tokenHolder);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
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
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
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
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
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
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}