/**
 *Submitted for verification at polygonscan.com on 2023-04-24
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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: contracts/BoardMember.sol

//SPDX-License-Identifier: GPL 3.0
pragma solidity ^0.8.7;




error Blacklisted(string _reason);
error NotOwner(string _reason);

contract BoardMember{
    // can filter any of the events by indexed items 
    event DISSOCIATION(bytes reason, address indexed member);
    event TRANSFER_OF_RIGHTS(address indexed from, address indexed to);
    event MAJORITY_TRANSFER(address indexed initiator, uint16 notice);
    event TERMINATION_OF_DUTIES(address indexed _out, address indexed _in, string _position);
    event AMEND_ARTICLES(uint indexed _id, bool _passed);
    // change to Mortgage event
    event MORTGAGE_MANNERS(bytes _type, bool _passed);
    event MERGER(bytes _who, bool _passed);
    event INDEBTEDNESS(uint _amount, bool _passed);
    event CHANGE_NATURE_OF_BUSINESS(bytes _to, bool _passed);
    event COMMENCE_VOLUNTARY_BANKRUPTCY(bool _passed);
    event CHANGE_AMT_MANAGERS(bytes _addSub, bool _passed, uint indexed _amount);
    event NEW_SHARES_CREATED(bytes _class, uint _amount);

    /*
    whatever token used for boardmembers make sure to set this contracts allowance to all tokens
    to prevent anyone from abusing this owning all tokens set every function to owner and have
    governor contract own contract
    */
    IERC20 public BSR = IERC20(0xBb767f678519007a4d86D95ce621E25A3915b2Ef);
    // article counter
    uint128 counter = 0;
    // set owner to timelock since that has the execution type functions
    address owner = 0x96b7069cAB641496aD2E975975C8185A1e234C7B;

    struct Manager {
        bytes position;
        bytes name;
        address wallet;
    }

    Manager public secretary = Manager(abi.encode("secretary"), abi.encode("Tyler"), 0xb94ae34DE09B1EeF75E18e8Ed17F91C32E9B0A9f);
    Manager public manager = Manager(abi.encode("manager"), abi.encode("Tyler"), 0xB535c6e924b591013c6027Dc66aAEc5B634ce567);
    // default bool mapping is false
    mapping(address => bool) public blacklist;

    modifier notBlacklisted(address _user){
        if(blacklist[_user]){
            revert Blacklisted("This address is blacklisted from this dao");
        }
        _;
    }

    modifier onlyOwner(){
        if(msg.sender != owner){
            revert NotOwner("Only owner allowed to execute functions");
        }
        _;
    }

    function terminationOfDuties(address _in, string memory _name, string memory _position) onlyOwner public {
        if(keccak256(abi.encode(_position)) == keccak256(abi.encode("secretary"))){
            emit TERMINATION_OF_DUTIES(secretary.wallet, _in, _position);
            secretary.name = abi.encode(_name);
            secretary.wallet = _in;
        } else {
            emit TERMINATION_OF_DUTIES(manager.wallet, _in, _position);
            manager.name = abi.encode(_name);
            manager.wallet = _in;
        }
    }

    function transferRights(address _from, address _to, uint amount) onlyOwner public notBlacklisted(_to){
        IERC20(BSR).transferFrom(_from, _to, amount);
        emit TRANSFER_OF_RIGHTS(_from, _to);
    }

    function dissociation(address _who, string memory _reason) onlyOwner public {
        uint amount = IERC20(BSR).balanceOf(_who);
        // for now transfer tokens from person add to contract burn not accessable from Interface ERC20
        IERC20(BSR).transferFrom(_who, address(this), amount);
        emit DISSOCIATION(abi.encode(_reason), _who);
    }
    // revisit
    function dissociationReassign(address _who) onlyOwner public {
        blacklist[_who] = true;
    }

    function amendArticles() onlyOwner public {
        emit AMEND_ARTICLES(counter, true);
        counter++;
    }
    function mortgageManners(string memory _type) onlyOwner public {
        emit MORTGAGE_MANNERS(abi.encode(_type), true);
    }
    function merger(string memory _who) onlyOwner public {
        emit MERGER(abi.encode(_who), true);
    }
    function incurDebt(uint _amt) onlyOwner public {
        emit INDEBTEDNESS(_amt, true);
    }
    function changeBusinessNature(string memory _to) onlyOwner public {
        emit CHANGE_NATURE_OF_BUSINESS(abi.encode(_to), true);
    }
    function commenceBankruptcy() onlyOwner public {
        emit COMMENCE_VOLUNTARY_BANKRUPTCY(true);
    }
    function changeAmountManagers(string memory _addSub, uint _amt) onlyOwner public {
        emit CHANGE_AMT_MANAGERS(abi.encode(_addSub), true, _amt);
    }
    function addShares(string memory _class, uint _amount) onlyOwner public {
        // add in constructor for erc20 tokens add name and symbol to above function params
        emit NEW_SHARES_CREATED(abi.encode(_class), _amount);
    }
    function withdrawl() onlyOwner public {
        uint amount = IERC20(BSR).balanceOf(address(this));
        IERC20(BSR).transferFrom(address(this), msg.sender, amount);
    }

}