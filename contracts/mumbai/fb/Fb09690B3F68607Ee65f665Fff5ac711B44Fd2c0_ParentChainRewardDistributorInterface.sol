// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;
contract ParentChainRewardDistributorInterface {
    address public callproxy; // AnycallV7 Router
    address public minter;
    address public voter;
    address public nftBridge; // The Solidly NFT Bridge contract
    address public base; // Solid
    string public thisAddress; // Need this address as string for fallback for anycall
    uint256 public kickMin; // Minimum amount of Solid accrued in order to kick
    mapping (uint256 => uint256) public periodEmissions; // period -> totalEmissions
    mapping (uint256 => uint256) public accruedEmissions; // chainId -> accruedEmissions 

    // ChainId => String of ChildChainDistributor Address
    mapping (uint256 => string) public childChainDistributor;

    event KickFailed(uint256 time);
    event KickedEmissions(uint256 indexed chainId, uint256 indexed activePeriod, uint256 amount);
    event NewKickMin(uint256 amount);

    function initialize(
        address _base,
        address _minter,
        address _voter,
        address _nftBridge,  
        address _callproxy,
        uint256 _kickMin
    ) public  {}

    // Called by voter, allocates peroiod solid by chain nft balances.
    function notifyRewardAmount(address _token, uint256 _amount) external { }

    // Helper to kick multiple chains at once
    function kickMultiple(uint256[] calldata _chainIds) external {}

    // Kick down solid rewards to child chain reward distributor
    function kick(uint256 _chainId) public { }

    // Hopefully wont have to use this. If our bridge out fails, anycall will send solid back to this contract. 
    // We can retry bridging them again.
    function forceKickGovernance(uint256 _chainId) external { }

    // Set minimum amount to kick, anycall could have minimum bridge amounts.
    function setKickMin(uint256 _minAmount) external {}
    
    function setVoter(address _voter) external {}
}