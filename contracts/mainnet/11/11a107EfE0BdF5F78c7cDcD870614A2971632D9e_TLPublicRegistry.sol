// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.14;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import './ILinearCliffTimelock.sol';

/**
 * @notice Public registry for LinearCliffTimelock contracts.
 * @notice The registry is used for the frontend at "https://github.com/difof" for indexing timelocks.
 */
contract TLPublicRegistry {
    /// @dev List of beneficiary timelocks
    mapping(address => ILinearCliffTimelock[]) private _timelocks;

    /// @dev Used to avoid duplicate timelocks
    mapping(ILinearCliffTimelock => address) private _timelockBeneficiary;

    /**
     * @dev Maps a timelock to beneficiary
     * @param beneficiary The beneficiary of the timelock
     * @param timelock The timelock to map
     */
    function addTimelock(address beneficiary, ILinearCliffTimelock timelock)
        external
    {
        require(
            _timelockBeneficiary[timelock] == address(0),
            'ERROR_ALREADY_ADDED'
        );

        require(
            timelock.supportsInterface(type(ILinearCliffTimelock).interfaceId),
            'ERROR_NOT_TIMELOCK'
        );

        require(
            timelock.beneficiary() == beneficiary,
            'ERROR_BENEFICIARY_MISMATCH'
        );

        require(timelock.balance() > 0, 'ERROR_NO_BALANCE');

        _timelocks[beneficiary].push(timelock);
        _timelockBeneficiary[timelock] = beneficiary;
    }

    /**
     * @dev Returns the list of timelocks for a beneficiary
     * @param beneficiary The beneficiary of the timelocks
     * @return - The list of timelocks for the beneficiary
     */
    function timelocks(address beneficiary)
        external
        view
        returns (ILinearCliffTimelock[] memory)
    {
        return _timelocks[beneficiary];
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

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.14;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/**
 * @notice A customizable timelock for vesting any ERC20 token.
 * @dev Once the timelock is deployed, contract must be approved to spend the amount of token on behalf on the sender.
 * @dev `initialize` function must be called by the `INITIALIZE_ROLE` role (or from deployer by default) to initialize the timelock.
 * @dev Anyone with `WITHDRAW_ROLE` can withdraw to the beneficiary.
 * @dev Timelock cliff defines how many times and how many tokens can the beneficiary withdraw in timelock start and end periods.
 */
interface ILinearCliffTimelock is IERC165 {
    event OnInitialized(
        IERC20 indexed token,
        address indexed beneficiary,
        uint256 indexed amount,
        uint256 cliffStart,
        uint256 cliffEnd,
        uint256 cliffTimePeriod
    );

    /**
     * @dev Emitted on token withdraw
     * @param amount The amount of tokens withdrawn
     * @param next Next timestamp for tokens to be released. If 0, the timelock is over.
     */
    event OnWithdraw(uint256 indexed amount, uint256 next);

    function token() external view returns (IERC20);

    function beneficiary() external view returns (address);

    function totalLocked() external view returns (uint256);

    function cliffStart() external view returns (uint256);

    function cliffEnd() external view returns (uint256);

    function cliffTimePeriod() external view returns (uint256);

    function cliffEdge() external view returns (uint256);

    function cliffAmount() external view returns (uint256);

    function initialized() external view returns (bool);

    /**
     * @notice Call this function after deploying and allowing the timelock to spend the token from sender.
     * @dev if `_cliffTimePeriod` is `_cliffEnd` - `_cliffStart`, then the timelock will be released at the end of the cliff period.
     * @param _token Token to be spent and locked.
     * @param _amount Amount of token to be locked.
     * @param _sender Sender/spender of the token.
     * @param _beneficiary Beneficiary of the token whom the tokens will be withdrawn to.
     * @param _cliffStart Timestamp of lock start in seconds.
     * @param _cliffEnd Timestamp of lock end in seconds.
     * @param _cliffTimePeriod Duration of each cliff in seconds.
     */
    function initialize(
        IERC20 _token,
        uint256 _amount,
        address _sender,
        address _beneficiary,
        uint256 _cliffStart,
        uint256 _cliffEnd,
        uint256 _cliffTimePeriod
    ) external;

    /**
     * @notice Withdraw the locked tokens to the beneficiary.
     * @dev If cliff edge is past `now`, then all of the tokens will be withdrawn.
     */
    function withdraw() external;

    /// @return - Balance of the timelock in locked tokens.
    function balance() external view returns (uint256);
}

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