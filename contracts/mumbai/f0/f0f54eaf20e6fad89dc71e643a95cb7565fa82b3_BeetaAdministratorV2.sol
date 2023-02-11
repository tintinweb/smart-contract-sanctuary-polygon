// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "./openzeppalin-utils/EIP712.sol";
import "./interfaces/IRewardNFT.sol";
import "./interfaces/ISzeetaEventRewards.sol";
import "./interfaces/IFactory.sol";

/**
 * @dev Contract manages event information throughout all supported networks.
 *
 * Contract stores the network specific event data.
 *
 * Contract also manages all the admin functions that mainly include manipulating sensitive
 * data of an event such as the receiving address by the user. All admin interactions require
 * the event owner to sign the required data and call the contract through the organization's private
 * key to enable gasless transactions.
 *
 * Contract also keeps track of all the contributions received by dumping transasction data into the blockchain.
 *
 * Last and the main functionality of the contract is handling NFT rewards that include initiating
 * new instances, minting and managing ownership throughout the lifetime of the event.
 *
 * All the mutations restricted for the Creator are done by the governor.
 */
contract BeetaAdministratorV2 is EIP712{
    /**
     * @dev Address of the organization.
     */
    address public org;

    /** 
     * @dev Address of the Custom NFT Factory.
     */
    address public factory;

    /**
     * @dev Address of the governor.
     */
    address public governor;

    /**
     * @dev Event ids are assigned by an incremented state variable. 
     */
    uint256 public eventCounter;

    /**
     * @dev Method used to calculate the fee
     * When the amount is divided by the fee factor, the quotient will be the fee.
     * Example: If the fee is 1%, feeFactor will be 100.
     */
    uint256 public feeFactor;

    /**
     * @dev Address of the public NFT collection for event Rewards.
     */
    address public publicCollectionAddress;

    /**
     * @dev For getting network information required when creating an event.
     * Contains the chain id and the receiving address of the specific network.
     */
    struct ChainData{
        uint256 netId;
        address receiver;
    }

    /**
     * @dev used for validating data with EIP712 signature type when receiving
     * token contributions.
     */
    struct AdminCall{
        string cause;
        address caller;
        uint256 eventId;
        uint256 nonce;
    }

    /**
     *@dev Typehash of the structs to be used in the validation process mentioned above.
     */
    bytes32 private constant adminTypeHash =
        keccak256(
            'AdminCall(string cause,address caller,uint256 eventId,uint256 nonce)'
        );

/**
 * @dev receivers mapping keep track of the receiving addresses related to events
 * where network is mapped to event id that is mapped to receiving address.
 */
    mapping(uint256 => mapping(uint256 => address)) public receivers;

    /**
     * @dev Records the owners of the event.
     */
    mapping(uint256 => address) public owners;

    /**
     * @dev Keeps track of the closed and opened state of an event.
     */
    mapping(uint256 => bool) public closed;

    /**
     * @dev Keeps in-track of the custom NFT contracts created by the events
     * for rewards.
     */
    mapping(uint256 => address) public customCollections;

    /**
     * @dev Keeps track of the processed transactions.
     */
    mapping(uint256 => bool) private isExpired;

    // events
    event EventCreated(
        uint256 indexed eventId,
        address indexed owner,
        ChainData[] data
    );

    event EventTransfered(
        uint256 indexed eventId,
        address indexed newOwner,
        address exOwner
    );

    event EventClosed(
        address indexed owner,
        uint256 eventId,
        uint256 time
    );

    event ReceiverChanged(
        address indexed newReceiver,
        uint256 indexed network,
        uint256 eventId
    );

    event NFTMinted(
        uint256 indexed eventId,
        address indexed contributor,
        address indexed collection
    );

    event NativeContribution(
        uint256 indexed eventId,
        uint256 indexed network,
        address receiver,
        uint256 amount
    );

    event TokenContribution(
        uint256 indexed eventId,
        uint256 indexed network,
        address indexed token,
        address receiver,
        uint256 amount
    );

    // modifiers
    modifier onlyOrg(){
      require(msg.sender == org, "Unauthorized call!");
      _;
    }

    modifier onlyGovernor(){
      require(msg.sender == governor, "Unauthorized call!");
      _;
    }

    constructor(uint feeFactor_, address org_, address governor_) EIP712('szeeta', '0.0.1'){
        feeFactor = feeFactor_;
        org = org_;
        governor = governor_;
        eventCounter = 1;
    }

    /**
     * @dev Events are created by assigning an event id.
     *
     * @param owner Address of the event owner. Only the owner can manipulate the event data by calling
     * the contract through the organization's private key.
     * @param chainData Array of ChainData. The creator must at least select one supported network to create an event.
     */
    function createEvent(address owner, ChainData[] memory chainData) external onlyOrg returns(uint){
        require(chainData.length != 0, "Chain Data Empty!");

        /**
         * @dev Assigning event id to a local variable to save gas
         */
        uint eventId = eventCounter;
        owners[eventId] = owner;
        for(uint i; i<chainData.length;){
            ChainData memory data = chainData[i];
            receivers[data.netId][eventId] = data.receiver;
            unchecked{
                i++;
            }
        }
        eventCounter ++;

        emit EventCreated(eventId, owner, chainData);
        return eventId;
    }

    // Functions of event administration

    /**
     * @dev Function to change the receiver of an event specific to the network.
     */
    function changeReceiver(
        address newReceiver,
        string memory cause,
        uint256 chainId, 
        address caller, 
        uint256 eventId,
        uint nonce,
        bytes calldata signature
    ) 
        external 
        onlyOrg
    {
        authorizedAndOpen(cause, caller, eventId, nonce, signature);
        receivers[chainId][eventId] = newReceiver;

        emit ReceiverChanged(newReceiver, chainId, eventId);
    }

    /**
     * @dev Function close an event
     *
     * NOTE: ONCE CLOSED AN EVENT CAN NOT BE RE-OPENED
     */
    function close(
        string memory cause,
        address caller,
        uint256 eventId,
        uint256 nonce,
        bytes calldata signature,
        address nftContract
    )
        external
        onlyOrg
    {   
        authorizedAndOpen(cause, caller, eventId, nonce, signature);
        if(nftContract != address(0)){
            IRewardNFT(nftContract).close();
        }
        closed[eventId] = true;

        emit EventClosed(caller, eventId, block.timestamp);
    }

    /**
     * @dev Function to transfer ownership of an event
     */
    function transferAuthority(
        address newOwner,
        string memory cause,
        address caller,
        uint256 eventId,
        uint256 nonce,
        bytes calldata signature
    )
        external
        onlyOrg
    {
        authorizedAndOpen(cause, caller, eventId, nonce, signature);
        address nftContract = customCollections[eventId];
        if(nftContract != address(0)){
            IRewardNFT(nftContract).transferOwnership(newOwner);
        }
        owners[eventId] = newOwner;

        emit EventTransfered(eventId, newOwner, caller);
    }

    /**
     * @dev Emits an event to dump the native contribution receieved by the event to the blockchain.
     */
    function recordNativeContribution(uint eventId, uint amount, uint netId) external onlyOrg{
        emit NativeContribution(eventId, netId, receivers[netId][eventId], amount);
    }

    /**
     * @dev Emits an event to dump the token contribution receieved by the event to the blockchain.
     */
    function recordTokenContribution(uint eventId, uint amount, uint netId, address token) external onlyOrg{
        emit TokenContribution(eventId, netId, token, receivers[netId][eventId], amount);
    }

    // NFT interaction

    /**
     * @dev Function to add the public NFT collection address after minting the contract.
     */
    function addPublicCollectionAddress(address collectionAddress) external onlyGovernor{
        publicCollectionAddress = collectionAddress;
    }

    /**
     * @dev Function to add the custom NFT factory address.
     */
    function addCollectionFactory(address factoryAddress) external onlyGovernor{
        factory = factoryAddress;
    }

    /**
     * @dev Function mints a new custom NFT collection for event rewards.
     */
    function createCustomCollection(
        address eventOwner,
        uint256 eventId,
        string memory name, 
        string memory symbol,
        string memory uri
    ) 
        external
        onlyOrg
        returns(address)
    {
        require(customCollections[eventId] == address(0), "Collection Already Created!");
        // deploying the new NFT collection
        address contractAddress =  IFactory(factory).mintCollection(eventOwner, name, symbol, uri);
        customCollections[eventId] = contractAddress;

        return contractAddress;
    }

    function authorizedAndOpen(string memory cause, address caller, uint eventId, uint256 nonce, bytes calldata signature) internal{
        require(!closed[eventId] ,"Event closed!");
        require(owners[eventId] == caller,"Unauthorized Call!");
        require(!isExpired[nonce], "Transaction Expired!");
        bytes32 typedDataHash = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    adminTypeHash,
                    keccak256(abi.encodePacked(cause)),
                    caller,
                    eventId,
                    nonce
                )
            )
        );
        address caller_ = ECDSA.recover(typedDataHash, signature);
        require(caller == caller_, "Fake Signature!");

        isExpired[nonce] = true;
    }

    // For organizational use

    /**
     * @dev restricted function to change organization address.
     */
    function changeOrg(address newOrg) external onlyGovernor{
        org = newOrg;
    }

    /**
     * @dev restricted function to change governor address.
     */
    function changeGovernor(address newGovernor) external onlyGovernor{
        governor = newGovernor;
    }

    /**
     * @dev Function for changing the fee factor.
     */
    function changeFeeFactor(uint newFeeFactor) external onlyGovernor{
        feeFactor = newFeeFactor;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

interface IFactory{
    function mintCollection( address eventOwner, string memory name, string memory symbol, string memory uri) external returns(address);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

interface IRewardNFT{
    function close() external;
    function mint(address contributor) external returns(uint256);
    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

interface ISzeetaEventRewards{
    function mint(address contributor, uint eventId) external returns(uint256); 
    function addEventUri(uint eventId, string memory metadataUri) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}