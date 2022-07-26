//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "./interfaces/IDAOInterface.sol";
import "./interfaces/ITokenInterface.sol";
import "./interfaces/IVotingInterface.sol";

contract DAOFactory is OwnableUpgradeable {

    using ClonesUpgradeable for address;

    enum DaoType{
        RawDao,
        ExternalDao,
        CrossGovDao
    }
    uint public curDaoId;
    mapping(uint => address) public daoMap;// daoId -> DAO
    mapping(address => address[]) public createdDao;// user address -> DAO
    mapping(address => DaoType) public getDaoType;

    address public daoImpl;
    address public externalDaoImpl;
    address public crossGovDaoImpl;
    address public tokenImpl;
    address public votingImpl;
    address public externalVotingImpl;
    address public crossGovVotingImpl;
    address[] public trustedAddr;


    event CreateDAO(uint indexed id, address indexed daoProxy, address indexed tokenProxy, address votingProxy, address creator);
    event CreateExternalDAO(uint indexed id, address indexed daoProxy, address indexed tokenProxy, address votingProxy, address creator);
    event CreateCrossGovDAO(uint indexed id, address indexed daoProxy, address indexed tokenProxy, address votingProxy, address creator);
    event UpdateDaoImpl(address oldDaoImpl, address newDaoImpl);
    event UpdateExternalDaoImpl(address oldExternalDaoImpl, address newExternalDaoImpl);
    event UpdateCrossGovDaoImpl(address oldCrossGovDaoImpl, address newCrossGovDaoImpl);
    event UpdateTokenImpl(address oldTokenImpl, address newTokenImpl);
    event UpdateVotingImpl(address oldVotingImpl, address newVotingImpl);
    event UpdateExternalVotingImpl(address oldExternalVotingImpl, address newExternalVotingImpl);
    event UpdateCrossGovVotingImpl(address oldCrossGovVotingImpl, address newCrossGovVotingImpl);

    function initialize(address _daoImpl, address _externalDaoImpl, address _crossGovDaoImpl, address _tokenImpl,
        address _votingImpl, address _externalVotingImpl, address _crossGovVotingImpl) initializer() public {
        daoImpl = _daoImpl;
        externalDaoImpl = _externalDaoImpl;
        tokenImpl = _tokenImpl;
        votingImpl = _votingImpl;
        externalVotingImpl = _externalVotingImpl;
        crossGovDaoImpl = _crossGovDaoImpl;
        crossGovVotingImpl = _crossGovVotingImpl;
        __Ownable_init();
    }

    function updateDaoImpl(address _daoImpl) public onlyOwner {
        address old = daoImpl;
        daoImpl = _daoImpl;
        emit UpdateDaoImpl(old, _daoImpl);
    }

    function updateExternalDaoImpl(address _externalDaoImpl) public onlyOwner {
        address old = externalDaoImpl;
        externalDaoImpl = _externalDaoImpl;
        emit UpdateExternalDaoImpl(old, _externalDaoImpl);
    }

    function updateCrossGovDaoImpl(address _crossGovDaoImpl) public onlyOwner {
        address old = externalDaoImpl;
        crossGovDaoImpl = _crossGovDaoImpl;
        emit UpdateCrossGovDaoImpl(old, _crossGovDaoImpl);
    }

    function updateTokenImpl(address _tokenImpl) public onlyOwner {
        address old = tokenImpl;
        tokenImpl = _tokenImpl;
        emit UpdateTokenImpl(old, _tokenImpl);
    }

    function updateVotingImpl(address _votingImpl) public onlyOwner {
        address old = votingImpl;
        votingImpl = _votingImpl;
        emit UpdateVotingImpl(old, _votingImpl);
    }

    function updateExternalVotingImpl(address _externalVotingImpl) public onlyOwner {
        address old = externalVotingImpl;
        externalVotingImpl = _externalVotingImpl;
        emit UpdateExternalVotingImpl(old, _externalVotingImpl);
    }

    function updateCrossGovVotingImpl(address _crossGovVotingImpl) public onlyOwner {
        address old = crossGovVotingImpl;
        crossGovVotingImpl = _crossGovVotingImpl;
        emit UpdateCrossGovVotingImpl(old, _crossGovVotingImpl);
    }

    function addTrustedAddr(address[] calldata addrs) onlyOwner public {
        for (uint i = 0; i < addrs.length; i++) {
            trustedAddr.push(addrs[i]);
        }
    }

    function getTrustedAddr() public view returns (address[] memory){
        return trustedAddr;
    }

    function deleteTrustedAddr(address addr) onlyOwner public {
        uint index = trustedAddr.length;
        for (uint i = 0; i < trustedAddr.length; i++) {
            if (trustedAddr[i] == addr) {
                index = i;
                break;
            }
        }
        if (index < trustedAddr.length) {
            delete trustedAddr[index];
        }
        return;
    }


    // query dao address created by user
    function getCreatedDaoByAddress(address user) public view returns (address[] memory) {
        return createdDao[user];
    }

    function createCrossGovDAO(IDAOCrossGovInterface.DAOBasic memory basic,
        IDAOCrossGovInterface.DAORule memory rule) public returns (address) {
        require(trustedAddr.length >= 1, "nonexistent trusted address");
        address daoProxy = crossGovDaoImpl.clone();
        address votingProxy = crossGovVotingImpl.clone();
        ICrossGovVotingInterface(votingProxy).initialize(daoProxy, basic.chainId, trustedAddr);
        IDAOCrossGovInterface(daoProxy).initialize(basic, rule, votingProxy);
        uint id = getCurId() + 1;
        daoMap[id] = daoProxy;
        createdDao[msg.sender].push(daoProxy);
        getDaoType[daoProxy] = DaoType.CrossGovDao;
        incrementId();
        emit CreateCrossGovDAO(id, daoProxy, basic.contractAddress, votingProxy, msg.sender);
        return daoProxy;
    }

    function createDAOWithExternalToken(IDAOExternalInterface.DAOBasic memory basic,
        IDAOInterface.DAORule memory rule, address token) public returns (address) {
        TokenSnapshotInterface(token).getCurrentSnapshotId();
        address daoProxy = externalDaoImpl.clone();
        address votingProxy = externalVotingImpl.clone();
        IVotingInterface(votingProxy).initialize(daoProxy);
        IDAOExternalInterface(daoProxy).initialize(basic, rule, token, votingProxy);
        uint id = getCurId() + 1;
        daoMap[id] = daoProxy;
        createdDao[msg.sender].push(daoProxy);
        getDaoType[daoProxy] = DaoType.ExternalDao;
        incrementId();
        emit CreateExternalDAO(id, daoProxy, token, votingProxy, msg.sender);
        return daoProxy;
    }

    function createDAO(IDAOInterface.DAOBasic memory basic, IDAOInterface.Distribution memory dis,
        IDAOInterface.DAORule memory rule) public returns (address) {
        address daoProxy = daoImpl.clone();
        address tokenProxy = tokenImpl.clone();
        address votingProxy = votingImpl.clone();
        IVotingInterface(votingProxy).initialize(daoProxy);
        TokenInterface(tokenProxy).initialize(basic.tokenName, basic.tokenSymbol,
            basic.tokenLogo, basic.tokenSupply, basic.tokenDecimal, basic.transfersEnabled, daoProxy);
        IDAOInterface(daoProxy).initialize(basic, dis, rule, tokenProxy, votingProxy);
        uint id = getCurId() + 1;
        daoMap[id] = daoProxy;
        createdDao[msg.sender].push(daoProxy);
        getDaoType[daoProxy] = DaoType.RawDao;
        incrementId();
        emit CreateDAO(id, daoProxy, tokenProxy, votingProxy, msg.sender);
        return daoProxy;
    }

    function getCurId() public view returns (uint){
        return curDaoId;
    }

    function incrementId() internal {
        curDaoId += 1;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
library ClonesUpgradeable {
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


interface IDAOInterface {

    struct DAOBasic {
        string daoName;
        string daoDesc;
        string website;
        string twitter;
        string discord;
        string tokenName;
        string tokenSymbol;
        string tokenLogo;
        uint tokenSupply;
        uint8 tokenDecimal;
        bool transfersEnabled;
    }

    struct ReservedTokens {
        address to;
        uint amount;
        uint lockDate;
    }

    struct PrivateSale {
        address to;
        uint amount; //daoToken的数量
        uint price;
    }

    struct PublicSale {
        uint amount;
        uint price;
        uint startTime;
        uint endTime;
        uint pledgeLimitMin;// Crowdfunding minimum
        uint pledgeLimitMax;//Crowdfunding maximum
    }

    struct Distribution {
        ReservedTokens[] reserves;
        PrivateSale[] priSales;
        PublicSale pubSale;
        address receiveToken;
        string introduction;
    }

    struct DAORule {
        uint minimumVote;
        uint minimumCreateProposal;
        uint minimumValidVotes;// 最小有效票数
        uint communityVotingDuration;
        uint contractVotingDuration;
        string content;
    }

    function initialize(DAOBasic memory basic, Distribution memory dis, DAORule memory rule,
        address _daoToken, address _voting) external;

    function getDaoRule() view external returns (DAORule memory);

    function getDaoToken() view external returns (address);
}


interface IDaoVotingInterface {
    function updateReserveLockDate(address user, uint date) external;

    function updateDaoRule(IDAOInterface.DAORule memory _rule) external;

    function withdrawToken(address token, address to, uint amount) external;
}

interface IDaoExternalVotingInterface {
    function updateDaoRule(IDAOInterface.DAORule memory _rule) external;
}

interface IDAOExternalInterface {

    struct DAOBasic {
        string daoName;
        string daoDesc;
        string website;
        string twitter;
        string discord;
        string tokenLogo;
    }

    function initialize(IDAOExternalInterface.DAOBasic memory basic, IDAOInterface.DAORule memory rule,
        address _daoToken, address _voting) external;

    function getDaoRule() view external returns (IDAOInterface.DAORule memory);

    function getDaoToken() view external returns (address);
}


interface IDAOCrossGovInterface {

    struct DAOBasic {
        string name;
        uint chainId;
        address contractAddress;
        string daoDesc;
        string website;
        string twitter;
        string discord;
        string tokenLogo;
    }

    struct DAORule {
        uint minimumVote;
        uint minimumCreateProposal;
        uint minimumValidVotes;// 最小有效票数
        uint communityVotingDuration;
        uint contractVotingDuration;
        string content;
    }


    function initialize(IDAOCrossGovInterface.DAOBasic memory basic, IDAOCrossGovInterface.DAORule memory rule,
        address _voting) external;

    function getDaoRule() view external returns (IDAOCrossGovInterface.DAORule memory);

    function updateDaoRule(IDAOCrossGovInterface.DAORule memory _rule) external;

    function getDaoToken() pure external returns (address);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


interface TokenInterface {
    function initialize(string memory name_, string memory symbol_,
        string memory logo_, uint totalSupply_, uint8 decimals_,
        bool _transfersEnabled, address to) external;

    //if external dao, the second args is snapshotId
    function balanceOfAt(address _user, uint _blockNumber) external view returns (uint);
}

interface TokenSnapshotInterface {

    //if external dao, the second args is snapshotId
    function balanceOfAt(address _user, uint _blockNumber) external view returns (uint);

    function snapshot() external returns (uint);

    function getCurrentSnapshotId() external view returns (uint);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


interface IVotingInterface {
    struct Proposal {
        uint id;
        ProposalType proType;
        address creator;
        string title;
        string content;
        uint startTime;
        uint endTime;
        uint blkHeight;
        uint minimumVote;
        uint minimumValidVotes;// 最小有效票数
        uint minimumCreateProposal;
        ProposalStatus status;
        bytes data;// executeScript
    }
    enum ProposalType {
        Community, // community proposal
        Contract
    }
    enum ProposalStatus {
        Review,
        Active,
        Failed,
        Success,
        Cancel,
        Executed // 已执行
    }
    function initialize(address dao) external;
}


interface ICrossGovVotingInterface {
    enum ProposalType {
        Community, // community proposal
        Contract
    }

    struct Proposal {
        uint id;
        ProposalType proType;
        address creator;
        string title;
        string content;
        uint startTime;
        uint endTime;
        uint minimumVote;
        uint minimumValidVotes;// 最小有效票数
        uint minimumCreateProposal;
        ProposalStatus status;
        bytes data;
    }

    enum ProposalStatus {
        Review,
        Active,
        Failed,
        Success,
        Cancel,
        Executed // 已执行
    }
    function initialize(address dao, uint chainId, address[] calldata _trustedAddr) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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