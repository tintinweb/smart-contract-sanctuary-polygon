/**
 *Submitted for verification at polygonscan.com on 2023-07-06
*/

// Sources flattened with hardhat v2.15.0 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}


// File contracts/interfaces/IAddressRelay.sol

pragma solidity ^0.8.18;

    struct Implementation {
        address implAddress;
        bytes4[] selectors;
    }

interface IAddressRelay {
    /**
     * @notice Returns the fallback implementation address
     */
    function fallbackImplAddress() external returns (address);

    /**
     * @notice Adds or updates selectors and their implementation addresses
     * @param _selectors The selectors to add or update
     * @param _implAddress The implementation address the selectors will point to
     */
    function addOrUpdateSelectors(
        bytes4[] memory _selectors,
        address _implAddress
    ) external;

    /**
     * @notice Removes selectors
     * @param _selectors The selectors to remove
     */
    function removeSelectors(bytes4[] memory _selectors) external;

    /**
     * @notice Removes an implementation address and all the selectors that point to it
     * @param _implAddress The implementation address to remove
     */
    function removeImplAddressAndAllSelectors(address _implAddress) external;

    /**
     * @notice Returns the implementation address for a given function selector
     * @param _functionSelector The function selector to get the implementation address for
     */
    function getImplAddress(
        bytes4 _functionSelector
    ) external view returns (address implAddress_);

    /**
     * @notice Returns all the implementation addresses and the selectors they support
     * @return impls_ An array of Implementation structs
     */
    function getAllImplAddressesAndSelectors()
    external
    view
    returns (Implementation[] memory impls_);

    /**
     * @notice Return all the fucntion selectors associated with an implementation address
     * @param _implAddress The implementation address to get the selectors for
     */
    function getSelectorsForImplAddress(
        address _implAddress
    ) external view returns (bytes4[] memory selectors_);

    /**
     * @notice Sets the fallback implementation address to use when a function selector is not found
     * @param _fallbackAddress The fallback implementation address
     */
    function setFallbackImplAddress(address _fallbackAddress) external;

    /**
     * @notice Updates the supported interfaces
     * @param _interfaceId The interface ID to update
     * @param _supported Whether the interface is supported or not
     */
    function updateSupportedInterfaces(
        bytes4 _interfaceId,
        bool _supported
    ) external;

    /**
     * @notice Returns whether the interface is supported or not
     * @param _interfaceId The interface ID to check
     */
    function supportsInterface(
        bytes4 _interfaceId
    ) external view returns (bool);
}


// File contracts/libraries/DropuStorage.sol

pragma solidity 0.8.18;

    struct BaseConfig {
        // If true tokens can be minted in the public sale
        bool publicSaleActive;
        // If enabled, automatic start and stop times for the public sale will be enforced, otherwise ignored
        bool usePublicSaleTimes;
        // If true tokens can be minted in the presale
        bool presaleActive;
        // If enabled, automatic start and stop times for the presale will be enforced, otherwise ignored
        bool usePresaleTimes;
        // If true, all tokens will be soulbound
        bool soulbindingActive;
        // If true, a random hash will be generated for each token
        bool randomHashActive;
        // If true, the default CORI subscription address will be used to enforce royalties with the Operator Filter Registry
        bool enforceRoyalties;
        // If true, Dropu fees will be charged for minting tokens
        bool dropuFeeActive;
        // The number of tokens that can be minted in the public sale per address
        uint8 publicMintsAllowedPerAddress;
        // The number of tokens that can be minted in the presale per address
        uint8 presaleMintsAllowedPerAddress;
        // The number of tokens that can be minted in the public sale per transaction
        uint8 publicMintsAllowedPerTransaction;
        // The number of tokens that can be minted in the presale sale per transaction
        uint8 presaleMintsAllowedPerTransaction;
        // Maximum supply of tokens that can be minted
        uint16 maxSupply;
        // Total number of tokens available for minting in the presale
        uint16 presaleMaxSupply;
        // The royalty payout percentage in basis points
        uint16 royaltyBps;
        // The price of a token in the public sale in 1/100,000 ETH - e.g. 1 = 0.00001 ETH, 100,000 = 1 ETH - multiply by 10^13 to get correct wei amount
        uint32 publicPrice;
        // The price of a token in the presale in 1/100,000 ETH
        uint32 presalePrice;
        // Used to create a default Dropu Launchpad URI for token metadata to save gas over setting a custom URI and increase fetch reliability
        uint24 projectId;
        // The base URI for all token metadata
        string uriBase;
        // The address used to sign and validate presale mints
        address presaleSignerAddress;
        // The automatic start time for the public sale (if usePublicSaleTimes is true and publicSaleActive is true)
        uint32 publicSaleStartTime;
        // The automatic end time for the public sale (if usePublicSaleTimes is true and publicSaleActive is true)
        uint32 publicSaleEndTime;
        // The automatic start time for the presale (if usePresaleTimes is true and presaleActive is true)
        uint32 presaleStartTime;
        // The automatic end time for the presale (if usePresaleTimes is true and presaleActive is true)
        uint32 presaleEndTime;
        // If set, the UTC timestamp in seconds by which the fundingTarget must be met or funds are refundable
        uint32 fundingEndsAt;
        // The amount of centiETH that must be raised by fundingEndsAt or funds are refundable - multiply by 10^16
        uint32 fundingTarget;
    }

    struct AdvancedConfig {
        // When false, tokens cannot be staked but can still be unstaked
        bool stakingActive;
        // When false, tokens cannot be loaned but can still be retrieved
        bool loaningActive;
        // If true tokens can be claimed for free
        bool freeClaimActive;
        // The number of tokens that can be minted per free claim
        uint8 mintsPerFreeClaim;
        // Optional address of an NFT that is eligible for free claim
        address freeClaimContractAddress;
        // If true tokens can be burned in order to mint
        bool burnClaimActive;
        // If true, the original token id of a burned token will be used for metadata
        bool useBurnTokenIdForMetadata;
        // The number of tokens that can be minted per burn transaction
        uint8 mintsPerBurn;
        // The payment required alongside a burn transaction in order to mint in 1/100,000 ETH
        uint32 burnPayment;
        // Permanently freezes payout addresses and basis points so they can never be updated
        bool payoutAddressesFrozen;
        // If set, the UTC timestamp in seconds until which tokens are refundable for refundPrice
        uint32 refundEndsAt;
        // The amount returned to a user in a token refund in 1/100,000 ETH
        uint32 refundPrice;
        // Permanently freezes metadata so it can never be changed
        bool metadataFrozen;
        // If true the soulbind admin address is permanently disabled
        bool soulbindAdminTransfersPermanentlyDisabled;
        // If true deposit tokens can be burned in order to mint
        bool depositClaimActive;
        // If additional payment is required to mint, this is the amount required in centiETH
        uint32 remainingDepositPayment;
        // The deposit token smart contract address
        address depositContractAddress;
        // The merkle root used to validate if deposit tokens are eligible to burn to mint
        bytes32 depositMerkleRoot;
        // The respective share of funds to be sent to each address in payoutAddresses in basis points
        uint16[] payoutBasisPoints;
        // The addresses to which funds are sent when a token is sold. If empty, funds are sent to the contract owner.
        address[] payoutAddresses;
        // Optional address where royalties are paid out. If not set, royalties are paid to the contract owner.
        address royaltyPayoutAddress;
        // Used to allow transferring soulbound tokens with admin privileges. Defaults to the contract owner if not set.
        address soulboundAdminAddress;
        // The address where refunded tokens are returned. If not set, refunded tokens are sent to the contract owner.
        address refundAddress;
        // An address authorized to call the creditCardMint function.
        address creditCardMintAddress;
    }

    struct BurnToken {
        // The contract address of the token to be burned
        address contractAddress;
        // The type of contract - 1 = ERC-721, 2 = ERC-1155
        uint8 tokenType;
        // The number of tokens to burn per mint
        uint8 tokensPerBurn;
        // The ID of the token on an ERC-1155 contract eligible for burn; unused for ERC-721
        uint16 tokenId;
    }

    struct Data {
        // ============ BASE FUNCTIONALITY ============
        // Dropu fee to be paid per minted token (if not set, defaults to defaultDropuFeePerToken)
        uint256 dropuFeePerToken;
        // Keeps track of if advanced config settings have been initialized to prevent setting multiple times
        bool advancedConfigInitialized;
        // A mapping of token IDs to specific tokenURIs for tokens that have custom metadata
        mapping(uint256 => string) tokenURIs;
        // ============ CONDITIONAL FUNDING ============
        // If true, the funding target was reached and funds are not refundable
        bool fundingTargetReached;
        // If true, funding success has been determined and determineFundingSuccess() can no longer be called
        bool fundingSuccessDetermined;
        // A mapping of token ID to price paid for the token
        mapping(uint256 => uint256) pricePaid;
        // ============ SOULBINDING ============
        // Used to allow an admin to transfer soulbound tokens when necessary
        bool soulboundAdminTransferInProgress;
        // ============ BURN TO MINT ============
        // Maps a token id to the burn token id that was used to mint it to match metadata
        mapping(uint256 => uint256) tokenIdToBurnTokenId;
        // ============ STAKING ============
        // Used to allow direct transfers of staked tokens without unstaking first
        bool stakingTransferActive;
        // Returns the UNIX timestamp at which a token began staking if currently staked
        mapping(uint256 => uint256) currentTimeStaked;
        // Returns the total time a token has been staked in seconds, not counting the current staking time if any
        mapping(uint256 => uint256) totalTimeStaked;
        // ============ LOANING ============
        // Used to keep track of the total number of tokens on loan
        uint256 currentLoanTotal;
        // Returns the total number of tokens loaned by an address
        mapping(address => uint256) totalLoanedPerAddress;
        // Returns the address of the original token owner if a token is currently on loan
        mapping(uint256 => address) tokenOwnersOnLoan;
        // ============ FREE CLAIM ============
        // If true token has already been used to claim and cannot be used again
        mapping(uint256 => bool) freeClaimUsed;
        // ============ RANDOM HASH ============
        // Stores a random hash for each token ID
        mapping(uint256 => bytes32) randomHashStore;
    }

library DropuStorage {
    struct State {
        BaseConfig cfg;
        AdvancedConfig advCfg;
        BurnToken[] burnTokens;
        Data data;
    }

    bytes32 internal constant STORAGE_SLOT =
    keccak256("dropu.launchpad.storage.erc721a");

    function state() internal pure returns (State storage s) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }
}


// File contracts/_17.sol

pragma solidity 0.8.18;



//
// 17。1 - generated with http://localhost:3000
//

contract _17 {
    bytes32 internal constant _IMPLEMENTATION_SLOT =
    0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    bytes32 internal constant _ADDRESS_RELAY_SLOT =
    keccak256("dropu.launchpad.addressRelay");

    /**
     * @notice Initializes the child contract with the base implementation address and the configuration settings
     * @param _name The name of the NFT
     * @param _symbol The symbol of the NFT
     * @param _baseConfig Base configuration settings
     */
    constructor(
        string memory _name,
        string memory _symbol,
        address _addressRelay,
        address _implementation,
        BaseConfig memory _baseConfig
    ) {
        StorageSlot
        .getAddressSlot(_IMPLEMENTATION_SLOT)
        .value = _implementation;
        StorageSlot.getAddressSlot(_ADDRESS_RELAY_SLOT).value = _addressRelay;
        IAddressRelay addressRelay = IAddressRelay(
            StorageSlot.getAddressSlot(_ADDRESS_RELAY_SLOT).value
        );
        address implContract = addressRelay.fallbackImplAddress();
        (bool success, ) = implContract.delegatecall(
            abi.encodeWithSelector(0x35a825b0, _name, _symbol, _baseConfig)
        );
        require(success);
    }

    /**
     * @dev Delegates the current call to nftImplementation
     *
     * This function does not return to its internal call site - it will return directly to the external caller.
     */
    fallback() external payable {
        IAddressRelay addressRelay = IAddressRelay(
            StorageSlot.getAddressSlot(_ADDRESS_RELAY_SLOT).value
        );
        address implContract = addressRelay.getImplAddress(msg.sig);

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(
            gas(),
            implContract,
            0,
            calldatasize(),
            0,
            0
            )
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}
}