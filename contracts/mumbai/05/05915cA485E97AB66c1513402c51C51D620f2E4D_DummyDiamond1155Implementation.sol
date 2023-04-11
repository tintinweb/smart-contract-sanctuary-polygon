// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * This is a generated dummy diamond implementation for compatibility with
 * etherscan. For full contract implementation, check out the diamond on louper:
 * https://louper.dev/diamond/0xBC44e2Ddd52A6B98d5f066592F4a9b276E57fD00?network=goerli
 */

contract DummyDiamond1155Implementation {
    struct Tuple800840 {
        uint256 maxSupply;
        uint256 price;
        address creator;
        string tokenUri;
        bool allowListEnabled;
        uint256 startTime;
        bool isCrossmintUSDC;
    }

    struct Tuple2548212 {
        uint256 maxSupply;
        uint256 price;
        address creator;
        string tokenUri;
        bool allowListEnabled;
        uint256 startTime;
        bool isCrossmintUSDC;
    }

    struct Tuple576603 {
        address account;
        uint256 allowance;
    }

    struct Tuple6871229 {
        address facetAddress;
        uint8 action;
        bytes4[] functionSelectors;
    }

    struct Tuple1236461 {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    function accountsByToken(
        uint256 id
    ) external view returns (address[] memory) {}

    function balanceOf(
        address account,
        uint256 id
    ) external view returns (uint256) {}

    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    ) external view returns (uint256[] memory) {}

    function crossmintMint(
        address account,
        uint256 id,
        uint256 amount
    ) external {}

    function isApprovedForAll(
        address account,
        address operator
    ) external view returns (bool) {}

    function supportsInterface(
        bytes4 interfaceId
    ) external view returns (bool) {}

    function tokensByAccount(
        address account
    ) external view returns (uint256[] memory) {}

    function totalHolders(uint256 id) external view returns (uint256) {}

    function totalSupply(uint256 id) external view returns (uint256) {}

    function OPERATOR_FILTER_REGISTRY() external view returns (address) {}

    function batchCreate(
        uint256 _amount,
        Tuple800840 memory _tokenData
    ) external returns (bool success) {}

    function batchCreate(
        Tuple2548212[] memory _tokenData
    ) external returns (bool success) {}

    function burn(address account, uint256 id, uint256 amount) external {}

    function create(
        Tuple800840 memory _tokenData
    ) external returns (uint256 _id) {}

    function exists(uint256 _tokenId) external view returns (bool) {}

    function maxSupply(uint256 _id) external view returns (uint256) {}

    function mint(
        address account,
        uint256 id,
        uint256 amount
    ) external payable {}

    function mint(
        address[] memory accounts,
        uint256 id,
        uint256 amount
    ) external {}

    function name() external view returns (string memory) {}

    function price(uint256 _id) external view returns (uint256) {}

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory _amounts,
        bytes memory data
    ) external {}

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) external {}

    function setApprovalForAll(address operator, bool approved) external {}

    function setMaxSupply(uint256 _id, uint256 _maxSupply) external {}

    function setName(string memory _name) external {}

    function setPrice(uint256 _id, uint256 _price) external {}

    function setStartTime(uint256 _id, uint256 _startTime) external {}

    function setSymbol(string memory _symbol) external {}

    function setTokenData(
        uint256 _id,
        uint256 _price,
        address _creator,
        string memory _tokenUri,
        bool _allowListEnabled,
        uint256 _startTime
    ) external {}

    function startTime(uint256 _id) external view returns (uint256) {}

    function symbol() external view returns (string memory) {}

    function tokenData(
        uint256 _id
    )
        external
        view
        returns (
            uint256 _price,
            address _creator,
            string memory _tokenUri,
            bool _allowListEnabled,
            uint256 _startTime
        )
    {}

    function uri(uint256 _tokenId) external view returns (string memory) {}

    function addToAllowList(uint256 tokenId, address account) external {}

    function addToAllowList(
        uint256 tokenId,
        address[] memory accounts,
        uint256 allowance
    ) external {}

    function addToAllowList(
        uint256 tokenId,
        address account,
        uint256 allowance,
        uint256 allowTime
    ) external {}

    function addToAllowList(
        uint256 tokenId,
        address[] memory accounts
    ) external {}

    function addToAllowList(
        uint256 tokenId,
        address account,
        uint256 allowance
    ) external {}

    function addToAllowList(
        uint256 tokenId,
        address[] memory accounts,
        uint256 allowance,
        uint256 allowTime
    ) external {}

    function allowList(
        uint256 _tokenId
    ) external view returns (Tuple576603[] memory allowListMap) {}

    function allowListContains(
        uint256 tokenId,
        address account
    ) external view returns (bool contains) {}

    function allowListEnabled(
        uint256 _tokenId
    ) external view returns (bool enabled) {}

    function disableAllowList(uint256 _tokenId) external {}

    function enableAllowList(uint256 _tokenId) external {}

    function removeFromAllowList(uint256 tokenId, address account) external {}

    function removeFromAllowList(
        uint256 tokenId,
        address[] memory accounts
    ) external {}

    function diamondCut(
        Tuple6871229[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) external {}

    function implementation() external view returns (address) {}

    function setDummyImplementation(address _implementation) external {}

    function facetAddress(
        bytes4 _functionSelector
    ) external view returns (address facetAddress_) {}

    function facetAddresses()
        external
        view
        returns (address[] memory facetAddresses_)
    {}

    function facetFunctionSelectors(
        address _facet
    ) external view returns (bytes4[] memory _facetFunctionSelectors) {}

    function facets() external view returns (Tuple1236461[] memory facets_) {}

    function __transitiveOwner() external view returns (address) {}

    function owner() external view returns (address) {}

    function transferOwnership(address account) external {}

    function pause() external {}

    function paused() external view returns (bool) {}

    function unpause() external {}

    function addPayee(address account, uint256 shares_) external {}

    function payee(uint256 index) external view returns (address) {}

    function releasable(address account) external view returns (uint256) {}

    function releasable(
        address token,
        address account
    ) external view returns (uint256) {}

    function release(address account) external {}

    function release(address token, address account) external {}

    function released(
        address token,
        address account
    ) external view returns (uint256) {}

    function released(address account) external view returns (uint256) {}

    function shares(address account) external view returns (uint256) {}

    function totalReleased(address token) external view returns (uint256) {}

    function totalReleased() external view returns (uint256) {}

    function totalShares() external view returns (uint256) {}

    function updatePaymentSplitterAddress(
        address _newPayee
    ) external returns (bool success) {}

    function contractURI() external view returns (string memory) {}

    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address, uint256) {}

    function setDefaultRoyalty(
        uint16 _defaultRoyaltyBPS,
        address _defaultRoyalyReceiver
    ) external {}
}