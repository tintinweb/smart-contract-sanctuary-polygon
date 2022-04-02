/**
 *Submitted for verification at polygonscan.com on 2022-04-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

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
}

/*

     _______  _______ _________ _______           _______  _______  _______  _______      _______  _______  _______  _______  _______ 
    (       )(  ____ \\__   __/(  ___  )|\     /|(  ____ \(  ____ )(  ____ \(  ____ \    (  ____ \(  ___  )(  ____ \(  ___  )(  ____ \
    | () () || (    \/   ) (   | (   ) || )   ( || (    \/| (    )|| (    \/| (    \/    | (    \/| (   ) || (    \/| (   ) || (    \/
    | || || || (__       | |   | (___) || |   | || (__    | (____)|| (_____ | (__        | (_____ | (___) || |      | (___) || (_____ 
    | |(_)| ||  __)      | |   |  ___  |( (   ) )|  __)   |     __)(_____  )|  __)       (_____  )|  ___  || | ____ |  ___  |(_____  )
    | |   | || (         | |   | (   ) | \ \_/ / | (      | (\ (         ) || (                ) || (   ) || | \_  )| (   ) |      ) |
    | )   ( || (____/\   | |   | )   ( |  \   /  | (____/\| ) \ \__/\____) || (____/\    /\____) || )   ( || (___) || )   ( |/\____) |
    |/     \|(_______/   )_(   |/     \|   \_/   (_______/|/   \__/\_______)(_______/    \_______)|/     \|(_______)|/     \|\_______)
                                                                                                                                    
                                     _______ _________ _______  _       _________ _        _______                                  
                                    (  ____ \\__   __/(  ___  )| \    /\\__   __/( (    /|(  ____ \                                 
                                    | (    \/   ) (   | (   ) ||  \  / /   ) (   |  \  ( || (    \/                                 
                                    | (_____    | |   | (___) ||  (_/ /    | |   |   \ | || |                                       
                                    (_____  )   | |   |  ___  ||   _ (     | |   | (\ \) || | ____                                  
                                          ) |   | |   | (   ) ||  ( \ \    | |   | | \   || | \_  )                                 
                                    /\____) |   | |   | )   ( ||  /  \ \___) (___| )  \  || (___) |                                 
                                    \_______)   )_(   |/     \||_/    \/\_______/|/    )_)(_______)                                 
                                                                                                                                    
*/

contract MetaverseSagasStaking {

    // ---------------------------------------------------------------------------------------------
    // EVENTS
    // ---------------------------------------------------------------------------------------------

    event Start (uint timestamp);
    event Close (uint timestamp);
    event Swap (address wallet, uint MVSAmount, uint NPTAmount);    
    event Unstake (address wallet, uint amount, uint unstakeDate);    
    event Stake (address wallet, uint tier, uint amount, uint unstakeDate);

    // ---------------------------------------------------------------------------------------------
    // STRUCTS
    // ---------------------------------------------------------------------------------------------

    struct StakingInfo {
        uint amount;
        uint unstakeDate;
        bool unstaked;
    }

    // ---------------------------------------------------------------------------------------------
    // INITIALIZATION
    // ---------------------------------------------------------------------------------------------

    constructor() {
        owner = msg.sender;
        MVSPriceForNPT = 50;
    }

    // ---------------------------------------------------------------------------------------------
    // EVENTS
    // ---------------------------------------------------------------------------------------------

    modifier onlyOwner {
        require(msg.sender == owner, "NOT THE OWNER!");
        _;
    }

    // ---------------------------------------------------------------------------------------------
    // CONSTANTS
    // ---------------------------------------------------------------------------------------------

    address private constant MVS = 0xB96af157655B7C9384A32213861d2aa6673DCA9e;
    address private constant NPT = 0x445Ee30936f96b4c4d9c18B759BFEf8F7C4DC0Fb;

    // ---------------------------------------------------------------------------------------------
    // MAPPINGS
    // ---------------------------------------------------------------------------------------------

    mapping(uint256 => uint256) public _tiers;
    mapping(address => uint256) public _stakingsIdCounter;    
    mapping(address => mapping(uint256 => StakingInfo)) public _stakingsInfo;

    // ---------------------------------------------------------------------------------------------
    // EVENTS
    // ---------------------------------------------------------------------------------------------

    uint256 public MVSPriceForNPT;
    bool public status;
    address private owner;
    uint256 public tiers;
    uint256 public stakingPeriod;

    // ---------------------------------------------------------------------------------------------
    // OWNER SETTERS
    // ---------------------------------------------------------------------------------------------

    function setMVSPriceForNPT(uint price) external onlyOwner {
        MVSPriceForNPT = price;
    }

    function setStakingPeriod(uint period) external onlyOwner {
        stakingPeriod = period;
    }

    function closeEvent() external onlyOwner {
        status = false;
        for(uint i; i < tiers; i++) {
            delete _tiers[i];
        }
        tiers = 0;
        stakingPeriod = 0;
        emit Close (block.timestamp);
    }

    function startEvent(uint[] calldata tiersAmount, uint _stakingPeriod) external onlyOwner {
        status = true;
        for(uint i; i < tiersAmount.length; i++) {
            _tiers[i] = tiersAmount[i];
        }
        tiers = tiersAmount.length;
        stakingPeriod = _stakingPeriod;
        emit Start (block.timestamp);
    }

    // ---------------------------------------------------------------------------------------------
    // PUBLIC SETTERS
    // ---------------------------------------------------------------------------------------------

    function stake(uint256 tier) external {
        require(status, "EVENT_CLOSED!");
        uint tierAmount = _tiers[tier];
        require(IERC20(MVS).balanceOf(msg.sender) >= tierAmount, "NOT_ENOUGH_BALANCE!");
        IERC20(MVS).transferFrom(msg.sender, address(this), tierAmount);
        uint currentIdCounter = _stakingsIdCounter[msg.sender]++;
        _stakingsInfo[msg.sender][currentIdCounter].amount = tierAmount;
        _stakingsInfo[msg.sender][currentIdCounter].unstakeDate = block.timestamp + stakingPeriod;
        emit Stake (msg.sender, tier, tierAmount, _stakingsInfo[msg.sender][currentIdCounter].unstakeDate);
    }

    function unstake(uint id) external {
        require(!_stakingsInfo[msg.sender][id].unstaked, "ALREADY_UNSTAKED!");
        require(block.timestamp >= _stakingsInfo[msg.sender][id].unstakeDate, "CANNOT_STILL_UNSTAKE!");      
        IERC20(MVS).transfer(msg.sender, _stakingsInfo[msg.sender][id].amount);
        _stakingsInfo[msg.sender][id].unstaked = true;
        emit Unstake (msg.sender, _stakingsInfo[msg.sender][id].amount, block.timestamp);
    }

    function swap(uint256 amount) external {
        require(status, "EVENT_CLOSED!");
        require(IERC20(MVS).balanceOf(msg.sender) >= amount, "NOT_ENOUGH_BALANCE!");
        IERC20(MVS).transferFrom(msg.sender, address(this), amount);
        uint NPTAmount = amount / MVSPriceForNPT;
        IERC20(NPT).transferFrom(address(this), msg.sender, NPTAmount);
        emit Swap (msg.sender, amount, NPTAmount);
    }

    // ---------------------------------------------------------------------------------------------
    // BACKUPS 
    // ---------------------------------------------------------------------------------------------

    function withdraw(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    function withdrawTokens(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(msg.sender, amount);
    }

}