/**
 *Submitted for verification at polygonscan.com on 2023-06-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TestPad {

    address constant public ZERO_ADDRESS = address(0);
    
    address public owner;

    // Structure to store project details
    struct Project {
        string name; // token name
        IERC20 tokenContract; // contract address of token
        IERC20[] priceContracts; // Contract address list for prices (enter [ZERO_ADDRESS] for native coin)
        uint256[] prices; // Price list for token
        uint256 totalTokens; // Total allocation
        uint256[] remainingTokens; // Remaining tokens according to tier list
        uint256 maxInvestment; // Max allocation
        uint256 minInvestment; // Min allocation
        uint256[] tierPercentage; // Tier list. Example: [100] for 1 tier or [30,20,25,25] for 4 tiers
        uint256 startTime; // project start time (timestamp)
        uint256 endTime; // project end time (timestamp)
        uint256 accessType; // 0-> private, 1-> public (default: public)
        bool claimable; // users can claim tokens when claimable is true
        mapping(address => uint256) investments; // investment list
        mapping(address => uint256) claimedTokens; // claimed token list
    }
    
    mapping(address => uint256) public tierUserList;

    constructor() public {
        owner = msg.sender;
    }

    // Mapping to store projects
    mapping(uint256 => Project) public projects;
    uint256 public projectId = 1;

    // Event emitted when a new project is created
    event ProjectCreated(uint256 projectId);

    // Function to create a new project
    function createProject(
        string memory _name,
        IERC20 _tokenContract,
        IERC20[] memory _priceContracts,
        uint256[] memory _prices,
        uint256 _totalTokens,
        uint256 _maxInvestment,
        uint256 _minInvestment,
        uint256[] memory _tierPercentage,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _accessType
    ) external onlyOwner {
        require(_endTime > block.timestamp, "End time must be in the future");
        require(_priceContracts.length == _prices.length, "Price and Contract arrays must have the same length");

        Project storage newProject = projects[projectId];
        newProject.name = _name;
        newProject.tokenContract = _tokenContract;
        newProject.priceContracts = _priceContracts;
        newProject.prices = _prices;
        newProject.totalTokens = _totalTokens;
        newProject.maxInvestment = _maxInvestment;
        newProject.minInvestment = _minInvestment;
        newProject.tierPercentage = _tierPercentage;
        newProject.startTime = _startTime;
        newProject.endTime = _endTime;
        newProject.accessType = _accessType;
        newProject.claimable = false;

        for(uint256 i = 0; i < newProject.tierPercentage.length;i++) {
            newProject.remainingTokens.push((newProject.totalTokens * newProject.tierPercentage[i]) / 100);
        }

        emit ProjectCreated(projectId);

        projectId++;
    }

    // Function to invest in a project
    function invest(uint256 _projectId, uint256 _tokens, uint256 _tierNumber, address _tokenContract) external payable {

        Project storage project = projects[_projectId];
        require(block.timestamp >= project.startTime, "Investment period has not started");
        require(block.timestamp <= project.endTime, "Investment period has ended");
        require(project.tierPercentage.length>=_tierNumber, "Index must be smaller than length");
        require(_tokens <= project.remainingTokens[_tierNumber-1], "Not enough tokens available");
        require(_tokens >= project.minInvestment, "Too low to invest");
        require(_tokens <= project.maxInvestment, "Too high to invest");
        require(tierUserList[msg.sender] == _tierNumber,"Tier number is invalid");
        
        uint256 token_exist = 0;
        for(uint256 i = 0; i < project.priceContracts.length; i++) {
            if(_tokenContract == address(project.priceContracts[i])) {
                if(_tokenContract == address(0)) {
                    // Investment with native token
                    require(msg.value / project.prices[i] >= _tokens, "Insufficient funds");
                    payable(msg.sender).transfer(msg.value);
                } else {
                    // Investment with ERC20 token
                    IERC20 token = IERC20(_tokenContract);
                    require(token.transferFrom(msg.sender, address(this), _tokens * project.prices[i]), "Token transfer failed");
                }
                token_exist = 1;
                break;
            }
        }
        require(token_exist==1,"Token address does not exist!");

        project.investments[msg.sender] += _tokens;
        project.remainingTokens[_tierNumber-1] -= _tokens;
    }

    // Function to claim tokens (set claimable as true to able to call this function)
    function claimTokens(uint256 _projectId) external {
        Project storage project = projects[_projectId];
        require(project.claimable, "Tokens are not yet claimable");
        
        uint256 totalInvestment = project.investments[msg.sender];
        uint256 claimedTokens = project.claimedTokens[msg.sender];
        uint256 tokensToClaim = totalInvestment-claimedTokens;
        
        require(tokensToClaim > 0, "No tokens to claim");

        project.claimedTokens[msg.sender] += tokensToClaim;

        IERC20 token = IERC20(project.tokenContract);
        require(token.transfer(msg.sender, tokensToClaim * 1e18), "Token transfer failed");
    }

    // Project's total investments
    function getTotalInvestments(uint256 _projectId) external view returns (uint256) {
        require(_projectId<projectId,"Index must be smaller than length");
        Project storage project = projects[_projectId];
        uint256 ret_value = 0;
        for(uint256 i=0;i<project.remainingTokens.length;i++) {
            ret_value += project.remainingTokens[i];
        }
        return ret_value;
    }

    // Returns remaining tokens for the specific tier
    function getRemainingTokens(uint256 _projectId, uint256 _tierIndex) external view returns (uint256) {
        require(_projectId<projectId,"Index must be smaller than length");
        Project storage project = projects[_projectId];
        require(project.remainingTokens.length>_tierIndex,"Index must be smaller than length");
        return project.remainingTokens[_tierIndex];
    }

    // Function to get project details
    function getUserInvestmentInfo(uint256 _projectId, address wallet)
        external
        view
        returns (
            uint256 totalInvestment,
            uint256 totalClaimedTokens,
            uint256 tier
        )
    {
        Project storage project = projects[_projectId];

        uint256 tier_number = tierUserList[wallet];

        return (
            project.investments[wallet],
            project.claimedTokens[wallet],
            tier_number
        );
    }

    // Function to get project details
    function getProjectDetails(uint256 _projectId)
        external
        view
        returns (
            string memory name,
            IERC20[] memory priceContracts,
            uint256[] memory prices,
            uint256 totalTokens,
            uint256 maxInvestment,
            uint256 minInvestment,
            uint256 startTime,
            uint256 endTime,
            uint256 accessType,
            bool claimable
        )
    {
        Project storage project = projects[_projectId];

        return (
            project.name,
            project.priceContracts,
            project.prices,
            project.totalTokens,
            project.maxInvestment,
            project.minInvestment,
            project.startTime,
            project.endTime,
            project.accessType,
            project.claimable
        );
    }

    // Function to withdraw specific token from the contract
    function withdrawTokens(address _tokenContract) external onlyOwner {
        if (_tokenContract == ZERO_ADDRESS) {
            // Withdraw Native Token
            payable(owner).transfer(address(this).balance);
        } else {
            // Withdraw ERC20 tokens
            IERC20 token = IERC20(_tokenContract);
            uint256 tokenBalance = token.balanceOf(address(this));
            require(tokenBalance > 0, "No tokens to withdraw");

            require(token.transfer(owner, tokenBalance*10**18), "Token transfer failed");
        }
    }

    function setTotalTokens(uint256 _projectId, uint256 _totalTokens) external onlyOwner {
        Project storage project = projects[_projectId];
        project.totalTokens = _totalTokens;
    }

    function setMaxInvestment(uint256 _projectId, uint256 _maxInvestment) external onlyOwner {
        Project storage project = projects[_projectId];
        project.maxInvestment = _maxInvestment;
    }

    function setMinInvestment(uint256 _projectId, uint256 _minInvestment) external onlyOwner {
        Project storage project = projects[_projectId];
        project.minInvestment = _minInvestment;
    }

    function setStartTime(uint256 _projectId, uint256 _startTime) external onlyOwner {
        Project storage project = projects[_projectId];
        project.startTime = _startTime;
    }

    function setEndTime(uint256 _projectId, uint256 _endTime) external onlyOwner {
        Project storage project = projects[_projectId];
        require(_endTime > block.timestamp, "End time must be in the future");
        project.endTime = _endTime;
    }

    function setClaimable(uint256 _projectId, bool _claimable) external onlyOwner {
        Project storage project = projects[_projectId];
        project.claimable = _claimable;
    }
    function setTierForAddressList(address[] memory _address, uint256 _tier) external onlyOwner {
        for(uint256 i=0;i<_address.length;i++) {
            tierUserList[_address[i]] = _tier;
        }
    }

    function setTierForAddress(address _address, uint256 _tier) external onlyOwner {
        tierUserList[_address] = _tier;
    }

    function setPrices(uint256 _projectId, uint256[] memory _prices) external onlyOwner {
        Project storage project = projects[_projectId];
        require(project.prices.length == _prices.length,"Price array length must be the same");
        project.prices = _prices;
    }

    function setAccessType(uint256 _projectId, uint256 _type) external onlyOwner {
        Project storage project = projects[_projectId];
        project.accessType = _type;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    receive() external payable {}
}