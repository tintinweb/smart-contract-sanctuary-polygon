// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
pragma solidity ^0.8.4;

import "./errMsgs/PrpGrantorErrMsgs.sol";
import "./common/ImmutableOwnable.sol";
import "./interfaces/IPrpGrantor.sol";

/**
 * @title PrpGrantor
 * @notice It registers issuing and redemption of PRP-nominated "grants"
 * @dev The owner may add (enable) new "grant types" or remove (disable) existing types. For every
 * type, the owner specifies (authorizes) the account of the "curator" and the amount of the grant
 * (in Panther Reward Points, aka "PRPs").
 * A curator calls `issueGrant` on this contract to issue a "grant" of a certain type to a grantee.
 * The curator must be authorized by the owner for this grant type.
 * Independently from curators, the owner may call `issueOwnerGrant` to issue a grant to a grantee.
 * In this case the amount is specified as the call param, rather than via the grant type.
 * Every `issueGrant` or `issueOwnerGrant` call increases the amount (in PRPs) of "unused grants"
 * for the grantee.
 * The authorized "processor" (one for all grant types) may call `redeemGrant` to account for usage
 * (i.e.  redemption) of grants. Every `redeemGrant` call decreases the amount of unused grants for
 * the grantee.
 * Assumed:
 * - the "processor" is the `PantherPool` contract
 * - a grant is redeemed when the PantherPool creates a PRP-nominated UTXO for a grantee.
 */
contract PrpGrantor is ImmutableOwnable, IPrpGrantor {
    // The contract is supposed to run behind a proxy DELEGATECALLing it.
    // On upgrades, adjust `__gap` to match changes of the storage layout.
    uint256[50] private __gap;

    // solhint-disable var-name-mixedcase

    // Max amount in PRPs
    uint256 private constant MAX_PRP_GRANT = 2**32;

    // To distinguish "undefined" from "zero"
    uint256 private constant ZERO_AMOUNT = 1;
    uint256 private constant UNDEF_AMOUNT = 0;

    // bytes4(keccak('issueOwnerGrant(address,uint256)'))
    bytes4 private constant OWNER_GRANT_TYPE = 0x479ed83f;

    // Account authorized to call `redeemGrant`
    address private immutable GRANT_PROCESSOR;

    // solhint-enable var-name-mixedcase

    /// @dev Mapping from "curator" to "grant type" to "grant amount in PRPs"
    /// To distinguish "zero" from "undefined", values are biased by `ZERO_AMOUNT`
    mapping(address => mapping(bytes4 => uint256)) private _prpGrantsAmounts;

    /// @dev mapping from "grantee" to the PRP amount that may be "used"
    mapping(address => uint256) private _unusedPrpGrants;

    // Total amount (in PRPs) of grants issued so far
    uint256 public override totalGrantsIssued;

    // Total amount (in PRPs) of grants redeemed so far
    // (excluding burnt grants amounts)
    uint256 public override totalGrantsRedeemed;

    constructor(address _owner, address _grantProcessor)
        ImmutableOwnable(_owner)
    {
        // As it runs behind the DELEGATECALL'ing proxy, initialization of
        // immutable "vars" only is allowed in the constructor
        require(_grantProcessor != address(0), ERR_ZERO_PROCESSOR_ADDR);
        GRANT_PROCESSOR = _grantProcessor;
    }

    /// @inheritdoc IPrpGrantor
    function grantProcessor() external view override returns (address) {
        return GRANT_PROCESSOR;
    }

    /// @inheritdoc IPrpGrantor
    function getUnusedGrantAmount(address grantee)
        external
        view
        override
        returns (uint256 prpAmount)
    {
        return _unusedPrpGrants[grantee];
    }

    /// @inheritdoc IPrpGrantor
    function getGrantAmount(address curator, bytes4 grantType)
        external
        view
        override
        returns (uint256 prpAmount)
    {
        prpAmount = _prpGrantsAmounts[curator][grantType];
        _revertOnUndefPrpAmount(prpAmount);
        // In this and other `unchecked` blocks, over/underflow impossible since:
        // - prpAmount is limited when granted and can never exceed MAX_PRP_GRANT
        // - prpAmount's summation (accumulation) can't practically exceed 2**256
        // - prpAmount is checked to be equal or more than the value subtracted
        // - prpAmount checked to be less or equal the value it's subtracted from
        unchecked {
            prpAmount -= ZERO_AMOUNT;
        }
    }

    /// @inheritdoc IPrpGrantor
    function issueGrant(address grantee, bytes4 grantType)
        external
        override
        nonZeroGrantType(grantType)
        returns (uint256 prpAmount)
    {
        require(grantee != address(0), ERR_ZERO_GRANTEE_ADDR);
        prpAmount = _prpGrantsAmounts[msg.sender][grantType];
        _revertOnUndefPrpAmount(prpAmount);
        unchecked {
            prpAmount -= ZERO_AMOUNT;
        }
        _issueGrant(grantee, prpAmount, grantType);
    }

    /// @inheritdoc IPrpGrantor
    function issueOwnerGrant(address grantee, uint256 prpAmount)
        external
        override
        onlyOwner
    {
        require(grantee != address(0), ERR_ZERO_GRANTEE_ADDR);
        _revertOnTooBigPrpAmount(prpAmount);
        _issueGrant(grantee, prpAmount, OWNER_GRANT_TYPE);
    }

    /// @inheritdoc IPrpGrantor
    function burnGrant(uint256 prpAmount) external override {
        uint256 oldBalance = _unusedPrpGrants[msg.sender];
        require(oldBalance >= prpAmount, ERR_LOW_GRANT_BALANCE);
        unchecked {
            _unusedPrpGrants[msg.sender] = oldBalance - prpAmount;
            totalGrantsIssued -= prpAmount;
        }
        emit PrpGrantBurnt(msg.sender, prpAmount);
    }

    /// @inheritdoc IPrpGrantor
    function redeemGrant(address grantee, uint256 prpAmount) external override {
        require(msg.sender == GRANT_PROCESSOR, ERR_UNAUTHORIZED_CALL);
        uint256 oldBalance = _unusedPrpGrants[grantee];
        require(oldBalance >= prpAmount, ERR_LOW_GRANT_BALANCE);
        unchecked {
            _unusedPrpGrants[grantee] = oldBalance - prpAmount;
            totalGrantsRedeemed += prpAmount;
        }
        emit PrpGrantRedeemed(grantee, prpAmount);
    }

    /// @dev Add a new "grant type", with the specified amount (in PRPs) of the grant, and
    /// allow the specified "curator" to issue grants of this type (by calling `issueGrant`).
    /// Only the owner may call.
    function enableGrantType(
        address curator,
        bytes4 grantType,
        uint256 prpAmount
    ) external onlyOwner nonZeroGrantType(grantType) {
        require(curator != address(0), ERR_ZERO_CURATOR_ADDR);
        _revertOnTooBigPrpAmount(prpAmount);
        require(
            _prpGrantsAmounts[curator][grantType] == UNDEF_AMOUNT,
            ERR_GRANT_TYPE_EXISTS
        );
        _prpGrantsAmounts[curator][grantType] = ZERO_AMOUNT + prpAmount;
        emit PrpGrantEnabled(curator, grantType, prpAmount);
    }

    /// @dev Disable previously enabled "grant type".
    /// Only the owner may call.
    function disableGrantType(address curator, bytes4 grantType)
        external
        onlyOwner
        nonZeroGrantType(grantType)
    {
        _revertOnUndefPrpAmount(_prpGrantsAmounts[curator][grantType]);
        _prpGrantsAmounts[curator][grantType] = UNDEF_AMOUNT;
        emit PrpGrantDisabled(curator, grantType);
    }

    /// Modifiers and private functions follow

    modifier nonZeroGrantType(bytes4 grantType) {
        require(grantType != bytes4(0), ERR_UKNOWN_GRANT_TYPE);
        _;
    }

    function _revertOnTooBigPrpAmount(uint256 prpAmount) private pure {
        require(prpAmount <= MAX_PRP_GRANT, ERR_TOO_LARGE_GRANT_AMOUNT);
    }

    function _revertOnUndefPrpAmount(uint256 prpAmount) private pure {
        require(prpAmount != UNDEF_AMOUNT, ERR_UNDEF_GRANT);
    }

    function _issueGrant(
        address grantee,
        uint256 prpAmount,
        bytes4 grantType
    ) private {
        unchecked {
            if (prpAmount != 0) {
                uint256 newBalance = _unusedPrpGrants[grantee] + prpAmount;
                _revertOnTooBigPrpAmount(newBalance);
                _unusedPrpGrants[grantee] = newBalance;
                totalGrantsIssued += prpAmount;
            }
        }
        emit PrpGrantIssued(grantType, grantee, prpAmount);
    }
}

// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
// solhint-disable-next-line compiler-fixed, compiler-gt-0_8
pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
pragma solidity ^0.8.4;

string constant ERR_ZERO_PROCESSOR_ADDR = "GR:E0";
string constant ERR_ZERO_CURATOR_ADDR = "GR:E1";
string constant ERR_ZERO_GRANTEE_ADDR = "GR:E2";
string constant ERR_GRANT_TYPE_EXISTS = "GR:E3";
string constant ERR_UNEXPECTED_GRANT_RECEIPIENT = "GR:E4";
string constant ERR_LOW_GRANT_BALANCE = "GR:E5";
string constant ERR_UKNOWN_GRANT_TYPE = "GR:E6";
string constant ERR_TOO_LARGE_GRANT_AMOUNT = "GR:E6";
string constant ERR_UNDEF_GRANT = "GR:E7";
string constant ERR_UNAUTHORIZED_CALL = "GR:Unauthorized";

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
pragma solidity ^0.8.4;

/**
 * @title IPrpGrantor
 * @notice Interface for the `PrpGrantor` contract
 * @dev Excluding `onlyOwner` functions
 */
interface IPrpGrantor {
    /// @notice Return the address of the "grant processor"
    /// @dev This account only is authorized to call `redeemGrant`
    function grantProcessor() external view returns (address);

    /// @notice Returns the total amount (in PRPs) of grants issued so far
    /// (excluding burnt grants)
    function totalGrantsIssued() external returns (uint256);

    /// @notice Returns the total amount (in PRPs) of grants redeemed so far
    function totalGrantsRedeemed() external returns (uint256);

    /// @notice Returns the total amount (in PRPs) of unused grants for the given grantee
    function getUnusedGrantAmount(address grantee)
        external
        view
        returns (uint256 prpAmount);

    /// @notice Returns the PRP amount of the grant specified by a given curator and type
    function getGrantAmount(address curator, bytes4 grantType)
        external
        view
        returns (uint256 prpAmount);

    /// @notice Increase the amount of "unused" grants for the given grantee, by the amount
    /// defined for the given "grant type"
    /// @return prpAmount The amount (in PRPs) of the grant
    /// @dev An authorized "curator" may call with the enabled (added) "grant type" only
    function issueGrant(address grantee, bytes4 grantType)
        external
        returns (uint256 prpAmount);

    /// @notice Increase the amount of "unused" grants for the given grantee, by the amount
    /// specified.
    /// @dev Only the owner may call.
    function issueOwnerGrant(address grantee, uint256 prpAmount) external;

    /// @notice Burn unused grants for the msg.sender in the specified PRP amount
    function burnGrant(uint256 prpAmount) external;

    /// @notice Account for redemption of grants in the given amount for the given grantee
    /// @dev Only the account returned by `grantProcessor()` may call
    function redeemGrant(address grantee, uint256 prpAmount) external;

    /// @notice PRP grant issued
    event PrpGrantIssued(
        bytes4 indexed grantType,
        address grantee,
        uint256 prpAmount
    );

    /// @notice PRP grant redeemed (used)
    event PrpGrantRedeemed(address grantee, uint256 prpAmount);

    /// @notice PRP grant burnt
    event PrpGrantBurnt(address grantee, uint256 prpAmount);

    /// @notice New grant type added
    event PrpGrantEnabled(address curator, bytes4 grantType, uint256 prpAmount);

    /// @notice Existing grant type disabled
    event PrpGrantDisabled(address curator, bytes4 grantType);
}