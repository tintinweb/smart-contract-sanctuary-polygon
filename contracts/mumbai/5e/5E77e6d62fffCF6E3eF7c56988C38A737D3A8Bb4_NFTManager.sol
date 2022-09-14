// SPDX-License-Identifier: MIT
// This is a peripheral contract.
// For storage, use NFTManagerStore instead.
// Version 0.1.0

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "../../contracts-deps/@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "./Interface_NFTManagementStore.sol";

interface Store is I_NFTManagementStore {}

interface ERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function setApprovalForAll(address operator, bool approved) external;

    function transferByPermitOperator(
        address store,
        address from,
        address to,
        uint256 tokenId
    ) external;
}

interface ERC20 {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external;

    function approve(
        address spender,
        uint256 amount
    ) external;
}

interface Factory {
    function createNFTContract(
        bytes32 hostSignature,
        bytes32 eventSignature,
        address platform,
        address owner,
        uint256 mintAmount,
        string memory baseURI,
        string memory eventName,
        string memory eventSymbol
    ) external returns (address);
}

contract ERC2771TrustForwarderChangeable is ERC2771Context {
    address private _trustedForwarder;

    constructor(address trustedForwarder) 
        ERC2771Context(trustedForwarder)
    {
        _trustedForwarder = trustedForwarder;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    function changeTrustForwarder(address newTrustForwarder) public {
        require(_msgSender() == _trustedForwarder, "ERC2771Context: only the trusted forwarder can change it");
        _trustedForwarder = newTrustForwarder;
    }
}

contract NFTManager is ERC2771TrustForwarderChangeable {
    address public $store;
    address public $token;
    address public $platform;
    address public $forwarder;

    event Fail(string message, bytes32 data);

    constructor(
        address store,
        address token,
        address platform,
        address forwarder
    ) ERC2771TrustForwarderChangeable(platform) {
        $store = store;
        $token = token;
        $platform = platform;
        $forwarder = forwarder;
    }

    modifier onlyPlatform {
        require(
            _msgSender() == $platform 
            || _msgSender() == $forwarder
            , "NFTManager: only platform"
        );
        _;
    }

    function changeForwarder(
        address forwarder
    ) public onlyPlatform {
        $forwarder = forwarder;
        changeTrustForwarder(forwarder);
    }

    function createNFT(
        bytes32 hostSignature,
        bytes32 eventSignature,
        address platform,
        address owner,
        uint256 mintAmount,
        uint256 fee,
        string memory baseURI,
        string memory eventName,
        string memory eventSymbol,
        uint256 factory_built_version
    ) public onlyPlatform {
        transferTokenToPlatform(owner, fee);
        address factory = Store($store).getFactory(factory_built_version);
        require(factory != address(0), "Factory not found");
        address nft = Factory(factory).createNFTContract(
            hostSignature,
            eventSignature,
            platform,
            owner,
            mintAmount,
            baseURI,
            eventName,
            eventSymbol
        );

        Store($store).addNFT(eventSignature, nft);
        Store($store).setUser(eventSignature, owner);
    }

    function buyNFT(
        address nft_contract,
        address end_user,
        uint256 token_id,
        bytes32 event_signature,
        uint256 price
    ) public onlyPlatform {
        address event_host = _getEventHostAddressByEventSignature(event_signature);
        require(event_host != address(0), "Event host not found or set");
        ERC721(nft_contract).transferByPermitOperator($store, event_host, end_user, token_id);
        transferTokenFromPlatform(event_host, price);
    }

    function buyNFTs(
        address nft_contract,
        address end_user,
        uint256[] calldata token_ids,
        bytes32 event_signature,
        uint256 price
    ) public onlyPlatform {
        address event_host = _getEventHostAddressByEventSignature(event_signature);
        require(event_host != address(0), "Event host not found or set");

        for (uint256 i = 0; i < token_ids.length; i++) {
            ERC721(nft_contract).transferByPermitOperator($store, event_host, end_user, token_ids[i]);
            transferTokenFromPlatform(event_host, price);
        }
    }

    function _getEventHostAddressByEventSignature(bytes32 event_signature) private view returns (address) {
        return Store($store).getUser(event_signature);
    }

    function transferTokenFromPlatform(
        address user,
        uint256 amount
    ) public onlyPlatform {
        ERC20($token).transferFrom($platform, user, amount);
    }

    function transferTokenToPlatform(
        address user,
        uint256 amount
    ) public {
        ERC20($token).transferFrom(user, $platform, amount);
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
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface I_NFTManagementStore {    
    struct Meta {
        string text;
        bytes data;
    }

    function setMeta(bytes32 key, string memory text, bytes memory data) external;
    function getMeta(bytes32 key) external view returns (Meta memory meta);
    function setActiveness(address factory, bool flag) external;
    function getActiveness(address factory) external view returns (bool);
    function setAllowance(address factory, bool flag) external;
    function getAllowance(address factory) external view returns (bool);
    function addFactory(uint256 factory_built_version, address factory) external;
    function getFactory(uint256 factory_built_version) external view returns (address);
    function getTotalFactory() external view returns (uint256);
    function addNFT(bytes32 signature, address nft) external;
    function getNFT(bytes32 signature) external view returns (address);
    function getTotalNFT() external view returns (uint256);
    function setUser(bytes32 signature, address user) external;
    function getUser(bytes32 signature) external view returns (address);
    function getTotalUser() external view returns (uint256);
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