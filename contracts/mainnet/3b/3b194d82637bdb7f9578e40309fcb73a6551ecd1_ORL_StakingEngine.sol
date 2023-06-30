/**
 *Submitted for verification at polygonscan.com on 2023-06-30
*/

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


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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

// File: contracts/ORL_Staking_New.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;




error NFTOwnershipIssue();
error NotEnoughMatic();
error NotEnoughPearls();
error PearlTransferIssue();
error NotTeamMember();
error alreadyRegistered();
error MaticTransferIssue();
error StakingIsPaused();
error StakedMoreThanMax();

    struct raceRules{
        address conCheck;
        uint8 gridSize;
        uint8 conValue;
        uint8 maxQty;
        uint matPrice;
        uint prlPrice;     
    }

    struct walletInfo {
        uint16 wAnchor;
        uint16 wAssistant;
        uint16 wEquip;
        uint16 wBench;
        address anchorContract;
        address assistContract;
        address equipContract;
        address benchContract;
    }

        struct performance{
        address nftContract;
        address owner;
        uint16 id;
        uint8 leg1;
        uint8 leg2;
        uint8 leg3;
        uint8 eventWanted;
    }

    struct funchecks{
        uint count;
        uint mTotal;
        uint pTotal;
        uint money;
        uint pearls;
        uint num;
        uint8 newn;
        uint16 tempstaked;
        address own;
    }


interface RacerInterface {
    function tokensOfOwner(address _owner) external view returns (uint[] memory);
}

contract ORL_StakingEngine is Ownable {

    //Pearls
    //Local address
    //address internal constant tokenAddress = address(0xd9145CCE52D386f254917e481eB44e9943F39138); 
    //Mumbai address
    //address internal constant tokenAddress = address(0x3B782594595096f1c854A606945980834b8a0e0c);
    //Polygon address
    address internal constant tokenAddress = address(0xCAf44e62003De4B8bD17c724f2B78CC532550C2F); 
    IERC20 internal constant rewardToken = IERC20(tokenAddress);

    //Racers
    //Local address
    //address internal constant erc721Contract = address(0xd8b934580fcE35a11B58C6D73aDeE468a2833fa8);
    //Mumbai Address
    //address internal constant erc721Contract = address(0x6De8482cA107bc87AA23208fEE28C5b160FD3E6c);
    //Polygon Address
    address internal constant erc721Contract = address(0x72106Bbe2b447ECB9b52370Ddc63cfa8e553B08C);
    IERC721 internal constant stakeableNFT = IERC721(erc721Contract);
    
    //Customs
    //Local address
    //address internal constant customAddress = 0xf8e81D47203A594245E36C48e151709F0C19fBe8;
    //Mumbai Address
    //address internal constant customAddress = 0x6Dc9207608Ac27Eb68B7E76B39C193F98284D9a7;
    //Polygon address
    address internal constant customAddress = 0xabA082D325AdC08F9a1c5A8208Bb5c42B3A6F978;
    IERC721  internal constant customContract = IERC721(customAddress);

    bool internal paused;
    uint immutable deployT;
    uint16 public currentWeek = 7; 

    //walletByWeek[week][walletID].walletInfo
    mapping(uint16 => mapping(address => walletInfo)) public walletByWeek;
    
    //mapping(address => uint) public walletToID;
    //address[] public walletID;

    mapping(address => bytes1) internal isTeamMember;

    //[week][id].raceRules
    mapping(uint16 => mapping(uint16 => raceRules)) public rulesByRace;

    //[week][slotid].performance
    mapping(uint16 => mapping(uint16 => performance)) public perfByRacer;

    //[week][racer contract][racer id]
    mapping(uint16 => mapping(address => mapping(uint16 => uint16))) public slotByRacer;

    //[week][wallet][tier] count
    mapping(uint16 => mapping(address => mapping(uint8 => uint16))) internal tierCount; 


    mapping(uint16 => uint16) public currentlyStaked;

    constructor() {
        isTeamMember[msg.sender] = "1";
        deployT = block.timestamp;
    }

    // ADMIN //

    function createEvent(uint16 _id, uint8 _size, address _conCheck, uint8 _conValue, uint8 _maxqty, uint _matP, uint _nutP) public {
        if(isTeamMember[msg.sender] != "1") revert NotTeamMember();
        raceRules memory _rules;
        if (_id == 1){
            uint8 i = 1;
            do{
                _rules.gridSize = _size;
                _rules.conCheck = _conCheck;
                _rules.conValue = i;
                _rules.maxQty = _maxqty;
                _rules.matPrice = _matP;
                _rules.prlPrice = _nutP;
                rulesByRace[currentWeek][i] = _rules;
                unchecked {
                    ++i;
                }
            }while( i < 19);
        } else {
            _rules.gridSize = _size;
            _rules.conCheck = _conCheck;
            _rules.conValue = _conValue;
            _rules.maxQty = _maxqty;
            _rules.matPrice = _matP;
            _rules.prlPrice = _nutP;
            rulesByRace[currentWeek][_id] = _rules;
        }      
    }



    function teamUpdate(address to, bytes1 member) public {
        if(isTeamMember[msg.sender] != "1") revert NotTeamMember();
        isTeamMember[to] = member;
    }

    function pause(bool _state) public {
        if(isTeamMember[msg.sender] != "1") revert NotTeamMember();
        paused = _state;
    }


    function signUp (uint16[] calldata _racers, address[] calldata _con, uint8[] calldata _event) external payable {

    if (paused) revert StakingIsPaused();
    funchecks memory _funchecks;
    uint8[25] memory raceCounts; 
   

        _funchecks.count = _racers.length;
        uint i;
        
        do {
            raceCounts[_event[i]]++;

            if (raceCounts[_event[i]] + tierCount[currentWeek][msg.sender][_event[i]] > rulesByRace[currentWeek][_event[i]].maxQty){
                revert StakedMoreThanMax();
            }
            _funchecks.money = (rulesByRace[currentWeek][_event[i]].matPrice);
            _funchecks.pearls = (rulesByRace[currentWeek][_event[i]].prlPrice);

            _funchecks.mTotal += _funchecks.money;
            _funchecks.pTotal += _funchecks.pearls;

            _funchecks.own = IERC721(_con[i]).ownerOf(_racers[i]);
            if (_funchecks.own != msg.sender) revert NFTOwnershipIssue();

         unchecked {
                    ++i;
                }
        } while (i < _funchecks.count);
        
        
        if (msg.value != _funchecks.mTotal) revert NotEnoughMatic();
        if (rewardToken.balanceOf(msg.sender) < _funchecks.pTotal) revert NotEnoughPearls();
        if(!rewardToken.transferFrom(msg.sender, address(this), _funchecks.pTotal)) revert PearlTransferIssue();
        
        
        performance memory _temp;
        _funchecks.num = block.timestamp;  
        _funchecks.tempstaked = currentlyStaked[currentWeek];
        delete i;
        do{


            _temp.id = _racers[i];
            _temp.nftContract = _con[i];
            _temp.eventWanted = _event[i];
            _temp.owner = msg.sender;
            uint16 _slot = slotByRacer[currentWeek][_con[i]][_temp.id];

            if (_slot != 0)  {
                if (perfByRacer[currentWeek][_slot].eventWanted != 100)  revert alreadyRegistered();
            }
                ++_funchecks.tempstaked;
                _slot = _funchecks.tempstaked;
                slotByRacer[currentWeek][_con[i]][_temp.id] = _slot;
            

            _funchecks.newn = uint8(randomNumber(_funchecks.num, 3, 9));  
            _temp.leg1 = _funchecks.newn;
            _funchecks.num += _funchecks.newn;
            _funchecks.newn = uint8(randomNumber(_funchecks.num, 3, 9));  
            _temp.leg2 = _funchecks.newn;
            _funchecks.num += _funchecks.newn;
            _funchecks.newn = uint8(randomNumber(_funchecks.num, 5, 12));  
            _temp.leg3 = _funchecks.newn;
            perfByRacer[currentWeek][_slot] = _temp;
            ++tierCount[currentWeek][msg.sender][_event[i]];


            unchecked {
                ++i;
            }

                 } while (i <_funchecks.count);
                 currentlyStaked[currentWeek] = _funchecks.tempstaked;
    }

     function returnRacers() external view returns(performance[] memory){
        performance[] memory _racers = new performance[](currentlyStaked[currentWeek] + 1);

        for (uint16 i = 1; i <= currentlyStaked[currentWeek];){

            _racers[i] = perfByRacer[currentWeek][i];
            _racers[i].owner = IERC721(_racers[i].nftContract).ownerOf(_racers[i].id);

             unchecked {
                ++i;
            }
        }

        return _racers;
    }

    // DEBUG AND MANAGEMENT //
    function randomNumber(uint _nonce, uint8 _start, uint8 _end) private view returns (uint random){
        uint8 _far = _end - _start;
        random = uint(keccak256(abi.encodePacked(deployT, msg.sender, _nonce))) % _far;
        random = random + _start;
        return random;
    }

     function returnTokens(uint16[] calldata _tokenID, address[] calldata _contract ) public {
 
        uint16[] memory _racers = _tokenID;
        funchecks memory _funchecks;
        uint i;
   

        _funchecks.count = _racers.length;
        do{
            uint16 _slot = slotByRacer[currentWeek][_contract[i]][_racers[i]];
            performance memory staking = perfByRacer[currentWeek][_slot];

            uint _tt = staking.id;
            address _owner = IERC721(_contract[i]).ownerOf(_tt);
            if (_owner != msg.sender) revert NFTOwnershipIssue();
            _funchecks.money = (rulesByRace[currentWeek][staking.eventWanted].matPrice);
            _funchecks.pearls = (rulesByRace[currentWeek][staking.eventWanted].prlPrice);

            _funchecks.mTotal += _funchecks.money;
            _funchecks.pTotal += _funchecks.pearls;

            perfByRacer[currentWeek][_slot].eventWanted = 100;
        unchecked {
                ++i;
            }

                 } while (i <_funchecks.count);

                 if (_funchecks.mTotal > 0) {
   //                 payable(msg.sender).transfer(_funchecks.mTotal);
                    (bool success, ) = (msg.sender).call{value: _funchecks.mTotal}("");
            //require(success, "Transfer failed.");
                    if (!success) revert MaticTransferIssue();

                 }
                 if (_funchecks.pTotal > 0) {
                        if (rewardToken.balanceOf(address(this)) < _funchecks.pTotal) revert NotEnoughPearls();
                        if(!rewardToken.transferFrom(address(this), msg.sender, _funchecks.pTotal)) revert PearlTransferIssue();
                 }
    }



    function setBoost(uint8 _boost, uint16 _tokenID, address _contract) external {

        address _own = IERC721(_contract).ownerOf(_tokenID);
        if (_own != msg.sender) revert NFTOwnershipIssue();


        uint nutso;
        if (_boost == 1){
            nutso = 250 ether;
            walletByWeek[currentWeek][_own].wAnchor = _tokenID;
            walletByWeek[currentWeek][_own].anchorContract = _contract;
        } else if (_boost == 2){
            nutso = 100 ether;
            walletByWeek[currentWeek][_own].wAssistant = _tokenID;
            walletByWeek[currentWeek][_own].assistContract = _contract;
        } else if (_boost == 3){
            nutso = 200 ether;
            walletByWeek[currentWeek][_own].wEquip = _tokenID;
            walletByWeek[currentWeek][_own].equipContract = _contract;
        } else if (_boost == 4){
            nutso = 100 ether;
            walletByWeek[currentWeek][_own].wBench = _tokenID;
            walletByWeek[currentWeek][_own].benchContract = _contract;
        }
        
        if (rewardToken.balanceOf(msg.sender) < nutso) revert NotEnoughPearls();
        if(!rewardToken.transferFrom(msg.sender, address(this), nutso)) revert PearlTransferIssue();

    }

    function getOwnerStaked(address _owner, address _contract) public view returns ( uint [] memory){
        uint[] memory ownersTokens = RacerInterface(_contract).tokensOfOwner(_owner);
        uint cachedLength = ownersTokens.length;
        uint[] memory ownersStaked = new uint[](cachedLength);
        uint index;
        for ( uint i; i < cachedLength; ) {
            uint t = ownersTokens[i];
            uint16 _slot = slotByRacer[currentWeek][erc721Contract][uint16(t)];
            uint _id = perfByRacer[currentWeek][_slot].id;
            if (_id == t && perfByRacer[currentWeek][_slot].eventWanted != 100 ){
                ownersStaked[index] = _id ;
                ++index;
            }
                        unchecked {
                ++i;
            }
        }


        uint[] memory _return = new uint[](index);
        uint j;
        for(j; j < index; j++){
            _return[j] = ownersStaked[j];
        }


        return _return;
    }

 
    function getOwnerUnstaked(address _owner, address _contract) external view returns ( uint [] memory){
        uint[] memory ownersTokens = RacerInterface(_contract).tokensOfOwner(_owner);
        uint cachedLength = ownersTokens.length;
        uint[] memory ownersUnstaked = new uint[](cachedLength);
        uint index;
        
        for ( uint i; i < cachedLength; i++ ) {
            uint t = (ownersTokens[i]);
            uint16 _slot = slotByRacer[currentWeek][erc721Contract][uint16(t)];
            uint _id = perfByRacer[currentWeek][_slot].id;
            if (_id != ownersTokens[i] || perfByRacer[currentWeek][_slot].eventWanted == 100 ){
                ownersUnstaked[index] = ownersTokens[i];
                index++;
            }
        }
        uint[] memory _return = new uint[](index);
        uint j;
        for(j; j < index; j++){
            _return[j] = ownersUnstaked[j];
        }
        return _return;
    }

  //  function getOwnerStakedCount(address _owner) public view returns (uint){
  //      uint[] memory _temp = getOwnerStaked(_owner);
  //      uint _return = _temp.length;
  //      return _return;
  //  }

    function withdraw() external onlyOwner {
        (bool success, ) = (msg.sender).call{value: address(this).balance}("");
            //require(success, "Transfer failed.");
            if (!success) revert MaticTransferIssue();

            uint _nut = rewardToken.balanceOf(address(this));
            if(!rewardToken.transfer(msg.sender, _nut)) revert PearlTransferIssue();
    }

    function updateWeek() external {
        if(isTeamMember[msg.sender] != "1") revert NotTeamMember();
        ++currentWeek;
        paused = true;
    }

}