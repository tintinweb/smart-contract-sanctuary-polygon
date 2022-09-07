// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Price.sol";
import "./Utils.sol";
import "./marketplace/CurrencyManager.sol";

contract Harfang is Ownable {
    using Counters for Counters.Counter;

    // storage
    mapping(uint256 => Utils.GlobalElement) private _elements;
    mapping(string => Utils.Element) private _owners;
    mapping(string => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    Counters.Counter public count;
    Counters.Counter public stampCount;
    address public marketplace;
    address public price;
    CurrencyManager public currencyManager;

    constructor(address _currencyManager, address _price, bytes memory cid){
        require(cid[0] == 0x12 && cid[1] == 0x20 && cid.length == 34, "Incorrect cid (v0 only)");
        price = _price;
        currencyManager = CurrencyManager(_currencyManager);
        count.increment();
        _elements[count.current()] = Utils.createGlobalElement(
            cid,
            667667667667,
            Utils.ElementType.stamp,
            address(0)
        );
        count.increment();
        emit ElementCreated(cid, 667667667667, Utils.ElementType.stamp, 1, address(0));
    }

    // events

    event Transfer(address indexed _from, address indexed _to, uint256 indexed id, uint256 sid);
    event Approval(address indexed _owner, address indexed _approved, string indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event ElementCreated(bytes cid, uint256 copies, Utils.ElementType indexed t, uint256 indexed id, address indexed owner);
    event SpecificElementCreated(uint256 indexed sid, uint256 indexed id, address indexed owner);
    event Stamp(address indexed operator, string stamp, string card, bytes32 indexed stampId, bytes32 indexed cardId);
    event Unstamp(address indexed operator, string stamp, string card, bytes32 indexed stampId, bytes32 indexed cardId);
    event Burn(address indexed operator, uint256 indexed id, uint256 indexed sid, uint256 copies);
    event Withdraw(address indexed operator, address indexed currency, uint256 amount);
    event NewPrice(address indexed operator, address price);
    event Marketplace(address indexed operator, address marketplace);
    event NewCurrencyManager(address indexed operator, address manager);

    function createElement(bytes calldata cid, uint256 _copies, Utils.ElementType t, address currency) external {
        require(cid[0] == 0x12 && cid[1] == 0x20 && cid.length == 34, "Incorrect cid (v0 only)");
        require(currencyManager.isCurrencyWhitelisted(currency), "Invalid currency");
        uint256 priceToPay = Price(price).cardPrice(_copies, currency);
        require(_copies >= 1, "copies cannot be less than 1");
        require(ERC20(currency).allowance(msg.sender, address(this)) >= priceToPay, "Not enough tokens allowed");
        _elements[count.current()] = Utils.createGlobalElement(
            cid,
            _copies,
            t,
            msg.sender
        );
        count.increment();
        ERC20(currency).transferFrom(msg.sender, address(this), priceToPay);
        emit ElementCreated(cid, _copies, t, count.current()-1, msg.sender);
    }

    function createSpecificElement(uint256 id, address to) public {
        Utils.GlobalElement storage global = _elements[id];
        require(global.copies >= 1, "This global element does not exist");
        require(global.creator == msg.sender || _operatorApprovals[global.creator][msg.sender], "You do not own the element");
        require(global.copies > global.lastId, "limit of copies hitted");
        require(_owners[Utils.encode(id, global.lastId)].owner == address(0), "Element already exists");
        _owners[Utils.encode(id, global.lastId)] = Utils.createLocalElement(to);
        global.lastId = global.lastId+1;
        emit SpecificElementCreated(global.lastId, id, to);
    }

    function send(uint256 id, uint256 sid, address to, bytes calldata messageURI) external {
        require(messageURI.length == 0 || messageURI[0] == 0x12 && messageURI[1] == 0x20 && messageURI.length == 34, "Not correct cid");
        Utils.Element storage element = _owners[Utils.encode(id, sid)];
        require(element.owner != address(0), "This specific element does not exist");
        Utils.GlobalElement storage global = _elements[id];
        require(global.copies >= 1, "This global element does not exist");
        require(element.owner == msg.sender, "The sender is not the owner");
        if (global.t == Utils.ElementType.stamp){
            require(element.twin == 0 && element.twinSid == 0, "Stamp is attached to a card");
            element.owner = to;
            _tokenApprovals[Utils.encode(id, sid)] = address(0);
            emit Transfer(msg.sender, to, id, sid);
        }else if(global.t == Utils.ElementType.card){
            // require(string(messageURI).length == 46, "Message URI is not a valid IPFS hash");
            require(element.twin != 0, "Card is not stamped");
            Utils.Element storage lstamp = _owners[Utils.encode(element.twin, element.twinSid)];
            element.owner = to;
            element.messageCID = messageURI;
            lstamp.owner = to;
            _tokenApprovals[Utils.encode(id, sid)] = address(0);
            emit Transfer(msg.sender, to, id, sid);
        }else{
            revert("Element does not have a type");
        }
    }

    function transfer(uint256 id, uint256 sid, address from, address to) external {
        require(msg.sender == marketplace, "Can only be executed by the marketplace contract");
        require(_tokenApprovals[Utils.encode(id, sid)] == marketplace || _operatorApprovals[from][marketplace] == true, "Marketplace is not allowed to transfer this element");
        Utils.Element storage element = _owners[Utils.encode(id, sid)];
        require(element.owner != address(0), "This specific element does not exist");
        Utils.GlobalElement storage global = _elements[id];
        require(global.copies >= 1, "This global element does not exist");
        require(element.owner == from, "The sender is not the owner");
        if(global.t == Utils.ElementType.stamp){
            require(element.twin == 0 && element.twinSid == 0, "Stamp is linked");
            element.owner = to;
            _tokenApprovals[Utils.encode(id, sid)] = address(0);
            emit Transfer(from, to, id, sid);
        }else if(global.t == Utils.ElementType.card){
            require(element.twin == 0 && element.twinSid == 0, "Card is attached to stamp");
            element.owner = to;
            _tokenApprovals[Utils.encode(id, sid)] = address(0);
            emit Transfer(from, to, id, sid);
        }else{ 
            revert("Element does not have a type");
        }
    }   

    function stampHarfang(uint256 cardID, uint256 cardSID) internal {
        Utils.Element storage element = _owners[Utils.encode(cardID, cardSID)];
        require(element.owner != address(0), "This specific element does not exist");
        require(element.owner == msg.sender, "The sender is not the owner");
        require(element.twin == 0 && element.twinSid == 0, "Card is already attached to stamp");
        Utils.GlobalElement storage global = _elements[cardID];
        require(global.copies >= 1, "This global card does not exist");
        require(global.t == Utils.ElementType.card, "Provided card is not a card");
        Utils.Element memory lstamp = Utils.createLocalElement(msg.sender);
        lstamp.used = true;
        string memory key = Utils.encode(1, stampCount.current());
        _owners[key] = lstamp;
        _owners[key].twin = cardID;
        _owners[key].twinSid = cardSID;
        element.twin = 1;
        element.twinSid = stampCount.current();
        stampCount.increment();
        emit Stamp(msg.sender, key, Utils.encode(cardID, cardSID), keccak256(bytes(key)), keccak256(bytes(Utils.encode(cardID, cardSID))));
    }

    function stamp(uint256 cardID, uint256 cardSID, uint256 stampID, uint256 stampSID, address currency) external {
        require(_elements[cardID].t == Utils.ElementType.card, "Incorrect type");
        if(stampID == 1){
            require(currencyManager.isCurrencyWhitelisted(currency), "Invalid currency");
            uint256 priceToPay = Price(price).stampPrice(currency);
            stampHarfang(cardID, cardSID);
            require(ERC20(currency).allowance(msg.sender, address(this)) >= priceToPay, "Not enough tokens allowed");
            ERC20(currency).transferFrom(msg.sender, address(this), priceToPay);
        }else{
            Utils.Element storage card = _owners[Utils.encode(cardID, cardSID)];
            require(card.owner != address(0), "This specific card does not exist");
            Utils.GlobalElement storage gcard = _elements[cardID];
            require(gcard.copies >= 1, "This global card does not exist");
            Utils.Element storage lstamp = _owners[Utils.encode(stampID, stampSID)];
            require(lstamp.owner != address(0), "This specific stamp does not exist");
            Utils.GlobalElement storage gstamp = _elements[stampID];
            require(gstamp.copies >= 1, "This global stamp does not exist");
            require(gcard.t == Utils.ElementType.card && gstamp.t == Utils.ElementType.stamp, "Incorrect types");
            require(lstamp.twin == 0 && lstamp.twinSid == 0 && card.twin == 0 && card.twinSid == 0, "Card or Stamp already attached");
            require(card.owner == msg.sender && lstamp.owner == msg.sender, "You are not the owner");
            require(lstamp.used == false, "Stamp has already been used");
            lstamp.used = true;
            lstamp.twin = cardID;
            lstamp.twinSid = cardSID;
            card.twin = stampID;
            card.twinSid = stampSID;
            emit Stamp(msg.sender, Utils.encode(stampID, stampSID), Utils.encode(cardID, cardSID), keccak256(bytes(Utils.encode(stampID, stampSID))), keccak256(bytes(Utils.encode(cardID, cardSID))));
        }
    }

    function unstamp(uint256 id, uint256 sid) public {
        Utils.Element storage elementA = _owners[Utils.encode(id, sid)];
        require(elementA.owner != address(0), "This specific element does not exist");
        Utils.GlobalElement storage gElementA = _elements[id];
        require(gElementA.copies >= 1, "This global element does not exist");
        Utils.Element storage elementB = _owners[Utils.encode(elementA.twin, elementA.twinSid)];
        require(elementB.owner != address(0), "This specific element does not exist");
        Utils.GlobalElement storage gElementB = _elements[elementA.twin];
        require(gElementB.copies >= 1, "This global element does not exist");
        require(elementA.owner == msg.sender && elementB.owner == msg.sender, "You are not the owner");
        require(elementB.twin == id && elementB.twinSid == sid, "Elements are not attached together");
        if(gElementA.t == Utils.ElementType.card){
            emit Unstamp(msg.sender, Utils.encode(elementA.twin, elementA.twinSid), Utils.encode(id, sid), keccak256(bytes(Utils.encode(elementA.twin, elementA.twinSid))), keccak256(bytes(Utils.encode(id, sid))));
        }else{
            emit Unstamp(msg.sender, Utils.encode(id, sid), Utils.encode(elementA.twin, elementA.twinSid), keccak256(bytes(Utils.encode(id, sid))), keccak256(bytes(Utils.encode(elementA.twin, elementA.twinSid))));
        }
        elementA.twin = 0;
        elementA.twinSid = 0;
        elementB.twin = 0;
        elementB.twinSid = 0;
    }

    function burn(uint256[2][] calldata elementsToBurn) external {
        for(uint256 i = 0;i<elementsToBurn.length;i++){
            uint256 id = elementsToBurn[i][0];
            uint256 sid = elementsToBurn[i][1];
            Utils.Element storage element = _owners[Utils.encode(id, sid)];
            require(element.owner != address(0), "This specific element does not exist");
            Utils.GlobalElement storage global = _elements[id];
            require(global.copies >= 1, "This global element does not exist");
            require(element.owner == msg.sender, "The sender is not the owner");
            if(element.twin != 0){
                unstamp(id, sid);
            }
            delete _owners[Utils.encode(id, sid)];
            emit Burn(msg.sender, id, sid, global.copies);
        }
    }

    function withdraw(address currency) external onlyOwner{
        require(currencyManager.isCurrencyWhitelisted(currency), "Invalid currency");
        uint256 amount = ERC20(currency).balanceOf(address(this));
        ERC20(currency).transfer(msg.sender, amount);
        emit Withdraw(msg.sender, currency, amount);
    }

    function setPrice(address newPrice) external onlyOwner{
        price = newPrice;
        emit NewPrice(msg.sender, newPrice);
    }

    function setMarketplace(address _marketplace) external onlyOwner {
        marketplace = _marketplace;
        emit Marketplace(msg.sender, _marketplace);
    }

    function setCurrencyManager(address _currencyManager) external onlyOwner {
        currencyManager = CurrencyManager(_currencyManager);
        emit NewCurrencyManager(msg.sender, _currencyManager);
    }

    function approve(address to, uint256 id, uint256 sid) external {
        require(to != msg.sender, "Sender cannot be equal to the approved"); 
        require(to != address(0), "To cannot be null");
        require(sid != 0, "SID cannot be null");
        Utils.Element storage element = _owners[Utils.encode(id, sid)];
        require(element.owner != address(0), "This specific element does not exist");
        Utils.GlobalElement storage global = _elements[id];
        require(global.copies >= 1, "This global element does not exist");
        require(element.owner == msg.sender || msg.sender == _tokenApprovals[Utils.encode(id, sid)] || _operatorApprovals[element.owner][msg.sender], "The granter is not the owner");
        _tokenApprovals[Utils.encode(id, sid)] = to;
        emit Approval(element.owner, to, Utils.encode(id, sid));
    }

    function setApprovalForAll(address operator, bool approved) external {
        require(operator != address(0), "operator cannot be null");
        require(operator != msg.sender, "Sender cannot be equal to the operator"); 
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function getApproved(uint256 id, uint256 sid) external view returns(address) {
        return _tokenApprovals[Utils.encode(id, sid)];
    }

    function isApprovedForAll(address _owner, address _operator) external view returns(bool){
        return _operatorApprovals[_owner][_operator];
    }

    function ownerOf(uint256 id, uint256 sid) external view returns(address) {
        return _owners[Utils.encode(id, sid)].owner;
    }

    function getGlobal(uint256 id) external view returns(Utils.GlobalElement memory){
        return _elements[id];
    }

    function getElement(uint256 id, uint256 sid) external view returns (Utils.Element memory) {
        return _owners[Utils.encode(id, sid)];
    }

    function attached(uint256 id, uint256 sid) external view returns(uint256[2] memory) {
        uint256[2] memory _ids;
        Utils.Element storage element = _owners[Utils.encode(id, sid)];
        _ids[0] = element.twin;
        _ids[1] = element.twinSid;
        return _ids;
    }

    function uri(uint256 id) external view returns(bytes memory) {
        return _elements[id].cid;
    }

    function messageUri(uint256 id, uint256 sid) external view returns (bytes memory){
        return _owners[Utils.encode(id, sid)].messageCID;
    }

    function copies(uint256 id) external view returns (uint256){
        return _elements[id].copies;
    }
    
    function creator(uint256 id) external view returns(address) {
        return _elements[id].creator;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Price {

    modifier correctQuantity(uint256 quantity){
        require(quantity >= 1, "Cannot get a price less than one");
        _;
    }

    function cardPrice(uint256 copies, address currency) external view correctQuantity(copies) returns(uint256) {
        uint8 decimals = ERC20(currency).decimals();
        require(decimals >= 3, "Incorrect currency");
        if (copies <= 4) {
            return 4667*10**(decimals-3)*copies;
        }else if (copies <= 10) {
            return 3667*10**(decimals-3)*copies;
        }else if (copies <= 20) {
            return 298*10**(decimals-2)*copies;
        }else if (copies <= 100) {
            return 23*10**(decimals-1)*copies;
        }else{
            return 2*10**decimals*copies;
        }
    }

    function stampPrice(address currency) external view returns(uint256) {
        uint8 decimals = ERC20(currency).decimals();
        require(decimals >= 3, "Incorrect currency");
        return 5*10**(decimals-1);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Harfang.sol";
library Utils {
    enum ElementType {
        card,
        stamp
    }

    struct Element {
        address owner;
        uint256 twin;
        uint256 twinSid;
        bytes messageCID;
        bool used;
    }

    struct GlobalElement {
        address creator;
        bytes cid;
        uint256 copies;
        ElementType t;
        uint256 lastId;
    }

    function createGlobalElement(bytes memory cid, uint256 copies, ElementType t, address owner) internal pure returns(GlobalElement memory){
        return GlobalElement(
            owner, // creator
            cid, // uri
            copies, // copies
            t, // type
            0 // lastId
        );
    }

    function createLocalElement(address owner) internal pure returns(Element memory){
        return Element(
            owner, // owner
            0, // twin
            0, // twin sid
            "", // message
            false // used
        );
    }

    function encode(uint256 x, uint256 y) internal pure returns (string memory){
        return string(abi.encodePacked(abi.encodePacked(Strings.toString(x),"-"),Strings.toString(y)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract CurrencyManager is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _whitelistedCurrencies;

    event CurrencyRemoved(address indexed currency);
    event CurrencyWhitelisted(address indexed currency);

    /**
     * @notice Add a currency in the system
     * @param currency address of the currency to add
     */
    function addCurrency(address currency) external onlyOwner {
        require(!_whitelistedCurrencies.contains(currency), "Currency: Already whitelisted");
        _whitelistedCurrencies.add(currency);

        emit CurrencyWhitelisted(currency);
    }

    /**
     * @notice Remove a currency from the system
     * @param currency address of the currency to remove
     */
    function removeCurrency(address currency) external onlyOwner {
        require(_whitelistedCurrencies.contains(currency), "Currency: Not whitelisted");
        _whitelistedCurrencies.remove(currency);

        emit CurrencyRemoved(currency);
    }

    /**
     * @notice Returns if a currency is in the system
     * @param currency address of the currency
     */
    function isCurrencyWhitelisted(address currency) external view returns (bool) {
        return _whitelistedCurrencies.contains(currency);
    }

    /**
     * @notice View number of whitelisted currencies
     */
    function viewCountWhitelistedCurrencies() external view returns (uint256) {
        return _whitelistedCurrencies.length();
    }

    /**
     * @notice See whitelisted currencies in the system
     * @param cursor cursor (should start at 0 for first request)
     * @param size size of the response (e.g., 50)
     */
    function viewWhitelistedCurrencies(uint256 cursor, uint256 size)
        external
        view
        returns (address[] memory, uint256)
    {
        uint256 length = size;

        if (length > _whitelistedCurrencies.length() - cursor) {
            length = _whitelistedCurrencies.length() - cursor;
        }

        address[] memory whitelistedCurrencies = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            whitelistedCurrencies[i] = _whitelistedCurrencies.at(cursor + i);
        }

        return (whitelistedCurrencies, cursor + length);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}