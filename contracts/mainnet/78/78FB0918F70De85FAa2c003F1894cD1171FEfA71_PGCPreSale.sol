// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./interface/IContractMetadata.sol";

/**
 *  @title   Contract Metadata
 *  @notice  Thirdweb's `ContractMetadata` is a contract extension for any base contracts. It lets you set a metadata URI
 *           for you contract.
 *           Additionally, `ContractMetadata` is necessary for NFT contracts that want royalties to get distributed on OpenSea.
 */

abstract contract ContractMetadata is IContractMetadata {
    /// @notice Returns the contract metadata URI.
    string public override contractURI;

    /**
     *  @notice         Lets a contract admin set the URI for contract-level metadata.
     *  @dev            Caller should be authorized to setup contractURI, e.g. contract admin.
     *                  See {_canSetContractURI}.
     *                  Emits {ContractURIUpdated Event}.
     *
     *  @param _uri     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     */
    function setContractURI(string memory _uri) external override {
        if (!_canSetContractURI()) {
            revert("Not authorized");
        }

        _setupContractURI(_uri);
    }

    /// @dev Lets a contract admin set the URI for contract-level metadata.
    function _setupContractURI(string memory _uri) internal {
        string memory prevURI = contractURI;
        contractURI = _uri;

        emit ContractURIUpdated(prevURI, _uri);
    }

    /// @dev Returns whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal view virtual returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

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

/**
 *  Thirdweb's `ContractMetadata` is a contract extension for any base contracts. It lets you set a metadata URI
 *  for you contract.
 *
 *  Additionally, `ContractMetadata` is necessary for NFT contracts that want royalties to get distributed on OpenSea.
 */

interface IContractMetadata {
    /// @dev Returns the metadata URI of the contract.
    function contractURI() external view returns (string memory);

    /**
     *  @dev Sets contract URI for the storefront-level metadata of the contract.
     *       Only module admin can call this function.
     */
    function setContractURI(string calldata _uri) external;

    /// @dev Emitted when the contract URI is updated.
    event ContractURIUpdated(string prevURI, string newURI);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@thirdweb-dev/contracts/extension/ContractMetadata.sol";
import "@thirdweb-dev/contracts/extension/Ownable.sol";

contract PGCPreSale is Ownable, Pausable, ContractMetadata, ReentrancyGuard {
    using Counters for Counters.Counter;

    Counters.Counter private _refCount;
    Counters.Counter private _payCount;

    address payable public admin;
    address public deployer;
    address payable public recipient;

    IERC20 public PGC;
    IERC20 public token;

    uint256 public tokenPrice;
    uint8 public tokenDecimals;

    uint256 public share;

    struct Payments {
        address payer;
        uint256 amount;
        uint256 date;
        string paymentType;
        address token;
        uint256 paymentAmount;
        bool payed;
        address ref;
    }

    mapping(address => uint256) private commissions;
    address[] private referrers;

    mapping(string => Payments) private PaymentsList;
    string[] private payments;

    event Sold(address to, uint256 amount);

    constructor(
        address _pgc,
        address _token,
        uint256 _tokenPrice,
        uint8 _tokenDecimals
    ) payable {
        _setupOwner(msg.sender);
        admin = payable(msg.sender);
        deployer = msg.sender;

        recipient = payable(address(0x0F9c6cf1D587973c125237D8F97Fe9523e5fF19E));

        share = 500; // Share inicial de 5%

        PGC = IERC20(_pgc);
        token = IERC20(_token);
        tokenPrice = _tokenPrice;
        tokenDecimals = _tokenDecimals;
    }

    function setRecipient(address _recipient)  public onlyOwner {
        recipient = payable(_recipient);
    }

    function setShare(uint256 _share) public onlyOwner {
        share = _share;
    }

    function setCommissions(address _ref, uint256 _saldo) public onlyOwner {
        if (commissions[_ref] == 0) {
            _refCount.increment();
            referrers.push(_ref);
        }
        commissions[_ref] = _saldo;
    }

    function addCommission(address _ref, uint256 _amount) internal {
        if (commissions[_ref] == 0) {
            _refCount.increment();
            referrers.push(_ref);
        }
        commissions[_ref] += (_amount * share) / 10000;
    }

    function addPyment(
        string memory _paymentId,
        address _buyer,
        uint256 _amount,
        string memory _paymentType,
        address _tokenAddress,
        uint256 _tokenAmount,
        bool _paid,
        address _ref
    ) internal {
        PaymentsList[_paymentId] = Payments(
            _buyer,
            _amount,
            block.timestamp,
            _paymentType,
            _tokenAddress,
            _tokenAmount,
            _paid,
            _ref
        );

        payments.push(_paymentId);

        _payCount.increment();
    }

    function setToken(address _tokenAddress) public onlyOwner {
        token = IERC20(_tokenAddress);
    }

    function setPGC(address _pgc) public onlyOwner {
        PGC = IERC20(_pgc);
    }

    function setTokenPrice(uint256 _tokenPrice) public onlyOwner {
        tokenPrice = _tokenPrice;
    }

    function setTokenDecimals(uint8 _tokendecimals) public onlyOwner {
        tokenDecimals = _tokendecimals;
    }

    function pgcBalance() public view onlyOwner returns (uint256 _balance) {
        return PGC.balanceOf(address(this));
    }

    function getPayments() public view onlyOwner returns (string[] memory) {
        return payments;
    }

    function getPayment(string memory _paymentId)
        public
        view
        onlyOwner
        returns (Payments memory)
    {
        return PaymentsList[_paymentId];
    }

    function getReferrers() public view onlyOwner returns (address[] memory) {
        return referrers;
    }

    function getCommission(address _referrer)
        public
        view
        onlyOwner
        returns (uint256)
    {
        return commissions[_referrer];
    }

    function buyToken(uint256 _amount, string memory _paymentId)
        external
        payable
        whenNotPaused
        nonReentrant
    {
        uint256 _tokenAmount = (_amount * tokenPrice) / 10**tokenDecimals / (10** (18 - tokenDecimals));
        uint256 allowance = token.allowance(msg.sender, address(this));

        require(
            PGC.balanceOf(address(this)) >= _amount,
            "Saldo no Contrato insuficiente!"
        );

        require(_amount > 0, "Quantidade precisa ser maior que zero");
        require(allowance >= _tokenAmount, "O contrato precisa ser aprovado");

        token.transferFrom(msg.sender, recipient, _tokenAmount);
        PGC.transfer(msg.sender, _amount);

        addPyment(
            _paymentId,
            msg.sender,
            _amount,
            "crypto",
            address(token),
            _tokenAmount,
            true,
            address(0)
        );

        emit Sold(msg.sender, _amount);
    }

    function buyToken(
        uint256 _amount,
        string memory _paymentId,
        address _ref
    ) external payable whenNotPaused nonReentrant {
        uint256 _tokenAmount = (_amount * tokenPrice) / 10**tokenDecimals / (10** (18 - tokenDecimals));
        uint256 allowance = token.allowance(msg.sender, address(this));

        require(
            PGC.balanceOf(address(this)) >= _amount,
            "Saldo no Contrato insuficiente!"
        );
        require(
            token.balanceOf(msg.sender) >= _tokenAmount,
            "Saldo na sua carteira insuficiente!"
        );
        require(_amount > 0, "Quantidade precisa ser maior que zero");
        require(allowance >= _tokenAmount, "O contrato precisa ser aprovado");

        token.transferFrom(msg.sender, address(recipient), _tokenAmount);
        PGC.transfer(msg.sender, _amount);

        addCommission(_ref, _amount);

        addPyment(
            _paymentId,
            msg.sender,
            _amount,
            "crypto",
            address(token),
            _tokenAmount,
            true,
            _ref
        );

        emit Sold(msg.sender, _amount);
    }

    function sellToken(
        address payable _to,
        uint256 _amount,
        string memory _paymentId,
        uint256 _value
    ) external payable whenNotPaused onlyOwner nonReentrant {
        require(
            PGC.balanceOf(address(this)) >= _amount,
            "Saldo no Contrato insuficiente!"
        );
        require(_amount > 0, "Quantidade precisa ser maior que zero");

        PGC.transfer(payable(_to), _amount);

        addPyment(
            _paymentId,
            _to,
            _amount,
            "fiat",
            address(0),
            _value,
            true,
            address(0)
        );

        emit Sold(msg.sender, _amount);
    }

    function sellToken(
        address payable _to,
        uint256 _amount,
        string memory _paymentId,
        uint256 _value,
        address _ref
    ) external payable whenNotPaused onlyOwner nonReentrant {
        require(
            PGC.balanceOf(address(this)) >= _amount,
            "Saldo no Contrato insuficiente!"
        );
        require(_amount > 0, "Quantidade precisa ser maior que zero");

        PGC.transfer(payable(_to), _amount);

        addCommission(_ref, _amount);

        addPyment(
            _paymentId,
            _to,
            _amount,
            "fiat",
            address(0),
            _value,
            true,
            _ref
        );

        emit Sold(msg.sender, _amount);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function withdrawToken(address _token, uint256 _amount) external onlyOwner {
        IERC20 tokenContract = IERC20(_token);
        tokenContract.approve(address(this), _amount);
        tokenContract.transfer(payable(admin), _amount);
    }

    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;

        (bool success, ) = admin.call{value: amount}("");
        require(success, "Failed to send Matic");
    }

    function _canSetContractURI()
        internal
        view
        virtual
        override
        returns (bool)
    {
        return msg.sender == deployer;
    }

    function _canSetOwner() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }
}