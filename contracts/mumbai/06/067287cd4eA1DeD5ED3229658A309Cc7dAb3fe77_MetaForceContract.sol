// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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
pragma solidity 0.8.15;

enum Workflow {
    Preparatory,
    Presale,
    SaleHold,
    SaleOpen
}

uint256 constant PRICE_PACK_LEVEL1_IN_USD = 50e18;
uint256 constant PRICE_PACK_LEVEL1_IN_MFS_FIRST_BB = 200e18;
uint256 constant TWO = 2e18;
uint256 constant OVERRLAP_TIME_ACTIVITY = 3 days;
uint256 constant PACK_ACTIVITY_PERIOD = 30 days;
uint256 constant PURCHASE_TIME_LIMIT_PERIOD = 30 days;
uint256 constant SHARE_OF_MARKETING = 60e16;
uint256 constant SHARE_OF_REWARDS = 10e16;
uint256 constant SHARE_OF_LIQUIDITY_POOL = 10e16;
uint256 constant SHARE_OF_FORSAGE_PARTICIPANTS = 5e16;
uint256 constant SHARE_OF_META_DEVELOPMENT_AND_INCENTIVE = 5e16;
uint256 constant SHARE_OF_TEAM = 5e16;
uint256 constant SHARE_OF_LIQUIDITY_LISTING = 5e16;
uint256 constant LEVELS_COUNT = 9;
uint256 constant HMFS_COUNT = 8;
uint256 constant TRANSITION_PHASE_PERIOD = 30 days;
uint256 constant ACTIVATION_COST_RATIO_TO_RENEWAL = 5e18;
uint256 constant COEFF_INCREASE_COST_PACK_FOR_NEXT_LEVEL = 2e18;
uint256 constant COEFF_DECREASE_NEXT_BB = 2e18; //2
uint256 constant COEFF_DECREASE_COST_PACK_NEXT_BB = 2e18; //2
uint256 constant COEFF_DECREASE_COST_PACK_NEXT_MB = 6e16; //0.06
uint256 constant MB_COUNT = 10;
uint256 constant COEFF_FIRST_MB = 127e16; //1.27
uint256 constant START_COEFF_DECREASE_MICROBLOCK = 124e16;
uint256 constant MARKETING_REFERRALS_TREE_ARITY = 2;

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./interfaces/ICoreContract.sol";
import "./interfaces/IMetaForceContract.sol";
import "./interfaces/ICoins.sol";
import "./interfaces/IRequestMFSContract.sol";
import "./interfaces/IHoldingContract.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/FixedPointMath.sol";
import "./Constants.sol";

contract MetaForceContract is Ownable, IMetaForceContract {
    using FixedPointMath for uint256;

    IRegistryContract internal registry;
    uint256 public nowPriceFirstPackInMFS;
    mapping(address => mapping(uint256 => uint256)) public countRenewal;

    uint256 public override priceMFSInUSD;
    uint256 public endBigBlock;
    uint256 public endSmallBlock;
    uint256 public nowNumberSmallBlock;
    uint256 public nowNumberBigBlock;
    uint256 public nowCoeffDecreaseMicroBlock;
    uint256 public bigBlockSize;
    uint256 public meanSmallBlock;
    uint256 public totalEmissionMFS;
    mapping(address => DatesBuyingMFS[]) public datesForBuying;
    mapping(address => uint256) public lastIndexBuying;

    uint256 public cap;
    bool public emissionCommitted;

    uint256 public meanDecreaseMicroBlock;

    modifier onlyRequestMFSContract() {
        if (msg.sender != registry.getRequestMFSContract()) {
            revert MFCSenderIsNotRequestMFSContract();
        }
        _;
    }

    constructor(IRegistryContract _registry) {
        registry = _registry;

        IMFS mfsToken = IMFS(registry.getMFS());

        cap = mfsToken.cap();
        bigBlockSize = cap.mul(SHARE_OF_MARKETING).div(COEFF_DECREASE_NEXT_BB);
        meanSmallBlock = bigBlockSize / MB_COUNT;
        nowNumberSmallBlock = 0;
        endSmallBlock =
            endBigBlock +
            meanSmallBlock.mul(COEFF_FIRST_MB - COEFF_DECREASE_COST_PACK_NEXT_MB * nowNumberSmallBlock);
        endBigBlock = bigBlockSize;
        nowCoeffDecreaseMicroBlock = START_COEFF_DECREASE_MICROBLOCK;
        nowPriceFirstPackInMFS = PRICE_PACK_LEVEL1_IN_MFS_FIRST_BB;
        priceMFSInUSD = PRICE_PACK_LEVEL1_IN_USD.div(PRICE_PACK_LEVEL1_IN_MFS_FIRST_BB);

        meanDecreaseMicroBlock =
            (PRICE_PACK_LEVEL1_IN_MFS_FIRST_BB - (PRICE_PACK_LEVEL1_IN_MFS_FIRST_BB.div(COEFF_DECREASE_NEXT_BB))) /
            MB_COUNT;
    }

    function distibuteEmission() external override {
        if (emissionCommitted) {
            revert MFCEmissionCommitted();
        }

        IMFS mfsToken = IMFS(registry.getMFS());

        mfsToken.mint(registry.getMetaPool(), cap.mul(SHARE_OF_MARKETING));
        mfsToken.mint(registry.getRewardsFund(), cap.mul(SHARE_OF_REWARDS));

        mfsToken.mint(registry.getLiquidityPool(), cap.mul(SHARE_OF_LIQUIDITY_POOL));
        mfsToken.mint(registry.getForsageParticipants(), cap.mul(SHARE_OF_FORSAGE_PARTICIPANTS));
        mfsToken.mint(registry.getMetaDevelopmentAndIncentiveFund(), cap.mul(SHARE_OF_META_DEVELOPMENT_AND_INCENTIVE));
        mfsToken.mint(registry.getTeamFund(), cap.mul(SHARE_OF_TEAM));
        mfsToken.mint(registry.getLiquidityListingFund(), cap.mul(SHARE_OF_LIQUIDITY_LISTING));
        emissionCommitted = true;
    }

    function setRegistryContract(IRegistryContract _registry) external override onlyOwner {
        registry = _registry;
        emit MFCRegistryContractAddressSetted(address(registry));
    }

    function giveMFSFromPool(address to, uint256 amount) external override onlyRequestMFSContract {
        transferMFSFrom(registry.getMetaPool(), to, amount);
    }

    function buyMFS(uint256 amountMFS) external override {
        IERC20 stableCoin = IERC20(registry.getStableCoin());
        ICoreContract core = ICoreContract(registry.getCoreContract());
        if (core.getWorkflowStage() == Workflow.SaleOpen) {
            revert MFCLateForBuyMFS();
        }
        uint256 tempAmount = amountMFS;
        for (uint256 i = lastIndexBuying[msg.sender]; i < datesForBuying[msg.sender].length; i++) {
            if (datesForBuying[msg.sender][i].date < block.timestamp) {
                datesForBuying[msg.sender][i].amount = 0;
            } else if (datesForBuying[msg.sender][i].amount < tempAmount) {
                tempAmount -= datesForBuying[msg.sender][i].amount;
                datesForBuying[msg.sender][i].amount = 0;
            } else {
                datesForBuying[msg.sender][i].amount -= tempAmount;
                tempAmount = 0;
            }
            if (tempAmount == 0) {
                lastIndexBuying[msg.sender] = i;
                break;
            }
        }
        if (tempAmount != 0) {
            revert MFCBuyLimitOfMFSExceeded(tempAmount);
        }

        uint256 amountToPay = calcUSDAmountForMFS(amountMFS);
        stableCoin.transferFrom(msg.sender, registry.getMetaPool(), amountToPay);
        mintMFS(msg.sender, amountMFS);
    }

    function firstActivationPack(address marketinReferrer) external override {
        ICoreContract core = ICoreContract(registry.getCoreContract());
        if (core.getMarketingReferrer(msg.sender) != address(0x0)) {
            revert MFCNotFirstActivationPack();
        }
        if (msg.sender == marketinReferrer) {
            revert MFCRefererNotCantBeSelf();
        }
        core.setMarketingReferrer(msg.sender, marketinReferrer);
        activationPack(1);
    }

    function firstActivationPackWithReplace(address replace) external override {
        ICoreContract core = ICoreContract(registry.getCoreContract());
        if (core.getMarketingReferrer(msg.sender) != address(0x0)) {
            revert MFCNotFirstActivationPack();
        }
        core.replaceUserInMarketingTree(replace, msg.sender);
        activationPack(1);
    }

    function renewalPack(
        uint256 level,
        uint256 amount,
        TypeRenewalCurrency typeCurrency
    ) external override {
        renewalConditions(level, amount);
        ICoreContract core = ICoreContract(registry.getCoreContract());
        IHoldingContract holding = IHoldingContract(registry.getHoldingContract());
        if (core.getWorkflowStage() < Workflow.SaleOpen && typeCurrency != TypeRenewalCurrency.MFS) {
            revert MFCEarlyStageForRenewalPackInHMFS();
        }
        uint256 priceRenewalPackInUSD = PRICE_PACK_LEVEL1_IN_USD.mul(
            COEFF_INCREASE_COST_PACK_FOR_NEXT_LEVEL.pow((level - 1).convertIntToFixPoint()).div(
                ACTIVATION_COST_RATIO_TO_RENEWAL
            )
        );
        uint256 priceRenewalPackInMFS = nowPriceFirstPackInMFS
            .mul(uint256(COEFF_INCREASE_COST_PACK_FOR_NEXT_LEVEL).pow((level - 1).convertIntToFixPoint()))
            .div(ACTIVATION_COST_RATIO_TO_RENEWAL);

        if (core.getWorkflowStage() == Workflow.SaleOpen) {
            if (typeCurrency == TypeRenewalCurrency.MFS) {
                uint256 startSaleOpenDate = core.getDateStartSaleOpen();
                if (
                    core.getRegistrationDate(msg.sender) > startSaleOpenDate ||
                    block.timestamp > startSaleOpenDate + TRANSITION_PHASE_PERIOD
                ) {
                    revert MFCRenewalPaymentIsOnlyPossibleInHMFS();
                }
                transferMFSFrom(msg.sender, address(this), priceRenewalPackInMFS * amount);
                transferMFSFrom(msg.sender, registry.getMetaPool(), priceRenewalPackInMFS * amount);
                holding.holdOnBehalf(msg.sender, 1, priceRenewalPackInMFS * amount);
                IEnergy energy = IEnergy(registry.getEnergyCoin());
                energy.mint(msg.sender, (priceRenewalPackInMFS * amount).mul(core.getEnergyConversionFactor()));
                distributionRewardReferal(
                    msg.sender,
                    level,
                    priceRenewalPackInMFS * amount,
                    priceRenewalPackInUSD * amount
                );
                renewalPack(level, amount);
            } else {
                uint256[] memory amountCurrency = new uint256[](HMFS_COUNT);
                amountCurrency[uint256(typeCurrency) - 1] = priceRenewalPackInMFS * amount;
                renewalPack(level, amount, amountCurrency);
            }
        } else {
            transferMFSFrom(msg.sender, registry.getMetaPool(), priceRenewalPackInMFS * amount);
            DatesBuyingMFS memory purchase;
            purchase.date = block.timestamp + PURCHASE_TIME_LIMIT_PERIOD;
            purchase.amount = priceRenewalPackInMFS * amount;
            datesForBuying[msg.sender].push(purchase);
            IEnergy energy = IEnergy(registry.getEnergyCoin());
            energy.mint(msg.sender, (priceRenewalPackInMFS * amount).mul(core.getEnergyConversionFactor()));
            distributionRewardReferal(
                msg.sender,
                level,
                priceRenewalPackInMFS * amount,
                priceRenewalPackInUSD * amount
            );
            renewalPack(level, amount);
        }
    }

    function activationPack(uint256 level) public override {
        ICoreContract core = ICoreContract(registry.getCoreContract());
        IERC20 stableCoin = IERC20(registry.getStableCoin());
        IMFS mfs = IMFS(registry.getMFS());
        if (level > LEVELS_COUNT) {
            revert MFCLevelMoreMaxPackLevel();
        }
        if (level == 0) {
            revert MFCPackLevelIs0();
        }
        if (core.getMarketingReferrer(msg.sender) == address(0x0)) {
            revert MFCUserIsNotRegistredInMarketing();
        }
        if (core.getWorkflowStage() < Workflow.Presale) {
            revert MFCEarlyStageForActivatePack();
        }
        if (!core.checkRegistration(msg.sender)) {
            revert MFCUserNotRegisteredYet();
        }
        if (core.isPackActive(msg.sender, level)) {
            revert MFCPackIsActive(level);
        }
        for (uint256 i = 1; i < level; i++) {
            if (!core.isPackActive(msg.sender, i)) {
                revert MFCNeedActivatePack(i);
            }
        }
        uint256 pricePackInUSD = PRICE_PACK_LEVEL1_IN_USD.mul(uint256(TWO).pow((level - 1).convertIntToFixPoint()));
        uint256 pricePackInMFS;
        DatesBuyingMFS memory purchase;
        pricePackInMFS = calcMFSAmountForUSD(pricePackInUSD);

        if (core.getWorkflowStage() != Workflow.SaleOpen) {
            stableCoin.transferFrom(msg.sender, registry.getMetaPool(), pricePackInUSD);
            purchase.date = block.timestamp + PURCHASE_TIME_LIMIT_PERIOD;
            purchase.amount = pricePackInMFS;
            datesForBuying[msg.sender].push(purchase);
            mintMFS(registry.getMetaPool(), pricePackInMFS);
        } else {
            mfs.transferFrom(msg.sender, registry.getMetaPool(), pricePackInMFS);
        }
        IEnergy energy = IEnergy(registry.getEnergyCoin());
        energy.mint(msg.sender, pricePackInMFS.mul(core.getEnergyConversionFactor()));
        core.setTimestampEndPack(msg.sender, level, block.timestamp + PACK_ACTIVITY_PERIOD);
        distributionRewardReferal(msg.sender, level, pricePackInMFS, pricePackInUSD);
        emit MFCPackIsActivated(msg.sender, level, core.getTimestampEndPack(msg.sender, level));
    }

    function renewalPack(
        uint256 level,
        uint256 amount,
        uint256[] memory amountsCurrency
    ) public {
        renewalConditions(level, amount);
        ICoreContract core = ICoreContract(registry.getCoreContract());
        if (amountsCurrency.length != HMFS_COUNT) {
            revert MFCSizeArrayDifferentFromExpected();
        }
        if (core.getWorkflowStage() != Workflow.SaleOpen) {
            revert MFCEarlyStageForRenewalPackInHMFS();
        }
        uint256 priceRenewalPackInUSD = PRICE_PACK_LEVEL1_IN_USD.mul(
            COEFF_INCREASE_COST_PACK_FOR_NEXT_LEVEL.pow((level - 1).convertIntToFixPoint()).div(
                ACTIVATION_COST_RATIO_TO_RENEWAL
            )
        );
        uint256 priceRenewalPackInMFS = nowPriceFirstPackInMFS
            .mul(uint256(COEFF_INCREASE_COST_PACK_FOR_NEXT_LEVEL).pow((level - 1).convertIntToFixPoint()))
            .div(ACTIVATION_COST_RATIO_TO_RENEWAL);
        uint256 tempAmount = amount;
        while (tempAmount > 0) {
            uint256 tempPrice = priceRenewalPackInMFS;
            for (uint256 i = countRenewal[msg.sender][level]; i < amountsCurrency.length; i++) {
                if (amountsCurrency[i] < tempPrice) {
                    IHMFS hFMS = IHMFS(registry.getHMFS(i + 1));
                    hFMS.burn(msg.sender, amountsCurrency[i]);
                    tempPrice -= amountsCurrency[i];
                    amountsCurrency[i] = 0;
                } else {
                    IHMFS hFMS = IHMFS(registry.getHMFS(i + 1));
                    hFMS.burn(msg.sender, tempPrice);
                    amountsCurrency[i] -= tempPrice;
                    tempPrice = 0;
                    break;
                }
            }
            if (tempPrice != 0) {
                revert MFCNotEnoughHMFSNeedLevel();
            }
            renewalPack(level, 1);
            if (countRenewal[msg.sender][level] < HMFS_COUNT - 1) {
                countRenewal[msg.sender][level] += 1;
            }
            tempAmount--;
        }
        IEnergy energy = IEnergy(registry.getEnergyCoin());
        energy.mint(msg.sender, (priceRenewalPackInMFS * amount).mul(core.getEnergyConversionFactor()));
        distributionRewardReferal(msg.sender, level, priceRenewalPackInMFS * amount, priceRenewalPackInUSD * amount);
    }

    function cashingFrozenMFS() public {
        ICoreContract core = ICoreContract(registry.getCoreContract());
        if (core.getWorkflowStage() != Workflow.SaleOpen) {
            revert MFCToEarlyToCashing();
        }
        if (core.getAmountFrozenMFS(msg.sender) == 0) {
            revert MFCNoFundsOnAccount();
        }
        transferMFSFrom(registry.getMetaPool(), msg.sender, core.getAmountFrozenMFS(msg.sender));
        core.decreaseFrozenMFS(msg.sender, core.getAmountFrozenMFS(msg.sender));
    }

    function renewalPack(uint256 level, uint256 amount) internal {
        ICoreContract core = ICoreContract(registry.getCoreContract());
        core.increaseTimestampEndPack(msg.sender, level, PACK_ACTIVITY_PERIOD * amount);
        emit MFCPackIsRenewed(msg.sender, level, core.getTimestampEndPack(msg.sender, level));
    }

    function distributionRewardReferal(
        address user,
        uint256 level,
        uint256 amountMFS,
        uint256 amountUSD
    ) internal {
        ICoreContract core = ICoreContract(registry.getCoreContract());
        IERC20 stableCoin = IERC20(registry.getStableCoin());
        uint256[] memory rewardsRefers = core.getRewardsDirectReferrers();
        uint256[] memory rewardsMarketingRefers = core.getRewardsMarketingReferrers();
        address[] memory referrers = core.getReferrers(user, level, rewardsRefers.length);
        address[] memory marketingReferrers = core.getMarketingReferrers(user, level, rewardsMarketingRefers.length);
        uint256 amountMFSForRealization;
        for (uint256 i = 0; i < referrers.length; i++) {
            TypeReward typeReward;
            typeReward = core.getTypeReward(referrers[i]);
            if (typeReward == TypeReward.ONLY_MFS || core.getWorkflowStage() == Workflow.SaleOpen) {
                transferMFSFrom(registry.getMetaPool(), referrers[i], amountMFS.mul(rewardsRefers[i]));
            } else if (typeReward == TypeReward.ONLY_USD) {
                stableCoin.transferFrom(registry.getMetaPool(), referrers[i], amountUSD.mul(rewardsRefers[i]));
                amountMFSForRealization += amountMFS.mul(rewardsRefers[i]);
            } else {
                uint256 tempAmount = amountMFS.mul(rewardsRefers[i]) / 2;
                transferMFSFrom(registry.getMetaPool(), referrers[i], tempAmount);
                amountMFSForRealization += tempAmount;
                tempAmount = amountUSD.mul(rewardsRefers[i]) / 2;
                stableCoin.transferFrom(registry.getMetaPool(), referrers[i], tempAmount);
            }
        }
        for (uint256 i = 0; i < marketingReferrers.length; i++) {
            TypeReward typeReward;
            typeReward = core.getTypeReward(marketingReferrers[i]);
            if (typeReward == TypeReward.ONLY_MFS || core.getWorkflowStage() == Workflow.SaleOpen) {
                transferMFSFrom(
                    registry.getMetaPool(),
                    marketingReferrers[i],
                    amountMFS.mul(rewardsMarketingRefers[i])
                );
            } else if (typeReward == TypeReward.ONLY_USD) {
                stableCoin.transferFrom(
                    registry.getMetaPool(),
                    marketingReferrers[i],
                    amountUSD.mul(rewardsMarketingRefers[i])
                );
                amountMFSForRealization += amountMFS.mul(rewardsMarketingRefers[i]);
            } else {
                uint256 tempAmount = amountMFS.mul(rewardsMarketingRefers[i]) / 2;
                transferMFSFrom(registry.getMetaPool(), marketingReferrers[i], tempAmount);
                amountMFSForRealization += tempAmount;
                tempAmount = amountUSD.mul(rewardsMarketingRefers[i]) / 2;
                stableCoin.transferFrom(registry.getMetaPool(), marketingReferrers[i], tempAmount);
            }
        }
        realizeMFS(amountMFSForRealization);
    }

    function realizeMFS(uint256 amount) internal {
        IRequestMFSContract requestContract = IRequestMFSContract(registry.getRequestMFSContract());
        IMFS mfs = IMFS(registry.getMFS());
        mfs.burn(registry.getMetaPool(), requestContract.realizeMFS(amount));
    }

    function transferMFSFrom(
        address from,
        address to,
        uint256 amount
    ) internal {
        ICoreContract core = ICoreContract(registry.getCoreContract());
        if (core.getWorkflowStage() == Workflow.SaleOpen) {
            IMFS mfs = IMFS(registry.getMFS());
            mfs.transferFrom(from, to, amount);
        } else {
            core.increaseFrozenMFS(to, amount);
            core.decreaseFrozenMFS(from, amount);
        }
        emit MFCTransferMFS(from, to, amount);
    }

    function mintMFS(address to, uint256 amount) internal {
        ICoreContract core = ICoreContract(registry.getCoreContract());
        if (core.getWorkflowStage() == Workflow.SaleOpen) {
            address metaPool = registry.getMetaPool();
            if (to != metaPool) {
                transferMFSFrom(metaPool, to, amount);
            }
        } else {
            core.increaseFrozenMFS(to, amount);
        }
        increaseTotalEmission(amount);
        emit MFCMintMFS(to, amount);
    }

    function nextBigBlock() internal {
        bigBlockSize = bigBlockSize.div(COEFF_DECREASE_NEXT_BB);
        meanSmallBlock = bigBlockSize / MB_COUNT;
        nowNumberSmallBlock = 0;
        nowNumberBigBlock++;
        endSmallBlock =
            endBigBlock +
            meanSmallBlock.mul(COEFF_FIRST_MB - COEFF_DECREASE_COST_PACK_NEXT_MB * nowNumberSmallBlock);
        endBigBlock = endBigBlock + bigBlockSize;
        nowCoeffDecreaseMicroBlock = START_COEFF_DECREASE_MICROBLOCK;
        nowPriceFirstPackInMFS = PRICE_PACK_LEVEL1_IN_MFS_FIRST_BB.div(
            COEFF_DECREASE_COST_PACK_NEXT_BB.pow(nowNumberBigBlock.convertIntToFixPoint())
        );
        priceMFSInUSD = PRICE_PACK_LEVEL1_IN_USD.div(nowPriceFirstPackInMFS);
        meanDecreaseMicroBlock = meanDecreaseMicroBlock.div(COEFF_DECREASE_NEXT_BB);
        emit MFCBigBlockMove(nowNumberBigBlock);
    }

    function nextSmallBlock() internal {
        if (nowNumberSmallBlock < MB_COUNT - 1) {
            nowNumberSmallBlock = nowNumberSmallBlock + 1;
            endSmallBlock =
                endSmallBlock +
                meanSmallBlock.mul(COEFF_FIRST_MB - COEFF_DECREASE_COST_PACK_NEXT_MB * nowNumberSmallBlock);
            nowPriceFirstPackInMFS = nowPriceFirstPackInMFS - meanDecreaseMicroBlock.mul(nowCoeffDecreaseMicroBlock);
            priceMFSInUSD = PRICE_PACK_LEVEL1_IN_USD.div(nowPriceFirstPackInMFS);
            nowCoeffDecreaseMicroBlock = nowCoeffDecreaseMicroBlock - COEFF_DECREASE_COST_PACK_NEXT_MB;
        } else {
            nextBigBlock();
        }
        emit MFCSmallBlockMove(nowNumberSmallBlock);
    }

    function increaseTotalEmission(uint256 amount) internal {
        totalEmissionMFS += amount;
        if (totalEmissionMFS > endSmallBlock) {
            nextSmallBlock();
        }
    }

    function renewalConditions(uint256 level, uint256 amount) internal view {
        ICoreContract core = ICoreContract(registry.getCoreContract());
        if (level > LEVELS_COUNT) {
            revert MFCLevelMoreMaxPackLevel();
        }
        if (level == 0) {
            revert MFCPackLevelIs0();
        }
        if (amount == 0) {
            revert MFCRenewalAmountIs0();
        }
        for (uint256 i = 1; i <= level; i++) {
            if (!core.isPackActive(msg.sender, i)) {
                revert MFCNeedActivatePack(i);
            }
        }
    }

    function calcMFSAmountForUSD(uint256 amountUSD) internal view returns (uint256 amount) {
        amount = amountUSD.div(priceMFSInUSD);
        if (totalEmissionMFS + amount > endSmallBlock) {
            uint256 amountInOldPrice = endSmallBlock - totalEmissionMFS;
            uint256 balance = amountUSD - amountInOldPrice.mul(priceMFSInUSD);
            uint256 amountInNewPrice = balance.div(calculateNextMFSPrice());
            amount = amountInOldPrice + amountInNewPrice;
        }
    }

    function calcUSDAmountForMFS(uint256 amountMFS) internal view returns (uint256 amountUSD) {
        if (totalEmissionMFS + amountMFS > endSmallBlock) {
            uint256 amountBefore = endSmallBlock - totalEmissionMFS;
            uint256 amountAfter = totalEmissionMFS + amountMFS - endSmallBlock;

            uint256 amountInOldPrice = priceMFSInUSD.mul(amountBefore);
            uint256 amountInNewPrice = amountAfter.mul(calculateNextMFSPrice());

            amountUSD = amountInOldPrice + amountInNewPrice;
        } else {
            amountUSD = priceMFSInUSD.mul(amountMFS);
        }
    }

    function calculateNextMFSPrice() internal view returns (uint256 nextPriceMFS) {
        if (nowNumberSmallBlock < 9) {
            uint256 nextPriceFirstPackInMFS = nowPriceFirstPackInMFS -
                meanDecreaseMicroBlock.mul(nowCoeffDecreaseMicroBlock);
            nowPriceFirstPackInMFS.mul(nowCoeffDecreaseMicroBlock);
            nextPriceMFS = PRICE_PACK_LEVEL1_IN_USD.div(nextPriceFirstPackInMFS);
        } else {
            nextPriceMFS = PRICE_PACK_LEVEL1_IN_USD.div(PRICE_PACK_LEVEL1_IN_MFS_FIRST_BB.div(COEFF_DECREASE_NEXT_BB));
        }
    }
}

// SPDX-License-Identifier:  MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMFS is IERC20 {
    function mint(address to, uint256 amount) external;

    function burn(address to, uint256 amount) external;

    function cap() external view returns (uint256);
}

interface IHMFS is IERC20 {
    function mint(address to, uint256 amount) external;

    function burn(address to, uint256 amount) external;

    function cap() external view returns (uint256);
}

interface IEnergy is IERC20 {
    function mint(address to, uint256 amount) external;

    function burn(address to, uint256 amount) external;
}

// SPDX-License-Identifier:  MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../Constants.sol";
import "./IRegistryContract.sol";

error MetaForceSpaceCoreNotAllowed();
error MetaForceSpaceCoreNoMoreSpaceInTree();
error MetaForceSpaceCoreInvalidCursor();
error MetaForceSpaceCoreActiveUser();
error MetaForceSpaceCoreReplaceSameAddress();
error MetaForceSpaceCoreNotEnoughFrozenMFS();
error MetaForceSpaceCoreSaleOpenIsLastWorkflowStep();
error MetaForceSpaceCoreSumRewardsMustBeHundred();
error MetaForceSpaceCoreRewardsIsNotChange();
error MetaForceSpaceCoreUserAlredyRegistered();

struct User {
    TypeReward rewardType;
    //address referrer;
    address marketingReferrer;
    uint256 mfsFrozenAmount;
    mapping(uint256 => uint256) packs;
    //uint256 registrationDate;
    //EnumerableSet.AddressSet referrals;
    EnumerableSet.AddressSet marketingReferrals;
}

enum TypeReward {
    ONLY_MFS,
    MFS_AND_USD,
    ONLY_USD
}

interface IClassicReferal {
    function parent(address user) external view returns (address);

    function childs(address user) external view returns (address[] memory);

    function getRegistrationDate(address user) external view returns (uint256);
}

interface ICoreContract {
    event ReferrerChanged(address indexed account, address indexed referrer);
    event MarketingReferrerChanged(address indexed account, address indexed marketingReferrer);
    event TimestampEndPackSet(address indexed account, uint256 level, uint256 timestamp);
    event WorkflowStageMove(Workflow workflowstage);
    event RewardsReferrerSetted();
    event UserIsRegistered(address indexed user, address indexed referrer);
    event PoolMFSBurned();

    //Set referrer in referral tree
    //function setReferrer(address user, address referrer) external;

    //Set referrer in Marketing tree
    function setMarketingReferrer(address user, address marketingReferrer) external;

    //Set users type reward
    function setTypeReward(address user, TypeReward typeReward) external;

    //Increase timestamp end pack of the corresponding level
    function increaseTimestampEndPack(
        address user,
        uint256 level,
        uint256 time
    ) external;

    //Set timestamp end pack of the corresponding level
    function setTimestampEndPack(
        address user,
        uint256 level,
        uint256 timestamp
    ) external;

    //increase user frozen MFS in mapping
    function increaseFrozenMFS(address user, uint256 amount) external;

    //decrease user frozen MFS in mapping
    function decreaseFrozenMFS(address user, uint256 amount) external;

    //delete user in referral tree and marketing tree
    function clearInfo(address user) external;

    // replace user (place in referral and marketing tree(refer and all referrals), frozenMFS, and packages)
    function replaceUser(address to) external;

    //replace user in marketing tree(refer and all referrals)
    function replaceUserInMarketingTree(address from, address to) external;

    function nextWorkflowStage() external;

    function setEnergyConversionFactor(uint256 _energyConversionFactor) external;

    function setRewardsDirectReferrers(uint256[] calldata _rewardsRefers) external;

    function setRewardsMarketingReferrers(uint256[] calldata _rewardsMarketingRefers) external;

    function setRewardsReferrers(uint256[] calldata _rewardsRefers, uint256[] calldata _rewardsMarketingRefers)
        external;

    //function registration() external;

    //function registration(address referer) external;

    // Check have referrer in referral tree
    function checkRegistration(address user) external view returns (bool);

    // Request user type reward
    function getTypeReward(address user) external view returns (TypeReward);

    // request user frozen MFS in mapping
    function getAmountFrozenMFS(address user) external view returns (uint256);

    // Request timestamp end pack of the corresponding level
    function getTimestampEndPack(address user, uint256 level) external view returns (uint256);

    // Request user referrer in referral tree
    function getReferrer(address user) external view returns (address);

    // Request user referrer in marketing tree
    function getMarketingReferrer(address user) external view returns (address);

    //Request user some referrals starting from indexStart in referral tree
    /*function getReferrals(
        address user,
        uint256 indexStart,
        uint256 amount
    ) external view returns (address[] memory);*/

    // Request user some referrers (father, grandfather, great-grandfather and etc.) in referral tree
    function getReferrers(
        address user,
        uint256 level,
        uint256 amount
    ) external view returns (address[] memory);

    /*Request user's some referrers (father, grandfather, great-grandfather and etc.)
    in marketing tree having of the corresponding level*/
    function getMarketingReferrers(
        address user,
        uint256 level,
        uint256 amount
    ) external view returns (address[] memory);

    //Request user referrals starting from indexStart in marketing tree
    function getMarketingReferrals(address user) external view returns (address[] memory);

    //get user level (maximum active level)
    function getUserLevel(address user) external view returns (uint256);

    //function getReferralsAmount(address user) external view returns (uint256);

    function getFrozenMFSTotalAmount() external view returns (uint256);

    function root() external view returns (address);

    function isPackActive(address user, uint256 level) external view returns (bool);

    function getWorkflowStage() external view returns (Workflow);

    function getRewardsDirectReferrers() external view returns (uint256[] memory);

    function getRewardsMarketingReferrers() external view returns (uint256[] memory);

    function getDateStartSaleOpen() external view returns (uint256);

    function getEnergyConversionFactor() external view returns (uint256);

    function getRegistrationDate(address user) external view returns (uint256);

    function getLevelForNFT(address _user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

error MetaForceSpaceHoldingLevelDontExist(uint256 levelNumber);
error MetaForceSpaceHoldingLockupPeriodTooSmall(uint256 lockupPeriod);
error MetaForceSpaceHoldingDepositDontExist(uint256 depositId);
error MetaForceSpaceHoldingNotAllowed();
error MetaForceSpaceHoldingInsufficientDepositAmount(uint256 depositId, uint256 amount);
error MetaForceSpaceHoldingAmountIsZero(uint256 depositId);
error MetaForceSpaceHoldingDepositInactive(uint256 depositId);

struct Deposit {
    address holder;
    bool unholdingAllowed;
    uint8 levelNumber;
    uint224 amount;
    uint32 lockedUntil;
}

interface IHoldingContract {
    event Hold(uint256 indexed depositId, uint256 levelNumber, uint256 amount);
    event Unhold(uint256 indexed depositId, uint256 amount);

    function hold(uint256 level, uint256 amount) external returns (uint256);

    function holdOnBehalf(
        address beneficiary,
        uint256 level,
        uint256 amount
    ) external returns (uint256);

    function unhold(uint256 depositId, uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getDeposit(uint256 depositId) external view returns (Deposit memory);

    function getDepositIds(address holder) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
import "./IRegistryContract.sol";

error MFCUserNotRegisteredYet();
error MFCLevelMoreMaxPackLevel();
error MFCPackLevelIs0();
error MFCEarlyStageForActivatePack();
error MFCNeedActivatePack(uint256 level);
error MFCNeedRenewalPack(uint256 level);
error MFCPackIsActive(uint256 level);
error MFCSenderIsNotRequestMFSContract();
error MFCNotFirstActivationPack();
error MFCBuyLimitOfMFSExceeded(uint256 shortage);
error MFCUserIsNotRegistredInMarketing();
error MFCRefererNotCantBeSelf();
error MFCEarlyStageForRenewalPackInHMFS();
error MFCRenewalPaymentIsOnlyPossibleInHMFS();
error MFCNoFundsOnAccount();
error MFCToEarlyToCashing();
error MFCRenewalInThisStageOnlyForMFS();
error MFCEmissionCommitted();
error MFCLateForBuyMFS();
error MFCSizeArrayDifferentFromExpected();
error MFCNotEnoughHMFSNeedLevel();
error MFCRenewalAmountIs0();

enum TypeRenewalCurrency {
    MFS,
    hMFS1,
    hMFS2,
    hMFS3,
    hMFS4,
    hMFS5,
    hMFS6,
    hMFS7,
    hMFS8
}

struct DatesBuyingMFS {
    uint256 date;
    uint256 amount;
}

interface IMetaForceContract {
    event MFCSmallBlockMove(uint256 nowNumberSmallBlock);
    event MFCBigBlockMove(uint256 nowNumberBigBlock);
    event MFCMintMFS(address indexed to, uint256 amount);
    event MFCTransferMFS(address indexed from, address indexed to, uint256 amount);
    event MFCPackIsRenewed(address indexed user, uint256 level, uint256 timestampEndPack);
    event MFCPackIsActivated(address indexed user, uint256 level, uint256 timestampEndPack);
    event MFCRegistryContractAddressSetted(address registry);

    function setRegistryContract(IRegistryContract _registry) external;

    function buyMFS(uint256 amount) external;

    function activationPack(uint256 level) external;

    function firstActivationPack(address marketinReferrer) external;

    function firstActivationPackWithReplace(address replace) external;

    function renewalPack(
        uint256 level,
        uint256 amount,
        TypeRenewalCurrency typeCurrency
    ) external;

    function renewalPack(
        uint256 level,
        uint256 amount,
        uint256[] memory amountCurrency
    ) external;

    function giveMFSFromPool(address to, uint256 amount) external;

    function cashingFrozenMFS() external;

    function distibuteEmission() external;

    function priceMFSInUSD() external view returns (uint256);
}

// SPDX-License-Identifier:  MIT
pragma solidity 0.8.15;

interface IRegistryContract {
    function setHoldingContract(address _holdingContract) external;

    function setMetaForceContract(address _metaForceContract) external;

    function setCoreContract(address _coreContract) external;

    function setMFS(address _mfs) external;

    function setHMFS(uint256 level, address _hMFS) external;

    function setStableCoin(address _stableCoin) external;

    function setRequestMFSContract(address _requestMFSContract) external;

    function setReferalClassicContract(address _referalClassicContract) external;

    function setEnergyCoin(address _energyCoin) external;

    function setRewardsFund(address addresscontract) external;

    function setLiquidityPool(address addresscontract) external;

    function setForsageParticipants(address addresscontract) external;

    function setMetaDevelopmentAndIncentiveFund(address addresscontract) external;

    function setTeamFund(address addresscontract) external;

    function setLiquidityListingFund(address addresscontract) external;

    function setMetaPool(address) external;

    function setRequestPool(address) external;

    function getHoldingContract() external view returns (address);

    function getMetaForceContract() external view returns (address);

    function getCoreContract() external view returns (address);

    function getMFS() external view returns (address);

    function getHMFS(uint256 level) external view returns (address);

    function getStableCoin() external view returns (address);

    function getEnergyCoin() external view returns (address);

    function getRequestMFSContract() external view returns (address);

    function getReferalClassicContract() external view returns (address);

    function getRewardsFund() external view returns (address);

    function getLiquidityPool() external view returns (address);

    function getForsageParticipants() external view returns (address);

    function getMetaDevelopmentAndIncentiveFund() external view returns (address);

    function getTeamFund() external view returns (address);

    function getLiquidityListingFund() external view returns (address);

    function getMetaPool() external view returns (address);

    function getRequestPool() external view returns (address);
}

// SPDX-License-Identifier:  MIT
pragma solidity 0.8.15;

error RMFSCAmountUSDIsSmall();
error RMFSCSenderIsNotOwner();
error RMFSCQueueIsEmpty();
error RMFSCSenderIsNotMetaForceContract();

interface IRequestMFSContract {
    function createRequestMFS(uint256 _amountUSD) external returns (uint256 requestId);

    function deleteRequestMFS(uint256 _requestId) external;

    function getNextLevel() external returns (uint256 levelQueue);

    function getNextRequestId() external returns (uint256 requestId);

    function getNumberInQueue(uint256 _requestId) external returns (uint256 numberInQueue);

    function getAddressRequester(uint256 _requestId) external returns (address requester);

    function getAmountUSDRequest(uint256 _requestId) external returns (uint256 amount);

    function realizeMFS(uint256 _amountMFS) external returns (uint256 amount);

    function getRequestsIdsForUser(address _user) external returns (uint256[] memory requestsIds);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./Math.sol";

error FixedPointMathMulDivOverflow(uint256 prod1, uint256 denominator);
error FixedPointMathExpArgumentTooBig(uint256 a);
error FixedPointMathExp2ArgumentTooBig(uint256 a);
error FixedPointMathLog2ArgumentTooBig(uint256 a);

uint256 constant SCALE = 1e18;

/// @title Fixed point math implementation
library FixedPointMath {
    uint256 internal constant HALF_SCALE = 5e17;
    /// @dev Largest power of two divisor of scale.
    uint256 internal constant SCALE_LPOTD = 262144;
    /// @dev Scale inverted mod 2**256.
    uint256 internal constant SCALE_INVERSE =
        78156646155174841979727994598816262306175212592076161876661508869554232690281;

    function mul(uint256 a, uint256 b) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 >= SCALE) {
            revert FixedPointMathMulDivOverflow(prod1, SCALE);
        }

        uint256 remainder;
        uint256 roundUpUnit;
        assembly {
            remainder := mulmod(a, b, SCALE)
            roundUpUnit := gt(remainder, 499999999999999999)
        }

        if (prod1 == 0) {
            assembly {
                result := add(div(prod0, SCALE), roundUpUnit)
            }
            return result;
        }

        assembly {
            result := add(
                mul(
                    or(
                        div(sub(prod0, remainder), SCALE_LPOTD),
                        mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, SCALE_LPOTD), SCALE_LPOTD), 1))
                    ),
                    SCALE_INVERSE
                ),
                roundUpUnit
            )
        }
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 result) {
        result = mulDiv(a, SCALE, b);
    }

    /// @notice Calculates ⌊a × b ÷ denominator⌋ with full precision.
    /// @dev Credit to Remco Bloemen under MIT license https://2π.com/21/muldiv.
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 >= denominator) {
            revert FixedPointMathMulDivOverflow(prod1, denominator);
        }

        if (prod1 == 0) {
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)

            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        unchecked {
            uint256 lpotdod = denominator & (~denominator + 1);
            assembly {
                denominator := div(denominator, lpotdod)
                prod0 := div(prod0, lpotdod)
                lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
            }
            prod0 |= prod1 * lpotdod;

            uint256 inverse = (3 * denominator) ^ 2;
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;

            result = prod0 * inverse;
        }
    }

    function exp2(uint256 x) internal pure returns (uint256 result) {
        if (x >= 192e18) {
            revert FixedPointMathExp2ArgumentTooBig(x);
        }

        unchecked {
            x = (x << 64) / SCALE;

            result = 0x800000000000000000000000000000000000000000000000;
            if (x & 0x8000000000000000 > 0) {
                result = (result * 0x16A09E667F3BCC909) >> 64;
            }
            if (x & 0x4000000000000000 > 0) {
                result = (result * 0x1306FE0A31B7152DF) >> 64;
            }
            if (x & 0x2000000000000000 > 0) {
                result = (result * 0x1172B83C7D517ADCE) >> 64;
            }
            if (x & 0x1000000000000000 > 0) {
                result = (result * 0x10B5586CF9890F62A) >> 64;
            }
            if (x & 0x800000000000000 > 0) {
                result = (result * 0x1059B0D31585743AE) >> 64;
            }
            if (x & 0x400000000000000 > 0) {
                result = (result * 0x102C9A3E778060EE7) >> 64;
            }
            if (x & 0x200000000000000 > 0) {
                result = (result * 0x10163DA9FB33356D8) >> 64;
            }
            if (x & 0x100000000000000 > 0) {
                result = (result * 0x100B1AFA5ABCBED61) >> 64;
            }
            if (x & 0x80000000000000 > 0) {
                result = (result * 0x10058C86DA1C09EA2) >> 64;
            }
            if (x & 0x40000000000000 > 0) {
                result = (result * 0x1002C605E2E8CEC50) >> 64;
            }
            if (x & 0x20000000000000 > 0) {
                result = (result * 0x100162F3904051FA1) >> 64;
            }
            if (x & 0x10000000000000 > 0) {
                result = (result * 0x1000B175EFFDC76BA) >> 64;
            }
            if (x & 0x8000000000000 > 0) {
                result = (result * 0x100058BA01FB9F96D) >> 64;
            }
            if (x & 0x4000000000000 > 0) {
                result = (result * 0x10002C5CC37DA9492) >> 64;
            }
            if (x & 0x2000000000000 > 0) {
                result = (result * 0x1000162E525EE0547) >> 64;
            }
            if (x & 0x1000000000000 > 0) {
                result = (result * 0x10000B17255775C04) >> 64;
            }
            if (x & 0x800000000000 > 0) {
                result = (result * 0x1000058B91B5BC9AE) >> 64;
            }
            if (x & 0x400000000000 > 0) {
                result = (result * 0x100002C5C89D5EC6D) >> 64;
            }
            if (x & 0x200000000000 > 0) {
                result = (result * 0x10000162E43F4F831) >> 64;
            }
            if (x & 0x100000000000 > 0) {
                result = (result * 0x100000B1721BCFC9A) >> 64;
            }
            if (x & 0x80000000000 > 0) {
                result = (result * 0x10000058B90CF1E6E) >> 64;
            }
            if (x & 0x40000000000 > 0) {
                result = (result * 0x1000002C5C863B73F) >> 64;
            }
            if (x & 0x20000000000 > 0) {
                result = (result * 0x100000162E430E5A2) >> 64;
            }
            if (x & 0x10000000000 > 0) {
                result = (result * 0x1000000B172183551) >> 64;
            }
            if (x & 0x8000000000 > 0) {
                result = (result * 0x100000058B90C0B49) >> 64;
            }
            if (x & 0x4000000000 > 0) {
                result = (result * 0x10000002C5C8601CC) >> 64;
            }
            if (x & 0x2000000000 > 0) {
                result = (result * 0x1000000162E42FFF0) >> 64;
            }
            if (x & 0x1000000000 > 0) {
                result = (result * 0x10000000B17217FBB) >> 64;
            }
            if (x & 0x800000000 > 0) {
                result = (result * 0x1000000058B90BFCE) >> 64;
            }
            if (x & 0x400000000 > 0) {
                result = (result * 0x100000002C5C85FE3) >> 64;
            }
            if (x & 0x200000000 > 0) {
                result = (result * 0x10000000162E42FF1) >> 64;
            }
            if (x & 0x100000000 > 0) {
                result = (result * 0x100000000B17217F8) >> 64;
            }
            if (x & 0x80000000 > 0) {
                result = (result * 0x10000000058B90BFC) >> 64;
            }
            if (x & 0x40000000 > 0) {
                result = (result * 0x1000000002C5C85FE) >> 64;
            }
            if (x & 0x20000000 > 0) {
                result = (result * 0x100000000162E42FF) >> 64;
            }
            if (x & 0x10000000 > 0) {
                result = (result * 0x1000000000B17217F) >> 64;
            }
            if (x & 0x8000000 > 0) {
                result = (result * 0x100000000058B90C0) >> 64;
            }
            if (x & 0x4000000 > 0) {
                result = (result * 0x10000000002C5C860) >> 64;
            }
            if (x & 0x2000000 > 0) {
                result = (result * 0x1000000000162E430) >> 64;
            }
            if (x & 0x1000000 > 0) {
                result = (result * 0x10000000000B17218) >> 64;
            }
            if (x & 0x800000 > 0) {
                result = (result * 0x1000000000058B90C) >> 64;
            }
            if (x & 0x400000 > 0) {
                result = (result * 0x100000000002C5C86) >> 64;
            }
            if (x & 0x200000 > 0) {
                result = (result * 0x10000000000162E43) >> 64;
            }
            if (x & 0x100000 > 0) {
                result = (result * 0x100000000000B1721) >> 64;
            }
            if (x & 0x80000 > 0) {
                result = (result * 0x10000000000058B91) >> 64;
            }
            if (x & 0x40000 > 0) {
                result = (result * 0x1000000000002C5C8) >> 64;
            }
            if (x & 0x20000 > 0) {
                result = (result * 0x100000000000162E4) >> 64;
            }
            if (x & 0x10000 > 0) {
                result = (result * 0x1000000000000B172) >> 64;
            }
            if (x & 0x8000 > 0) {
                result = (result * 0x100000000000058B9) >> 64;
            }
            if (x & 0x4000 > 0) {
                result = (result * 0x10000000000002C5D) >> 64;
            }
            if (x & 0x2000 > 0) {
                result = (result * 0x1000000000000162E) >> 64;
            }
            if (x & 0x1000 > 0) {
                result = (result * 0x10000000000000B17) >> 64;
            }
            if (x & 0x800 > 0) {
                result = (result * 0x1000000000000058C) >> 64;
            }
            if (x & 0x400 > 0) {
                result = (result * 0x100000000000002C6) >> 64;
            }
            if (x & 0x200 > 0) {
                result = (result * 0x10000000000000163) >> 64;
            }
            if (x & 0x100 > 0) {
                result = (result * 0x100000000000000B1) >> 64;
            }
            if (x & 0x80 > 0) {
                result = (result * 0x10000000000000059) >> 64;
            }
            if (x & 0x40 > 0) {
                result = (result * 0x1000000000000002C) >> 64;
            }
            if (x & 0x20 > 0) {
                result = (result * 0x10000000000000016) >> 64;
            }
            if (x & 0x10 > 0) {
                result = (result * 0x1000000000000000B) >> 64;
            }
            if (x & 0x8 > 0) {
                result = (result * 0x10000000000000006) >> 64;
            }
            if (x & 0x4 > 0) {
                result = (result * 0x10000000000000003) >> 64;
            }
            if (x & 0x2 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
            if (x & 0x1 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }

            result *= SCALE;
            result >>= (191 - (x >> 64));
        }
    }

    function pow(uint256 x, uint256 y) internal pure returns (uint256 result) {
        if (x == 0) {
            result = y == 0 ? SCALE : uint256(0);
        } else {
            result = exp2(mul(log2(x), y));
        }
    }

    function log2(uint256 x) internal pure returns (uint256 result) {
        if (x < SCALE) {
            revert FixedPointMathLog2ArgumentTooBig(x);
        }
        unchecked {
            uint256 n = Math.mostSignificantBit(x / SCALE);

            result = n * SCALE;

            uint256 y = x >> n;

            if (y == SCALE) {
                return result;
            }

            for (uint256 delta = HALF_SCALE; delta > 0; delta >>= 1) {
                y = (y * y) / SCALE;

                if (y >= 2 * SCALE) {
                    result += delta;

                    y >>= 1;
                }
            }
        }
    }

    function convertIntToFixPoint(uint256 integer) internal pure returns (uint256 result) {
        result = integer * SCALE;
    }

    function convertFixPointToInt(uint256 integer) internal pure returns (uint256 result) {
        result = integer / SCALE;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

library Math {
    function mostSignificantBit(uint256 x) internal pure returns (uint256 msb) {
        if (x >= 2**128) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 2**64) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 2**32) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 2**16) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 2**8) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 2**4) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 2**2) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 2**1) {
            // No need to shift x any more.
            msb += 1;
        }
    }
}