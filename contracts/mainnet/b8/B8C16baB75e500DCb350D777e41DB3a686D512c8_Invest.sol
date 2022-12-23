// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

contract Invest is ERC2771Context, Ownable, ReentrancyGuard {
    struct Project {
        string key; /* Unique Project Key */
        uint256 investment; /* Total Invested Amount */
        uint256 tokens; /* Amount Of Sold Tokens */
        uint256 price; /* Price Per 1 Token */
        uint256 decimals; /* Effectively Shifting All Numbers By The Declared Number Of Zeros To Simulate Decimals */
        address owner; /* Project Owner */
        address destination; /* Destination For Investments */
        address releasableToken; /* Releasable Token */
    }

    struct ProjectInvestor {
        uint256 investment; /* Total Invested Amount */
        uint256 tokens; /* Total Amount of Bought Tokens */
        uint256 shortage; /* Amount of Bought Tokens That Project Owes To This Investor */
    }

    struct ProjectArrears {
        uint256 amount; /* Total Amount of Bought Tokens That Project Owes To All Investors */
        address[] investors; /* Investors Who Are Waiting For Tokens */
    }

    struct Fund {
        string key; /* Unique Fund Key */
        address owner; /* Fund Owner */
        string[] projects; /* Array Of Projects */
        uint256 weight; /* Total Fund Weight */
    }

    /* Investments Mapping: Project Key => Investor Wallet => Project Investor Struct */
    mapping(string => mapping(address => ProjectInvestor)) public investments;
    /* Projects Mapping: Project Key => Project Data Struct */
    mapping(string => Project) public projects;
    /* Arrears Mapping: Project Key => Arrears Data Struct */
    mapping(string => ProjectArrears) public arrears;
    /* Fund Mapping: Fund Key => Fund Data Struct */
    mapping(string => Fund) public funds;
    /* Weights Mapping: Fund Key => Project Key => Weight */
    mapping(string => mapping(string => uint256)) public weights;

    /* Payable Token - Stable Coin (USDT, USDC, DAI) */
    IERC20 public payableToken;

    constructor (address _trustedForwarder) ERC2771Context(_trustedForwarder) {}

    function _msgSender() internal view virtual override(Context, ERC2771Context) returns (address) {
        return ERC2771Context._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC2771Context) returns(bytes calldata) {
        return ERC2771Context._msgData();
    }

    function getFundProjects(string memory _key) public view returns(string[] memory) {
        return funds[_key].projects;
    }

    function getArrearsList(string memory _key) public view returns(address[] memory) {
        return arrears[_key].investors;
    }

    function setPayableTooken(IERC20 _token) public onlyOwner {
        payableToken = _token;
    }

    function setProjectDestination(string memory _key, address _destination) public onlyOwner {
        projects[_key].destination = _destination;
    }

    function createProject(string memory _key, uint256 _price, uint256 _decimals) public {
        require(projects[_key].owner == address(0), "Project with this key already exists");

        Project memory newProject = Project({
            key: _key,
            investment: 0,
            tokens: 0,
            price: _price,
            decimals: _decimals,
            owner: _msgSender(),
            destination: _msgSender(),
            releasableToken: address(0)
        });

        projects[_key] = newProject;
    }

    function createFund(string memory _key) public {
        require(funds[_key].owner == address(0), "Fund with this key already exists");

        string[] memory fundProjects;

        Fund memory newFund = Fund({
            key: _key,
            owner: _msgSender(),
            projects: fundProjects,
            weight: 0
        });

        funds[_key] = newFund;
    }

    function setReleasableToken(string memory _key, address _token) public {
        require(projects[_key].owner == _msgSender(), "Only the project owner can set releasable token");
        require(projects[_key].tokens == arrears[_key].amount, "Current token is already released");

        projects[_key].releasableToken = _token;
    }

    function addProjectToFund(string memory _key, string memory _projectKey, uint256 _weight) public {
        require(funds[_key].owner == _msgSender(), "Only the fund owner can add a project to fund");
        require(projects[_projectKey].owner != address(0), "Project not exist");
        require(weights[_key][_projectKey] == 0, "The project is already included in the fund");
        require(_weight > 0, "Weight required");

        funds[_key].projects.push(_projectKey);
        funds[_key].weight += _weight;

        weights[_key][_projectKey] = _weight;
    }

    function removeProjectFromFund(string memory _key, string memory _projectKey) public {
        require(funds[_key].owner == _msgSender(), "Only the fund owner can add a project to fund");
        require(weights[_key][_projectKey] > 0, "The project is not included in the fund");

        uint256 projectsLength = funds[_key].projects.length;

        for (uint i = 0; i < funds[_key].projects.length; i++) {
            if (keccak256(bytes(funds[_key].projects[i])) == keccak256(bytes(_projectKey))) {
                funds[_key].projects[i] = funds[_key].projects[projectsLength - 1];
                funds[_key].projects.pop();
                break;
            }
        }

        funds[_key].weight -= weights[_key][_projectKey];

        weights[_key][_projectKey] = 0;
    }

    function invest(string memory _key, uint256 _amount) internal {
        IERC20 tkn = IERC20(payableToken);
        require(tkn.transferFrom(_msgSender(), projects[_key].destination, _amount));

        uint256 tokens = _amount * projects[_key].price / (10 ** projects[_key].decimals);

        projects[_key].investment += _amount;
        projects[_key].tokens += tokens;

        arrears[_key].amount += tokens;

        investments[_key][_msgSender()].investment += _amount;
        investments[_key][_msgSender()].tokens += tokens;

        if (investments[_key][_msgSender()].shortage == 0) {
            arrears[_key].investors.push(_msgSender());
        }

        investments[_key][_msgSender()].shortage += tokens;
    }

    function investProject(string memory _key, uint256 _amount) public nonReentrant {
        require(projects[_key].owner != address(0), "Project not exist");

        invest(_key, _amount);
    }

    function investFund(string memory _key, uint256 _amount) public nonReentrant {
        require(
            IERC20(payableToken).allowance(_msgSender(), address(this)) >= _amount,
            "Not enough tokens"
        );

        for (uint i = 0; i < funds[_key].projects.length; i++) {
            string memory projectKey = funds[_key].projects[i];
            uint256 share = weights[_key][projectKey] * 100 / funds[_key].weight;
            uint256 amount = _amount / 100 * share;

            invest(projectKey, amount);
        }
    }

    function releaseToken(string memory _key) public nonReentrant {
        require(projects[_key].releasableToken != address(0), "Releasable token is required");
        require(
            IERC20(projects[_key].releasableToken).allowance(_msgSender(), address(this)) >= arrears[_key].amount,
            "Not enough tokens"
        );

        for (uint i = 0; i < arrears[_key].investors.length; i++) {
            address investor = arrears[_key].investors[i];
    
            require(
                IERC20(projects[_key].releasableToken).transferFrom(
                    _msgSender(), investor, investments[_key][investor].shortage
                )
            );

            investments[_key][investor].shortage = 0;
        }

        address[] memory investors;

        arrears[_key].amount = 0;
        arrears[_key].investors = investors;
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
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
            /// @solidity memory-safe-assembly
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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