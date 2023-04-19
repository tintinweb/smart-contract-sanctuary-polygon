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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

contract Invest is Ownable, ReentrancyGuard {
    struct Project {
        string key;
        bool closed;
        uint256 investment;
        uint256 limit;
        uint256 tokens;
        uint256 price;
        uint256 decimals;
        address owner;
        address beneficiary;
        uint256 receivable;
        uint256 lastIndex;
        address releaseToken;
        address[] investors;
        string[] funds;
    }

    struct ProjectInvestor {
        uint256 investment;
        uint256 tokens;
        uint256 receivable;
    }

    struct Fund {
        string key;
        address owner;
        string[] projects;
        uint256 weight;
        bool closed;
    }

    mapping(address => bool) private _signers;
    mapping(string => mapping(address => ProjectInvestor)) public investments;
    mapping(string => Project) public projects;
    mapping(string => Fund) public funds;
    mapping(string => mapping(string => uint256)) public weights;

    address public payableToken;

    modifier onlyOwnerOrSigner() {
        require(owner() == _msgSender() || _signers[_msgSender()] == true, "InvestSplitter: caller must be owner or signer");
        _;
    }

    modifier onlyProjectOwner(string memory _key) {
        require(projects[_key].owner != address(0), "Project not exists");
        require(
            owner() == _msgSender() ||
            _signers[_msgSender()] ||
            projects[_key].owner == _msgSender(),
            "Caller does not have enough rights"
        );
        _;
    }

    modifier onlyFundOwner(string memory _key) {
        require(funds[_key].owner != address(0), "Fund not exists");
        require(
            owner() == _msgSender() ||
            _signers[_msgSender()] ||
            funds[_key].owner == _msgSender(),
            "Caller does not have enough rights"
        );
        _;
    }

    function setSigner(address signer, bool isSigner) public onlyOwner {
        require(signer != address(0), "Signer is the zero address");
        _signers[signer] = isSigner;
    }

    function getInvestors(string memory _key, uint256 startIndex, uint256 endIndex) public view onlyProjectOwner(_key) returns(address[] memory, uint256[] memory) {
        address[] memory investorAddresses = projects[_key].investors;
        
        if (startIndex == 0 && endIndex == 0) {
            endIndex = investorAddresses.length;
        } else {
            require(startIndex < endIndex, "Invalid start and end indexes");
            require(endIndex <= investorAddresses.length, "End index is greater than investor list length");
        }
        
        uint256 range = endIndex - startIndex;
        uint256[] memory investorTokens = new uint256[](range);
        address[] memory rangeInvestorAddresses = new address[](range);
    
        for (uint i = startIndex; i < endIndex; i++) {
            rangeInvestorAddresses[i - startIndex] = investorAddresses[i];
            investorTokens[i - startIndex] = investments[_key][investorAddresses[i]].tokens;
        }
        
        return (rangeInvestorAddresses, investorTokens);
    }

    function generateInvestorListHash(
        string memory projectKey,
        uint256 startIndex,
        uint256 endIndex,
        bytes32 prevAddressHash,
        bytes32 prevTokenHash
    ) public view returns (bytes32, bytes32) {
        (address[] memory investors, uint256[] memory amounts) = getInvestors(projectKey, startIndex, endIndex);
        require(investors.length > 0, "Investor list must not be empty");

        if (startIndex == 0 && endIndex == 0) {
            endIndex = investors.length;
        } else {
            require(startIndex < endIndex, "Invalid start and end indexes");
            require(endIndex <= investors.length, "End index is greater than investor list length");
        }

        bytes32 currentAddressHash = prevAddressHash == bytes32(0) ? bytes32(uint256(uint160(investors[startIndex]))) : prevAddressHash;
        bytes32 currentTokenHash = prevTokenHash == bytes32(0) ? bytes32(amounts[startIndex]) : prevTokenHash;

        for (uint256 i = startIndex; i < endIndex; i++) {
            bytes32 nextAddressHash = keccak256(abi.encodePacked(investors[i]));
            bytes32 nextTokenHash = keccak256(abi.encodePacked(amounts[i]));

            currentAddressHash = keccak256(abi.encodePacked(currentAddressHash, nextAddressHash));
            currentTokenHash = keccak256(abi.encodePacked(currentTokenHash, nextTokenHash));
        }

        return (currentAddressHash, currentTokenHash);
    }

    function getFundData(string memory _key) public view returns (
        address owner,
        string[] memory projectKeys,
        uint256[] memory projectWeights,
        uint256 weight,
        bool closed
    ) {
        Fund memory fund = funds[_key];
        require(fund.owner != address(0), "Fund not exists");
    
        projectKeys = new string[](fund.projects.length);
        projectWeights = new uint256[](fund.projects.length);
        uint256 totalWeight;
    
        for (uint i = 0; i < fund.projects.length; i++) {
            string memory projectKey = fund.projects[i];
            projectKeys[i] = projectKey;
            projectWeights[i] = weights[_key][projectKey];
            totalWeight += projectWeights[i];
        }
    
        return (fund.owner, projectKeys, projectWeights, totalWeight, fund.closed);
    }

    function setCurrencyToken(address _token) public onlyOwner {
        payableToken = _token;
    }

    function setProjectBeneficiary(string memory _key, address _beneficiary) public onlyOwner {
        projects[_key].beneficiary = _beneficiary;
    }

    function setProjectPrice(string memory _key, uint256 _price, uint256 _decimals) public onlyProjectOwner(_key) {
        projects[_key].price = _price;
        projects[_key].decimals = _decimals;
    }

    function setProjectToken(string memory _key, address _token) public onlyProjectOwner(_key) {
        require(_token != address(0), "Token address cannot be zero address");
        projects[_key].releaseToken = _token;
    }

    function setProjectLimit(string memory _key, uint256 _limit) public onlyProjectOwner(_key) {
        require(projects[_key].owner != address(0), "Project not exist");
        require(!projects[_key].closed, "Project is closed for investments");
    
        projects[_key].limit = _limit;
    }

    function createProject(string memory _key, uint256 _price, uint256 _decimals, uint256 _limit) public {
        require(projects[_key].owner == address(0), "Project with this key already exists");

        address[] memory investors;
        string[] memory projectFunds;

        Project memory newProject = Project({
            key: _key,
            closed: false,
            investment: 0,
            limit: _limit,
            tokens: 0,
            receivable: 0,
            lastIndex: 0,
            price: _price,
            decimals: _decimals,
            owner: _msgSender(),
            beneficiary: _msgSender(),
            releaseToken: address(0),
            investors: investors,
            funds: projectFunds
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
            weight: 0,
            closed: false
        });

        funds[_key] = newFund;
    }

    function addFundProject(string memory _key, string memory _projectKey, uint256 _weight) public onlyFundOwner(_key) {
        require(projects[_projectKey].owner != address(0), "Project not exist");
        require(!projects[_projectKey].closed, "Project is already closed for investments");
        require(weights[_key][_projectKey] == 0, "The project is already included in the fund");
        require(_weight > 0, "Weight required");

        funds[_key].projects.push(_projectKey);
        funds[_key].weight += _weight;

        projects[_projectKey].funds.push(_key);

        weights[_key][_projectKey] = _weight;
    }

    function removeElementFromArray(string[] storage array, string memory value) internal {
        for (uint i = 0; i < array.length; i++) {
            if (keccak256(bytes(array[i])) == keccak256(bytes(value))) {
                array[i] = array[array.length - 1];
                array.pop();
                break;
            }
        }
    }

    function removeFundProject(string memory _key, string memory _projectKey) public onlyFundOwner(_key) {
        removeElementFromArray(funds[_key].projects, _projectKey);
        removeElementFromArray(projects[_projectKey].funds, _key);

        funds[_key].weight -= weights[_key][_projectKey];

        weights[_key][_projectKey] = 0;
    }

    function setFundProjectWeight(string memory _key, string memory _projectKey, uint256 _weight) public onlyFundOwner(_key) {
        require(!projects[_projectKey].closed, "Project is already closed for investments");
        require(!funds[_key].closed, "Fund is closed");

        funds[_key].weight = funds[_key].weight - weights[_key][_projectKey] + _weight;
        weights[_key][_projectKey] = _weight;
    }

    function invest(address _user, string memory _key, uint256 _amount) internal {
        require(IERC20(payableToken).transferFrom(_user, projects[_key].beneficiary, _amount));
        require(projects[_key].investment < projects[_key].limit, "Investment limit reached");
    
        uint256 remainingInvestment = projects[_key].limit - projects[_key].investment;
        uint256 investment = _amount;
    
        if (investment > remainingInvestment) {
            investment = remainingInvestment;
        }

        uint256 tokens = investment / projects[_key].price * 10 ** projects[_key].decimals;

        projects[_key].investment += investment;
        projects[_key].tokens += tokens;
        projects[_key].receivable += tokens;

        if (investments[_key][_user].investment == 0) {
            projects[_key].investors.push(_user);
        }

        investments[_key][_user].investment += investment;
        investments[_key][_user].tokens += tokens;
        investments[_key][_user].receivable += tokens;
    }

    function investProject(address _user, string memory _key, uint256 _amount) public nonReentrant {
        require(projects[_key].owner != address(0), "Project does not exist");
        require(!projects[_key].closed, "Project is closed for investments");

        invest(_user, _key, _amount);
    }

    function investFund(address _user, string memory _key, uint256 _amount) public nonReentrant {
        require(funds[_key].owner != address(0), "Fund does not exist");
        require(funds[_key].projects.length > 0, "No projects inside the fund");
        require(!funds[_key].closed, "Fund is closed");

        for (uint i = 0; i < funds[_key].projects.length; i++) {
            string memory projectKey = funds[_key].projects[i];

            if (projects[projectKey].investment >= projects[projectKey].limit) {
                continue;
            }

            uint256 share = weights[_key][projectKey] * 100 / funds[_key].weight;
            uint256 amount = _amount / 100 * share;

            invest(_user, projectKey, amount);
        }
    }

    function investWithPermit(bool isFund, address _user, string memory _key, uint256 _amount, uint8 v, bytes32 r, bytes32 s, uint256 _expiry) public {
        IERC20Permit(payableToken).permit(_user, address(this), _amount, _expiry,  v, r, s);

        (isFund ? investFund : investProject)(_user, _key, _amount);
    }

    function closeProject(string memory _key) public onlyProjectOwner(_key) {
        require(!projects[_key].closed, "Project is closed for investment");

        projects[_key].closed = true;

        for (uint i = 0; i < projects[_key].funds.length; i++) {
            string memory fundKey = projects[_key].funds[i];

            funds[fundKey].weight -= weights[fundKey][_key];
            weights[fundKey][_key] = 0;
        }
    }

    function closeFund(string memory _key) public onlyFundOwner(_key) {
        require(!funds[_key].closed, "Fund is closed");

        funds[_key].closed = true;
    }

    function sendReleasableTokens(string memory _key, address _investor, address _token, uint256 _amount) internal {
        require(
            IERC20(_token).transferFrom(
                _msgSender(), _investor, _amount
            )
        );

        investments[_key][_investor].receivable -= _amount;
        projects[_key].receivable -= _amount;
    }

    function releaseToken(string memory _key, uint256 _amount) public nonReentrant {
        require(projects[_key].closed, "Investment must be closed");

        address token = projects[_key].releaseToken;

        require(token != address(0), "Release token is not set");

        uint256 remainAmount = _amount;

        for (uint i = projects[_key].lastIndex; i < projects[_key].investors.length; i++) {
            address investor = projects[_key].investors[i];

            if (investments[_key][investor].receivable > remainAmount) {
                sendReleasableTokens(_key, investor, token, remainAmount);
                break;
            }
            
            if (investments[_key][investor].receivable <= remainAmount) {
                remainAmount -= investments[_key][investor].receivable;
                projects[_key].lastIndex += 1;

                sendReleasableTokens(_key, investor, token, investments[_key][investor].receivable);               
            }
        }
    }
}