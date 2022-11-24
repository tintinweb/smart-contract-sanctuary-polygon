/**
 *Submitted for verification at polygonscan.com on 2022-11-23
*/

// File: contracts/IERC20Burnable.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Burnable {
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
    function maxSupply() external view returns (uint256);

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

    function mint(address to, uint256 amount) external;
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;

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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/Vesting.sol


pragma solidity ^0.8.9;




contract Vesting is Context, Ownable {
    struct Step {
        uint256 step_date;
        uint256 launchpad;
        uint256 private_sale;
        uint256 team;
        uint256 advisors;
        uint256 treasury;
        bool paid;
    }

    uint256 private constant ONE_QUARTAL_SECONDS = (365.255 * 24 * 60 * 60) / 4;

    uint256 public constant total_quartals = 28;

    uint256 public constant max_percent = 1000;

    uint256 public constant launchpad_percent = 60;
    uint256 public constant private_sale_percent = 150;
    uint256 public constant team_percent = 200;
    uint256 public constant advisors_percent = 20;
    uint256 public constant treasury_percent_first = 25;
    uint256 public constant treasury_percent_left = 145;

    address public token;

    address public launchpad;
    address public private_sale;
    address public team;
    address public advisors;
    address public treasury;

    uint256 public launchpad_cliff_left = 0;
    uint256 public private_sale_cliff_left = 4; // 4 quartals = 12 month
    uint256 public team_cliff_left = 4; // 4 quartals = 12 month
    uint256 public advisors_cliff_left = 4; // 4 quartals = 12 month
    uint256 public treasury_cliff_left = 0;

    uint256 public start_time;
    uint256 public last_claim;

    uint256 public total_amount;
    
    mapping(uint256 => Step) public steps;

    constructor(
        address _token,
        address _launchpad,
        address _private_sale,
        address _team,
        address _advisors,
        address _treasury
    ) {
        token = _token;

        launchpad = _launchpad;
        private_sale = _private_sale;
        team = _team;
        advisors = _advisors;
        treasury = _treasury;

        _transferOwnership(_msgSender());
    }

    function getStep(uint256 stepId) public view returns (Step memory step) {
        step = steps[stepId];
    }

    function startVesting() public onlyOwner {
        uint256 balance = IERC20Burnable(token).balanceOf(_msgSender());
        require(IERC20Burnable(token).allowance(_msgSender(), address(this)) == balance, "Vesting: you must allow all tokens");
        
        IERC20Burnable(token).transferFrom(_msgSender(), address(this), balance);

        start_time = block.timestamp - (block.timestamp % ONE_QUARTAL_SECONDS);
        _init();

        _claim();
    }

    function claim() public {
        require(start_time != 0, "Vesting: must be started");

        _claim();
    }

    function _claim() internal {
        Step memory step = Step(0, 0, 0, 0, 0, 0, false);
        for(uint256 i = 0; i < total_quartals; i += 1) {
            Step storage _step = steps[i];

            if (!_step.paid && block.timestamp > _step.step_date) {
                step.launchpad += _step.launchpad;
                step.private_sale += _step.private_sale;
                step.team += _step.team;
                step.advisors += _step.advisors;
                step.treasury += _step.treasury;

                _step.paid = true;
            }
        }

        if (step.launchpad != 0) {
            IERC20Burnable(token).transfer(launchpad, step.launchpad);
        }
        
        if (step.private_sale != 0) {
            IERC20Burnable(token).transfer(private_sale, step.private_sale);
        }
        
        if (step.team != 0) {
            IERC20Burnable(token).transfer(team, step.team);
        }

        if (step.advisors != 0) {
            IERC20Burnable(token).transfer(advisors, step.advisors);
        }

        if (step.treasury != 0) {
            IERC20Burnable(token).transfer(treasury, step.treasury);
        }

        last_claim = block.timestamp - (block.timestamp % ONE_QUARTAL_SECONDS);
    }

    function _init() internal {
        total_amount = IERC20Burnable(token).maxSupply();

        for(uint256 i = 0; i < total_quartals; i += 1) {
            Step memory step = Step(
                start_time + i * ONE_QUARTAL_SECONDS,
                _getLaunchpadStepAmount(i),
                _getPrivateSaleStepAmount(i),
                _getTeamStepAmount(i),
                _getAdvisorsStepAmount(i),
                _getTreasuryStepAmount(i),
                false
            );

            steps[i] = step;
        }
    }

    function _getLaunchpadStepAmount(uint256 step) internal view returns (uint256) {
        if (step == 0) {
            return (total_amount * launchpad_percent) / max_percent;
        }

        return 0;
    }

    function _getPrivateSaleStepAmount(uint256 step) internal view returns (uint256) {
        if (step >= private_sale_cliff_left && step < private_sale_cliff_left + 8) {
            return total_amount * private_sale_percent / max_percent / 8;
        }

        return 0;
    }

    function _getTeamStepAmount(uint256 step) internal view returns (uint256) {
        if (step >= team_cliff_left && step < team_cliff_left + 16) {
            return total_amount * team_percent / max_percent / 16;
        }

        return 0;
    }

    function _getAdvisorsStepAmount(uint256 step) internal view returns (uint256) {
        if (step >= advisors_cliff_left && step < advisors_cliff_left + 8) {
            return total_amount * advisors_percent / max_percent / 8;
        }

        return 0;
    }

    function _getTreasuryStepAmount(uint256 step) internal view returns (uint256) {
        if (step == 0) {
            return total_amount * treasury_percent_first / max_percent;
        }

        if (step > 0 && step < 27) {
            return total_amount * treasury_percent_left / max_percent / 27;
        }

        if (step == 27) {
            return total_amount * treasury_percent_left / max_percent / 27 + 3;
        }

        return 0;
    }
}