// SPDX-License-Identifier: AGPL-3.0 License
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/ICliptoToken.sol";
import "./CliptoExchangeStorage.sol";

contract CliptoExchange is CliptoExchangeStorage, Initializable, ReentrancyGuardUpgradeable {
    uint256 private _feeNumer;
    uint256 private _feeDenom;

    modifier onlyOwner() {
        require(owner == msg.sender, "not the owner");
        _;
    }

    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);
    event CreatorRegistered(address indexed creator, address indexed nft);
    event CreatorUpdated(address indexed creator, string metadataURI);
    event NewRequest(address indexed creator, uint256 requestId);
    event RequestUpdated(address indexed creator, uint256 updatedAmount);
    event DeliveredRequest(address indexed creator, uint256 requestId, uint256 nftTokenId);
    event RefundedRequest(address indexed creator, uint256 requestId);
    event Payment(address to, address erc20, uint256 amount);
    event MigrationCreator(address[] creators);
    event MigrationRequest(address[] creators, uint256[] requestIds);

    function initialize(address _owner, address _cliptoToken) public initializer {
        __ReentrancyGuard_init();

        owner = _owner;
        _feeDenom = 1;
        CLIPTO_TOKEN_ADDRESS = _cliptoToken;
    }

    function getRequest(address _creator, uint256 _requestId) public view returns (Request memory) {
        return requests[_creator][_requestId];
    }

    function getCreator(address _creator) public view returns (Creator memory) {
        return creators[_creator];
    }

    function getFeeRate() public view returns (uint256, uint256) {
        return (_feeNumer, _feeDenom);
    }

    function updateCliptoTokenImplementation(address _newImplementation) public onlyOwner {
        require(_newImplementation != address(0), "not a valid implementation");
        CLIPTO_TOKEN_ADDRESS = _newImplementation;
    }

    function setFeeRate(uint256 feeNumer_, uint256 feeDenom_) public onlyOwner {
        require(feeDenom_ != 0, "error: denom should be non zero");
        require(feeDenom_ >= feeNumer_, "error: donom should be greater than numer");
        _feeNumer = feeNumer_;
        _feeDenom = feeDenom_;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function registerCreator(string calldata _creatorName, string calldata _metadataURI) external {
        require(!_existsCreator(msg.sender), "error: creator already registered");
        _registerCreator(msg.sender, _creatorName, _metadataURI);
    }

    function updateCreator(string calldata _metadataURI) external {
        require(_existsCreator(msg.sender), "error: creator is not yet registered");
        _updateCreator(msg.sender, _metadataURI);
    }

    function newRequest(
        address _creator,
        address _erc20,
        uint256 _amount,
        string calldata _metadataURI
    ) external {
        _validateRequest(_creator, _amount);
        _checkAllowance(_erc20, msg.sender, _amount);
        _pay(msg.sender, address(this), _erc20, _amount);
        _newRequest(_creator, msg.sender, _erc20, _amount, _metadataURI);
    }

    function newRequestFor(
        address _creator,
        address _requester,
        address _erc20,
        uint256 _amount,
        string calldata _metadataURI
    ) external {
        _validateRequest(_creator, _amount);
        _checkAllowance(_erc20, msg.sender, _amount);
        _pay(msg.sender, address(this), _erc20, _amount);
        _newRequest(_creator, _requester, _erc20, _amount, _metadataURI);
    }

    function nativeNewRequest(address _creator, string calldata _metadataURI) external payable {
        _validateRequest(_creator, msg.value);
        _newRequest(_creator, msg.sender, address(0), msg.value, _metadataURI);
    }

    function nativeNewRequestFor(
        address _creator,
        address _requester,
        string calldata _metadataURI
    ) external payable {
        _newRequest(_creator, _requester, address(0), msg.value, _metadataURI);
    }

    function deliverRequest(uint256 _requestId, string calldata _tokenURI) external nonReentrant {
        Request storage request = requests[msg.sender][_requestId];
        require(!request.fulfilled, "error: request already fulfilled/refunded");

        uint256 feeAmount = (request.amount * _feeNumer) / _feeDenom;
        _transferPayment(owner, request.erc20, feeAmount);

        uint256 paymentAmount = request.amount - feeAmount;
        _transferPayment(msg.sender, request.erc20, paymentAmount);

        address nft = creators[msg.sender].nft;
        uint256 nftTokenId = ICliptoToken(nft).totalSupply();
        ICliptoToken(nft).safeMint(request.requester, _tokenURI);

        request.fulfilled = true;
        emit DeliveredRequest(msg.sender, _requestId, nftTokenId + 1);
    }

    function refundRequest(address _creator, uint256 _requestId) external nonReentrant {
        Request storage request = requests[_creator][_requestId];
        require(request.requester == msg.sender, "error: only requester can make a refund");
        require(!request.fulfilled, "error: request already fulfilled/refunded");

        _transferPayment(msg.sender, request.erc20, request.amount);
        request.fulfilled = true;

        emit RefundedRequest(_creator, _requestId);
    }

    function migrateCreator(
        address[] calldata _creatorAddress,
        string[] calldata _creatorNames,
        string[] calldata _metadataURIs
    ) public onlyOwner {
        require(_creatorAddress.length > 0, "error: empty creator address");

        uint256 i;
        for (i = 0; i < _creatorAddress.length; i++) {
            address nft = _deployCliptoFor(_creatorNames[i]);
            creators[_creatorAddress[i]] = Creator(nft, _metadataURIs[i]);
        }

        emit MigrationCreator(_creatorAddress);
    }

    function migrateRequest(
        address[] calldata _creatorAddress,
        address[] calldata _requesterAddress,
        uint256[] calldata _amount,
        bool[] calldata _fulfilled,
        string[] calldata _metadataURIs
    ) public onlyOwner {
        require(_creatorAddress.length > 0, "error: empty creator address");

        uint256[] memory requestIds = new uint256[](_creatorAddress.length);
        uint256 i;

        for (i = 0; i < _creatorAddress.length; i++) {
            requests[_creatorAddress[i]].push(
                Request(_requesterAddress[i], address(0), _amount[i], _fulfilled[i], _metadataURIs[i])
            );
            requestIds[i] = requests[_creatorAddress[i]].length - 1;
        }

        emit MigrationRequest(_creatorAddress, requestIds);
    }

    function _transferPayment(
        address _to,
        address _erc20,
        uint256 _amount
    ) internal {
        if (_erc20 == address(0)) _pay(_to, _amount);
        else _pay(address(this), _to, _erc20, _amount);
    }

    function _registerCreator(
        address _creator,
        string calldata _creatorName,
        string calldata _metadataURI
    ) internal {
        address nft = _deployCliptoFor(_creatorName);
        creators[_creator] = Creator(nft, _metadataURI);

        emit CreatorRegistered(_creator, nft);
    }

    function _updateCreator(address _creator, string calldata _metadataURI) internal {
        Creator storage creator = creators[_creator];
        creator.metadataURI = _metadataURI;

        emit CreatorUpdated(_creator, _metadataURI);
    }

    function _validateRequest(address _creator, uint256 _amount) internal view {
        require(_existsCreator(_creator), "error: creator does not exists");
        require(_amount > 0, "amount should be greater than 0");
    }

    function _newRequest(
        address _creator,
        address _requester,
        address _erc20,
        uint256 _amount,
        string calldata _metadataURI
    ) internal {
        requests[_creator].push(Request(_requester, _erc20, _amount, false, _metadataURI));
        emit NewRequest(_creator, requests[_creator].length - 1);
    }

    function _existsCreator(address _creator) internal view returns (bool) {
        return creators[_creator].nft != address(0);
    }

    function _deployCliptoFor(string calldata _creatorName) internal returns (address) {
        address nftAddress = Clones.clone(CLIPTO_TOKEN_ADDRESS);
        ICliptoToken(nftAddress).initialize(address(this), _creatorName);
        return nftAddress;
    }

    function _checkAllowance(
        address _erc20,
        address _from,
        uint256 _amount
    ) internal view {
        uint256 allowance = IERC20(_erc20).allowance(_from, address(this));
        require(allowance >= _amount, "error: allowance is either not given or is insufficient");
    }

    function _pay(
        address _from,
        address _to,
        address _erc20,
        uint256 _amount
    ) internal {
        bool sent;
        if (_from == address(this)) {
            sent = IERC20(_erc20).transfer(_to, _amount);
        } else {
            sent = IERC20(_erc20).transferFrom(_from, _to, _amount);
        }
        require(sent, "error: payment transfer failed");

        emit Payment(_to, _erc20, _amount);
    }

    function _pay(address _to, uint256 _amount) internal {
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "error: payment transfer failed");

        emit Payment(_to, address(0), _amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: AGPL-3.0 License
pragma solidity ^0.8.10;

interface ICliptoToken {
    function initialize(address _owner, string memory _creatorName) external;

    function name() external view returns (string memory);

    function symbol() external pure returns (string memory);

    function totalSupply() external view returns (uint256);

    function contractURI() external pure returns (string memory);

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256);

    function tokenURI(uint256 _tokenId) external view returns (string memory);

    function setRoyaltyRate(uint256 _royaltyNumer, uint256 _royaltyDenom) external;

    function safeMint(address to, string memory _tokenURI) external;

    function burn(uint256 _tokenId) external;

    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: AGPL-3.0 License
pragma solidity ^0.8.10;

contract CliptoExchangeStorage {
    address public CLIPTO_TOKEN_ADDRESS;
    address public owner;

    struct Request {
        address requester;
        address erc20;
        uint256 amount;
        bool fulfilled;
        string metadataURI;
    }

    struct Creator {
        address nft;
        string metadataURI;
    }

    mapping(address => Creator) public creators;
    mapping(address => Request[]) public requests;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
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

        (bool success, ) = recipient.call{value: amount}("");
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

        (bool success, bytes memory returndata) = target.call{value: value}(data);
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