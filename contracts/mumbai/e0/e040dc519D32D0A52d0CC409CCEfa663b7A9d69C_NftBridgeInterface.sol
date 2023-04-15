// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;

contract NftBridgeInterface {
    event ChildChainVeAdded(uint256 indexed chainId, address ve);
    event Error();
    event NftBridged(
        address indexed user,
        uint256 indexed tokenId,
        uint256 indexed chainId,
        uint256 amount
    );
    event NftBurned(
        address indexed user,
        uint256 indexed tokenId,
        uint256 indexed chainId,
        uint256 amount
    );
    event NftClaimed(
        address indexed user,
        uint256 indexed oldTokenId,
        uint256 indexed newTokenId,
        uint256 amount
    );
    event SetAnycall(
        address oldProxy,
        address newProxy,
        address oldExec,
        address newExec
    );
    event VoteDelaySet(uint256 delay);

    function _exec(bytes memory _data)
        external
        returns (bool success, bytes memory result) {}

    function addChildChainVe(
        uint256 _chainId,
        address _ve,
        bool _init
    ) external {}

    function anyExecute(bytes memory data)
        external
        returns (bool success, bytes memory result) {}

    function bridgeOutNft(
        uint256[] calldata _chainIds,
        uint256 _tokenId,
        uint256[] calldata _amounts,
        uint256[] calldata _feeInEther
    ) external payable {}

    function callproxy() external view returns (address) {}

    function chainBalances(uint256) external view returns (uint256) {}

    function chains(uint256) external view returns (uint256) {}

    function childChainVe(uint256) external view returns (address) {}

    function childChains() external view returns (uint256[] memory _chains) {}

    function claimNft(uint256 _tokenId) external {}

    function claimVeRebase() external {}

    function configureChildChainWeights(
        uint256[] memory _chainIds,
        uint256 _tokenId,
        uint256[] memory _amounts,
        uint256[] memory _feeInEther
    ) external payable {}

    function executor() external view returns (address) {}

    function increaseUnlockTime() external {}

    function initialize(
        address _callproxy,
        address _executor,
        address _voter,
        address _ve,
        address _ve_dist,
        address _rewardsDistributor,
        uint256 _tokenId
    ) external {}

    function lockInfo()
        external
        view
        returns (
            uint256 endTime,
            uint256 secondsRemaining,
            bool shouldIncreaseLock
        ) {}

    function masterTokenId() external view returns (uint256) {}

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) external view returns (bytes4) {}

    function ownerOf(uint256) external view returns (address) {}

    function rewardsDistributor(uint256) external view returns (address) {}

    function setAnycallAddresses(address _proxy, address _executor) external {}

    function setVoteDelay(uint256 _delay) external {}

    function totalBridgedBase() external view returns (uint256) {}

    function totalLocked() external view returns (uint256) {}

    function userData(address, uint256)
        external
        view
        returns (uint256 bridgedTotal, uint256 bridgedOutstanding) {}

    function ve() external view returns (address) {}

    function ve_dist() external view returns (address) {}

    function vote() external {}

    function voteDelay() external view returns (uint256) {}

    function voteWeights(uint256) external view returns (uint256) {}

    function voter() external view returns (address) {}
}