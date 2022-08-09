// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./SafeMath.sol";

/**
 * @title Stash
 * @dev Create a Stash token
 */
contract Stash is ERC20, ERC20Burnable {

    constructor() ERC20("Stash", "STH") {
        uint256 _ts = 500000000*10**18;
        _mint(msg.sender, _ts);
        staking_started = false;
    }

    using SafeMath for uint256;
    uint256 startedstake;

    /**
     * @notice We usually require to know who are all the stakeholders.
     */
    address[] internal stakeholders;


    bool internal staking_started = false;

    /**
     * @notice The stakes for each stakeholder.
     */

    mapping(address => uint256) internal stakes;

    /**
    * @notice list of events
    */

    event Staked(address _staker, uint256 _staked_amt, uint256 _time_of_stake);
    event Unstaked(address _unstaker, uint256 _unstake, uint256 _time_at);

    /**
     * @notice The accumulated rewards for each stakeholder.
     */
    mapping(address => uint256) internal rewards;

    // ---------- STAKES ----------

    /**
     * @notice A method for a stakeholder to create a stake.
     * @param _stake The size of the stake to be created.
     */
    function createStake(uint256 _stake)
        public returns(uint256)
    {
        require(staking_started==true, "Staking has not started");
        address staker = msg.sender;
        (bool x, uint256 y) = isStakeholder(staker);
        require(x ==  true && y>=0, "Not a stakeholder");
        _burn(staker, _stake);
        stakes[msg.sender] = stakes[msg.sender].add(_stake);
        emit Staked(staker, _stake, block.timestamp);
        return block.timestamp;
    }


    /**
     * @notice A method for a stakeholder to remove a stake.
     * The total size of the stake to be removed.
     */
    function removeStake()
        public
    {
	  require(staking_started==false, "Staking has not stopped yet");
        address staker = msg.sender;
        (bool x, uint256 y) = isStakeholder(staker);
        require(x ==  true && y>=0, "Not a stakeholder");
        //if(stakes[msg.sender] == 0) removeStakeholder(msg.sender);
        _mint(msg.sender, stakes[msg.sender]);
        emit Unstaked(msg.sender, stakes[msg.sender], block.timestamp);
        stakes[msg.sender] = 0;
    }

    /**
     * @notice A method to retrieve the stake for a stakeholder.
     * @param _stakeholder The stakeholder to retrieve the stake for.
     * @return uint256 The amount of wei staked.
     */
    function stakeOf(address _stakeholder)
        public
        view
        returns(uint256)
    {
        return stakes[_stakeholder];
    }

    /**
     * @notice A method to the aggregated stakes from all stakeholders.
     * @return uint256 The aggregated stakes from all stakeholders.
     */
    function totalStakes()
        public
        view
        returns(uint256)
    {
        uint256 _totalStakes = 0;
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            _totalStakes = _totalStakes.add(stakes[stakeholders[s]]);
        }
        return _totalStakes;
    }

    // ---------- STAKEHOLDERS ----------

    /**
     * @notice A method to check if an address is a stakeholder.
     * @param _address The address to verify.
     * @return bool, uint256 Whether the address is a stakeholder, 
     * and if so its position in the stakeholders array.
     */
    function isStakeholder(address _address)
        public
        view
        returns(bool, uint256)
    {
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            if (_address == stakeholders[s]) return (true, s);
        }
        return (false, 0);
    }

    /**
     * @notice A method to add a stakeholder.
     * @param _stakeholder The stakeholder to add.
     */
    function addStakeholder(address _stakeholder)
        public onlyOwner
    {
        (bool _isStakeholder, ) = isStakeholder(_stakeholder);
        if(!_isStakeholder) stakeholders.push(_stakeholder);
    }

    /**
     * @notice A method to remove a stakeholder.
     * @param _stakeholder The stakeholder to remove.
     */
    function removeStakeholder(address _stakeholder)
        public onlyOwner
    {
        (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
        if(_isStakeholder){
            stakeholders[s] = stakeholders[stakeholders.length - 1];
            stakeholders.pop();
        } 
    }

    // ---------- REWARDS ----------
    
    /**
     * @notice A method to allow a stakeholder to check his rewards.
     * @param _stakeholder The stakeholder to check rewards for.
     */
    function rewardOf(address _stakeholder) 
        public
        view
        returns(uint256)
    {
        return rewards[_stakeholder];
    }

    /**
     * @notice A method to the aggregated rewards from all stakeholders.
     * @return uint256 The aggregated rewards from all stakeholders.
     */
    function totalRewards()
        public
        view
        returns(uint256)
    {
        uint256 _totalRewards = 0;
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            _totalRewards = _totalRewards.add(rewards[stakeholders[s]]);
        }
        return _totalRewards;
    }

    /** 
     * @notice A simple method that calculates the rewards for each stakeholder.
     */
    function calculateReward(uint256 _stakes, uint256 time_in_days)
        internal
        pure
        returns(uint256)
    {
        return (_stakes * 164383562 * time_in_days)/100000000000;
    }

    /**
     * @notice A method to distribute rewards to all stakeholders.
     */
    function distributeRewards(address stakeholder, uint256 _stakes, uint256 _timestamp) 
        public
        onlyOwner
    {
            _timestamp = (block.timestamp - _timestamp) / 1 days;
            uint256 reward = calculateReward(_stakes, _timestamp);
            rewards[stakeholder] = rewards[stakeholder].add(reward);
            ERC20.transfer(stakeholder,reward);
    }



    function startstaking() public onlyOwner{
        require(staking_started == false, "Staking: Staking already started");
        staking_started = true;
        startedstake = block.timestamp;
    }

    function stopstaking() public onlyOwner{
        require(staking_started == true, "Staking: Staking already stopped");
        staking_started = false;
    }
    
    function staking_start_date()public view returns(uint256){
        return startedstake;
    }
}