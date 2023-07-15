// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {INFT} from "./interfaces/INFT.sol";
import {IFacilitator} from "./interfaces/IFacilitator.sol";
import {INFTFactory} from "./interfaces/INFTFactory.sol";
import {IMutagenNFT} from "./mutagens/interfaces/IMutagenNFT.sol";
import {IRoyaltyDistributorFactory} from "./interfaces/IRoyaltyDistributorFactory.sol";
import "./mutagens/Mutagen.sol";

contract NFTFactory is Ownable, INFTFactory {
    //------------------- Errors ---------------------//

    error NoContractAddress();
    error ZeroAddressFacilitator();
    error UnOrderedTokenIds();
    error ZeroAddress();
    error InvalidAgentOrClassification();

    //------------------- State variables ----------------//

    /// Address of the logic implementation address.
    address public proxyImplementation;

    /// Address of the mutagen logic implementation address.
    address public mutagenImplementation;

    /// Address of the Royality distributor factory address.
    IRoyaltyDistributorFactory public immutable royaltyDistributorFactory;

    /// Address of the facilitator contract
    /// used for the primary market sales.
    address public facilitator;

    /// Address of the clones produced by the factory.
    address[] private _createdClones;

    /// Address of the mutagen clones produced by the factory.
    address[] private _createdMutagenClones;

    /// Cheap storage technique
    address public globalRoyaltyReceiver;

    /// Percentage of royalty that get charged during sales of NFT.
    uint96 public feeNumerator;

    /// Authorised signer for the mutation.
    address public authorisedMutationSigner;

    /// Metadata revealer Address
    address public metadataRevealer;

    /// Mutagenise contract address 
    address public mutagenise;

    /// InterfaceId of mutagen.
    bytes4 public mutagenInterfaceId;

    //------------------ Events -----------------------//

    /// Event emission when new nft aka clone got created.
    event NFTCreated(
        string name, string symbol, string baseUri, address cloneAddress
    );

    /// Emitted when facilitator get set.
    event FacilitatorSet(address newFacilitator);

    /// Emit when implementation contract address get changed.
    event ImplementationChanged(
        address oldImplementation, address newImplementation
    );

    /// Emit when the global royalty info is set.
    event SetGlobalRoyaltyInfo(
        address globalRoyaltyReceiver, uint96 feeNumerator
    );

    /// Emit when authorised mutation signer changes.
    event AuthorisedMutationSignerChanged(address _newSigner);

    /// Emit when mutagen interface id changes.
    event MutagenInterfaceIdChanged(bytes4 newInterfaceId);

    /// Emit when implementation contract address get changed.
    event MutagenImplementationChanged(address oldImplementation, address newImplementation);

    /// Emit when new mutagen nft aka clone got created.
    event MutagenNFTCreated(address indexed clone, string name, string symbol);

    /// Emit when metadata revealer address changed.
    event MetadataRevealerAddressChanged(address metadataRevealer);

    /// Emit when mutagenise address changed.
    event MutageniseAddressChanged(address mutagenise);

    /// Initialization of the contract.
    /// @param _proxyImplementation Address of the logic contract which get used
    ///                             to create the clones.
    constructor(
        address _proxyImplementation, 
        IRoyaltyDistributorFactory _royaltyDistributorFactory, 
        address _mutagenImplementation, 
        address _metadataRevealer, 
        address _mutagenise, 
        address _authorisedMutationSigner
    ) {
        metadataRevealer = _metadataRevealer;
        proxyImplementation = _proxyImplementation;
        royaltyDistributorFactory = _royaltyDistributorFactory;
        mutagenImplementation = _mutagenImplementation;
        mutagenise = _mutagenise;
        authorisedMutationSigner = _authorisedMutationSigner;
    }

    /// @notice Allows the owner to set the facilitator.
    /// @param _facilitator Address of the primary market contract.
    function setFacilitator(address _facilitator) external onlyOwner {
        if (_facilitator == address(0)) {
            revert ZeroAddressFacilitator();
        }
        facilitator = _facilitator;
        emit FacilitatorSet(_facilitator);
    }

    /// @notice Facilitates the creation of the NFT aka clone, Only owner is allowed to call.
    /// @param  _baseUri Base uri of the NFT.
    /// @param  _name Name of the NFT.
    /// @param  _symbol Symbol of the NFT
    /// @param  _series List of series supported by the primary sale.
    /// @param  _mintPrices List of purchase price or mint price that user has to pay for
    /// @param  _maxTokenIdForSeries Maximum tokenId supported for different series. (Should be sorted in order).
    /// @param  _payees Addresses of the royalty receivers.
    /// @param  _shares Share percentages of each royalty receivers address.
    /// @param  _royaltyMetadata[0] Default royalty percentage and _royaltyMetadata[1] Max royalty percentage.
    /// @param _tokenAddress address(1) if native currency else ERC20 token address.
    /// @param _oracleCurrency Currency pair to get price from oracle.
    function createNFT(
        string memory _baseUri,
        string memory _name,
        string memory _symbol,
        string[] memory _series,
        uint256[] memory _mintPrices,
        uint256[] memory _maxTokenIdForSeries,
        address[] memory _payees,
        uint256[] memory _shares,
        uint96[2] memory _royaltyMetadata, 
        address _tokenAddress,
        string memory _oracleCurrency
    )
        external
        onlyOwner
        returns (address clone)
    {
        // Create clone
        clone = Clones.clone(proxyImplementation);
        address _royaltyDefaultReceiver;
        // This will set the RoyaltyDistributor contract as _royaltyDefaultReceiver.
        // If payees doesn't exist then _royaltyDefaultReceiver will become zero.
        if (_payees.length != 0 && _payees.length == _shares.length) {
            _royaltyDefaultReceiver = royaltyDistributorFactory.createRoyaltyDistributor(clone, msg.sender, _payees, _shares);
        }
        // Initialize the contract
        INFT(clone).initialize(
            _maxTokenIdForSeries.length == 1
                ? _maxTokenIdForSeries[0]
                : _getMaxTokenId(_maxTokenIdForSeries),
            _baseUri,
            _name,
            _symbol,
            msg.sender, // TODO: discuss who should be initial owner
            facilitator,
            _royaltyDefaultReceiver,
            _royaltyMetadata[0],
            _royaltyMetadata[1]
        );
        _createdClones.push(clone);
        // Add NFT in primary market
        IFacilitator(facilitator).addNFTInPrimaryMarket(
            clone,
            _mintPrices,
            _series,
            _maxTokenIdForSeries,
            _tokenAddress,
            _oracleCurrency
        );
        // Emit event for NFT creation.
        emit NFTCreated(_name, _symbol, _baseUri, clone);
    }

    /// @notice Facilitates the creation of the mutagen NFT aka clone, Only owner is allowed to call.
    /// @param _agent Agent of the mutagen NFT.
    /// @param _classification Classification of the mutagen NFT.
    /// @param  _baseUri Base uri of the NFT.
    /// @param _name Name of the mutagen NFT.
    /// @param _symbol Symbol of the mutagen NFT.
    /// @param _payees Addresses of the royalty receivers.
    /// @param _shares Share percentages of each royalty receivers address.
    /// @param  _royaltyMetadata[0] Default royalty percentage, _royaltyMetadata[1] Max royalty percentage and _royaltyMetadata[2] is max supply.
    function createMutagen(
        Mutagen.AgentType _agent,
        Mutagen.Classification _classification,
        string memory _baseUri,
        string memory _name,
        string memory _symbol,
        address[] memory _payees,
        uint256[] memory _shares,
        uint96[3] memory _royaltyMetadata
    )
    external
    onlyOwner
    returns (address clone)
    {   
        // creation of the mutagen NFT aka clone
       clone = _createMutagen(_baseUri, _name, _symbol, _payees, _shares, _royaltyMetadata, _agent, _classification);
    }

    /// @notice Facilitates the creation of the mutagen NFT aka clone and list in the market, Only owner is allowed to call.
    /// @param _agent Agent of the mutagen NFT.
    /// @param _classification Classification of the mutagen NFT.
    /// @param  _baseUri Base uri of the NFT.
    /// @param _name Name of the mutagen NFT.
    /// @param _symbol Symbol of the mutagen NFT.
    /// @param _payees Addresses of the royalty receivers.
    /// @param _shares Share percentages of each royalty receivers address.
    /// @param  _royaltyMetadata[0] Default royalty percentage, _royaltyMetadata[1] Max royalty percentage and _royaltyMetadata[2] is max supply.
    /// @param _tokenAddress address(1) if native currency else ERC20 token address.
    /// @param _oracleCurrency Currency pair to get price from oracle.
    function createMutagenAndListOnPrimaryMarket(
        string memory _baseUri,
        string memory _name,
        string memory _symbol,
        address[] memory _payees,
        uint256[] memory _shares,
        uint256 _basePrice,
        uint96[3] memory _royaltyMetadata,
        address _tokenAddress,
        string memory _oracleCurrency,
        Mutagen.AgentType _agent,
        Mutagen.Classification _classification
    )
    external
    onlyOwner
    returns (address clone)
     {
        // Creation of the mutagen NFT aka clone
        clone = _createMutagen(_baseUri, _name, _symbol, _payees, _shares, _royaltyMetadata, _agent, _classification);
        // List nft in primary market
        IFacilitator(facilitator).addMutagenNFTInPrimaryMarket(clone, _basePrice, _tokenAddress, _oracleCurrency, _royaltyMetadata[2]);
     }

    function _createMutagen(
        string memory _baseUri,
        string memory _name,
        string memory _symbol,
        address[] memory _payees,
        uint256[] memory _shares,
        uint96[3] memory _royaltyMetadata,
        Mutagen.AgentType _agent,
        Mutagen.Classification _classification
    )
    internal 
    returns (address clone)
    {  
        // Validate the agent and classification
        if(!Mutagen.matchClassification(_agent, _classification)) {
            revert InvalidAgentOrClassification();
        }
        // Create clone
        clone = Clones.clone(mutagenImplementation);
        address _royaltyDefaultReceiver;
        // This will set the RoyaltyDistributor contract as _royaltyDefaultReceiver.
        // If payees doesn't exist then _royaltyDefaultReceiver will become zero.
        if(_payees.length != 0 && _shares.length != 0) {
            _royaltyDefaultReceiver = IRoyaltyDistributorFactory(royaltyDistributorFactory).createRoyaltyDistributor(clone, msg.sender, _payees, _shares);
        }
        // Initialize the contract
        IMutagenNFT(clone).initialize(
            _baseUri,
            _name,
            _symbol,
            msg.sender,
            facilitator,
            _royaltyDefaultReceiver,
            _royaltyMetadata,
            _agent,
            _classification
        );
        _createdMutagenClones.push(clone);
        // Emit event for NFT creation.
        emit MutagenNFTCreated(clone, _name, _symbol);
    }

    /// @notice Set global royalty that can be used by the NFTs.
    /// @dev Can only be set by the owner.
    /// @param  _receiver Address of the royalty receiver.
    /// @param  _feeNumerator Fee fraction that will get charge for every sale.
    function setGlobalRoyaltyInfo(address _receiver, uint96 _feeNumerator)
        external
        onlyOwner
    {
        require(
            _feeNumerator <= 10000, "ERC2981: royalty fee will exceed salePrice"
        );
        require(_receiver != address(0), "ERC2981: invalid receiver");
        globalRoyaltyReceiver = _receiver;
        feeNumerator = _feeNumerator;
        emit SetGlobalRoyaltyInfo(globalRoyaltyReceiver, feeNumerator);
    }

    /// @notice Retrieve the global royalty info.
    function getGlobalRoyaltyInfo()
        external
        view
        returns (GlobalRoyaltyInfo memory)
    {
        return _getGlobalRoyaltyInfo();
    }

    /// @notice return all the create clones.
    function getClones() external view returns (address[] memory) {
        return _createdClones;
    }

    /// @notice return all the created mutagen clones.
    function getMutagenClones() external view returns (address[] memory) {
        return _createdMutagenClones;
    }

    /// @notice Change implementation address, Owner of the contract has the authorisation
    /// to change.
    /// @param newImplementation Address of the new logic contract address.
    function changeNFTImplementation(address newImplementation)
        external
        onlyOwner
    {
        if (!Address.isContract(newImplementation)) {
            revert NoContractAddress();
        }
        emit ImplementationChanged(proxyImplementation, newImplementation);
        proxyImplementation = newImplementation;
    }

    /// @notice Change mutagen implementation address, Owner of the contract has the authorisation
    /// to change.
    /// @param newImplementation Address of the new logic contract address.
    function changeMutagenImplementation(address newImplementation)
        external
        onlyOwner
    {
        if (!Address.isContract(newImplementation)) {
            revert NoContractAddress();
        }
        emit MutagenImplementationChanged(proxyImplementation, newImplementation);
        mutagenImplementation = newImplementation;
    }

    /// @notice Allow to change the authorised mutation signer. Only owner can change that.
    /// @param newAuthorisedSigner New address set as the authorised signer.
    function changeAuthorisedMutationSigner(address newAuthorisedSigner)
        external
        onlyOwner
    {
        if (newAuthorisedSigner == address(0)) {
            revert ZeroAddress();
        }
        authorisedMutationSigner = newAuthorisedSigner;
        emit AuthorisedMutationSignerChanged(newAuthorisedSigner);
    }

    /// @notice Allow to change the metadata revealer. Only owner can change that.
    /// @param newMetadataRevealer New address set as the metadata revealer.
    function changeMetadataRevealer(address newMetadataRevealer)
        external
        onlyOwner
    {
        if (newMetadataRevealer == address(0)) {
            revert ZeroAddress();
        }
        metadataRevealer = newMetadataRevealer;
        emit MetadataRevealerAddressChanged(metadataRevealer);
    }

    /// @notice Allow to change the mutagenise address. Only owner can change that.
    /// @param newMutageniseAddress New address set as the mutagenise.
    function changeMutageniseAddress(address newMutageniseAddress)
        external
        onlyOwner
    {
        if (newMutageniseAddress == address(0)) {
            revert ZeroAddress();
        }
        mutagenise = newMutageniseAddress;
        emit MutageniseAddressChanged(mutagenise);
    }

    /// @notice Allow to change the mutagen interface id. Only owner can change that.
    /// @param newInterfaceId New interface id of mutagen.
    function changeMutagenInterfaceId(bytes4 newInterfaceId)
        external
        onlyOwner
    {
        mutagenInterfaceId = newInterfaceId;
        emit MutagenInterfaceIdChanged(newInterfaceId);
    }

    function _getGlobalRoyaltyInfo()
        internal
        view
        returns (GlobalRoyaltyInfo memory)
    {
        return GlobalRoyaltyInfo(globalRoyaltyReceiver, feeNumerator);
    }

    function _getMaxTokenId(uint256[] memory _maxTokenIds)
        internal
        pure
        returns (uint256 _maxTokenId)
    {
        uint256 len = _maxTokenIds.length;
        for (uint256 i = 0; i < len - 1; i++) {
            if (_maxTokenIds[i + 1] < _maxTokenIds[i]) {
                revert UnOrderedTokenIds();
            }
        }
        _maxTokenId = _maxTokenIds[len - 1];
    }
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
        /// @solidity memory-safe-assembly
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
        /// @solidity memory-safe-assembly
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
        /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../mutagens/NFTMetadataViews.sol";

interface INFT is IERC721 {
    /// @notice Initialize the NFT collection.
    /// @param _maxSupply maximum supply of a collection.
    /// @param baseUri base Url of the nft's metadata.
    /// @param _name name of the collection.
    /// @param _symbol symbol of the collection.
    /// @param _owner owner of the collection.
    /// @param _minter Address of the minter allowed to mint tokenIds.
    /// @param _royaltyReceiver Beneficary of the royalty.
    /// @param _feeNumerator Percentage of fee charged as royalty.
    /// @param _maxRoyaltyPercentage Percentage of maximum fee charged as royalty.
    function initialize(
        uint256 _maxSupply,
        string calldata baseUri,
        string calldata _name,
        string calldata _symbol,
        address _owner,
        address _minter,
        address _royaltyReceiver,
        uint96 _feeNumerator,
        uint96 _maxRoyaltyPercentage
    )
        external;

    /// @notice Mint a token and assign it to an address.
    /// @param _to NFT transferred to the given address.
    /// @param metadata of the NFT.
    function mint(address _to, NFTMetadataViews.NFTView memory metadata) external;

    /// @notice Mint a token and assign it to an address.
    /// @param _to NFT transferred to the given address.
    /// @param metadataHash Hash of the metadata of the NFT.
    function commitMint(address _to, bytes32 metadataHash, string calldata _tokenUri) external;

    /// @notice Sets the royalty information that all ids in this contract will default to.
    /// Requirements:
    /// `receiver` cannot be the zero address.
    /// `feeNumerator` cannot be greater than the fee denominator.
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external;

    /// @notice Sets the royalty information for a specific token id, overriding the global default.
    /// Requirements:
    /// `receiver` cannot be the zero address.
    /// `feeNumerator` cannot be greater than the fee denominator.
    /// @param tokenId Token identitifer whom royalty information gonna set.
    /// @param receiver Beneficiary of the royalty.
    /// @param feeNumerator Percentage of fee gonna charge as royalty.
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    )
        external;

    /// @notice Deletes the default royalty information.
    function deleteDefaultRoyalty() external;

    /// @notice Global royalty would not be in use after this.
    function closeGlobalRoyalty() external;

    /// @notice Global royalty would be in use after this.
    function openGlobalRoyalty() external;

    /// @notice Resets royalty information for the token id back to the global default.
    function resetTokenRoyalty(uint256 tokenId) external;

    /// @notice Returns the URI that provides the details of royalty for OpenSea support.
    /// Ref - https://docs.opensea.io/v2.0/docs/contract-level-metadata
    function contractURI() external view returns (string memory);

    /// @notice Returns the Uniform Resource Identifier (URI) for `tokenId` token.
    /// @param tokenId Identifier for the token
    function tokenURI(uint256 tokenId)
        external
        view
        returns (string memory);
    
    /// @notice Returns the base URI for the contract.
    function baseURI() external view returns (string memory);

    /// @notice Set the base URI, Only ADMIN can call it.
    /// @param newBaseUri New base uri for the metadata.
    function setBaseUri(string memory newBaseUri) external;

    /// @notice Set the token URI for the given tokenId.
    /// @param tokenId Identifier for the token
    /// @param tokenUri URI for the given tokenId.
    function setTokenUri(uint256 tokenId, string memory tokenUri) external;

    /// @notice Perform the mutation on a tokenID. Only tokenId owner allowed to perform mutation.
    /// @param tokenId Identifier for the token.
    /// @param mutagen Address of the mutagen.
    /// @param expiry Expiry of the signature.
    /// @param signatureNonce Nonce that is used to create the signature.
    /// @param signature Offchain signature of the authorised address.
    function mutate(
        address projectNFT, 
        uint256 tokenId, 
        address mutagen, 
        uint256 mutagenNFTId,
        uint256 expiry, 
        uint256 signatureNonce,
        bytes memory signature
    ) external;

    /// @notice Reveal the metadata of the already minted tokenId.
    /// @param tokenId Identifier of the NFT whose metadata is going to set.
    /// @param metadata Metadata of the given NFT.
    /// @param salt Unique identifier use to reveal the metadata.
    function revealMetadata(uint256 tokenId, NFTMetadataViews.NFTView memory metadata, string memory salt) external;

    function nextTokenId() external view returns (uint256);

    function maximumSupply() external view returns (uint256);

    function globalRoyaltyInEffect() external view returns (bool);

    function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../mutagens/NFTMetadataViews.sol";

interface IFacilitator {
    /// @notice Function to provide the ownership of the minting of the given nft.
    /// @param nft Address of the nft whose purchase would be allowed.
    /// @param basePrices Base prices of the NFT during the primary sales for different series.
    /// @param series Supoorted series for a given nft sale.
    /// @param maxTokenIdForSeries Maximum tokenId supported for different series. (Should be sorted in order).
    /// @param tokenAddress Token address if currency is ERC20.
    /// @param oracleCurrencyPair Currency pair to get price from oracle.
    function addNFTInPrimaryMarket(
        address nft,
        uint256[] calldata basePrices,
        string[] calldata series,
        uint256[] calldata maxTokenIdForSeries,
        address tokenAddress,
        string calldata oracleCurrencyPair
    )
        external;

    /// @notice Function to provide the ownership of the minting of the given nft.
    /// @param mutagenNFT Address of the nft whose purchase would be allowed.
    /// @param basePrice Base prices of the NFT during the primary sales.
    /// @param tokenAddress Token address if currency is ERC20.
    /// @param oracleCurrencyPair Currency pair to get price from oracle.
    /// @param maxSupply Maximum Supply of the nfts.
    function addMutagenNFTInPrimaryMarket(
        address mutagenNFT,
        uint256 basePrice,
        address tokenAddress,
        string calldata oracleCurrencyPair,
        uint256 maxSupply
    )
        external;

    /// @notice Allow the owner to remove the given NFT from the listings.
    /// @param nft Address of the NFT that needs to be unlisted.
    function removeNFTFromPrimaryMarket(address nft) external;

    /// @notice Allow a user to purchase the NFTs in batch.
    /// @param nft Address of the NFT which need to get purcahse.
    /// @param receiver Address of the receiver.
    /// @param expiry Expiry of the signature.
    /// @param signatureNonce Nonce that is used to create the signature.
    /// @param signature Offchain signature of the authorised address.
    /// @param erc20TokenAmt Amount of tokens if currency is ERC20.
    /// @param metadataHashes Hash of the metadata of a NFT.
    function batchPurchaseNFT(
        address nft,
        address receiver,
        uint256 expiry,
        uint256 signatureNonce,
        bytes memory signature,
        uint256 erc20TokenAmt,
        bytes32[] calldata metadataHashes
    )
        external
        payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface INFTFactory {
    struct GlobalRoyaltyInfo {
        address globalRoyaltyReceiver;
        uint96 feeNumerator;
    }

    function getGlobalRoyaltyInfo()
        external
        view
        returns (GlobalRoyaltyInfo memory);

    function authorisedMutationSigner() external view returns (address);

    function mutagenInterfaceId() external view returns (bytes4);

    function metadataRevealer() external view returns (address);

    function mutagenise() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../NFTMetadataViews.sol";
import "../Mutagen.sol";

interface IMutagenNFT {

    function initialize (
        string calldata _baseUri,
        string calldata _name,
        string calldata _symbol,
        address _owner,
        address _minter,
        address _royaltyReceiver,
        uint96[3] memory _royaltyMetadata,
        Mutagen.AgentType _agent,
        Mutagen.Classification _classification
    ) external;

    function mint(address _to, NFTMetadataViews.NFTView memory metadata) external;

    function maximumSupply() external view returns(uint256);

    function burn(uint256 tokenId) external;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IRoyaltyDistributorFactory {
    function createRoyaltyDistributor(
        address royaltyOf,
        address owner,
        address[] calldata payees,
        uint256[] calldata shares
    )
        external
        returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

library Mutagen {

    type Classification is uint8;

    enum AgentType { PHYSICAL, CHEMICAL, BIOLOGICAL }

    enum PhysicalClassification { HEAT, RADIATION }

    enum ChemicalClassification { BASE_ANALOGS, INTERCALATING_AGENTS, METAL_IONS, ALKYLATING_AGENTS }

    enum BiologicalClassification { TRANSPOSONS_IS, VIRUS, BACTERIA, OTHER }


    function matchClassification(AgentType agent, Classification classification) external pure returns(bool) {
       if (AgentType.PHYSICAL == agent) {
        return physicalAgentClassification(classification);
       } else if (AgentType.CHEMICAL == agent) {
        return chemicalAgentClassification(classification);
       } else if (AgentType.BIOLOGICAL == agent) {
        return biologicalAgentClassification(classification);
       }
       return false;
    }

    function physicalAgentClassification(Classification classification) public pure returns(bool) {
        uint8 _unwrappedClassification = Classification.unwrap(classification);
        if (uint8(PhysicalClassification.HEAT) == _unwrappedClassification) {
            return true;
        } else if (uint8(PhysicalClassification.RADIATION) == _unwrappedClassification) {
            return true;
        } 
        return false;
    }

    function chemicalAgentClassification(Classification classification) public pure returns(bool) {
        uint8 _unwrappedClassification = Classification.unwrap(classification);
        if (uint8(ChemicalClassification.BASE_ANALOGS) == _unwrappedClassification) {
            return true;
        } else if (uint8(ChemicalClassification.INTERCALATING_AGENTS) == _unwrappedClassification) {
            return true;
        } else if (uint8(ChemicalClassification.METAL_IONS) == _unwrappedClassification) {
            return true;
        } else if (uint8(ChemicalClassification.ALKYLATING_AGENTS) == _unwrappedClassification) {
            return true;
        } 
        return false;
    }

    function biologicalAgentClassification(Classification classification) public pure returns(bool) {
        uint8 _unwrappedClassification = Classification.unwrap(classification);
        if (uint8(BiologicalClassification.TRANSPOSONS_IS) == _unwrappedClassification) {
            return true;
        } else if (uint8(BiologicalClassification.VIRUS) == _unwrappedClassification) {
            return true;
        } else if (uint8(BiologicalClassification.BACTERIA) == _unwrappedClassification) {
            return true;
        }
        return false;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IMetadataViewResolver} from "./interfaces/IMetadataViewResolver.sol";
import { strings } from "@string-utils/strings.sol";

library NFTMetadataViews {

    using strings for *;

    // bytes32 constant rarityView = keccak256(abi.encode("Struct Rarity{uint256 score, uint256 max, string description}"));
    // bytes32 constant traitView = keccak256(abi.encode("Struct Trait{string name, bytes vaule, string dataType, string displayType, Rarity rarity}"));
    bytes32 constant traitsView = keccak256(abi.encode("Struct Attributes{Attribute[] attributes}"));
    bytes32 constant displayView = keccak256(abi.encode("Struct Display{string name, string description}"));

    /// View to expose rarity information for a single rarity
    /// Note that a rarity needs to have either score or description but it can 
    /// have both
    ///
    struct Rarity {
        /// The score of the rarity as a number
        uint256 score;

        /// The maximum value of score
        uint256 max;

        /// The description of the rarity as a string.
        ///
        /// This could be Legendary, Epic, Rare, Uncommon, Common or any other string value
        string description;
    }

    /// Helper to get Rarity view in a typesafe way
    ///
    /// @param nftContract: NFT contract to get the rarity
    /// @param nftId: NFT id
    /// @return Rarity 
    ///
    // function getRarity(address nftContract, uint256 nftId) external view returns(Rarity rarityMetadata){
    //     bytes rarity = IMetadataViewResolver(nftContract).resolveView(nftId, rarityView);
    //     if (rarity.length > 0) {
    //         rarityMetadata = abi.decode(rarity, (Rarity));
    //     }
    // }


    /// View to represent a single field of metadata on an NFT.
    /// This is used to get traits of individual key/value pairs along with some
    /// contextualized data about the trait
    ///
    struct Attribute {
        // The name of the trait. Like Background, Eyes, Hair, etc.
        string trait_type;

        // The underlying value of the trait, the rest of the fields of a trait provide context to the value.
        bytes value;

        // The data type of the underlying value.
        string data_type;

        // displayType is used to show some context about what this name and value represent
        // for instance, you could set value to a unix timestamp, and specify displayType as "Date" to tell
        // platforms to consume this trait as a date and not a number
        string display_type;

        // Rarity can also be used directly on an attribute.
        //
        // This is optional because not all attributes need to contribute to the NFT's rarity.
        Rarity rarity;
    }


    /// Wrapper view to return all the traits on an NFT.
    /// This is used to return traits as individual key/value pairs along with
    /// some contextualized data about each trait.
    struct Attributes {
        Attribute[] attributes;
    }

    /// Helper to get Traits view in a typesafe way
    ///
    /// @param nftContract: A reference to the resolver resource
    /// @param nftId: A reference to the resolver resource
    ///
    function getTraits(address nftContract, uint256 nftId) public returns(Attributes memory traitsMetadata) {
        bytes memory traits = IMetadataViewResolver(nftContract).resolveView(nftId, traitsView);
        if (traits.length > 0) {
            traitsMetadata = abi.decode(traits, (Attributes));
        }
    }

    /// View to expose a file stored on IPFS.
    /// IPFS images are referenced by their content identifier (CID)
    /// rather than a direct URI. A client application can use this CID
    /// to find and load the image via an IPFS gateway.
    ///
    struct IPFSFile {

        /// CID is the content identifier for this IPFS file.
        ///
        /// Ref: https://docs.ipfs.io/concepts/content-addressing/
        ///
        string cid;

        /// Path is an optional path to the file resource in an IPFS directory.
        ///
        /// This field is only needed if the file is inside a directory.
        ///
        /// Ref: https://docs.ipfs.io/concepts/file-systems/
        ///
        string path;
    }

    /// This function returns the IPFS native URL for this file.
    /// Ref: https://docs.ipfs.io/how-to/address-ipfs-on-web/#native-urls
    ///
    /// @return The string containing the file uri
    ///
    function getUri(IPFSFile memory ipfs) public pure returns(string memory) {
        string memory ipfs_default_location = "ipfs://".toSlice().concat(ipfs.cid.toSlice());
        if (bytes(ipfs.path).length == 0) {
            return (ipfs_default_location
                .toSlice()
                .concat("/".toSlice()))
                .toSlice()
                .concat(ipfs.path.toSlice());
        }
        return ipfs_default_location;
    }


    struct Display {
        /// The name of the object. 
        ///
        /// This field will be displayed in lists and therefore should
        /// be short an concise.
        ///
        string name;

        /// A written description of the object. 
        ///
        /// This field will be displayed in a detailed view of the object,
        /// so can be more verbose (e.g. a paragraph instead of a single line).
        ///
        string description;


        IPFSFile file;
    }


    function getDisplay(address nftContract, uint256 nftId) public returns(Display memory displayMetadata) {
        bytes memory display_content = IMetadataViewResolver(nftContract).resolveView(nftId, displayView);
        if (display_content.length > 0) {
            displayMetadata = abi.decode(display_content, (Display));
        }
    }

    struct NFTView {
        Display display;
        string uri;
        Attributes attributes;
    }

    function getNFTView(address nftContract, uint256 nftId) external returns(NFTView memory nftMetdata) {
        Display memory display = getDisplay(nftContract, nftId);
        return NFTView({
            display: display,
            uri: bytes(display.file.cid).length > 0? getUri(display.file): "" ,
            attributes: getTraits(nftContract, nftId)
        });
    }

    /// @dev This function has been created just to use in abi for the signature generation at FE
    function getView(NFTView[] memory nftView) external pure returns(string memory) {
        return "abc";
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IMetadataViewResolver is IERC165 {

    function getViews(uint256 nftId) external view returns(bytes32[] memory);
    function resolveView(uint256 nftId, bytes32 viewType) external returns(bytes memory);

}

/*
 * @title String & slice utility library for Solidity contracts.
 * @author Nick Johnson <[email protected]>
 *
 * @dev Functionality in this library is largely implemented using an
 *      abstraction called a 'slice'. A slice represents a part of a string -
 *      anything from the entire string to a single character, or even no
 *      characters at all (a 0-length slice). Since a slice only has to specify
 *      an offset and a length, copying and manipulating slices is a lot less
 *      expensive than copying and manipulating the strings they reference.
 *
 *      To further reduce gas costs, most functions on slice that need to return
 *      a slice modify the original one instead of allocating a new one; for
 *      instance, `s.split(".")` will return the text up to the first '.',
 *      modifying s to only contain the remainder of the string after the '.'.
 *      In situations where you do not want to modify the original slice, you
 *      can make a copy first with `.copy()`, for example:
 *      `s.copy().split(".")`. Try and avoid using this idiom in loops; since
 *      Solidity has no memory management, it will result in allocating many
 *      short-lived slices that are later discarded.
 *
 *      Functions that return two slices come in two versions: a non-allocating
 *      version that takes the second slice as an argument, modifying it in
 *      place, and an allocating version that allocates and returns the second
 *      slice; see `nextRune` for example.
 *
 *      Functions that have to copy string data will return strings rather than
 *      slices; these can be cast back to slices for further processing if
 *      required.
 *
 *      For convenience, some functions are provided with non-modifying
 *      variants that create a new slice and return both; for instance,
 *      `s.splitNew('.')` leaves s unmodified, and returns two values
 *      corresponding to the left and right parts of the string.
 */

pragma solidity ^0.8.0;

library strings {
    struct slice {
        uint _len;
        uint _ptr;
    }

    function memcpy(uint dest, uint src, uint len) private pure {
        // Copy word-length chunks while possible
        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = type(uint).max;
        if (len > 0) {
            mask = 256 ** (32 - len) - 1;
        }
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /*
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    /*
     * @dev Returns the length of a null-terminated bytes32 string.
     * @param self The value to find the length of.
     * @return The length of the string, from 0 to 32.
     */
    function len(bytes32 self) internal pure returns (uint) {
        uint ret;
        if (self == 0)
            return 0;
        if (uint(self) & type(uint128).max == 0) {
            ret += 16;
            self = bytes32(uint(self) / 0x100000000000000000000000000000000);
        }
        if (uint(self) & type(uint64).max == 0) {
            ret += 8;
            self = bytes32(uint(self) / 0x10000000000000000);
        }
        if (uint(self) & type(uint32).max == 0) {
            ret += 4;
            self = bytes32(uint(self) / 0x100000000);
        }
        if (uint(self) & type(uint16).max == 0) {
            ret += 2;
            self = bytes32(uint(self) / 0x10000);
        }
        if (uint(self) & type(uint8).max == 0) {
            ret += 1;
        }
        return 32 - ret;
    }

    /*
     * @dev Returns a slice containing the entire bytes32, interpreted as a
     *      null-terminated utf-8 string.
     * @param self The bytes32 value to convert to a slice.
     * @return A new slice containing the value of the input argument up to the
     *         first null.
     */
    function toSliceB32(bytes32 self) internal pure returns (slice memory ret) {
        // Allocate space for `self` in memory, copy it there, and point ret at it
        assembly {
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 0x20))
            mstore(ptr, self)
            mstore(add(ret, 0x20), ptr)
        }
        ret._len = len(self);
    }

    /*
     * @dev Returns a new slice containing the same data as the current slice.
     * @param self The slice to copy.
     * @return A new slice containing the same data as `self`.
     */
    function copy(slice memory self) internal pure returns (slice memory) {
        return slice(self._len, self._ptr);
    }

    /*
     * @dev Copies a slice to a new string.
     * @param self The slice to copy.
     * @return A newly allocated string containing the slice's text.
     */
    function toString(slice memory self) internal pure returns (string memory) {
        string memory ret = new string(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

    /*
     * @dev Returns the length in runes of the slice. Note that this operation
     *      takes time proportional to the length of the slice; avoid using it
     *      in loops, and call `slice.empty()` if you only need to know whether
     *      the slice is empty or not.
     * @param self The slice to operate on.
     * @return The length of the slice in runes.
     */
    function len(slice memory self) internal pure returns (uint l) {
        // Starting at ptr-31 means the LSB will be the byte we care about
        uint ptr = self._ptr - 31;
        uint end = ptr + self._len;
        for (l = 0; ptr < end; l++) {
            uint8 b;
            assembly { b := and(mload(ptr), 0xFF) }
            if (b < 0x80) {
                ptr += 1;
            } else if(b < 0xE0) {
                ptr += 2;
            } else if(b < 0xF0) {
                ptr += 3;
            } else if(b < 0xF8) {
                ptr += 4;
            } else if(b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
    }

    /*
     * @dev Returns true if the slice is empty (has a length of 0).
     * @param self The slice to operate on.
     * @return True if the slice is empty, False otherwise.
     */
    function empty(slice memory self) internal pure returns (bool) {
        return self._len == 0;
    }

    /*
     * @dev Returns a positive number if `other` comes lexicographically after
     *      `self`, a negative number if it comes before, or zero if the
     *      contents of the two slices are equal. Comparison is done per-rune,
     *      on unicode codepoints.
     * @param self The first slice to compare.
     * @param other The second slice to compare.
     * @return The result of the comparison.
     */
    function compare(slice memory self, slice memory other) internal pure returns (int) {
        uint shortest = self._len;
        if (other._len < self._len)
            shortest = other._len;

        uint selfptr = self._ptr;
        uint otherptr = other._ptr;
        for (uint idx = 0; idx < shortest; idx += 32) {
            uint a;
            uint b;
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }
            if (a != b) {
                // Mask out irrelevant bytes and check again
                uint mask = type(uint).max; // 0xffff...
                if(shortest < 32) {
                  mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
                }
                unchecked {
                    uint diff = (a & mask) - (b & mask);
                    if (diff != 0)
                        return int(diff);
                }
            }
            selfptr += 32;
            otherptr += 32;
        }
        return int(self._len) - int(other._len);
    }

    /*
     * @dev Returns true if the two slices contain the same text.
     * @param self The first slice to compare.
     * @param self The second slice to compare.
     * @return True if the slices are equal, false otherwise.
     */
    function equals(slice memory self, slice memory other) internal pure returns (bool) {
        return compare(self, other) == 0;
    }

    /*
     * @dev Extracts the first rune in the slice into `rune`, advancing the
     *      slice to point to the next rune and returning `self`.
     * @param self The slice to operate on.
     * @param rune The slice that will contain the first rune.
     * @return `rune`.
     */
    function nextRune(slice memory self, slice memory rune) internal pure returns (slice memory) {
        rune._ptr = self._ptr;

        if (self._len == 0) {
            rune._len = 0;
            return rune;
        }

        uint l;
        uint b;
        // Load the first byte of the rune into the LSBs of b
        assembly { b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF) }
        if (b < 0x80) {
            l = 1;
        } else if(b < 0xE0) {
            l = 2;
        } else if(b < 0xF0) {
            l = 3;
        } else {
            l = 4;
        }

        // Check for truncated codepoints
        if (l > self._len) {
            rune._len = self._len;
            self._ptr += self._len;
            self._len = 0;
            return rune;
        }

        self._ptr += l;
        self._len -= l;
        rune._len = l;
        return rune;
    }

    /*
     * @dev Returns the first rune in the slice, advancing the slice to point
     *      to the next rune.
     * @param self The slice to operate on.
     * @return A slice containing only the first rune from `self`.
     */
    function nextRune(slice memory self) internal pure returns (slice memory ret) {
        nextRune(self, ret);
    }

    /*
     * @dev Returns the number of the first codepoint in the slice.
     * @param self The slice to operate on.
     * @return The number of the first codepoint in the slice.
     */
    function ord(slice memory self) internal pure returns (uint ret) {
        if (self._len == 0) {
            return 0;
        }

        uint word;
        uint length;
        uint divisor = 2 ** 248;

        // Load the rune into the MSBs of b
        assembly { word:= mload(mload(add(self, 32))) }
        uint b = word / divisor;
        if (b < 0x80) {
            ret = b;
            length = 1;
        } else if(b < 0xE0) {
            ret = b & 0x1F;
            length = 2;
        } else if(b < 0xF0) {
            ret = b & 0x0F;
            length = 3;
        } else {
            ret = b & 0x07;
            length = 4;
        }

        // Check for truncated codepoints
        if (length > self._len) {
            return 0;
        }

        for (uint i = 1; i < length; i++) {
            divisor = divisor / 256;
            b = (word / divisor) & 0xFF;
            if (b & 0xC0 != 0x80) {
                // Invalid UTF-8 sequence
                return 0;
            }
            ret = (ret * 64) | (b & 0x3F);
        }

        return ret;
    }

    /*
     * @dev Returns the keccak-256 hash of the slice.
     * @param self The slice to hash.
     * @return The hash of the slice.
     */
    function keccak(slice memory self) internal pure returns (bytes32 ret) {
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }

    /*
     * @dev Returns true if `self` starts with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function startsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        if (self._ptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let selfptr := mload(add(self, 0x20))
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }
        return equal;
    }

    /*
     * @dev If `self` starts with `needle`, `needle` is removed from the
     *      beginning of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function beyond(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        bool equal = true;
        if (self._ptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let selfptr := mload(add(self, 0x20))
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
            self._ptr += needle._len;
        }

        return self;
    }

    /*
     * @dev Returns true if the slice ends with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function endsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        uint selfptr = self._ptr + self._len - needle._len;

        if (selfptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }

        return equal;
    }

    /*
     * @dev If `self` ends with `needle`, `needle` is removed from the
     *      end of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function until(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        uint selfptr = self._ptr + self._len - needle._len;
        bool equal = true;
        if (selfptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
        }

        return self;
    }

    // Returns the memory address of the first byte of the first occurrence of
    // `needle` in `self`, or the first byte after `self` if not found.
    function findPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr = selfptr;
        uint idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask;
                if (needlelen > 0) {
                    mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));
                }

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                uint end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr >= end)
                        return selfptr + selflen;
                    ptr++;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

    // Returns the memory address of the first byte after the last occurrence of
    // `needle` in `self`, or the address of `self` if not found.
    function rfindPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask;
                if (needlelen > 0) {
                    mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));
                }

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                ptr = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr <= selfptr)
                        return selfptr;
                    ptr--;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr + needlelen;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }
                ptr = selfptr + (selflen - needlelen);
                while (ptr >= selfptr) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr + needlelen;
                    ptr -= 1;
                }
            }
        }
        return selfptr;
    }

    /*
     * @dev Modifies `self` to contain everything from the first occurrence of
     *      `needle` to the end of the slice. `self` is set to the empty slice
     *      if `needle` is not found.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function find(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len -= ptr - self._ptr;
        self._ptr = ptr;
        return self;
    }

    /*
     * @dev Modifies `self` to contain the part of the string from the start of
     *      `self` to the end of the first occurrence of `needle`. If `needle`
     *      is not found, `self` is set to the empty slice.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function rfind(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len = ptr - self._ptr;
        return self;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and `token` to everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function split(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and returning everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` up to the first occurrence of `delim`.
     */
    function split(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        split(self, needle, token);
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and `token` to everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function rsplit(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = ptr;
        token._len = self._len - (ptr - self._ptr);
        if (ptr == self._ptr) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and returning everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` after the last occurrence of `delim`.
     */
    function rsplit(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        rsplit(self, needle, token);
    }

    /*
     * @dev Counts the number of nonoverlapping occurrences of `needle` in `self`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return The number of occurrences of `needle` found in `self`.
     */
    function count(slice memory self, slice memory needle) internal pure returns (uint cnt) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr = findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) + needle._len;
        }
    }

    /*
     * @dev Returns True if `self` contains `needle`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return True if `needle` is found in `self`, false otherwise.
     */
    function contains(slice memory self, slice memory needle) internal pure returns (bool) {
        return rfindPtr(self._len, self._ptr, needle._len, needle._ptr) != self._ptr;
    }

    /*
     * @dev Returns a newly allocated string containing the concatenation of
     *      `self` and `other`.
     * @param self The first slice to concatenate.
     * @param other The second slice to concatenate.
     * @return The concatenation of the two strings.
     */
    function concat(slice memory self, slice memory other) internal pure returns (string memory) {
        string memory ret = new string(self._len + other._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }

    /*
     * @dev Joins an array of slices, using `self` as a delimiter, returning a
     *      newly allocated string.
     * @param self The delimiter to use.
     * @param parts A list of slices to join.
     * @return A newly allocated string containing all the slices in `parts`,
     *         joined with `self`.
     */
    function join(slice memory self, slice[] memory parts) internal pure returns (string memory) {
        if (parts.length == 0)
            return "";

        uint length = self._len * (parts.length - 1);
        for(uint i = 0; i < parts.length; i++)
            length += parts[i]._len;

        string memory ret = new string(length);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        for(uint i = 0; i < parts.length; i++) {
            memcpy(retptr, parts[i]._ptr, parts[i]._len);
            retptr += parts[i]._len;
            if (i < parts.length - 1) {
                memcpy(retptr, self._ptr, self._len);
                retptr += self._len;
            }
        }

        return ret;
    }
}