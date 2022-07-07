/**
 *Submitted for verification at polygonscan.com on 2022-07-07
*/

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: stakePool.sol

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;





interface IGovernanceNFT is IERC721 {
    function mintTokens(address _to, uint tokenId) external;
    function burnTokens(uint tokenId) external;
}
interface IPool {
    function transferFunds(address _tokenAddress, address _to, uint _amount ) external;
    function payRewards(address _to, uint _amount ) external;
}

contract distributorContract is Ownable, ReentrancyGuard {



        struct nftDetails {
                uint poolId;
                uint termId;
                uint weightageEquivalent;
                uint stakeAmount;
                uint stakeTime;
                uint lastClaimTime;
                address _currentOwner;
                address _tokenAddress;
        }
        IERC20 public token;
        // uint public rewardsTax;
        address public insuranceFundAddress=0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
        uint public minimumTimeQuantum = 1 minutes;
        address[4] public collectionPools;
        address[4] public governanceTokenAddress;
        uint[4] public nftIndexPerPool = [0,0,0,0];
        uint[4] public aprPercent = [0,25,50,100]; //2.5%,5%,10%
        uint[4] public weightageCalculationPercentagePerPool = [0,200,150,100];
        uint[3] public lockQuantumPerPool = [0,10 minutes, 20 minutes];
        uint[4] public investmentDistribution=[0,40,40,20];
        // tokenId => poolId => nftDetails
        mapping (uint =>  mapping( uint => nftDetails)) detailsPerNftId;
        mapping (uint => mapping (address => uint)) poolMapper;
        mapping (address => bool) public authorisedCaller;
        mapping (address => bool) public whitelistedTokens;
        // user => tokenAddress => poolId => termId
        mapping (address => mapping (address => mapping (uint => uint))) public currentTermIdForUserPerPool;
        //get invested amount in Each pool
        mapping(uint=>uint) public totalInvestedInEachPool;
        // total funds in treasuryPool
        mapping(uint=>uint) public totalTreasuryFunds;
        // total funds in Rewards
          mapping(uint=>uint) public totalrewardFunds;
        // total funds in marketing
        mapping(uint=>uint) public totalMarketingFunds;
        //track rewards using userAddress and poolId
        mapping(address =>mapping(uint=>uint)) public givenRewards;
        //Rewards giveAway per pool
        mapping(uint=>uint) public totalPoolRewards;
        constructor(address _address){
            token=IERC20(_address);
        }

           

        event Treasury(address _from, address _to,uint amount);
        event Rewards(address _from, address _to,uint amount);
        event Marketing(address _from, address _to,uint amount);

        function deposit (uint poolId, address tokenAddress, uint tokenAmount) external nonReentrant {
                require (poolId > 0 && poolId < 4, 'Error: Invalid Pool Ids');
                require (whitelistedTokens[tokenAddress],'Error: Token Not Whitelisted');
                uint tokenAmounts = (tokenAmount * 1 ether);
    
                uint termId = ++currentTermIdForUserPerPool[msg.sender][tokenAddress][poolId];
                uint weightageEquivalent = calculateGovernanceToken(poolId, tokenAmount);
                uint currentIndexOfPool = nftIndexPerPool[poolId]+1;
                ++nftIndexPerPool[poolId];
                poolMapper[currentIndexOfPool][governanceTokenAddress[poolId]] = poolId;
                totalInvestedInEachPool[poolId]+=tokenAmounts;
                uint treasury= (tokenAmounts *investmentDistribution[1])/100;  
                if (poolId == 1) {
                        uint insuranceAmount = treasury *1/100;
                        treasury -= insuranceAmount;
                        token.transferFrom(msg.sender, insuranceFundAddress, insuranceAmount);
                } 
                uint rewards= (tokenAmounts*investmentDistribution[2])/100;
                uint marketing= (tokenAmounts*investmentDistribution[3])/100;
                 totalTreasuryFunds[poolId]+=treasury;
                 totalrewardFunds[poolId]+=rewards;
                 totalMarketingFunds[poolId]+=marketing;
                nftDetails storage details = detailsPerNftId[currentIndexOfPool][poolId];
                details.poolId =poolId;
                details.termId =termId;
                details.weightageEquivalent =weightageEquivalent;
                details.stakeAmount = tokenAmounts;
                details.stakeTime = block.timestamp;
                details.lastClaimTime = block.timestamp;
                details._currentOwner =msg.sender;
                details._tokenAddress =tokenAddress;
               token .transferFrom(msg.sender, collectionPools[poolId], treasury);
               token .transferFrom(msg.sender, collectionPools[poolId], rewards);
               token .transferFrom(msg.sender, collectionPools[poolId], marketing);
               IGovernanceNFT(governanceTokenAddress[poolId]).mintTokens(msg.sender, nftIndexPerPool[poolId]);
        }


        function claimFunds (uint[] memory poolIds, uint[] memory _nftIds) external nonReentrant {
                require(poolIds.length == _nftIds.length,'Error: Array length Not Equal');
                
                for (uint i=0; i< poolIds.length; i++) {
                        require (IGovernanceNFT(governanceTokenAddress[poolIds[i]]).ownerOf(_nftIds[i]) == msg.sender,'Error: Caller Not Owner');
                        uint amount = (getRewardDetails(poolIds[i], _nftIds[i]));
                        if(poolIds[i]==1){
                            uint insure= (amount*5)/100;
                            amount-=insure;
                             IPool(collectionPools[poolIds[i]]).payRewards(msg.sender, insure);
                        }else{
                            amount=amount-((amount*10)/100);
                        }
                        nftDetails storage details = detailsPerNftId[_nftIds[i]][poolIds[i]];
                        details.lastClaimTime = block.timestamp;
                        require(amount > 0 ,'Error: Not Enough Reward Collected');
                        IPool(collectionPools[poolIds[i]]).payRewards(msg.sender, amount);
                        givenRewards[msg.sender][poolIds[i]]+=amount;
                        totalPoolRewards[poolIds[i]]+=amount;
                }

        }


      function investBack(uint poolId, uint _nftId) external{
          uint amount= getRewardDetails(poolId, _nftId);
          detailsPerNftId[_nftId][poolId].stakeAmount+=amount;
          nftDetails storage details = detailsPerNftId[_nftId][poolId];
          details.lastClaimTime = block.timestamp;
        }

        function unstakeTokens (uint[] memory poolIds, uint[] memory _nftIds) external nonReentrant {
                require(poolIds.length == _nftIds.length,'Error: Array length Not Equal');
                for (uint i=0; i< poolIds.length; i++) {
                        require (IGovernanceNFT(governanceTokenAddress[poolIds[i]]).ownerOf(_nftIds[i])==msg.sender,'Error: Caller Not Owner');
                        uint poolId = poolIds[i];
                        address tokenAddress = detailsPerNftId[_nftIds[i]][poolId]._tokenAddress;
                        uint amountToReturn = detailsPerNftId[_nftIds[i]][poolId].stakeAmount;
                        require (block.timestamp > detailsPerNftId[_nftIds[i]][poolId].stakeTime + lockQuantumPerPool[poolId],'Error: Lock Period Not Over');
                        if(poolIds[i]==1){
                            uint insurance= (amountToReturn * 10)/100 ;
                            amountToReturn-=insurance;
                           IPool(collectionPools[poolId]).transferFunds(tokenAddress,insuranceFundAddress,insurance); 
                        }
                        delete currentTermIdForUserPerPool[msg.sender][tokenAddress][poolId];
                        delete poolMapper[_nftIds[i]][governanceTokenAddress[poolId]];
                        delete detailsPerNftId[_nftIds[i]][poolId];
                        IGovernanceNFT(governanceTokenAddress[poolId]).burnTokens(_nftIds[i]);
                        IPool(collectionPools[poolId]).transferFunds(tokenAddress,msg.sender,amountToReturn);
                }
        }


        function getRewardDetails(uint poolId, uint _nftId) public view returns(uint) {
                uint amount = detailsPerNftId[_nftId][poolId].stakeAmount;
                uint lastClaimTime = detailsPerNftId[_nftId][poolId].lastClaimTime;
                uint finalAmount;
                uint time;
                if (block.timestamp > lastClaimTime + minimumTimeQuantum)
                {
                        finalAmount = (amount - ((amount * (1000 - aprPercent[poolId])) / 1000));
                        time = (block.timestamp - lastClaimTime + minimumTimeQuantum)/minimumTimeQuantum;

                }
                return time * finalAmount;
        }


        function calculateGovernanceToken(uint poolId, uint tokenAmount) internal view returns(uint) {
                return (tokenAmount * weightageCalculationPercentagePerPool[poolId]) / 1000;
        }

        function viewNftDetails (uint tokenId, uint poolId) external view returns(nftDetails memory) {
                return detailsPerNftId[tokenId][poolId];
        }

        function addCollectionPoolAddresses (address pool1, address pool2, address pool3) external onlyOwner {
                collectionPools = [address(0),pool1,pool2,pool3];
        }

        function addGovernanceTokenAddress (address _pool1GovernanceToken, address _pool2GovernanceToken, address _pool3GovernanceToken) external onlyOwner {
                governanceTokenAddress = [address(0),_pool1GovernanceToken,_pool2GovernanceToken,_pool3GovernanceToken];
        }

        function addInsuranceFundAddress (address _insuranceFundAddress) external onlyOwner {
                insuranceFundAddress = _insuranceFundAddress;
        }

        function whitelistTokenAddresses (address[] memory addresses) external onlyOwner {
                for (uint i =0; i<addresses.length; i++) {
                        require (!whitelistedTokens[addresses[i]], 'Error: Already Whitelisted');
                        whitelistedTokens[addresses[i]] = true;
                }
        }

        function blackListWhitelistedTokenAddresses (address[] memory addresses) external onlyOwner {
                for (uint i =0; i<addresses.length; i++) {
                        require (whitelistedTokens[addresses[i]], 'Error: Already BlackListed or Never Whitelisted');
                        whitelistedTokens[addresses[i]] = false;
                }
        }

        function addAuthorisedCaller(address _caller) external onlyOwner {
                authorisedCaller[_caller] = true;
        }

        function removeAuthorisedCaller(address _caller) external onlyOwner {
                authorisedCaller[_caller] = false;
        }

        function changeMinimumQuantum(uint time) external onlyOwner {
                minimumTimeQuantum = time;
        }

        function changeLockQuantumPerPool(uint[3] memory time) external onlyOwner {
                lockQuantumPerPool = time;
        }

        function changeAPR(uint[4] memory apr) external onlyOwner {
                aprPercent = apr;
        }

        function changeWeightageCalculationPercentagePerPool(uint[4] memory weightage) external onlyOwner {
                weightageCalculationPercentagePerPool = weightage;
        }

        function changeDetailsOfInvestors(address _to, address _nftAddress, uint _tokenId) external {
                require (authorisedCaller[msg.sender],'Error: Caller Not Authorised');
                uint poolId = poolMapper[_tokenId][_nftAddress];
                address _tokenAddress = detailsPerNftId[_tokenId][poolId]._tokenAddress;
                uint newTermId = ++currentTermIdForUserPerPool[_to][_tokenAddress][poolId];
                nftDetails storage details = detailsPerNftId[_tokenId][poolId];
                details._currentOwner = _to;
                details.termId = newTermId;
        }
        function setToken(address _tokenAddress) external onlyOwner{
         token=IERC20(_tokenAddress);
        }

        function setPoolDistributions(uint[4] memory _DistributionPercent) external onlyOwner{
            investmentDistribution=_DistributionPercent;
        }
        
}