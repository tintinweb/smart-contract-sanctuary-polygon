// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.15;

import "./BaseMinter.sol";

/**
 * @title DebtMinter
 * BOB minting/burning middleware for generic debt-minting use-cases.
 */
contract DebtMinter is BaseMinter {
    struct Parameters {
        uint104 maxDebtLimit; // max possible debt limit
        uint104 minDebtLimit; // min possible debt limit
        uint48 raiseDelay; // min delay between debt limit raises
        uint96 raise; // debt limit raising step
        address treasury; // receiver of repaid debt surplus
    }

    struct State {
        uint104 debtLimit; // current debt limit, minDebtLimit <= debtLimit <= maxDebtLimit
        uint104 debt; // current debt value
        uint48 lastRaise; // timestamp of last debt limit raise
    }

    Parameters internal parameters;
    State internal state;

    event UpdateDebt(uint104 debt, uint104 debtLimit);

    constructor(
        address _token,
        uint104 _maxDebtLimit,
        uint104 _minDebtLimit,
        uint48 _raiseDelay,
        uint96 _raise,
        address _treasury
    )
        BaseMinter(_token)
    {
        require(_minDebtLimit + uint104(_raise) <= _maxDebtLimit, "DebtMinter: invalid raise");
        parameters = Parameters(_maxDebtLimit, _minDebtLimit, _raiseDelay, _raise, _treasury);
        state = State(_minDebtLimit, 0, uint48(block.timestamp));
    }

    function getState() external view returns (State memory) {
        return state;
    }

    function getParameters() external view returns (Parameters memory) {
        return parameters;
    }

    /**
     * @dev Tells remaining mint amount subject to immediate debt limit.
     * @return available mint amount.
     */
    function maxDebtIncrease() external view returns (uint256) {
        Parameters memory p = parameters;
        State memory s = state;
        _updateDebtLimit(p, s);
        return s.debtLimit - s.debt;
    }

    /**
     * @dev Updates limit configuration.
     * Callable only by the contract owner.
     * @param _params new parameters to apply.
     */
    function updateParameters(Parameters calldata _params) external onlyOwner {
        require(_params.minDebtLimit + uint104(_params.raise) <= _params.maxDebtLimit, "DebtMinter: invalid raise");
        parameters = _params;

        State memory s = state;
        _updateDebtLimit(_params, s);
        state = s;

        emit UpdateDebt(s.debt, s.debtLimit);
    }

    /**
     * @dev Internal function for adjusting debt limits on tokens mint.
     * @param _amount amount of minted tokens.
     */
    function _beforeMint(uint256 _amount) internal override {
        Parameters memory p = parameters;
        State memory s = state;

        _updateDebtLimit(p, s);
        uint256 newDebt = uint256(s.debt) + _amount;
        require(newDebt <= s.debtLimit, "DebtMinter: exceeds debt limit");
        s.debt = uint104(newDebt);

        state = s;

        emit UpdateDebt(s.debt, s.debtLimit);
    }

    /**
     * @dev Internal function for adjusting debt limits on tokens burn.
     * @param _amount amount of burnt tokens.
     */
    function _beforeBurn(uint256 _amount) internal override {
        Parameters memory p = parameters;
        State memory s = state;

        unchecked {
            if (_amount <= s.debt) {
                s.debt -= uint104(_amount);
            } else {
                IMintableERC20(token).mint(p.treasury, _amount - s.debt);
                s.debt = 0;
            }
        }
        _updateDebtLimit(p, s);
        state = s;

        emit UpdateDebt(s.debt, s.debtLimit);
    }

    /**
     * @dev Internal function for recalculating immediate debt limit.
     */
    function _updateDebtLimit(Parameters memory p, State memory s) internal view {
        if (s.debt >= p.maxDebtLimit) {
            s.debtLimit = s.debt;
        } else {
            uint104 newDebtLimit = s.debt + p.raise;
            if (newDebtLimit < p.minDebtLimit) {
                s.debtLimit = p.minDebtLimit;
                return;
            }

            if (newDebtLimit > p.maxDebtLimit) {
                newDebtLimit = p.maxDebtLimit;
            }
            if (newDebtLimit <= s.debtLimit) {
                s.debtLimit = newDebtLimit;
            } else if (s.lastRaise + p.raiseDelay < block.timestamp) {
                s.debtLimit = newDebtLimit;
                s.lastRaise = uint48(block.timestamp);
            }
        }
    }
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.15;

import "../utils/Ownable.sol";
import "../interfaces/IMintableERC20.sol";
import "../interfaces/IBurnableERC20.sol";
import "../interfaces/IERC677Receiver.sol";

/**
 * @title BaseMinter
 * Base contract for BOB minting/burning middleware
 */
abstract contract BaseMinter is IMintableERC20, IBurnableERC20, IERC677Receiver, Ownable {
    address public immutable token;

    mapping(address => bool) public isMinter;

    event UpdateMinter(address indexed minter, bool enabled);
    event Mint(address minter, address to, uint256 amount);
    event Burn(address burner, address from, uint256 amount);

    constructor(address _token) {
        token = _token;
    }

    /**
     * @dev Updates mint/burn permissions for the given address.
     * Callable only by the contract owner.
     * @param _account managed minter account address.
     * @param _enabled true, if enabling minting/burning, false otherwise.
     */
    function setMinter(address _account, bool _enabled) external onlyOwner {
        isMinter[_account] = _enabled;

        emit UpdateMinter(_account, _enabled);
    }

    /**
     * @dev Mints the specified amount of tokens.
     * This contract should have minting permissions assigned to it in the token contract.
     * Callable only by one of the minter addresses.
     * @param _to address of the tokens receiver.
     * @param _amount amount of tokens to mint.
     */
    function mint(address _to, uint256 _amount) external override {
        require(isMinter[msg.sender], "BaseMinter: not a minter");

        _beforeMint(_amount);
        IMintableERC20(token).mint(_to, _amount);

        emit Mint(msg.sender, _to, _amount);
    }

    /**
     * @dev Burns tokens sent to the address.
     * Callable only by one of the minter addresses.
     * Caller should send specified amount of tokens to this contract, prior to calling burn.
     * @param _amount amount of tokens to burn.
     */
    function burn(uint256 _amount) external override {
        require(isMinter[msg.sender], "BaseMinter: not a burner");

        _beforeBurn(_amount);
        IBurnableERC20(token).burn(_amount);

        emit Burn(msg.sender, msg.sender, _amount);
    }

    /**
     * @dev Burns pre-approved tokens from the other address.
     * Callable only by one of the burner addresses.
     * Minters should handle with extra care cases when first argument is not msg.sender.
     * @param _from account to burn tokens from.
     * @param _amount amount of tokens to burn. Should be less than or equal to account balance.
     */
    function burnFrom(address _from, uint256 _amount) external override {
        require(isMinter[msg.sender], "BaseMinter: not a burner");

        _beforeBurn(_amount);
        IBurnableERC20(token).burnFrom(_from, _amount);

        emit Burn(msg.sender, _from, _amount);
    }

    /**
     * @dev ERC677 callback for burning tokens atomically.
     * @param _from tokens sender, should correspond to one of the minting addresses.
     * @param _amount amount of sent/burnt tokens.
     * @param _data extra data, not used.
     */
    function onTokenTransfer(address _from, uint256 _amount, bytes calldata _data) external override returns (bool) {
        require(msg.sender == address(token), "BaseMinter: not a token");
        require(isMinter[_from], "BaseMinter: not a burner");

        _beforeBurn(_amount);
        IBurnableERC20(token).burn(_amount);

        emit Burn(_from, _from, _amount);

        return true;
    }

    function _beforeMint(uint256 _amount) internal virtual;

    function _beforeBurn(uint256 _amount) internal virtual;
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol" as OZOwnable;

/**
 * @title Ownable
 */
contract Ownable is OZOwnable.Ownable {
    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view override {
        require(_isOwner(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Tells if caller is the contract owner.
     * @return true, if caller is the contract owner.
     */
    function _isOwner() internal view virtual returns (bool) {
        return owner() == _msgSender();
    }
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.15;

interface IMintableERC20 {
    function mint(address to, uint256 amount) external;
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.15;

interface IBurnableERC20 {
    function burn(uint256 amount) external;
    function burnFrom(address user, uint256 amount) external;
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.15;

interface IERC677Receiver {
    function onTokenTransfer(address from, uint256 value, bytes calldata data) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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