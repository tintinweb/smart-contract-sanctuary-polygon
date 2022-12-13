// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./Interface/IQatarWorldCup.sol";
import "./common/Ownable.sol";


contract AirdropPool is Ownable {
    uint256 constant RANK_GOLD= 1;
    uint256 constant RANK_SILVER= 2;
    uint256 constant RANK_BRONZE = 3;

    // 1st team
    uint256 public championTeam;

    // 2nd team
    uint256 public runnerUpTeam;

    // 3rd team
    uint256 public thirdPlaceTeam;

    uint256 public airdropBalance;

    // start time to claim by unix
    uint256 public claimStartTime;

    // rate share of team
    mapping(uint256 => uint256) public rateShareByTeam;

    // rate share of rank team
    mapping(uint256 => uint256) public rateShareByRank;

    uint256 public denominator = 100000;

    // tokenId is claimed or not
    mapping(uint256 => bool) public claimedTokenId;

    // amount airdrop is claimed by wallet
    mapping(address => uint256) public walletClaimedAmount;

    // state of claim process
    bool public claimIsActive = false;

    IQatarWorldCup qatarWorldCup;

    constructor(){}

    receive() external payable {
    }

    modifier hasClaimRunning() {
        require(claimIsActive, "Claim must be active to receive airdrop");
        _;
    }

    function deposit(uint256 amount) payable public {
        require(msg.value == amount, "Airdrop: Not correct amount!");
    }

    function checkValidTeam(uint256 _tokenId) public view returns(bool){
        (uint256 team,,) = qatarWorldCup.getNFTProperty(_tokenId);
        if(team == championTeam || team == runnerUpTeam || team == thirdPlaceTeam){
            return true;
        }else{
            return false;
        }
    }

    //** CLAIM FUND AFTER POOL START */
    function claimFund(uint256[] memory _tokenIds) public hasClaimRunning {
        for(uint256 i = 0; i < _tokenIds.length; i++){
            require(msg.sender == qatarWorldCup.ownerOf(_tokenIds[i]), "Airdrop: caller is not owner");
            require(!claimedTokenId[_tokenIds[i]], "Airdrop: TokenId has been claimed");
            (uint256 team, uint256 rank,) = qatarWorldCup.getNFTProperty(_tokenIds[i]);
            if(team == championTeam || team == runnerUpTeam || team == thirdPlaceTeam){
                if( rank == RANK_GOLD || rank == RANK_SILVER || rank == RANK_BRONZE){
                     walletClaimedAmount[msg.sender] +=  getAmountSharePerNFT(team, rank);
                     claimedTokenId[_tokenIds[i]] = true;
                }
            }
        }
        payable(msg.sender).transfer(walletClaimedAmount[msg.sender]);
    }

    function getAmountSharePerTeam(uint256 _team) public view returns(uint256){
        unchecked { return(airdropBalance * rateShareByTeam[_team])/denominator; }
    }

    function getAmountSharePerNFT(uint256 _team, uint256 _rank) public view returns(uint256){
        uint256 amountsharePerTeam = getAmountSharePerTeam(_team);
        uint256 getAmountNFTByTeamAndRank = qatarWorldCup.getAmountNFTByTeamAndRank(_team, _rank);
        if(getAmountNFTByTeamAndRank == 0){
            return 0;
        }
        unchecked{return(amountsharePerTeam * rateShareByRank[_rank])/(getAmountNFTByTeamAndRank * denominator);}
    }

    function getBalance() public view returns(uint256){
        return address(this).balance;
    }

    function setQatarWorldCupAdress( address _qatarWorldCupAdress) public onlyOwner {
        qatarWorldCup = IQatarWorldCup(_qatarWorldCupAdress);
    }

    /*
    * Pause sale if active, make active if paused
    */
    function flipClaimState() public onlyOwner {
        claimIsActive = !claimIsActive;
    }

    function setAirdropBalance() public onlyOwner {
        airdropBalance = address(this).balance;
    }

    function setUpPlaceForTeams(uint256 _championTeam, uint256 _runnerUpTeam, uint256 _thirdPlaceTeam) public onlyOwner {
        championTeam = _championTeam;
        runnerUpTeam = _runnerUpTeam;
        thirdPlaceTeam = _thirdPlaceTeam;
    }

    function setRatedRank(uint256 _goldRate,uint256 _silverRate,uint256 _bronzeRate) public onlyOwner {
        rateShareByRank[RANK_GOLD] = _goldRate;
        rateShareByRank[RANK_SILVER] = _silverRate;
        rateShareByRank[RANK_BRONZE] = _bronzeRate;
    }

    function setRatedTeam(uint256 _championTeamRate,uint256 _runnerUpTeamRate,uint256 _thirdPlaceTeamRate) public onlyOwner {
        rateShareByTeam[championTeam] = _championTeamRate;
        rateShareByTeam[runnerUpTeam] = _runnerUpTeamRate;
        rateShareByTeam[thirdPlaceTeam] = _thirdPlaceTeamRate;
    }
    
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.4;
interface IQatarWorldCup {
    function tokensOfOwner(address _owner) external view returns (uint256 [] memory);
    function getNFTProperty(uint256 _tokenId) external view returns ( uint256 teams, uint256 rank, uint256 imageIndex);
    function getAmountNFTByTeamAndRank(uint256 _team, uint256 _rank) external view returns ( uint256 amount);
    function ownerOf(uint256 tokenId) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Context.sol";
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    /**
     * Call when init cloned Contract
     */
    function initOwnable() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    /*    function renounceOwnership() public virtual onlyOwner {
     *   emit OwnershipTransferred(_owner, address(0));
     *   _owner = address(0);
     *   }
    */

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}