/**
 *Submitted for verification at polygonscan.com on 2023-03-07
*/

// Sources flattened with hardhat v2.12.6 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

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


// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File contracts/IDistributorService.sol

interface IDistributorService {

    struct DistributorServiceState {
        uint256 ethBalance;
        address[] distributors;
        uint256[] distributorsEthBalances;
        bool[] distributorsActiveStatus;
        address[] tokens;
        uint256[] contractTokenBalances;
    }

    function distribute(
        address[] memory receivers,
        address[] memory tokens,
        uint256[] memory amounts
    ) external;

    function distributeToken(
        address[] memory receivers,
        address token,
        uint256[] memory amounts
    ) external;

    function distributeTokenAndAmount(
        address[] memory receivers,
        address token,
        uint256 amount
    ) external;

    function distributeEth(
        address[] memory receivers,
        uint256[] memory amounts
    ) external;

    function distributeEthAndAmount(
        address[] memory receivers,
        uint256 amount
    ) external;

    function getState(
        address[] memory tokens
    ) external view returns (DistributorServiceState memory state);
}


// File contracts/DistributorService.sol

contract DistributorService is Ownable, IDistributorService {

    event DistributorStateUpdate(address indexed caller, address indexed distributor, bool whitelisted);
    event Distribute(address indexed caller, address indexed receiver, address indexed token, uint256 amount);

    mapping (address => bool) public distributorExists;
    mapping (address => bool) public allowedDistributors;

    address[] public distributorsList;

    constructor(address _owner, address[] memory distributors) {
        require(
            _owner != address(0),
            "DistributorService:: Owner address is 0x0!"
        );
        for (uint256 i = 0; i < distributors.length; i++) {
            _setDistributorState(distributors[i], true);
        }
        _transferOwnership(_owner);
    }

    modifier isWhitelisted() {
        require(
            allowedDistributors[msg.sender],
            "DistributorService:: Caller not whitelisted!"
        );
        _;
    }

    function updateDistributors(
        address[] memory distributors,
        bool[] memory whitelisted
    ) external onlyOwner {
        require(
            distributors.length == whitelisted.length,
            "DistributorService:: Distributors list and the whitelisted list sizes differ!"
        );
        for (uint256 i = 0; i < distributors.length; i++) {
            _setDistributorState(distributors[i], whitelisted[i]);
        }
    }

    function distribute(
        address[] memory receivers,
        address[] memory tokens,
        uint256[] memory amounts
    ) external override isWhitelisted {
        require(
            receivers.length == tokens.length &&
            tokens.length == amounts.length,
            "DistributorService:: (Receivers[], Tokens[], Amounts[]) list sizes are different!"
        );
        for (uint256 i = 0; i < receivers.length; i++) {
            uint256 amount = amounts[i];
            address token = tokens[i];
            if (amount > 0) {
                if (token == address(0)) {
                    _sendETH(receivers[i], amount);
                } else {
                    _sendToken(token, receivers[i], amount);
                }
            }
        }
    }

    function distributeToken(
        address[] memory receivers,
        address token,
        uint256[] memory amounts
    ) external override isWhitelisted {
        require(
            receivers.length == amounts.length,
            "DistributorService:: (Receivers[], Amounts[]) list sizes are different!"
        );
        for (uint256 i = 0; i < receivers.length; i++) {
            uint256 amount = amounts[i];
            if (amount > 0) {
                _sendToken(token, receivers[i], amount);
            }
        }
    }

    function distributeTokenAndAmount(
        address[] memory receivers,
        address token,
        uint256 amount
    ) external override isWhitelisted {
        for (uint256 i = 0; i < receivers.length; i++) {
            if (amount > 0) {
                _sendToken(token, receivers[i], amount);
            }
        }
    }

    function distributeEth(
        address[] memory receivers,
        uint256[] memory amounts
    ) external override isWhitelisted {
        require(
            receivers.length == amounts.length,
            "DistributorService:: (Receivers[], Amounts[]) list sizes are different!"
        );
        for (uint256 i = 0; i < receivers.length; i++) {
            uint256 amount = amounts[i];
            if (amount > 0) {
                _sendETH(receivers[i], amount);
            }
        }
    }

    function getState(
        address[] memory tokens
    ) external view override returns (DistributorServiceState memory) {
        uint256[] memory balances = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            balances[i] = IERC20(tokens[i]).balanceOf(address(this));
        }
        bool[] memory distributorsActiveStatus = new bool[](distributorsList.length);
        uint256[] memory distributorsEthBalances = new uint256[](distributorsList.length);
        for (uint256 i = 0; i < distributorsList.length; i++) {
            distributorsActiveStatus[i] = allowedDistributors[distributorsList[i]];
            distributorsEthBalances[i] = distributorsList[i].balance;
        }
        return DistributorServiceState(
            address(this).balance,
            distributorsList,
            distributorsEthBalances,
            distributorsActiveStatus,
            tokens,
            balances
        );
    }

    function distributeEthAndAmount(
        address[] memory receivers,
        uint256 amount
    ) external override isWhitelisted {
        for (uint256 i = 0; i < receivers.length; i++) {
            if (amount > 0) {
                _sendETH(receivers[i], amount);
            }
        }
    }
    
    function pullETH(uint256 amount) external onlyOwner {
        _sendETH(msg.sender, amount);
    }
    
    function pullToken(address token, uint256 amount) external onlyOwner {
        _sendToken(token, msg.sender, amount);
    }

    receive() external payable {}
    fallback() external payable {}

    function getDistributors() external view returns (address[] memory) {
        return distributorsList;
    }

    function _sendETH(address _to, uint256 _amount) private {
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "DistributorService:: failed to send Ether. Check contract balance.");
        emit Distribute(msg.sender, _to, address(0), _amount);
    }

    function _sendToken(address _token, address _to, uint256 _amount) private {
        IERC20(_token).transfer(_to, _amount);
        emit Distribute(msg.sender, _to, _token, _amount);
    }

    function _setDistributorState(address _distributor, bool _whitelisted) private {
        if (!distributorExists[_distributor]) {
            distributorExists[_distributor] = true;
            distributorsList.push(_distributor);
        }
        allowedDistributors[_distributor] = _whitelisted;
        emit DistributorStateUpdate(msg.sender, _distributor, _whitelisted);
    }

}