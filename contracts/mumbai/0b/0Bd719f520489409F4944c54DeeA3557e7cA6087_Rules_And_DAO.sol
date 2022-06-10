/**
 *Submitted for verification at polygonscan.com on 2022-06-09
*/

// File: DAO_and_Rules/IGameContract.sol

pragma solidity ^0.8.0;

interface IGameContract
{
    // Needed
    // mapping(address => Statistic)
    //Statistic(Interacted/rewarded)
    function Rewarded(address) external view returns(uint);
    function Interacted(address) external view returns(uint64);
}
// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/IERC165.sol


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

// File: DAO_and_Rules/IERC20Charity.sol


pragma solidity ^0.8.4;
//import "./IERC165.sol";



///
/// @dev Required interface of an ERC20 Charity compliant contract.
///
interface IERC20charity is IERC20,IERC165 {
    /// ERC165 bytes to add to interface array - set in parent contract
    /// implementing this standard
    ///
    ///type(IERC20charity).interfaceId.interfaceId == 0x557512b6
    /// bytes4 private constant _INTERFACE_ID_ERCcharity = 0x557512b6;
    /// _registerInterface(_INTERFACE_ID_ERCcharity);

    
    /**
     * @dev Emitted when `toAdd` charity address is added to `whitelistedRate`.
     */
    event AddedToWhitelist (address toAdd);

    /**
     * @dev Emitted when `toRemove` charity address is deleted from `whitelistedRate`.
     */
    event RemovedFromWhitelist (address toRemove);

    /**
     * @dev Emitted when `_defaultAddress` charity address is modified and set to `whitelistedAddr`.
     */
    event DonnationAddressChanged (address whitelistedAddr);

    /**
     * @dev Emitted when `_defaultAddress` charity address is modified and set to `whitelistedAddr` 
    * and _donation is set to `rate`.
     */
    event DonnationAddressAndRateChanged (address whitelistedAddr,uint256 rate);

    /**
     * @dev Emitted when `whitelistedRate` for `whitelistedAddr` is modified and set to `rate`.
     */
    event ModifiedCharityRate(address whitelistedAddr,uint256 rate);
    
    /**
    *@notice Called with the charity address to determine if the contract whitelisted the address
    *and if it is the rate assigned.
    *@param addr - the Charity address queried for donnation information.
    *@return whitelisted - true if the contract whitelisted the address to receive donnation
    *@return defaultRate - the rate defined by the contract owner by default , the minimum rate allowed different from 0
    */
    function charityInfo(
        address addr
    ) external view returns (
        bool whitelisted,
        uint256 defaultRate
    );

    /**
    *@notice Add address to whitelist and set rate to the default rate.
    * @dev Requirements:
     *
     * - `toAdd` cannot be the zero address.
     *
     * @param toAdd The address to whitelist.
     */
    function addToWhitelist(address toAdd) external;

    /**
    *@notice Remove the address from the whitelist and set rate to the default rate.
    * @dev Requirements:
     *
     * - `toRemove` cannot be the zero address.
     *
     * @param toRemove The address to remove from whitelist.
     */
    function deleteFromWhitelist(address toRemove) external;

    /**
    *@notice Set personlised rate for charity address in {whitelistedRate}.
    * @dev Requirements:
     *
     * - `whitelistedAddr` cannot be the zero address.
     * - `rate` cannot be inferior to the default rate.
     *
     * @param whitelistedAddr The address to set as default.
     * @param rate The personalised rate for donation.
     */
    function setSpecificRate(address whitelistedAddr , uint256 rate) external;

    /**
    *@notice Set for a user a default charity address that will receive donation. 
    * The default rate specified in {whitelistedRate} will be applied.
    * @dev Requirements:
     *
     * - `whitelistedAddr` cannot be the zero address.
     *
     * @param whitelistedAddr The address to set as default.
     */
    function setSpecificDefaultAddress(address whitelistedAddr) external;

    /**
    *@notice Set for a user a default charity address that will receive donation. 
    * The rate is specified by the user.
    * @dev Requirements:
     *
     * - `whitelistedAddr` cannot be the zero address.
     * - `rate` cannot be inferior to the default rate 
     * or to the rate specified by the owner of this contract in {whitelistedRate}.
     *
     * @param whitelistedAddr The address to set as default.
     * @param rate The personalised rate for donation.
     */
    function setSpecificDefaultAddressAndRate(address whitelistedAddr , uint256 rate) external;

    /**
    *@notice Display for a user the default charity address that will receive donation. 
    * The default rate specified in {whitelistedRate} will be applied.
     */
    function SpecificDefaultAddress() external view returns (
        address defaultAddress
    );

    /**
    *@notice Delete The Default Address and so deactivate donnations .
     */
    function DeleteDefaultAddress() external;
}

// File: DAO_and_Rules/DAO_V2_Test.sol

pragma solidity ^0.8.0;




contract Rules_And_DAO{
    // Chief of Decisions
    address public Judge;

    // index
    uint64 public index_proposition=0;
    uint64 public index_accepted=0;

    // token P2E
    IERC20charity public TokenDAO;

    // Game Contract
    IGameContract public GameContract;

    // 5 rules
    mapping(uint8 => string) public Rules;

    // Proposition
    mapping(uint64 => Proposition) public Propositions;

    // Accepted improvement
    mapping(uint64 => string) public Accepted_proposal;

    // Vote
    mapping(bytes32 => Voter) private All_Vote;

    // time Locked for a vote 1 week
    uint32 TimeLocker=600; // 604800

    // Event
    event Proposal(address add,string propo);
    event SwitchJudge(address old,address New);
    event Vote(address add,uint64 id);


    // Proposition
    struct Proposition{
        address Asker;
        uint64 time_start;
        uint64 time_end;
        uint256 TotalStaked;
        string proposal;
        uint256 vote_true;
        uint256 vote_false; 
        string result;
        bool decision;
    }

    // Vote
    struct Voter{
        address add;
        uint64 id_proposition;
        uint256 staked;
        bool withdrawed;
        bool voted;
    }

    modifier OnlyJudge{
        require(tx.origin == Judge,"Not Master");
        _;
    }

    modifier Compare(uint64 value1,uint64 value2){
        require(value1 >= value2,"It's not time !");
        _;
    }

    function ChangeIERC20(IERC20charity New)
    OnlyJudge
    public{
        TokenDAO = New;
    }

    function ChangeGameContract(IGameContract New)
    OnlyJudge
    public{
        GameContract = New;
    }
    function changeTimeLocker(uint32 lock)
    OnlyJudge
    public{
        TimeLocker = lock;
    }
    // the signature cannot code in Solidity due to Confidentiality

    function ChangeJudge(address New)
    OnlyJudge
    public
    {
        // result
        emit SwitchJudge(Judge,New);
        Judge = New;
    }

    // 5 REGLES DU DAO
    // 0) UNIQUEMENT LES JOUEURS PEUVENT PROPOSER ET VOTER LES AMELIORATIONS DU PROTOCOLE
    // 1) LES LOYALTIES DES NFT NE DOIVENT PAS DEPASSER LE SEUIL
    // 2) LES ASSOCIATIONS CARITATIVES SONT CHOISIES EN FONCTION DE LA COMMUNAUTE
    // 3) LES REWARDS SERONT DONNES APRES LE JEU ET UTILISABLE DIRECTEMENT
    // 4) LE COURS DU TOKEN DEPENT UNIQUEMENT DE LA COMMUNAUTE
    constructor(string[] memory Rule) 
    public
    {
        for(uint8 i=0;i<5;i++){
            Rules[i]=Rule[i];
        }
        Judge = msg.sender;
    }

    function SendProposal(string memory proposal)
    OnlyJudge 
    public
    {
        uint64 time = uint64(block.timestamp);
        Proposition memory P=Proposition(tx.origin,time,time+TimeLocker,0,proposal,0,0,"Pending",false);
        Propositions[index_proposition] = P;
        index_proposition++;
        emit Proposal(tx.origin,proposal);
    }

    function Send() 
    public payable
    returns(uint256,uint256)
    {
        uint256 reward = GameContract.Rewarded(tx.origin);
        uint256 approved = TokenDAO.allowance(tx.origin,address(this)) > TokenDAO.balanceOf(tx.origin) ? TokenDAO.balanceOf(tx.origin):TokenDAO.allowance(tx.origin,address(this));
        if(approved >= reward){
            TokenDAO.transferFrom(tx.origin,address(this),reward);
            approved = reward;
        }else{
            TokenDAO.transferFrom(tx.origin,address(this),approved);
        }
        return (reward,approved);
    }

    
    function HasVoted(uint64 id_proposition,bool choice,uint256 Vote_Score,uint256 approved) 
    internal
    {
        Propositions[id_proposition].TotalStaked += approved;
        if(choice){
            Propositions[id_proposition].vote_true += Vote_Score;
        }else{
            Propositions[id_proposition].vote_false += Vote_Score;
        }
        Voter memory Vote_id = Voter(tx.origin,id_proposition,approved,false,true);
        bytes32 All_vote_id = keccak256(abi.encodePacked(tx.origin,id_proposition));
        All_Vote[All_vote_id] = Vote_id;
    }

    function sqrt(uint64 y)
    internal pure
    returns (uint64 z) {
        if (y > 2) {
            z = y;
            uint64 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function VoteProposal(uint64 id_proposition,bool choice)
    Compare(Propositions[id_proposition].time_end,uint64(block.timestamp))
    public
    {
        bytes32 All_vote_id = keccak256(abi.encodePacked(tx.origin,id_proposition));
        require(!All_Vote[All_vote_id].voted,"Already Voted");

        // send amount
        (uint256 reward,uint256 approved) = Send();
        // Calcul Vote_Score
        uint64 interact = GameContract.Interacted(tx.origin);
        // sqrt au lieu de logarithme car plus simple à manipuler
        uint64 score = sqrt(interact*1000);
        uint256 Vote_Score = (score*approved)/reward;

        // Attribution
        HasVoted(id_proposition,choice,Vote_Score,approved);
        emit Vote(tx.origin,id_proposition);
    }

    function CheckVote(uint64 id_proposition) 
    public view 
    returns(Voter memory)
    {
        bytes32 All_vote_id = keccak256(abi.encodePacked(tx.origin,id_proposition));
        return All_Vote[All_vote_id];
    }

    function FinalDecision(uint64 id_proposition)
    OnlyJudge
    Compare(uint64(block.timestamp),Propositions[id_proposition].time_end)
    Compare(index_proposition-1,id_proposition)
    public
    {
        require(!Propositions[id_proposition].decision, "already Decided !");
        if(Propositions[id_proposition].vote_true > Propositions[id_proposition].vote_false){
            Accepted_proposal[index_accepted] = Propositions[id_proposition].proposal;
            Propositions[id_proposition].result = "Pass";
            index_accepted ++;
        }
        else{
            Propositions[id_proposition].result = "Fail";
        }
        Propositions[id_proposition].decision = true;
    }

    function withdraw(uint64 id_proposition) 
    Compare(uint64(block.timestamp),Propositions[id_proposition].time_end)
    Compare(index_proposition,id_proposition)
    public
    {
        bytes32 All_vote_id = keccak256(abi.encodePacked(tx.origin,id_proposition));
        require(!All_Vote[All_vote_id].withdrawed,"Already Withdrawed");
        TokenDAO.transfer(tx.origin,All_Vote[All_vote_id].staked);
        All_Vote[All_vote_id].withdrawed = true;
    } 
}