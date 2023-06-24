// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "./interface/IOwnable.sol";

/**
 *  @title   Ownable
 *  @notice  Thirdweb's `Ownable` is a contract extension to be used with any base contract. It exposes functions for setting and reading
 *           who the 'owner' of the inheriting smart contract is, and lets the inheriting contract perform conditional logic that uses
 *           information about who the contract's owner is.
 */

abstract contract Ownable is IOwnable {
    /// @dev Owner of the contract (purpose: OpenSea compatibility)
    address private _owner;

    /// @dev Reverts if caller is not the owner.
    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert("Not authorized");
        }
        _;
    }

    /**
     *  @notice Returns the owner of the contract.
     */
    function owner() public view override returns (address) {
        return _owner;
    }

    /**
     *  @notice Lets an authorized wallet set a new owner for the contract.
     *  @param _newOwner The address to set as the new owner of the contract.
     */
    function setOwner(address _newOwner) external override {
        if (!_canSetOwner()) {
            revert("Not authorized");
        }
        _setupOwner(_newOwner);
    }

    /// @dev Lets a contract admin set a new owner for the contract. The new owner must be a contract admin.
    function _setupOwner(address _newOwner) internal {
        address _prevOwner = _owner;
        _owner = _newOwner;

        emit OwnerUpdated(_prevOwner, _newOwner);
    }

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal view virtual returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

/**
 *  Thirdweb's `Ownable` is a contract extension to be used with any base contract. It exposes functions for setting and reading
 *  who the 'owner' of the inheriting smart contract is, and lets the inheriting contract perform conditional logic that uses
 *  information about who the contract's owner is.
 */

interface IOwnable {
    /// @dev Returns the owner of the contract.
    function owner() external view returns (address);

    /// @dev Lets a module admin set a new owner for the contract. The new owner must be a module admin.
    function setOwner(address _newOwner) external;

    /// @dev Emitted when a new Owner is set.
    event OwnerUpdated(address indexed prevOwner, address indexed newOwner);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 amount) external;

    function transfer(address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

// Helper interfaces
import { IWETH } from "../interfaces/IWETH.sol";

import "../openzeppelin-presets/token/ERC20/utils/SafeERC20.sol";

library CurrencyTransferLib {
    using SafeERC20 for IERC20;

    /// @dev The address interpreted as native token of the chain.
    address public constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev Transfers a given amount of currency.
    function transferCurrency(
        address _currency,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        if (_amount == 0) {
            return;
        }

        if (_currency == NATIVE_TOKEN) {
            safeTransferNativeToken(_to, _amount);
        } else {
            safeTransferERC20(_currency, _from, _to, _amount);
        }
    }

    /// @dev Transfers a given amount of currency. (With native token wrapping)
    function transferCurrencyWithWrapper(
        address _currency,
        address _from,
        address _to,
        uint256 _amount,
        address _nativeTokenWrapper
    ) internal {
        if (_amount == 0) {
            return;
        }

        if (_currency == NATIVE_TOKEN) {
            if (_from == address(this)) {
                // withdraw from weth then transfer withdrawn native token to recipient
                IWETH(_nativeTokenWrapper).withdraw(_amount);
                safeTransferNativeTokenWithWrapper(_to, _amount, _nativeTokenWrapper);
            } else if (_to == address(this)) {
                // store native currency in weth
                require(_amount == msg.value, "msg.value != amount");
                IWETH(_nativeTokenWrapper).deposit{ value: _amount }();
            } else {
                safeTransferNativeTokenWithWrapper(_to, _amount, _nativeTokenWrapper);
            }
        } else {
            safeTransferERC20(_currency, _from, _to, _amount);
        }
    }

    /// @dev Transfer `amount` of ERC20 token from `from` to `to`.
    function safeTransferERC20(
        address _currency,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        if (_from == _to) {
            return;
        }

        if (_from == address(this)) {
            IERC20(_currency).safeTransfer(_to, _amount);
        } else {
            IERC20(_currency).safeTransferFrom(_from, _to, _amount);
        }
    }

    /// @dev Transfers `amount` of native token to `to`.
    function safeTransferNativeToken(address to, uint256 value) internal {
        // solhint-disable avoid-low-level-calls
        // slither-disable-next-line low-level-calls
        (bool success, ) = to.call{ value: value }("");
        require(success, "native token transfer failed");
    }

    /// @dev Transfers `amount` of native token to `to`. (With native token wrapping)
    function safeTransferNativeTokenWithWrapper(
        address to,
        uint256 value,
        address _nativeTokenWrapper
    ) internal {
        // solhint-disable avoid-low-level-calls
        // slither-disable-next-line low-level-calls
        (bool success, ) = to.call{ value: value }("");
        if (!success) {
            IWETH(_nativeTokenWrapper).deposit{ value: value }();
            IERC20(_nativeTokenWrapper).safeTransfer(to, value);
        }
    }
}

// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

/// @author thirdweb

/**
 * @dev Collection of functions related to the address type
 */
library TWAddress {
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
     * [EIP1884](https://eips.ethereum.org/EIPS/eip-1884) increases the gas cost
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

        (bool success, ) = recipient.call{ value: amount }("");
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

        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../../../../eip/interface/IERC20.sol";
import "../../../../lib/TWAddress.sol";

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
    using TWAddress for address;

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

pragma solidity ^0.8.0;
//SPDX-License-Identifier: 	CC-BY-NC-2.5

interface ICompetition {
    function createNewCompetition(uint256 _entryTokenId, string[] memory _teams, uint256 _firstStageEnd) external;
    function registerIntoCompetition(uint256 _tokenId, uint256 _redeemedTokenId) external;
    function makePrediction(uint256 _entryTokenId, uint256 _redeemedTokenId, string calldata _prediction) external;
    function resetPostponed(uint256 _entryTokenId, string[] calldata _postponedTeams) external;
    function settleCompetitionStage(uint256 _entryTokenId, string[] calldata _winningTeams, uint256 _nextStageEnd)
        external
        returns (uint256[] memory, uint256[] memory);
    function canClaimPrize(uint256 _entryTokenId, uint256 _redeemedTokenId) external returns (bool, uint256);
    function acceptsRegistration(uint256 _entryTokenId) external returns (bool);
}

struct Participant {
    uint256 tokenId;
    uint128 prediction;
    uint128 pastPredictions; // encode all predictions as bitmask
    bool eliminated;
}

struct Team {
    uint128 id;
    bool valid;
}

struct Winner {
    uint256 redeemedTokenId;
    bool hasClaimedPrize;
}

struct Competition {
    uint256 entryTokenId;
    mapping(string => Team) teams;
    uint256[] participantIds;
    mapping(uint256 => Participant) participantsMap;
    uint256 currentStageEnd;
    bool isRegistrationStage;
    Winner[] winners;
}

struct CompetitionStageInfo {
    bool[] currentParticipantIds;
    uint256 eliminatedParticipants;
    uint256 currentValidParticipants;
}

pragma solidity ^0.8.0;
//SPDX-License-Identifier: 	CC-BY-NC-2.5

interface ICompetitionOrganiser {
    event NewCompetition(uint256 indexed entryTokenId, uint256 indexed leagueId, uint256 firstStageEnd);

    event CompetitionRegistration(uint256 indexed entryTokenId, uint256 indexed redeemedTokenId);

    event Prediction(uint256 indexed entryTokenId, uint256 indexed redeemedTokenId, string prediction);

    event CompetitionElimination(uint256 indexed entryTokenId, uint256 indexed redeemedTokenId);

    event CompetitionWinner(uint256 indexed entryTokenId, uint256 indexed redeemedTokenId);

    event PrizeClaim(uint256 indexed entryTokenId, uint256 indexed redeemedTokenId);

    event CompetitionStageSettled(uint256 indexed entryTokenId, uint256 nextStageEnd);

    event PostponedTeams(uint256 indexed entryTokenId, string[] postponedTeams);
}

//SPDX-License-Identifier: 	CC-BY-NC-2.5
pragma solidity ^0.8.0;

interface IGameTokenProvider {
    /// @notice The tokenId assigned to the next new NFT to be lazy minted.
    function getNextTokenIdToMint() external view returns (uint256);
    function registerEntryToCompetition(address _receiver, uint256 _tokenID) external returns (uint256);
    function getBalanceOf(address _owner, uint256 _tokenId) external view returns (uint256);
    function getCompetitionPrize(uint256 _tokenId) external view returns (uint256);

    event PrizeUpdate(uint256 indexed tokenId, uint256 amount);
}

pragma solidity ^0.8.0;
//SPDX-License-Identifier: 	CC-BY-NC-2.5

import "@thirdweb-dev/contracts/extension/Ownable.sol";
import "./IGameTokenProvider.sol";
import "./ICompetitionOrganiser.sol";
import "./ICompetition.sol";
import "@thirdweb-dev/contracts/lib/CurrencyTransferLib.sol";

contract LastManStanding is Ownable, ICompetitionOrganiser {
    uint128 constant MAX_UINT128 = type(uint128).max;
    uint256 public nextLeagueId;
    mapping(uint256 => string[]) leagueToTeams;
    mapping(uint256 => ICompetition) public competitions;

    IGameTokenProvider internal tokenContract;
    address tokenContractAddr;

    constructor(address _tokenContractAddress) {
        _setupOwner(msg.sender);
        tokenContract = IGameTokenProvider(_tokenContractAddress);
        tokenContractAddr = _tokenContractAddress;
    }

    receive() external payable {}

    function createNewLeague(string[] calldata _teams) external onlyOwner {
        string[] storage league = leagueToTeams[nextLeagueId];
        for (uint256 i = 0; i < _teams.length; i++) {
            league.push(_teams[i]);
        }
        nextLeagueId++;
    }

    function createNewCompetition(
        address _competitionAddress,
        uint256 _entryTokenId,
        uint256 _leagueId,
        uint256 _firstStageEnd
    ) external onlyOwner {
        require(leagueToTeams[_leagueId].length > 0, "League doesn't exist!");
        require(_entryTokenId < tokenContract.getNextTokenIdToMint(), "Token doesn't exist");

        ICompetition comp = ICompetition(_competitionAddress);
        competitions[_entryTokenId] = comp;
        comp.createNewCompetition(_entryTokenId, leagueToTeams[_leagueId], _firstStageEnd);

        emit NewCompetition(_entryTokenId, _leagueId, _firstStageEnd);
    }

    function registerIntoCompetition(uint256 _tokenId, address _newEntrant) external {
        require(msg.sender == _newEntrant, "!Register someone else");
        ICompetition comp = competitions[_tokenId];
        require(comp.acceptsRegistration(_tokenId), "Cannot register");

        uint256 redeemedTokenId = tokenContract.registerEntryToCompetition(_newEntrant, _tokenId);

        comp.registerIntoCompetition(_tokenId, redeemedTokenId);

        emit CompetitionRegistration(_tokenId, redeemedTokenId);
    }

    function makePrediction(uint256 _entryTokenId, uint256 _redeemedTokenId, string calldata _prediction) external {
        require(tokenContract.getBalanceOf(msg.sender, _redeemedTokenId) > 0, "!Redeemed ticket owner");
        ICompetition comp = competitions[_entryTokenId];

        comp.makePrediction(_entryTokenId, _redeemedTokenId, _prediction);

        emit Prediction(_entryTokenId, _redeemedTokenId, _prediction);
    }

    function resetPostponed(uint256 _entryTokenId, string[] calldata _postponedTeams) external onlyOwner {
        require(_entryTokenId < tokenContract.getNextTokenIdToMint(), "Token doesn't exist");

        ICompetition comp = competitions[_entryTokenId];
        comp.resetPostponed(_entryTokenId, _postponedTeams);

        emit PostponedTeams(_entryTokenId, _postponedTeams);
    }

    function settleCompetitionStage(uint256 _entryTokenId, string[] calldata _winningTeams, uint256 _nextStageEnd)
        external
        onlyOwner
    {
        require(_entryTokenId < tokenContract.getNextTokenIdToMint(), "Token doesn't exist");
        ICompetition comp = competitions[_entryTokenId];

        (uint256[] memory eliminated, uint256[] memory winners) =
            comp.settleCompetitionStage(_entryTokenId, _winningTeams, _nextStageEnd);

        for (uint256 i; i < eliminated.length && eliminated[i] != 0; i++) {
            emit CompetitionElimination(_entryTokenId, eliminated[i]);
        }

        emit CompetitionStageSettled(_entryTokenId, _nextStageEnd);

        for (uint256 i; i < winners.length && winners[i] != 0; i++) {
            emit CompetitionWinner(_entryTokenId, winners[i]);
        }
    }

    function claimPrize(uint256 _entryTokenId, uint256 _redeemedTokenId, address _owner) external {
        require(tokenContract.getBalanceOf(_owner, _redeemedTokenId) > 0, "!Redeemed ticket owner");
        ICompetition comp = competitions[_entryTokenId];
        (bool canClaim, uint256 winnersLen) = comp.canClaimPrize(_entryTokenId, _redeemedTokenId);

        require(canClaim, "!Claim prize");

        uint256 prize = tokenContract.getCompetitionPrize(_entryTokenId);
        CurrencyTransferLib.safeTransferNativeToken(_owner, prize / winnersLen);

        emit PrizeClaim(_entryTokenId, _redeemedTokenId);
    }

    function _validateTeams(string[] calldata _teamsToValidate, mapping(string => Team) storage _validTeams)
        private
        view
        returns (uint256)
    {
        uint256 teamsBitmask;
        for (uint256 i; i < _teamsToValidate.length; i++) {
            Team storage t = _validTeams[_teamsToValidate[i]];
            if (!t.valid) {
                revert("Invalid team!");
            }
            teamsBitmask |= (1 << t.id);
        }
        return teamsBitmask;
    }

    function _validateTeamPrediction(string calldata _teamToValidate, mapping(string => Team) storage _validTeams)
        private
        view
        returns (uint128)
    {
        Team storage t = _validTeams[_teamToValidate];
        if (!t.valid) {
            revert("Invalid team for competition!");
        }
        return t.id;
    }

    function _canSetOwner() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }
}