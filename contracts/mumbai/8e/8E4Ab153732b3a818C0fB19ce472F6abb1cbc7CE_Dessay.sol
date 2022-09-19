/**
 *Submitted for verification at polygonscan.com on 2022-09-18
*/

// File: Dessay_flat.sol


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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




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

// File: Workspace/DessayToken.sol


pragma solidity ^0.8.8;


contract DessayToken is ERC20 {
    uint constant INIT_SUPPLY = 100 * (10**18);
    mapping(address => uint) public stakedBalances;
    mapping(address => bool) public isStaked;
    mapping(address => uint) public stakeTimes;
    mapping(address => uint) public userPowers;

    constructor() ERC20("Dessay", "DSY") {
        _mint(msg.sender, INIT_SUPPLY);
    }

    function stakeToken(uint256 amount) public {
        require(
            amount <= balanceOf(msg.sender),
            "Not enough Dessay tokens in your wallet, please try lesser amount"
        );
        require(!isStaked[msg.sender], "You have already staked Dessay tokens");
        approve(msg.sender, amount);
        transferFrom(msg.sender, address(this), amount);
        stakedBalances[msg.sender] = amount;
        stakeTimes[msg.sender] = block.timestamp;
        isStaked[msg.sender] = true;
        userPowers[msg.sender] = amount;
    }

    function unstakeToken(uint256 amount) public {
        require(isStaked[msg.sender], "You have not staked Dessay tokens");
        require(
            block.timestamp >= stakeTimes[msg.sender] + 86400,
            "You can unstake only after 24 hours"
        );
        require(
            amount <= stakedBalances[msg.sender],
            "You can't unstake more than you have staked"
        );
        isStaked[msg.sender] = false;
        stakedBalances[msg.sender] -= amount;
        transfer(msg.sender, amount);
    }

    function getStakedBalance(address user) public view returns (uint) {
        return stakedBalances[user];
    }

    function getStakeTime(address user) public view returns (uint) {
        return stakeTimes[user];
    }

    function getUserPower(address user) public view returns (uint) {
        return userPowers[user];
    }
}

// File: Workspace/Dessay.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;



contract Dessay is DessayToken {
    DessayToken public ourToken;

    event WritingEntered(
        string header,
        string ipfsaddr,
        address publisher,
        Topics[] topics,
        uint tstamp,
        uint index,
        uint id
    );

    event PersonFollowed(
        address follower,
        address followed,
        uint targetFollowerCount,
        uint tstamp
    );

    event Upvoted(
        address voter,
        address receiver,
        uint amount,
        uint writingID,
        uint tstamp
    );

    event UpdatedName(address user, string name, uint tstamp);
    event UpdatedBio(address user, string bio, uint tstamp);
    event UpdatedPp(address user, string data, uint tstamp);

    event ReplyAdded(uint id, address publisher, string content);

    constructor(address _ourToken) {
        ourToken = DessayToken(_ourToken);
    }

    enum Topics {
        Felsefe,
        BilimKurgu,
        Teknoloji,
        Bilim,
        Sanat,
        Muzik,
        Programlama,
        Biyoloji,
        Fizik,
        Kimya,
        Matematik,
        Evrim,
        Havacilik,
        Cografya,
        FilmIncelemesi,
        BilgisayarBilimleri,
        Kripto
    }

    enum NotifType {
        Follow,
        Upvote,
        Reply,
        Warn,
        BadgeBuy,
        BadgeOffer,
        WritingAdded
    }

    enum WarnType {
        UygunsuzBaslik,
        UygunsuzIcerik,
        HateSpeech,
        UygunsuzResim,
        Spam,
        Other
    }


    struct Collection {
        address creator;
        uint collectionID;
        uint count;
        uint kalan;
        string collectionName;
        string collectionDesc;
        string collectionPp;
        address[] owners;
    }

    struct Notif {
        NotifType notifType;
        address sender;
        uint id;
    }

    struct Warning {
        address sender;
        WarnType reason;
        uint writingID;
        string description;
    }

    struct Profile {
        string Pp;
        string Name;
        string Biography;
        uint Followers;
        uint Followed;
        uint Writings;
    }

    struct Upvote {
        address publisher;
        uint amount;
        uint percentage;
        uint writingId;
        uint before;

    }

    struct Writing {
        string header;
        string ipfsaddress;
        Topics[] topics;
        address publisher;
        uint comments;
        uint tstamp;
        uint index;
        uint id;
        uint upvoteAmount;
        uint upvoteCount;
        uint replyCount;
        uint warnCount;
        uint badgeThreshold;
    }

    struct Object {
        address publisher;
        uint index;
    }


    struct Comment {
        address publisher;
        string content;
    }

    uint writingCount = 0;
    mapping(uint => Warning[]) idToWarnings;
    mapping(address => Writing[]) addrToWriting;
    mapping(address => address[]) addrToFollowed;
    mapping(address => address[]) addrToFollowers;
    mapping(uint => Object) idToObject;
    mapping(address => Object[]) addrToFeed;
    mapping(address => Notif[]) addrToNotifs;
    mapping(uint => Comment[]) idToComments;
    mapping(address => Profile) addrToProfile;
    mapping(Topics => Writing[]) topicToWritings;
    mapping(address => uint[]) addrToOwnedBadges;
    mapping(address=>uint[]) addrToCategories;
    mapping(address=>Upvote[]) addrToUpvotes;
    mapping(uint=>Collection) idToCollection;

    function enterWriting(
        string memory _header,
        string memory _ipfsaddress,
        Topics[] memory _topicsInput,
        uint _badgeThreshold,
        uint count,
        string memory collectionName,
        string memory collectionDesc,
        string memory collectionPp
    ) public {
        addrToWriting[msg.sender].push(
            Writing(
                _header,
                _ipfsaddress,
                _topicsInput,
                msg.sender,
                0,
                block.timestamp,
                addrToWriting[msg.sender].length,
                writingCount,
                0,
                0,
                0,
                0,
                _badgeThreshold
            )
        );
        idToCollection[writingCount] = Collection(msg.sender, writingCount, count,count, collectionName, collectionDesc, collectionPp,  new address[](count));
        idToObject[writingCount] = Object(
            msg.sender,
            addrToWriting[msg.sender].length - 1
        );
        writingCount++;
        addrToProfile[msg.sender].Writings++;
        for (uint i = 0; i < _topicsInput.length; i++) {
            topicToWritings[_topicsInput[i]].push(
                addrToWriting[msg.sender][addrToWriting[msg.sender].length - 1]
            );
        }
        for (uint i = 0; i < addrToFollowers[msg.sender].length; i++) {
            addrToFeed[addrToFollowers[msg.sender][i]].push(
                Object(msg.sender, addrToWriting[msg.sender].length - 1)
            );
            sendNotif(
                uint8(NotifType.WritingAdded),
                addrToFollowers[msg.sender][i],
                writingCount - 1
            );
        }

        emit WritingEntered(
            _header,
            _ipfsaddress,
            msg.sender,
            _topicsInput,
            block.timestamp,
            addrToWriting[msg.sender].length - 1,
            writingCount - 1
        );
    }

    function getWrites(address user)
        public
        view
        returns (Writing[] memory hisWriting)
    {
        return addrToWriting[user];
    }

    function getWritingForIndex(address _addr, uint index)
        public
        view
        returns (Writing memory writing)
    {
        return addrToWriting[_addr][index];
    }

    function getWritingForID(uint _id)
        public
        view
        returns (Writing memory writing)
    {
        return
            addrToWriting[idToObject[_id].publisher][idToObject[_id].index];
    }

    function follow(address _addr) public {
        addrToFollowed[msg.sender].push(_addr);
        addrToProfile[_addr].Followers++;
        sendNotif(uint8(NotifType.Follow), _addr, 0);
        emit PersonFollowed(
            msg.sender,
            _addr,
            addrToProfile[_addr].Followers,
            block.timestamp
        );
    }

     function getTopicsForAddress(address _addr)
        public
        view
        returns (uint[] memory topics)
    {
        return addrToCategories[_addr];

    }

    function setTopicsForAddress(uint[] memory hisTopics ) public {
        addrToCategories[msg.sender] = hisTopics;
    }


    function reply(
        address _publisher,
        string memory content,
        uint _id
    ) public {
        idToComments[_id].push(Comment(_publisher, content));
        addrToWriting[idToObject[_id].publisher][idToObject[_id].index].replyCount++;
        sendNotif(uint8(NotifType.Reply), _publisher, _id);
        emit ReplyAdded(_id, _publisher, content);
    }

    function warnWriting(
        address publisher,
        uint index,
        uint warnType,
        string memory desc
    ) public {
        addrToWriting[publisher][index].warnCount++;
        idToWarnings[addrToWriting[publisher][index].id].push(
            Warning(
                msg.sender,
                WarnType(warnType),
                addrToWriting[publisher][index].id,
                desc
            )
        );
    }

    function upvote(uint256 amount, uint256 writingId, uint percentage) public {
        require(userPowers[idToObject[writingId].publisher] >= amount,"Not enough power");
        require(percentage <= 100,"Percentage cannot be more than 100");
        userPowers[idToObject[writingId].publisher] -= amount;
        addrToUpvotes[msg.sender].push(Upvote(msg.sender,amount,percentage,writingId,addrToWriting[idToObject[writingId].publisher][idToObject[writingId].index].upvoteAmount));
        addrToWriting[idToObject[writingId].publisher][
            idToObject[writingId].index
        ].upvoteCount++;
        addrToWriting[idToObject[writingId].publisher][
            idToObject[writingId].index
        ].upvoteAmount += amount;
        Writing memory ourWriting=addrToWriting[idToObject[writingId].publisher][idToObject[writingId].index];
        if(ourWriting.badgeThreshold < amount){
            addrToOwnedBadges[msg.sender].push(writingId);
            idToCollection[writingId].owners.push(msg.sender);
            idToCollection[writingId].kalan--;
        }
        sendNotif(uint8(NotifType.Upvote), idToObject[writingId].publisher, 0);
        emit Upvoted(
            msg.sender,
            idToObject[writingId].publisher,
            amount,
            writingId,
            block.timestamp
        );
    }

    function updateName(string memory _name) public {
        addrToProfile[msg.sender].Name = _name;
        emit UpdatedName(msg.sender, _name, block.timestamp);
    }

    function updateBio(string memory _bio) public {
        addrToProfile[msg.sender].Biography = _bio;
        emit UpdatedBio(msg.sender, _bio, block.timestamp);
    }

    function updatePp(string memory _pp) public {
        addrToProfile[msg.sender].Pp = _pp;
        emit UpdatedPp(msg.sender, _pp, block.timestamp);
    }

    function getComments(uint _id)
        public
        view
        returns (Comment[] memory comments)
    {
        return idToComments[_id];
    }

    function getProfile(address _addr)
        public
        view
        returns (Profile memory profile)
    {
        return addrToProfile[_addr];
    }

    

    function calcRewards() public view returns(uint userRewards, uint writerRewards) {
        for (uint256 index = 0; index < addrToUpvotes[msg.sender].length; index++) {
            if (addrToUpvotes[msg.sender][index].publisher == msg.sender) {
                userRewards +=  ( sqrt(addrToUpvotes[msg.sender][index].amount) * (  ( sqrt(addrToWriting[addrToUpvotes[msg.sender][index].publisher][addrToUpvotes[msg.sender][index].writingId].upvoteAmount)) - sqrt(addrToUpvotes[msg.sender][index].before)   )    )/2;
            } else {
                writerRewards += sqrt(stakedBalances[msg.sender]) * sqrt(addrToUpvotes[msg.sender][index].percentage);
            }
        }

        return (userRewards, writerRewards);
    }

    function claimRewards() public payable {
        (uint userRewards, uint writerRewards) = calcRewards();
        stakedBalances[msg.sender] += (userRewards + writerRewards) * 3 / 4;
        (bool success,) = msg.sender.call{value: (userRewards + writerRewards)/4}("");
        require(success, "Transfer failed.");
    }

    function sqrt(uint x) private pure returns (uint y) {
    uint z = (x + 1) / 2;
    y = x;
    while (z < y) {
        y = z;
        z = (x / z + z) / 2;
    }
}

    function getFeed()
        public
        view
        returns (Writing[] memory cards)
    {
        cards = new Writing[](addrToFeed[msg.sender].length);
        for (uint i = 0; i < addrToFeed[msg.sender].length ; i++) {
            
                cards[i] = addrToWriting[
                addrToFeed[msg.sender][i].publisher
                ][addrToFeed[msg.sender][i].index];
            
            
        }
    }

    function getWritingsForTopic(
        Topics _topic
        
    ) public view returns (Writing[] memory writings) {
        Writing[] memory output = new Writing[](topicToWritings[_topic].length);
        for (uint i = 0; i < topicToWritings[_topic].length; i++) {
            
            output[i] = topicToWritings[_topic][i];
            
        }
        return output;
    }

    function sendNotif(
        uint8 notifType,
        address receiver,
        uint id
    ) public {
        require(notifType < 3, "Notif type must be 0, 1 or 2");
        addrToNotifs[receiver].push(
            Notif(NotifType(notifType), msg.sender, id)
        );
    }

    function getOwnedBadges() public view returns (Collection[] memory ) {
         Collection[] memory ourBadges = new Collection[](addrToOwnedBadges[msg.sender].length);
        
        for (uint256 index = 0; index < addrToOwnedBadges[msg.sender].length; index++) {
            ourBadges[index] = idToCollection[addrToOwnedBadges[msg.sender][index]];
        }
        return ourBadges;
        

    }
    
    function getBadgeExplore() public view returns (Collection[] memory ) {
        
        Collection[] memory ourBadges = new Collection[](writingCount);
        for (uint256 index = 0; index < writingCount; index++) {
            ourBadges[index] = idToCollection[index];
           
        }

        return ourBadges;
    }

    function getFeedFromInfura() public view returns (Writing[] memory cards) {
        cards = new Writing[](writingCount);
        for (uint i = 0; i < writingCount ; i++) {
            
                cards[i] = addrToWriting[idToObject[i].publisher][idToObject[i].index];
            
            
        }
        return cards;

    }


    function Init() public {
        Topics[] memory TopicInput = new Topics[](2);
        TopicInput[0] = Topics.BilgisayarBilimleri;
        TopicInput[1] = Topics.Sanat;
        enterWriting("Dessay", "IPFSaddr",TopicInput ,15, 50, "As", "Sa dedik", "Yok valla");
        enterWriting("ASFAS", "sdsfsfsfsfa",TopicInput ,126, 30, "asdfasfasf", "Ssdfsdf", "Ysdfsdffsd");
        enterWriting("sdgasgasgsdg", "SASFASFFASFfa",TopicInput ,137, 70, "asdDGFDFGf", "SsdfFGFdf", "YsdfsFd");
        enterWriting("ASFAS", "sdsfsfsfsfa",TopicInput ,126, 30, "asdfasfasf", "Ssdfsdf", "Ysdfsdffsd");
   
    }

    function getNotif() public view returns (Notif[] memory notifs) {
        return addrToNotifs[msg.sender];
    }

    function getBadgeFromId(uint _id) public view returns (Collection memory badge) {
        return idToCollection[_id];
    }

}