// SPDX-FileCopyrightText: © 2022 Virtually Human Studio

// SPDX-License-Identifier: No-license

pragma solidity 0.8.11;

import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { RacingStorage } from "./RacingStorage.sol";
import { ICore } from "../../interfaces/ICore.sol";
import { ILendingRegistry } from "../../interfaces/ILendingRegistry.sol";
import { ILendingAgreement } from "../../interfaces/ILendingAgreement.sol";

/**
@title RacingArena
@author The VHS team
 */
contract RacingArena is RacingStorage {
    using SafeERC20 for IERC20;

    // -----------------------------------------
    // EVENTS
    // -----------------------------------------
    event PrizeClaimed(
        bytes32 indexed _raceId,
        address indexed _claimer,
        uint256 _claimAmount,
        uint256 indexed _horseId
    );

    event HorseRegistered(
        bytes32 indexed _raceId,
        address indexed _horseOwner,
        uint256 indexed _horseId,
        uint256 _gateNumber
    );

    event RaceCreated(bytes32 indexed _raceId, uint256 _length, uint256 _registrationFee);
    event RaceCanceled(bytes32 indexed _raceId, string _reason, address _canceler);
    event HorseRemovedFromRace(bytes32 indexed _raceId, uint256 _horseId, address _remover);

    modifier onlyOwnersAdmins() {
        require(hasRole(RACING_OWNERS_ADMIN_ROLE, _msgSender()), "Racing: unauthorized owner admin");
        _;
    }

    modifier onlyOwners() {
        require(hasRole(RACING_OWNERS_ROLE, _msgSender()), "Racing: unauthorized owner");
        _;
    }

    /**
    @notice Initializes state of contract
    @param feeReceiver_ Address that's going to receive fees
    @param weth_ Address of ERC20 WETH contract
    @param core_ Address of the Core contract
     */
    function initialize(
        address feeReceiver_,
        IERC20 weth_,
        ICore core_,
        ILendingRegistry lendingRegistry_
    ) external initializer {
        require(feeReceiver_ != address(0), "Racing: invalid fee receiver");
        require(address(weth_) != address(0), "Racing: invalid weth address");
        require(address(core_) != address(0), "Racing: invalid core address");
        require(address(lendingRegistry_) != address(0), "Racing: invalid lending registry address");

        feeReceiver = feeReceiver_;
        weth = weth_;
        core = core_;
        lendingRegistry = lendingRegistry_;
        // Access Control
        _setRoleAdmin(RACING_OWNERS_ROLE, RACING_OWNERS_ADMIN_ROLE);

        // Grants role to the caller
        _setupRole(RACING_OWNERS_ADMIN_ROLE, _msgSender());
    }

    /**
    @notice Fallback function, will revert if Ether is sent to this contract
     */
    fallback() external {}

    /**
     @notice Creates a new race
     @dev Admin creates upcoming races, specifying the track name, the track length, and the entrance fee.
     @param raceId ID of the race
     @param horsesAllowed Number of horses allowed in this race
     @param entranceFee Amount to be paid to enter this race
     @param distance Length of the race
     @param payouts List of numbers indicating the win percentage for each position
     */
    function createRace(
        bytes32 raceId,
        uint8 horsesAllowed,
        uint256 entranceFee,
        uint16 distance,
        uint256 prizePool,
        uint8 zedFee,
        uint256[] calldata payouts
    ) external onlyOwners nonReentrant whenNotPaused {
        // Pre-check and struct initialization.
        require(horsesAllowed > 0, "Racing: horses allowed cannot be less than 1");
        require(entranceFee > 0, "Racing: entrance fee lower than zero");
        require(!isIdSaved[raceId], "Racing: race ID exists");
        require(payouts.length >= 1, "Racing: payouts list cannot be less than 1");
        require(payouts.length <= horsesAllowed, "Racing: payouts list longer than allowed horses");

        uint256 payoutsAcc;
        uint256 prizeAcc;

        for (uint256 i = 0; i < payouts.length; i++) {
            payoutsAcc += payouts[i];
            prizeAcc += (entranceFee * horsesAllowed * (100 - zedFee) * payouts[i]) / 10000; // handle rounding
        }

        require(payoutsAcc == 100, "Racing: payouts percentages should add up to 100");
        require(prizePool == prizeAcc, "Racing: prize pool does not match entrance fee");

        isIdSaved[raceId] = true;

        races[raceId] = Race({
            horsesRegistered: 0,
            horsesAllowed: horsesAllowed,
            zedFee: zedFee,
            raceState: State.Registration,
            distance: distance,
            payouts: payouts,
            raceId: raceId,
            entranceFee: entranceFee,
            prizePool: prizePool
        });

        // Event trigger.
        emit RaceCreated(raceId, distance, entranceFee);
    }

    /**
     @notice Registers a horse into a race
     @param raceId ID of the race
     @param horseId ID of the horse to register
     @param gateNumber Gate number to register horse in
     */
    function registerHorse(
        bytes32 raceId,
        uint32 horseId,
        uint8 gateNumber
    ) external nonReentrant whenNotPaused {
        address horseOwner = core.ownerOf(horseId);
        if (horseOwner != _msgSender()) {
            require(lendingRegistry.isValidLendingAgreement(horseOwner), "Racing: not the horse owner");
            require(ILendingAgreement(horseOwner).borrower() == _msgSender(), "Racing: not the current horse borrower");
        }

        Race storage race = races[raceId];

        // Pre-checks.
        _generalRaceRegistrationChecks(race, raceId, horseId, gateNumber);
        require(
            horseActiveRaces[horseId] < HORSE_REGISTRATION_LIMIT,
            "Racing: horse has reached the active races limit"
        );

        isRaceGateTaken[raceId][gateNumber] = true;

        // Insert a new Horse struct with the appropriate information.
        horseActiveRaces[horseId]++;
        race.horsesRegistered++;
        raceLineup[raceId][horseId] = Horse({ nominator: horseOwner, gateNumber: gateNumber, finalPosition: 0 });
        raceGateToId[raceId][gateNumber] = horseId;

        emit HorseRegistered(raceId, horseOwner, horseId, gateNumber);

        // Transfer tokens from user wallet to racing arena contract
        weth.safeTransferFrom(_msgSender(), address(this), race.entranceFee);
    }

    /**
    @notice Takes a horse out of a race
    @dev This function is called when security measures have been broken or another exceptional cases
    @param raceId ID of the race
    @param horseId ID of the horse to remove
     */
    function deregisterHorseFromRace(bytes32 raceId, uint32 horseId) external onlyOwners {
        Race storage race = races[raceId];

        // Default validations
        require(race.raceState == State.Registration, "Racing: race is not in registration state");
        require(raceLineup[raceId][horseId].gateNumber != 0, "Racing: horse is not registered for this race");

        uint256 fee = race.entranceFee;
        uint8 horseGateNumber = raceLineup[raceId][horseId].gateNumber;
        address horseNominator = raceLineup[raceId][horseId].nominator;

        // Decrease horse active races count
        horseActiveRaces[horseId]--;

        // Decrease registered horses amount
        race.horsesRegistered--;

        // Clean horse values on lineup
        delete raceLineup[raceId][horseId];

        // Clean gate from horse id
        delete raceGateToId[raceId][horseGateNumber];

        // Mark gate number as empty again
        delete isRaceGateTaken[raceId][horseGateNumber];

        emit HorseRemovedFromRace(raceId, horseId, _msgSender());

        // Sends entrance fee back to nominator
        _refund(horseNominator, fee);
    }

    /**
     @notice Admin posts the result of the race, enabling users to claim their winnings.
     @dev Receives results for a given race, removes 1 active race from the given horses.
     @dev Transitions race state and sends funds to one of the owner addresses as well.
     @param raceId Race ID we're going to post the results to.
     @param results Final position ordered list of horse IDs that participated in the race
     */
    function postResults(bytes32 raceId, uint32[] calldata results) external onlyOwners nonReentrant {
        Race storage race = races[raceId];

        // Pre-checks
        require(race.raceState == State.Registration, "Racing: race is not in registration state");
        require(results.length == race.horsesAllowed, "Racing: number of horses sent does not match allowed horses");
        require(
            race.horsesAllowed == race.horsesRegistered,
            "Racing: number of horses registered does not match allowed horses"
        );

        // State transition to 'Final'
        race.raceState = State.Final;

        uint256 feeAcc = race.entranceFee * race.horsesAllowed;

        for (uint32 i = 0; i < race.horsesAllowed; i++) {
            uint32 horseId = results[i];
            uint8 finalHorsePosition = uint8(i + 1);

            require(raceLineup[raceId][horseId].gateNumber != 0, "Racing: horse not registered for race");

            raceLineup[raceId][horseId].finalPosition = finalHorsePosition;
            horseActiveRaces[horseId]--;

            // Just make transfers for payouts that are actually in place, otherwise the transfer will revert
            if (i < race.payouts.length) {
                address horseNominator = raceLineup[raceId][horseId].nominator;
                uint256 wonAmount = (race.entranceFee * race.horsesAllowed * (100 - race.zedFee) * race.payouts[i]) /
                    10000;
                feeAcc -= wonAmount;

                emit PrizeClaimed(raceId, horseNominator, wonAmount, horseId);

                // Transfer funds to winner
                if (lendingRegistry.isValidLendingAgreement(horseNominator)) {
                    _splitPrize(horseNominator, wonAmount, race.entranceFee);
                } else {
                    _transfer(horseNominator, wonAmount);
                }
            }
        }

        /*
        Transfer funds to one of Zed's accounts.
        Zed will take a percentage which will be on contract's balance as a difference.
        The prize pool does not include the fees, only how much will be paid to participants
        Most of the time, what participants pay as the entry (total) ends up being more than the prize pool,
        this is because of ~entrance fee * number of horses allowed~. So, even when paying out the prize pool there should be
        a leftover in contract's balance, which will be used to pay the Zed fee.
         */
        _transfer(feeReceiver, feeAcc);
    }

    function _splitPrize(
        address lendingAgreementAddress,
        uint256 wonAmount,
        uint256 entranceFee
    ) private {
        ILendingAgreement agreement = ILendingAgreement(lendingAgreementAddress);
        if (wonAmount > entranceFee) {
            (uint256 ownerShare, uint256 borrowerShare) = agreement.calculateShare(wonAmount - entranceFee);
            _transfer(agreement.borrower(), borrowerShare + entranceFee);
            _transfer(agreement.owner(), ownerShare);
        } else {
            _transfer(agreement.borrower(), wonAmount);
        }
    }

    /**
    @notice Cancels a race
    @dev This will perform some actions similar to 'postResults' and will send fees back to users
    @param raceId ID of the race to cancel
    @param reason Reason for this race to get canceled
     */
    function cancelRace(bytes32 raceId, string calldata reason) external onlyOwners {
        Race storage race = races[raceId];

        // Pre-checks
        require(race.raceState == State.Registration, "Racing: race is not in registration state");

        race.raceState = State.Fail_Safe;
        canceledRaces[raceId] = reason;

        // Combines horses allowed and GateToId so we can know the horse
        for (uint256 i = 1; i <= race.horsesAllowed; i++) {
            uint256 horseId = raceGateToId[raceId][i];

            // If ID is 0 then there was no horse registered in this gate
            if (horseId != 0) {
                Horse memory horseInRace = raceLineup[raceId][horseId];

                // Decreases number of active races for horse
                horseActiveRaces[horseId]--;

                // Sends entrance fee back to the nominator
                _refund(horseInRace.nominator, race.entranceFee);
            }
        }

        emit RaceCanceled(raceId, reason, _msgSender());
    }

    // -----------------------------------------
    // GETTERS
    // -----------------------------------------

    /**
     @notice Retrieves horse ID based on race ID and gate
     @param raceId ID of the race
     @param gateNumber Number of the gate in race
     @return uint32 representing ID of the horse or `0` if empty
     */
    function getHorseId(bytes32 raceId, uint8 gateNumber) external view returns (uint256) {
        return raceGateToId[raceId][gateNumber];
    }

    /**
     @notice Gets some data of a horse in a race
     @param raceId ID of the race
     @param gateNumber Number of the gate in race
     @return uint256 For ID of the horse in gate or `0` if empty
     @return uint8 For final position of horse in race or `0` if empty
     */
    function getHorseInfo(bytes32 raceId, uint8 gateNumber) external view returns (uint256, uint8) {
        return (raceGateToId[raceId][gateNumber], raceLineup[raceId][gateNumber].finalPosition);
    }

    /** RESTRICTED */
    /**
    @dev Grants a role to an account without the need to go through admin verification. This is useful in case we need to have more than
    one admin account for the same role. Allowing to easily switch accounts.
    @param role Role to grant
    @param account Account to grant role
    */
    function grantRoleAdmin(bytes32 role, address account) external onlyOwnersAdmins {
        _setupRole(role, account);
    }

    /**
    @notice Grants ability to an admin account to nominate a horse without paying anything.
    @dev This is useful for migrations, faulty races or even tournaments
    @dev Removed checks are
        1. Active races of the horse even though registering for this race still counts to active races
        2. wETH transfer from sender
    @param raceId ID of the race
    @param horseId ID of the horse
    @param gateNumber Gate to nominate the horse to
     */
    function adminRegisterHorse(
        bytes32 raceId,
        uint32 horseId,
        uint8 gateNumber
    ) external onlyOwners {
        Race storage race = races[raceId];

        // Pre-checks.
        _generalRaceRegistrationChecks(race, raceId, horseId, gateNumber);

        isRaceGateTaken[raceId][gateNumber] = true;

        // Even if an admin called this function, the nominator needs to be the owner of the horse
        // If we're curious about who sent the transaction, admin's address will still appear
        // under transaction's details
        address nominator = core.ownerOf(horseId);

        // Insert a new Horse struct with the appropriate information.
        horseActiveRaces[horseId]++;
        race.horsesRegistered++;
        raceLineup[raceId][horseId] = Horse({ nominator: nominator, gateNumber: gateNumber, finalPosition: 0 });
        raceGateToId[raceId][gateNumber] = horseId;

        emit HorseRegistered(raceId, nominator, horseId, gateNumber);
    }

    /**
    @notice Changes fee receiver address
    @param feeReceiver_ address of the new receiver account
     */
    function changeFeeReceiver(address feeReceiver_) external onlyOwners {
        require(address(feeReceiver_) != address(0), "Racing: invalid account");

        feeReceiver = feeReceiver_;
    }

    /**
    @notice Changes the address of the Core contract
    @param core_ address of the new Core contract
     */
    function changeCoreAddress(ICore core_) external onlyOwners {
        require(address(core_) != address(0), "Racing: invalid core address");
        core = core_;
    }

    /**
    @notice Changes the address of the LendingRegistry contract
    @param lendingRegistry_ address of the new LendingRegistry contract
     */
    function changeLendingRegistryAddress(ILendingRegistry lendingRegistry_) external onlyOwners {
        require(address(lendingRegistry_) != address(0), "Racing: invalid LendingRegistry address");
        lendingRegistry = lendingRegistry_;
    }

    /**
    @notice Pauses the contract
     */
    function pause() external onlyOwners {
        _pause();
    }

    /**
    @notice Unpauses the contract
     */
    function unpause() external onlyOwners {
        _unpause();
    }

    /**  INTERNALS */
    function _msgSender() internal view override returns (address sender) {
        sender = msgSender();
    }

    /**  PRIVATE  */
    function _generalRaceRegistrationChecks(
        Race memory race,
        bytes32 raceId,
        uint32 horseId,
        uint8 gateNumber
    ) private view {
        require(race.raceState == State.Registration, "Racing: race not accepting registrations");
        require(race.horsesRegistered < race.horsesAllowed, "Racing: max number of horses for race");
        require(gateNumber >= 1, "Racing: gate number lower than 1");
        require(gateNumber <= race.horsesAllowed, "Racing: gate number greater than horses allowed");
        require(!isRaceGateTaken[raceId][gateNumber], "Racing: gate number already taken");
        require(raceLineup[raceId][horseId].gateNumber == 0, "Racing: horse already registered for this race");
    }

    function _transfer(address to, uint256 amount) private {
        if (amount > 0) weth.safeTransfer(to, amount);
    }

    function _refund(address horseNominator, uint256 amount) private {
        if (lendingRegistry.isValidLendingAgreement(horseNominator)) {
            ILendingAgreement lendingAgreement = ILendingAgreement(horseNominator);
            _transfer(lendingAgreement.borrower(), amount);
        } else {
            _transfer(horseNominator, amount);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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

// SPDX-FileCopyrightText: © 2022 Virtually Human Studio

// SPDX-License-Identifier: No-license

pragma solidity 0.8.11;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../../base/access/AccessControlEnumerableLegacy.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ICore } from "../../interfaces/ICore.sol";
import "../../base/EIP712/EIP712MetaTransaction.sol";
import { ILendingRegistry } from "../../interfaces/ILendingRegistry.sol";

contract RacingStorage is
    Initializable,
    ReentrancyGuard,
    AccessControlEnumerableLegacy,
    EIP712MetaTransaction,
    Pausable
{
    // --
    // Permanent Storage Variables
    // --
    mapping(uint256 => uint256) public horseActiveRaces; // Number of races the horse is registered for.
    mapping(bytes32 => Race) public races; // The race mapping structure.
    mapping(bytes32 => bool) public isIdSaved; // Returns whether or not the race ID is present on storage already.
    mapping(bytes32 => string) public canceledRaces; // Returns a canceled race and its reason to be cancelled.
    mapping(bytes32 => mapping(uint256 => Horse)) public raceLineup; // Mapping of race_id => horse_id => struct
    mapping(bytes32 => mapping(uint256 => uint256)) public raceGateToId; // Mapping of race_id => gate # => horse ID
    mapping(bytes32 => mapping(uint256 => bool)) public isRaceGateTaken; // Whether or not a gate in a race has been taken

    address public feeReceiver; // ZED wallet that's receiving fees

    IERC20 public weth; // WETH contract

    ICore public core; // Core contract

    enum State {
        Null,
        Registration,
        Final,
        Fail_Safe
    }

    struct Race {
        uint8 horsesRegistered; // Current number of horses registered.
        uint8 horsesAllowed; // Total number of horses allowed for a race.
        uint8 zedFee; // Zed Fee for this race
        State raceState; // Current state of the race.
        uint16 distance; // Length of the track (m).
        uint256[] payouts; // List holding percentages of payouts for each position
        bytes32 raceId; // Key provided for Race ID.
        uint256 entranceFee; // Entrance fee for a particular race (10^18).
        uint256 prizePool; // Total prize pool (10^18).
    }

    struct Horse {
        address nominator; // The address who nominated this horse
        uint8 gateNumber; // Gate this horse is currently at.
        uint8 finalPosition; // Final position of the horse (1 to Horses allowed in race).
    }

    bytes32 public constant RACING_OWNERS_ROLE = bytes32("racing_owners");
    bytes32 public constant RACING_OWNERS_ADMIN_ROLE = bytes32("racing_owners_admin");
    uint256 public constant HORSE_REGISTRATION_LIMIT = 3;

    /// @notice The lending registry address
    ILendingRegistry public lendingRegistry;
}

// SPDX-FileCopyrightText: © 2022 Virtually Human Studio

// SPDX-License-Identifier: No-license

pragma solidity 0.8.11;

import { IAccessControlEnumerable } from "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";
import { IERC721Enumerable, IERC721 } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import { INameplate } from "./INameplate.sol";
import { IFreezable } from "./IFreezable.sol";

struct Horse {
    address initialOwner;
    uint256 genotype;
    uint256 baseValue;
    uint256 timestamp;
    bytes32 bloodline;
    bytes32 sex;
    bytes32 hType;
    bytes32 color;
    uint256 lastBundlingAt;
}

struct AccessoryData {
    IERC721 accessory;
    uint256 id;
}

interface ICore is IAccessControlEnumerable, IERC721Enumerable, IFreezable {
    function nameplate() external view returns (INameplate);

    function horses(uint256 tokenId) external view returns (Horse memory);

    function nameplateOf(uint256 tokenId) external view returns (uint256);

    function tokenExists(uint256 tokenId) external view returns (bool);

    function getBaseValue(uint256 tokenId) external view returns (uint256);

    function setBaseValue(uint256 tokenId, uint256 baseValue) external;

    function mintCustomHorse(
        address owner,
        uint256 genotype,
        bytes32 gender,
        bytes32 name,
        bytes32 color
    ) external;

    function mintOffspring(
        address owner,
        uint256 male,
        uint256 female,
        bytes32 color
    ) external;

    function mintUpgradedHorse(
        address currentOwner,
        uint256 horseId,
        bytes32 gender,
        uint256 baseValue,
        uint256 timestamp,
        uint256 genotype,
        bytes32 bloodline,
        bytes32 horseType,
        bytes32 name,
        bytes32 color,
        address initialOwner
    ) external;

    function nextTokenId() external view returns (uint256);

    function isNameTaken(bytes32 name) external view returns (bool);

    function getHorseName(uint256 _tokenId) external view returns (bytes32);

    function accessoriesOf(uint256 _tokenId, uint256 index) external view returns (AccessoryData memory);

    function accessoryCountOf(uint256 _tokenId) external view returns (uint256);

    function allAccessoriesOf(uint256 _tokenId) external view returns (AccessoryData[] memory);

    function burn(uint256 tokenId) external;
}

// SPDX-FileCopyrightText: © 2022 Virtually Human Studio

// SPDX-License-Identifier: No-license
pragma solidity 0.8.11;

/**
 * @title ZED Lending Registry
 * @author The VHS team
 */
interface ILendingRegistry {
    /**
    @dev Emitted adding a new LendingMarketplace contract.
    @param lendingMarketplaceToAdd added LendingMarketplace address.
    */
    event AddedLendingMarketplace(address lendingMarketplaceToAdd);

    /**
    @notice Checks if an address is a LendingAgreement and what is its corresponding LendingMarketplace
    @param agreementAddress - lendingAgreement contract address
    @return isAgreementValid Whether or not this is a valid agreement
    */
    function isValidLendingAgreement(address agreementAddress) external view returns (bool isAgreementValid);
}

// SPDX-FileCopyrightText: © 2022 Virtually Human Studio

// SPDX-License-Identifier: No-license
pragma solidity 0.8.11;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILendingAgreement {
    // @return Address of the Lending marketplace that holds the token
    function lendingMarketplace() external view returns (address);

    // @return Address of the original token owner
    function owner() external view returns (address);

    // @return Address of the borrower
    function borrower() external view returns (address);

    // @return The ID of the ERC721 token
    function tokenId() external view returns (uint256);

    // @return The owner share of a token balance will be taken
    function ownerSharePercentage() external view returns (uint8);

    // @return Block timestamp of the contract deployment
    function start() external view returns (uint64);

    // @return Expirity period of the agreement
    function period() external view returns (uint64);

    // @return Whether an agreement has been finalized
    function isFinalized() external view returns (bool);

    /**
    @dev Splits amount in owner and borrower share. If the share is below 100, owner takes it all to prevent arithmetic underflow
    @param amount Amount that will be shared by owner and borrower
    @return ownerShare Owner share of the amount
    @return borrowerShare Borrower share of the amount
    */
    function calculateShare(uint256 amount) external view returns (uint256 ownerShare, uint256 borrowerShare);

    /**
    @dev Allows the admin role to set the agreement isFinalized to true
    @notice Marks the agreement as finalized 
     */
    function markAsFinalized() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
@dev This contract was inherited from OZ-V3. We need this version around for
@dev backwards compatibility with our already deployed proxies. Newer contracts can use
@dev the implementation directly from OZ.
 */
abstract contract AccessControlEnumerableLegacy is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
     * bearer except when using {_setupRole}.
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
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
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
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

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
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

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
    function renounceRole(bytes32 role, address account) public virtual {
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
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./EIP712Base.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
@title Interface to enable MetaTransactions
 */
contract EIP712MetaTransaction is EIP712Base {
    using Address for address;

    bytes32 private constant META_TRANSACTION_TYPEHASH =
        // solium-disable-next-line
        keccak256(bytes("MetaTransaction(uint256 nonce,address from,bytes functionSignature)"));

    event MetaTransactionExecuted(address _userAddress, address payable _relayerAddress, bytes _functionSignature);

    mapping(address => uint256) public nonces;

    /**
     @dev Meta transaction structure.
     @dev No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     @dev He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    /**
    @notice Executes a MetaTransaction
    @param _userAddress The address of the user
    @param _functionSignature The signature of the function
    @param _sigR ECDSA signature
    @param _sigS ECDS signature
    @param _sigV Recovery ID signature
     */
    function executeMetaTransaction(
        address _userAddress,
        bytes memory _functionSignature,
        bytes32 _sigR,
        bytes32 _sigS,
        uint8 _sigV
    ) external payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction(nonces[_userAddress], _userAddress, _functionSignature);

        require(
            verify(_userAddress, metaTx, _sigR, _sigS, _sigV),
            "EIP712MetaTransaction: Signer and signature do not match"
        );

        // increase nonce for user (to avoid re-use)
        nonces[_userAddress]++;

        emit MetaTransactionExecuted(_userAddress, payable(msg.sender), _functionSignature);

        // Append userAddress and relayer address at the end to extract it from calling context
        bytes memory returnData = address(this).functionCall(abi.encodePacked(_functionSignature, _userAddress));

        return returnData;
    }

    /**
    @notice Hashes a meta transaction
    @param _metaTx The MetaTransaction struct
    @return bytes Representing the hashed meta transaction
     */
    function hashMetaTransaction(MetaTransaction memory _metaTx) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(META_TRANSACTION_TYPEHASH, _metaTx.nonce, _metaTx.from, keccak256(_metaTx.functionSignature))
            );
    }

    /**
    @notice Returns the message sender of a transaction, not the relayer
    @return sender Representing the message sender
     */
    function msgSender() internal view returns (address payable sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;

            // solium-disable-next-line
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender = payable(msg.sender);
        }

        return sender;
    }

    /**
    @notice Gets the nonce of a particular address
    @param _user Address of the user
    @return uint256 Representing the nonce of a particular address
     */
    function getNonce(address _user) public view returns (uint256) {
        return nonces[_user];
    }

    /**
    @notice Verifies the meta transaction being executed
    @param _signer Address of transaction's signer
    @param _metaTx The MetaTransaction struct
    @param _sigR ECDSA signature
    @param _sigS ECDS signature
    @param _sigV Recovery ID signature
    @return bool Representing whether or not the transaction is valid
     */
    function verify(
        address _signer,
        MetaTransaction memory _metaTx,
        bytes32 _sigR,
        bytes32 _sigS,
        uint8 _sigV
    ) internal view returns (bool) {
        require(_signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return _signer == ecrecover(toTypedMessageHash(hashMetaTransaction(_metaTx)), _sigV, _sigR, _sigS);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/IAccessControlEnumerable.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-FileCopyrightText: © 2022 Virtually Human Studio

// SPDX-License-Identifier: No-license

pragma solidity 0.8.11;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface INameplate is IERC721 {
    function core() external view returns (address);

    function idOf(bytes32 name) external view returns (uint256);

    function nameOf(uint256 tokenId) external view returns (bytes32);

    function mint(address to, bytes32 name) external returns (uint256);

    function setCore(address core) external;
}

// SPDX-FileCopyrightText: © 2022 Virtually Human Studio

// SPDX-License-Identifier: No-license

pragma solidity 0.8.11;

interface IFreezable {
    function freezeToken(uint256 tokenId) external;

    function freezeAccount(address account) external;

    function unfreezeToken(uint256 tokenId) external;

    function unfreezeAccount(address account) external;

    function notFrozenToken(uint256 tokenId) external view;

    function notFrozenAccount(address account) external view;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/structs/EnumerableSet.sol)

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

pragma solidity 0.8.11;

contract EIP712Base {
    bytes constant EIP721_DOMAIN_BYTES =
        // solium-disable-next-line
        bytes("EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)");

    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    bytes32 internal domainSeparator;
    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(EIP721_DOMAIN_BYTES);

    /**
    @notice Sets domain separator
    @param _name Name of the domain
    @param _version Version of the domain
    @param _chainId ID of the chain
     */
    function setDomainSeparator(
        string memory _name,
        string memory _version,
        uint256 _chainId
    ) public {
        require(domainSeparator == bytes32(0), "EIP721Base: domain separator is already set");

        domainSeparator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(_name)),
                keccak256(bytes(_version)),
                address(this),
                bytes32(_chainId)
            )
        );
    }

    /**
    @notice Gets domain separator
    @return bytes32 R
    epresenting the domain separator
     */
    function getDomainSeparator() public view returns (bytes32) {
        return domainSeparator;
    }

    /**
     @dev Accept message hash and returns hash message in EIP712 compatible form
     @dev So that it can be used to recover signer from signature signed using EIP712 formatted data
     @dev https://eips.ethereum.org/EIPS/eip-712
     @dev "\\x19" makes the encoding deterministic
     @dev "\\x01" is the version byte to make it compatible to EIP-191
     @param _messageHash Hash of the message
     @return bytes32 Representing the typed hash of `_messageHash`
     */
    function toTypedMessageHash(bytes32 _messageHash) internal view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeparator(), _messageHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/IAccessControl.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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