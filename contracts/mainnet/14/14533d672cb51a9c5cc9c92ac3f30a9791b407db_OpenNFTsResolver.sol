// SPDX-License-Identifier: MIT
//
// EIP-165: Standard Interface Detection
// https://eips.ethereum.org/EIPS/eip-165
//
// Derived from OpenZeppelin Contracts (utils/introspection/ERC165.sol)
// https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/utils/introspection/ERC165.sol
//
//       ___           ___         ___           ___              ___           ___                     ___
//      /  /\         /  /\       /  /\         /__/\            /__/\         /  /\        ___        /  /\
//     /  /::\       /  /::\     /  /:/_        \  \:\           \  \:\       /  /:/_      /  /\      /  /:/_
//    /  /:/\:\     /  /:/\:\   /  /:/ /\        \  \:\           \  \:\     /  /:/ /\    /  /:/     /  /:/ /\
//   /  /:/  \:\   /  /:/~/:/  /  /:/ /:/_   _____\__\:\      _____\__\:\   /  /:/ /:/   /  /:/     /  /:/ /::\
//  /__/:/ \__\:\ /__/:/ /:/  /__/:/ /:/ /\ /__/::::::::\    /__/::::::::\ /__/:/ /:/   /  /::\    /__/:/ /:/\:\
//  \  \:\ /  /:/ \  \:\/:/   \  \:\/:/ /:/ \  \:\~~\~~\/    \  \:\~~\~~\/ \  \:\/:/   /__/:/\:\   \  \:\/:/~/:/
//   \  \:\  /:/   \  \::/     \  \::/ /:/   \  \:\  ~~~      \  \:\  ~~~   \  \::/    \__\/  \:\   \  \::/ /:/
//    \  \:\/:/     \  \:\      \  \:\/:/     \  \:\           \  \:\        \  \:\         \  \:\   \__\/ /:/
//     \  \::/       \  \:\      \  \::/       \  \:\           \  \:\        \  \:\         \__\/     /__/:/
//      \__\/         \__\/       \__\/         \__\/            \__\/         \__\/                   \__\/
//
//  OpenERC165 —— IERC165
//
pragma solidity ^0.8.17;

import "OpenNFTs/contracts/interfaces/IERC165.sol";

abstract contract OpenERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == 0x01ffc9a7; //  type(IERC165).interfaceId
    }
}

// SPDX-License-Identifier: MIT
//
// EIP-173: Contract Ownership Standard
// https://eips.ethereum.org/EIPS/eip-173
//
// Derived from OpenZeppelin Contracts (access/Ownable.sol)
// https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/access/Ownable.sol
//
//       ___           ___         ___           ___              ___           ___                     ___
//      /  /\         /  /\       /  /\         /__/\            /__/\         /  /\        ___        /  /\
//     /  /::\       /  /::\     /  /:/_        \  \:\           \  \:\       /  /:/_      /  /\      /  /:/_
//    /  /:/\:\     /  /:/\:\   /  /:/ /\        \  \:\           \  \:\     /  /:/ /\    /  /:/     /  /:/ /\
//   /  /:/  \:\   /  /:/~/:/  /  /:/ /:/_   _____\__\:\      _____\__\:\   /  /:/ /:/   /  /:/     /  /:/ /::\
//  /__/:/ \__\:\ /__/:/ /:/  /__/:/ /:/ /\ /__/::::::::\    /__/::::::::\ /__/:/ /:/   /  /::\    /__/:/ /:/\:\
//  \  \:\ /  /:/ \  \:\/:/   \  \:\/:/ /:/ \  \:\~~\~~\/    \  \:\~~\~~\/ \  \:\/:/   /__/:/\:\   \  \:\/:/~/:/
//   \  \:\  /:/   \  \::/     \  \::/ /:/   \  \:\  ~~~      \  \:\  ~~~   \  \::/    \__\/  \:\   \  \::/ /:/
//    \  \:\/:/     \  \:\      \  \:\/:/     \  \:\           \  \:\        \  \:\         \  \:\   \__\/ /:/
//     \  \::/       \  \:\      \  \::/       \  \:\           \  \:\        \  \:\         \__\/     /__/:/
//      \__\/         \__\/       \__\/         \__\/            \__\/         \__\/                   \__\/
//
//  OpenERC165
//       |
//  OpenERC173 —— IERC173
//
pragma solidity ^0.8.17;

import "OpenNFTs/contracts/OpenERC/OpenERC165.sol";
import "OpenNFTs/contracts/interfaces/IERC173.sol";

abstract contract OpenERC173 is IERC173, OpenERC165 {
    bool private _openERC173Initialized;
    address private _owner;

    modifier onlyOwner() {
        require(_owner == msg.sender, "Not owner");
        _;
    }

    function transferOwnership(address newOwner) external override(IERC173) onlyOwner {
        _transferOwnership(newOwner);
    }

    function owner() public view override(IERC173) returns (address) {
        return _owner;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(OpenERC165)
        returns (bool)
    {
        return interfaceId == 0x7f5828d0 || super.supportsInterface(interfaceId);
    }

    function _initialize(address owner_) internal {
        require(_openERC173Initialized == false, "Already initialized");
        _openERC173Initialized = true;

        _transferOwnership(owner_);
    }

    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
//
// Derived from OpenZeppelin Contracts (utils/introspection/ERC165Ckecker.sol)
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/ERC165Checker.sol
//
//       ___           ___         ___           ___              ___           ___                     ___
//      /  /\         /  /\       /  /\         /__/\            /__/\         /  /\        ___        /  /\
//     /  /::\       /  /::\     /  /:/_        \  \:\           \  \:\       /  /:/_      /  /\      /  /:/_
//    /  /:/\:\     /  /:/\:\   /  /:/ /\        \  \:\           \  \:\     /  /:/ /\    /  /:/     /  /:/ /\
//   /  /:/  \:\   /  /:/~/:/  /  /:/ /:/_   _____\__\:\      _____\__\:\   /  /:/ /:/   /  /:/     /  /:/ /::\
//  /__/:/ \__\:\ /__/:/ /:/  /__/:/ /:/ /\ /__/::::::::\    /__/::::::::\ /__/:/ /:/   /  /::\    /__/:/ /:/\:\
//  \  \:\ /  /:/ \  \:\/:/   \  \:\/:/ /:/ \  \:\~~\~~\/    \  \:\~~\~~\/ \  \:\/:/   /__/:/\:\   \  \:\/:/~/:/
//   \  \:\  /:/   \  \::/     \  \::/ /:/   \  \:\  ~~~      \  \:\  ~~~   \  \::/    \__\/  \:\   \  \::/ /:/
//    \  \:\/:/     \  \:\      \  \:\/:/     \  \:\           \  \:\        \  \:\         \  \:\   \__\/ /:/
//     \  \::/       \  \:\      \  \::/       \  \:\           \  \:\        \  \:\         \__\/     /__/:/
//      \__\/         \__\/       \__\/         \__\/            \__\/         \__\/                   \__\/
//
//   OpenERC165
//        |
//  OpenChecker —— IOpenChecker
//
pragma solidity ^0.8.17;

import "OpenNFTs/contracts/OpenERC/OpenERC165.sol";
import "OpenNFTs/contracts/interfaces/IOpenChecker.sol";

abstract contract OpenChecker is IOpenChecker, OpenERC165 {
    /// 0xffffffff :  O Invalid
    /// 0x01ffc9a7 :  1 ERC165
    /// 0x80ac58cd :  2 ERC721
    /// 0x5b5e139f :  3 ERC721Metadata
    /// 0x780e9d63 :  4 ERC721Enumerable
    /// 0x150b7a02 :  5 ERC721TokenReceiver
    /// 0xd9b67a26 :  6 ERC1155
    /// 0x0e89341c :  7 ERC1155MetadataURI
    /// 0x4e2312e0 :  8 ERC1155TokenReceiver
    /// 0x7f5828d0 :  9 ERC173
    /// 0x2a55205a : 10 ERC2981
    bytes4[] private _ercInterfaceIds = [
        bytes4(0xffffffff),
        bytes4(0x01ffc9a7),
        bytes4(0x80ac58cd),
        bytes4(0x5b5e139f),
        bytes4(0x780e9d63),
        bytes4(0x150b7a02),
        bytes4(0xd9b67a26),
        bytes4(0x0e89341c),
        bytes4(0x4e2312e0),
        bytes4(0x7f5828d0),
        bytes4(0x2a55205a)
    ];
    uint8 private constant _INVALID = 0;
    uint8 private constant _ERC165 = 1;
    uint8 private constant _ERC721 = 2;
    uint8 private constant _ERC1155 = 6;

    modifier onlyContract(address account) {
        require(account.code.length > 0, "Not smartcontract");
        _;
    }

    function isCollections(address[] memory smartcontracts)
        public
        view
        override(IOpenChecker)
        returns (bool[] memory checks)
    {
        uint256 len = smartcontracts.length;
        checks = new bool[](len);

        for (uint256 i = 0; i < len; i++) {
            checks[i] = isCollection(smartcontracts[i]);
        }
    }

    // TODO check only 4 interfaces
    function isCollection(address smartcontract)
        public
        view
        override(IOpenChecker)
        onlyContract(smartcontract)
        returns (bool)
    {
        bool[] memory checks = checkErcInterfaces(smartcontract);

        // (!INVALID and ERC165) and (ERC721 or ERC1155)
        return !checks[_INVALID] && checks[_ERC165] && (checks[_ERC721] || checks[_ERC1155]);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(OpenERC165)
        returns (bool)
    {
        return interfaceId == type(IOpenChecker).interfaceId || super.supportsInterface(interfaceId);
    }

    function checkErcInterfaces(address smartcontract)
        public
        view
        override(IOpenChecker)
        returns (bool[] memory)
    {
        return checkSupportedInterfaces(smartcontract, true, new bytes4[](0));
    }

    function checkSupportedInterfaces(address smartcontract, bool erc, bytes4[] memory interfaceIds)
        public
        view
        override(IOpenChecker)
        onlyContract(smartcontract)
        returns (bool[] memory interfaceIdsChecks)
    {
        uint256 len1 = _ercInterfaceIds.length;
        uint256 len2 = interfaceIds.length;
        uint256 len = (erc ? len1 : 0) + len2;
        uint256 i;

        interfaceIdsChecks = new bool[](len);

        if (erc) {
            for (uint256 j = 0; j < len1; j++) {
                interfaceIdsChecks[i++] =
                    IERC165(smartcontract).supportsInterface(_ercInterfaceIds[j]);
            }
        }
        for (uint256 k = 0; k < len2; k++) {
            interfaceIdsChecks[i++] = IERC165(smartcontract).supportsInterface(interfaceIds[k]);
        }
    }
}

// SPDX-License-Identifier: MIT
//
//
//       ___           ___         ___           ___              ___           ___                     ___
//      /  /\         /  /\       /  /\         /__/\            /__/\         /  /\        ___        /  /\
//     /  /::\       /  /::\     /  /:/_        \  \:\           \  \:\       /  /:/_      /  /\      /  /:/_
//    /  /:/\:\     /  /:/\:\   /  /:/ /\        \  \:\           \  \:\     /  /:/ /\    /  /:/     /  /:/ /\
//   /  /:/  \:\   /  /:/~/:/  /  /:/ /:/_   _____\__\:\      _____\__\:\   /  /:/ /:/   /  /:/     /  /:/ /::\
//  /__/:/ \__\:\ /__/:/ /:/  /__/:/ /:/ /\ /__/::::::::\    /__/::::::::\ /__/:/ /:/   /  /::\    /__/:/ /:/\:\
//  \  \:\ /  /:/ \  \:\/:/   \  \:\/:/ /:/ \  \:\~~\~~\/    \  \:\~~\~~\/ \  \:\/:/   /__/:/\:\   \  \:\/:/~/:/
//   \  \:\  /:/   \  \::/     \  \::/ /:/   \  \:\  ~~~      \  \:\  ~~~   \  \::/    \__\/  \:\   \  \::/ /:/
//    \  \:\/:/     \  \:\      \  \:\/:/     \  \:\           \  \:\        \  \:\         \  \:\   \__\/ /:/
//     \  \::/       \  \:\      \  \::/       \  \:\           \  \:\        \  \:\         \__\/     /__/:/
//      \__\/         \__\/       \__\/         \__\/            \__\/         \__\/                   \__\/
//
//   OpenChecker
//        |
//  OpenGetter —— IOpenGetter
//
pragma solidity ^0.8.17;

import "OpenNFTs/contracts/OpenResolver/OpenChecker.sol";
import "OpenNFTs/contracts/interfaces/IOpenGetter.sol";
import "OpenNFTs/contracts/interfaces/IERC721.sol";
import "OpenNFTs/contracts/interfaces/IERC721Metadata.sol";
import "OpenNFTs/contracts/interfaces/IERC721Enumerable.sol";
import "OpenNFTs/contracts/interfaces/IERC1155.sol";
import "OpenNFTs/contracts/interfaces/IERC1155MetadataURI.sol";
import "OpenNFTs/contracts/interfaces/IERC165.sol";
import "OpenNFTs/contracts/interfaces/IERC173.sol";

abstract contract OpenGetter is IOpenGetter, OpenChecker {
    uint8 private constant _INVALID = 0;
    uint8 private constant _ERC165 = 1;
    uint8 private constant _ERC721 = 2;
    uint8 private constant _ERC721_ENUMERABLE = 2;
    uint8 private constant _ERC1155 = 6;
    bytes4 private constant _ERC721_ID = 0x80ac58cd;
    bytes4 private constant _ERC1155_ID = 0xd9b67a26;
    bytes4 private constant _ERC721_METADATA_ID = 0x5b5e139f;
    bytes4 private constant _ERC1155_METADATA_URI_ID = 0x0e89341c;

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(OpenChecker)
        returns (bool)
    {
        return interfaceId == type(IOpenGetter).interfaceId || super.supportsInterface(interfaceId);
    }

    function getCollectionInfos(address collection, address account)
        public
        view
        override(IOpenGetter)
        returns (
            // override(IOpenGetter)
            CollectionInfos memory collectionInfos
        )
    {
        collectionInfos = _getCollectionInfos(collection, account, new bytes4[](0));
    }

    function getNftsInfos(address collection, uint256[] memory tokenIDs, address account)
        public
        view
        override(IOpenGetter)
        returns (NftInfos[] memory nftsInfos)
    {
        uint256 len = tokenIDs.length;
        nftsInfos = new NftInfos[](len);
        for (uint256 i; i < len; i++) {
            nftsInfos[i] = _getNftInfos(collection, tokenIDs[i], account);
        }
    }

    function getNftsInfos(address collection, address account, uint256 limit, uint256 offset)
        public
        view
        override(IOpenGetter)
        returns (NftInfos[] memory nftsInfos, uint256 count, uint256 total)
    {
        bool[] memory supported = checkErcInterfaces(collection);

        // IF ERC721 & ERC721Enumerable supported
        if (supported[_ERC721] && supported[_ERC721_ENUMERABLE]) {
            if (account == address(0)) {
                total = IERC721Enumerable(collection).totalSupply();

                require(offset <= total, "Invalid offset");
                count = (offset + limit <= total) ? limit : total - offset;

                nftsInfos = new NftInfos[](count);
                for (uint256 i; i < count; i++) {
                    nftsInfos[i] = _getNftInfos(
                        collection, IERC721Enumerable(collection).tokenByIndex(offset + i), account
                    );
                }
            } else {
                total = IERC721(collection).balanceOf(account);

                require(offset <= total, "Invalid offset");
                count = (offset + limit <= total) ? limit : total - offset;

                nftsInfos = new NftInfos[](count);
                for (uint256 i; i < count; i++) {
                    nftsInfos[i] = _getNftInfos(
                        collection,
                        IERC721Enumerable(collection).tokenOfOwnerByIndex(account, offset + i),
                        account
                    );
                }
            }
        }
    }

    function getNftInfos(address collection, uint256 tokenID, address account)
        public
        view
        override(IOpenGetter)
        returns (NftInfos memory nftInfos)
    {
        return _getNftInfos(collection, tokenID, account);
    }

    function _getNftInfos(address collection, uint256 tokenID, address account)
        internal
        view
        onlyContract(collection)
        returns (NftInfos memory nftInfos)
    {
        nftInfos.tokenID = tokenID;

        if (IERC165(collection).supportsInterface(_ERC721_ID)) {
            try IERC721(collection).ownerOf(tokenID) returns (address owner) {
                nftInfos.owner = owner;
            } catch {}

            // tokenID exists <=> owner != 0
            if (nftInfos.owner != address(0)) {
                nftInfos.approved = IERC721(collection).getApproved(tokenID);
                if (IERC165(collection).supportsInterface(_ERC721_METADATA_ID)) {
                    nftInfos.tokenURI = IERC721Metadata(collection).tokenURI(tokenID);
                }
            }
        } else if (IERC165(collection).supportsInterface(_ERC1155_ID)) {
            if (account != address(0)) {
                nftInfos.balanceOf = IERC1155(collection).balanceOf(account, tokenID);
            }
            if (IERC165(collection).supportsInterface(_ERC1155_METADATA_URI_ID)) {
                nftInfos.tokenURI = IERC1155MetadataURI(collection).uri(tokenID);
            }
        }
    }

    function _getCollectionInfos(address collection, address account, bytes4[] memory interfaceIds)
        internal
        view
        onlyContract(collection)
        returns (CollectionInfos memory collectionInfos)
    {
        bool[] memory supported = checkSupportedInterfaces(collection, true, interfaceIds);
        collectionInfos.supported = supported;

        // ERC165 must be supported
        require(!supported[_INVALID] && supported[_ERC165], "Not ERC165");

        // ERC721 or ERC1155 must be supported
        require(supported[_ERC721] || supported[_ERC1155], "Not NFT smartcontract");

        collectionInfos.collection = collection;

        // try ERC173 owner
        try IERC173(collection).owner() returns (address owner) {
            collectionInfos.owner = owner;
        } catch {}

        // try ERC721Metadata name
        try IERC721Metadata(collection).name() returns (string memory name) {
            collectionInfos.name = name;
        } catch {}

        // try ERC721Metadata symbol
        try IERC721Metadata(collection).symbol() returns (string memory symbol) {
            collectionInfos.symbol = symbol;
        } catch {}

        // try ERC721Enumerable totalSupply
        try IERC721Enumerable(collection).totalSupply() returns (uint256 totalSupply) {
            collectionInfos.totalSupply = totalSupply;
        } catch {}

        if (account != address(0)) {
            try IERC721(collection).balanceOf(account) returns (uint256 balanceOf) {
                collectionInfos.balanceOf = balanceOf;
            } catch {}

            try IERC721(collection).isApprovedForAll(account, collection) returns (
                bool approvedForAll
            ) {
                collectionInfos.approvedForAll = approvedForAll;
            } catch {}
        }
    }
}

// SPDX-License-Identifier: MIT
//
// Derived from Kredeum NFTs
// https://github.com/Kredeum/kredeum
//
//       ___           ___         ___           ___              ___           ___                     ___
//      /  /\         /  /\       /  /\         /__/\            /__/\         /  /\        ___        /  /\
//     /  /::\       /  /::\     /  /:/_        \  \:\           \  \:\       /  /:/_      /  /\      /  /:/_
//    /  /:/\:\     /  /:/\:\   /  /:/ /\        \  \:\           \  \:\     /  /:/ /\    /  /:/     /  /:/ /\
//   /  /:/  \:\   /  /:/~/:/  /  /:/ /:/_   _____\__\:\      _____\__\:\   /  /:/ /:/   /  /:/     /  /:/ /::\
//  /__/:/ \__\:\ /__/:/ /:/  /__/:/ /:/ /\ /__/::::::::\    /__/::::::::\ /__/:/ /:/   /  /::\    /__/:/ /:/\:\
//  \  \:\ /  /:/ \  \:\/:/   \  \:\/:/ /:/ \  \:\~~\~~\/    \  \:\~~\~~\/ \  \:\/:/   /__/:/\:\   \  \:\/:/~/:/
//   \  \:\  /:/   \  \::/     \  \::/ /:/   \  \:\  ~~~      \  \:\  ~~~   \  \::/    \__\/  \:\   \  \::/ /:/
//    \  \:\/:/     \  \:\      \  \:\/:/     \  \:\           \  \:\        \  \:\         \  \:\   \__\/ /:/
//     \  \::/       \  \:\      \  \::/       \  \:\           \  \:\        \  \:\         \__\/     /__/:/
//      \__\/         \__\/       \__\/         \__\/            \__\/         \__\/                   \__\/
//
//   OpenERC165
//        |
//   OpenERC173
//        |
//  OpenRegistry —— IOpenRegistry
//
pragma solidity ^0.8.17;

import "OpenNFTs/contracts/OpenERC/OpenERC173.sol";
import "OpenNFTs/contracts/interfaces/IOpenRegistry.sol";

abstract contract OpenRegistry is IOpenRegistry, OpenERC173 {
    mapping(address => uint256) private _numAddress;
    address[] private _addresses;
    address public registerer;

    /// @notice onlyRegisterer, by default owner is registerer and can add addresses, can be overriden
    modifier onlyRegisterer() virtual {
        require(msg.sender == owner() || msg.sender == registerer, "Not registerer nor owner");
        _;
    }

    /// @notice isValid, by default all addresses valid
    modifier onlyValid(address) virtual {
        _;
    }

    function setRegisterer(address registerer_) external override(IOpenRegistry) onlyOwner {
        _setRegisterer(registerer_);
    }

    function addAddresses(address[] memory addrs) external override(IOpenRegistry) {
        uint256 len = addrs.length;
        for (uint256 i = 0; i < len; i++) {
            _addAddress(addrs[i]);
        }
    }

    function addAddress(address addr) external override(IOpenRegistry) {
        _addAddress(addr);
    }

    function removeAddress(address addr) external override(IOpenRegistry) {
        _removeAddress(addr);
    }

    function countAddresses() external view override(IOpenRegistry) returns (uint256) {
        return _addresses.length;
    }

    function isRegistered(address addr) public view returns (bool) {
        return _numAddress[addr] >= 1;
    }

    function getAddresses() public view override(IOpenRegistry) returns (address[] memory) {
        return _addresses;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(OpenERC173)
        returns (bool)
    {
        return
            interfaceId == type(IOpenRegistry).interfaceId || super.supportsInterface(interfaceId);
    }

    function _setRegisterer(address registerer_) internal {
        registerer = registerer_;
    }

    function _addAddress(address addr) private onlyRegisterer onlyValid(addr) {
        if (!isRegistered(addr)) {
            _addresses.push(addr);
            _numAddress[addr] = _addresses.length;
        }
    }

    function _removeAddress(address addr) private onlyRegisterer {
        require(isRegistered(addr), "Not registered");

        uint256 num = _numAddress[addr];
        if (num != _addresses.length) {
            address addrLast = _addresses[_addresses.length - 1];
            _addresses[num - 1] = addrLast;
            _numAddress[addrLast] = num;
        }

        delete (_numAddress[addr]);
        _addresses.pop();
    }
}

// SPDX-License-Identifier: MIT
//
// Derived from OpenZeppelin Contracts (utils/introspection/ERC165Ckecker.sol)
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/ERC165Checker.sol
//
//       ___           ___         ___           ___              ___           ___                     ___
//      /  /\         /  /\       /  /\         /__/\            /__/\         /  /\        ___        /  /\
//     /  /::\       /  /::\     /  /:/_        \  \:\           \  \:\       /  /:/_      /  /\      /  /:/_
//    /  /:/\:\     /  /:/\:\   /  /:/ /\        \  \:\           \  \:\     /  /:/ /\    /  /:/     /  /:/ /\
//   /  /:/  \:\   /  /:/~/:/  /  /:/ /:/_   _____\__\:\      _____\__\:\   /  /:/ /:/   /  /:/     /  /:/ /::\
//  /__/:/ \__\:\ /__/:/ /:/  /__/:/ /:/ /\ /__/::::::::\    /__/::::::::\ /__/:/ /:/   /  /::\    /__/:/ /:/\:\
//  \  \:\ /  /:/ \  \:\/:/   \  \:\/:/ /:/ \  \:\~~\~~\/    \  \:\~~\~~\/ \  \:\/:/   /__/:/\:\   \  \:\/:/~/:/
//   \  \:\  /:/   \  \::/     \  \::/ /:/   \  \:\  ~~~      \  \:\  ~~~   \  \::/    \__\/  \:\   \  \::/ /:/
//    \  \:\/:/     \  \:\      \  \:\/:/     \  \:\           \  \:\        \  \:\         \  \:\   \__\/ /:/
//     \  \::/       \  \:\      \  \::/       \  \:\           \  \:\        \  \:\         \__\/     /__/:/
//      \__\/         \__\/       \__\/         \__\/            \__\/         \__\/                   \__\/
//
//   OpenERC165
//        |
//        ————————————————
//        |              |
//   OpenChecker     OpenERC173
//        |              |
//    OpenGetter    OpenRegistry
//        |              |
//        ————————————————
//        |
//  OpenResolver —— IOpenResolver
//
pragma solidity ^0.8.17;

import "OpenNFTs/contracts/OpenResolver/OpenRegistry.sol";
import "OpenNFTs/contracts/OpenResolver/OpenGetter.sol";
import "OpenNFTs/contracts/interfaces/IOpenResolver.sol";

abstract contract OpenResolver is IOpenResolver, OpenRegistry, OpenGetter {
    /// @notice isValid, by default all addresses valid
    modifier onlyValid(address addr) override(OpenRegistry) {
        require(isCollection(addr), "Not Collection");
        _;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(OpenRegistry, OpenGetter)
        returns (bool)
    {
        return
            interfaceId == type(IOpenResolver).interfaceId || super.supportsInterface(interfaceId);
    }

    function getCollectionsInfos(
        address[] memory collections,
        address account,
        bytes4[] memory interfaceIds
    ) public view override(IOpenResolver) returns (CollectionInfos[] memory collectionsInfos) {
        uint256 len = collections.length;
        collectionsInfos = new CollectionInfos[](len);
        for (uint256 i = 0; i < len; i++) {
            collectionsInfos[i] = _getCollectionInfos(collections[i], account, interfaceIds);
        }
    }

    function _getCollectionsInfos(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (CollectionInfos[] memory collectionsInfos)
    {
        CollectionInfos[] memory collectionsInfosAll =
            getCollectionsInfos(getAddresses(), account, interfaceIds);

        uint256 count;
        uint256 len = collectionsInfosAll.length;
        for (uint256 i = 0; i < len; i++) {
            if (collectionsInfosAll[i].balanceOf > 0 || collectionsInfosAll[i].owner == account) {
                count++;
            }
        }

        collectionsInfos = new CollectionInfos[](count);

        uint256 j;
        for (uint256 i = 0; i < len; i++) {
            if (collectionsInfosAll[i].balanceOf > 0 || collectionsInfosAll[i].owner == account) {
                collectionsInfos[j++] = collectionsInfosAll[i];
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.17;

interface IERC1155 {
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    function setApprovalForAll(address operator, bool approved) external;

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    function isApprovedForAll(address account, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155METADATAURI.sol)

pragma solidity ^0.8.17;

interface IERC1155MetadataURI {
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC173 {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function transferOwnership(address newOwner) external;

    function owner() external view returns (address currentOwner);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC2981 {
    function royaltyInfo(uint256 tokenID, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data)
        external
        payable;

    function safeTransferFrom(address from, address to, uint256 tokenId) external payable;

    function transferFrom(address from, address to, uint256 tokenId) external payable;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool approved) external;

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function getApproved(uint256 tokenId) external view returns (address operator);

    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC721Enumerable {
    function totalSupply() external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC721Metadata {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Infos of either ERC721 or ERC1155 NFT
interface IERCNftInfos {
    enum NftType {
        ERC721,
        ERC1155
    }

    struct CollectionInfos {
        address collection;
        address owner;
        string name;
        string symbol;
        uint256 totalSupply;
        uint256 balanceOf;
        bool approvedForAll;
        bool[] supported;
        NftType erc;
    }

    struct NftInfos {
        uint256 tokenID;
        string tokenURI;
        address owner;
        address approved;
        uint256 balanceOf;
        NftType erc;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IOpenChecker {
    function checkErcInterfaces(address smartcontract)
        external
        view
        returns (bool[] memory interfaceIdsChecks);

    function checkSupportedInterfaces(address smartcontract, bool erc, bytes4[] memory interfaceIds)
        external
        view
        returns (bool[] memory interfaceIdsChecks);

    function isCollection(address collection) external view returns (bool check);

    function isCollections(address[] memory collection)
        external
        view
        returns (bool[] memory checks);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IOpenCloneable {
    function initialize(
        string memory name,
        string memory symbol,
        address owner,
        bytes memory params
    ) external;

    function initialized() external view returns (bool);

    function template() external view returns (string memory);

    function version() external view returns (uint256);

    function parent() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "OpenNFTs/contracts/interfaces/IERCNftInfos.sol";

interface IOpenGetter is IERCNftInfos {
    function getCollectionInfos(address collection, address account)
        external
        view
        returns (CollectionInfos memory collectionInfos);

    function getNftInfos(address collection, uint256 tokenID, address account)
        external
        view
        returns (NftInfos memory nftInfos);

    function getNftsInfos(address collection, address account, uint256 limit, uint256 offset)
        external
        view
        returns (NftInfos[] memory nftsInfos, uint256 count, uint256 total);

    function getNftsInfos(address collection, uint256[] memory tokenIDs, address account)
        external
        view
        returns (NftInfos[] memory nftsInfos);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "OpenNFTs/contracts/interfaces/IOpenReceiverInfos.sol";

interface IOpenMarketable is IOpenReceiverInfos {
    enum Approve {
        None,
        One,
        All
    }

    event SetDefaultRoyalty(address receiver, uint96 fee);

    event SetTokenRoyalty(uint256 tokenID, address receiver, uint96 fee);

    event SetMintPrice(uint256 price);

    event SetTokenPrice(uint256 tokenID, uint256 price);

    event Pay(
        uint256 tokenID,
        uint256 price,
        address seller,
        uint256 paid,
        address receiver,
        uint256 royalties,
        uint256 fee,
        address buyer,
        uint256 unspent
    );

    function withdraw() external returns (uint256);

    function setMintPrice(uint256 price) external;

    function setDefaultRoyalty(address receiver, uint96 fee) external;

    function setTokenPrice(uint256 tokenID, uint256 price) external;

    function setTokenRoyalty(uint256 tokenID, address receiver, uint96 fee) external;

    function minimal() external view returns (bool);

    function getMintPrice() external view returns (uint256 price);

    function getDefaultRoyalty() external view returns (ReceiverInfos memory receiver);

    function getTokenPrice(uint256 tokenID) external view returns (uint256 price);

    function getTokenRoyalty(uint256 tokenID)
        external
        view
        returns (ReceiverInfos memory receiver);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IOpenNFTs {
    function mint(address minter, string memory tokenURI) external returns (uint256 tokenID);

    function burn(uint256 tokenID) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IOpenPauseable {
    event SetPaused(bool indexed paused, address indexed account);

    function paused() external returns (bool);

    function togglePause() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IOpenReceiverInfos {
    struct ReceiverInfos {
        address account;
        uint96 fee;
        uint256 minimum;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IOpenRegistry {
    function setRegisterer(address registerer) external;

    function removeAddress(address addr) external;

    function addAddress(address addr) external;

    function addAddresses(address[] memory addrs) external;

    function getAddresses() external view returns (address[] memory);

    function registerer() external view returns (address);

    function countAddresses() external view returns (uint256);

    function isRegistered(address addr) external view returns (bool registered);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "OpenNFTs/contracts/interfaces/IERCNftInfos.sol";

interface IOpenResolver is IERCNftInfos {
    function getCollectionsInfos(
        address[] memory collections,
        address account,
        bytes4[] memory interfaceIds
    ) external view returns (CollectionInfos[] memory collectionsInfos);
}

// SPDX-License-Identifier: MIT
//
//    OpenERC165
//        |
//  OpenResolver
//        |
//  OpenNFTsResolver —— IOpenNFTsResolver
//
pragma solidity ^0.8.9;

import {IOpenNFTsResolver} from "src/interfaces/IOpenNFTsResolver.sol";
import {IOpenAutoMarket} from "src/interfaces/IOpenAutoMarket.sol";
import {IOpenBound} from "src/interfaces/IOpenBound.sol";
import {IOpenNFTsV0} from "src/interfaces/IOpenNFTsV0.sol";
import {IOpenNFTsV1} from "src/interfaces/IOpenNFTsV1.sol";
import {IOpenNFTsV2} from "src/interfaces/IOpenNFTsV2.sol";
import {IOpenNFTsV3} from "src/interfaces/IOpenNFTsV3.sol";
import {IOpenNFTsV4} from "src/interfaces/IOpenNFTsV4.sol";

import {OpenERC173, OpenRegistry, OpenResolver, OpenGetter} from "OpenNFTs/contracts/OpenResolver/OpenResolver.sol";
import {IOpenMarketable} from "OpenNFTs/contracts/interfaces/IOpenMarketable.sol";
import {IERC2981} from "OpenNFTs/contracts/interfaces/IERC2981.sol";
import {IOpenNFTs} from "OpenNFTs/contracts/interfaces/IOpenNFTs.sol";
import {IOpenMarketable} from "OpenNFTs/contracts/interfaces/IOpenMarketable.sol";
import {IOpenChecker} from "OpenNFTs/contracts/interfaces/IOpenChecker.sol";
import {IOpenPauseable} from "OpenNFTs/contracts/interfaces/IOpenPauseable.sol";
import {IOpenCloneable} from "OpenNFTs/contracts/interfaces/IOpenCloneable.sol";

contract OpenNFTsResolver is IOpenNFTsResolver, OpenResolver {
    bytes4[] private _interfaceIds = new bytes4[](12);

    uint8 private constant _IERC_2981 = 10;
    uint8 private constant _IERC_LENGTH = 11;

    uint8 private constant _IOPEN_NFTS = _IERC_LENGTH + 0;
    uint8 private constant _IOPEN_CHECKER = _IERC_LENGTH + 1;
    uint8 private constant _IOPEN_CLONEABLE = _IERC_LENGTH + 2;
    uint8 private constant _IOPEN_MARKETABLE = _IERC_LENGTH + 3;
    uint8 private constant _IOPEN_PAUSEABLE = _IERC_LENGTH + 4;

    uint8 private constant _IOPEN_NFTS_V0 = _IERC_LENGTH + 5;
    uint8 private constant _IOPEN_NFTS_V1 = _IERC_LENGTH + 6;
    uint8 private constant _IOPEN_NFTS_V2 = _IERC_LENGTH + 7;
    uint8 private constant _IOPEN_NFTS_V3 = _IERC_LENGTH + 8;
    uint8 private constant _IOPEN_NFTS_V4 = _IERC_LENGTH + 9;
    uint8 private constant _IOPEN_AUTOMARKET = _IERC_LENGTH + 10;
    uint8 private constant _IOPEN_BOUND = _IERC_LENGTH + 11;

    constructor(address owner_, address registerer_) {
        OpenERC173._initialize(owner_);
        OpenRegistry._setRegisterer(registerer_);

        /// 0xffffffff :  O Invalid
        /// 0x01ffc9a7 :  1 ERC165
        /// 0x80ac58cd :  2 ERC721
        /// 0x5b5e139f :  3 ERC721Metadata
        /// 0x780e9d63 :  4 ERC721Enumerable
        /// 0x150b7a02 :  5 ERC721TokenReceiver
        /// 0xd9b67a26 :  6 ERC1155
        /// 0x0e89341c :  7 ERC1155MetadataURI
        /// 0x4e2312e0 :  8 ERC1155TokenReceiver
        /// 0x7f5828d0 :  9 ERC173
        /// 0x2a55205a : 10 ERC2981

        _interfaceIds[_IOPEN_NFTS - _IERC_LENGTH] = type(IOpenNFTs).interfaceId;
        _interfaceIds[_IOPEN_CHECKER - _IERC_LENGTH] = type(IOpenChecker).interfaceId;
        _interfaceIds[_IOPEN_CLONEABLE - _IERC_LENGTH] = type(IOpenCloneable).interfaceId;
        _interfaceIds[_IOPEN_MARKETABLE - _IERC_LENGTH] = type(IOpenMarketable).interfaceId;
        _interfaceIds[_IOPEN_PAUSEABLE - _IERC_LENGTH] = type(IOpenPauseable).interfaceId;

        _interfaceIds[_IOPEN_NFTS_V0 - _IERC_LENGTH] = type(IOpenNFTsV0).interfaceId;
        _interfaceIds[_IOPEN_NFTS_V1 - _IERC_LENGTH] = type(IOpenNFTsV1).interfaceId;
        _interfaceIds[_IOPEN_NFTS_V2 - _IERC_LENGTH] = type(IOpenNFTsV2).interfaceId;
        _interfaceIds[_IOPEN_NFTS_V3 - _IERC_LENGTH] = type(IOpenNFTsV3).interfaceId;
        _interfaceIds[_IOPEN_NFTS_V4 - _IERC_LENGTH] = type(IOpenNFTsV4).interfaceId;
        _interfaceIds[_IOPEN_AUTOMARKET - _IERC_LENGTH] = type(IOpenAutoMarket).interfaceId;
        _interfaceIds[_IOPEN_BOUND - _IERC_LENGTH] = type(IOpenBound).interfaceId;
    }

    function getOpenNFTsNftsInfos(address collection, address account, uint256 limit, uint256 offset)
        external
        view
        override(IOpenNFTsResolver)
        returns (
            NftInfos[] memory nftInfos,
            OpenNFTsNftInfos[] memory openNTFsNftInfos,
            CollectionInfos memory collectionInfos,
            uint256 count,
            uint256 total
        )
    {
        collectionInfos = OpenGetter._getCollectionInfos(collection, account, _interfaceIds);

        (nftInfos, count, total) = OpenGetter.getNftsInfos(collection, account, limit, offset);

        openNTFsNftInfos = new OpenNFTsNftInfos[](nftInfos.length);
        for (uint256 i = 0; i < nftInfos.length; i++) {
            openNTFsNftInfos[i] = _getOpenNFTsNftInfos(collection, nftInfos[i].tokenID, collectionInfos.supported);
        }
    }

    function getOpenNFTsNftsInfos(address collection, uint256[] memory tokenIDs, address account)
        external
        view
        override(IOpenNFTsResolver)
        returns (
            NftInfos[] memory nftInfos,
            OpenNFTsNftInfos[] memory openNTFsNftInfos,
            CollectionInfos memory collectionInfos
        )
    {
        collectionInfos = OpenGetter._getCollectionInfos(collection, address(0), _interfaceIds);

        nftInfos = OpenGetter.getNftsInfos(collection, tokenIDs, account);
        openNTFsNftInfos = new OpenNFTsNftInfos[](tokenIDs.length);
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            openNTFsNftInfos[i] = _getOpenNFTsNftInfos(collection, tokenIDs[i], collectionInfos.supported);
        }
    }

    function getOpenNFTsNftInfos(address collection, uint256 tokenID, address account)
        external
        view
        override(IOpenNFTsResolver)
        returns (
            NftInfos memory nftInfos,
            OpenNFTsNftInfos memory openNTFsNftInfos,
            CollectionInfos memory collectionInfos
        )
    {
        collectionInfos = OpenGetter._getCollectionInfos(collection, account, _interfaceIds);

        nftInfos = OpenGetter.getNftInfos(collection, tokenID, account);
        openNTFsNftInfos = _getOpenNFTsNftInfos(collection, tokenID, collectionInfos.supported);
    }

    function getOpenNFTsCollectionsInfos(address account)
        external
        view
        override(IOpenNFTsResolver)
        returns (
            CollectionInfos[] memory collectionsInfos,
            OpenNFTsCollectionInfos[] memory openNFTsCollectionsInfos,
            uint256 count,
            uint256 total
        )
    {
        CollectionInfos[] memory collectionsInfosAll = getCollectionsInfos(getAddresses(), account, _interfaceIds);
        total = collectionsInfosAll.length;

        for (uint256 i = 0; i < collectionsInfosAll.length; i++) {
            if (collectionsInfosAll[i].balanceOf > 0 || collectionsInfosAll[i].owner == account) {
                count++;
            }
        }

        collectionsInfos = new CollectionInfos[](count);
        openNFTsCollectionsInfos = new OpenNFTsCollectionInfos[](count);

        uint256 j;
        for (uint256 i = 0; i < total; i++) {
            if (collectionsInfosAll[i].balanceOf > 0 || collectionsInfosAll[i].owner == account) {
                collectionsInfos[j] = collectionsInfosAll[i];
                openNFTsCollectionsInfos[j] =
                    _getOpenNFTsCollectionInfos(collectionsInfosAll[i].collection, collectionsInfosAll[i].supported);
                j++;
            }
        }
    }

    function getOpenNFTsCollectionInfos(address collection, address account)
        external
        view
        override(IOpenNFTsResolver)
        returns (CollectionInfos memory collectionInfos, OpenNFTsCollectionInfos memory openNTFscollectionInfos)
    {
        collectionInfos = OpenGetter._getCollectionInfos(collection, account, _interfaceIds);
        openNTFscollectionInfos = _getOpenNFTsCollectionInfos(collection, collectionInfos.supported);
    }

    function supportsInterface(bytes4 interfaceId) public view override(OpenResolver) returns (bool) {
        return interfaceId == type(IOpenNFTsResolver).interfaceId || super.supportsInterface(interfaceId);
    }

    function _getOpenNFTsNftInfos(address collection, uint256 tokenID, bool[] memory supported)
        internal
        view
        returns (OpenNFTsNftInfos memory nftInfos)
    {
        if (supported[_IOPEN_MARKETABLE]) {
            nftInfos.receiver = IOpenMarketable(payable(collection)).getTokenRoyalty(tokenID);
            nftInfos.price = IOpenMarketable(payable(collection)).getTokenPrice(tokenID);
        } else if (supported[_IERC_2981]) {
            (nftInfos.receiver.account,) = IERC2981(payable(collection)).royaltyInfo(tokenID, 1);
        }
    }

    function _getOpenNFTsCollectionInfos(address collection, bool[] memory supported)
        internal
        view
        returns (OpenNFTsCollectionInfos memory collInfos)
    {
        if (supported[_IOPEN_CLONEABLE]) {
            collInfos.version = IOpenCloneable(collection).version(); // 4
            collInfos.template = IOpenCloneable(collection).template(); // OpenNFTsV4 or OpenBound
            collInfos.open = IOpenNFTsV4(collection).open();
        } else if (supported[_IOPEN_NFTS_V3]) {
            collInfos.version = 3;
            collInfos.template = "OpenNFTsV3";
            collInfos.open = IOpenNFTsV3(collection).open();
        } else if (supported[_IOPEN_NFTS_V2]) {
            collInfos.version = 2;
        } else if (supported[_IOPEN_NFTS_V1]) {
            collInfos.version = 1;
        }

        if (supported[_IOPEN_MARKETABLE]) {
            collInfos.receiver = IOpenMarketable(payable(collection)).getDefaultRoyalty();
            collInfos.price = IOpenMarketable(payable(collection)).getMintPrice();
            collInfos.minimal = IOpenMarketable(payable(collection)).minimal();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IOpenAutoMarket {
    function mint(string memory tokenURI) external returns (uint256 tokenID);

    function mint(address minter, string memory tokenURI, uint256 price, address receiver, uint96 fee)
        external
        payable
        returns (uint256 tokenID);

    function gift(address to, uint256 tokenID) external payable;

    function buy(uint256 tokenID) external payable;

    function open() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IOpenBound {
    function mint(uint256 tokenID) external returns (uint256);

    function claim(uint256 tokenID, uint256 cid) external;

    function burn(uint256 tokenID) external;

    function getMyTokenID(uint256 cid) external view returns (uint256);

    function getTokenID(address addr, uint256 cid) external view returns (uint256 tokenID);

    function getCID(uint256 tokenID) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERCNftInfos} from "OpenNFTs/contracts/interfaces/IERCNftInfos.sol";
import {IOpenReceiverInfos} from "OpenNFTs/contracts/interfaces/IOpenReceiverInfos.sol";

interface IOpenNFTsInfos is IERCNftInfos, IOpenReceiverInfos {
    struct OpenNFTsCollectionInfos {
        uint256 version;
        string template;
        bool open;
        bool minimal;
        uint256 price;
        ReceiverInfos receiver;
    }

    struct OpenNFTsNftInfos {
        uint256 price;
        ReceiverInfos receiver;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IOpenNFTsInfos} from "src/interfaces/IOpenNFTsInfos.sol";

interface IOpenNFTsResolver is IOpenNFTsInfos {
    function getOpenNFTsNftsInfos(address collection, address account, uint256 limit, uint256 offset)
        external
        view
        returns (
            NftInfos[] memory nftInfos,
            OpenNFTsNftInfos[] memory openNTFsnftInfos,
            CollectionInfos memory collectionInfos,
            uint256 count,
            uint256 total
        );

    function getOpenNFTsNftsInfos(address collection, uint256[] memory tokenIDs, address account)
        external
        view
        returns (
            NftInfos[] memory nftInfos,
            OpenNFTsNftInfos[] memory openNTFsnftInfos,
            CollectionInfos memory collectionInfos
        );

    function getOpenNFTsNftInfos(address collection, uint256 tokenID, address account)
        external
        view
        returns (
            NftInfos memory nftInfos,
            OpenNFTsNftInfos memory openNTFsnftInfos,
            CollectionInfos memory collectionInfos
        );

    function getOpenNFTsCollectionsInfos(address account)
        external
        view
        returns (
            CollectionInfos[] memory collectionsInfos,
            OpenNFTsCollectionInfos[] memory openNFTsCollectionsInfos,
            uint256 count,
            uint256 total
        );

    function getOpenNFTsCollectionInfos(address collection, address account)
        external
        view
        returns (CollectionInfos memory collectionInfos, OpenNFTsCollectionInfos memory openNTFscollectionInfos);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IOpenNFTsV0 {
    function addUser(address minter, string memory jsonURI) external returns (uint256 tokenID);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IOpenNFTsV1 {
    function mintNFT(address minter, string memory jsonURI) external returns (uint256 tokenID);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IOpenNFTsV2 {
    function transferOwnership(address newOwner) external;

    function initialize(string memory name, string memory symbol) external;

    function mintNFT(address minter, string memory jsonURI) external returns (uint256 tokenID_);

    function owner() external view returns (address owner_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IOpenNFTsV3 {
    function open() external view returns (bool);

    function burnable() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IOpenNFTsV4 {
    function mint(string memory tokenURI) external returns (uint256 tokenID);

    function mint(address minter, string memory tokenURI) external returns (uint256 tokenID);

    function burn(uint256 tokenID) external;

    function open() external view returns (bool);
}