// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./library/SafeERC20.sol";
import "./utils/Context.sol";
import "./utils/ReentrancyGuard.sol";

contract Ownable is Context {
    address private _owner;
    address internal _co_owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwnerr
    );

    event CoOwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function coOwner() public view returns (address) {
        return _co_owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Throws if called by any account other than the owners.
     */
    modifier onlyOwners() {
        require(
            _owner == _msgSender() || _co_owner == _msgSender(),
            "Ownable: caller is not the owner"
        );
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers co-ownership of the contract to a new account (`newCoOwner`).
     */
    function transferCoOwnership(address newCoOwner) public onlyOwners {
        require(
            newCoOwner != address(0),
            "Ownable: new co-owner is the zero address"
        );
        emit CoOwnershipTransferred(_co_owner, newCoOwner);
        _co_owner = newCoOwner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwners {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract Pausable is Ownable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Pause the tokens.
     *
     *  Requirements:
     *
     * - Only owner can call this fundction.
     */
    function pause() public virtual onlyOwner returns (bool) {
        _pause();
        return true;
    }

    /**
     * @dev Unpause the tokens.
     *
     * Requirements:
     *
     * - Only owner can call this fundction.
     */
    function unpause() public virtual onlyOwner returns (bool) {
        _unpause();
        return true;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

abstract contract BlackList is Ownable {
    /**
     * @dev blacklisted addresses
     */
    mapping(address => bool) private isBlackListed;

    event AddedBlackList(address _user);
    event RemovedBlackList(address _user);

    function getBlackListStatus(address _user) public view returns (bool) {
        return isBlackListed[_user];
    }

    /**
     * Define address as blcklist
     */
    function addBlackList(address _user) public onlyOwner returns (bool) {
        isBlackListed[_user] = true;
        emit AddedBlackList(_user);
        return true;
    }

    /**
     * Remove address from blcklist
     */
    function removeBlackList(address _user) public onlyOwner returns (bool) {
        isBlackListed[_user] = false;
        emit RemovedBlackList(_user);
        return true;
    }
}

abstract contract ReleasableToken is Ownable {
    /* The finalizer contract that allows unlift the transfer limits on this token */
    address public releaseAgent;

    /** A crowdsale contract can release us to the wild if the sale is a success. If false we are are in transfer lock up period.*/
    bool public released = false;

    /** Map of agents that are allowed to transfer tokens regardless of the lock down period. These are crowdsale contracts and possible the team multisig itself. */
    mapping(address => bool) public transferAgents;

    /**
     * Limit token transfer until the crowdsale is over.
     *
     */
    modifier canTransfer(address _sender) {
        require(
            released || transferAgents[_sender],
            "For the token to be able to transfer: it's required that the crowdsale is in released state; or the sender is a transfer agent."
        );
        _;
    }

    /**
     * Set the contract that can call release and make the token transferable.
     *
     * Design choice. Allow reset the release agent to fix fat finger mistakes.
     */
    function setReleaseAgent(address _addr)
        public
        onlyOwner
        inReleaseState(false)
    {
        // We don't do interface check here as we might want to a normal wallet address to act as a release agent
        releaseAgent = _addr;
    }

    /**
     * Owner can allow a particular address (a crowdsale contract) to transfer tokens despite the lock up period.
     */
    function setTransferAgent(address _addr, bool _state)
        public
        onlyOwner
        inReleaseState(false)
    {
        transferAgents[_addr] = _state;
    }

    /**
     * One way function to release the tokens to the wild.
     *
     * Can be called only from the release agent that is the final sale contract. It is only called if the crowdsale has been success (first milestone reached).
     */
    function releaseTokenTransfer() public onlyReleaseAgent {
        released = true;
    }

    /** The function can be called only before or after the tokens have been released */
    modifier inReleaseState(bool releaseState) {
        require(
            releaseState == released,
            "It's required that the state to check aligns with the released flag."
        );
        _;
    }

    /** The function can be called only by a whitelisted release agent. */
    modifier onlyReleaseAgent() {
        require(
            msg.sender == releaseAgent,
            "Message sender is required to be a release agent."
        );
        _;
    }
}

abstract contract MigrateToken is Ownable {
    /**
     * @dev Newly created token (Keep token's decimals same as old token)
     */
    IERC20 public newToken;

    /**
     * Rate of the tokens ==> 1 token V1 == (1 * rate) token V2
     */
    uint256 public rate;
    /**
     * Migration started
     */
    bool public migrationStarted = false;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier canMigrate() {
        require(
            migrationStarted == true,
            "Tokens are not open for migration process!"
        );
        _;
    }

    /**
     * @dev we want to track who has already migrated to V2
     */
    mapping(address => uint256) public claimed;

    /** How many tokens we have upgraded by now. */
    uint256 public totalUpgraded;

    /**
     * Somebody has upgraded some of his tokens.
     */
    event Migration(address indexed _user, uint256 _value);

    /**
     * Set newly created token's information for token migration process
     */
    function setMigrationToken(IERC20 _newToken, uint256 _rate)
        public
        canMigrate
        onlyOwner
        returns (bool)
    {
        newToken = _newToken;
        rate = _rate;
        return true;
    }

    /**
     * Total tokens available to migrate from V1 => V2
     */
    function availableTokensToMigrate()
        public
        view
        canMigrate
        returns (uint256)
    {
        return IERC20(newToken).balanceOf(address(this));
    }

    /**
     * Start migration process (Only Admin(Owner) can start)
     */
    function startMigration() public onlyOwner returns (bool) {
        require(migrationStarted == false, "Migration already started!");
        migrationStarted = true;
    }

    /**
     * Stop migration process (Only Admin(Owner) can start)
     */
    function stopMigration() public onlyOwner returns (bool) {
        require(migrationStarted == true, "Migration already stopped!");
        migrationStarted = false;
    }
}

abstract contract MultiTransfer is Ownable {
    using SafeMath for uint256;
    event TokenAirdrop(
        address indexed by,
        address indexed tokenAddress,
        uint256 totalTransfers
    );
    event MATICAirdrop(
        address indexed by,
        uint256 totalTransfers,
        uint256 ethValue
    );

    fallback() external payable {
        revert();
    }

    receive() external payable {
        revert();
    }

    /**
     * Used to give change to users who accidentally send too much MATIC to payable functions.
     *
     * @param _price The service fee the user has to pay for function execution.
     **/
    function giveChange(uint256 _price) internal {
        if (msg.value > _price) {
            uint256 change = msg.value.sub(_price);
            payable(msg.sender).transfer(change);
        }
    }

    /**
     * Allows for the distribution of Ether to be transferred to multiple recipients at
     * a time. This function only facilitates batch transfers of constant values (i.e., all recipients
     * will receive the same amount of tokens).
     *
     * @param _recipients The list of addresses which will receive tokens.
     * @param _value The amount of tokens all addresses will receive.
     *
     * @return true if function executes successfully, false otherwise.
     * */
    function singleValueMATICAirdrop(
        address[] memory _recipients,
        uint256 _value
    ) public payable returns (bool) {
        uint256 totalCost = _value.mul(_recipients.length);

        require(
            msg.value >= totalCost,
            "Not enough native coin sent with transaction!"
        );

        giveChange(totalCost);

        for (uint256 i = 0; i < _recipients.length; i++) {
            if (_recipients[i] != address(0)) {
                payable(_recipients[i]).transfer(_value);
            }
        }

        emit MATICAirdrop(
            msg.sender,
            _recipients.length,
            _value.mul(_recipients.length)
        );

        return true;
    }

    function _getTotalMATICValue(uint256[] memory _values)
        internal
        pure
        returns (uint256)
    {
        uint256 totalVal = 0;
        for (uint256 i = 0; i < _values.length; i++) {
            totalVal = totalVal.add(_values[i]);
        }
        return totalVal;
    }

    /**
     * Allows for the distribution of MATIC to be transferred to multiple recipients at
     * a time.
     *
     * @param _recipients The list of addresses which will receive tokens.
     * @param _values The corresponding amounts that the recipients will receive
     *
     * @return true if function executes successfully, false otherwise.
     * */
    function multiValueMATICAirdrop(
        address[] memory _recipients,
        uint256[] memory _values
    ) public payable returns (bool) {
        require(
            _recipients.length == _values.length,
            "Total number of recipients and values are not equal"
        );

        uint256 totalCost = _getTotalMATICValue(_values);

        require(
            msg.value >= totalCost,
            "Not enough MATIC sent with transaction!"
        );

        giveChange(totalCost);

        for (uint256 i = 0; i < _recipients.length; i++) {
            if (_recipients[i] != address(0) && _values[i] > 0) {
                payable(_recipients[i]).transfer(_values[i]);
            }
        }

        emit MATICAirdrop(msg.sender, _recipients.length, totalCost);
        return true;
    }

    /**
     * Allows for the distribution of an ERC20 token to be transferred to multiple recipients at
     * a time. This function only facilitates batch transfers of constant values (i.e., all recipients
     * will receive the same amount of tokens).
     *
     * @param _addressOfToken The contract address of an ERC20 token.
     * @param _recipients The list of addresses which will receive tokens.
     * @param _value The amount of tokens all addresses will receive.
     *
     * @return true if function executes successfully, false otherwise.
     * */
    function singleValueTokenAirdrop(
        address _addressOfToken,
        address[] memory _recipients,
        uint256 _value
    ) public returns (bool) {
        IERC20 token = IERC20(_addressOfToken);

        for (uint256 i = 0; i < _recipients.length; i++) {
            if (_recipients[i] != address(0)) {
                token.transferFrom(msg.sender, _recipients[i], _value);
            }
        }

        emit TokenAirdrop(msg.sender, _addressOfToken, _recipients.length);
        return true;
    }

    /**
     * Allows for the distribution of an ERC20 token to be transferred to multiple recipients at
     * a time. This function facilitates batch transfers of differing values (i.e., all recipients
     * can receive different amounts of tokens).
     *
     * @param _addressOfToken The contract address of an ERC20 token.
     * @param _recipients The list of addresses which will receive tokens.
     * @param _values The corresponding values of tokens which each address will receive.
     *
     * @return true if function executes successfully, false otherwise.
     * */
    function multiValueTokenAirdrop(
        address _addressOfToken,
        address[] memory _recipients,
        uint256[] memory _values
    ) public returns (bool) {
        IERC20 token = IERC20(_addressOfToken);
        require(
            _recipients.length == _values.length,
            "Total number of recipients and values are not equal"
        );

        for (uint256 i = 0; i < _recipients.length; i++) {
            if (_recipients[i] != address(0) && _values[i] > 0) {
                token.transferFrom(msg.sender, _recipients[i], _values[i]);
            }
        }

        emit TokenAirdrop(msg.sender, _addressOfToken, _recipients.length);
        return true;
    }
}

contract SpreaddToken is
    IERC20,
    ReentrancyGuard,
    BlackList,
    Pausable,
    ReleasableToken,
    MigrateToken,
    MultiTransfer
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    string private _name = "Spreadd Token";
    string private _symbol = "SPRD";
    uint8 private _decimals = 18;
    uint256 private _totalSupply;

    // Additional minting wallet
    address public Minter;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    event Mint(address indexed to, uint256 amount);
    event MintingRightsTransferred(address minter, address newMinter);
    event AdminTokenRecovery(address tokenRecovered, uint256 amount);

    /**
     * Wallets which has minting rights
     */
    modifier canMintTokens(address _address) {
        require(
            _address == Minter || _address == owner(),
            "User can not mint new tokens"
        );
        _;
    }

    /**
     * This value is immutable: it can only be set once during
     * construction.
     */

    constructor(address _coOwnerAddress, uint256 _initialSupply) public {
        require(
            _coOwnerAddress != address(0),
            "Co-owner's address can't be zero."
        );
        require(_initialSupply != 0, "Initial supply can't be zero.");
        _co_owner = _coOwnerAddress;
        releaseAgent = _msgSender();
        Minter = _msgSender();
        uint256 initialSupply = _initialSupply;

        _mint(address(_msgSender()), initialSupply);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address _recipient, uint256 _amount)
        public
        virtual
        override
        canTransfer(msg.sender)
        whenNotPaused
        returns (bool)
    {
        _transfer(_msgSender(), _recipient, _amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address _owner, address _spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[_owner][_spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address _spender, uint256 _amount)
        public
        virtual
        override
        whenNotPaused
        returns (bool)
    {
        _approve(_msgSender(), _spender, _amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    )
        public
        virtual
        override
        canTransfer(_sender)
        whenNotPaused
        returns (bool)
    {
        _transfer(_sender, _recipient, _amount);
        _approve(
            _sender,
            _msgSender(),
            _allowances[_sender][_msgSender()].sub(
                _amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
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
    function increaseAllowance(address _spender, uint256 _addedValue)
        public
        virtual
        whenNotPaused
        returns (bool)
    {
        _approve(
            _msgSender(),
            _spender,
            _allowances[_msgSender()][_spender].add(_addedValue)
        );
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
    function decreaseAllowance(address _spender, uint256 _subtractedValue)
        public
        virtual
        whenNotPaused
        returns (bool)
    {
        _approve(
            _msgSender(),
            _spender,
            _allowances[_msgSender()][_spender].sub(
                _subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 _amount) public virtual whenNotPaused {
        _burn(_msgSender(), _amount);
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `passed address in parameter`, increasing
     * the total supply.
     *
     * Requirements
     *
     * - `msg.sender` must be the token owner
     */
    function mint(address _to, uint256 _amount)
        public
        canMintTokens(_msgSender())
        returns (bool)
    {
        _mint(_to, _amount);
        return true;
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address _account, uint256 _amount)
        public
        virtual
        whenNotPaused
    {
        uint256 decreasedAllowance = allowance(_account, _msgSender()).sub(
            _amount,
            "ERC20: burn amount exceeds allowance"
        );

        _approve(_account, _msgSender(), decreasedAllowance);
        _burn(_account, _amount);
    }

    /**
     * @dev Transfers minting rights of the contract to a new address/contract.
     */
    function transferMintingRights(address _newMinter) public onlyOwner {
        require(
            _newMinter != address(0),
            "Minting: new Minter is the zero address"
        );
        emit MintingRightsTransferred(Minter, _newMinter);
        Minter = _newMinter;
    }

    /**
     * @dev Migrate tokens to newer version.
     *
     * Emits an {Migration} event indicating the Migrate tokens.
     *
     * Requirements:
     *
     * - `msg.sender` can hold required tokens.
     * - `_amount` Number of tokens you want to migrate
     */
    function migrateTokens(uint256 _amount) external canMigrate nonReentrant {
        // Validate input value.
        require(_amount > 0, "The upgrade value is required to be above 0.");
        uint256 amount = _amount;
        uint256 oldTokenBalance = balanceOf(msg.sender);
        require(
            oldTokenBalance >= amount,
            "You must hold old tokens to migrate"
        );
        uint256 tokensToMigrate = _amount * rate;
        require(
            IERC20(newToken).balanceOf(address(this)) >= tokensToMigrate,
            "Not enough new token's as liquidity"
        );

        // Take tokens out from circulation
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        totalUpgraded = totalUpgraded.add(amount);
        claimed[msg.sender] += amount;

        // transfer V2 tokens
        IERC20(newToken).safeTransfer(msg.sender, tokensToMigrate);
        emit Migration(msg.sender, tokensToMigrate);
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @dev This function is only callable by admin.
     */
    function recoverWrongTokens(address _tokenAddress) external onlyOwner {
        require(
            _tokenAddress != address(0),
            "Token address must not be zero address"
        );
        uint256 _tokenAmount = IERC20(_tokenAddress).balanceOf(address(this));
        IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);

        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address _sender,
        address _recipient,
        uint256 _amount
    ) internal virtual {
        require(_sender != address(0), "ERC20: transfer from the zero address");
        require(
            _recipient != address(0),
            "ERC20: transfer to the zero address"
        );
        require(
            getBlackListStatus(_sender) == false,
            "Blacklisted address can not perform token transfer"
        );

        _balances[_sender] = _balances[_sender].sub(
            _amount,
            "ERC20: transfer amount exceeds balance"
        );

        _balances[_recipient] = _balances[_recipient].add(_amount);
        emit Transfer(_sender, _recipient, _amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address _account, uint256 _amount) internal {
        require(_account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(_amount);
        _balances[_account] = _balances[_account].add(_amount);
        emit Transfer(address(0), _account, _amount);
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
    function _burn(address _account, uint256 _amount) internal virtual {
        _balances[_account] = _balances[_account].sub(
            _amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(_amount);
        emit Transfer(_account, address(0), _amount);
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
        address _owner,
        address _spender,
        uint256 _amount
    ) internal virtual {
        require(_spender != address(0), "ERC20: approve to the zero address");

        _allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./SafeMath.sol";
import "./Address.sol";
import "../interfaces/IERC20.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

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

    constructor() internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }

    function ceil(uint256 a, uint256 m) internal pure returns (uint256 r) {
        require(m != 0, "SafeMath: to ceil number shall not be zero");
        return ((a + m - 1) / m) * m;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}