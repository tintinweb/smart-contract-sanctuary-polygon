// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";
import "./shared/HodlLib.sol";
import "./shared/MintMath.sol";
import "./shared/Interfaces.sol";

contract HodlV1 is
    IHodl,
    OwnableUpgradeable,
    ERC2771ContextUpgradeable,
    UUPSUpgradeable
{
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IPurpose private immutable _prps;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IDubi private immutable _dubi;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address prps,
        address dubi,
        address trustedForwarder
    ) ERC2771ContextUpgradeable(trustedForwarder) {
        require(
            prps != address(0) || dubi != address(0),
            "HODL_V1: bad initialize"
        );

        _prps = IPurpose(prps);
        _dubi = IDubi(dubi);
    }

    event HodlHodl(
        uint24 hodlId,
        address creator,
        uint96 amountPrps,
        uint16 duration,
        address dubiBeneficiary,
        address prpsBeneficiary
    );

    event HodlRelease(bytes32 key, uint96 prps);

    event HodlWithdraw(bytes32 key, uint96 dubi);

    event HodlBurned(
        bytes32 key,
        uint96 burnedPrps,
        uint96 mintedDubi,
        bool deleted
    );

    mapping(bytes32 => HodlLib.PackedHodlItem) private _hodls;

    function initialize() public initializer {
        __Ownable_init_unchained();
    }

    function getHodl(
        uint32 id,
        address prpsBeneficiary,
        address creator
    ) public view returns (HodlLib.PrettyHodlItem memory) {
        bytes32 key = HodlLib.getHodlKey({
            creator: creator,
            prpsBeneficiary: prpsBeneficiary,
            hodlId: id
        });

        return getHodlByKey(key);
    }

    function getHodlByKey(bytes32 key)
        public
        view
        returns (HodlLib.PrettyHodlItem memory)
    {
        HodlLib.PackedHodlItem storage _packed = _hodls[key];

        HodlLib.PrettyHodlItem memory pretty;

        // return default value if it doesn't exist
        if (_packed.packedData == 0) {
            return pretty;
        }

        HodlLib.UnpackedHodlItem memory _unpacked = HodlLib.unpackHodlItem(
            _packed.packedData
        );

        address _creator = _packed.prpsBeneficiary;
        if (_packed.creator != address(0)) {
            _creator = _packed.creator;
        }

        address _dubiBeneficiary = _packed.dubiBeneficiary;
        if (_dubiBeneficiary == address(0)) {
            _dubiBeneficiary = _packed.prpsBeneficiary;
        }

        pretty.id = _unpacked.id;
        pretty.duration = _unpacked.duration;
        pretty.lastWithdrawal = _unpacked.lastWithdrawal;
        pretty.lockedPrps = _unpacked.lockedPrps;
        pretty.burnedLockedPrps = _unpacked.burnedLockedPrps;
        pretty.prpsBeneficiary = _packed.prpsBeneficiary;
        pretty.creator = _creator;
        pretty.dubiBeneficiary = _dubiBeneficiary;
        return pretty;
    }

    function hodl(
        uint24 hodlId,
        uint96 amountPrps,
        uint16 duration,
        address dubiBeneficiary,
        address prpsBeneficiary
    ) external {
        _hodl(
            hodlId,
            _msgSender(),
            amountPrps,
            duration,
            dubiBeneficiary,
            prpsBeneficiary
        );
    }

    /**
     * @dev Lock the given amount of PRPS for the specified period (or infinitely)
     * for DUBI.
     *
     * The lock duration is given in seconds where the maximum is `31536000` seconds (365 days) after
     * which the PRPS becomes releasable again.
     *
     * A lock duration of '0' has a special meaning and is used to lock PRPS infinitely,
     * without being able to unlock it ever again.
     *
     * DUBI minting:
     * - If locking PRPS finitely, the caller immediately receives DUBI proportionally to the
     * duration of the hodl and the amount of PRPS.
     *
     * If locking for the maximum duration of 365 days (or infinitely), the caller gets
     * 4% of the hodled PRPS worth of DUBI.
     *
     * Additionally, `withdraw` can be called with a hodl id that corresponds to a permanent
     * lock and the beneficiary receives DUBI based on the passed time since the
     * last `withdraw`.
     *
     * In both cases - whether locking infinitely or finitely - the maximum amount of DUBI per
     * year one can mint is equal to 4% of the hodled PRPS. DUBI from infinitely locked PRPS
     * is simply available earlier.
     */
    function _hodl(
        uint24 hodlId,
        address creator,
        uint96 amountPrps,
        uint16 duration,
        address dubiBeneficiary,
        address prpsBeneficiary
    ) private {
        bytes32 key = _validateHodlAndGetKey(
            hodlId,
            creator,
            prpsBeneficiary,
            dubiBeneficiary,
            amountPrps,
            duration
        );

        // Calculate release time. If `duration` is 0,
        // then the PRPS is locked infinitely.
        uint96 dubiToMint;

        // Calculate the release time and DUBI to mint.
        // When locking finitely, it is based on the actual duration.
        // When locking infinitely, a full year is minted up front.
        if (duration > 0) {
            dubiToMint = MintMath.calculateDubiToMintByDays(
                amountPrps,
                duration
            );
        } else {
            dubiToMint = MintMath.calculateDubiToMintMax(amountPrps);
        }

        require(dubiToMint > 0, "HODL_V1: bad mint amount");

        // Update hodl balance of beneficiary by calling into the PRPS contract.
        _prps.lockPrps(creator, prpsBeneficiary, amountPrps);

        HodlLib.UnpackedHodlItem memory _unpacked;
        _unpacked.id = hodlId;
        _unpacked.duration = duration;
        _unpacked.lockedPrps = amountPrps;
        _unpacked.lastWithdrawal = uint32(block.timestamp);

        HodlLib.PackedHodlItem memory _packed;
        _packed.prpsBeneficiary = prpsBeneficiary;

        // Rare case
        if (creator != prpsBeneficiary) {
            _packed.creator = creator;
        }

        // Rare case
        if (dubiBeneficiary != prpsBeneficiary) {
            _packed.dubiBeneficiary = dubiBeneficiary;
        }

        // Write to storage and mint DUBI
        _packed.packedData = HodlLib.packHodlItem(_unpacked);
        _hodls[key] = _packed;

        _dubi.hodlMint(dubiBeneficiary, dubiToMint);

        emit HodlHodl(
            hodlId,
            creator,
            amountPrps,
            duration,
            dubiBeneficiary,
            prpsBeneficiary
        );
    }

    function release(
        uint24 id,
        address prpsBeneficiary,
        address creator
    ) external {
        (
            bytes32 key,
            ,
            /* HodlLib.PackedHodlItem storage packed */
            HodlLib.UnpackedHodlItem memory unpacked
        ) = _safeGetHodl({
                id: id,
                prpsBeneficiary: prpsBeneficiary,
                creator: creator
            });

        require(
            HodlLib.isHodlExpired(
                uint32(block.timestamp),
                unpacked.lastWithdrawal,
                unpacked.duration
            ),
            "HODL_V1: not expired"
        );

        // Get releasable PRPS, that is locked PRPS - burned PRPS
        assert(unpacked.lockedPrps >= unpacked.burnedLockedPrps);
        uint96 releasablePrps = unpacked.lockedPrps - unpacked.burnedLockedPrps;

        delete _hodls[key];

        _prps.unlockPrps(prpsBeneficiary, releasablePrps);

        emit HodlRelease(key, releasablePrps);
    }

    /**
     * @dev Withdraw can be used to withdraw DUBI from infinitely locked PRPS.
     * The amount of DUBI withdrawn depends on the time passed since the last withdrawal.
     *
     * All minted DUBI is sent to the DUBI beneficiary.
     */
    function withdraw(
        uint24 id,
        address prpsBeneficiary,
        address creator
    ) external {
        (
            bytes32 key,
            HodlLib.PackedHodlItem storage packed,
            HodlLib.UnpackedHodlItem memory unpacked
        ) = _safeGetHodl({
                id: id,
                prpsBeneficiary: prpsBeneficiary,
                creator: creator
            });

        require(unpacked.duration == 0, "HODL_V1: finite lock duration");

        uint32 lastWithdrawal = unpacked.lastWithdrawal;

        address dubiBeneficiary = packed.dubiBeneficiary;
        if (packed.dubiBeneficiary == address(0)) {
            dubiBeneficiary = prpsBeneficiary;
        }

        // Must be in the past (i.e. less than block timestamp), practically impossible
        require(
            lastWithdrawal > 0 && lastWithdrawal < block.timestamp,
            "HODL_V1: bad time"
        );

        // NOTE: safe to assume that this always fits into a uint32 without overflow
        // for the forseeable future.
        uint32 timePassedSinceLastWithdrawal = uint32(
            block.timestamp - lastWithdrawal
        );

        // Take burned PRPS into account
        uint96 lockedPrps = unpacked.lockedPrps - unpacked.burnedLockedPrps;
        assert(lockedPrps > 0 && lockedPrps <= unpacked.lockedPrps);

        // Calculate amount of DUBI based on time passed (in seconds) since last withdrawal.
        // The minted DUBI is guaranteed to be > 0, else the transaction will revert.
        uint96 dubiToMint = MintMath.calculateDubiToMintBySeconds(
            lockedPrps,
            timePassedSinceLastWithdrawal
        );
        require(dubiToMint > 0, "HODL_V1: insufficient DUBI");

        unpacked.lastWithdrawal = uint32(block.timestamp);
        packed.packedData = HodlLib.packHodlItem(unpacked);

        _dubi.hodlMint(dubiBeneficiary, dubiToMint);

        emit HodlWithdraw(key, dubiToMint);
    }

    /**
     * @dev Burn `amount` of the senders locked PRPS. A pro-rated amount of DUBI is auto-minted
     * before burning, to make up for an eventual suboptimal timing of the PRPS burn.
     *
     * Whether burning infinitely or finitely locked PRPS, the amount of minted DUBI over the same timespan
     * will be the same.
     *
     * This function is supposed to be only called by the PRPS contract and returns the amount of
     * DUBI that needs to be minted.
     *
     */
    function purposeLockedBurn(
        address from,
        uint96 amount,
        uint32 dubiMintTimestamp,
        bytes32[] calldata hodlKeys
    ) external override returns (uint96) {
        // NOTE: msg.sender is intentional
        require(msg.sender == address(_prps), "HODL_V1: bad caller");

        // Hodls are burned in the order they are passed in.

        uint96 remainingPrpsToBurn = amount;
        uint96 dubiToMint = 0;

        for (uint256 i = 0; i < hodlKeys.length; i++) {
            bytes32 key = hodlKeys[i];
            HodlLib.PackedHodlItem storage packed = _hodls[key];
            require(
                packed.packedData > 0,
                "HODL_V1: burn of non-existent hodl"
            );
            require(
                packed.prpsBeneficiary == from,
                "HODL_V1: bad PRPS beneficiary"
            );

            HodlLib.UnpackedHodlItem memory unpacked = HodlLib.unpackHodlItem(
                packed.packedData
            );

            // New scope to workaround: CompilerError: Stack too deep, try removing local variables.
            {
                address dubiBeneficiary = from;
                if (packed.dubiBeneficiary != address(0)) {
                    dubiBeneficiary = packed.dubiBeneficiary;
                }
                require(
                    dubiBeneficiary == from,
                    "HODL_V1: bad DUBI beneficiary"
                );
            }

            (
                uint192 packedBurnHodlAmount,
                bool deleteHodl
            ) = _burnPrpsFromHodl({
                    packed: packed,
                    unpacked: unpacked,
                    remainingPrpsToBurn: remainingPrpsToBurn,
                    dubiMintTimestamp: dubiMintTimestamp
                });

            if (deleteHodl) {
                delete _hodls[key];
            }

            // Calculate the pro-rated amount of DUBI to mint based on the PRPS
            // that gets burned from the locked.
            // The lower 96 bits of 'packedBurnHodlAmount' correspond to the `dubiToMint` amount.
            dubiToMint += uint96(packedBurnHodlAmount);

            // Reduce amount that is left to burn from hodl
            uint96 burnedAmount = uint96(packedBurnHodlAmount >> 96);

            // NOTE: This assert here cannot be hit assuming that the PRPS contract is correct, since it doesn't even call into this function when there's insufficient locked prps.
            require(
                remainingPrpsToBurn >= burnedAmount,
                "HODL_V1: insufficient locked PRPS"
            );
            remainingPrpsToBurn -= burnedAmount;

            emit HodlBurned(
                key,
                burnedAmount,
                uint96(packedBurnHodlAmount),
                deleteHodl
            );

            // Stop iterating if we burnt enough PRPS
            if (remainingPrpsToBurn == 0) {
                break;
            }
        }

        // NOTE: This assert here cannot be hit assuming that the PRPS contract is correct, since it doesn't
        // even call into this function when there's insufficient locked prps.
        require(remainingPrpsToBurn == 0, "HODL_V1: remaining PRPS to burn");

        return dubiToMint;
    }

    function _burnPrpsFromHodl(
        HodlLib.PackedHodlItem storage packed,
        HodlLib.UnpackedHodlItem memory unpacked,
        uint96 remainingPrpsToBurn,
        uint32 dubiMintTimestamp
    )
        private
        returns (
            // NOTE: we return a single uint192 which contains two separate uint96 values
            // to workaround this error: 'CompilerError: Stack too deep, try removing local variables'
            // The upper 96-bits is the 'burnAmount' and the lower part the 'dubiToMint'.
            uint192,
            bool
        )
    {
        bool deleteHodl;

        // Calculate the duration to use when minting DUBI.
        uint32 _mintDuration = _calculateMintDuration(
            unpacked,
            dubiMintTimestamp
        );

        // Remaining PRPS on the lock that can be burned.
        //
        // Burnable PRPS is equal to locked PRPS - burned locked PRPS
        uint96 burnablePrpsOnHodl = unpacked.lockedPrps -
            unpacked.burnedLockedPrps;

        // Nothing to burn
        if (burnablePrpsOnHodl == 0) {
            return (0, false);
        }

        // Cap burn amount if the remaining PRPS to burn is less.
        uint96 burnAmount = remainingPrpsToBurn;
        if (burnAmount > burnablePrpsOnHodl) {
            burnAmount = burnablePrpsOnHodl;
        }

        // Burn PRPS from lock
        uint96 burnedLockedPrps = unpacked.burnedLockedPrps + burnAmount;

        // Delete hodl if all locked PRPS has been burned, otherwise
        // update burned locked PRPS.
        if (burnedLockedPrps < unpacked.lockedPrps) {
            unpacked.burnedLockedPrps = burnedLockedPrps;

            // Write updated hodl item to storage
            packed.packedData = HodlLib.packHodlItem(unpacked);
        } else {
            deleteHodl = true;
        }

        // Calculate the pro-rated amount of DUBI to mint based on the PRPS
        // that gets burned from the locked.
        uint96 dubiToMint = MintMath.calculateDubiToMintBySeconds(
            burnAmount,
            _mintDuration
        );

        // NOTE: we return a single uint192 which contains two separate uint96 values
        // to workaround this error: 'CompilerError: Stack too deep, try removing local variables'
        // The upper 96-bits is the 'burnAmount' and the lower part the 'dubiToMint'.
        // Also, it is safe to downcast to uint96, because PRPS/DUBI are using 18 decimals.
        uint192 packedResult = uint192(burnAmount) << 96;
        packedResult = packedResult | dubiToMint;
        return (packedResult, deleteHodl);
    }

    /**
     * @dev Calculate the DUBI mint duration for minting DUBI when burning locked PRPS.
     */
    function _calculateMintDuration(
        HodlLib.UnpackedHodlItem memory unpacked,
        uint32 dubiMintTimestamp
    ) private pure returns (uint32) {
        uint32 lastWithdrawal = unpacked.lastWithdrawal;
        uint16 durationInDays = unpacked.duration;

        // Offset the lastWithdrawal time for finite locks that have not been locked for the full duration
        // to account for otherwise missed-out DUBI, since the mint duration is pro-rated based on the max
        // lock duration possible.
        //
        // Example:
        // If locking for 3 months (=1%) and then burning after 2 months, he would only get 2+3 months
        // worth of DUBI.
        // If he had locked for 12 months (=4%) and then burned after 2 months, he would
        // have gotten 14 months worth of DUBI.
        //
        // To fix this, subtract the difference of actual lock duration and max lock duration from the
        // lastWithdrawal time.
        //
        // Examples with applied offset:
        // When locking for 3 months and burning after 2 months: 3 + 2 + (12-3) => 14 months worth of DUBI
        // When locking for 12 months and burning after 2 months: 12 + 2 + (12-12) => 14 months worth of DUBI
        //
        // This way nobody is at a disadvantage.
        if (durationInDays > 0) {
            uint32 durationInSeconds = uint32(durationInDays) * 24 * 60 * 60;
            lastWithdrawal -=
                MintMath.MAX_FINITE_LOCK_DURATION_SECONDS -
                durationInSeconds;

            // Sanity check
            assert(lastWithdrawal <= unpacked.lastWithdrawal);
        }

        // See Utils/MintMath.sol
        return
            MintMath.calculateMintDuration(dubiMintTimestamp, lastWithdrawal);
    }

    //---------------------------------------------------------------

    /**
     * @dev Create new hodls, without minting new DUBI.
     *
     * The creator becomes the PRPS/DUBI beneficiary.
     *
     */
    function migrateHodls(
        uint24[] calldata hodlIds,
        address[] calldata creators,
        uint96[] calldata hodlBalances,
        uint16[] calldata durations,
        uint32[] calldata createdAts
    ) external onlyOwner {
        for (uint256 i = 0; i < hodlIds.length; i++) {
            uint24 hodlId = hodlIds[i];
            address creator = creators[i];
            uint96 amountPrps = hodlBalances[i];
            uint16 duration = durations[i];
            uint32 createdAt = createdAts[i];

            bytes32 key = _validateHodlAndGetKey(
                hodlId,
                creator,
                creator,
                creator,
                amountPrps,
                duration
            );

            // Update hodl balance of beneficiary by calling into the PRPS contract.
            _prps.migrateLockedPrps(creator, amountPrps);

            HodlLib.UnpackedHodlItem memory _unpacked;
            _unpacked.id = hodlId;
            _unpacked.duration = duration;
            _unpacked.lockedPrps = amountPrps;
            _unpacked.lastWithdrawal = createdAt;

            HodlLib.PackedHodlItem memory _packed;
            _packed.packedData = HodlLib.packHodlItem(_unpacked);
            _packed.prpsBeneficiary = creator;

            _hodls[key] = _packed;
        }
    }

    function _validateHodlAndGetKey(
        uint24 hodlId,
        address creator,
        address prpsBeneficiary,
        address dubiBeneficiary,
        uint96 amountPrps,
        uint16 duration
    ) private view returns (bytes32) {
        require(creator != address(0), "HODL_V1: bad creator");
        require(amountPrps > 0 && hodlId > 0, "HODL_V1: bad input");
        require(
            duration >= 0 && duration <= 365,
            "HODL_V1: duration out of range"
        );
        require(
            dubiBeneficiary != address(0) && prpsBeneficiary != address(0),
            "HODL_V1: bad beneficiary"
        );

        bytes32 key = HodlLib.getHodlKey({
            creator: creator,
            prpsBeneficiary: prpsBeneficiary,
            hodlId: hodlId
        });

        HodlLib.PackedHodlItem storage packed = _hodls[key];
        require(packed.packedData == 0, "HODL_V1: key already in use");

        return key;
    }

    function _safeGetHodl(
        uint24 id,
        address prpsBeneficiary,
        address creator
    )
        private
        view
        returns (
            bytes32,
            HodlLib.PackedHodlItem storage,
            HodlLib.UnpackedHodlItem memory
        )
    {
        bytes32 key = HodlLib.getHodlKey({
            creator: creator,
            prpsBeneficiary: prpsBeneficiary,
            hodlId: id
        });

        HodlLib.PackedHodlItem storage packed = _hodls[key];
        require(packed.packedData > 0, "HODL_V1: key not found");

        HodlLib.UnpackedHodlItem memory unpacked = HodlLib.unpackHodlItem(
            packed.packedData
        );

        return (key, packed, unpacked);
    }

    function _msgSender()
        internal
        view
        virtual
        override(ERC2771ContextUpgradeable, ContextUpgradeable)
        returns (address sender)
    {
        sender = ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(ERC2771ContextUpgradeable, ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }

    // Upgradability

    function _authorizeUpgrade(address) internal view override onlyOwner {}

    function implementation() public view returns (address) {
        return _getImplementation();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771ContextUpgradeable is Initializable, ContextUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }

    /**
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

library HodlLib {
    // The packed hodl item makes heavy use of bit packing
    // to minimize storage costs.
    struct PackedHodlItem {
        // Contains the fields of a packed `UnpackedHodlItem`. See the struct definition
        // below for more information.
        uint256 packedData;
        // The prpsBeneficiary address is always set and usually equal to `creator` and `dubiBeneficiary`.
        address prpsBeneficiary;
        //
        // Mostly zero
        //
        // The creator address is only set if different than the `prpsBeneficiary`.
        address creator;
        // The dubiBeneficiary is only set if different than the `prpsBeneficiary`.
        address dubiBeneficiary;
    }

    // The unpacked hodl item contains the unpacked data of an hodl item from storage.
    // It minimizes storage reads, since only a single read from storage is necessary
    // in most cases to access all relevant data.
    //
    // NOTE: The bit-sizes of the fields are rounded up to the nearest Solidity type.
    struct UnpackedHodlItem {
        // The id of the hodl item allows for 2^24 = 16_777_216 hodls per address
        uint24 id;
        // The hodl duration is stored using 9 bits and measured in days.
        // Technically, allowing for 2^9 = 512 days, but we cap it to 365 days.
        // Actual size: uint12
        uint16 duration;
        // The last withdrawal timestamp in unix seconds (block timestamp). Defaults to
        // the creation date of the hodl.
        // Actual size: uint31
        uint32 lastWithdrawal;
        // Storing the PRPS amount in a uint96 still allows to lock up to ~ 7 billion PRPS
        // which is plenty enough.
        uint96 lockedPrps;
        uint96 burnedLockedPrps;
    }

    // Struct that contains all unpacked data and the additional almost-always zero fields from
    // the packed hodl item - returned from `getHodl()` to be more user-friendly to consume.
    struct PrettyHodlItem {
        uint24 id;
        uint16 duration;
        uint32 lastWithdrawal;
        uint96 lockedPrps;
        uint96 burnedLockedPrps;
        address prpsBeneficiary;
        address creator;
        address dubiBeneficiary;
    }

    /**
     * @dev Pack an unpacked hodl item and return a uint256
     */
    function packHodlItem(UnpackedHodlItem memory _unpackedHodlItem)
        internal
        pure
        returns (uint256)
    {
        //
        // Allows for 2^24 = 16_777_216 hodls per address
        // uint24 id;
        //
        // The hodl duration is stored using 9 bits and measured in days.
        // Technically, allowing for 2^9 = 512 days, but we only need 365 days anyway.
        // uint9 duration;
        //
        // The last withdrawal timestamp in unix seconds (block timestamp). Defaults to
        // the creation date of the hodl and uses 31 bits:
        // uint31 lastWithdrawal
        //
        // The PRPS amounts are stored in a uint96 which can hold up to ~ 7 billion PRPS
        // which is plenty enough.
        // uint96 lockedPrps;
        // uint96 burnedLockedPrps;
        //

        // Build the packed data according to the spec above.
        uint256 packedData;
        uint256 offset;

        // 1) Set first 24 bits to id
        uint24 id = _unpackedHodlItem.id;
        packedData |= uint256(id) << offset;
        offset += 24;

        // 2) Set next 9 bits to duration.
        // Since it is stored in a uint16 AND it with a bitmask where the first 9 bits are 1

        uint16 duration = _unpackedHodlItem.duration;
        uint16 durationMask = (1 << 9) - 1;
        packedData |= uint256(duration & durationMask) << offset;
        offset += 9;

        // 3) Set next 31 bits to withdrawal time
        // Since it is stored in a uint32 AND it with a bitmask where the first 31 bits are 1
        uint32 lastWithdrawal = _unpackedHodlItem.lastWithdrawal;
        uint32 lastWithdrawalMask = (1 << 31) - 1;
        packedData |= uint256(lastWithdrawal & lastWithdrawalMask) << offset;
        offset += 31;

        // 5) Set next 96 bits to locked PRPS
        // We don't need to apply a bitmask here, because it occupies the full 96 bit.
        packedData |= uint256(_unpackedHodlItem.lockedPrps) << offset;
        offset += 96;

        // 6) Set next 96 bits to burned locked PRPS
        // We don't need to apply a bitmask here, because it occupies the full 96 bit.
        packedData |= uint256(_unpackedHodlItem.burnedLockedPrps) << offset;
        offset += 96;

        assert(offset == 256);
        assert(packedData != 0);

        return packedData;
    }

    /**
     * @dev Unpack a packed hodl item.
     */
    function unpackHodlItem(uint256 packedData)
        internal
        pure
        returns (UnpackedHodlItem memory)
    {
        UnpackedHodlItem memory _unpacked;
        uint256 offset;

        // 1) Read id from the first 24 bits
        uint24 id = uint24(packedData >> offset);
        _unpacked.id = id;
        offset += 24;

        // 2) Read duration from the next 9 bits
        uint16 duration = uint16(packedData >> offset);
        uint16 durationMask = (1 << 9) - 1;
        _unpacked.duration = duration & durationMask;
        offset += 9;

        // 3) Read lastWithdrawal time from the next 31 bits
        uint32 lastWithdrawal = uint32(packedData >> offset);
        uint32 lastWithdrawalMask = (1 << 31) - 1;
        _unpacked.lastWithdrawal = lastWithdrawal & lastWithdrawalMask;
        offset += 31;

        // 4) Read locked PRPS from the next 96 bits
        // We don't need to apply a bitmask here, because it occupies the full 96 bit.
        _unpacked.lockedPrps = uint96(packedData >> offset);
        offset += 96;

        // 5) Read burned locked PRPS from the next 96 bits
        // We don't need to apply a bitmask here, because it occupies the full 96 bit.
        _unpacked.burnedLockedPrps = uint96(packedData >> offset);
        offset += 96;

        assert(offset == 256);

        return _unpacked;
    }

    function getHodlKey(
        address creator,
        address prpsBeneficiary,
        uint32 hodlId
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(creator, prpsBeneficiary, hodlId));
    }

    function isHodlExpired(
        uint32 _now,
        uint32 lastWithdrawal,
        uint16 lockDurationInDays
    ) internal pure returns (bool) {
        assert(_now >= lastWithdrawal);

        uint32 durationInSeconds = uint32(lockDurationInDays) * 24 * 60 * 60;

        bool hasExpiration = durationInSeconds > 0;
        bool isExpired = _now - lastWithdrawal >= durationInSeconds;

        return hasExpiration && isExpired;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

// NOTE: we ignore leap-seconds etc.
library MintMath {
    // The maximum number of seconds per month (365 * 24 * 60 * 60 / 12)
    uint32 public constant SECONDS_PER_MONTH = 2628000;
    // The maximum number of days PRPS can be finitely locked for
    uint16 public constant MAX_FINITE_LOCK_DURATION_DAYS = 365;
    // The maximum number of seconds PRPS can be finitely locked for
    uint32 public constant MAX_FINITE_LOCK_DURATION_SECONDS =
        uint32(MAX_FINITE_LOCK_DURATION_DAYS) * 24 * 60 * 60;

    /**
     * @dev Calculates the DUBI to mint based on the given amount of PRPS and duration in days.
     * NOTE: We trust the caller to ensure that the duration between 1 and 365.
     */
    function calculateDubiToMintByDays(
        uint256 amountPrps,
        uint16 durationInDays
    ) internal pure returns (uint96) {
        uint32 durationInSeconds = uint32(durationInDays) * 24 * 60 * 60;
        return calculateDubiToMintBySeconds(amountPrps, durationInSeconds);
    }

    /**
     * @dev Calculates the DUBI to mint based on the given amount of PRPS and duration in seconds.
     */
    function calculateDubiToMintBySeconds(
        uint256 amountPrps,
        uint32 durationInSeconds
    ) internal pure returns (uint96) {
        uint256 _percentage = percentage(
            durationInSeconds,
            MAX_FINITE_LOCK_DURATION_SECONDS,
            18 // precision in WEI, 10^18
        ) * 4; // A full lock grants 4%, so multiply by 4.

        // Multiply PRPS by the percentage and then divide by the precision (=10^8)
        // from the previous step
        uint256 _dubiToMint = (amountPrps * _percentage) / (1 ether * 100); // multiply by 100, because we deal with percentages

        // Assert that the calculated DUBI never overflows uint96
        assert(_dubiToMint < 2**96);

        return uint96(_dubiToMint);
    }

    function calculateDubiToMintMax(uint96 amount)
        internal
        pure
        returns (uint96)
    {
        return
            calculateDubiToMintBySeconds(
                amount,
                MAX_FINITE_LOCK_DURATION_SECONDS
            );
    }

    function calculateMintDuration(uint32 _now, uint32 lastWithdrawal)
        internal
        pure
        returns (uint32)
    {
        require(lastWithdrawal > 0 && lastWithdrawal <= _now, "MINT-1");

        uint256 _elapsedTotal = _now - lastWithdrawal;
        uint256 _proRatedYears = _elapsedTotal / SECONDS_PER_MONTH / 12;
        uint256 _elapsedInYear = _elapsedTotal %
            MAX_FINITE_LOCK_DURATION_SECONDS;

        //
        // Examples (using months instead of seconds):
        // calculation formula: (monthsSinceWithdrawal % 12) + (_proRatedYears * 12)

        // 1) Burn after 11 months since last withdrawal (number of years = 11 / 12 + 1 = 1)
        // => (11 % 12) + (years * 12) => 23 months worth of DUBI
        // => 23 months

        // 1) Burn after 4 months since last withdrawal (number of years = 4 / 12 + 1 = 1)
        // => (4 % 12) + (years * 12) => 16 months worth of DUBI
        // => 16 months

        // 2) Burn 0 months after withdrawal after 4 months (number of years = 0 / 12 + 1 = 1):
        // => (0 % 12) + (years * 12) => 12 months worth of DUBI (+ 4 months worth of withdrawn DUBI)
        // => 16 months

        // 3) Burn after 36 months since last withdrawal (number of years = 36 / 12 + 1 = 4)
        // => (36 % 12) + (years * 12) => 48 months worth of DUBI
        // => 48 months

        // 4) Burn 1 month after withdrawal after 35 months (number of years = 1 / 12 + 1 = 1):
        // => (1 % 12) + (years * 12) => 12 month worth of DUBI (+ 35 months worth of withdrawn DUBI)
        // => 47 months
        uint32 _mintDuration = uint32(
            _elapsedInYear + _proRatedYears * MAX_FINITE_LOCK_DURATION_SECONDS
        );

        return _mintDuration;
    }

    function percentage(
        uint256 numerator,
        uint256 denominator,
        uint256 precision
    ) internal pure returns (uint256) {
        return
            ((numerator * (uint256(10)**(precision + 1))) / denominator + 5) /
            uint256(10);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface IDubi {
    function purposeMint(address to, uint96 amount) external;

    function hodlMint(address to, uint96 amount) external;
}

interface IPurpose {
    function migrateLockedPrps(address to, uint96 amount) external;

    function lockPrps(
        address creator,
        address prpsBeneficiary,
        uint96 amount
    ) external;

    function unlockPrps(address from, uint96 amount) external;
}

interface IHodl {
    function purposeLockedBurn(
        address from,
        uint96 amount,
        uint32 dubiMintTimestamp,
        bytes32[] calldata hodlKeys
    ) external returns (uint96);
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
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}