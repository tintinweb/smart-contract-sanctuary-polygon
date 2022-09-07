// SPDX-License-Identifier: MIT
// This is a peripheral contract.
// For storage, use NFTManagerStore instead.
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./Interface_NFTManagementStore.sol";

interface Store is I_NFTManagementStore {}

interface ERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function setApprovalForAll(address operator, bool approved) external;
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
    function createEventNFTContract(
        bytes32 hostSignature,
        bytes32 eventSignature,
        address platform,
        address owner,
        uint256 mintAmount,
        string memory eventName,
        string memory eventSymbol
    ) external returns (address);
}

contract NFTManager {
    address public $store;
    address public $token;
    address public $platform;

    constructor(
        address store,
        address token,
        address platform
    ) {
        $store = store;
        $token = token;
        $platform = platform;
        ERC20($token).approve(address(this), 1000000000000000000000000000000);
    }

    event Fail(string message, bytes32 data);

    function createNFT(
        bytes32 hostSignature,
        bytes32 eventSignature,
        address platform,
        address owner,
        uint256 mintAmount,
        string memory eventName,
        string memory eventSymbol,
        uint256 factory_built_version
    ) public payable {
        address factory = Store($store).getFactory(factory_built_version);
        require(factory != address(0), "Factory not found");
        address nft = Factory(factory).createEventNFTContract(
            hostSignature,
            eventSignature,
            platform,
            owner,
            mintAmount,
            eventName,
            eventSymbol
        );

        Store($store).addNFT(eventSignature, nft);
        Store($store).setUser(eventSignature, msg.sender);

        (bool approveSuccess, /* bytes memory data */) = address(nft).delegatecall(
            abi.encodeWithSignature("setApprovalForAll(address,bool)", address(this), true)
        );
        if (approveSuccess == false) { emit Fail("NFT not approved after created", ""); }
    }

    function buyNFT(
        address nft_contract,
        address end_user,
        uint256 token_id,
        bytes32 event_signature,
        uint256 price
    ) public {
        address event_host = _getEventHostAddressByEventSignature(event_signature);
        require(event_host != address(0), "Event host not found or set");
        ERC721(nft_contract).safeTransferFrom(event_host, end_user, token_id);
        ERC20($token).transferFrom($platform, event_host, price);
    }

    function _getEventHostAddressByEventSignature(bytes32 event_signature) private view returns (address) {
        return Store($store).getUser(event_signature);
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
    function setActiveness(bool flag, address factory) external;
    function getActiveness(address factory) external view returns (bool);
    function setAllowance(bool flag, address factory) external;
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