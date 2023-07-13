/**
 *Submitted for verification at polygonscan.com on 2023-07-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

contract TokenVesting {
    struct Organization {
        address organizationAddress;
        address tokenContract;
        string name;
        mapping(address => bool) whitelistedAddresses;
        mapping(address => uint256) vestingPeriods;
    }

    struct Stakeholder {
        address stakerAddress;
        uint256 vestingPeriod;
        uint256 startTime;
        uint256 totalTokens;
        uint256 claimedTokens;
    }

    mapping(address => Organization) public organizations;
    mapping(address => Stakeholder) public stakeholders;
    mapping (address => uint256) public  stakeHolderBalance;

    event OrganizationRegistered(address indexed organization, address indexed tokenContract);
    event AddressWhitelisted(address indexed organization, address indexed stakeholder);
    event TokensClaimed(address indexed organization, address indexed stakeholder, uint256 amount);

    function registerOrganization(address _tokenContract, string calldata _name) external {
        require(_tokenContract != address(0), "Invalid token contract address");
        require(organizations[msg.sender].tokenContract == address(0), "Organization already registered");

        organizations[msg.sender].organizationAddress = msg.sender;
        organizations[msg.sender].tokenContract = _tokenContract;
        organizations[msg.sender].name = _name;
        emit OrganizationRegistered(msg.sender, _tokenContract);
    }

    function addStakeHolder(address _organization, address _stakeholderAddress, uint256 _vestingPeriod, uint256 _totalTokens) external  {
        require(organizations[_organization].tokenContract != address(0), "Organization not registered");
        require(organizations[_organization].organizationAddress == msg.sender, "Unauthorized!");

        stakeholders[_stakeholderAddress] = Stakeholder({
            stakerAddress: _stakeholderAddress,
            vestingPeriod: _vestingPeriod,
            startTime: block.timestamp,
            totalTokens: _totalTokens,
            claimedTokens: 0
        });
    }

    function whitelistAddress(address _stakeholder, uint256 _vestingPeriod) external {
        require(_stakeholder != address(0), "Invalid stakeholder address");
        require(organizations[msg.sender].tokenContract != address(0), "Organization not registered");

        organizations[msg.sender].whitelistedAddresses[_stakeholder] = true;
        organizations[msg.sender].vestingPeriods[_stakeholder] = _vestingPeriod;
        emit AddressWhitelisted(msg.sender, _stakeholder);
    }

    function claimTokens() external {
        require(stakeholders[msg.sender].vestingPeriod > 0, "Stakeholder not registered");

        Stakeholder storage stakeholder = stakeholders[msg.sender];
        require(stakeholder.totalTokens > 0, "No tokens to claim");
        require(stakeholder.claimedTokens < stakeholder.totalTokens, "All tokens claimed");
        require(block.timestamp >= stakeholder.startTime + stakeholder.vestingPeriod, "Vesting period not ended");
        
        uint256 maxToClaim = stakeholder.totalTokens - stakeholder.claimedTokens;
        require(maxToClaim > 0, "No tokens");

        stakeholder.claimedTokens += maxToClaim; 
        stakeHolderBalance[stakeholder.stakerAddress] =  maxToClaim;

    }

    function getStakerTokensClaimed() external view returns(uint256) {
        return stakeHolderBalance[msg.sender];
    }

    function getStakeholder() external view returns(Stakeholder memory) {
        return stakeholders[msg.sender];
    }
}