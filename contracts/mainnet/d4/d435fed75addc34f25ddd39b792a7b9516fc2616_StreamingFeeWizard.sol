// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: Apache License 2.0
pragma solidity ^0.8.13.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IArchChamber} from "./interfaces/IArchChamber.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";

contract StreamingFeeWizard is ReentrancyGuard {
    /*//////////////////////////////////////////////////////////////
                              STRUCT
    //////////////////////////////////////////////////////////////*/
    struct FeeState {
        address feeRecipient;
        uint256 maxStreamingFeePercentage;
        uint256 streamingFeePercentage;
        uint256 lastCollectTimestamp;
    }

    /*//////////////////////////////////////////////////////////////
                              EVENTS
    //////////////////////////////////////////////////////////////*/
    event FeeCollected(address indexed _archChamber, uint256 _streamingFeePercentage);
    event StreamingFeeUpdated(address indexed _archChamber, uint256 _newStreamingFee);
    event MaxStreamingFeeUpdated(address indexed _archChamber, uint256 _newMaxStreamingFee);
    event FeeRecipientUpdated(address indexed _archChamber, address _newFeeRecipient);

    /*//////////////////////////////////////////////////////////////
                              STORAGE
    //////////////////////////////////////////////////////////////*/
    uint256 private constant ONE_YEAR_IN_SECONDS = 365.25 days;
    uint256 private constant SCALE_UNIT = 1 ether;
    mapping(IArchChamber => FeeState) public feeStates;

    /*//////////////////////////////////////////////////////////////
                              FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * Sets the initial _feeState to the chamber. The chamber needs to exist beforehand.
     * Will revert if msg.sender is not a a manager from the _archChamber. The feeState
     * is structured as:
     *
     * {
     *   feeRecipient:              address; [mandatory]
     *   maxStreamingFeePercentage: uint256; [mandatory] < 100%
     *   streamingFeePercentage:    address; [mandatory] <= maxStreamingFeePercentage
     *   lastCollectTimestamp:      address; [optional]  any value
     * }
     *
     * Consider [1 % = 10e18] for the fees
     *
     * @param _archChamber  ArchChamber to enable
     * @param _feeState     First feeState of the ArchChamber
     */
    function enableArchChamber(IArchChamber _archChamber, FeeState memory _feeState)
        external
        nonReentrant
    {
        require(
            IArchChamber(_archChamber).isChamberManager(msg.sender),
            "msg.sender is not chamber's manager"
        );
        require(_feeState.feeRecipient != address(0), "Recipient cannot be null address");
        require(_feeState.maxStreamingFeePercentage <= 100 * SCALE_UNIT, "Max fee must be <= 100%");
        require(
            _feeState.streamingFeePercentage <= _feeState.maxStreamingFeePercentage,
            "Fee must be <= Max fee"
        );
        require(feeStates[_archChamber].lastCollectTimestamp < 1, "ArchChamber already exists");

        _feeState.lastCollectTimestamp = block.timestamp;
        feeStates[_archChamber] = _feeState;
    }

    /**
     * Calculates total inflation percentage. Mints new tokens in the ArchChamber for the
     * streaming fee recipient. Then calls the chamber to update its quantities.
     *
     * @param _archChamber ArchChamber to acquire streaming fees from
     */
    function collectStreamingFee(IArchChamber _archChamber) public {
        require(feeStates[_archChamber].lastCollectTimestamp > 0, "ArchChamber does not exist");
        uint256 previousCollectTimestamp = feeStates[_archChamber].lastCollectTimestamp;
        uint256 currentStreamingFeePercentage = feeStates[_archChamber].streamingFeePercentage;

        feeStates[_archChamber].lastCollectTimestamp = block.timestamp;

        _collectStreamingFee(_archChamber, previousCollectTimestamp, currentStreamingFeePercentage);

        emit FeeCollected(address(_archChamber), currentStreamingFeePercentage);
    }

    /**
     * Will collect pending fees, and then update the streaming fee percentage for the ArchChamber
     * specified. Cannot be larger than the maximum fee. Will revert if msg.sender is not a
     * manager from the _archChamber. To disable a chamber, set the streaming fee to zero.
     *
     * @param _archChamber          ArchChamber to update streaming fee percentage
     * @param _newFeePercentage     New streaming fee in percentage [1 % = 10e18]
     */
    function updateStreamingFee(IArchChamber _archChamber, uint256 _newFeePercentage) external {
        require(feeStates[_archChamber].lastCollectTimestamp > 0, "ArchChamber does not exist");
        require(
            IArchChamber(_archChamber).isChamberManager(msg.sender),
            "msg.sender is not chamber's manager"
        );
        require(
            _newFeePercentage <= feeStates[_archChamber].maxStreamingFeePercentage,
            "New fee is above maximum"
        );
        uint256 previousLastCollectTimestamp = feeStates[_archChamber].lastCollectTimestamp;
        uint256 previousStreamingFeePercentage = feeStates[_archChamber].streamingFeePercentage;

        feeStates[_archChamber].lastCollectTimestamp = block.timestamp;
        feeStates[_archChamber].streamingFeePercentage = _newFeePercentage;

        _collectStreamingFee(
            _archChamber, previousLastCollectTimestamp, previousStreamingFeePercentage
        );

        emit FeeCollected(address(_archChamber), previousStreamingFeePercentage);
        emit StreamingFeeUpdated(address(_archChamber), _newFeePercentage);
    }

    /**
     * Will update the maximum streaming fee of a chamber. The _newMaxFeePercentage
     * can only be lower than the current maximum streaming fee, and cannot be greater
     * than the current streaming fee. Will revert if msg.sender is not a manager from
     * the _archChamber.
     *
     * @param _archChamber          ArchChamber to update max. streaming fee percentage
     * @param _newMaxFeePercentage  New max. streaming fee in percentage [1 % = 10e18]
     */
    function updateMaxStreamingFee(IArchChamber _archChamber, uint256 _newMaxFeePercentage)
        external
    {
        require(feeStates[_archChamber].lastCollectTimestamp > 0, "ArchChamber does not exist");
        require(
            IArchChamber(_archChamber).isChamberManager(msg.sender),
            "msg.sender is not chamber's manager"
        );
        require(
            _newMaxFeePercentage <= feeStates[_archChamber].maxStreamingFeePercentage,
            "New max fee is above maximum"
        );
        require(
            _newMaxFeePercentage >= feeStates[_archChamber].streamingFeePercentage,
            "New max fee is below current fee"
        );

        feeStates[_archChamber].maxStreamingFeePercentage = _newMaxFeePercentage;

        emit MaxStreamingFeeUpdated(address(_archChamber), _newMaxFeePercentage);
    }

    /**
     * Update the streaming fee recipient for the ArchChamber specified. Will revert if msg.sender
     * is not a manager from the _archChamber.
     *
     * @param _archChamber          ArchChamber to update streaming fee recipient
     * @param _newFeeRecipient      New fee recipient address
     */
    function updateFeeRecipient(IArchChamber _archChamber, address _newFeeRecipient)
        external
        nonReentrant
    {
        require(feeStates[_archChamber].lastCollectTimestamp > 0, "ArchChamber does not exist");
        require(
            IArchChamber(_archChamber).isChamberManager(msg.sender),
            "msg.sender is not chamber's manager"
        );
        require(_newFeeRecipient != address(0), "Recipient cannot be null address");
        feeStates[_archChamber].feeRecipient = _newFeeRecipient;

        emit FeeRecipientUpdated(address(_archChamber), _newFeeRecipient);
    }

    /**
     * Returns the streaming fee recipient of the AcrhChamber specified.
     *
     * @param _archChamber ArchChamber to consult
     */
    function getStreamingFeeRecipient(IArchChamber _archChamber) external view returns (address) {
        require(feeStates[_archChamber].lastCollectTimestamp > 0, "ArchChamber does not exist");
        return feeStates[_archChamber].feeRecipient;
    }

    /**
     * Returns the maximum streaming fee percetage of the AcrhChamber specified.
     * Consider [1 % = 10e18]
     *
     * @param _archChamber ArchChamber to consult
     */
    function getMaxStreamingFeePercentage(IArchChamber _archChamber)
        external
        view
        returns (uint256)
    {
        require(feeStates[_archChamber].lastCollectTimestamp > 0, "ArchChamber does not exist");
        return feeStates[_archChamber].maxStreamingFeePercentage;
    }

    /**
     * Returns the streaming fee percetage of the AcrhChamber specified.
     * Consider [1 % = 10e18]
     *
     * @param _archChamber ArchChamber to consult
     */
    function getStreamingFeePercentage(IArchChamber _archChamber) external view returns (uint256) {
        require(feeStates[_archChamber].lastCollectTimestamp > 0, "ArchChamber does not exist");
        return feeStates[_archChamber].streamingFeePercentage;
    }

    /**
     * Returns the last streaming fee timestamp of the AcrhChamber specified.
     *
     * @param _archChamber ArchChamber to consult
     */
    function getLastCollectTimestamp(IArchChamber _archChamber) external view returns (uint256) {
        require(feeStates[_archChamber].lastCollectTimestamp > 0, "ArchChamber does not exist");
        return feeStates[_archChamber].lastCollectTimestamp;
    }

    /*//////////////////////////////////////////////////////////////
                              INTERNAL
    //////////////////////////////////////////////////////////////*/

    /**
     * Given the current supply of an ArchChamber, the last timestamp and the current streaming fee,
     * this function returns the inflation quantity to mint. The formula to calculate inflation quantity
     * is this:
     *
     * currentSupply * (streamingFee [10e18] / 100 [10e18]) * ((now [s] - last [s]) / one_year [s])
     *
     * @param _currentSupply            ArchChamber current supply
     * @param _lastCollectTimestamp     Last timestamp of collect
     * @param _streamingFeePercentage   Current streaming fee
     */
    function _calculateInflationQuantity(
        uint256 _currentSupply,
        uint256 _lastCollectTimestamp,
        uint256 _streamingFeePercentage
    ) internal view returns (uint256 inflationQuantity) {
        uint256 blockWindow = block.timestamp - _lastCollectTimestamp;
        uint256 inflation = _streamingFeePercentage * blockWindow;
        uint256 a = _currentSupply * inflation;
        uint256 b = ONE_YEAR_IN_SECONDS * (100 * SCALE_UNIT);
        return a / b;
    }

    /**
     * Performs the collect fee on the ArchChamber, considering the ArchChamber current supply,
     * the last collect timestamp and the streaming fee percentage provided. It calls the ArchChamber
     * to mint the inflation amount, and then calls it again so the Chamber can update its quantities.
     *
     * @param _archChamber              ArchChamber to collect fees from
     * @param _lastCollectTimestamp     Last collect timestamp to consider
     * @param _streamingFeePercentage   Streaming fee percentage to consider
     */
    function _collectStreamingFee(
        IArchChamber _archChamber,
        uint256 _lastCollectTimestamp,
        uint256 _streamingFeePercentage
    ) internal nonReentrant {
        if (_streamingFeePercentage > 0 && _lastCollectTimestamp < block.timestamp) {
            uint256 currentSupply = IERC20(_archChamber).totalSupply();

            // Calculate inflation quantity
            uint256 inflationQuantity = _calculateInflationQuantity(
                currentSupply, _lastCollectTimestamp, _streamingFeePercentage
            );

            // Mint the inlation quantity
            IArchChamber(_archChamber).mint(feeStates[_archChamber].feeRecipient, inflationQuantity);

            // Calculate chamber new quantities
            IArchChamber(_archChamber).updateQuantities();
        }
    }
}

// SPDX-License-Identifier: Apache License 2.0
pragma solidity ^0.8.13.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IArchChamber is IERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event ManagerAdded(address indexed _manager);

    event ManagerRemoved(address indexed _manager);

    event ConstituentAdded(address indexed _constituent);

    event ConstituentRemoved(address indexed _constituent);

    event WizardAdded(address indexed _wizard);

    event WizardRemoved(address indexed _wizard);

    /*//////////////////////////////////////////////////////////////
                               CHAMBER MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    function addConstituent(address _constituent) external;

    function removeConstituent(address _constituent) external;

    function isChamberManager(address _manager) external view returns (bool);

    function isWizard(address _wizard) external view returns (bool);

    function isConstituent(address _constituent) external view returns (bool);

    function addManager(address _manager) external;

    function removeManager(address _manager) external;

    function addWizard(address _wizard) external;

    function removeWizard(address _wizard) external;

    function getConstituentsAddresses() external view returns (address[] memory);

    function getQuantities() external view returns (uint256[] memory);

    function getConstituentQuantity(address _constituent) external view returns (uint256);

    function getWizards() external view returns (address[] memory);

    function mint(address _recipient, uint256 _quantity) external;

    function burn(address _from, uint256 _quantity) external;

    function withdrawTo(address _constituent, address _recipient, uint256 _quantity) external;

    function updateQuantities() external;

    function addAllowedContract(address target) external;

    function removeAllowedContract(address target) external;

    function executeTrade(
        address _sellToken,
        uint256 _sellQuantity,
        bytes memory _tradeQuoteData,
        address payable dexAggregator
    ) external;
}