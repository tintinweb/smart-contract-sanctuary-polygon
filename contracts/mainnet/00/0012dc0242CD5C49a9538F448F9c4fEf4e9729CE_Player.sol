// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";

interface ITreasuryWallet{
    function withdrawReferrals(uint , address ) external;
}

contract Player is Ownable {


    //..........................................Declarations...................................
    struct PlayerObject {
        address parent;
        uint amountEarned;
        uint referralEarned;
        uint referralWithdrawn;
        uint gamesPlayed;
        bool exists;
        bool extemptFees;
    }
    struct ratio {
        uint num;
        uint den;
    }
    mapping(uint8 => ratio) public referral;
    mapping(address => PlayerObject) public Players;
    bool public isSetup;
    address public IERC1155Contract;
    mapping(address=>bool) playableContracts;
    ITreasuryWallet _treasuryWallet;


    //..........................................Events...................................
    event PaidReferral(
        address player,
        address indexed referree,
        uint256 val,
        uint8 index
    );
    event PlayerRegistered(address parent, address user);
    event PlayerAlreadyRegistered(address parent, address user);
    event ReferralWithdrawn(address player,uint amount, uint remainingAmount);

    event RatioEvent(uint num, uint den);

    //..........................................Modifiers...................................
    modifier onlyPlayableContract(){
        require(playableContracts[msg.sender] == true,"Not a PlayableContract!!");
        _;
    }

    modifier onlyNFTHandler(){
        require(msg.sender == IERC1155Contract || msg.sender == owner(),"Not a NFT handler!!");
        _;
    }

    constructor(address treasuryWalletAddress) {
        referral[1] = ratio(5, 100);
        referral[2] = ratio(3, 100);
        referral[3] = ratio(2, 100);
        referral[4] = ratio(1, 100);
        referral[5] = ratio(5, 1000);
        _treasuryWallet=ITreasuryWallet(treasuryWalletAddress);
    }


    function setTreasuryWallet(address treasuryWalletAddress) public onlyOwner{
        _treasuryWallet=ITreasuryWallet(treasuryWalletAddress);
    }

    //..........................................Functions...................................

    function registerPlayer(
        address parent,
        address user
    ) public onlyPlayableContract returns (PlayerObject memory) {
        require(parent == address(0x0) || Players[parent].exists, "unregistered parent");
        if (!Players[user].exists) {
            Players[user].parent = parent;
            Players[user].exists = true;
            emit PlayerRegistered(user, parent);
        } else {
            emit PlayerAlreadyRegistered(user, parent);
        }
        return Players[user];
    }    

    function distributeReferrals(
        address user,
        uint amount        
    ) external onlyPlayableContract returns (uint256) {
        require(Players[user].exists, "Player is not yet registered!!");                
        uint256 val;
        uint256 totalReferral;
        address parentAddress = Players[user].parent;
        PlayerObject storage parent = Players[parentAddress];
        
        uint8 i = 1;
        while (parent.exists) {
            val = (amount * referral[i].num) / referral[i].den;            
            Players[parentAddress].referralEarned += val;
            totalReferral += val;
            emit PaidReferral(user, parentAddress, val, i);
            parentAddress = Players[parentAddress].parent;
            if(parentAddress==address(0))
                break;
            parent = Players[parentAddress];
            i++;
        }        
        return totalReferral;
    }

    function getPlayer(address useraddr) external view returns (PlayerObject memory) { return Players[useraddr]; }
    function getPlayerExistence(address useraddr) external view returns (bool) { return Players[useraddr].exists; }
    function getPlayerExemption(address useraddr) external view returns (bool) { return Players[useraddr].extemptFees; }

    

    function withdrawReferral(uint amount) public {
        
        require(Players[msg.sender].exists,"Player is not yet registered!!");
        PlayerObject storage player = Players[msg.sender];
        uint withdrawableFund = player.referralEarned - player.referralWithdrawn;
        require(amount<=withdrawableFund,"Amount asked is more than player has earned!!");        
       _treasuryWallet.withdrawReferrals(amount,msg.sender);
        player.referralWithdrawn += amount; 
        emit ReferralWithdrawn(msg.sender,amount,player.referralWithdrawn);
    }

    function getWithdrawableBalance(address playerAddress) public view returns(uint){
        PlayerObject storage player = Players[playerAddress];
        return (player.referralEarned-player.referralWithdrawn);
    }

    
    function extemptPlayer(address playerAddress ,address parent,bool _extemptPlayer) external onlyNFTHandler{    
        PlayerObject storage player = Players[playerAddress];
        if (player.exists) {
            player.extemptFees = _extemptPlayer;
        } else {
            player.parent = parent;
            player.extemptFees = _extemptPlayer;
        }
    }

    function setPlayableContract(address contractAddress) external onlyOwner{
        require(contractAddress!=address(0),"Invalid contract address!!");
        playableContracts[contractAddress]=true;
    }
    
    function setGAERC1155Contract(address contractAddress) external onlyOwner{
        require(contractAddress!=address(0),"Invalid contract address!!");
        IERC1155Contract = contractAddress;
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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