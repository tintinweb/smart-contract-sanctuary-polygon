// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract PoolConfigEpsilon {
    struct Pool {
        uint256 minInvest;
        uint256 maxInvest;
        uint256 maxMembers;
        uint8 votingThreshold;
        uint256 votingTime;
        uint256 minYesVoters;
    }

    mapping(address => Pool) pools;
    mapping(address => bool) poolExists;

    function setupPool(
        address _pool,
        uint256 _minInvest,
        uint256 _maxInvest,
        uint256 _maxMembers,
        uint8 _votingThreshold,
        uint256 _votingTime,
        uint256 _minYesVoters
    ) public {
        require(!poolExists[_pool], "Pool already Exists");
        require(_votingThreshold <= 100, "Invalid Voting Threshold (0-100)");
        require(_votingTime > 0, "Invalid Voting Time");
        require(_maxMembers > 0, "Invalid MaxMembers");
        require(_minYesVoters > 0, "Invalid minYesVoters");
        require(_minInvest > 0, "Invalid minInvest");
        require(
            _maxInvest >= _minInvest,
            "maxInvest must be larger than minInvest"
        );

        poolExists[_pool] = true;
        pools[_pool].minInvest = _minInvest;
        pools[_pool].maxInvest = _maxInvest;
        pools[_pool].maxMembers = _maxMembers;
        pools[_pool].votingThreshold = _votingThreshold;
        pools[_pool].votingTime = _votingTime;
        pools[_pool].minYesVoters = _minYesVoters;
    }

    function minInvest(address _pool) public view returns (uint256) {
        return pools[_pool].minInvest;
    }

    function maxInvest(address _pool) public view returns (uint256) {
        return pools[_pool].maxInvest;
    }

    function maxMembers(address _pool) public view returns (uint256) {
        return pools[_pool].maxMembers;
    }

    function votingThreshold(address _pool) public view returns (uint8) {
        return pools[_pool].votingThreshold;
    }

    function votingTime(address _pool) public view returns (uint256) {
        return pools[_pool].votingTime;
    }

    function minYesVoters(address _pool) public view returns (uint256) {
        return pools[_pool].minYesVoters;
    }

    function modifyMaxMembers(uint256 _maxMembers) public {
        pools[msg.sender].maxMembers = _maxMembers;
    }

    function modifyVotingThreshold(uint8 _votingThreshold) public {
        require(
            _votingThreshold >= 0 && _votingThreshold <= 100,
            "Invalid Voting Threshold (0-100)"
        );
        pools[msg.sender].votingThreshold = _votingThreshold;
    }

    function modifyVotingTime(uint256 _votingTime) public {
        require(_votingTime > 0, "Invalid Voting Time");
        pools[msg.sender].votingTime = _votingTime;
    }

    function modifyMinYesVoters(uint256 _minYesVoters) public {
        require(_minYesVoters > 0, "Invalid Value for minYesVoters");
        pools[msg.sender].minYesVoters = _minYesVoters;
    }

    function memberCanJoin(
        address _pool,
        uint256 _amount,
        uint256 _invested,
        uint256 _tokenPrice,
        uint256 _members
    ) public view returns (bool, string memory) {
        if (_amount < pools[_pool].minInvest) {
            return (false, "Stake is lower than minInvest");
        }
        if (_amount < _tokenPrice) {
            return (false, "Stake is lower than price of one Governance Token");
        }
        if (_invested + _amount > pools[_pool].maxInvest) {
            return (false, "Stake is higher than maxInvest");
        }
        if (_members >= pools[_pool].maxMembers) {
            return (false, "Member Limit reached");
        }
        return (true, "");
    }

    function getConfig(address _pool)
        public
        view
        returns (
            uint256 _minInvest,
            uint256 _maxInvest,
            uint256 _maxMembers,
            uint8 _votingThreshold,
            uint256 _votingTime,
            uint256 _minYesVoters
        )
    {
        Pool memory pool = pools[_pool];
        return (
            pool.minInvest,
            pool.maxInvest,
            pool.maxMembers,
            pool.votingThreshold,
            pool.votingTime,
            pool.minYesVoters
        );
    }
}