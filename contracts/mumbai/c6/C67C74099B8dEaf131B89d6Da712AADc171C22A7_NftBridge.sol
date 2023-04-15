// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;

interface CallProxy{
    function anyCall(
        address _to,
        bytes calldata _data,
        uint256 _toChainID,
        uint256 _flags,
        bytes calldata
    ) payable external;

    function anySwapOutUnderlyingAndCall(
        address _token,
        string calldata _to,
        uint256 _amount,
        uint256 _toChainID,
        string calldata _anyCallProxy,
        bytes calldata _data
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;

import "../ProxyPattern/SolidlyImplementation.sol";
import "../interfaces/CallProxy.sol";

interface IVe {
     struct LockedBalance {
        int128 amount;
        uint256 end;
    }

    function locked(uint256 _tokenId) external view returns (LockedBalance memory);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function slope_changes(uint256 _endTime) external view returns (int128);
    function point(uint256 _tokenId) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function merge(uint256 from, uint256 to) external;
    function split(uint256 tokenId, uint256 amount) external returns (uint256);

    function increase_unlock_time(uint256 _tokenId, uint256 _lock_duration)
        external;
    
    function epoch() external view returns (uint256);
}

interface IVoter {
    function vote(uint256 _tokenId, address[] memory poolVotes, uint256[] memory weights) external;
    function activePeriod() external view returns (uint256);
   function active_period() external view returns (uint256);
}

interface IVe_Dist {
    function claim(uint256 _tokenId) external; 
}

contract NftBridge is SolidlyImplementation {

    uint256 private constant MAX_LOCK = 4 * 52 * 1 weeks;
    uint256 public voteDelay;

    // Addresses we use
    CallProxy public callproxy; // Anycall contract called for bridging NFT 
    address public executor; // Anycall executor which bridges data back to mainnet
    address public voter; // Solidly Voter
    
    address public ve; // NFT
    address public ve_dist;

    address[] public rewardsDistributor; // The "ChildChainGauge" Reward Receiver 
    uint256[] public voteWeights; // Will just be [1e18] 100% vote for reward distributor
    uint256[] public chains; // Our chains array, push when goverances adds a new chain
    uint256 public masterTokenId; // The NFT ID we pass in intitialize
    uint256 public totalBridgedBase; // Total bridged base, will differ from our locked supply because we claim emissions
    uint256 public totalShares;

    /// Structs
    struct UserInfo { 
        address ownerOf;
        uint256 firstEpoch;
        uint256 amount;
    }

    struct UserData {
        uint256 bridgedTotal;
        uint256 shares;
        uint256 bridgedOutPeriod;
        mapping (uint256 => uint256) chainBalances;
    }

    /// Mappings
    mapping (uint256 => address) public childChainVe; // ChainId -> ChildChain Ve contract which handles NFT
    mapping (address => mapping(uint256 => UserData)) public userData; // Map the user to NFTs to their UserData
    mapping (uint256 => address) public ownerOf; // Map user to bridged NFT  ID. 
    mapping (uint256 => uint256) public chainBalances; // ChainId -> Locked Solid Balance in Total
    mapping (uint256 => bytes) public errors; // Map bridge errors to timestampe of error. 
    mapping (uint256 => bool) public isPaused; // Is chain paused?
    mapping(address => bool) public isOperator;

    bool public paused;

    event ChildChainVeAdded(uint256 indexed chainId, address ve);
    event VoteDelaySet(uint256 delay);
    event NftBridged(address indexed user, uint256 indexed tokenId, uint256 indexed chainId, uint256 amount);
    event NftClaimed(address indexed user, uint256 indexed oldTokenId, uint256 indexed newTokenId, uint256 amount);
    event NftBurned(address indexed user, uint256 indexed tokenId, uint256 indexed chainId, uint256 amount);

    event SetAnycall(address oldProxy, address newProxy, address oldExec, address newExec);
    event SetOperator(address newOperator, bool status);
    event Error(uint256 indexed errorTime);
    event Paused();
    event Unpaused();
    event ChainPaused(uint256 indexed chainId);
    event ChainUnpaused(uint256 indexed chainId);

    // Only anycall executor can call
    modifier onlyAuth() {
        require(msg.sender == executor, "Solidly: !Auth");
        _;
    }

     modifier onlyOperator() {
        require(isOperator[msg.sender], "Solidly: !Operator");
        _;
    }

    modifier whenNotPaused() {
        require(paused == false, "Solidly: paused");
        _;
    }

    function initialize (
        address _callproxy,
        address _executor,
        address _voter, 
        address _ve, 
        address _ve_dist,
        address _rewardsDistributor,
        uint256 _tokenId
    ) external onlyGovernance notInitialized {
        callproxy = CallProxy(_callproxy);
        executor = _executor;
        voter = _voter;
        ve = _ve;
        ve_dist = _ve_dist;
        rewardsDistributor.push(_rewardsDistributor);
        voteWeights.push(1e18);
        voteDelay = 1 weeks - 1 hours; // Can vote within one hour of end of epoch.
        isOperator[msg.sender] = true;

        _initMasterTokenId(_tokenId);
    }

    function _initMasterTokenId(uint256 _tokenId) private {
        require (masterTokenId == 0, "Solidly: masterToken already set");

        // Donation
        IVe(ve).safeTransferFrom(msg.sender, address(this), _tokenId);
        masterTokenId = _tokenId;
    }

    // Pass and array of Child Chain IDs
    function childChains() external view returns (uint256[] memory _chains) {
        return chains;
    }

    // Total underlying Solid locked in master veNFT
    function totalLocked() public view returns (uint256) {
        return abi.decode(abi.encode(IVe(ve).locked(masterTokenId).amount),(uint256));
    }

    // Public claim of veRebase
    function claimVeRebase() external {
        IVe_Dist(ve_dist).claim(masterTokenId);
    }

    // public increase of unlockTime
    function increaseUnlockTime() public {
        (,,bool shouldLock) = lockInfo();
        if (shouldLock) {
             IVe(ve).increase_unlock_time(masterTokenId, MAX_LOCK);
        }
    }

    function lockInfo() public view returns (uint256 endTime, uint256 secondsRemaining, bool shouldIncreaseLock) {
        endTime = IVe(ve).locked(masterTokenId).end;
        uint256 unlockTime = (block.timestamp + MAX_LOCK) / 1 weeks * 1 weeks;
        secondsRemaining = endTime > block.timestamp ? endTime - block.timestamp : 0;
        shouldIncreaseLock = unlockTime > endTime ? true : false;
    }
    
    // Internal check to make sure user has no existing bridged NFTs
    function _checkUserChainBalances(address _user, uint256 _tokenId) private view {
        for (uint i; i < chains.length;) {
            require(userData[_user][_tokenId].chainBalances[chains[i]] == 0, "Solidly: NFT Still Bridged");
            unchecked { ++i; }
        }
    }

    function _checkIfValidChain(uint256 _chainId) private view {
            require(childChainVe[_chainId] != address(0), "Solidly: Not valid chain");
            require(!isPaused[_chainId], "Solidly: Chain paused");
    }
   
    /** 
    * @notice Main Bridge NFT Function
    * @param _to = Address to receive NFTs on child chains
    * @param _chainIds = ChainID Array of bridge to chains
    * @param _tokenId = User NFT TokenId
    * @param _amounts = How much of their NFT is used for each chain
    * @param _feeInEther = We have to calc the calldata cost from anycall contract, have the user pay that in ETH for execution. 
    */
    function bridgeOutNft(
        address _to, 
        uint256[] calldata _chainIds, 
        uint256 _tokenId, 
        uint256[] calldata _amounts, 
        uint256[] calldata _feeInEther
    ) external payable whenNotPaused {
        require (ownerOf[_tokenId] == address(0), "Solidly: NFT already bridged");
        require (IVe(ve).ownerOf(_tokenId) == msg.sender, "Solidly: !owner");
        
        // If we can lock, max lock again;
        increaseUnlockTime();

        // Set ownerOf to msg.sender, non transferable. Transfer NFT to bridge.
        ownerOf[_tokenId] = msg.sender;
        IVe(ve).safeTransferFrom(msg.sender, address(this), _tokenId);

        uint256 userTotalLocked = abi.decode(abi.encode(IVe(ve).locked(_tokenId).amount), (uint256));

       _bridgeOutNft(_to, _chainIds, _tokenId, _amounts, userTotalLocked, _feeInEther);
    }

    function _bridgeOutNft(
        address _to,
        uint256[] calldata _chainIds, 
        uint256 _tokenId, 
        uint256[] calldata _amounts,
        uint256 _userTotalLocked, 
        uint256[] calldata _feeInEther
    ) private {
        uint256 totalWeight; 
         for (uint i; i < _amounts.length;) {
            totalWeight += _amounts[i];
            unchecked { ++i;}
        }
        
        for (uint i; i < _chainIds.length;) {
            
            uint256 chainId = _chainIds[i];
         //   _checkIfValidChain(chainId);
            uint256 amount = (_amounts[i] * _userTotalLocked) / totalWeight;
        ///   UserInfo memory userInfo = UserInfo({
          //      ownerOf: _to,
          //      firstEpoch: IVe(ve).epoch(),
          //      amount: amount
         //   });
        
            userData[msg.sender][_tokenId].chainBalances[chainId] = amount;
            chainBalances[chainId] += amount;

        //    bytes memory data = abi.encode(_tokenId, userInfo.firstEpoch, IVe(ve).totalSupply(), userInfo);
        //    callproxy.anyCall{value: _feeInEther[i]}(
        //        childChainVe[chainId], // Child Chain Ve contract
        //        data, // our encoded data
        //        chainId, // Chain Id we are sending info to
         //       0, // Charge Fees on Src Chain
         //       '0x'
        //    );
            
            emit NftBridged(msg.sender, _tokenId, chainId, amount);
            unchecked { ++i;}
        }

        if (totalShares == 0) {
            totalShares = _userTotalLocked;
            userData[msg.sender][_tokenId].shares = _userTotalLocked;
        } else {
            uint256 shares = (_userTotalLocked * totalShares) / totalLocked();
            totalShares += shares;
            userData[msg.sender][_tokenId].shares = shares;
        }

        
        // Update user and nft total info
        userData[msg.sender][_tokenId].bridgedTotal = _userTotalLocked;
       // userData[msg.sender][_tokenId].bridgedOutPeriod = IVoter(voter).activePeriod();
       userData[msg.sender][_tokenId].bridgedOutPeriod = IVoter(voter).active_period();
        
        totalBridgedBase += _userTotalLocked;
        
        // Finally, merge the users nft to our master nft
        IVe(ve).merge(_tokenId, masterTokenId);
    } 

    /**
    * @notice Configure Weights NFT Function. Must have burned all child chain nfts first. 
    * @param _to = Address to receive NFTs on child chains
    * @param _chainIds = ChainID Array of bridge to chains
    * @param _tokenId = User NFT TokenId
    * @param _amounts = How much of their NFT is used for each chain
    * @param _feeInEther = We have to calc the calldata cost from anycall contract, have the user pay that in ETH for execution. 
    */
    function configureChildChainWeights(
        address _to, 
        uint256[] calldata _chainIds, 
        uint256 _tokenId, 
        uint256[] calldata _amounts, 
        uint256[] calldata _feeInEther
    ) external payable whenNotPaused {
        require(msg.sender == ownerOf[_tokenId], "Solidly: Not Owner");
        _checkUserChainBalances(msg.sender, _tokenId);

        _configureChildChainWeights(_to, _chainIds, _tokenId, _amounts, _feeInEther);
    }

    function _configureChildChainWeights(
        address _to,
        uint256[] calldata _chainIds, 
        uint256 _tokenId, 
        uint256[] calldata _amounts, 
        uint256[] calldata _feeInEther
    ) private {
        uint256 userTotalLocked = userData[msg.sender][_tokenId].bridgedTotal;
        uint256 totalWeight;

        for (uint i; i < _amounts.length;) {
            totalWeight += _amounts[i];
            unchecked { ++i;}
        }

        for (uint i; i < _chainIds.length;) {
            uint256 chainId = _chainIds[i];
            _checkIfValidChain(chainId);
            uint256 amount = _amounts[i] * userTotalLocked / totalWeight;
            UserInfo memory userInfo = UserInfo({
                ownerOf: _to,
                firstEpoch: IVe(ve).epoch(),
                amount: amount
            });

            userData[msg.sender][_tokenId].chainBalances[chainId] = amount;
            chainBalances[chainId] += amount;
            bytes memory data = abi.encode(_tokenId, userInfo.firstEpoch, IVe(ve).totalSupply(), userInfo);

            callproxy.anyCall{value: _feeInEther[i]}(
                childChainVe[chainId], // Child Chain Ve contract
                data, // our encoded data
                chainId, // Chain Id we are sending info to
                0, // Charge Fees on Src Chain
                '0x'
            );

            emit NftBridged(msg.sender, _tokenId, chainId, amount);
            unchecked { ++i;}
        }
    }

    function claimNft(uint256 _tokenId) external {
        require(ownerOf[_tokenId] == msg.sender, "Solidly: Not Owner");
        require(IVoter(voter).activePeriod() != userData[msg.sender][_tokenId].bridgedOutPeriod, "Solidly: wait a period");
        uint256 balance = userData[msg.sender][_tokenId].bridgedTotal;
        uint256 shares = userData[msg.sender][_tokenId].shares;
        
        // Reset user data 
        userData[msg.sender][_tokenId].bridgedTotal = 0;
        userData[msg.sender][_tokenId].shares = 0;
        userData[msg.sender][_tokenId].bridgedOutPeriod = 0;

        require(balance != 0, "Solidy: No Balance");
        _checkUserChainBalances(msg.sender, _tokenId);

        // Since total lock will increase with emissions
        // we give a ratio of shares vs total shares to the user.
        uint256 tokenAmount = shares * totalLocked() / totalShares;
        totalBridgedBase -= balance;
        delete ownerOf[_tokenId]; 

        // Split NFT and send the new token to the user. 
        uint256 newTokenId = IVe(ve).split(masterTokenId, tokenAmount);
        IVe(ve).safeTransferFrom(address(this), msg.sender, newTokenId);
        emit NftClaimed(msg.sender, _tokenId, newTokenId, tokenAmount);
    }

    // Can only vote once, should be done right before epoch end so we set delay attached to activePeriod on voter. 
    function vote() external {

        // Right now onlyGovernance but can be made to only vote right before epoch
        require(block.timestamp >= IVoter(voter).activePeriod() + voteDelay, "Solidly: Voting too early");
        increaseUnlockTime();
        IVoter(voter).vote(masterTokenId, rewardsDistributor, voteWeights);
    }

    function anyExecute(bytes calldata data) external onlyAuth returns (bool success, bytes memory result) {
       try this._exec(data) returns (
            bool succ,
            bytes memory res
        ) {
            (success, result) = (succ, res);
        } catch Error(string memory reason) {
            result = bytes(reason);
        } catch (bytes memory reason) {
            result = reason;
        }

        if (!success) {
            // process failure situation
            errors[block.timestamp] = data;
            emit Error(block.timestamp);
        }
    }   

    function _exec(bytes memory _data) public returns (bool success, bytes memory result) {
        require(msg.sender == address(this), "Solidly: !allowed");

        (uint256 tokenId, uint256 chainId) = abi.decode(_data, (uint256,uint256));
        
        address user = ownerOf[tokenId];
        uint256 amount = userData[user][tokenId].chainBalances[chainId];
        chainBalances[chainId] -= amount; // End up with unclaimed NFTs weight being distributed amongst all chains
        userData[user][tokenId].chainBalances[chainId] = 0;
       

        emit NftBurned(ownerOf[tokenId], tokenId, chainId, amount);
        
        return (
            true, 
            '0x'
        );
    }

    // If there is an error, hopefully wont/shouldnt happen. We can retry processing the data. 
    function retryError(uint256 _timestamp) external {
        require(errors[_timestamp].length > 0, "Solidly: No Error");

        (address user, uint256 tokenId, uint256 chainId, uint256 _amount) = abi.decode(errors[_timestamp], (address,uint256,uint256,uint256));
        
        userData[user][tokenId].chainBalances[chainId] = 0;
        chainBalances[chainId] -= _amount; // End up with unclaimed NFTs weight being distributed amongst all chains

        emit NftBurned(ownerOf[tokenId], tokenId, chainId, _amount);
    }

    /// Setters /// 
    function addChildChainVe(uint256 _chainId, address _ve, bool _init) external onlyGovernance {
        if (_init && childChainVe[_chainId] == address(0)) chains.push(_chainId);
        childChainVe[_chainId] = _ve;
        emit ChildChainVeAdded(_chainId, _ve);
    }

    function setVoteDelay(uint256 _delay) external onlyGovernance {
        voteDelay = 1 weeks - _delay;
        emit VoteDelaySet(voteDelay);
    }
    function setPaused(bool _status) external onlyGovernance {
        paused = _status;
        if (paused) emit Paused();
        else emit Unpaused();
    }

    function setOperator(address _operator, bool _status) external onlyGovernance {
        emit SetOperator(_operator, _status);
        isOperator[_operator] = _status;
    }
  
    function setAnycallAddresses(CallProxy _proxy, address _executor) external onlyGovernance {
        emit SetAnycall(address(callproxy), address(_proxy), executor, _executor);
        callproxy = CallProxy(_proxy);
        executor = _executor;
    }

    /// Pause chain, stop bridging NFT and reallocate solid to all other chains
    function pauseChain(uint256 _chainId) external onlyOperator {
        isPaused[_chainId] = true;
        emit ChainPaused(_chainId);
    }

    function unpauseChain(uint256 _chainId) external onlyOperator {
        isPaused[_chainId] = false;
        emit ChainUnpaused(_chainId);
    }

    function onERC721Received(
        address _operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external view returns (bytes4) {
        _operator;
        from;
        tokenId;
        data;
        require(msg.sender == address(ve), "Solidly: !veToken");
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;

/**
 * @title Solidly+ Implementation
 * @author Solidly+
 * @notice Governable implementation that relies on governance slot to be set by the proxy
 */
contract SolidlyImplementation {
    bytes32 constant GOVERNANCE_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103; // keccak256('eip1967.proxy.admin')
    bytes32 constant INITIALIZED_SLOT =
        0x834ce84547018237034401a09067277cdcbe7bbf7d7d30f6b382b0a102b7b4a3; // keccak256('eip1967.proxy.initialized')

    /**
     * @notice Reverts if msg.sender is not governance
     */
    modifier onlyGovernance() {
        require(msg.sender == governanceAddress(), "Only governance");
        _;
    }

    /**
     * @notice Reverts if contract is already initialized
     * @dev U4sed by implementations to ensure initialize() is only called once
     */
    modifier notInitialized() {
        bool initialized;
        assembly {
            initialized := sload(INITIALIZED_SLOT)
            if eq(initialized, 1) {
                revert(0, 0)
            }
            sstore(INITIALIZED_SLOT, 1)
        }
        _;
    }

    /**
     * @notice Fetch current governance address
     * @return _governanceAddress Returns current governance address
     */
    function governanceAddress()
        public
        view
        virtual
        returns (address _governanceAddress)
    {
        assembly {
            _governanceAddress := sload(GOVERNANCE_SLOT)
        }
    }
}