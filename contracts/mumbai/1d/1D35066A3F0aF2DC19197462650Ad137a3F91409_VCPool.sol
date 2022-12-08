// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IVCStarter.sol";
import "../interfaces/IPoCNft.sol";

contract VCPool {
    error PoolNotStarter();
    error PoolNotAdmin();
    error PoolUnexpectedAddress();
    error PoolERC20TransferError();
    error PoolAmountTooHigh();
    error PoolInvalidCurrency();

    event AdminChanged(address oldAmin, address newAdmin);
    event StarterChanged(address oldStarer, address newStarer);
    event PoCNftChanged(address oldPocNft, address newPocNft);
    event Funding(address indexed user, uint256 amount);
    event Withdrawal(IERC20 indexed currency, address indexed to, uint256 amount);

    address _admin;
    address _starter;
    IPoCNft _pocNft;
    IERC20 _currency;

    // REMARK OFF-CHAIN QUERIES:
    // 1) To obtain the balance of the Pool one has to call _currency.balanceOf(poolAddress)
    // 2) To obtain the totalRaisedFunds, one has to add to 1) the totalWithdrawnAmount obtainedg from the subgraph

    constructor(IERC20 currency, address admin) {
        if (admin == address(this) || admin == address(0)) {
            revert PoolUnexpectedAddress();
        }
        _admin = admin;
        _currency = currency;
    }

    ///////////////////////////////////////////////
    //           ONLY-ADMIN FUNCTIONS
    ///////////////////////////////////////////////

    function setPoCNft(address _poolNFT) external {
        _onlyAdmin();
        _pocNft = IPoCNft(_poolNFT);
    }

    function setCurrency(IERC20 currency) external {
        _onlyAdmin();
        _currency = currency;
    }

    function setStarter(address starter) external {
        _onlyAdmin();
        _starter = starter;
    }

    function supportPoolFromStarter(address _supporter, uint256 _amount) external {
        _onlyStarter();
        _pocNft.mint(_supporter, _amount);
        // emit event?
    }

    function changeAdmin(address admin) external {
        _onlyAdmin();
        if (admin == address(this) || admin == address(0) || admin == address(_admin)) {
            revert PoolUnexpectedAddress();
        }
        emit AdminChanged(_admin, admin);
        _admin = admin;
    }

    function changeStarter(address starter) external {
        _onlyAdmin();
        if (starter == address(this) || starter == address(0) || starter == address(_starter)) {
            revert PoolUnexpectedAddress();
        }
        emit StarterChanged(_starter, starter);
        _starter = starter;
    }

    function changePoCNft(address pocNft) external {
        _onlyAdmin();
        if (pocNft == address(this) || pocNft == address(0) || pocNft == address(_pocNft)) {
            revert PoolUnexpectedAddress();
        }
        emit PoCNftChanged(address(_pocNft), pocNft);
        _pocNft = IPoCNft(pocNft);
    }

    function withdraw(
        IERC20 currency,
        address _to,
        uint256 _amount
    ) external {
        _onlyAdmin();
        if (currency == _currency) {
            revert PoolInvalidCurrency();
        }
        uint256 available = currency.balanceOf(address(this));
        if (_amount > available) {
            revert PoolAmountTooHigh();
        }
        if (!currency.transferFrom(address(this), _to, _amount)) {
            revert PoolERC20TransferError();
        }
        emit Withdrawal(currency, _to, _amount);
    }

    // for flash grants
    function withdrawToProject(address _project, uint256 _amount) external {
        _onlyAdmin();
        uint256 available = _currency.balanceOf(address(this));
        if (_amount > available) {
            revert PoolAmountTooHigh();
        }
        _currency.approve(_starter, _amount);
        IVCStarter(_starter).fundProjectOnBehalf(address(this), _project, _currency, _amount);
    }

    ///////////////////////////////////////////////
    //         EXTERNAL/PUBLIC FUNCTIONS
    ///////////////////////////////////////////////

    function fund(uint256 _amount) external {
        if (!_currency.transferFrom(msg.sender, address(this), _amount)) {
            revert PoolERC20TransferError();
        }
        _pocNft.mint(msg.sender, _amount);
        emit Funding(msg.sender, _amount);
    }

    function getCurrency() external view returns (IERC20) {
        return _currency;
    }

    ///////////////////////////////////////////////
    //        INTERNAL/PRIVATE FUNCTIONS
    ///////////////////////////////////////////////

    function _onlyAdmin() internal view {
        if (msg.sender != _admin) {
            revert PoolNotAdmin();
        }
    }

    function _onlyStarter() internal view {
        if (msg.sender != _starter) {
            revert PoolNotStarter();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct Project {
    address _projectAddress;
    address _lab;
}

interface IVCStarter {
    function changeAdmin(address admin) external;

    function whitelistLab(address lab) external;

    function blacklistLab(address lab) external;

    function listCurrency(IERC20 currency) external;

    function unlistCurrency(IERC20 currency) external;

    function setMinCampaignDuration(uint256 minCampaignDuration) external;

    function setMaxCampaignDuration(uint256 maxCampaignDuration) external;

    function setMaxCampaignOffset(uint256 maxCampaignOffset) external;

    function setMinCampaignTarget(uint256 minCampaignTarget) external;

    function setMaxCampaignTarget(uint256 maxCampaignTarget) external;

    function setSoftTargetBps(uint256 softTargetBps) external;

    function setPoCNft(address _pocNft) external;

    function createProject(address _lab) external returns (address);

    function areActiveProjects(address[] memory _projects) external view returns (bool[] memory);

    function fundProjectOnBehalf(
        address _user,
        address _project,
        IERC20 _currency,
        uint256 _amount
    ) external;
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IPoCNft {
    function mint(address _user, uint256 _amount) external;

    function getVotingPowerBoost(address _user) external view returns (uint256 votingPowerBoost);
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